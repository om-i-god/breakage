// compile + smoke-test Engine_Breakage: boot, alloc, fire every command,
// record a few seconds, report peak/rms. run via test/sc/run.sh
var out = thisProcess.argv[0] ? "/tmp/breakage_test.wav";
s.options.numInputBusChannels = 0;
s.options.numOutputBusChannels = 2;
s.waitForBoot {
  var xg = Group.new(s), inb = [Bus.audio(s, 1), Bus.audio(s, 1)];
  var ctx = (server: s, xg: xg, in_b: inb, out_b: Bus.new(\audio, 0, 2, s));
  var cond = Condition.new, eng, rec;
  eng = Engine_Breakage.new(ctx, { cond.test = true; cond.signal });
  cond.wait;
  s.sync;
  "ENGINE ALLOCATED".postln;
  ~eng = eng;
  ~script = thisProcess.argv[1];
  ~tmp = PathName(out).pathOnly;
  // ~seg.("name") prints the peak (max over both channels) of the output
  // since the last call; ~reset clears it without printing
  ~mbus = Bus.control(s, 1);
  ~meter = { arg t_reset = 0;
    var o = In.ar(0, 2).abs;
    Out.kr(~mbus.index, Peak.ar(max(o[0], o[1]), Delay1.kr(t_reset)));
  }.play(s, addAction: \addToTail);
  ~reset = { s.sync; ~meter.set(\t_reset, 1) };
  ~seg = { |name|
    s.sync;
    ("SEG " ++ name ++ " peak " ++ ~mbus.getSynchronous.round(0.001)).postln;
    ~meter.set(\t_reset, 1);
  };
  // a short test break: 8 decaying noise + tone hits over 2 s, mono or stereo
  ~makeBreak = { |path, nc = 1|
    var sr = 48000, n = sr * 2;
    var data = FloatArray.newClear(n * nc);
    var f = SoundFile.new.headerFormat_("WAV").sampleFormat_("float")
      .numChannels_(nc).sampleRate_(sr);
    n.do { |i|
      var t = (i % 12000) / sr;
      var v = exp(t * -25) * ((0.5.rand2) + (sin(i * 0.03 * (1 + ((i / 12000).floor % 3))) * 0.4));
      nc.do { |c| data[(i * nc) + c] = v * (1 - (c * 0.3)) };
    };
    f.openWrite(path); f.writeData(data); f.close;
    path
  };
  s.sync;
  s.recHeaderFormat = "wav"; s.recSampleFormat = "float";
  s.record(out, numChannels: 2);
  0.3.wait;
  // any error in the test body still reaches the report and quits the
  // server, so a failure can't leave scsynth holding the pipe open
  try { if(~script.notNil, { ~script.load }, {
    var t = 60 / 128 / 4;
    eng.cmd(\brk, 0.8, 0, 0.2, 1, 0);          // no buffer yet: a no-op
    eng.cmd(\break_load, ~makeBreak.(~tmp +/+ "brk_smoke.wav", 2));
    0.5.wait;
    eng.cmd(\tweak, \echo_time, t * 3);
    32.do { |i|
      if(i % 4 == 0, { eng.cmd(\kick, 0.8, 33, 0.45, 0.1, 1, (i / 4).floor % 5 + 1) });
      if(i % 8 == 4, { eng.cmd(\snare, 0.7, 52, 0.18, 0.5, 0, 0, (i / 8).floor % 4 + 1) });
      if(i % 2 == 0, { eng.cmd(\hat, 0.5, 0.05, 0.5, 0.2, i % 3 + 1) });
      if(i % 8 == 6, { eng.cmd(\hat, 0.5, 0.4, 0.5, -0.2, 1) });
      if(i % 16 == 12, { eng.cmd(\clap, 0.6, 0.18, 0.5, 0.1) });
      if(i % 8 == 3, { eng.cmd(\rim, 0.5, 92, -0.3) });
      if(i % 8 == 0, { eng.cmd(\ride, 0.3, 1.2, 0.5, 0.3) });
      eng.cmd(\shaker, 0.3, 0.07, -0.2);
      if(i % 8 == 7, { eng.cmd(\tom, 0.6, 110, 0.3, 0.2, -5) });
      if(i % 3 == 1, { eng.cmd(\perc, 0.5, 220, 0.25, -0.3, i % 5 + 1) });
      if(i % 2 == 1, { eng.cmd(\tick, 0.4, i % 6 + 1, 3000, 0.4) });
      if(i % 4 == 2, { eng.cmd(\brk, 0.6, (i % 8) / 8, t * 2, [1, -1, 1.5].wrapAt(i), 0) });
      if(i == 8, { eng.cmd(\glitch, 1, t, t * 4, 1) });
      if(i == 13, { eng.cmd(\glitch, 2, t, t * 3, 1) });
      if(i == 16, { eng.cmd(\tweak, \dip, 600); eng.cmd(\tweak, \crush, 0.6) });
      if(i == 20, { eng.cmd(\glitch, 3, t, t * 2, 1) });
      if(i == 24, { eng.cmd(\glitch, 4, t / 2, t * 2, 1); eng.cmd(\tweak, \dip, 20000); eng.cmd(\tweak, \crush, 0) });
      if(i == 24, { eng.polls.keysValuesDo { |k, f| ("poll mid " ++ k ++ " = " ++ f.value.round(0.001)).postln } });
      if(i == 29, { eng.cmd(\glitch, 5, t, t * 2, 0.8) });
      t.wait;
    };
  }) } { |err| ("ERROR in test body: " ++ err.errorString).postln };
  2.wait;
  ~eng.polls.keysValuesDo { |k, f| ("poll " ++ k ++ " = " ++ f.value).postln };
  ("CHECK nodes " ++ s.numSynths).postln;
  s.stopRecording;
  1.wait;
  // level report
  SoundFile.use(out, { |f|
    var data = FloatArray.newClear(f.numFrames * f.numChannels), peak, rms;
    f.readData(data);
    peak = data.abs.maxItem;
    rms = (data.squared.sum / data.size.max(1)).max(1e-12).sqrt;
    ("LEVELS peak " ++ peak.round(0.001) ++ "  rms " ++ rms.round(0.0001)
      ++ "  secs " ++ (f.numFrames / f.sampleRate).round(0.1)).postln;
  });
  "SMOKE DONE".postln;
  s.quit;
  0.5.wait;
  0.exit;
};
