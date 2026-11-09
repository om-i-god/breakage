# breakage — design

A norns drummer. Its own SuperCollider drum synth (no samples) plus an
optional breakbeat chopper, played by its own conductor. It is built to run on
a second norns beside **gradient** (github om-i-god/gradient): clock-locked,
and while gradient sends its CC OUT the drummer follows gradient's arc. With
no gradient signal it runs its own arc.

Range: everything Aphex-adjacent and dub-techno-adjacent in one script, from
dub techno / analog house kits up to drill'n'bass ratchet storms.

## Two axes

- **energy** (0..1) — how much plays and how hard. Owned by the conductor
  (solo) or by gradient's energy CC (follow). E1 nudges it like gradient.
- **chaos** (0..1) — how far toward drill'n'bass. **Manual only**: the
  conductor never moves it. Low = steady 4/4 or broken dub, swing, space. Mid =
  broken / syncopated, ghost notes, odd perc lanes, occasional rolls. High =
  ratchets to 64ths with pitch sweeps, slice rearrangement, micro-edits,
  halftime flips. Low energy + high chaos = sparse but twitchy.

## Kits (8)

A kit = a sound palette + groove-family weights + default swing/echo + its
own visual theme. Switch with hold K2 + E2 (lands next bar), grid row 4, or
`kit` param. `kit auto` (off / phrase edges) lets the conductor switch.

| # | kit | sound | grooves |
|---|-----|-------|---------|
| 1 | dub | sub kick, rim + echo, soft analog hats, congas | dub, four |
| 2 | house | 909 kick/clap/open hats, cowbell | four |
| 3 | acid | 909 kick, crisp hats, 303-ish blip perc | four, acid |
| 4 | analord | 808 kick/snare, metallic hats, electro | electro, broken |
| 5 | syro | knock kick, analog snare, ticks, bongos | broken, electro |
| 6 | broken | dusty kick, 909 snare, shaker, wood | broken, break |
| 7 | drill | knock kick, drill snare, crush ticks | break |
| 8 | gabber | gabber kick, noise snare, ring ticks | four, break |

## Engine interface (lib/Engine_Breakage.sc)

All args floats unless noted. Every voice is a one-shot that frees itself.

| command | args | notes |
|---|---|---|
| kick | amp tune decay drive bend type | tune = midi note; bend = pitch-env depth multiplier (1 normal); type 1 sub 2 909 3 808 4 knock 5 gabber 6 rave 7 acoustic 8 metal 9 minipops 10 dubstep 11 click 12 toy 13 dusty 14 tribal 15 808 long 16 simmons |
| snare | amp tune decay tone pan bend type | bend = semitones glide over the hit (+ up, - down); type 1 909 2 drill (tight pitched body) 3 808 4 noise 5 acoustic 6 jungle 7 metal 8 minipops 9 dubstep 10 click 11 toy 12 dusty 13 frame 14 disco 15 simmons |
| clap | amp decay tone pan | |
| rim | amp tune pan | |
| hat | amp decay tone pan type | type 1 analog 2 metallic (606) 3 crisp noise 4 acoustic (small cymbal) 5 lofi (crushed) 6 minipops (hissy cymbal) 7 dusty 8 click 9 disco. decay > 0.15 is "open"; any hat with decay <= 0.15 chokes the ringing open hat |
| ride | amp decay tone pan | |
| shaker | amp decay pan | |
| tom | amp hz decay pan bend | bend in semitones |
| perc | amp hz decay pan kind | 1 conga 2 bongo 3 cowbell 4 clave 5 acid (resonant saw squelch) 6 metal (struck pipe) 7 log (wood) 8 plink (prepared piano) 9 guiro 10 tambourine 11 music box 12 squeak 13 talking drum 14 wobble 15 crackle 16 vox 17 syntom |
| tick | amp kind hz pan | 1 click 2 blip 3 crush 4 ring 5 chirp (fm) 6 zap 7 error 8 pop |
| brk | amp pos len rate pan | play the loaded break from `pos` (0..1 of file) for `len` seconds at `rate` (negative = backwards from pos). monophonic: a new slice fades out the last one in ~3 ms. no-op if nothing loaded |
| break_load | path (string, "s") | load a sound file (mono or stereo) into the break buffer |
| glitch | mode slice dur mix | insert on the whole drum mix: 1 stutter 2 tape stop 3 reverse 4 chop 5 crush (as gradient) |
| tweak | key (s) val (f) | see keys below |

Tweak keys — read at spawn (levels / sends): `kick_lvl snare_lvl clap_lvl
rim_lvl hat_lvl ride_lvl perc_lvl tom_lvl tick_lvl break_lvl`, echo sends
`snare_echo clap_echo rim_echo hat_echo perc_echo tom_echo tick_echo
break_echo`, reverb sends `snare_verb clap_verb rim_verb hat_verb ride_verb
perc_verb tom_verb tick_verb break_verb`. Persistent fx: `echo_time echo_fb
echo_lpf echo_hpf echo_wow echo_sat verb_size verb_damp verb_level level drive
crush` (0..1 bitcrush/downsample on the main bus) `dip` (lowpass Hz on main
bus, fill dips).

Routing: kick → dry bus; everything else → main bus (+ echo/verb sends);
echo and reverb return to main; crush + dip on main; glitch insert on dry +
main; master sums, sanitizes, drives, limits. Polls `out_amp out_lo out_mid
out_hi` (0..1, as gradient) feed the visuals.

## Script

- `breakage.lua` — state, step loop (16ths on the norns clock, swing, ratchets
  scheduled as sub-step coroutines), keys/encoders, screen, params.
- `lib/kits.lua` — kit table.
- `lib/gen.lua` — pattern generation per groove family; chaos transforms.
- `lib/conductor.lua` — energy arc (set / track), phrase, part entry by
  thresholds with jitter, fills, mutation, kit auto, kickless.
- `lib/follow.lua` — MIDI in from gradient: energy / dub / phrase pulse /
  kickless CCs, start/stop, optional note channel for tom tuning; times out to
  solo after 8 bars of silence, keeping the energy where it was.
- `lib/visuals.lua` + `lib/vis/<kit>.lua` — one theme per kit; the theme
  follows the kit (or fixed, param).
- `lib/gridui.lua`.

## Following gradient

Clock: both norns on Link (or MIDI clock) — system CLOCK menu. Start: gradient
SYNC OUT start → breakage starts on the next bar (also via clock.transport).
gradient CC OUT → breakage FOLLOW: energy cc, dub cc (drives the drum echo
send), phrase pulse cc (realigns the phrase so fills land on gradient's
edges; phrase length learned from pulse spacing), kickless cc (new in
gradient: 127 while its kick is out). Defaults on both sides: ch 16, energy
20, dub 21, tone 22, phrase 23, kickless 24.

## Controls

| | |
|---|---|
| E1 / E2 / E3 | page (play: energy nudge / chaos / dub) |
| K2 tap | drop (kick + hats out, 8 + 8 bars) |
| K3 tap | fill now (type from chaos) |
| K2 + K3 | play / stop |
| hold K2 | E2 kit, E3 fill rate |
| hold K3 | E2 bpm, E3 play mode |
| hold K1 | E1 theme, E2 page, K3 mutate, K2 strip (break / glitch only) |

Pages: play, sound (kick tune / kick decay / snare tune), space (swing /
reverb / crush), break (break level / break pitch / slice chaos), parts (E2
part, E3 level, K2 mute, K3 solo).
