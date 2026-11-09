-- breakage / kits
-- a kit is a sound palette (engine voice types and tunings), the groove
-- families it likes, and its default feel. the visual theme with the same
-- index belongs to it. chaos is separate and manual: any kit can be pushed
-- into drill territory, and it keeps its sounds while it gets there.
--
-- fields
--   kick   {type, tune (midi), decay, drive}   type 1 sub 2 909 3 808 4 knock 5 gabber
--                                              6 rave 7 acoustic 8 metal 9 minipops
--                                              10 dubstep 11 click 12 toy 13 dusty 14 tribal
--                                              15 808 long 16 simmons 17 hardstyle
--                                              18 trance 19 gqom
--   snare  {type, tune, decay, tone}           type 1 909 2 drill 3 808 4 noise
--                                              5 acoustic 6 jungle 7 metal 8 minipops
--                                              9 dubstep 10 click 11 toy 12 dusty 13 frame
--                                              14 disco 15 simmons 16 gated 17 miami
--   rim    weight of rim (vs snare) on the backbeat / ghosts, 0..1
--   clap   chance a phrase uses claps on the backbeat, 0..1
--   hat    {type, tone (0..1), open decay}       type 1 analog 2 metallic 3 crisp
--                                                4 acoustic 5 lofi 6 minipops 7 dusty 8 click
--                                                9 disco 10 shaker
--   perc   list of perc kinds (1 conga 2 bongo 3 cowbell 4 clave 5 acid
--          6 metal 7 log 8 plink 9 guiro 10 tambourine 11 music box
--          12 squeak 13 talking drum 14 wobble 15 crackle 16 vox 17 syntom
--          18 log drum 19 bed squeak 20 tamborzao 21 phonk bell)
--   ticks  list of tick kinds (1 click 2 blip 3 crush 4 ring 5 chirp 6 zap
--          7 error 8 pop)
--   shaker, ride, toms   chance per phrase that the part is in the arrangement
--   grooves {family = weight}   families in lib/gen
--   swing  0..50 %            echo  dub echo amount 0..1 (the dub knob's home)
--   verb   reverb send scale  crush main-bus crush floor  drive master drive

local K = {}

K.list = {
  {name = "dub",
   kick = {1, 31, 0.6, 0.1}, snare = {3, 52, 0.18, 0.3}, rim = 0.85, clap = 0.1,
   hat = {1, 0.45, 0.35}, perc = {1, 4}, ticks = {1, 2},
   shaker = 0.5, ride = 0.2, toms = 0.6,
   grooves = {dub = 3, four = 2}, swing = 12, echo = 0.75, verb = 1.3, crush = 0, drive = 0.15},

  {name = "house",
   kick = {2, 33, 0.45, 0.2}, snare = {1, 50, 0.16, 0.5}, rim = 0.3, clap = 0.9,
   hat = {1, 0.6, 0.4}, perc = {3, 2}, ticks = {1},
   shaker = 0.6, ride = 0.5, toms = 0.3,
   grooves = {four = 4, acid = 1}, swing = 18, echo = 0.3, verb = 0.8, crush = 0, drive = 0.2},

  {name = "acid",
   kick = {2, 34, 0.38, 0.35}, snare = {1, 54, 0.14, 0.6}, rim = 0.4, clap = 0.6,
   hat = {3, 0.7, 0.3}, perc = {5, 5, 3}, ticks = {2, 5},
   shaker = 0.2, ride = 0.4, toms = 0.2,
   grooves = {acid = 3, four = 2}, swing = 8, echo = 0.4, verb = 0.6, crush = 0.05, drive = 0.35},

  {name = "analord",
   kick = {3, 30, 0.7, 0.15}, snare = {3, 50, 0.2, 0.45}, rim = 0.5, clap = 0.4,
   hat = {2, 0.55, 0.3}, perc = {3, 4, 1}, ticks = {2},
   shaker = 0.3, ride = 0.2, toms = 0.5,
   grooves = {electro = 3, broken = 1}, swing = 22, echo = 0.45, verb = 0.7, crush = 0.05, drive = 0.25},

  {name = "syro",
   kick = {4, 36, 0.32, 0.2}, snare = {3, 56, 0.16, 0.55}, rim = 0.5, clap = 0.3,
   hat = {1, 0.58, 0.25}, perc = {2, 4, 5}, ticks = {1, 2, 5},
   shaker = 0.4, ride = 0.3, toms = 0.4,
   grooves = {broken = 3, electro = 2, brk = 1}, swing = 26, echo = 0.4, verb = 0.7, crush = 0.05, drive = 0.2},

  {name = "broken",
   kick = {2, 32, 0.4, 0.3}, snare = {1, 52, 0.18, 0.55}, rim = 0.35, clap = 0.2,
   hat = {3, 0.65, 0.3}, perc = {4, 2}, ticks = {1, 3},
   shaker = 0.7, ride = 0.4, toms = 0.4,
   grooves = {broken = 3, brk = 2}, swing = 30, echo = 0.45, verb = 0.8, crush = 0.1, drive = 0.25},

  {name = "drill",
   kick = {4, 35, 0.3, 0.35}, snare = {2, 60, 0.12, 0.7}, rim = 0.2, clap = 0.1,
   hat = {3, 0.8, 0.2}, perc = {4, 5}, ticks = {3, 5, 6},
   shaker = 0.2, ride = 0.5, toms = 0.5,
   grooves = {brk = 4, broken = 1}, swing = 4, echo = 0.3, verb = 0.5, crush = 0.15, drive = 0.3},

  {name = "gabber",
   kick = {5, 38, 0.4, 0.8}, snare = {4, 55, 0.14, 0.7}, rim = 0.1, clap = 0.5,
   hat = {2, 0.7, 0.25}, perc = {3}, ticks = {3, 4, 6},
   shaker = 0.1, ride = 0.6, toms = 0.3,
   grooves = {four = 3, brk = 2}, swing = 0, echo = 0.25, verb = 0.5, crush = 0.2, drive = 0.6},

  -- early-90s ambient techno: soft long 808, ride and shaker, wood and
  -- piano plinks, a lot of air
  {name = "ambient",
   kick = {3, 29, 0.8, 0.05}, snare = {3, 50, 0.25, 0.3}, rim = 0.6, clap = 0.05,
   hat = {4, 0.4, 0.5}, perc = {7, 8, 1}, ticks = {2, 1},
   shaker = 0.6, ride = 0.6, toms = 0.3,
   grooves = {half = 2, four = 2, dub = 2}, swing = 10, echo = 0.6, verb = 1.8, crush = 0, drive = 0.05},

  -- hardcore rave: a driven boom kick under a breakbeat snare
  {name = "rave",
   kick = {6, 34, 0.5, 0.35}, snare = {1, 55, 0.16, 0.65}, rim = 0.2, clap = 0.5,
   hat = {3, 0.7, 0.3}, perc = {3, 5}, ticks = {2, 4},
   shaker = 0.3, ride = 0.5, toms = 0.3,
   grooves = {rave = 4, brk = 1, four = 1}, swing = 6, echo = 0.35, verb = 0.7, crush = 0.08, drive = 0.4},

  -- jungle: deep sub, a bright tuned snare rolling through the break, rides
  {name = "jungle",
   kick = {1, 29, 0.55, 0.15}, snare = {6, 61, 0.15, 0.65}, rim = 0.3, clap = 0.05,
   hat = {3, 0.75, 0.3}, perc = {2, 4}, ticks = {1, 2},
   shaker = 0.3, ride = 0.7, toms = 0.4,
   grooves = {jungle = 4, brk = 1}, swing = 8, echo = 0.45, verb = 0.7, crush = 0.05, drive = 0.2},

  -- industrial: clanging metal kick and snare, crushed hats, halftime
  {name = "industrial",
   kick = {8, 31, 0.5, 0.5}, snare = {7, 53, 0.22, 0.6}, rim = 0.2, clap = 0.3,
   hat = {5, 0.6, 0.3}, perc = {6, 3}, ticks = {3, 4, 6},
   shaker = 0.2, ride = 0.3, toms = 0.5,
   grooves = {half = 3, brk = 2, four = 1}, swing = 0, echo = 0.35, verb = 1.0, crush = 0.2, drive = 0.55},

  -- acoustic: a solenoid-struck drum kit, wood, pipes and prepared piano
  {name = "acoustic",
   kick = {7, 33, 0.5, 0.05}, snare = {5, 53, 0.2, 0.5}, rim = 0.5, clap = 0,
   hat = {4, 0.55, 0.45}, perc = {7, 8, 6}, ticks = {1, 2},
   shaker = 0.4, ride = 0.5, toms = 0.7,
   grooves = {broken = 2, half = 1, brk = 1, jungle = 1}, swing = 16, echo = 0.3, verb = 0.9, crush = 0, drive = 0.1},

  -- minipops: a 70s preset rhythm box, its round kick, dull snare and
  -- hissy cymbal, claves, guiro, bongos, congas and tambourine, playing its
  -- Latin and pop presets until chaos takes them apart
  {name = "minipops",
   kick = {9, 36, 0.35, 0}, snare = {8, 58, 0.12, 0.3}, rim = 0.8, clap = 0,
   hat = {6, 0.5, 0.5}, perc = {4, 9, 2, 1, 10}, ticks = {2, 1},
   shaker = 0.7, ride = 0.1, toms = 0.15,
   grooves = {bossa = 2, rhumba = 2, chacha = 2, samba = 1, beguine = 2, rock = 2},
   swing = 0, echo = 0.35, verb = 0.6, crush = 0.05, drive = 0.1},

  -- detroit / minimal techno: 909, rimshots in a 3-3-2, ride
  {name = "techno",
   kick = {2, 33, 0.42, 0.3}, snare = {1, 52, 0.15, 0.6}, rim = 0.85, clap = 0.4,
   hat = {3, 0.75, 0.25}, perc = {4, 6}, ticks = {1, 4},
   shaker = 0.3, ride = 0.7, toms = 0.2,
   grooves = {minimal = 3, four = 2}, swing = 6, echo = 0.4, verb = 0.7, crush = 0, drive = 0.3},

  -- halfstep dubstep: a long sub, a huge snare on 3, wobble stabs
  {name = "dubstep",
   kick = {10, 29, 0.6, 0.2}, snare = {9, 53, 0.25, 0.5}, rim = 0.3, clap = 0.3,
   hat = {3, 0.65, 0.3}, perc = {14, 4}, ticks = {2, 6},
   shaker = 0.3, ride = 0.2, toms = 0.3,
   grooves = {halfstep = 4, half = 1}, swing = 10, echo = 0.55, verb = 1.0, crush = 0.05, drive = 0.3},

  -- breakcore: gabber kicks under a rattling amen
  {name = "breakcore",
   kick = {5, 36, 0.35, 0.7}, snare = {6, 62, 0.13, 0.8}, rim = 0.2, clap = 0.3,
   hat = {3, 0.8, 0.2}, perc = {6, 3}, ticks = {3, 6, 7},
   shaker = 0.1, ride = 0.6, toms = 0.4,
   grooves = {breakcore = 4, brk = 1, jungle = 1}, swing = 0, echo = 0.3, verb = 0.5, crush = 0.25, drive = 0.6},

  -- glitch: clicks and cuts, sine pops, one-bit snares, errors
  {name = "glitch",
   kick = {11, 36, 0.3, 0.1}, snare = {10, 60, 0.1, 0.7}, rim = 0.4, clap = 0,
   hat = {8, 0.6, 0.2}, perc = {4, 11, 12}, ticks = {7, 1, 5, 2},
   shaker = 0.2, ride = 0.1, toms = 0.2,
   grooves = {glitch = 4, broken = 1}, swing = 0, echo = 0.45, verb = 0.6, crush = 0.1, drive = 0.1},

  -- toy: a toy drum machine and a music box
  {name = "toy",
   kick = {12, 36, 0.3, 0}, snare = {11, 62, 0.12, 0.5}, rim = 0.4, clap = 0.1,
   hat = {4, 0.7, 0.3}, perc = {11, 12, 4}, ticks = {2},
   shaker = 0.5, ride = 0.2, toms = 0.3,
   grooves = {march = 3, rock = 1, four = 1}, swing = 0, echo = 0.35, verb = 0.8, crush = 0.05, drive = 0},

  -- boom bap: dusty, crunchy, swung, crackling
  {name = "boombap",
   kick = {13, 33, 0.5, 0.3}, snare = {12, 53, 0.2, 0.5}, rim = 0.3, clap = 0.3,
   hat = {7, 0.55, 0.3}, perc = {15, 1}, ticks = {8, 1},
   shaker = 0.3, ride = 0.2, toms = 0.2,
   grooves = {boombap = 4, broken = 1}, swing = 34, echo = 0.35, verb = 0.6, crush = 0.1, drive = 0.3},

  -- tribal: frame drums, talking drum, logs, a lot of shaker and toms
  {name = "tribal",
   kick = {14, 31, 0.6, 0.1}, snare = {13, 55, 0.2, 0.5}, rim = 0.3, clap = 0.1,
   hat = {4, 0.5, 0.4}, perc = {13, 7, 1, 10}, ticks = {1},
   shaker = 0.8, ride = 0.1, toms = 0.9,
   grooves = {tribal = 4, half = 1}, swing = 14, echo = 0.4, verb = 1.1, crush = 0, drive = 0.15},

  -- uk garage: 2-step, rimshots, heavily shuffled hats
  {name = "garage",
   kick = {4, 34, 0.4, 0.25}, snare = {1, 55, 0.14, 0.6}, rim = 0.7, clap = 0.5,
   hat = {3, 0.7, 0.25}, perc = {2, 4}, ticks = {2},
   shaker = 0.6, ride = 0.3, toms = 0.2,
   grooves = {garage = 4, broken = 1}, swing = 40, echo = 0.4, verb = 0.7, crush = 0, drive = 0.2},

  -- footwork: juke kicks in threes, claps, rapid toms, vox chops
  {name = "footwork",
   kick = {3, 33, 0.35, 0.3}, snare = {1, 56, 0.12, 0.6}, rim = 0.4, clap = 0.8,
   hat = {3, 0.7, 0.2}, perc = {16, 2}, ticks = {2, 5},
   shaker = 0.2, ride = 0.2, toms = 0.8,
   grooves = {footwork = 4, brk = 1}, swing = 4, echo = 0.35, verb = 0.6, crush = 0.05, drive = 0.3},

  -- trap: a long sagging 808, the snare on 3, hat rolls
  {name = "trap",
   kick = {15, 31, 0.8, 0.25}, snare = {1, 55, 0.15, 0.6}, rim = 0.2, clap = 0.8,
   hat = {3, 0.8, 0.15}, perc = {3, 16}, ticks = {2},
   shaker = 0.1, ride = 0.1, toms = 0.2,
   grooves = {trap = 4}, swing = 0, echo = 0.35, verb = 0.7, crush = 0.05, drive = 0.3},

  -- disco: a live-feel kit, open hats on the offbeats, tambourine
  {name = "disco",
   kick = {7, 33, 0.4, 0.1}, snare = {14, 55, 0.18, 0.55}, rim = 0.3, clap = 0.7,
   hat = {9, 0.6, 0.35}, perc = {10, 1, 3}, ticks = {2},
   shaker = 0.4, ride = 0.3, toms = 0.4,
   grooves = {disco = 4, four = 1}, swing = 8, echo = 0.35, verb = 0.8, crush = 0, drive = 0.15},

  -- motorik: krautrock steadiness on 80s electronic drums
  {name = "motorik",
   kick = {16, 33, 0.45, 0.1}, snare = {15, 57, 0.2, 0.5}, rim = 0.3, clap = 0.1,
   hat = {1, 0.55, 0.3}, perc = {17, 4}, ticks = {2, 1},
   shaker = 0.2, ride = 0.3, toms = 0.5,
   grooves = {motorik = 4, four = 1}, swing = 0, echo = 0.45, verb = 0.8, crush = 0, drive = 0.15},

  {name = "trance",
   kick = {18, 33, 0.38, 0.2}, snare = {1, 55, 0.2, 0.6}, rim = 0.2, clap = 0.95,
   hat = {3, 0.7, 0.28}, perc = {12, 4}, ticks = {2, 5},
   shaker = 0.4, ride = 0.6, toms = 0.2,
   grooves = {trance = 4, four = 1}, swing = 0, echo = 0.55, verb = 1.2, crush = 0, drive = 0.2},

  {name = "hardstyle",
   kick = {17, 32, 0.5, 0.6}, snare = {16, 56, 0.2, 0.6}, rim = 0.1, clap = 0.8,
   hat = {2, 0.65, 0.25}, perc = {6, 12}, ticks = {6, 3},
   shaker = 0.1, ride = 0.3, toms = 0.3,
   grooves = {hardstyle = 4, rave = 1}, swing = 0, echo = 0.3, verb = 1.0, crush = 0.05, drive = 0.5},

  {name = "amapiano",
   kick = {2, 31, 0.5, 0.1}, snare = {1, 56, 0.14, 0.45}, rim = 0.7, clap = 0.5,
   hat = {10, 0.5, 0.3}, perc = {18, 18, 4}, ticks = {1},
   shaker = 0.9, ride = 0.2, toms = 0.2,
   grooves = {amapiano = 4, four = 1}, swing = 16, echo = 0.4, verb = 0.9, crush = 0, drive = 0.15},

  {name = "gqom",
   kick = {19, 30, 0.65, 0.3}, snare = {4, 52, 0.2, 0.4}, rim = 0.5, clap = 0.3,
   hat = {5, 0.45, 0.3}, perc = {20, 17, 13}, ticks = {3, 1},
   shaker = 0.3, ride = 0.1, toms = 0.9,
   grooves = {gqom = 4, tribal = 1}, swing = 6, echo = 0.6, verb = 1.2, crush = 0.1, drive = 0.3},

  {name = "baile",
   kick = {3, 31, 0.55, 0.35}, snare = {17, 55, 0.15, 0.55}, rim = 0.4, clap = 0.6,
   hat = {1, 0.55, 0.25}, perc = {20, 20, 16}, ticks = {8, 2},
   shaker = 0.4, ride = 0.1, toms = 0.3,
   grooves = {baile = 4, trap = 1}, swing = 10, echo = 0.35, verb = 0.6, crush = 0.05, drive = 0.4},

  {name = "jersey",
   kick = {2, 33, 0.4, 0.3}, snare = {17, 56, 0.15, 0.6}, rim = 0.3, clap = 0.8,
   hat = {3, 0.6, 0.25}, perc = {19, 19, 16}, ticks = {8, 5},
   shaker = 0.2, ride = 0.1, toms = 0.2,
   grooves = {jersey = 4, footwork = 1}, swing = 8, echo = 0.3, verb = 0.6, crush = 0, drive = 0.3},

  {name = "phonk",
   kick = {15, 29, 0.8, 0.5}, snare = {17, 54, 0.18, 0.5}, rim = 0.3, clap = 0.5,
   hat = {5, 0.5, 0.25}, perc = {21, 21, 16}, ticks = {3, 8},
   shaker = 0.2, ride = 0.1, toms = 0.2,
   grooves = {phonk = 4, trap = 1}, swing = 12, echo = 0.4, verb = 0.7, crush = 0.15, drive = 0.55},

  {name = "synthwave",
   kick = {16, 33, 0.45, 0.15}, snare = {16, 55, 0.3, 0.55}, rim = 0.2, clap = 0.3,
   hat = {1, 0.55, 0.3}, perc = {17, 4}, ticks = {2},
   shaker = 0.3, ride = 0.4, toms = 0.7,
   grooves = {synthwave = 4, rock = 1}, swing = 0, echo = 0.5, verb = 1.3, crush = 0, drive = 0.2},
}

K.names = {}
for i, k in ipairs(K.list) do K.names[i] = k.name end

return K
