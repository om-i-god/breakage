-- breakage
-- a drummer: dub techno to drill
-- synced beside gradient, or alone
--
-- E1-E3: the current page
--   play: energy / chaos / dub
--   sound: kick tune / decay / snare
--   voices: kick / snare / hat model
--   groove: groove / perc / ticks
--   time: meter / 5/4 / 7/8 grouping
--   space: swing / reverb / crush
--   break: level / pitch / beats
-- K2 tap: drop (kick + hats out)
-- K3 tap: fill now
-- K2+K3: play / stop
-- hold K2: E2 kit  E3 fills
-- hold K3: E2 bpm  E3 play mode
-- hold K1: E1 theme  E2 page  E3 view
--   K3 mutate  K2 strip
--
-- PARAMS > FOLLOW: gradient's CC OUT
-- on the same channel + ccs, and
-- breakage follows its arc
--
-- v0.3

engine.name = "Breakage"

local KT  = include("lib/kits")
local G   = include("lib/gen")
local C   = include("lib/conductor")
local F   = include("lib/follow")
local VIS = include("lib/visuals")
local GU  = include("lib/gridui")

local NOTE_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
-- scales, in gradient's KEY > mode order so its mode cc means the same here
local SCALES = {
  {"aeolian", {0, 2, 3, 5, 7, 8, 10}}, {"dorian", {0, 2, 3, 5, 7, 9, 10}},
  {"phrygian", {0, 1, 3, 5, 7, 8, 10}}, {"locrian", {0, 1, 3, 5, 6, 8, 10}},
  {"mixolydian", {0, 2, 4, 5, 7, 9, 10}}, {"ionian", {0, 2, 4, 5, 7, 9, 11}},
  {"lydian", {0, 2, 4, 6, 7, 9, 11}}, {"harmonic minor", {0, 2, 3, 5, 7, 8, 11}},
  {"melodic minor", {0, 2, 3, 5, 7, 9, 11}}, {"phrygian dominant", {0, 1, 4, 5, 7, 8, 10}},
  {"dorian #4", {0, 2, 3, 6, 7, 9, 10}}, {"hungarian minor", {0, 2, 3, 6, 7, 8, 11}},
}
local SCALE_NAMES = {}
for i, sc in ipairs(SCALES) do SCALE_NAMES[i] = sc[1] end
local ECHO_DIVS      = {0.5, 0.75, 1, 1.5}
local ECHO_DIV_NAMES = {"1/8", "3/16", "1/4", "3/8"}
local GLITCH_NAMES   = {"stutter", "tape stop", "reverse", "chop", "crush"}
local BRK_BEATS      = {0, 2, 4, 8, 16, 32}       -- 0 = auto

