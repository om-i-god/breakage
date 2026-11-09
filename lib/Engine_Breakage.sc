// Engine_Breakage
//
// A synthesized drum kit (Aphex / dub-techno range, no samples) plus a
// monophonic breakbeat slice player. One-shot voices are spawned per hit into
// a voice group; a fixed fx chain (dub echo -> reverb -> glitch -> master)
// sits in an fx group after it.
//
// buses: dry  (kick only: skips crush and dip)
//        main (everything else, plus the echo and reverb returns)
//        echo / verb sends
//
// the glitch insert reads dry and main and writes them back (stutter, tape
// stop, reverse, chop, crush); the master then crushes + dips main, sums,
// sanitizes, drives and limits
//
// NOTE: sclang binary operators have no precedence (strict left-to-right),
// so every compound expression below is fully parenthesized.
// NOTE: norns' ARM sqrt returns NaN for 0 and denormals: clamp before sqrt.
//
// commands (all args f unless noted; tone is always 0..1)
//   kick   amp tune decay drive bend type   tune midi; type 1 sub 2 909 3 808 4 knock 5 gabber
//                                            6 rave 7 acoustic 8 metal 9 minipops 10 dubstep
//                                            11 click 12 toy 13 dusty 14 tribal 15 808 long 16 simmons
//   snare  amp tune decay tone pan bend type   tune midi; bend semitones; 1 909 2 drill 3 808 4 noise
//                                            5 acoustic 6 jungle 7 metal 8 minipops 9 dubstep
//                                            10 click 11 toy 12 dusty 13 frame 14 disco 15 simmons
//   clap   amp decay tone pan
//   rim    amp tune pan                      tune midi
//   hat    amp decay tone pan type           1 analog 2 metallic 3 crisp 4 acoustic 5 lofi 6 minipops 7 dusty 8 click 9 disco; decay <= 0.15 chokes the open hat
//   ride   amp decay tone pan
//   shaker amp decay pan
//   tom    amp hz decay pan bend tone        bend semitones; tone 0..1 (skin + drive)
//   perc   amp hz decay pan kind tone        tone 0..1, its own timbre per kind; 1 conga 2 bongo 3 cowbell 4 clave 5 acid
//                                            6 metal 7 log 8 plink 9 guiro 10 tambourine
//                                            11 music box 12 squeak 13 talking drum 14 wobble 15 crackle
//                                            16 vox 17 syntom
//   tick   amp kind hz pan                   1 click 2 blip 3 crush 4 ring 5 chirp 6 zap 7 error 8 pop
//   brk    amp pos len rate pan              slice of the loaded break; monophonic
//   break_load path (s)                      mono or stereo sound file
//   glitch mode slice dur mix                1 stutter 2 tape stop 3 reverse 4 chop 5 crush
//   tweak  key (s) val (f)                   see `st` and fxMap below
//
// polls
//   out_amp, out_lo, out_mid, out_hi  0..1 on a dB scale, for the visuals

