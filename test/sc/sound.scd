// every voice and type on its own, at amp 0.8: each SEG is one voice's
// peak out of the master. none should be silent (< 0.02) or clipping (>= 1)
var e = ~eng, t = 60 / 128 / 4;
var gap = { 0.9.wait; ~reset.value };
var hits = { |n, step, fn| n.do { |i| fn.value(i); step.wait } };
// break: a no-op before anything is loaded
e.cmd(\brk, 0.8, 0, 0.2, 1, 0); 0.4.wait; ~seg.("brk (nothing loaded, expect 0)");
[\sub, \909, \808, \knock, \gabber, \rave, \acoustic, \metal, \minipops, \dubstep, \click, \toy, \dusty, \tribal, \trap808, \simmons].do { |name, k|
  hits.(3, 0.5, { e.cmd(\kick, 0.8, 33, 0.45, 0, 1, k + 1) });
  ~seg.("kick " ++ name); gap.value;
};
hits.(3, 0.5, { e.cmd(\kick, 0.8, 33, 0.45, 1, 2.5, 2) }); ~seg.("kick 909 drive1 bend2.5"); gap.value;
hits.(3, 0.5, { e.cmd(\kick, 0.8, 33, 0.45, 1, 1, 5) }); ~seg.("kick gabber drive1"); gap.value;
[\909, \drill, \808, \noise, \acoustic, \jungle, \metal, \minipops, \dubstep, \click, \toy, \dusty, \frame, \disco, \simmons].do { |name, k|
  hits.(3, 0.4, { e.cmd(\snare, 0.8, [52, 62, 54, 55, 52, 60, 55, 58, 53, 60, 62, 53, 55, 55, 57][k], 0.18, 0.5, 0, 0, k + 1) });
  ~seg.("snare " ++ name); gap.value;
};
// drill ratchet: 64ths, pitch rising, decay scaled down
hits.(16, t / 4, { |i| e.cmd(\snare, 0.8, 60 + i, 0.04, 0.7, 0, 2, 2) });
~seg.("snare drill 64th ratchet"); gap.value;
hits.(3, 0.4, { e.cmd(\clap, 0.8, 0.18, 0.5, 0) }); ~seg.("clap"); gap.value;
hits.(3, 0.3, { e.cmd(\rim, 0.8, 92, 0) }); ~seg.("rim"); gap.value;
[\analog, \metallic, \crisp, \acoustic, \lofi, \minipops, \dusty, \click, \disco].do { |name, k|
  hits.(4, 0.2, { e.cmd(\hat, 0.8, 0.05, 0.5, 0, k + 1) }); ~seg.("hat closed " ++ name); gap.value;
  e.cmd(\hat, 0.8, 0.6, 0.5, 0, k + 1); 0.6.wait; ~seg.("hat open " ++ name); gap.value;
};
// choke: open hat then a closed one 60 ms later; the 60 ms..300 ms window
// after the closed hat should be near silent (the open one would still ring)
e.cmd(\hat, 0.8, 1.0, 0.5, 0, 1); 0.06.wait;
e.cmd(\hat, 0.3, 0.03, 0.5, 0, 1); 0.1.wait; ~reset.value; 0.25.wait;
~seg.("hat choke tail (expect ~0)"); gap.value;
e.cmd(\hat, 0.8, 1.0, 0.5, 0, 1); 0.16.wait; ~reset.value; 0.25.wait;
~seg.("hat unchoked tail (expect > choke)"); gap.value;
hits.(2, 0.8, { e.cmd(\ride, 0.8, 1.2, 0.5, 0) }); ~seg.("ride"); gap.value;
hits.(4, 0.2, { e.cmd(\shaker, 0.8, 0.07, 0) }); ~seg.("shaker"); gap.value;
hits.(3, 0.4, { e.cmd(\tom, 0.8, 110, 0.3, 0, 0, 0.5) }); ~seg.("tom"); gap.value;
hits.(3, 0.4, { e.cmd(\tom, 0.8, 110, 0.3, 0, -7, 0.5) }); ~seg.("tom bend -7"); gap.value;
[\conga, \bongo, \cowbell, \clave, \acid, \metal, \log, \plink, \guiro, \tambourine, \musicbox, \squeak, \talking, \wobble, \crackle, \vox, \syntom].do { |name, k|
  hits.(4, 0.25, { |i| e.cmd(\perc, 0.8, [220, 400, 540, 2500, 110, 440, 220, 440, 2800, 6000, 1046, 660, 147, 55, 80, 220, 147][k] * [1, 1.5].wrapAt(i), 0.25, 0, k + 1, 0.5) });
  ~seg.("perc " ++ name); gap.value;
};
// tone 0 and 1 on every perc kind and the tom: never silent, never clipping
17.do { |k|
  [0, 1].do { |tn|
    hits.(3, 0.25, { |i| e.cmd(\perc, 0.8, [220, 400, 540, 2500, 110, 440, 220, 440, 2800, 6000, 1046, 660, 147, 55, 80, 220, 147][k], 0.3, 0, k + 1, tn) });
    ~seg.("perc " ++ (k + 1) ++ " tone " ++ tn); gap.value;
  };
};
[0, 1].do { |tn| hits.(3, 0.3, { e.cmd(\tom, 0.8, 110, 0.3, 0, 0, tn) }); ~seg.("tom tone " ++ tn); gap.value };
[\click, \blip, \crush, \ring, \chirp, \zap, \error, \pop].do { |name, k|
  hits.(6, 0.12, { e.cmd(\tick, 0.8, k + 1, 3000, 0) }); ~seg.("tick " ++ name); gap.value;
};
// break: mono + stereo
e.cmd(\break_load, ~makeBreak.(~tmp +/+ "brk_test_mono.wav", 1)); 0.5.wait; ~reset.value;
hits.(8, t * 2, { |i| e.cmd(\brk, 0.8, i / 8, t * 2, 1, 0) }); ~seg.("brk mono fwd"); gap.value;
hits.(8, t * 2, { |i| e.cmd(\brk, 0.8, (i + 1) / 8, t * 2, -1, 0) }); ~seg.("brk mono rev"); gap.value;
// monophonic: long slices restarted every 16th must not stack
hits.(8, t, { |i| e.cmd(\brk, 0.8, 0, 1.5, 1, 0) }); ~seg.("brk mono retrig"); gap.value;
("CHECK nodes after retrig " ++ s.numSynths).postln;
e.cmd(\break_load, ~makeBreak.(~tmp +/+ "brk_test_st.wav", 2)); 0.5.wait; ~reset.value;
hits.(8, t * 2, { |i| e.cmd(\brk, 0.8, i / 8, t * 2, [1, 0.5, 2, -1].wrapAt(i), 0.3) }); ~seg.("brk stereo"); gap.value;
e.cmd(\break_load, "/nope/missing.wav"); 0.2.wait;
hits.(2, t * 2, { |i| e.cmd(\brk, 0.8, 0, t * 2, 1, 0) }); ~seg.("brk after bad load (still stereo)"); gap.value;
// main-bus crush and dip on a snare + hat loop; kick bypasses them
[[0, 20000, "clean"], [0.5, 20000, "crush 0.5"], [1, 20000, "crush 1"], [0, 400, "dip 400"]].do { |c|
  e.cmd(\tweak, \crush, c[0]); e.cmd(\tweak, \dip, c[1]); 0.2.wait; ~reset.value;
  hits.(8, t, { |i| e.cmd(\hat, 0.8, 0.05, 0.6, 0, 3); if(i % 4 == 2, { e.cmd(\snare, 0.8, 52, 0.18, 0.5, 0, 0, 1) }) });
  ~seg.("main " ++ c[2]); gap.value;
};
e.cmd(\tweak, \crush, 0); e.cmd(\tweak, \dip, 400); 0.2.wait; ~reset.value;
hits.(2, 0.5, { e.cmd(\kick, 0.8, 33, 0.45, 0, 1, 2) }); ~seg.("kick under dip 400 (unaffected)");
e.cmd(\tweak, \dip, 20000); gap.value;
// tweak routing: an st key and an fx key
e.cmd(\tweak, \snare_lvl, 0.25);
hits.(3, 0.4, { e.cmd(\snare, 0.8, 52, 0.18, 0.5, 0, 0, 1) }); ~seg.("snare at snare_lvl 0.25"); gap.value;
e.cmd(\tweak, \snare_lvl, 1);
e.cmd(\tweak, \level, 0.3);
hits.(3, 0.4, { e.cmd(\snare, 0.8, 52, 0.18, 0.5, 0, 0, 1) }); ~seg.("snare at level 0.3"); gap.value;
e.cmd(\tweak, \level, 0.8);
2.wait;
("CHECK nodes " ++ s.numSynths).postln;