-- time signatures. a bar is a run of beats, in 16ths (4 = a quarter, 6 = a
-- dotted quarter); each beat borrows one beat of the 16-step pattern (src,
-- 0-based: 0 the downbeat, 1 and 3 backbeats, 2 the second strong beat),
-- and a 6-long beat runs on into the next beat's first two 16ths. so every
-- groove plays in every meter.
--
-- 5/4 and 7/8 come in groupings (PARAMS > 5/4 grouping, 7/8 grouping, or
-- the time page): each group opens on a strong beat, so the accents move.
-- 5/4  3+2    K S s | K S         (beats from src 0 1 3 | 2 3)
--      2+3    K S | K S s         (0 1 | 2 1 3)
--      2+2+1  K S | K S | K       (0 1 | 2 3 | 2)
-- 7/8  2+2+3, 3+2+2, 2+3+2 (in eighths): the same three beats, regrouped
local METERS = {
  {name = "4/4", opts = {{"", {4, 4, 4, 4}, {0, 1, 2, 3}}}},
  {name = "3/4", opts = {{"", {4, 4, 4}, {0, 1, 3}}}},
  {name = "5/4", group = "group54", opts = {
    {"3+2", {4, 4, 4, 4, 4}, {0, 1, 3, 2, 3}},
    {"2+3", {4, 4, 4, 4, 4}, {0, 1, 2, 1, 3}},
    {"2+2+1", {4, 4, 4, 4, 4}, {0, 1, 2, 3, 2}}}},
  {name = "6/8", opts = {{"", {6, 6}, {0, 1}}}},
  {name = "7/8", group = "group78", opts = {
    {"2+2+3", {4, 4, 6}, {0, 1, 2}},
    {"3+2+2", {6, 4, 4}, {0, 1, 2}},
    {"2+3+2", {4, 6, 4}, {0, 1, 2}}}},
  {name = "9/8", opts = {{"", {4, 4, 4, 6}, {0, 1, 2, 3}}}},
  {name = "5/8", opts = {{"", {4, 6}, {0, 1}}}},
  {name = "7/4", opts = {{"", {4, 4, 4, 4, 4, 4, 4}, {0, 1, 2, 3, 0, 1, 3}}}},
}
local METER_NAMES = {}
local GROUP54, GROUP78 = {}, {}
for i, o in ipairs(METERS[3].opts) do GROUP54[i] = o[1] end
for i, o in ipairs(METERS[5].opts) do GROUP78[i] = o[1] end
-- MAP[m][g][t] = the pattern step (1..16) bar step t (0-based) reads, for
-- meter m in grouping g
local MAP = {}
for i, m in ipairs(METERS) do
  METER_NAMES[i] = m.name
  MAP[i] = {}
  for gi, o in ipairs(m.opts) do
    local t = {}
    for g, len in ipairs(o[2]) do
      local b = o[3][g]
      for j = 0, len - 1 do
        local src = j < 4 and (b * 4 + j) or (((b + 1) % 4) * 4 + (j - 4))
        t[#t + 1] = src + 1
      end
    end
    MAP[i][gi] = t
  end
end
-- the grouping in use for meter m
local function grouping(m)
  local id = METERS[m].group
  return id and params:get(id) or 1
end
local function meter_label(m, g)
  local l = METERS[m].opts[g][1]
  return METERS[m].name .. (l ~= "" and (" " .. l) or "")
end
-- per perc kind: midi base (fixed-pitch kinds 3, 4, 9, 10, 15 use PERC_FIXED), decay
local PERC_BASE      = {50, 62, 0, 0, 36, 69, 57, 72, 0, 0, 84, 76, 50, 36, 0, 57, 50}
local PERC_FIXED     = {[3] = 800, [4] = 2500, [9] = 2800, [10] = 6000, [15] = 80}
local PERC_DECAY     = {0.18, 0.18, 0.18, 0.18, 0, 0.4, 0.25, 0.45, 0.13, 0.2, 0.5, 0.25, 0.4, 0.35, 0.3, 0.22, 0.35}
-- SOUND > ... model: "kit" or a voice model that replaces the kit's own
local KICK_MODELS  = {"kit", "sub", "909", "808", "knock", "gabber", "rave", "acoustic", "metal", "minipops",
  "dubstep", "click", "toy", "dusty", "tribal", "808 long", "simmons"}
local SNARE_MODELS = {"kit", "909", "drill", "808", "noise", "acoustic", "jungle", "metal", "minipops",
  "dubstep", "click", "toy", "dusty", "frame", "disco", "simmons"}
local HAT_MODELS   = {"kit", "analog", "metallic", "crisp", "acoustic", "lofi", "minipops", "dusty", "click", "disco"}
local PERC_MODELS  = {"kit", "conga", "bongo", "cowbell", "clave", "acid", "metal", "log", "plink",
  "guiro", "tambourine", "music box", "squeak", "talking drum", "wobble", "crackle", "vox", "syntom"}
local TICK_MODELS  = {"kit", "click", "blip", "crush", "ring", "chirp", "zap", "error", "pop"}

------------------------------------------------------------------------
-- state
------------------------------------------------------------------------

local S = {
  playing = false, tstep = 0, step = 0, bar = 0, track_bar = 0,
  meter = 1, group = 1, bar_len = 16, sib = 0, src_step = 1,  -- time signature + grouping, 16ths in the bar, step in it
  energy = 0.5, nudge = 0, chaos = 0, kit = 1, kit_pending = nil, kit_auto = 1,
  dub = 0.5, phrase_len = 16, phrase_pos = 0, phrase_anchor = 0, cycle_bars = 128,
  mode_play = 1, hold_energy = 0.6, track_minutes = 8, end_action = 2,
  kick_style = 1, hat_style = 1, fills = 1, glitch_amt = 3, break_mode = 2, freeze = false,
  pat = {}, gain = {}, want = {}, jitter = {}, mute = {}, solo = {},
  drop_bars = 0, strip_bars = 0, hand_throw = 0, half_bars = 0, halftime = false,
  kickless = false, fill = nil, edit = nil, throw = false,
  following = false, f_energy = nil, f_dub = nil, f_kickless = false, f_last_bar = -99,
  root_pc = 9, brk_ready = false, brk_dur = 0, brk_beats = 8, bpm = 120,
}

local main_clock, draw_clock
local loop_gen = 0
local k1, k2, k3 = false, false, false
local k2_used, k3_used, k1_used = false, false, false
local theme = 1
local page = 1
local part_sel = 1
local msg, msg_t = nil, 0
local fill_now = false       -- K3: a fill on the next beat
local start, stop

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function chance(p) return math.random() < p end
local function mtof(n) return 440 * 2 ^ ((n - 69) / 12) end
local function flash(t) msg, msg_t = t, util.time() end
local function kit() return C.kit(S) end
local function beat_sec() return clock.get_beat_sec() end

------------------------------------------------------------------------
-- engine helpers
------------------------------------------------------------------------

local tweak_cache = {}
local function tweak(k, v)
  if tweak_cache[k] ~= v then
    tweak_cache[k] = v
    engine.tweak(k, v)
  end
end

-- run fn(j) n times spread over `span` 16ths, from now
local function spread(n, span, fn)
  if n <= 1 then fn(1); return end
  local dt = beat_sec() * 0.25 * span / n
  clock.run(function()
    for j = 1, n do
      fn(j)
      if j < n then clock.sleep(dt) end
    end
  end)
end

local function later(sec, fn)
  if sec <= 0 then fn() else clock.run(function() clock.sleep(sec); fn() end) end
end

local function glitch(mode, slice_q, beats)
  if S.glitch_amt == 1 then return end
  local b = beat_sec()
  local dur = math.min(mode == 3 and 1 or 1.5, b * beats)   -- reverse reads back 2 s at most
  engine.glitch(mode, b * 0.25 * slice_q, dur, params:get("glitch_mix") / 100)
  VIS.event("glitch", mode, dur)
end

-- the energy's say in how hard things hit
local function ev(part)
  return (S.gain[part] or 0) * (0.55 + 0.45 * S.energy)
end

------------------------------------------------------------------------
-- voices
------------------------------------------------------------------------

-- the pitch centre for toms, perc and ticks: gradient's current chord
-- root while following with "key + chords", else the key
local function tone_pc()
  if S.following and S.f_chord and params:get("follow_key") == 3 then return S.f_chord end
  return S.root_pc
end

local function root_note(base)
  return base + ((tone_pc() - base) % 12)
end

-- snap a midi note into the key's scale (nearest step, the lower on a tie)
local function in_key(n)
  local steps = SCALES[params:get("scale")][2]
  local o = (n - S.root_pc) % 12
  local best, bd = 0, 99
  for _, st in ipairs(steps) do
    for _, c in ipairs({st - 12, st, st + 12}) do
      local d = math.abs(o - c)
      if d < bd or (d == bd and c < best) then best, bd = c, d end
    end
  end
  return n - o + best
end

-- kick / snare / rim: the kit's tuning moved (at most a tritone) to the
-- nearest key note, when SOUND > tune drums to key is on
local function to_key(note, off)
  if params:get("tune_key") ~= 2 then return note end
  local d = ((S.root_pc + (off or 0) - note) % 12 + 6) % 12 - 6
  return note + d
end

-- the kit's voice model, unless SOUND picks another
local function model(id, own)
  local m = params:get(id)
  return m > 1 and m - 1 or own
end

local function kick(vel, bend)
  local k = kit().kick
  local tune = to_key(k[2]) + params:get("kick_tune")
  engine.kick(0.85 * vel, tune, k[3] * params:get("kick_decay") / 100, k[4], bend or 1, model("kick_model", k[1]))
  VIS.event("kick", vel)
end

local function snare(vel, up, rn, rim)
  local k = kit().snare
  if rim then
    engine.rim(0.7 * vel, to_key(k[2] + 22, 7) + params:get("snare_tune") + (up or 0), (math.random() - 0.5) * 0.4)
    VIS.event("rim", vel)
  else
    engine.snare(0.8 * vel, to_key(k[2], 7) + params:get("snare_tune") + (up or 0), k[3] * params:get("snare_decay") / 100, k[4],
      (math.random() - 0.5) * 0.3, (S.chaos > 0.6 and chance(0.3)) and G.pick({-2, 3, 5}) or 0,
      model("snare_model", k[1]))
    VIS.event("snare", vel, rn or 1)
  end
end

local function clap(vel)
  engine.clap(0.75 * vel, 0.3, 0.5, (math.random() - 0.5) * 0.3)
  VIS.event("clap", vel)
end

local function hat(vel, open)
  local k = kit().hat
  local tone = clamp(k[2] * params:get("hat_tone") / 100, 0, 1)
  local decay = open and math.max(0.16, k[3] * params:get("hat_decay") / 100) or (0.035 + vel * 0.04)
  engine.hat(0.5 * vel, decay, tone, (math.random() - 0.5) * 0.6, model("hat_model", k[1]))
  VIS.event("hat", vel, open)
end


local function tom(vel, deg, bend)
  local hz = mtof(in_key(root_note(43) + (deg or 0)))
  engine.tom(0.7 * vel, hz, 0.35, (math.random() - 0.5) * 0.8, bend or 0)
  VIS.event("tom", vel, hz)
end

local function perc(st, vel)
  local kind = model("perc_model", st.kind)
  local hz
  if (kind == 3 or kind == 4) and params:get("tune_key") == 2 then
    -- cowbell and clave land on a key note near their own pitch
    hz = mtof(in_key(to_key(kind == 3 and 79 or 99)))
  else
    hz = PERC_FIXED[kind] or mtof(in_key(root_note(PERC_BASE[kind]) + st.deg))
  end
  local decay = kind == 5 and (0.12 + S.energy * 0.2) or PERC_DECAY[kind]
  engine.perc(0.6 * vel, hz, decay * params:get("perc_decay") / 100, (math.random() - 0.5) * 0.9, kind)
  VIS.event("perc", kind, vel)
end

local function tick(kind, vel)
  kind = model("tick_model", kind)
  engine.tick(0.45 * vel, kind, mtof(in_key(root_note(72) + G.pick({0, 7, 12, 19, 24}))), (math.random() - 0.5) * 1.4)
  VIS.event("tick", kind)
end

-- the break: slice `sl` (0-based) of the loop, for `steps` 16ths
local function brk_slice(sl, vel, steps, rev, pitch)
  if not S.brk_ready then return end
  local n = S.brk_beats * 4
  sl = sl % n
  local b = beat_sec()
  local rate = (S.brk_dur / S.brk_beats) / b * 2 ^ (((pitch or 0) + params:get("brk_pitch")) / 12)
  -- a hand-picked length far from the file's own can ask for silly rates:
  -- fold them back by octaves
  while rate > 4 do rate = rate / 2 end
  while rate < 0.125 do rate = rate * 2 end
  local len = b * 0.25 * (steps or 1)
  local pos = sl / n
  if rev then pos, rate = (sl + 1) / n, -rate end
  engine.brk(0.8 * vel, pos, len, rate, 0)
  VIS.event("brk", sl + 1, n, rev or false)
end

------------------------------------------------------------------------
-- the bar: mix moves for this bar
------------------------------------------------------------------------

local SEND = {snare = 0.3, rim = 0.55, clap = 0.3, hat = 0.04, perc = 0.35, tom = 0.5,
  tick = 0.35, ["break"] = 0.15}
local VSEND = {snare = 0.2, rim = 0.25, clap = 0.3, hat = 0.08, ride = 0.12, perc = 0.2,
  tom = 0.25, tick = 0.12, ["break"] = 0.08}

local function apply_bar()
  local kt = kit()
  local dub = params:get("dub") / 100
  if S.following and params:get("follow_dub") == 2 and S.f_dub then dub = S.f_dub end
  S.dub = dub
  local throw = S.throw or S.hand_throw > 0
  local b = beat_sec()
  S.echo_time = b * ECHO_DIVS[params:get("echo_div")]
  S.echo_fb = throw and 0.86 or (0.18 + dub * 0.55)
  S.swing = params:get("swing") / 100
  tweak("echo_time", S.echo_time)
  tweak("echo_fb", S.echo_fb)
  for k, v in pairs(SEND) do
    local s = v * dub * 1.6
    if throw and (k == "snare" or k == "rim" or k == "clap") then s = math.min(1, s * 2.2 + 0.2) end
    tweak(k .. "_echo", clamp(s, 0, 1))
  end
  local vs = kt.verb * params:get("verb_send") / 100
  for k, v in pairs(VSEND) do tweak(k .. "_verb", clamp(v * vs, 0, 1)) end
  tweak("crush", clamp(kt.crush + S.chaos * params:get("crush_amt") / 100 * 0.5, 0, 1))
  tweak("drive", clamp(params:get("drive") / 100, 0, 1))
  tweak("dip", 20000)
end

-- a kit's own feel: dub, swing and drive move to the kit's home on a change
local function kit_feel()
  if params:get("kit_mix") ~= 2 then return end
  local kt = kit()
  params:set("dub", math.floor(kt.echo * 100 + 0.5))
  params:set("swing", kt.swing)
  params:set("drive", math.floor(kt.drive * 100 + 0.5))
end

------------------------------------------------------------------------
-- the step
------------------------------------------------------------------------

-- where in the pattern step s (0-based) reads from, after the bar's edit
local function read_at(s)
  local e = S.edit
  local beat, sub = s // 4 + 1, s % 4
  if e and beat == e.beat then
    if e.kind == "repeat" then return s - 4 + 1 end
    if e.kind == "shuffle" then return (beat - 1) * 4 + e.order[sub + 1] + 1 end
  end
  return s + 1
end

local FILL_SUPPRESS = {
  toms = {snare = true, clap = true},
  roll = {snare = true, clap = true},
  drill = {snare = true, clap = true, kick = true, hats = true, ticks = true},
  gap = {kick = true, snare = true, clap = true, hats = true, ride = true, toms = true, brk = true, ticks = true},
  open = {hats = true},
  brkroll = {brk = true},
  pops = {snare = true, clap = true, perc = true},
  cascade = {perc = true, toms = true},
}

local function do_fill(s)
  local f = S.fill
  local i = s + 1 + (16 - S.bar_len)    -- counted back from the bar's end, as in 4/4
  local j = i - f.start            -- 0.. into the fill
  local len = 17 - f.start
  local u = j / math.max(1, len - 1)
  local c = S.chaos
  if f.kind == "toms" then
    if j % 2 == 0 or c > 0.3 then
      local degs = {12, 10, 7, 5, 3, 0, -2, -5}
      tom(0.6 + u * 0.4, degs[(j % #degs) + 1], c > 0.5 and -2 or 0)
    end
  elseif f.kind == "roll" then
    local n = ({1, 2, 2, 3, 4, 4, 6, 8})[math.min(8, math.floor(u * (2 + c * 6)) + 1)]
    spread(n, 1, function(r) snare(0.35 + u * 0.6, math.floor(u * 7 * c), n) end)
    if n > 1 then VIS.event("ratchet", n, "snare") end
  elseif f.kind == "drill" then
    local n = ({2, 2, 4, 4, 6, 8, 12, 16})[math.min(8, j + 1)]
    local up = j * (1 + c)
    spread(n, 1, function(r) snare(0.5 + u * 0.5, up + r * 0.5, n) end)
    VIS.event("ratchet", n, "snare")
    if chance(0.5) then tick(G.pick(kit().ticks), 0.8) end
    if j == 0 then kick(1, 2) end
  elseif f.kind == "open" then
    if s % 2 == 0 then hat(0.8, true) else hat(0.4, false) end
  elseif f.kind == "throw" then
    if j == 0 then
      tweak("echo_fb", 0.88)
      for _, k in ipairs({"snare", "rim", "clap"}) do tweak(k .. "_echo", 0.9) end
    end
    if i == 15 then snare(0.9, 0, 1, model("snare_model", kit().snare[1]) ~= 2 and chance(0.6)) end
  elseif f.kind == "dip" then
    if j == 0 then tweak("dip", 450) end
  elseif f.kind == "stutter" then
    if j == 0 then glitch(1, len > 4 and 2 or 1, len / 4) end
  elseif f.kind == "reverse" then
    if j == 0 then glitch(3, 1, len / 4) end
  elseif f.kind == "tapestop" then
    if j == 0 then glitch(2, 1, len / 4) end
  elseif f.kind == "pops" then
    -- a rhythm box's fill-in: a written run of hand percussion
    local RUN = {{4, 0}, {9, 0}, {2, 7}, {2, 5}, {1, 0}, {1, 0}, {4, 0}, {9, 0}}
    local st = RUN[(j % #RUN) + 1]
    if j % 2 == 0 or c > 0.3 or i >= 15 then
      perc({kind = st[1], deg = st[2]}, 0.6 + u * 0.4)
    end
    if i == 16 then snare(0.8, 0, 1, true) end
  elseif f.kind == "cascade" then
    -- down through the kit's percussion, a step each, pitched down the key
    local pk = kit().perc
    local degs = {12, 10, 7, 5, 3, 0, -2, -5}
    perc({kind = pk[(j % #pk) + 1], deg = degs[(j % #degs) + 1]}, 0.55 + u * 0.4)
    if c > 0.5 and j % 2 == 1 then tick(G.pick(kit().ticks), 0.6) end
  elseif f.kind == "brkroll" then
    local n = ({1, 2, 2, 4, 4, 6, 8, 8})[math.min(8, j + 1)]
    local sl = (S.tstep - j) % (S.brk_beats * 4)
    spread(n, 1, function(r) brk_slice(sl, 0.7 + u * 0.3, 1 / n, false, c > 0.5 and j or 0) end)
    if n > 1 then VIS.event("ratchet", n, "brk") end
  end
  return FILL_SUPPRESS[f.kind] or {}
end

-- one hit of a part, ratcheted by chaos
local function hit(part, vel, fn)
  local n, span, bend = G.ratchet(part, S.chaos, S.energy)
  if n > 1 then
    VIS.event("ratchet", n, part)
    spread(n, span, function(r) fn(vel * (0.7 + 0.3 * r / n), (r - 1) * bend, n) end)
  else
    fn(vel, 0, 1)
  end
end

local function play_step()
  -- a new time signature lands on the next bar line
  if S.sib >= S.bar_len then S.sib = 0 end
  if S.sib == 0 then
    S.meter = params:get("meter")
    S.group = grouping(S.meter)
    S.bar_len = #MAP[S.meter][S.group]
  end
  local s = S.sib
  local N = S.bar_len
  S.step = S.tstep
  if s == 0 then
    F.bar()
    local r = C.bar(S)
    if S.kit_changed then
      S.kit_changed = nil
      params:set("kit", S.kit, true)
      if params:get("theme_mode") == 1 then theme = S.kit end
      kit_feel()
      VIS.event("kit", S.kit)
      flash("kit " .. kit().name)
    end
    apply_bar()
    VIS.event("bar", S)
    if S.fill then VIS.event("fill", S.fill.kind) end
    if r == "stop" then stop(true); return end
  end

  local P = S.pat
  local src = MAP[S.meter][S.group][s + 1]  -- the pattern step this bar step reads
  S.src_step = src
  local i = s + 1 + (16 - N)               -- for fills: counted back from the bar's end
  local beat, sub = (src - 1) // 4 + 1, s % 4
  local e = S.edit
  local skip = e and e.beat == beat and e.kind == "skip"

  -- the edit's glitch moves land on the first 16th of their beat
  if e and e.beat == beat and sub == 0 then
    if e.kind == "stutter" then glitch(1, G.pick({0.5, 1}), 1)
    elseif e.kind == "reverse" then glitch(3, 1, 1)
    elseif e.kind == "tapestop" then glitch(2, 1, 1) end
  end

  -- K3: a fill from the next beat to the end of the bar
  if fill_now and sub == 0 then
    fill_now = false
    S.fill = C.pick_fill(S, false)
    S.fill.start = i
    VIS.event("fill", S.fill.kind)
  end

  local sup = {}
  if S.fill and i >= S.fill.start then sup = do_fill(s) end

  local r = read_at(src - 1)
  -- halftime: kick, snare and clap read the first half of the bar, stretched
  local rh = r
  local half_off = false
  if S.halftime then
    if s % 2 == 1 then half_off = true else rh = (r - 1) // 2 + 1 end
  end

  -- kick
  if not sup.kick and not half_off and (S.gain.kick or 0) > 0 then
    local v = P.kick[rh] or 0
    if v > 0 then
      hit("kick", v * ev("kick"), function(a, b) kick(a, 1 + math.max(0, b) * 0.3) end)
    end
  end

  if not skip then
    -- snare / rim
    if not sup.snare and not half_off and (S.gain.snare or 0) > 0 then
      local v = P.snare[rh] or 0
      if v > 0 then
        local rim = P.rim and v < 0.9
        hit("snare", v * ev("snare"), function(a, b, n) snare(a, b, n, rim) end)
      end
    end
    if e and e.kind == "roll" and e.beat == beat then
      local n = ({2, 3, 4, 6})[sub + 1]
      spread(n, 1, function(rr) snare(0.3 + sub * 0.15, sub * 1.5 + rr * 0.3, n) end)
      VIS.event("ratchet", n, "snare")
    end
    -- clap
    if not sup.clap and not half_off and (S.gain.clap or 0) > 0 then
      local v = P.clap[rh] or 0
      if v > 0 then
        local late = beat_sec() * 0.25 * 0.08
        later(late, function() hit("clap", v * ev("clap"), function(a) clap(a) end) end)
      end
    end
    -- hats (+ shaker), with their own shuffle on the off 16ths
    if not sup.hats and (S.gain.hats or 0) > 0 then
      local v = P.hats[r] or 0
      if v > 0 and (v > 0.3 or chance(0.4 + S.energy * 0.6)) then
        local open = (P.open[r] or 0) > 0 and S.energy > 0.35
        local d = (s % 2 == 1) and beat_sec() * 0.25 * (P.hat_shuffle or 0) or 0
        local rn = P.rolls and P.rolls[r]
        if rn and S.energy > 0.3 then
          -- a written hat roll (trap): the 16th split into rn, swelling
          local a0 = v * ev("hats")
          VIS.event("ratchet", rn, "hats")
          spread(rn, 1, function(j) hat(a0 * (0.5 + 0.5 * j / rn), false) end)
        else
          later(d, function() hit("hats", v * ev("hats"), function(a) hat(a, open and a > 0.3) end) end)
        end
      end
      if P.shaker and S.want.shaker then
        local sv = P.shaker[r] or 0
        if sv > 0 then engine.shaker(0.35 * sv * ev("hats"), 0.06, (math.random() - 0.5) * 0.5); VIS.event("shaker", sv) end
      end
    end
    -- ride
    if P.ride and not sup.ride and (S.gain.ride or 0) > 0 then
      local v = P.ride[r] or 0
      if v > 0 then
        engine.ride(0.4 * v * ev("ride"), 1.2, 0.5, 0.3)
        VIS.event("ride", v)
      end
    end
    -- toms
    if P.toms and not sup.toms and (S.gain.toms or 0) > 0 then
      local v = P.toms[r] or 0
      if v > 0 then hit("toms", v * ev("toms"), function(a, b) tom(a, G.pick({0, 7, 12}), b) end) end
    end
    -- ticks
    if not sup.ticks and (S.gain.ticks or 0) > 0 then
      local kind = P.ticks[r] or 0
      if kind > 0 and chance(0.5 + S.chaos * 0.5) then
        hit("ticks", ev("ticks") * (0.5 + math.random() * 0.5), function(a) tick(kind, a) end)
      end
    end
  end

  -- perc lane: phases against the bar on the running step count
  if (S.gain.perc or 0) > 0 and P.perc then
    -- odd-length lanes phase on the running count; a 16-long (written) lane reads with the bar
    local st = P.perc.steps[P.perc.len == 16 and r or ((S.tstep % P.perc.len) + 1)]
    if st then hit("perc", st.vel * ev("perc"), function(a) perc(st, a) end) end
  end

  -- the break: the loop straight through, reworked by the slice map
  if S.brk_ready and not sup.brk and (S.gain.brk or 0) > 0 and P.brk then
    local m = P.brk[r] or {}
    if not m.rest and not skip then
      local sl
      if m.slice == -1 then sl = S.last_slice or S.tstep
      elseif m.slice then sl = (S.tstep - s) + m.slice
      else sl = (S.tstep - s) + (r - 1) end
      if S.halftime then sl = (S.tstep - s) + (rh - 1) end
      S.last_slice = sl
      hit("brk", ev("brk"), function(a, _, n)
        brk_slice(sl, a, 1 / n, m.rev, m.pitch)
      end)
    end
  end

  S.tstep = S.tstep + 1
  S.sib = S.sib + 1
end

------------------------------------------------------------------------
-- transport
------------------------------------------------------------------------

-- the same order as gradient's loop (wait for the bar, then a 16th before
-- each step), so the two land together. now = gradient's MIDI start just
-- arrived on its bar line: skip the bar wait
local function loop(my, now)
  if not now then clock.sync(4) end
  while true do
    clock.sync(1 / 4)
    local swing = params:get("swing") / 100 * (1 - S.chaos * 0.6)
    if S.tstep % 2 == 1 and swing > 0 then
      clock.sleep(beat_sec() * 0.25 * swing)
    end
    if not S.playing or my ~= loop_gen then return end
    play_step()
  end
end

start = function(now)
  if S.playing then return end
  S.playing = true
  S.bpm = clock.get_tempo()
  S.tstep = 0
  S.sib = 0
  loop_gen = loop_gen + 1
  local my = loop_gen
  main_clock = clock.run(function() loop(my, now) end)
  flash("play")
end

stop = function(from_loop)
  S.playing = false
  if main_clock and not from_loop then clock.cancel(main_clock) end
  main_clock = nil
  S.kit_pending = nil
  -- a later solo start shouldn't run on gradient's stale arc
  S.following, S.f_kickless, S.f_energy = false, false, nil
  flash("stop")
end

------------------------------------------------------------------------
-- actions
------------------------------------------------------------------------

-- the running bar's place in its 8-bar block, counted from the phrase
-- anchor (gradient's phrase when following); S.bar is already the next bar
local function block_pos()
  return (S.bar - 1 - (S.phrase_anchor or 0)) % 8
end

local function drop()
  if S.drop_bars > 0 then S.drop_bars = 0; flash("return")
  else S.drop_bars = 16 - block_pos(); flash("drop") end
  C.decide(S)
end

local function strip()
  if S.strip_bars > 0 then S.strip_bars = 0; flash("full kit")
  else S.strip_bars = 16 - block_pos(); flash(S.brk_ready and "strip: break + glitch" or "strip: glitch") end
  C.decide(S)
end

local function fill() fill_now = true; flash("fill") end

local function mutate() C.mutate(S); C.decide(S); flash("mutate") end

local function throw() S.hand_throw = 2; apply_bar(); flash("throw") end

local function build()
  S.drop_bars = 0
  S.nudge = clamp(S.nudge + 0.25, -1, 1)
  C.decide(S)
  flash("build")
end

local function brk_down()
  S.nudge = clamp(S.nudge - 0.35, -1, 1)
  S.drop_bars = 16 - block_pos()
  C.decide(S)
  flash("break")
end

local function hand_glitch(mode)
  return function()
    glitch(mode, mode == 4 and 0.5 or 1, 1)
    flash(GLITCH_NAMES[mode])
  end
end

local function set_kit(i)
  i = clamp(i, 1, #KT.list)
  if S.playing then
    S.kit_pending = i
    flash("kit > " .. KT.names[i])
  else
    S.kit = i
    S.kit_pending = nil
    C.mutate(S, true)
    C.decide(S)
    if params:get("theme_mode") == 1 then theme = i end
    kit_feel()
    VIS.event("kit", i)
    flash("kit " .. KT.names[i])
  end
end

local function set_energy(target)
  if S.mode_play == 3 and not S.following then
    S.hold_energy = clamp(target, 0, 1)
    S.energy = S.hold_energy
  else
    local base = S.energy - S.nudge
    S.nudge = clamp(target - base, -1, 1)
    S.energy = clamp(base + S.nudge, 0, 1)
  end
  C.decide(S)
end

-- hand mutes and solos land now
local function snap()
  C.decide(S)
  for _, k in ipairs(C.PARTS) do
    if not S.want[k] then S.gain[k] = 0 elseif (S.gain[k] or 0) == 0 then S.gain[k] = 1 end
  end
end

local function toggle_mute(k)
  S.mute[k] = not S.mute[k] or nil
  snap()
  flash((S.mute[k] and "mute " or "unmute ") .. k)
end

local function toggle_solo(k)
  S.solo[k] = not S.solo[k] or nil
  snap()
  flash((S.solo[k] and "solo " or "unsolo ") .. k)
end

local function toggle_play() if S.playing then stop() else start() end end

local function fresh()
  local seed = math.random(1, 9999)
  params:set("seed", seed, true)
  C.new_material(S, seed)
  C.decide(S)
  flash("seed " .. seed)
end

------------------------------------------------------------------------
-- break file
------------------------------------------------------------------------

local function brk_fit()
  if S.brk_dur <= 0 then return end
  local want = BRK_BEATS[params:get("brk_beats")]
  if want == 0 then
    -- auto: the beat count whose implied tempo sits nearest ours
    local best, bd = 8, math.huge
    for _, b in ipairs({2, 4, 8, 16, 32}) do
      local bpm = 60 * b / S.brk_dur
      local d = math.abs(math.log(bpm / S.bpm))
      if bpm >= 60 and bpm <= 200 and d < bd then best, bd = b, d end
    end
    want = best
  end
  S.brk_beats = want
end

local function load_break(path)
  if not path or path == "" or path == "-" or path:sub(-1) == "/" then
    S.brk_ready = false
    C.decide(S)
    return
  end
  local ch, frames, rate = audio.file_info(path)
  if not frames or frames <= 0 or not rate or rate <= 0 then
    S.brk_ready = false
    flash("can't read break")
    return
  end
  engine.break_load(path)
  S.brk_dur = frames / rate
  S.brk_ready = true
  brk_fit()
  C.decide(S)
  flash(string.format("break: %d beats", S.brk_beats))
end

------------------------------------------------------------------------
-- keys + encoders
------------------------------------------------------------------------

local PART_GLYPH = {"K", "S", "C", "H", "R", "P", "T", "G", "B"}
local PART_LVL = {kick = "kick_lvl", snare = "snare_lvl", clap = "clap_lvl", hats = "hat_lvl",
  ride = "ride_lvl", perc = "perc_lvl", toms = "tom_lvl", ticks = "tick_lvl", brk = "break_lvl"}

local PAGES = {
  {name = "play",  {"_energy", 1}, {"chaos", 1},      {"dub", 1}},
  {name = "sound", {"kick_tune", 1}, {"kick_decay", 1}, {"snare_tune", 1}},
  {name = "voices", {"kick_model", 1}, {"snare_model", 1}, {"hat_model", 1}},
  {name = "groove", {"groove", 1}, {"perc_model", 1}, {"tick_model", 1}},
  {name = "time", {"meter", 1}, {"group54", 1}, {"group78", 1}},
  {name = "space", {"swing", 1},   {"verb_send", 1},  {"crush_amt", 1}},
  {name = "break", {"break_lvl", 1}, {"brk_pitch", 1}, {"brk_beats", 1}},
  {name = "parts", {"_energy", 1}},
}
local function on_parts() return PAGES[page].name == "parts" end

local function both_keys()
  toggle_play()
  k2_used, k3_used = true, true
end

function key(n, z)
  if n == 1 then
    k1 = z == 1
    if z == 1 then k1_used = false end
  elseif n == 2 then
    if z == 1 then
      k2, k2_used = true, false
      if k3 then both_keys() end
      if k1 then strip(); k2_used, k1_used = true, true end
    else
      k2 = false
      if not k2_used then
        if on_parts() then toggle_mute(C.PARTS[part_sel]) else drop() end
      end
    end
  elseif n == 3 then
    if z == 1 then
      k3, k3_used = true, false
      if k2 then both_keys() end
      if k1 then mutate(); k3_used, k1_used = true, true end
    else
      k3 = false
      if not k3_used then
        if on_parts() then toggle_solo(C.PARTS[part_sel]) else fill() end
      end
    end
  end
end

function enc(n, d)
  if k1 then
    k1_used = true
    if n == 1 then
      params:set("theme_mode", 2)
      params:delta("theme", d)
    elseif n == 2 then
      page = clamp(page + d, 1, #PAGES)
      flash("page " .. PAGES[page].name)
    elseif n == 3 then
      params:set("vis_view", d > 0 and 2 or 1)
      flash("view " .. params:string("vis_view"))
    end
  elseif k2 then
    k2_used = true
    if n == 2 then
      local cur = S.kit_pending or S.kit
      set_kit(cur + (d > 0 and 1 or -1))
    elseif n == 3 then
      params:delta("fills", d)
      flash("fills " .. params:string("fills"))
    end
  elseif k3 then
    k3_used = true
    if n == 2 then
      params:delta("clock_tempo", d)
      flash(math.floor(clock.get_tempo() + 0.5) .. " bpm")
    elseif n == 3 then
      params:delta("play_mode", d)
      flash(params:string("play_mode"))
    end
  elseif on_parts() and n > 1 then
    if n == 2 then
      part_sel = clamp(part_sel + d, 1, #C.PARTS)
      local k = C.PARTS[part_sel]
      flash(k .. (S.solo[k] and " solo" or (S.mute[k] and " muted" or "")))
    else
      local id = PART_LVL[C.PARTS[part_sel]]
      params:delta(id, d)
      flash(params:lookup_param(id).name .. " " .. params:string(id))
    end
  else
    local id, mult = PAGES[page][n][1], PAGES[page][n][2]
    if id == "_energy" then
      if S.mode_play == 3 and not S.following then
        S.hold_energy = clamp(S.hold_energy + d * 0.02, 0, 1)
        S.energy = S.hold_energy
        C.decide(S)
        flash(string.format("energy %d", math.floor(S.hold_energy * 100 + 0.5)))
      else
        S.nudge = clamp(S.nudge + d * 0.03, -0.6, 0.6)
        flash(string.format("energy %+d", math.floor(S.nudge * 100 + 0.5)))
      end
    else
      params:delta(id, d * mult)
      flash(params:lookup_param(id).name .. " " .. params:string(id))
    end
  end
end

------------------------------------------------------------------------
-- screen
------------------------------------------------------------------------

local function text_box(x, y, s, lvl, right)
  local w = screen.text_extents(s)
  local x0 = right and (x - w) or x
  screen.level(0)
  screen.rect(x0 - 1, y - 6, w + 2, 8)
  screen.fill()
  screen.level(lvl)
  screen.move(x0, y)
  screen.text(s)
end

local function bar_meter(x, y, w, v, lvl)
  screen.level(2)
  screen.rect(x, y, w, 2)
  screen.fill()
  local n = math.floor(clamp(v, 0, 1) * w + 0.5)
  if n > 0 then
    screen.level(lvl)
    screen.rect(x, y, n, 2)
    screen.fill()
  end
end

local function draw_hud()
  local hud = params:get("hud")
  local top = kit().name
  if S.kit_pending then top = top .. " > " .. KT.names[S.kit_pending] end
  if k1 then top = "theme " .. VIS.names[theme] end
  if hud < 3 or k1 then text_box(1, 7, top, S.playing and 12 or 5) end
  if page ~= 1 and not k1 then text_box(1, 15, PAGES[page].name, 6) end

  if hud == 1 then
    local st
    if S.following then st = "<> gradient"
    else st = S.section or "-" end
    if S.following and params:get("follow_key") > 1 then st = st .. " " .. NOTE_NAMES[tone_pc() + 1] end
    st = st .. " " .. (S.phrase_pos + 1) .. "/" .. S.phrase_len
    if S.kickless and S.playing then st = st .. " ~" end
    if S.halftime then st = st .. " half" end
    if S.meter ~= 1 then st = st .. " " .. meter_label(S.meter, S.group) end
    text_box(127, 7, st, S.playing and 8 or 3, true)

    screen.level(0)
    screen.rect(0, 54, 128, 10)
    screen.fill()
    screen.level(4)
    screen.move(1, 58); screen.text("e")
    screen.move(1, 64); screen.text("x")
    bar_meter(7, 55, 30, S.energy, S.nudge ~= 0 and 15 or 10)
    bar_meter(7, 61, 30, S.chaos, 15)
    for i, k in ipairs(C.PARTS) do
      local on = S.gain[k] or 0
      if k == "brk" and not S.brk_ready then on = -1 end
      screen.level(on < 0 and 1 or math.floor(2 + on * 12))
      screen.move(44 + (i - 1) * 9, 63)
      screen.text(PART_GLYPH[i])
    end
  end

  if on_parts() then
    screen.level(0)
    screen.rect(0, 36, 128, 17)
    screen.fill()
    local any = next(S.solo) ~= nil
    for i, k in ipairs(C.PARTS) do
      local x = 6 + (i - 1) * 13
      local on = S.gain[k] or 0
      local lvl = S.mute[k] and 2 or (any and not S.solo[k]) and 3 or math.floor(5 + on * 10)
      screen.level(lvl)
      screen.move(x, 47)
      screen.text(PART_GLYPH[i])
      if S.solo[k] then
        screen.level(12)
        screen.rect(x - 2.5, 39.5, 9, 10)
        screen.stroke()
      end
      if i == part_sel then
        screen.level(15)
        screen.rect(x - 1, 51, 6, 1)
        screen.fill()
      end
    end
  end

  local hint
  if k1 then hint = "E1 theme E2 page E3 view"
  elseif k2 and not k3 then hint = "E2 kit  E3 fills"
  elseif k3 and not k2 then hint = "E2 bpm  E3 " .. params:string("play_mode") end
  if hint then
    text_box(64 - screen.text_extents(hint) / 2, 32, hint, 15)
  elseif msg and util.time() - msg_t < 1.5 then
    text_box(64 - screen.text_extents(msg) / 2, 32, msg, 15)
  elseif on_parts() then
    text_box(64 - screen.text_extents("K2 mute  K3 solo") / 2, 32, "K2 mute  K3 solo", 4)
  end
  if not S.playing then text_box(127, 50, "K2+K3 play", 4, true) end
end

local function draw_loop()
  local n = 0
  while true do
    clock.sleep(1 / 20)
    n = n + 1
    S.bpm = clock.get_tempo()
    if n % 4 ~= 0 then GU.redraw() end
    if not _menu.mode then
      screen.clear()
      screen.aa(0)
      VIS.draw(theme, S)
      draw_hud()
      screen.update()
    end
  end
end

------------------------------------------------------------------------
-- params
------------------------------------------------------------------------

local function setup_params()
  local vport_names, vport_ids = {"none"}, {0}
  for i = 1, #midi.vports do
    local nm = midi.vports[i].name
    if nm ~= nil and nm ~= "none" and nm ~= "" then
      table.insert(vport_names, i .. ":" .. nm)
      table.insert(vport_ids, i)
    end
  end

  params:add_separator("BREAKAGE")
  params:add_option("kit", "kit", KT.names, 1)
  params:set_action("kit", function(v) if v ~= (S.kit_pending or S.kit) then set_kit(v) end end)
  params:add_number("chaos", "chaos", 0, 100, 0)
  params:set_action("chaos", function(v) S.chaos = v / 100 end)
  params:add_option("play_mode", "play mode", {"set (endless)", "track", "hold"}, 1)
  params:set_action("play_mode", function(v)
    S.mode_play = v
    if v == 2 then S.track_bar = 0 end
    if v == 3 then S.hold_energy = S.energy end
  end)
  params:add_option("meter", "time signature", METER_NAMES, 1)
  params:set_action("meter", function() if not S.playing then S.sib = 0 end end)
  params:add_option("group54", "5/4 grouping", GROUP54, 1)
  params:add_option("group78", "7/8 grouping", GROUP78, 1)
  params:add_option("phrase_len", "phrase length (bars)", {"8", "16", "32", "64"}, 2)
  params:set_action("phrase_len", function(v)
    local old = S.phrase_len
    S.phrase_len = ({8, 16, 32, 64})[v]
    S.cycle_bars = math.max(S.phrase_len * 4, math.floor(S.cycle_bars * S.phrase_len / old))
  end)
  params:add_number("track_minutes", "track length (min)", 4, 32, 8)
  params:set_action("track_minutes", function(v) S.track_minutes = v end)
  params:add_option("end_action", "track end", {"stop", "next track"}, 2)
  params:set_action("end_action", function(v) S.end_action = v end)
  params:add_option("kit_auto", "kit changes", {"by hand", "on phrases"}, 1)
  params:set_action("kit_auto", function(v) S.kit_auto = v end)
  params:add_option("kit_mix", "kit sets dub/swing/drive", {"off", "on"}, 2)
  local gnames = {"kit"}
  for i, f in ipairs(G.FAMILIES) do gnames[i + 1] = f end
  params:add_option("groove", "groove", gnames, 1)
  params:set_action("groove", function(v)
    S.groove = v > 1 and G.FAMILIES[v - 1] or nil
    if S.pat and S.pat.kick then C.mutate(S, true); C.decide(S) end
  end)
  params:add_option("fills", "fills", {"normal", "busy", "off"}, 1)
  params:set_action("fills", function(v) S.fills = v end)
  params:add_option("kick_style", "kick", {"auto", "always", "never"}, 1)
  params:set_action("kick_style", function(v) S.kick_style = v; C.decide(S) end)
  params:add_option("hat_style", "hats", {"auto", "always", "never"}, 1)
  params:set_action("hat_style", function(v) S.hat_style = v; C.decide(S) end)
  params:add_option("glitch_amt", "glitch", {"off", "on"}, 2)
  params:set_action("glitch_amt", function(v) S.glitch_amt = v == 1 and 1 or 3; C.decide(S) end)
  params:add_option("freeze", "freeze material", {"off", "on"}, 1)
  params:set_action("freeze", function(v) S.freeze = v == 2 end)
  params:add_number("seed", "seed", 1, 9999, 1)
  params:add_trigger("regen", "> rebuild from seed")
  params:set_action("regen", function()
    C.new_material(S, params:get("seed")); C.decide(S); flash("seed " .. params:get("seed"))
  end)
  params:add_trigger("fresh", "> new random material")
  params:set_action("fresh", fresh)

  params:add_separator("PERFORM")
  for _, a in ipairs({{"p_play", "> play / stop", toggle_play}, {"p_drop", "> drop", drop},
      {"p_fill", "> fill", fill}, {"p_mutate", "> mutate", mutate}, {"p_strip", "> strip", strip},
      {"p_throw", "> throw", throw}, {"p_build", "> build", build}, {"p_break", "> break down", brk_down},
      {"p_stutter", "> stutter", hand_glitch(1)}, {"p_tapestop", "> tape stop", hand_glitch(2)},
      {"p_reverse", "> reverse", hand_glitch(3)}, {"p_chop", "> chop", hand_glitch(4)},
      {"p_kit_next", "> next kit", function() set_kit((S.kit_pending or S.kit) % #KT.list + 1) end},
      {"p_kit_prev", "> prev kit", function() set_kit(((S.kit_pending or S.kit) - 2) % #KT.list + 1) end}}) do
    params:add_trigger(a[1], a[2])
    params:set_action(a[1], a[3])
  end

  params:add_separator("FOLLOW")
  params:add_option("follow", "follow gradient", {"auto", "off"}, 1)
  params:set_action("follow", function() F.bar() end)
  params:add_option("follow_dev", "midi in from", vport_names, 1)
  params:set_action("follow_dev", function(v) F.connect(vport_ids[v]) end)
  params:add_number("follow_ch", "cc channel", 1, 16, 16)
  params:add_number("follow_energy_cc", "energy cc", 0, 127, 20)
  params:add_number("follow_dub_cc", "dub cc", 0, 127, 21)
  params:add_number("follow_phrase_cc", "phrase pulse cc", 0, 127, 23)
  params:add_number("follow_kickless_cc", "kickless cc", 0, 127, 24)
  params:add_option("follow_key", "follow its key", {"off", "key", "key + chords"}, 3)
  params:add_number("follow_key_cc", "key root cc", 0, 127, 25)
  params:add_number("follow_mode_cc", "mode cc", 0, 127, 26)
  params:add_number("follow_chord_cc", "chord root cc", 0, 127, 27)
  params:add_option("follow_dub", "follow its dub", {"off", "on"}, 2)
  params:add_option("follow_transport", "follow start/stop", {"off", "on"}, 2)
  params:add_option("follow_note_ch", "root from notes on", {"off", "ch 1", "ch 2", "ch 3", "ch 4",
    "ch 5", "ch 6", "ch 7", "ch 8", "ch 9", "ch 10", "ch 11", "ch 12", "ch 13", "ch 14", "ch 15", "ch 16"}, 1)

  params:add_separator("BREAK")
  params:add_file("brk_file", "break file", _path.audio)
  params:set_action("brk_file", load_break)
  params:add_option("break_mode", "break", {"off", "with the kit", "replaces snare + hats", "replaces the kit"}, 2)
  params:set_action("break_mode", function(v) S.break_mode = v; C.decide(S) end)
  params:add_option("brk_beats", "break length (beats)", {"auto", "2", "4", "8", "16", "32"}, 1)
  params:set_action("brk_beats", function() brk_fit() end)
  params:add_number("brk_pitch", "break pitch", -12, 12, 0)

  params:add_separator("MIX")
  params:add_number("dub", "dub", 0, 100, 50)
  params:set_action("dub", function() apply_bar() end)
  params:add_option("echo_div", "echo time", ECHO_DIV_NAMES, 2)
  params:add_number("swing", "swing %", 0, 50, 12)
  params:add_number("crush_amt", "chaos crush", 0, 100, 40)
  params:add_number("verb_send", "reverb send", 0, 200, 100)
  params:set_action("verb_send", function() apply_bar() end)
  params:add_number("drive", "drive", 0, 100, 20)
  params:set_action("drive", function() apply_bar() end)
  params:add_control("verb_size", "reverb size", controlspec.new(0, 1, "lin", 0.01, 0.7))
  params:set_action("verb_size", function(v) engine.tweak("verb_size", v) end)
  params:add_control("echo_wow", "echo wow", controlspec.new(0, 1, "lin", 0.01, 0.3))
  params:set_action("echo_wow", function(v) engine.tweak("echo_wow", v) end)
  params:add_control("level", "level", controlspec.new(0, 1, "lin", 0.01, 0.8))
  params:set_action("level", function(v) engine.tweak("level", v) end)
  params:add_number("glitch_mix", "glitch depth", 0, 100, 100)

  params:add_separator("breakage_levels", "LEVELS")
  for _, p in ipairs({"kick", "snare", "clap", "rim", "hat", "ride", "perc", "tom", "tick", "break"}) do
    params:add_number(p .. "_lvl", p .. " level", 0, 150, 100)
    params:set_action(p .. "_lvl", function(v) engine.tweak(p .. "_lvl", v / 100) end)
  end

  params:add_separator("SOUND")
  params:add_number("kick_tune", "kick tune", -12, 12, 0)
  params:add_number("kick_decay", "kick decay %", 25, 250, 100)
  params:add_number("snare_tune", "snare tune", -12, 12, 0)
  params:add_number("hat_tone", "hat tone %", 40, 160, 100)
  params:add_option("root", "key", NOTE_NAMES, 10)
  params:set_action("root", function(v) S.root_pc = v - 1 end)
  params:add_option("scale", "scale", SCALE_NAMES, 1)
  params:add_option("tune_key", "tune drums to key", {"off", "on"}, 2)
  params:add_option("kick_model", "kick model", KICK_MODELS, 1)
  params:add_option("snare_model", "snare model", SNARE_MODELS, 1)
  params:add_option("hat_model", "hat model", HAT_MODELS, 1)
  params:add_option("perc_model", "perc model", PERC_MODELS, 1)
  params:add_option("tick_model", "glitch tick model", TICK_MODELS, 1)
  params:add_number("snare_decay", "snare decay %", 25, 300, 100)
  params:add_number("hat_decay", "open hat decay %", 25, 300, 100)
  params:add_number("perc_decay", "perc decay %", 25, 300, 100)

  params:add_separator("VISUALS")
  params:add_option("theme_mode", "theme", {"follows the kit", "fixed"}, 1)
  params:set_action("theme_mode", function(v) if v == 1 then theme = S.kit end end)
  params:add_option("theme", "fixed theme", VIS.names, 1)
  params:set_action("theme", function(v) if params:get("theme_mode") == 2 then theme = v end end)
  params:add_option("hud", "overlay", {"full", "minimal", "off"}, 1)
  params:add_number("vis_speed", "speed", 1, 10, 3)
  params:add_number("vis_brightness", "brightness", 1, 15, 10)
  params:add_option("vis_view", "view", {"one", "two"}, 1)
  params:add_option("vis_shake", "kick shake", {"off", "soft", "hard"}, 1)
  params:add_number("vis_react", "audio reactivity", 0, 10, 5)
end

------------------------------------------------------------------------
-- lifecycle
------------------------------------------------------------------------

function init()
  VIS.init()
  F.step_in_bar = function()
    if not S.playing or S.tstep == 0 then return nil end
    return (S.sib - 1) % S.bar_len
  end
  F.N_MODES = #SCALES
  F.init(S, {
    start = function() start(true) end,
    stop = function() stop() end,
    changed = function(on) flash(on and "following gradient" or "solo") end,
    late_phrase = function() S.phrase_pos = 0; C.phrase(S) end,
  })
  C.new_material(S, 1)
  setup_params()
  params:bang()

  math.randomseed(os.time())
  local seed = math.random(1, 9999)
  params:set("seed", seed, true)
  C.new_material(S, seed)
  C.phrase(S)
  for _, k in ipairs(C.PARTS) do S.gain[k] = S.want[k] and 1 or 0 end
  kit_feel()
  apply_bar()

  for _, name in ipairs({"out_amp", "out_lo", "out_mid", "out_hi"}) do
    local ok, p = pcall(poll.set, name, function(v) VIS.audio(name, v) end)
    if ok and p then p.time = 1 / 20; p:start() end
  end

  clock.transport.start = function() start() end
  clock.transport.stop  = function() stop() end

  GU.init({
    S = S, play = toggle_play, drop = drop, fill = fill, mutate = mutate, strip = strip,
    throw = throw, build = build, brk_down = brk_down,
    stutter = hand_glitch(1), tapestop = hand_glitch(2), reverse = hand_glitch(3),
    set_energy = set_energy, set_kit = set_kit, toggle_mute = toggle_mute,
    set_chaos = function(v) params:set("chaos", math.floor(v * 100 + 0.5)) end,
    pad = function(sl) brk_slice(sl, 0.9, 1, false, 0) end,
  })

  draw_clock = clock.run(draw_loop)
end

function cleanup()
  stop()
  if draw_clock then clock.cancel(draw_clock) end
end

-- for the headless sim
_breakage = {play_step = play_step, S = S, set_kit = set_kit, fill = fill, drop = drop,
  strip = strip, load_break = load_break, F = F}