Engine_Breakage : CroneEngine {
  var voiceGroup, fxGroup;
  var dryBus, mainBus, echoBus, verbBus, outBus;
  var echoSynth, verbSynth, glitchSynth, masterSynth;
  var breakBuf, chokeBus, hatCount = 0, sliceCount = 0;
  var st, fx, fxMap, fxVals;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    var s = context.server;
    var kdrive, sends, hatSrc;

    dryBus  = Bus.audio(s, 2);
    mainBus = Bus.audio(s, 2);
    echoBus = Bus.audio(s, 2);
    verbBus = Bus.audio(s, 2);
    outBus  = Bus.control(s, 4);     // out_amp, out_lo, out_mid, out_hi
    // choke counters: [0] open hats, [1] break slices. a voice with id below
    // the counter releases itself (no /n_set on nodes that may be gone)
    chokeBus = Bus.control(s, 2);
    chokeBus.setn([0, 0]);

    voiceGroup = Group.head(context.xg);
    fxGroup    = Group.after(voiceGroup);

    // per-voice settings read at spawn time (set via `tweak`)
    st = IdentityDictionary[
      \kick_lvl -> 1.0,
      \snare_lvl -> 1.0, \snare_echo -> 0.15, \snare_verb -> 0.20,
      \clap_lvl -> 1.0,  \clap_echo -> 0.25,  \clap_verb -> 0.30,
      \rim_lvl -> 1.0,   \rim_echo -> 0.45,   \rim_verb -> 0.20,
      \hat_lvl -> 1.0,   \hat_echo -> 0.05,   \hat_verb -> 0.08,
      \ride_lvl -> 1.0,  \ride_verb -> 0.12,
      \perc_lvl -> 1.0,  \perc_echo -> 0.30,  \perc_verb -> 0.18,
      \tom_lvl -> 1.0,   \tom_echo -> 0.40,   \tom_verb -> 0.25,
      \tick_lvl -> 1.0,  \tick_echo -> 0.25,  \tick_verb -> 0.10,
      \break_lvl -> 1.0, \break_echo -> 0.0,  \break_verb -> 0.05
    ];

    // shared helpers, expanded at SynthDef build time

    // kick saturation: exactly clean at 0, a hot tanh blend up to 1.
    // loudness-compensated: the tanh squares the kick off at the same peak,
    // which made driven kits ~10 dB louder than clean ones and slammed the
    // master's drive (heard as clipping); scaled down as the drive rises
    kdrive = { |sig, d|
      var dd = d.clip(0, 1);
      ((sig * (1 - dd)) + ((sig * (1 + (dd * 8))).tanh * (0.9 * dd))) / (1 + (dd * 1.5))
    };

    // stereo voice -> main + sends
    sends = { |sig, out, echoOut, verbOut, echo, verb|
      Out.ar(out, sig);
      Out.ar(echoOut, sig * echo);
      Out.ar(verbOut, sig * verb);
    };

    // ----------------------------------------------------------------- kick
    // all kicks: tune = midi, bend scales the pitch-envelope depth

    // sub: deep clean dub sine, long, gentle pitch settle
    SynthDef(\brk_kick_sub, {
      arg out, amp=0.8, tune=31, decay=0.6, drive=0, bend=1;
      var base = tune.midicps;
      var pe   = EnvGen.ar(Env([1, 0], [0.08], [-5]));
      var f    = base * (1 + (pe * (1.2 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env([0, 1, 0.75, 0], [0.004, decay * 0.5, decay * 1.4], [0, -1, -3]), doneAction: 2);
      var sig  = (SinOsc.ar(f) + (SinOsc.ar(f * 2) * 0.06)) * aenv * 0.95;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // 909: fast deep pitch snap, click, a little noise
    SynthDef(\brk_kick_909, {
      arg out, amp=0.8, tune=33, decay=0.45, drive=0, bend=1;
      var base = tune.midicps;
      var pe   = EnvGen.ar(Env([1, 0], [0.04], [-8]));
      var f    = base * (1 + (pe * (5 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env.perc(0.001, decay, 1, -4.5), doneAction: 2);
      var body = SinOsc.ar(f) * aenv;
      var clk  = HPF.ar(WhiteNoise.ar, 3500) * EnvGen.ar(Env.perc(0.0003, 0.005)) * 0.45;
      var nz   = BPF.ar(WhiteNoise.ar, 4500, 1.2) * EnvGen.ar(Env.perc(0.001, 0.045, 1, -4)) * 0.18;
      var sig  = ((body * 1.25) + clk + nz).tanh * 0.95;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // 808: long boom, slow pitch fall
    SynthDef(\brk_kick_808, {
      arg out, amp=0.8, tune=31, decay=0.6, drive=0, bend=1;
      var base = tune.midicps;
      var pe   = EnvGen.ar(Env([1, 0], [0.32], [-3]));
      var f    = base * (1 + (pe * (0.9 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env.perc(0.003, decay * 2.2, 1, -3), doneAction: 2);
      var clk  = LPF.ar(WhiteNoise.ar, 3000) * EnvGen.ar(Env.perc(0.0005, 0.004)) * 0.25;
      var sig  = (((SinOsc.ar(f) * aenv) * 1.3) + clk).tanh * 0.95;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // knock: short, tight, woody
    SynthDef(\brk_kick_knock, {
      arg out, amp=0.8, tune=33, decay=0.45, drive=0, bend=1;
      var base = (tune + 7).midicps;
      var pe   = EnvGen.ar(Env([1, 0], [0.018], [-6]));
      var f    = base * (1 + (pe * (3 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env.perc(0.0005, (decay * 0.3).max(0.03), 1, -7), doneAction: 2);
      var wood = SinOsc.ar(f * 2.43) * EnvGen.ar(Env.perc(0.0005, 0.03, 1, -6)) * 0.3;
      var clk  = BPF.ar(WhiteNoise.ar, 2500, 0.6) * EnvGen.ar(Env.perc(0.0003, 0.008)) * 0.7;
      var sig  = ((((SinOsc.ar(f) + wood) * aenv) + clk) * 1.6).tanh * 0.9;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // gabber: pitched sine slammed into a square, hard transient
    SynthDef(\brk_kick_gabber, {
      arg out, amp=0.8, tune=33, decay=0.45, drive=0, bend=1;
      var base = (tune + 3).midicps;
      var pe   = EnvGen.ar(Env([1, 0.22, 0], [0.012, 0.14], [-6, -3]));
      var f    = base * (1 + (pe * (7 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env([0, 1, 0.85, 0], [0.0008, decay * 0.55, decay * 0.5], [0, -0.5, -5]), doneAction: 2);
      var body = SinOsc.ar(f) * aenv;
      var hit  = HPF.ar(WhiteNoise.ar, 2000) * EnvGen.ar(Env.perc(0.0002, 0.006)) * 0.8;
      var sig  = ((body * 22) + hit).tanh;
      sig = (sig.clip2(0.75) * 1.2) + (body * 0.25);
      sig = LPF.ar(sig, 9000) * 0.72;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;


    // rave: early-90s hardcore boom, a long pitched sine driven hard and
    // low-passed, with a hard click on top
    SynthDef(\brk_kick_rave, {
      arg out, amp=0.8, tune=33, decay=0.45, drive=0, bend=1;
      var base = tune.midicps;
      var pe   = EnvGen.ar(Env([1, 0.15, 0], [0.03, 0.12], [-6, -3]));
      var f    = base * (1 + (pe * (6 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env([0, 1, 0.7, 0], [0.001, decay * 0.6, decay * 1.2], [0, -1, -4]), doneAction: 2);
      var body = SinOsc.ar(f) * aenv;
      var clk  = HPF.ar(WhiteNoise.ar, 3000) * EnvGen.ar(Env.perc(0.0003, 0.008)) * 0.6;
      var sig  = ((body * 4) + clk).tanh;
      sig = (LPF.ar(sig, 2500) * 0.8) + (body * 0.2);
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // acoustic: a felt beater on a big kick drum, the shell ringing under it
    SynthDef(\brk_kick_acoustic, {
      arg out, amp=0.8, tune=33, decay=0.45, drive=0, bend=1;
      var base  = (tune + 5).midicps;
      var pe    = EnvGen.ar(Env([1, 0], [0.025], [-5]));
      var f     = base * (1 + (pe * (0.8 * bend.clip(0, 4))));
      var aenv  = EnvGen.ar(Env.perc(0.002, (decay * 0.7).max(0.08), 1, -5), doneAction: 2);
      var body  = SinOsc.ar(f) * aenv;
      var beat  = BPF.ar(WhiteNoise.ar, 2800, 1.5) * EnvGen.ar(Env.perc(0.0005, 0.012)) * 1.2;
      var shell = (SinOsc.ar(f * 1.59) * EnvGen.ar(Env.perc(0.001, decay * 0.2, 1, -5)))
                  + ((SinOsc.ar(f * 2.31) * EnvGen.ar(Env.perc(0.001, decay * 0.12, 1, -5))) * 0.6);
      var thud  = LPF.ar(WhiteNoise.ar, 180) * EnvGen.ar(Env.perc(0.001, 0.08)) * 0.8;
      var sig   = (((body * 1.1) + beat + (shell * 0.3) + thud) * 1.2).tanh * 0.9;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // metal: a knock with an inharmonic clang on the strike, crushed
    SynthDef(\brk_kick_metal, {
      arg out, amp=0.8, tune=33, decay=0.45, drive=0, bend=1;
      var base  = (tune + 2).midicps;
      var pe    = EnvGen.ar(Env([1, 0], [0.03], [-7]));
      var f     = base * (1 + (pe * (4 * bend.clip(0, 4))));
      var aenv  = EnvGen.ar(Env.perc(0.001, decay * 0.8, 1, -5), doneAction: 2);
      var body  = SinOsc.ar(f) * aenv;
      var cenv  = EnvGen.ar(Env.perc(0.0005, (decay * 0.35).max(0.04), 1, -6));
      var clang = (SinOsc.ar(f * 3.71) * SinOsc.ar(f * 5.13)) + (Pulse.ar(f * 2.07) * 0.3);
      var sig   = ((body * 3) + ((BPF.ar(clang, 1200, 0.8) * cenv) * 1.5)).tanh;
      sig = Latch.ar(sig, Impulse.ar(16000)).round(0.0625);
      sig = LPF.ar(sig, 8000) * 0.85;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // minipops: a rhythm box's bass drum, a damped resonant filter pinged
    // soft, round and short, no click
    SynthDef(\brk_kick_minipops, {
      arg out, amp=0.8, tune=36, decay=0.35, drive=0, bend=1;
      var base = tune.midicps;
      var pe   = EnvGen.ar(Env([1, 0], [0.02], [-4]));
      var f    = base * (1 + (pe * (0.35 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env([0, 1, 0], [0.006, (decay * 0.8).max(0.06)], [2, -5]), doneAction: 2);
      var body = SinOsc.ar(f) + (SinOsc.ar(f * 2.02) * 0.08);
      var sig  = LPF.ar(body * aenv, 900);
      sig = (sig * 1.4).tanh * 0.95;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // dubstep: a deep sub with a long tail, a punch and a click on top
    SynthDef(\brk_kick_dubstep, {
      arg out, amp=0.8, tune=29, decay=0.6, drive=0, bend=1;
      var base  = tune.midicps;
      var pe    = EnvGen.ar(Env([1, 0], [0.06], [-6]));
      var f     = base * (1 + (pe * (3 * bend.clip(0, 4))));
      var aenv  = EnvGen.ar(Env([0, 1, 0.8, 0], [0.002, decay * 0.7, decay * 1.2], [0, -0.5, -4]), doneAction: 2);
      var body  = SinOsc.ar(f) * aenv;
      var punch = SinOsc.ar(f * 3) * EnvGen.ar(Env.perc(0.001, 0.03, 1, -6)) * 0.4;
      var clk   = HPF.ar(WhiteNoise.ar, 4000) * EnvGen.ar(Env.perc(0.0003, 0.006)) * 0.5;
      var sig   = (((body * 1.4) + punch + clk) * 1.1).tanh * 0.95;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // click: microsound, a short sine pop and a digital click
    SynthDef(\brk_kick_click, {
      arg out, amp=0.8, tune=36, decay=0.3, drive=0, bend=1;
      var base = (tune + 12).midicps;
      var pe   = EnvGen.ar(Env([1, 0], [0.01], [-8]));
      var f    = base * (1 + (pe * (4 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env.perc(0.0005, (decay * 0.15).max(0.02), 1, -8), doneAction: 2);
      var pop  = SinOsc.ar(f) * aenv;
      var clk  = (Impulse.ar(0) * 0.8) + (Latch.ar(WhiteNoise.ar, Impulse.ar(8000)) * EnvGen.ar(Env.perc(0.0001, 0.002)) * 0.5);
      var sig  = ((pop * 1.6) + clk).clip2(1) * 0.9;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // toy: a tiny plastic thump with a rattle
    SynthDef(\brk_kick_toy, {
      arg out, amp=0.8, tune=36, decay=0.3, drive=0, bend=1;
      var base   = (tune + 19).midicps;
      var pe     = EnvGen.ar(Env([1, 0], [0.015], [-5]));
      var f      = base * (1 + (pe * (1.5 * bend.clip(0, 4))));
      var aenv   = EnvGen.ar(Env.perc(0.001, (decay * 0.25).max(0.04), 1, -6), doneAction: 2);
      var body   = (SinOsc.ar(f) + (Pulse.ar(f * 2, 0.3) * 0.08)) * aenv;
      var rattle = BPF.ar(WhiteNoise.ar, 1800, 0.5) * EnvGen.ar(Env.perc(0.001, 0.02)) * 0.4;
      var sig    = ((body * 1.3) + rattle).tanh * 0.85;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // dusty: a boom-bap kick, saturated, a little crushed and dulled
    SynthDef(\brk_kick_dusty, {
      arg out, amp=0.8, tune=33, decay=0.5, drive=0, bend=1;
      var base  = (tune + 2).midicps;
      var pe    = EnvGen.ar(Env([1, 0], [0.04], [-5]));
      var f     = base * (1 + (pe * (2.5 * bend.clip(0, 4))));
      var aenv  = EnvGen.ar(Env.perc(0.002, decay * 0.9, 1, -4), doneAction: 2);
      var body  = SinOsc.ar(f) * aenv;
      var knock = BPF.ar(WhiteNoise.ar, 180, 0.6) * EnvGen.ar(Env.perc(0.001, 0.05)) * 1.2;
      var sig   = (((body * 1.8) + knock) * 1.5).tanh;
      sig = LPF.ar(Latch.ar(sig, Impulse.ar(22050)).round(0.02), 3500) * 0.9;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // tribal: a big frame drum, a long low skin
    SynthDef(\brk_kick_tribal, {
      arg out, amp=0.8, tune=31, decay=0.6, drive=0, bend=1;
      var base = (tune + 4).midicps;
      var pe   = EnvGen.ar(Env([1, 0], [0.05], [-4]));
      var f    = base * (1 + (pe * (1.2 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env.perc(0.003, decay * 1.6, 1, -4), doneAction: 2);
      var body = (SinOsc.ar(f) + ((SinOsc.ar(f * 1.51) * 0.3) * EnvGen.ar(Env.perc(0.001, decay * 0.4)))) * aenv;
      var skin = LPF.ar(WhiteNoise.ar, 900) * EnvGen.ar(Env.perc(0.002, 0.06)) * 0.9;
      var sig  = ((body * 1.2) + skin).tanh * 0.9;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // 808 long: a trap 808, a long tuned boom that sags in pitch as it rings
    SynthDef(\brk_kick_808long, {
      arg out, amp=0.8, tune=31, decay=0.8, drive=0, bend=1;
      var base = tune.midicps;
      var pe   = EnvGen.ar(Env([1, 0], [0.12], [-4]));
      var sag  = EnvGen.ar(Env([1, 0.94], [decay * 2], [-2]));
      var f    = base * (1 + (pe * (0.6 * bend.clip(0, 4)))) * sag;
      var aenv = EnvGen.ar(Env([0, 1, 0.85, 0], [0.002, decay * 1.2, decay * 1.6], [0, -0.5, -3]), doneAction: 2);
      var clk  = HPF.ar(WhiteNoise.ar, 3000) * EnvGen.ar(Env.perc(0.0003, 0.004)) * 0.3;
      var sig  = (((SinOsc.ar(f) * aenv) * 1.6) + clk).tanh * 0.95;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // simmons: an 80s electronic drum, a fast sine sweep over a noise puff
    SynthDef(\brk_kick_simmons, {
      arg out, amp=0.8, tune=33, decay=0.45, drive=0, bend=1;
      var base = (tune + 7).midicps;
      var f    = base * EnvGen.ar(Env([1 + (2 * bend.clip(0, 4)), 1], [0.08], [-4]));
      var aenv = EnvGen.ar(Env.perc(0.001, decay * 0.7, 1, -5), doneAction: 2);
      var nz   = BPF.ar(WhiteNoise.ar, 1200, 0.8) * EnvGen.ar(Env.perc(0.001, 0.05)) * 0.6;
      var sig  = ((SinOsc.ar(f) * aenv * 1.3) + nz).tanh * 0.9;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // hardstyle: a distorted, pitched kick whose tail rings on as a tone
    SynthDef(\brk_kick_hardstyle, {
      arg out, amp=0.8, tune=33, decay=0.5, drive=0, bend=1;
      var base = tune.midicps;
      var pe   = EnvGen.ar(Env([1, 0], [0.05], [-6]));
      var f    = base * (1 + (pe * (6 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env([0, 1, 0.7, 0], [0.002, decay * 0.6, decay * 0.9], [0, -1, -4]), doneAction: 2);
      var clk  = HPF.ar(WhiteNoise.ar, 2500) * EnvGen.ar(Env.perc(0.0003, 0.006)) * 0.5;
      var body = SinOsc.ar(f) + (SinOsc.ar(f * 2.01) * 0.25);
      var sig  = (((body * aenv) * 6).tanh * 0.6) + clk;
      sig = LPF.ar(sig, 6000);
      sig = (kdrive.value(sig, (drive + 0.4).clip(0, 1)) * 0.8) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // trance: tight and punchy, a deep short body and a hard click on top
    SynthDef(\brk_kick_trance, {
      arg out, amp=0.8, tune=33, decay=0.35, drive=0, bend=1;
      var base = tune.midicps;
      var pe   = EnvGen.ar(Env([1, 0], [0.03], [-7]));
      var f    = base * (1 + (pe * (4 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env.perc(0.001, decay * 0.8, 1, -6), doneAction: 2);
      var clk  = BPF.ar(WhiteNoise.ar, 5000, 0.8) * EnvGen.ar(Env.perc(0.0002, 0.008)) * 0.9;
      var sig  = (((SinOsc.ar(f) * aenv) * 1.6) + clk).tanh * 0.9;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // gqom: a hollow booming kick, a resonant low tom under a soft attack
    SynthDef(\brk_kick_gqom, {
      arg out, amp=0.8, tune=31, decay=0.6, drive=0, bend=1;
      var base = tune.midicps;
      var pe   = EnvGen.ar(Env([1, 0], [0.12], [-3]));
      var f    = base * (1 + (pe * (1.5 * bend.clip(0, 4))));
      var aenv = EnvGen.ar(Env.perc(0.004, decay * 1.6, 1, -3), doneAction: 2);
      var hol  = Ringz.ar(Impulse.ar(0) * 0.08, base * 2.7, decay * 0.4);
      var sig  = (((SinOsc.ar(f) * aenv) * 1.4) + hol).tanh * 0.9;
      sig = kdrive.value(sig, drive) * amp;
      Out.ar(out, sig ! 2);
    }).add;

    // ---------------------------------------------------------------- snare
    // all snares: tune = midi of the body, decay = s, tone 0..1 brightness,
    // bend = semitones glided across the hit

    // 909: tuned two-sine body + bright noise
    SynthDef(\brk_snare_909, {
      arg out, echoOut, verbOut, amp=0.8, tune=52, decay=0.18, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.02, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = tune.midicps * gl * EnvGen.ar(Env([1.5, 1], [0.025], [-4]));
      var benv = EnvGen.ar(Env.perc(0.001, (len * 0.5).max(0.03), 1, -5));
      var body = (SinOsc.ar(f) + (SinOsc.ar(f * 1.62) * 0.5)) * benv;
      var nenv = EnvGen.ar(Env.perc(0.001, len, 1, -4), doneAction: 2);
      var w    = WhiteNoise.ar;
      var nz   = (BPF.ar(w, tn.linexp(0, 1, 1800, 6000), 1.2) * 1.4) + (HPF.ar(w, tn.linexp(0, 1, 3000, 9000)) * (0.25 + (tn * 0.5)));
      var sig  = (((body * 0.7) + (nz * nenv)) * 1.2).tanh * 0.85 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // drill: tight, strongly pitched, crisp, very short (made for 64th
    // ratchets with a rising pitch)
    SynthDef(\brk_snare_drill, {
      arg out, echoOut, verbOut, amp=0.8, tune=62, decay=0.12, tone=0.6, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.01, 1);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len * 0.8], [-1]))).midiratio;
      var f    = tune.midicps * gl * EnvGen.ar(Env([2.2, 1], [0.006], [-6]));
      var benv = EnvGen.ar(Env.perc(0.0005, len * 0.7, 1, -6));
      var body = ((SinOsc.ar(f) + (LFTri.ar(f * 1.5) * 0.25)) * benv * 2).tanh;
      var nenv = EnvGen.ar(Env.perc(0.0005, len * 0.55, 1, -7));
      var nz   = HPF.ar(WhiteNoise.ar, tn.linexp(0, 1, 2500, 7500)) * nenv * (0.5 + (tn * 0.6));
      var done = Line.kr(0, 1, len + 0.02, doneAction: 2);
      var sig  = ((body * 0.75) + nz).tanh * 0.85 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // 808: two sine bodies + filtered noise
    SynthDef(\brk_snare_808, {
      arg out, echoOut, verbOut, amp=0.8, tune=54, decay=0.22, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.02, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = tune.midicps * gl * EnvGen.ar(Env([1.25, 1], [0.015], [-4]));
      var body = (SinOsc.ar(f) * EnvGen.ar(Env.perc(0.001, len * 0.6, 1, -5)))
                 + (SinOsc.ar(f * 1.78) * EnvGen.ar(Env.perc(0.001, len * 0.35, 1, -6)) * 0.6);
      var nenv = EnvGen.ar(Env.perc(0.002, len, 1, -5), doneAction: 2);
      var nz   = LPF.ar(HPF.ar(WhiteNoise.ar, 1500), tn.linexp(0, 1, 4000, 13000)) * nenv * 0.9;
      var sig  = (((body * 0.8) + nz) * 1.1).tanh * 0.85 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // noise: a crushed, band-passed, distorted burst
    SynthDef(\brk_snare_noise, {
      arg out, echoOut, verbOut, amp=0.8, tune=55, decay=0.2, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.02, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = tune.midicps * gl;
      var env  = EnvGen.ar(Env.perc(0.001, len, 1, -3), doneAction: 2);
      var nz   = Latch.ar(WhiteNoise.ar, Impulse.ar(tn.linexp(0, 1, 3000, 18000)));
      var body = SinOsc.ar(f) * EnvGen.ar(Env.perc(0.001, 0.04, 1, -5)) * 0.4;
      var sig;
      nz = (nz * 4).round(1) * 0.25;
      nz = (BPF.ar(nz, (f * 8).clip(200, 12000), 0.9) * 2) + (HPF.ar(nz, 6000) * 0.3);
      sig = (((nz * 3).tanh * env) + body).tanh * 0.85 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;


    // acoustic: a tuned shell, a stick on the head and rattling snare wires
    SynthDef(\brk_snare_acoustic, {
      arg out, echoOut, verbOut, amp=0.8, tune=52, decay=0.18, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn    = tone.clip(0, 1);
      var len   = decay.clip(0.02, 2);
      var gl    = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f     = tune.midicps * gl * EnvGen.ar(Env([1.15, 1], [0.01], [-4]));
      var benv  = EnvGen.ar(Env.perc(0.0008, (len * 0.4).max(0.03), 1, -5));
      var body  = (SinOsc.ar(f) + (SinOsc.ar(f * 1.59) * 0.45) + (SinOsc.ar(f * 2.14) * 0.25)) * benv;
      var stick = HPF.ar(WhiteNoise.ar, 4000) * EnvGen.ar(Env.perc(0.0002, 0.004)) * 1.2;
      var wenv  = EnvGen.ar(Env.perc(0.003, len * 1.3, 1, -4), doneAction: 2);
      var w     = WhiteNoise.ar;
      var wires = ((BPF.ar(w, tn.linexp(0, 1, 3000, 7000), 0.9) * 1.6) + (HPF.ar(w, 8000) * (0.15 + (tn * 0.3))))
                  * (1 + (LFNoise1.ar(90) * 0.3));
      var sig   = (((body * 0.8) + stick + (wires * wenv)) * 1.1).tanh * 0.85 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // jungle: a bright, tuned-up snare with a ringing ping in it
    SynthDef(\brk_snare_jungle, {
      arg out, echoOut, verbOut, amp=0.8, tune=60, decay=0.16, tone=0.6, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.02, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = tune.midicps * gl * EnvGen.ar(Env([1.8, 1], [0.008], [-6]));
      var benv = EnvGen.ar(Env.perc(0.0005, (len * 0.45).max(0.03), 1, -5));
      var body = ((SinOsc.ar(f) + (SinOsc.ar(f * 2.13) * 0.35)) * benv * 1.5).tanh;
      var nenv = EnvGen.ar(Env.perc(0.0008, len, 1, -5), doneAction: 2);
      var w    = WhiteNoise.ar;
      var nz   = (BPF.ar(w, tn.linexp(0, 1, 2500, 6500), 0.7) * 1.5) + (HPF.ar(w, tn.linexp(0, 1, 5000, 10000)) * 0.6);
      var ping = BPF.ar(w, (f * 3.1).clip(100, 12000), 0.05) * 3 * benv;
      var sig  = (((body * 0.7) + (nz * nenv) + ping) * 1.3).tanh * 0.85 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // metal: ring-modulated plates and noise, distorted and stepped
    SynthDef(\brk_snare_metal, {
      arg out, echoOut, verbOut, amp=0.8, tune=55, decay=0.2, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn    = tone.clip(0, 1);
      var len   = decay.clip(0.02, 2);
      var gl    = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f     = tune.midicps * gl;
      var env   = EnvGen.ar(Env.perc(0.0008, len, 1, -4), doneAction: 2);
      var penv  = EnvGen.ar(Env.perc(0.0005, len * 0.6, 1, -6));
      var plate = (SinOsc.ar(f) * SinOsc.ar(f * 2.76)) + ((SinOsc.ar(f * 4.07) * SinOsc.ar(f * 6.21)) * 0.6);
      var nz    = HPF.ar(WhiteNoise.ar, tn.linexp(0, 1, 1500, 5000));
      var sig   = (((plate * penv * 2) + (nz * env)) * 3).tanh;
      sig = (sig.round(0.125) * env * 0.75) * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // minipops: a short dull noise burst through a band-pass, a soft ping
    SynthDef(\brk_snare_minipops, {
      arg out, echoOut, verbOut, amp=0.8, tune=58, decay=0.12, tone=0.3, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.02, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = tune.midicps * gl;
      var env  = EnvGen.ar(Env([0, 1, 0], [0.002, len], [0, -5]), doneAction: 2);
      var ping = SinOsc.ar(f) * EnvGen.ar(Env.perc(0.001, 0.025, 1, -5)) * 0.35;
      var nz   = BPF.ar(WhiteNoise.ar, tn.linexp(0, 1, 1200, 4000), 0.8) * 2.2;
      var sig  = (((nz * env) + ping) * 1.2).tanh * 0.8 * amp;
      sends.value(Pan2.ar(LPF.ar(sig, 7000), pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // dubstep: a big snare with a clap layer and a long noise tail
    SynthDef(\brk_snare_dubstep, {
      arg out, echoOut, verbOut, amp=0.8, tune=53, decay=0.25, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn     = tone.clip(0, 1);
      var len    = decay.clip(0.02, 2);
      var gl     = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f      = tune.midicps * gl * EnvGen.ar(Env([1.6, 1], [0.02], [-4]));
      var body   = (SinOsc.ar(f) + (SinOsc.ar(f * 1.47) * 0.4)) * EnvGen.ar(Env.perc(0.001, (len * 0.4).max(0.04), 1, -5));
      var bursts = EnvGen.ar(Env([0, 1, 0.2, 1, 0.2, 1, 0], [0.0008, 0.007, 0.0008, 0.008, 0.0008, len * 1.5],
                     [0, -4, 0, -4, 0, -4]), doneAction: 2);
      var w      = WhiteNoise.ar;
      var nz     = (BPF.ar(w, tn.linexp(0, 1, 1200, 3500), 0.7) * 2) + (HPF.ar(w, 6000) * 0.5);
      var sig    = (((body * 0.9) + (nz * bursts)) * 1.4).tanh * 0.85 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // click: digital, a burst of one-bit noise and a sine blip
    SynthDef(\brk_snare_click, {
      arg out, echoOut, verbOut, amp=0.8, tune=60, decay=0.1, tone=0.7, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.02, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = tune.midicps * gl;
      var env  = EnvGen.ar(Env.perc(0.0005, len * 0.5, 1, -8), doneAction: 2);
      var bits = Latch.ar(WhiteNoise.ar, Impulse.ar(tn.linexp(0, 1, 2000, 12000))).sign * 0.5;
      var blip = SinOsc.ar(f * 4) * EnvGen.ar(Env.perc(0.0002, 0.01));
      var sig  = ((bits * env) + (blip * 0.6)).clip2(1) * 0.75 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // toy: a tiny body and a buzzing rattle
    SynthDef(\brk_snare_toy, {
      arg out, echoOut, verbOut, amp=0.8, tune=62, decay=0.12, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.02, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = (tune + 12).midicps * gl;
      var body = SinOsc.ar(f) * EnvGen.ar(Env.perc(0.0005, 0.03, 1, -5)) * 0.5;
      var env  = EnvGen.ar(Env.perc(0.001, len * 0.7, 1, -5), doneAction: 2);
      var rat  = BPF.ar(WhiteNoise.ar, tn.linexp(0, 1, 3000, 8000), 0.6) * (0.6 + (LFPulse.ar(55) * 0.6));
      var sig  = ((body + (rat * env)) * 1.2).tanh * 0.75 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // dusty: a crunchy lo-fi snare, crushed and dulled
    SynthDef(\brk_snare_dusty, {
      arg out, echoOut, verbOut, amp=0.8, tune=53, decay=0.2, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.02, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = tune.midicps * gl * EnvGen.ar(Env([1.3, 1], [0.015], [-4]));
      var body = (SinOsc.ar(f) + (SinOsc.ar(f * 1.7) * 0.4)) * EnvGen.ar(Env.perc(0.001, (len * 0.4).max(0.03), 1, -5));
      var env  = EnvGen.ar(Env.perc(0.001, len * 1.1, 1, -4), doneAction: 2);
      var nz   = BPF.ar(WhiteNoise.ar, tn.linexp(0, 1, 1500, 4000), 0.9) * 1.8;
      var sig  = (((body * 0.8) + (nz * env)) * 2).tanh;
      sig = LPF.ar(Latch.ar(sig, Impulse.ar(16000)).round(0.03), 5000) * 0.8 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // frame: a hand slap on a frame drum
    SynthDef(\brk_snare_frame, {
      arg out, echoOut, verbOut, amp=0.8, tune=55, decay=0.2, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.02, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = tune.midicps * gl * 0.5;
      var env  = EnvGen.ar(Env.perc(0.001, len * 1.5, 1, -5), doneAction: 2);
      var drum = (SinOsc.ar(f * EnvGen.ar(Env([1.4, 1], [0.02], [-4]))) + (SinOsc.ar(f * 2.3) * 0.3)) * env;
      var slap = BPF.ar(WhiteNoise.ar, tn.linexp(0, 1, 1500, 4500), 0.5) * EnvGen.ar(Env.perc(0.0005, 0.025, 1, -5)) * 2;
      var sig  = ((drum * 0.9) + slap).tanh * 0.8 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // disco: a fat, tight snare with a short room
    SynthDef(\brk_snare_disco, {
      arg out, echoOut, verbOut, amp=0.8, tune=55, decay=0.18, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.02, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = tune.midicps * gl * EnvGen.ar(Env([1.3, 1], [0.012], [-4]));
      var body = (SinOsc.ar(f) + (SinOsc.ar(f * 1.62) * 0.4)) * EnvGen.ar(Env.perc(0.001, (len * 0.35).max(0.03), 1, -5));
      var env  = EnvGen.ar(Env.perc(0.002, len, 1, -4), doneAction: 2);
      var w    = WhiteNoise.ar;
      var nz   = LPF.ar((BPF.ar(w, tn.linexp(0, 1, 2500, 6000), 1.0) * 1.6) + (HPF.ar(w, 7000) * 0.3), 9000);
      var sig  = (((body * 0.9) + (nz * env)) * 1.15).tanh * 0.85 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // simmons: a pitch-swept tone over band-passed noise
    SynthDef(\brk_snare_simmons, {
      arg out, echoOut, verbOut, amp=0.8, tune=57, decay=0.2, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn  = tone.clip(0, 1);
      var len = decay.clip(0.02, 2);
      var gl  = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f   = tune.midicps * gl * EnvGen.ar(Env([2, 1], [0.05], [-4]));
      var env = EnvGen.ar(Env.perc(0.001, len * 1.2, 1, -4), doneAction: 2);
      var sig = ((SinOsc.ar(f) * 0.6) + (BPF.ar(WhiteNoise.ar, tn.linexp(0, 1, 2000, 6000), 1.2) * 1.5)) * env;
      sig = (sig * 1.3).tanh * 0.8 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // ----------------------------------------------------------- clap / rim

    // clap: four analog bursts of band-passed noise, then a tail of `decay`
    // gated: an 80s snare through a big room, the room cut dead by a gate
    SynthDef(\brk_snare_gated, {
      arg out, echoOut, verbOut, amp=0.8, tune=55, decay=0.25, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.05, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = tune.midicps * gl;
      var body = SinOsc.ar(f * EnvGen.ar(Env([1.4, 1], [0.02]))) * EnvGen.ar(Env.perc(0.001, 0.08));
      var w    = WhiteNoise.ar;
      var nz   = BPF.ar(w, tn.linexp(0, 1, 1500, 5000), 0.9) * 1.5;
      var room = CombC.ar(nz * EnvGen.ar(Env.perc(0.001, 0.05)), 0.05, [0.017, 0.023], 0.6).sum * 0.5;
      var gate = EnvGen.ar(Env([0, 1, 1, 0], [0.001, len, 0.02]), doneAction: 2);
      var sig  = (((body * 0.8) + nz + room) * gate * 0.8).tanh * 0.85 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // miami: a tight snare and a clap stacked, the bass-music backbeat
    SynthDef(\brk_snare_miami, {
      arg out, echoOut, verbOut, amp=0.8, tune=54, decay=0.16, tone=0.5, pan=0, bend=0, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var len  = decay.clip(0.02, 2);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [len], [-2]))).midiratio;
      var f    = tune.midicps * gl;
      var body = SinOsc.ar(f * EnvGen.ar(Env([1.6, 1], [0.015]))) * EnvGen.ar(Env.perc(0.001, 0.06));
      var w    = WhiteNoise.ar;
      var cenv = EnvGen.ar(Env([0, 1, 0.2, 1, 0.2, 1, 0], [0.001, 0.008, 0.001, 0.008, 0.001, len], [0, -4, 0, -4, 0, -5]));
      var clap = BPF.ar(w, tn.linexp(0, 1, 900, 2400), 1.1) * cenv * 2;
      var nz   = HPF.ar(w, 4000) * EnvGen.ar(Env.perc(0.001, len * 0.6)) * (0.3 + (tn * 0.5));
      var done = EnvGen.ar(Env.perc(0.001, len + 0.05), doneAction: 2);
      var sig  = (((body * 0.7) + clap + nz) * 1.1).tanh * 0.85 * amp * (done > 0);
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_clap, {
      arg out, echoOut, verbOut, amp=0.8, decay=0.18, tone=0.5, pan=0, echo=0, verb=0;
      var tn = tone.clip(0, 1);
      var bursts = EnvGen.ar(Env([0, 1, 0.15, 1, 0.15, 1, 0.15, 1, 0],
        [0.0008, 0.008, 0.0008, 0.009, 0.0008, 0.011, 0.0008, decay.clip(0.03, 2)],
        [0, -4, 0, -4, 0, -4, 0, -4]), doneAction: 2);
      var w   = WhiteNoise.ar;
      var sig = (BPF.ar(w, tn.linexp(0, 1, 800, 2600), 0.6) * 2.4) + (HPF.ar(w, 5000) * (0.15 + (tn * 0.3)));
      sig = (sig * bursts * 1.2).tanh * 0.8 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // rim: a ringing band-passed click, tune = midi
    SynthDef(\brk_rim, {
      arg out, echoOut, verbOut, amp=0.8, tune=92, pan=0, echo=0, verb=0;
      var f    = tune.midicps.clip(200, 8000);
      var env  = EnvGen.ar(Env.perc(0.0005, 0.05, 1, -8), doneAction: 2);
      var body = BPF.ar(WhiteNoise.ar, f, 0.08) * 5;
      var tick = SinOsc.ar(f * 0.47) * EnvGen.ar(Env.perc(0.0005, 0.02));
      var clk  = HPF.ar(Impulse.ar(0), 2000) * 0.5;
      var sig  = (((body + tick) * env) + clk).tanh * 0.75 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // ---------------------------------------------------------------- hats
    // brk_hat1..10 share args; once the hat counter passes `id` the hat is
    // choked (gate 0, 12 ms release). closed hats get an id nothing reaches

    hatSrc = [
      // analog: six detuned squares, the 808 way
      { |tn|
        var m = Mix([205.3, 304.4, 369.6, 522.7, 540, 800].collect { |f| Pulse.ar(f * 1.0) }) * 0.3;
        HPF.ar(BPF.ar(m, tn.linexp(0, 1, 6500, 11000), 0.6), 6000) * 8
      },
      // metallic: ring-modulated square pairs (606-ish), ringier
      { |tn|
        var m = Mix([[317, 471], [553, 829], [1207, 1741]].collect { |p| Pulse.ar(p[0]) * Pulse.ar(p[1]) }) * 0.4;
        HPF.ar(BPF.ar(m, tn.linexp(0, 1, 7000, 12000), 0.4), 5500) * 7
      },
      // crisp: high-passed white noise
      { |tn|
        var w = WhiteNoise.ar;
        (HPF.ar(w, tn.linexp(0, 1, 5000, 11000)) * 0.85) + (BPF.ar(w, 12000, 0.5) * 0.5)
      },
      // acoustic: a small cymbal, inharmonic partials over a sizzle
      { |tn|
        var sc = tn.linexp(0, 1, 0.8, 1.25);
        var m  = Mix([3150, 4230, 5370, 6890, 8120, 9440].collect { |f| SinOsc.ar(f * sc) }) * 0.12;
        var w  = WhiteNoise.ar;
        (m * 0.7) + (BPF.ar(w, tn.linexp(0, 1, 6000, 10000), 0.8) * 0.9) + (HPF.ar(w, 9000) * 0.3)
      },
      // lofi: sample-and-hold noise, few bits
      { |tn|
        var w = Latch.ar(WhiteNoise.ar, Impulse.ar(tn.linexp(0, 1, 6000, 16000)));
        HPF.ar((w * 3).round(1) * 0.33, 4000) * 0.9
      },
      // minipops: a rhythm box's hissy cymbal, noise through a resonant high-pass
      { |tn|
        var w = WhiteNoise.ar;
        (RHPF.ar(w, tn.linexp(0, 1, 5000, 9000), 0.3) * 0.6) + (BPF.ar(w, 9500, 1.2) * 0.4)
      },
      // dusty: high-passed noise, crushed and dulled
      { |tn|
        var w = HPF.ar(WhiteNoise.ar, tn.linexp(0, 1, 4000, 8000));
        LPF.ar(Latch.ar(w, Impulse.ar(14000)).round(0.125), 9000) * 1.1
      },
      // click: a very high sine burst over a digital tick
      { |tn|
        (SinOsc.ar(tn.linexp(0, 1, 7000, 12000)) * 0.6) + (HPF.ar(Latch.ar(WhiteNoise.ar, Impulse.ar(18000)), 9000) * 0.5)
      },
      // disco: bright and sizzly, a couple of bell partials in it
      { |tn|
        var w = WhiteNoise.ar;
        (BPF.ar(w, tn.linexp(0, 1, 8000, 12000), 0.5) * 1.1) + (HPF.ar(w, 10000) * 0.6)
          + (Mix([5400, 7200].collect { |f| SinOsc.ar(f) }) * 0.05)
      },
      // shaker hat: breathy, a soft attack, the afro / amapiano kind
      { |tn|
        var w = WhiteNoise.ar;
        (BPF.ar(w, tn.linexp(0, 1, 5000, 9000), 0.9) * 1.2) * EnvGen.ar(Env([0.3, 1], [0.012], [2]))
      }
    ];
    hatSrc.do { |src, i|
      SynthDef(("brk_hat" ++ (i + 1)).asSymbol, {
        arg out, echoOut, verbOut, chokeBus, id=1e9, amp=0.8, decay=0.05, tone=0.5, pan=0, echo=0, verb=0;
        var gate = In.kr(chokeBus, 1) <= id;
        var env  = EnvGen.ar(Env.perc(0.0008, decay.clip(0.01, 4), 1, -5), doneAction: 2);
        var chk  = EnvGen.ar(Env.asr(0, 1, 0.012), gate, doneAction: 2);
        var sig  = (src.value(tone.clip(0, 1)) * env * chk * 0.6 * amp).clip2(1);
        sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
      }).add;
    };

    // ride: 808 squares an octave-and-a-bit up, a bell ping on the strike
    SynthDef(\brk_ride, {
      arg out, verbOut, amp=0.8, decay=1.2, tone=0.5, pan=0, verb=0;
      var tn  = tone.clip(0, 1);
      var env = EnvGen.ar(Env.perc(0.002, decay.clip(0.05, 6), 1, -4), doneAction: 2);
      var sq  = Mix([205.3, 304.4, 369.6, 522.7, 540, 800].collect { |f| Pulse.ar(f * 1.7) }) * 0.18;
      var bell = (SinOsc.ar(3240) * SinOsc.ar(5130)) * EnvGen.ar(Env.perc(0.001, 0.25, 1, -5)) * 0.3;
      var sig = (BPF.ar(sq, tn.linexp(0, 1, 4000, 10000), 0.5) + (HPF.ar(sq, 9000) * 0.4) + bell) * env;
      sig = Pan2.ar(sig * 1.8 * amp, pan);
      Out.ar(out, sig);
      Out.ar(verbOut, sig * verb);
    }).add;

    SynthDef(\brk_shaker, {
      arg out, echoOut, verbOut, amp=0.8, decay=0.07, pan=0, echo=0, verb=0;
      var d   = decay.clip(0.01, 2);
      var env = EnvGen.ar(Env([0, 1, 0], [d * 0.35, d * 0.65], [2, -6]), doneAction: 2);
      var sig = BPF.ar(WhiteNoise.ar, 7000, 0.7) + (HPF.ar(WhiteNoise.ar, 11000) * 0.4);
      sends.value(Pan2.ar(sig * env * 0.8 * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // tom: pitched sine thump with a skin, a pitch drop, and `bend`
    // semitones glided over the decay
    SynthDef(\brk_tom, {
      arg out, echoOut, verbOut, amp=0.8, freq=110, decay=0.3, pan=0, bend=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var d    = decay.clip(0.02, 4);
      var gl   = (bend * EnvGen.ar(Env([0, 1], [d], [-2]))).midiratio;
      var f    = freq.clip(20, 4000) * gl * EnvGen.ar(Env([1.7, 1], [0.035], [-3]));
      var env  = EnvGen.ar(Env.perc(0.002, d, 1, -5), doneAction: 2);
      var skin = BPF.ar(WhiteNoise.ar, f * 4, 0.4) * EnvGen.ar(Env.perc(0.0005, 0.012)) * (0.15 + (tn * 1.2));
      var sig  = (((SinOsc.ar(f) * (0.9 + (tn * 2.2))).tanh * (1.1 - (tn * 0.3))) + skin) * env * 0.8 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // ---------------------------------------------------------------- perc
    // brk_perc1..21 share args: freq (hz), decay, pan

    SynthDef(\brk_perc1, {   // conga
      arg out, echoOut, verbOut, amp=0.8, freq=220, decay=0.3, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f    = freq.clip(30, 4000);
      var env  = EnvGen.ar(Env.perc(0.001, decay.clip(0.02, 3), 1, -5), doneAction: 2);
      var body = SinOsc.ar(f * EnvGen.ar(Env([1.3, 1], [0.02], [-3])));
      var slap = Resonz.ar(WhiteNoise.ar, f * 2.6, 0.3) * EnvGen.ar(Env.perc(0.0005, 0.012)) * (0.5 + (tn * 3));
      var sig  = (((body * env) + slap) * 1.2).tanh * 0.8 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc2, {   // bongo: higher, shorter, more slap
      arg out, echoOut, verbOut, amp=0.8, freq=400, decay=0.18, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f    = freq.clip(30, 6000);
      var env  = EnvGen.ar(Env.perc(0.0008, (decay * 0.6).clip(0.015, 2), 1, -6), doneAction: 2);
      var pd   = EnvGen.ar(Env([1.5, 1], [0.012], [-4]));
      var body = SinOsc.ar(f * pd) + (SinOsc.ar(f * pd * 1.52) * 0.2);
      var slap = Resonz.ar(WhiteNoise.ar, f * 3.4, 0.25) * EnvGen.ar(Env.perc(0.0003, 0.008)) * (0.6 + (tn * 3.8));
      var sig  = (((body * env) + slap) * 1.3).tanh * 0.75 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc3, {   // cowbell: two detuned squares through a band-pass
      arg out, echoOut, verbOut, amp=0.8, freq=540, decay=0.25, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f   = freq.clip(60, 4000);
      var env = EnvGen.ar(Env([0, 1, 0.3, 0], [0.001, 0.03, decay.clip(0.02, 3)], [0, -3, -4]), doneAction: 2);
      var sig = (Pulse.ar(f) + Pulse.ar(f * 1.48)) * 0.5;
      sig = BPF.ar(sig, f * (0.9 + (tn * 1.2)), 0.9 - (tn * 0.6)) * 2.2;
      sends.value(Pan2.ar((sig * env * 0.9 * amp).clip2(1), pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc4, {   // clave: a ringing resonator on a click
      arg out, echoOut, verbOut, amp=0.8, freq=2500, decay=0.2, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f   = freq.clip(200, 8000);
      var exc = Impulse.ar(0) + (WhiteNoise.ar * EnvGen.ar(Env.perc(0.0002, 0.002)) * 0.3);
      var sig = Ringz.ar(exc, [f, f * 2.57], [decay.clip(0.01, 2) * 0.35, decay.clip(0.01, 2) * 0.1]);
      sig = Mix(sig * [1, 0.05 + (tn * 0.6)]) * 0.9;
      DetectSilence.ar(sig, 0.0005, 0.05, doneAction: 2);
      sends.value(Pan2.ar(sig.tanh * 0.85 * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc5, {   // acid: a resonant saw squelch at `freq`, 303-ish
      arg out, echoOut, verbOut, amp=0.8, freq=110, decay=0.25, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f    = freq.clip(20, 2000);
      var d    = decay.clip(0.03, 3);
      var env  = EnvGen.ar(Env([0, 1, 0.8, 0], [0.002, d * 0.6, 0.04], [0, -1, -4]), doneAction: 2);
      var fenv = EnvGen.ar(Env.perc(0.001, d * 0.5, 1, -4));
      var sig  = Saw.ar(f) + (Pulse.ar(f, 0.5) * 0.2);
      sig = RLPF.ar(sig, (f * (1.5 + (fenv * (4 + (tn * 20))))).clip(60, 12000), tn.linexp(0, 1, 0.35, 0.05));
      sig = (sig * 1.6).tanh * env * 0.75 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;


    SynthDef(\brk_perc6, {   // metal: a struck pipe, inharmonic FM
      arg out, echoOut, verbOut, amp=0.8, freq=440, decay=0.4, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f    = freq.clip(60, 6000);
      var d    = decay.clip(0.03, 4);
      var env  = EnvGen.ar(Env.perc(0.0005, d * 2, 1, -5), doneAction: 2);
      var ienv = EnvGen.ar(Env.perc(0.0005, d * 0.4, 1, -4));
      var mod  = SinOsc.ar(f * 1.414) * f * ((0.5 + (ienv * 3)) * (0.2 + (tn * 1.6)));
      var sig  = (SinOsc.ar(f + mod) + ((SinOsc.ar(f * 2.76) * 0.3) * ienv)) * env * 0.5;
      sends.value(Pan2.ar(sig.tanh * 0.9 * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc7, {   // log: a wooden log drum, mallet click and a woody overtone
      arg out, echoOut, verbOut, amp=0.8, freq=220, decay=0.3, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f   = freq.clip(60, 3000);
      var d   = decay.clip(0.03, 2);
      var env = EnvGen.ar(Env.perc(0.0008, d, 1, -6), doneAction: 2);
      var p2  = SinOsc.ar(f * 3.93) * EnvGen.ar(Env.perc(0.0005, d * 0.25, 1, -6)) * (tn * 0.7);
      var clk = BPF.ar(WhiteNoise.ar, (f * 6).clip(100, 12000), 0.5) * EnvGen.ar(Env.perc(0.0003, 0.006)) * 0.8;
      var sig = (((SinOsc.ar(f) * env) + p2 + clk) * 1.1).tanh * 0.8 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc8, {   // plink: a prepared-piano string, a bolt buzzing on it
      arg out, echoOut, verbOut, amp=0.8, freq=440, decay=0.4, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f     = freq.clip(60, 4000);
      var d     = decay.clip(0.03, 3);
      var env   = EnvGen.ar(Env.perc(0.001, d * 1.5, 1, -6), doneAction: 2);
      var parts = Mix([[1, 1], [2.02, 0.5], [3.17, 0.35], [4.53, 0.2], [6.8, 0.12]].collect { |p| SinOsc.ar(f * p[0]) * (p[1] * (if(p[0] > 1.5, { 0.3 + (tn * 1.4) }, { 1 }))) });
      var buzz  = ((SinOsc.ar(f * 0.5) * EnvGen.ar(Env.perc(0.001, d * 0.3)) * 4).clip2(1)) * (tn * 0.3);
      var ham   = LPF.ar(WhiteNoise.ar, 2000) * EnvGen.ar(Env.perc(0.0005, 0.01)) * 0.4;
      var sig   = (((parts * env) + buzz + ham) * 0.6).tanh * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc9, {   // guiro: a scrape, a fast run of band-passed clicks
      arg out, echoOut, verbOut, amp=0.8, freq=2800, decay=0.12, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var d   = decay.clip(0.03, 1);
      var env = EnvGen.ar(Env([0, 1, 0.7, 0], [0.004, d * 0.85, 0.01], [0, 0, -4]), doneAction: 2);
      var rt  = EnvGen.ar(Env([38, 62], [d], [1])) * (0.6 + (tn * 0.8));
      var clk = Decay2.ar(Impulse.ar(rt), 0.0003, 0.004) * WhiteNoise.ar;
      var sig = BPF.ar(clk, freq.clip(800, 8000) * (0.6 + (tn * 0.8)), 0.6) * 6;
      sends.value(Pan2.ar((sig * env * 0.8 * amp).clip2(1), pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc10, {   // tambourine: jingles, a cluster of short metallic rings over a shake
      arg out, echoOut, verbOut, amp=0.8, freq=6000, decay=0.2, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var d   = decay.clip(0.03, 2);
      var env = EnvGen.ar(Env([0, 1, 0], [0.003, d], [0, -5]), doneAction: 2);
      var w   = WhiteNoise.ar;
      var jin = Mix([4700, 6100, 7350, 8900].collect { |f| BPF.ar(w, f * (0.75 + (tn * 0.5)), 0.04) }) * 4;
      var sig = (jin + (HPF.ar(w, 9000) * 0.3)) * env * (1 + (LFNoise1.ar(40) * 0.3));
      sends.value(Pan2.ar((sig * 0.7 * amp).clip2(1), pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc11, {   // music box: a tine, a bright partial and a pin's tick
      arg out, echoOut, verbOut, amp=0.8, freq=1046, decay=0.5, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f   = freq.clip(100, 6000);
      var d   = decay.clip(0.05, 4);
      var env = EnvGen.ar(Env.perc(0.001, d * 2.5, 1, -5), doneAction: 2);
      var sig = (SinOsc.ar(f) + ((SinOsc.ar(f * 5.4) * (tn * 0.5)) * EnvGen.ar(Env.perc(0.001, d * 0.3)))) * env * 0.5;
      sig = sig + (HPF.ar(WhiteNoise.ar, 5000) * EnvGen.ar(Env.perc(0.0002, 0.003)) * 0.3);
      sends.value(Pan2.ar(sig * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc12, {   // squeak: a toy's rising squeal with a wobble
      arg out, echoOut, verbOut, amp=0.8, freq=660, decay=0.25, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f   = freq.clip(200, 4000);
      var d   = decay.clip(0.05, 1);
      var env = EnvGen.ar(Env([0, 1, 0.8, 0], [0.01, d * 0.6, d * 0.3], [0, 0, -4]), doneAction: 2);
      var fm  = f * EnvGen.ar(Env([0.7, 1.3], [d], [2])) * (1 + (SinOsc.ar(10 + (tn * 16)) * (tn * 0.06)));
      var sig = (SinOsc.ar(fm) + (SinOsc.ar(fm * 2) * (tn * 0.4))) * env * 0.45;
      sends.value(Pan2.ar(sig * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc13, {   // talking drum: a pitch that rises under the hand and falls back
      arg out, echoOut, verbOut, amp=0.8, freq=147, decay=0.4, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f    = freq.clip(40, 1500);
      var d    = decay.clip(0.05, 2);
      var env  = EnvGen.ar(Env.perc(0.001, d, 1, -4), doneAction: 2);
      var pb   = EnvGen.ar(Env([1, 1 + (0.1 + (tn * 0.8)), 1 + (0.05 + (tn * 0.35))], [d * 0.25, d * 0.6], [2, -2]));
      var body = SinOsc.ar(f * pb) * env;
      var slap = BPF.ar(WhiteNoise.ar, (f * 5).clip(100, 12000), 0.4) * EnvGen.ar(Env.perc(0.0005, 0.01)) * 1.5;
      var sig  = ((body * 1.2) + slap).tanh * 0.75 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc14, {   // wobble: a bass stab, a low-pass swept by an lfo
      arg out, echoOut, verbOut, amp=0.8, freq=55, decay=0.35, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f   = freq.clip(30, 500);
      var d   = decay.clip(0.05, 2);
      var env = EnvGen.ar(Env([0, 1, 1, 0], [0.005, d, 0.03]), doneAction: 2);
      var lfo = LFTri.ar(4.0 / d.max(0.1)).range(0, 1);
      var sig = Saw.ar(f) + Saw.ar(f * 1.005);
      sig = RLPF.ar(sig, (f * (1.5 + (lfo * (2 + (tn * 20))))).clip(60, 8000), tn.linexp(0, 1, 0.5, 0.1));
      sig = (sig * 1.5).tanh * env * 0.6 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc15, {   // crackle: a burst of vinyl crackle, freq = how dense
      arg out, echoOut, verbOut, amp=0.8, freq=80, decay=0.3, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var d    = decay.clip(0.05, 1);
      var env  = EnvGen.ar(Env.perc(0.001, d, 1, -3), doneAction: 2);
      var pops = Decay.ar(Dust.ar(freq.clip(20, 400)), 0.002) * WhiteNoise.ar;
      var sig  = (HPF.ar(pops, tn.linexp(0, 1, 150, 3000)) * 3 * env * amp).clip2(1);
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc16, {   // vox: a sung formant chop
      arg out, echoOut, verbOut, amp=0.8, freq=220, decay=0.2, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f   = freq.clip(60, 1200);
      var d   = decay.clip(0.03, 1);
      var env = EnvGen.ar(Env([0, 1, 0.7, 0], [0.005, d * 0.6, d * 0.3], [0, -1, -4]), doneAction: 2);
      var src = Saw.ar(f * (1 + (SinOsc.ar(5) * 0.01)));
      var fm  = EnvGen.ar(Env([0.8, 1.2], [d], [0])) * (0.65 + (tn * 0.7));
      var sig = (BPF.ar(src, 700 * fm, 0.15) + (BPF.ar(src, 1200 * fm, 0.12) * 0.7)) + (BPF.ar(src, 2600 * fm, 0.1) * 0.3);
      sig = (sig * 3).tanh * env * 1.0 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc17, {   // syntom: an 80s electronic tom, a sine sweeping down
      arg out, echoOut, verbOut, amp=0.8, freq=147, decay=0.35, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f   = freq.clip(40, 1500);
      var d   = decay.clip(0.05, 2);
      var env = EnvGen.ar(Env.perc(0.001, d, 1, -4), doneAction: 2);
      var sw  = EnvGen.ar(Env([1.2 + (tn * 2.2), 1], [d * 0.5], [-3]));
      var nz  = BPF.ar(WhiteNoise.ar, (f * 4).clip(100, 12000), 0.5) * EnvGen.ar(Env.perc(0.001, 0.03)) * 0.8;
      var sig = (((SinOsc.ar(f * sw) * 1.2).tanh + nz) * env) * 0.7 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc18, {   // log drum: amapiano's bass, a sine that drops into a growl
      arg out, echoOut, verbOut, amp=0.8, freq=55, decay=0.45, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f    = freq.clip(25, 800);
      var d    = decay.clip(0.05, 3);
      var env  = EnvGen.ar(Env([0, 1, 0.6, 0], [0.003, d * 0.4, d * 0.8], [0, -1, -4]), doneAction: 2);
      var pe   = EnvGen.ar(Env([1.5 + (tn * 0.8), 1], [0.05 + (tn * 0.1)], [-4]));
      var sig  = SinOsc.ar(f * pe) + (SinOsc.ar(f * 2 * pe) * (0.15 + (tn * 0.3)));
      var thk  = BPF.ar(WhiteNoise.ar, (f * 8).clip(100, 8000), 0.6) * EnvGen.ar(Env.perc(0.0005, 0.01)) * 0.6;
      sig = (((sig * (1.2 + (tn * 3))).tanh * 0.75) + thk) * env * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc19, {   // bed squeak: jersey club's spring, a rising squeal through a formant
      arg out, echoOut, verbOut, amp=0.8, freq=600, decay=0.15, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f    = freq.clip(150, 3000);
      var d    = decay.clip(0.04, 1);
      var env  = EnvGen.ar(Env([0, 1, 0], [d * 0.3, d * 0.7], [1, -3]), doneAction: 2);
      var sw   = EnvGen.ar(Env([0.8, 1.2 + (tn * 0.6), 1], [d * 0.4, d * 0.6], [2, -2]));
      var src  = Pulse.ar(f * sw, 0.3);
      var sig  = (BPF.ar(src, f * 2.5 * sw, 0.3) * 2) + (BPF.ar(src, f * 4.5 * sw, 0.2) * tn);
      sig = (sig * 1.5).tanh * env * 0.6 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc20, {   // tamborzao: baile funk's tuned hand drum, a deep skin and a slap
      arg out, echoOut, verbOut, amp=0.8, freq=110, decay=0.25, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f    = freq.clip(40, 1200);
      var d    = decay.clip(0.03, 2);
      var env  = EnvGen.ar(Env.perc(0.001, d, 1, -5), doneAction: 2);
      var body = SinOsc.ar(f * EnvGen.ar(Env([1.5, 1], [0.03], [-4]))) * env;
      var slap = BPF.ar(WhiteNoise.ar, (f * 6).clip(200, 9000), 0.5) * EnvGen.ar(Env.perc(0.0005, 0.02 + (tn * 0.03))) * (0.4 + (tn * 2));
      var sig  = ((body * 1.3) + slap).tanh * 0.8 * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_perc21, {   // phonk bell: an 808 cowbell, tuned, pushed through drive
      arg out, echoOut, verbOut, amp=0.8, freq=540, decay=0.3, pan=0, tone=0.5, echo=0, verb=0;
      var tn   = tone.clip(0, 1);
      var f    = freq.clip(100, 3000);
      var d    = decay.clip(0.03, 2);
      var env  = EnvGen.ar(Env([0, 1, 0.4, 0], [0.001, 0.03, d], [0, -2, -4]), doneAction: 2);
      var sq   = Pulse.ar(f) + Pulse.ar(f * 1.48);
      var sig  = BPF.ar(sq, f * 1.7, 0.8) * 1.5;
      sig = ((sig * (1 + (tn * 6))).tanh * (0.7 - (tn * 0.2))) * env * amp;
      sends.value(Pan2.ar(sig, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // ---------------------------------------------------------------- ticks
    // brk_tick1..8 share args: freq, pan

    SynthDef(\brk_tick1, {   // click
      arg out, echoOut, verbOut, amp=0.8, freq=3000, pan=0, echo=0, verb=0;
      var sig = RHPF.ar(Impulse.ar(0) * 4, freq.clip(800, 12000), 0.05);
      DetectSilence.ar(sig, 0.0005, 0.02, doneAction: 2);
      sends.value(Pan2.ar(sig.clip2(1) * 0.7 * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_tick2, {   // blip
      arg out, echoOut, verbOut, amp=0.8, freq=3000, pan=0, echo=0, verb=0;
      var env = EnvGen.ar(Env.linen(0.0005, 0.012, 0.004), doneAction: 2);
      sends.value(Pan2.ar(SinOsc.ar(freq.clip(200, 12000)) * env * 0.55 * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_tick3, {   // crush: sample-rate + bit crushed noise
      arg out, echoOut, verbOut, amp=0.8, freq=3000, pan=0, echo=0, verb=0;
      var env = EnvGen.ar(Env.linen(0.0005, 0.025, 0.005), doneAction: 2);
      var sig = Latch.ar(WhiteNoise.ar, Impulse.ar(freq.clip(400, 8000)));
      sig = (sig * 4).round(1) * 0.25;
      sends.value(Pan2.ar(sig * env * 0.6 * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_tick4, {   // ring: ring-modulated sines
      arg out, echoOut, verbOut, amp=0.8, freq=3000, pan=0, echo=0, verb=0;
      var f   = freq.clip(100, 10000);
      var env = EnvGen.ar(Env.perc(0.0005, 0.045, 1, -6), doneAction: 2);
      var sig = SinOsc.ar(f) * SinOsc.ar(f * 1.414);
      sends.value(Pan2.ar(sig * env * 0.6 * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_tick5, {   // chirp: very short FM with a fast pitch fall
      arg out, echoOut, verbOut, amp=0.8, freq=3000, pan=0, echo=0, verb=0;
      var f   = freq.clip(100, 10000);
      var fc  = EnvGen.ar(Env([f * 2.5, f * 0.4], [0.03], \exp));
      var ie  = EnvGen.ar(Env.perc(0.0003, 0.02, 1, -4));
      var env = EnvGen.ar(Env.perc(0.0003, 0.035, 1, -6), doneAction: 2);
      var sig = SinOsc.ar(fc + (SinOsc.ar(fc * 1.5) * fc * 2 * ie));
      sends.value(Pan2.ar(sig * env * 0.55 * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_tick6, {   // zap: fast downward sine sweep
      arg out, echoOut, verbOut, amp=0.8, freq=3000, pan=0, echo=0, verb=0;
      var f   = EnvGen.ar(Env([freq.clip(200, 12000), 40], [0.06], \exp));
      var env = EnvGen.ar(Env.perc(0.0005, 0.07, 1, -4), doneAction: 2);
      sends.value(Pan2.ar(SinOsc.ar(f) * env * 0.6 * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_tick7, {   // error: a stuttering digital fault, random pitches
      arg out, echoOut, verbOut, amp=0.8, freq=3000, pan=0, echo=0, verb=0;
      var env = EnvGen.ar(Env.linen(0.0005, 0.04, 0.005), doneAction: 2);
      var f   = TExpRand.ar(300, freq.clip(400, 10000), Impulse.ar(150));
      sends.value(Pan2.ar(Pulse.ar(f) * env * 0.4 * amp, pan), out, echoOut, verbOut, echo, verb);
    }).add;

    SynthDef(\brk_tick8, {   // pop: a vinyl pop
      arg out, echoOut, verbOut, amp=0.8, freq=3000, pan=0, echo=0, verb=0;
      var env = EnvGen.ar(Env.perc(0.0002, 0.02), doneAction: 2);
      var sig = LPF.ar(Decay2.ar(Impulse.ar(0), 0.0002, 0.003) * WhiteNoise.ar * 4, freq.clip(500, 6000));
      sends.value(Pan2.ar((sig * env * amp).clip2(1), pan), out, echoOut, verbOut, echo, verb);
    }).add;

    // ---------------------------------------------------------------- break
    // one def per channel count: from pos (0..1) for len s at rate
    // (negative = backwards), 2 ms in / 4 ms out; once the slice counter
    // passes `id` (a newer slice started) it releases in 3 ms

    [1, 2].do { |nc|
      SynthDef(("brk_slice" ++ nc).asSymbol, {
        arg out, echoOut, verbOut, chokeBus, id=1e9, buf, amp=0.8, pos=0, len=0.25, rate=1, pan=0, echo=0, verb=0;
        var gate = In.kr(chokeBus, 1) <= id;
        var l   = len.clip(0.008, 30);
        var env = EnvGen.ar(Env([0, 1, 1, 0], [0.002, l - 0.006, 0.004]), doneAction: 2);
        var chk = EnvGen.ar(Env.asr(0, 1, 0.003), gate, doneAction: 2);
        var sig = PlayBuf.ar(nc, buf, rate * BufRateScale.kr(buf),
          startPos: pos.clip(0, 1) * (BufFrames.kr(buf) - 1), loop: 0);
        sig = if(nc == 1, { Pan2.ar(sig, pan) }, { Balance2.ar(sig[0], sig[1], pan) });
        sends.value(sig * env * chk * amp, out, echoOut, verbOut, echo, verb);
      }).add;
    };

    // ------------------------------------------------------------------- fx

    // tape-ish ping-pong dub echo: filters + saturation inside the loop, wow
    // on the delay line, lagged time so tempo changes slide like tape
    SynthDef(\brk_echo, {
      arg in, out, verbOut, time=0.375, fb=0.5, lpf=2500, hpf=300,
          wow=0.3, sat=0.4, pp=0.7, verb=0.3;
      var input = In.ar(in, 2);
      var t     = Lag.kr(time, 0.8);
      var mod   = (LFNoise2.kr(0.4) * 0.002 * wow) + (SinOsc.kr(0.17) * 0.0015 * wow);
      var fbk   = LocalIn.ar(2);
      var inj   = XFade2.ar(input, [Mix(input), DC.ar(0)], (pp * 2) - 1);
      var sig, del;
      sig = inj + (fbk * Lag.kr(fb, 0.2).clip(0, 1.02));
      sig = LPF.ar(sig, Lag.kr(lpf, 0.3).clip(200, 16000));
      sig = HPF.ar(sig, Lag.kr(hpf, 0.3).clip(20, 4000));
      sig = (sig * (1 + (sat * 2))).tanh / (1 + (sat * 0.8));
      del = DelayC.ar(sig, 2.5, (t + mod).clip(0.01, 2.4));
      LocalOut.ar([del[1], del[0]]);
      Out.ar(out, del);
      Out.ar(verbOut, del * verb);
    }).add;

    SynthDef(\brk_verb, {
      arg in, out, size=0.75, damp=0.5, level=0.7;
      var sig = In.ar(in, 2);
      sig = DelayN.ar(sig, 0.1, 0.02);
      [0.013, 0.017, 0.023, 0.031].do { |dt|
        sig = AllpassC.ar(sig, 0.08, (dt * [1, 1.13]) + (LFNoise2.kr([0.1, 0.11]) * 0.0008), 1.2);
      };
      sig = FreeVerb2.ar(sig[0], sig[1], 1, Lag.kr(size, 1).clip(0, 1), damp.clip(0, 1));
      sig = HPF.ar(sig, 180);
      Out.ar(out, sig * level);
    }).add;

    // the glitch insert: one 4-channel delay line over dry + main, its time
    // driven per mode from the moment of the trigger (el = seconds since)
    //   1 stutter  time steps up a slice at a time: the first slice plays
    //              live, then repeats; a tiny window at each slice edge
    //   2 tape stop time grows by (1 - rate) as the rate falls to zero
    //   3 reverse  time grows at 2x: reads backwards from the trigger
    //   4 chop     live, gated on and off every half slice
    //   5 crush    live, sample-and-hold + bit reduction
    // wet fades in and out over a few ms, so it never clicks on or off
    SynthDef(\brk_glitch, {
      arg dryBus, mainBus, t_go=0, mode=1, slice=0.1, dur=0, mix=1;
      var sig  = In.ar(dryBus, 2) ++ In.ar(mainBus, 2);
      var el   = Sweep.ar(t_go, 1);
      var sl   = slice.clip(0.01, 1);
      var d    = dur.clip(0, 1.5);
      var gate = EnvGen.ar(Env([0, 1, 1, 0], [0.004, (d - 0.012).max(0.001), 0.008]), t_go);
      var rate = EnvGen.ar(Env([1, 1, 0.0], [0, d.max(0.01)], [0, -2]), t_go);
      var ph   = (el / sl).frac;
      var win  = Select.ar(mode < 1.5, [DC.ar(1), (ph * sl / 0.003).min(1) * ((1 - ph) * sl / 0.003).min(1)]);
      var time = Select.ar((mode - 1).clip(0, 2), [
        (el / sl).floor * sl, Sweep.ar(t_go, 1 - rate), el * 2
      ]).clip(0.0001, 2);
      var wet  = Select.ar(mode > 3.5, [DelayC.ar(sig, 2.05, time) * win, sig]);
      wet = Select.ar((mode - 3).clip(0, 2), [
        wet,
        wet * Lag.ar(LFPulse.ar(sl.reciprocal, 0, 0.5), 0.002),
        // companded: 8 steps on the square root, so quiet tails survive.
        // the max() matters: norns' ARM sqrt returns NaN for 0 and for
        // denormals (fine on a Mac), and one NaN froze the master's levels
        { |h| h.sign * ((h.abs.max(0.000001).sqrt * 8).round(1) / 8).squared }.value(Latch.ar(wet, Impulse.ar(3000)))
      ]);
      ReplaceOut.ar(dryBus,  (sig[0..1] * (1 - (gate * mix))) + (wet[0..1] * gate * mix));
      ReplaceOut.ar(mainBus, (sig[2..3] * (1 - (gate * mix))) + (wet[2..3] * gate * mix));
    }).add;

    SynthDef(\brk_master, {
      arg dryIn, mainIn, out, ampOut, level=0.8, drive=0.2, crush=0, dip=20000;
      // Sanitize: a NaN or inf from any voice becomes 0 here, so it can't
      // stick in the limiter or the Amplitude followers (they never recover)
      var d    = Sanitize.ar(In.ar(dryIn, 2));
      var m    = Sanitize.ar(In.ar(mainIn, 2));
      var cr   = Lag.kr(crush, 0.05).clip(0, 1);
      var wet  = (cr * 4).clip(0, 1);          // 0 = exactly clean
      var steps = cr.linexp(0, 1, 2048, 6);
      var held = Latch.ar(m, Impulse.ar(cr.linexp(0, 1, 22000, 1800)));
      var sig, mono, toVis;
      held = (held * steps).round(1) / steps;
      m = (m * (1 - wet)) + (held * wet);
      // dip: the fill's filter dip, on everything but the kick
      m = LPF.ar(m, Lag.kr(dip, 0.12).clip(40, 20000));
      sig = d + m;
      sig = HPF.ar(sig, 25);
      // headroom: a busy bar sums to ~1.7 here, which pushed the drive's
      // tanh into hard saturation on every kick + snare (audible crunch).
      // trim into the drive, make the level back up after it (busy bars peak
      // ~0.7, the old level: norns mixers with gain after the engine clip)
      sig = sig * 0.35;
      sig = (sig * (1 + (drive * 2))).tanh / (1 + (drive * 0.6));
      sig = Limiter.ar(sig * level * 1.45, 0.95, 0.01);
      // the visuals' ears: three cheap filters and four Amplitude followers
      // on the mono sum, mapped from dB to 0..1
      toVis = { arg a, lo, hi; a.max(0.00001).ampdb.linlin(lo, hi, 0, 1) };
      mono = (sig[0] + sig[1]) * 0.5;
      Out.kr(ampOut, [
        toVis.value(Amplitude.kr(mono, 0.02, 0.3), -54, -3),
        toVis.value(Amplitude.kr(LPF.ar(mono, 160), 0.02, 0.3), -56, -3),
        toVis.value(Amplitude.kr(LPF.ar(HPF.ar(mono, 160), 3000), 0.02, 0.3), -60, -14),
        toVis.value(Amplitude.kr(HPF.ar(mono, 3000), 0.02, 0.25), -70, -24)
      ]);
      Out.ar(out, sig);
    }).add;

    s.sync;

    echoSynth = Synth(\brk_echo, [
      \in, echoBus.index, \out, mainBus.index, \verbOut, verbBus.index
    ], fxGroup, \addToTail);
    verbSynth = Synth(\brk_verb, [
      \in, verbBus.index, \out, mainBus.index
    ], fxGroup, \addToTail);
    masterSynth = Synth(\brk_master, [
      \dryIn, dryBus.index, \mainIn, mainBus.index, \out, context.out_b.index,
      \ampOut, outBus.index
    ], fxGroup, \addToTail);
    // after the echo and reverb (which write to main), before the master
    glitchSynth = Synth.before(masterSynth, \brk_glitch, [
      \dryBus, dryBus.index, \mainBus, mainBus.index
    ]);

    fx = IdentityDictionary[
      \echo -> echoSynth, \verb -> verbSynth, \master -> masterSynth
    ];
    fxVals = IdentityDictionary.new;

    // tweak keys that route straight to a persistent synth arg
    fxMap = IdentityDictionary[
      \echo_time -> [\echo, \time],   \echo_fb -> [\echo, \fb],
      \echo_lpf -> [\echo, \lpf],     \echo_hpf -> [\echo, \hpf],
      \echo_wow -> [\echo, \wow],     \echo_sat -> [\echo, \sat],
      \echo_pp -> [\echo, \pp],       \echo_verb -> [\echo, \verb],
      \verb_size -> [\verb, \size],   \verb_damp -> [\verb, \damp],
      \verb_level -> [\verb, \level],
      \level -> [\master, \level],    \drive -> [\master, \drive],
      \crush -> [\master, \crush],    \dip -> [\master, \dip]
    ];

    // ------------------------------------------------------------- commands

    this.addCommand(\kick, "ffffff", { |msg|
      Synth([\brk_kick_sub, \brk_kick_909, \brk_kick_808, \brk_kick_knock, \brk_kick_gabber,
        \brk_kick_rave, \brk_kick_acoustic, \brk_kick_metal, \brk_kick_minipops,
        \brk_kick_dubstep, \brk_kick_click, \brk_kick_toy, \brk_kick_dusty, \brk_kick_tribal,
        \brk_kick_808long, \brk_kick_simmons, \brk_kick_hardstyle, \brk_kick_trance,
        \brk_kick_gqom].clipAt(msg[6].asInteger - 1), [
        \out, dryBus.index, \amp, msg[1] * st[\kick_lvl],
        \tune, msg[2], \decay, msg[3], \drive, msg[4], \bend, msg[5]
      ], voiceGroup);
    });

    this.addCommand(\snare, "fffffff", { |msg|
      Synth([\brk_snare_909, \brk_snare_drill, \brk_snare_808, \brk_snare_noise,
        \brk_snare_acoustic, \brk_snare_jungle, \brk_snare_metal, \brk_snare_minipops,
        \brk_snare_dubstep, \brk_snare_click, \brk_snare_toy, \brk_snare_dusty, \brk_snare_frame,
        \brk_snare_disco, \brk_snare_simmons, \brk_snare_gated, \brk_snare_miami].clipAt(msg[7].asInteger - 1), [
        \out, mainBus.index, \echoOut, echoBus.index, \verbOut, verbBus.index,
        \amp, msg[1] * st[\snare_lvl], \tune, msg[2], \decay, msg[3], \tone, msg[4],
        \pan, msg[5], \bend, msg[6],
        \echo, st[\snare_echo], \verb, st[\snare_verb]
      ], voiceGroup);
    });

    this.addCommand(\clap, "ffff", { |msg|
      Synth(\brk_clap, [
        \out, mainBus.index, \echoOut, echoBus.index, \verbOut, verbBus.index,
        \amp, msg[1] * st[\clap_lvl], \decay, msg[2], \tone, msg[3], \pan, msg[4],
        \echo, st[\clap_echo], \verb, st[\clap_verb]
      ], voiceGroup);
    });

    this.addCommand(\rim, "fff", { |msg|
      Synth(\brk_rim, [
        \out, mainBus.index, \echoOut, echoBus.index, \verbOut, verbBus.index,
        \amp, msg[1] * st[\rim_lvl], \tune, msg[2], \pan, msg[3],
        \echo, st[\rim_echo], \verb, st[\rim_verb]
      ], voiceGroup);
    });

    // any closed hat (decay <= 0.15) chokes the ringing open hat, and a new
    // open hat chokes the last one; the choke is a fast gate release
    this.addCommand(\hat, "fffff", { |msg|
      var decay = msg[2];
      var open = decay > 0.15;
      hatCount = hatCount + 1;
      chokeBus.subBus(0).set(hatCount);
      Synth([\brk_hat1, \brk_hat2, \brk_hat3, \brk_hat4, \brk_hat5, \brk_hat6, \brk_hat7, \brk_hat8, \brk_hat9, \brk_hat10].clipAt(msg[5].asInteger - 1), [
        \out, mainBus.index, \echoOut, echoBus.index, \verbOut, verbBus.index,
        \chokeBus, chokeBus.index, \id, if(open, { hatCount }, { 1e9 }),
        \amp, msg[1] * st[\hat_lvl], \decay, decay, \tone, msg[3], \pan, msg[4],
        \echo, st[\hat_echo], \verb, st[\hat_verb]
      ], voiceGroup);
    });

    this.addCommand(\ride, "ffff", { |msg|
      Synth(\brk_ride, [
        \out, mainBus.index, \verbOut, verbBus.index,
        \amp, msg[1] * st[\ride_lvl], \decay, msg[2], \tone, msg[3], \pan, msg[4],
        \verb, st[\ride_verb]
      ], voiceGroup);
    });

    this.addCommand(\shaker, "fff", { |msg|
      Synth(\brk_shaker, [
        \out, mainBus.index, \echoOut, echoBus.index, \verbOut, verbBus.index,
        \amp, msg[1] * st[\hat_lvl], \decay, msg[2], \pan, msg[3],
        \echo, st[\hat_echo], \verb, st[\hat_verb]
      ], voiceGroup);
    });

    this.addCommand(\tom, "ffffff", { |msg|
      Synth(\brk_tom, [
        \out, mainBus.index, \echoOut, echoBus.index, \verbOut, verbBus.index,
        \amp, msg[1] * st[\tom_lvl], \freq, msg[2], \decay, msg[3], \pan, msg[4],
        \bend, msg[5], \tone, msg[6],
        \echo, st[\tom_echo], \verb, st[\tom_verb]
      ], voiceGroup);
    });

    this.addCommand(\perc, "ffffff", { |msg|
      Synth([\brk_perc1, \brk_perc2, \brk_perc3, \brk_perc4, \brk_perc5,
        \brk_perc6, \brk_perc7, \brk_perc8, \brk_perc9, \brk_perc10,
        \brk_perc11, \brk_perc12, \brk_perc13, \brk_perc14, \brk_perc15, \brk_perc16, \brk_perc17,
        \brk_perc18, \brk_perc19, \brk_perc20, \brk_perc21].clipAt(msg[5].asInteger - 1), [
        \out, mainBus.index, \echoOut, echoBus.index, \verbOut, verbBus.index,
        \amp, msg[1] * st[\perc_lvl], \freq, msg[2], \decay, msg[3], \pan, msg[4], \tone, msg[6],
        \echo, st[\perc_echo], \verb, st[\perc_verb]
      ], voiceGroup);
    });

    this.addCommand(\tick, "ffff", { |msg|
      Synth([\brk_tick1, \brk_tick2, \brk_tick3, \brk_tick4, \brk_tick5, \brk_tick6, \brk_tick7, \brk_tick8].clipAt(msg[2].asInteger - 1), [
        \out, mainBus.index, \echoOut, echoBus.index, \verbOut, verbBus.index,
        \amp, msg[1] * st[\tick_lvl], \freq, msg[3], \pan, msg[4],
        \echo, st[\tick_echo], \verb, st[\tick_verb]
      ], voiceGroup);
    });

    // monophonic slice player: a new slice releases the last one (3 ms)
    this.addCommand(\brk, "fffff", { |msg|
      var b = breakBuf;
      if(b.notNil, {
        sliceCount = sliceCount + 1;
        chokeBus.subBus(1).set(sliceCount);
        Synth(("brk_slice" ++ b.numChannels.clip(1, 2)).asSymbol, [
          \out, mainBus.index, \echoOut, echoBus.index, \verbOut, verbBus.index,
          \chokeBus, chokeBus.index + 1, \id, sliceCount, \buf, b.bufnum,
          \amp, msg[1] * st[\break_lvl], \pos, msg[2], \len, msg[3], \rate, msg[4], \pan, msg[5],
          \echo, st[\break_echo], \verb, st[\break_verb]
        ], voiceGroup);
      });
    });

    // load a sound file into the break buffer; the old buffer is freed once
    // the new one is in (after releasing the slice still reading it)
    this.addCommand(\break_load, "s", { |msg|
      var path = msg[1].asString;
      if(File.exists(path), {
        Buffer.read(context.server, path, action: { |b|
          var old = breakBuf;
          if(b.numFrames.notNil and: { b.numFrames > 0 }, {
            breakBuf = b;
            sliceCount = sliceCount + 1;
            chokeBus.subBus(1).set(sliceCount);
            if(old.notNil, { SystemClock.sched(0.05, { old.free; nil }) });
          }, {
            ("breakage: could not read break: " ++ path).postln;
            b.free;
          });
        });
      }, {
        ("breakage: break file not found: " ++ path).postln;
      });
    });

    this.addCommand(\glitch, "ffff", { |msg|
      glitchSynth.set(\mode, msg[1], \slice, msg[2], \dur, msg[3], \mix, msg[4], \t_go, 1);
    });

    this.addCommand(\tweak, "sf", { |msg|
      var key = msg[1].asSymbol;
      var val = msg[2];
      var dest = fxMap[key];
      if(dest.notNil, {
        var node = fx[dest[0]];
        if(fxVals[dest[0]].isNil, { fxVals[dest[0]] = IdentityDictionary.new });
        fxVals[dest[0]][dest[1]] = val;
        if(node.notNil, { node.set(dest[1], val) });
      }, {
        st[key] = val;
      });
    });

    // the visuals' ears (see brk_master)
    [\out_amp, \out_lo, \out_mid, \out_hi].do { |name, i|
      this.addPoll(name, { outBus.getnSynchronous(4)[i] });
    };
  }

  free {
    voiceGroup.free;
    fxGroup.free;
    dryBus.free;
    mainBus.free;
    echoBus.free;
    verbBus.free;
    outBus.free;
    chokeBus.free;
    if(breakBuf.notNil, { breakBuf.free });
  }
}
