// glitch insert: a kick + snare, then per-16th peaks with and without each
// mode. stutter should repeat the first 16th (flat peaks), reverse should
// bring energy back where the dry hit has died, chop should gate it.
// then every mode must hand the mix back alive (not stuck at 0 or NaN)
var e = ~eng, t = 60 / 128 / 4;
var probe = { |name, mode|
  e.cmd(\kick, 0.8, 33, 0.9, 0, 1, 2);
  e.cmd(\snare, 0.8, 52, 0.3, 0.5, 0, 0, 1);
  // reverse reads what came before the trigger: give it a hit to read
  if(mode == 3, { (t * 2).wait });
  if(mode > 0, { e.cmd(\glitch, mode, t, t * 6, 1) });
  ~seg.(name ++ " x");
  6.do { |i| t.wait; ~seg.(name ++ " 16th " ++ (i + 1)) };
  1.5.wait; ~reset.value;
};
var bar = { 4.do { |i|
  e.cmd(\kick, 0.8, 33, 0.45, 0, 1, 1);
  e.cmd(\hat, 0.6, 0.05, 0.5, 0, 1);
  if(i == 2, { e.cmd(\snare, 0.7, 52, 0.18, 0.5, 0, 0, 1) });
  (t * 4).wait } };
e.cmd(\tweak, \snare_echo, 0);
e.cmd(\tweak, \snare_verb, 0);
probe.("dry", 0);
probe.("stutter", 1);
probe.("tapestop", 2);
probe.("reverse", 3);
probe.("chop", 4);
probe.("crush", 5);
bar.value; ~seg.("warm");
[1, 2, 3, 4, 5, 1].do { |m|
  e.cmd(\glitch, m, 0.12, 0.9, 1);
  bar.value;
  ~seg.("AFTER mode " ++ m);
};
