-- breakage / kits
-- a kit is a sound palette (engine voice types and tunings), the groove
-- families it likes, and its default feel. the visual theme with the same
-- index belongs to it. chaos is separate and manual: any kit can be pushed
-- into drill territory, and it keeps its sounds while it gets there.
--
-- fields
--   kick   {type, tune (midi), decay, drive}   type 1 sub 2 909 3 808 4 knock 5 gabber
--                                              6 rave 7 acoustic 8 metal 9 minipops
--   snare  {type, tune, decay, tone}           type 1 909 2 drill 3 808 4 noise
--                                              5 acoustic 6 jungle 7 metal 8 minipops
--   rim    weight of rim (vs snare) on the backbeat / ghosts, 0..1
--   clap   chance a phrase uses claps on the backbeat, 0..1
--   hat    {type, tone (0..1), open decay}       type 1 analog 2 metallic 3 crisp
--                                                4 acoustic 5 lofi 6 minipops
--   perc   list of perc kinds (1 conga 2 bongo 3 cowbell 4 clave 5 acid
--          6 metal 7 log 8 plink 9 guiro 10 tambourine)
--   ticks  list of tick kinds (1 click 2 blip 3 crush 4 ring 5 chirp 6 zap)
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
}

K.names = {}
for i, k in ipairs(K.list) do K.names[i] = k.name end

return K
