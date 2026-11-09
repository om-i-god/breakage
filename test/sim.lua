-- headless sim: stubs the norns APIs breakage touches, drives the step
-- clock, and checks the conductor, the engine calls, follow and the controls.
-- run from repo root:  lua test/sim.lua [bars]

local BARS = tonumber(arg[1]) or 200
local VERBOSE = os.getenv("V")

calls = {}
local FMT, TWEAKS = {}, {}
do
  local f = assert(io.open("lib/Engine_Breakage.sc"))
  local src = f:read("a")
  f:close()
  for name, fmt in src:gmatch('addCommand%(\\([%w_]+), "(%w*)"') do FMT[name] = fmt end
  for k in src:gmatch('\\([%w_]+) %->') do TWEAKS[k] = true end
end
TWV = {}
engine = setmetatable({}, {__index = function(_, k)
  if k == "name" then return nil end
  return function(...)
    local fmt = FMT[k]
    if not fmt then error("engine has no command '" .. k .. "'", 2) end
    local n = select("#", ...)
    if n ~= #fmt then error(string.format("engine.%s: %d args, engine wants %d (%s)", k, n, #fmt, fmt), 2) end
    for i = 1, n do
      local v, t = select(i, ...), fmt:sub(i, i)
      if t == "f" or t == "i" then
        if type(v) ~= "number" then error("engine." .. k .. " arg " .. i .. " not a number", 2) end
        if v ~= v or v == math.huge or v == -math.huge then error("engine." .. k .. " arg " .. i .. " is NaN/inf", 2) end
      end
      if t == "s" and type(v) ~= "string" then error("engine." .. k .. " arg " .. i .. " not a string", 2) end
    end
    if k == "tweak" and not TWEAKS[(...)] then error("engine.tweak: unknown key '" .. (...) .. "'", 2) end
    calls[k] = (calls[k] or 0) + 1
    if perc_log and k == "perc" then perc_log[#perc_log + 1] = {select(5, ...), select(6, ...), select(1, ...), select(2, ...)} end
    if step_log and (k == "snare" or k == "rim" or k == "kick") then
      step_log[#step_log + 1] = {k, _breakage.S.sib, _breakage.S.bar}
    end
    if pitch_log then
      -- midi notes of the pitched voices: kick / snare / rim tune, tom / perc / tick hz
      local note
      if k == "kick" or k == "snare" or k == "rim" then note = select(2, ...)
      elseif k == "tom" then note = 69 + 12 * math.log(select(2, ...) / 440, 2)
      elseif k == "perc" and select(5, ...) < 9 and select(5, ...) ~= 5 then note = 69 + 12 * math.log(select(2, ...) / 440, 2)
      elseif k == "tick" then note = 69 + 12 * math.log(select(3, ...) / 440, 2) end
      if note then pitch_log[#pitch_log + 1] = {k, note} end
    end
    if k == "tweak" then TWV[(...)] = select(2, ...) end
    -- which voice models get played: kick / snare type, hat type, perc kind, tick kind
    local TYPE_ARG = {kick = 6, snare = 7, hat = 5, perc = 5, tick = 2}
    if TYPE_ARG[k] then
      local ty = select(TYPE_ARG[k], ...)
      assert(ty == math.floor(ty) and ty >= 1, "engine." .. k .. " type " .. ty)
      types[k .. ty] = (types[k .. ty] or 0) + 1
    end
    if k == "brk" then
      local amp, pos, len, rate = ...
      assert(pos >= 0 and pos <= 1, "brk pos out of range: " .. pos)
      assert(len > 0 and len < 2, "brk len odd: " .. len)
      assert(math.abs(rate) > 0.05 and math.abs(rate) < 8, "brk rate odd: " .. rate)
    end
    if amp_check and (k == "kick" or k == "snare" or k == "hat" or k == "tick" or k == "perc") then
      local a = (...)
      assert(a >= 0 and a <= 1.5, "engine." .. k .. " amp " .. a)
    end
  end
end})
amp_check = true
types = {}

function include(p) return dofile(p .. ".lua") end

-- params ---------------------------------------------------------------
P = {order = {}, defs = {}}
params = {}
local function add(id, def) def.id = id; P.defs[id] = def; table.insert(P.order, id) end
function params:add_separator() end
function params:add_option(id, _, opts, d) add(id, {v = d, lo = 1, hi = #opts, opts = opts}) end
function params:add_number(id, _, lo, hi, d) add(id, {v = d, lo = lo, hi = hi}) end
function params:add_control(id, _, spec) add(id, {v = spec.default, lo = spec.min, hi = spec.max, f = true}) end
function params:add_file(id, _, d) add(id, {v = d}) end
function params:add_trigger(id) add(id, {v = 0, trig = true}) end
function params:set_action(id, fn) P.defs[id].action = fn end
function params:get(id)
  if id == "clock_tempo" then return 128 end
  return P.defs[id].v
end
function params:string(id) local d = P.defs[id]; return d.opts and d.opts[d.v] or tostring(d.v) end
function params:set(id, v, silent)
  if id == "clock_tempo" then return end
  local d = assert(P.defs[id], "no param " .. id); d.v = v
  if not silent and d.action then d.action(v) end
end
function params:delta(id, n)
  if id == "clock_tempo" then return end
  local d = assert(P.defs[id], "no param " .. id)
  if d.trig then return end
  params:set(id, math.max(d.lo, math.min(d.hi, d.v + n * (d.f and 0.01 or 1))))
end
function params:lookup_param(id) return {name = id} end
function params:bang()
  for _, id in ipairs(P.order) do
    local d = P.defs[id]
    if d.action and not d.trig then d.action(d.v) end
  end
end
controlspec = {new = function(min, max, _, _, default) return {min = min, max = max, default = default} end}

-- clock ------------------------------------------------------------------
local threads, nid = {}, 0
clock = {transport = {}}
function clock.run(f) nid = nid + 1; threads[nid] = coroutine.create(f); return nid end
function clock.cancel(id) threads[id] = nil end
function clock.sync() coroutine.yield() end
function clock.sleep() coroutine.yield("sleep") end
function clock.get_beat_sec() return 60 / 128 end
function clock.get_tempo() return 128 end

-- midi -------------------------------------------------------------------
local follow_dev
midi = {vports = {{name = "gradient"}},
  connect = function()
    follow_dev = {}
    return follow_dev
  end,
  to_msg = function(d)
    local st, ch = d[1] & 0xF0, (d[1] & 0x0F) + 1
    if d[1] == 0xFA then return {type = "start"} end
    if d[1] == 0xFC then return {type = "stop"} end
    if st == 0xB0 then return {type = "cc", ch = ch, cc = d[2], val = d[3]} end
    if st == 0x90 then return {type = "note_on", ch = ch, note = d[2], vel = d[3]} end
  end}
local function cc(n, v) follow_dev.event({0xB0 + 15, n, v}) end

grid_dev = {cols = 16, rows = 8, leds = 0}
function grid_dev:all() end
function grid_dev:led() self.leds = self.leds + 1 end
function grid_dev:refresh() calls.grid_refresh = (calls.grid_refresh or 0) + 1 end
grid = {connect = function() return grid_dev end}
polls = {}
poll = {set = function(name, fn) polls[name] = fn; return {start = function() end} end}
screen = setmetatable({text_extents = function() return 20, 6 end},
  {__index = function() return function() end end})
_path = {audio = "/home/we/dust/audio/"}
VT = 0
util = {time = function() return VT end}
_menu = {mode = false}
audio = {file_info = function(p) return 2, 44100 * 4, 44100 end}   -- a 4 s stereo break

dofile("breakage.lua")
init()
local B = _breakage
local S = B.S

local function tick_all()
  VT = VT + 60 / 128 / 4
  for id, co in pairs(threads) do
    if coroutine.status(co) == "dead" then threads[id] = nil
    else
      local ok, err = coroutine.resume(co)
      if not ok then error("thread " .. id .. ": " .. tostring(err) .. "\n" .. debug.traceback(co)) end
    end
  end
end
local function run_bars(n, each)
  local b0 = S.bar
  local guard = 0
  while S.bar < b0 + n do
    tick_all()
    guard = guard + 1
    assert(guard < n * 28 * 4 + 64, "clock stalled")
    if each then each() end
  end
end

local function log(tag)
  local g = {}
  for _, k in ipairs({"kick", "snare", "clap", "hats", "ride", "perc", "toms", "ticks", "brk"}) do
    g[#g + 1] = k:sub(1, 2) .. "=" .. string.format("%.1f", S.gain[k] or 0)
  end
  print(string.format("%-8s bar %4d %-7s e=%.2f x=%.2f kit=%-7s fam=%-7s kl=%-5s fill=%-8s edit=%-8s %s",
    tag, S.bar, S.section or "-", S.energy, S.chaos, B.S.kit and include("lib/kits").names[S.kit],
    S.pat.family, tostring(S.kickless), S.fill and S.fill.kind or "-", S.edit and S.edit.kind or "-",
    table.concat(g, " ")))
end

-- play -------------------------------------------------------------------
key(2, 1); key(3, 1); key(3, 0); key(2, 0)
assert(S.playing, "K2+K3 didn't start")

-- solo arc, every kit, chaos sweeps
local KT = include("lib/kits")
local hits0 = {}
for k = 1, #KT.list do
  B.set_kit(k)
  for _, c in ipairs({0, 50, 100}) do
    params:set("chaos", c)
    run_bars(math.max(4, BARS // 24))
    if VERBOSE then log("kit" .. k) end
  end
  assert(S.kit == k, "kit " .. k .. " never landed")
end
print("kits x chaos ok; kick/snare/hat/tick/perc/tom calls:",
  calls.kick or 0, calls.snare or 0, calls.hat or 0, calls.tick or 0, calls.perc or 0, calls.tom or 0)
assert((calls.kick or 0) > 50 and (calls.hat or 0) > 50 and (calls.snare or 0) + (calls.rim or 0) > 20)
-- every kit's own voice models are heard (held high, so no kickless trough)
params:set("play_mode", 3); S.hold_energy = 0.9; params:set("chaos", 20)
for k, kt in ipairs(KT.list) do
  B.set_kit(k); run_bars(1)
  local k0, h0 = types["kick" .. kt.kick[1]] or 0, types["hat" .. kt.hat[1]] or 0
  for _ = 1, 8 do
    run_bars(2)
    if (types["kick" .. kt.kick[1]] or 0) > k0 and (types["hat" .. kt.hat[1]] or 0) > h0 then break end
  end
  assert(types["kick" .. kt.kick[1]], kt.name .. ": kick model " .. kt.kick[1] .. " never played")
  assert(types["hat" .. kt.hat[1]], kt.name .. ": hat model " .. kt.hat[1] .. " never played")
  local any = false
  for _, pk in ipairs(kt.perc) do any = any or types["perc" .. pk] ~= nil end
  assert(any, kt.name .. ": none of its perc played")
end
for ty = 1, 15 do assert(types["snare" .. ty], "snare model " .. ty .. " never played") end

-- SOUND > models override the kit's own, on every voice
B.set_kit(10); params:set("chaos", 60)
params:set("play_mode", 3); S.hold_energy = 0.9
local OVR = {{"kick_model", "kick", 17}, {"snare_model", "snare", 16}, {"hat_model", "hat", 10},
  {"perc_model", "perc", 18}, {"tick_model", "tick", 9}}
for _, o in ipairs(OVR) do
  local id, voice, n = o[1], o[2], o[3]
  for m = 2, n do
    params:set(id, m)
    local before = types[voice .. (m - 1)] or 0
    for _ = 1, 16 do
      run_bars(2)
      if (types[voice .. (m - 1)] or 0) > before then break end
      if voice == "snare" then key(1, 1); key(3, 1); key(3, 0); key(1, 0) end  -- mutate: a phrase with snares, not rims
    end
    assert((types[voice .. (m - 1)] or 0) > before, id .. " " .. m .. ": " .. voice .. " model " .. (m - 1) .. " never played")
  end
  params:set(id, 1)
end
for _, id in ipairs({"snare_decay", "hat_decay", "perc_decay"}) do
  params:set(id, 300); run_bars(2); params:set(id, 25); run_bars(2); params:set(id, 100)
end
params:set("play_mode", 1)
print("voice models ok")

-- MELODIC: a voice's tone reaches the engine, octave doubles its pitch,
-- level 0 silences it, and the others keep theirs
params:set("play_mode", 3); S.hold_energy = 0.9; params:set("chaos", 30)
params:set("perc_model", 2)                                     -- every perc a conga
params:set("mel_conga_tone", 100)
perc_log = {}; run_bars(4)
assert(#perc_log > 0, "no congas")
local hz0 = {}
for _, p in ipairs(perc_log) do
  assert(p[1] == 1 and math.abs(p[2] - 1) < 1e-9, "conga tone not 1: " .. tostring(p[2]))
  hz0[#hz0 + 1] = p[4]
end
params:set("mel_conga_oct", 1); perc_log = {}; run_bars(4)
local lo_ok = false
for _, p in ipairs(perc_log) do if p[4] > 150 then lo_ok = true end end
assert(lo_ok, "conga octave +1 didn't raise it")
params:set("mel_conga_lvl", 0); perc_log = {}; run_bars(3)
assert(#perc_log == 0, "conga level 0 still played " .. #perc_log)
for _, id in ipairs({"mel_conga_tone", "mel_conga_oct", "mel_conga_lvl"}) do params:set(id, ({mel_conga_tone = 50, mel_conga_oct = 0, mel_conga_lvl = 100})[id]) end
params:set("perc_model", 1); perc_log = nil; params:set("play_mode", 1)
print("melodic ok")

-- PARAMS > groove forces a family on any kit; back to kit lets the kit choose
local G = include("lib/gen")
for gi = 2, #G.FAMILIES + 1 do
  params:set("groove", gi)
  run_bars(2)
  local want = G.FAMILIES[gi - 1]
  assert(S.pat.family == want or S.pat.family == "brk", "groove " .. want .. " gave " .. tostring(S.pat.family))
end
params:set("groove", 1)
assert(S.groove == nil, "groove kit left a forced family")
-- time signatures: bar lengths, and the 5/4 groupings move the backbeat
params:set("fills", 3); params:set("play_mode", 3); S.hold_energy = 0.9
B.set_kit(4); params:set("chaos", 0)
local LEN = {16, 12, 20, 12, 14, 18, 10, 28}
for m = 1, 8 do
  params:set("meter", m)
  run_bars(2)
  local t0 = S.tstep
  run_bars(3)
  assert(S.tstep - t0 == 3 * LEN[m], "meter " .. m .. ": " .. (S.tstep - t0) / 3 .. " steps a bar, want " .. LEN[m])
  assert(S.bar_len == LEN[m], "meter " .. m .. " bar_len " .. S.bar_len)
end
-- electro's backbeat is pattern steps 5 and 13 (beats 2 and 4): in 5/4 each
-- grouping puts it on its own beats
params:set("meter", 3); params:set("trip54", 1)
local WANT = {[1] = {[4] = true, [8] = true, [16] = true},     -- 3+2:   K S s | K S
              [2] = {[4] = true, [12] = true, [16] = true},    -- 2+3:   K S | K S s
              [3] = {[4] = true, [12] = true}}                 -- 2+2+1: K S | K S | K
for g = 1, 3 do
  params:set("group54", g)
  params:set("groove", 1 + 4)                                    -- electro
  run_bars(2)
  step_log = {}
  run_bars(4)
  local seen = {}
  for _, e in ipairs(step_log) do
    if e[1] ~= "kick" then
      local st = e[2]                                            -- sib is the step being played
      assert(WANT[g][st], "5/4 grouping " .. g .. ": backbeat on step " .. st)
      seen[st] = true
    end
  end
  for st in pairs(WANT[g]) do assert(seen[st], "5/4 grouping " .. g .. ": no backbeat on step " .. st) end
  step_log = nil
end
-- 2+2+1 opens on a triplet: one kick and two rims across beat 1, nothing
-- else from the groove on it; off, the groove's beat 1 is back
params:set("group54", 3); params:set("trip54", 2)
run_bars(2)
step_log = {}
local bars = 0
run_bars(6, function() end)
local per = {}
for _, e in ipairs(step_log) do
  if e[2] < 4 then
    local b = per[e[3]] or {kick = 0, snare = 0, rim = 0}
    per[e[3]] = b
    b[e[1]] = b[e[1]] + 1
  end
end
local last = 0
for bar in pairs(per) do last = math.max(last, bar) end
per[last] = nil                                   -- the run stops on its downbeat: rims still to come
-- beat 1 holds only the triplet: one kick at most (none in a kickless bar),
-- and in most bars the full kick-rim-rim figure
for bar, b in pairs(per) do
  assert(b.kick <= 1 and b.snare == 0 and b.rim <= 2, string.format("bar %d: beat 1 kick %d snare %d rim %d", bar, b.kick, b.snare, b.rim))
  if b.kick == 1 and b.rim == 2 then bars = bars + 1 end
end
assert(bars >= 3, "full triplets in only " .. bars .. " bars")
step_log = nil
params:set("trip54", 1)
params:set("groove", 1); params:set("meter", 1); params:set("group54", 1)
params:set("fills", 1); params:set("play_mode", 1)
print("time signatures ok")

-- the minipops presets play their percussion parts
B.set_kit(14); params:set("chaos", 0); run_bars(2)
local p0 = types.perc9 or 0
for _ = 1, 12 do params:set("groove", 13); run_bars(2) end   -- chacha: guiro on the downbeats
params:set("groove", 1)
assert((types.perc9 or 0) > p0, "chacha never scraped the guiro")
print("grooves ok")

-- chaos really ratchets: more snare hits per bar at 100 than at 0
local function rate(c, bars)
  params:set("chaos", c)
  params:set("play_mode", 3); S.hold_energy = 0.85
  run_bars(2)
  local s0 = (calls.snare or 0) + (calls.rim or 0) + (calls.tick or 0)
  run_bars(bars)
  return ((calls.snare or 0) + (calls.rim or 0) + (calls.tick or 0) - s0) / bars
end
B.set_kit(7); run_bars(1)
params:set("chaos", 0)
local lo, hi = rate(0, 32), rate(100, 32)
print(string.format("drill kit snare+tick per bar: chaos 0 %.1f, chaos 100 %.1f", lo, hi))
assert(hi > lo * 1.5, "chaos didn't densify the drill kit")
params:set("play_mode", 1)

-- the break
params:set("brk_file", "/home/we/dust/audio/amen.wav")
assert(S.brk_ready and S.brk_beats == 8, "break didn't load / fit (beats " .. S.brk_beats .. ")")
params:set("break_mode", 4)
params:set("chaos", 60)
local b0 = calls.brk or 0
run_bars(16)
assert((calls.brk or 0) - b0 > 100, "break barely played: " .. ((calls.brk or 0) - b0))
assert((S.gain.kick or 0) == 0, "break replaces the kit but the kick is in")
params:set("break_mode", 2)
print("break ok:", (calls.brk or 0) - b0, "slices in 16 bars")

-- fills: K3 fires one; off = none; busy = more
key(3, 1); key(3, 0)
run_bars(1)
params:set("fills", 3)
run_bars(2)
run_bars(32, function() assert(not S.fill, "fill with fills off") end)
params:set("fills", 1)
local seen = {}
params:set("chaos", 80)
run_bars(160, function() if S.fill then seen[S.fill.kind] = true end end)
local kinds = {}
for k in pairs(seen) do kinds[#kinds + 1] = k end
table.sort(kinds)
print("fill kinds at chaos 80:", table.concat(kinds, " "))
assert(#kinds >= 3, "too few fill kinds")
-- a dip always opens on the next bar
assert(TWV.dip == 20000 or (S.fill and S.fill.kind == "dip"), "dip stuck")

-- follow gradient ----------------------------------------------------------
params:set("follow_dev", 2)
params:set("play_mode", 1)
params:set("chaos", 30)
cc(20, 20); cc(23, 0)
assert(S.following, "didn't start following on a cc")
-- gradient's arc: heartbeat every bar, phrase pulse every 32 bars, energy ramps
local pulses = 0
for bar = 1, 96 do
  local e = math.floor(127 * (0.2 + 0.7 * (bar / 96)))
  run_bars(1)
  -- gradient's bar message arrives a hair after our bar starts
  local p = (bar % 32 == 1) and 127 or 0
  if p > 0 then pulses = pulses + 1 end
  cc(20, e); cc(23, p); cc(24, (bar > 40 and bar < 56) and 127 or 0)
  if p > 0 and bar > 33 then
    assert(S.phrase_pos == 0, "phrase edge off gradient's pulse: pos " .. S.phrase_pos)
  end
  if bar == 48 then assert(S.kickless, "gradient kickless not followed") end
end
assert(S.phrase_len == 32, "phrase length not learned from pulses: " .. S.phrase_len)
assert(math.abs(S.energy - 0.9) < 0.12, "energy not following: " .. S.energy)
-- phrase edges line up with gradient's pulses
print("follow ok: phrase", S.phrase_len, "energy", string.format("%.2f", S.energy), "pos", S.phrase_pos)
-- gradient goes quiet: back to solo, no jump
local e_before = S.energy
run_bars(6)
assert(not S.following, "still following after gradient went quiet")
assert(math.abs(S.energy - e_before) < 0.2, "energy jumped going solo: " .. e_before .. " -> " .. S.energy)
run_bars(40)
print("solo again ok, energy", string.format("%.2f", S.energy))
-- gradient's start/stop
follow_dev.event({0xFC})
assert(not S.playing, "midi stop not followed")
assert(not S.following, "still following after a stop")
-- a shared start: gradient's MIDI start lands on its bar line; breakage's
-- first step comes a 16th later (no bar wait), its bar-1 pulse right after
local bar0 = S.bar
follow_dev.event({0xFA})
assert(S.playing, "midi start not followed")
tick_all(); tick_all()
assert(S.bar == bar0 + 1, "first bar not played right after a midi start")
cc(20, 64); cc(23, 127); cc(24, 0)
assert(S.phrase_anchor == bar0 and S.phrase_pos == 0, "shared start: phrase not anchored on bar 1")
-- pulses that arrive just before our downbeat (after step 15) belong to the next bar
run_bars(31)
while S.tstep % 16 ~= 0 do tick_all() end           -- step 15 just played
cc(20, 64); cc(23, 127)
assert(S.phrase_anchor == S.bar, "early pulse not placed on the coming bar")
run_bars(1)
assert(S.phrase_pos == 0, "phrase edge missed after an early pulse")
run_bars(2)

-- gradient's key: D dorian, on an A chord. drums snap into it
cc(25, 2); cc(26, 2); cc(27, 9)
assert(params:get("root") == 3 and params:get("scale") == 2, "key / mode ccs not taken")
assert(S.f_chord == 9, "chord root cc not taken")
params:set("play_mode", 3); S.hold_energy = 0.9; params:set("chaos", 50)
B.set_kit(13); run_bars(1)                               -- acoustic: toms, log, plinks
pitch_log = {}
for _ = 1, 12 do cc(20, 115); cc(23, 0); run_bars(1) end
local DOR = {[2] = true, [4] = true, [5] = true, [7] = true, [9] = true, [11] = true, [0] = true}
local seen_k = {}
for _, p in ipairs(pitch_log) do
  local n = math.floor(p[2] + 0.5)
  seen_k[p[1]] = true
  -- snares and rims glide up in rolls and drills, on purpose: not checked
  if p[1] ~= "snare" and p[1] ~= "rim" then
    assert(math.abs(p[2] - n) < 0.01, p[1] .. " off the semitone grid: " .. p[2])
    if p[1] == "kick" then assert(n % 12 == 2, "kick not on D: " .. n)
    else assert(DOR[n % 12], p[1] .. " out of D dorian: " .. n) end
  end
end
assert(seen_k.kick and (seen_k.tom or seen_k.perc), "no pitched hits logged")
-- tune off: the kit's own tuning again
params:set("tune_key", 1); pitch_log = {}; run_bars(2)
for _, p in ipairs(pitch_log) do
  if p[1] == "kick" then assert(p[2] == include("lib/kits").list[13].kick[2], "tune off still moved the kick") end
end
params:set("tune_key", 2); pitch_log = nil
params:set("play_mode", 1)
print("key follow ok")

-- controls -----------------------------------------------------------------
key(2, 1); key(2, 0); assert(S.drop_bars > 0, "drop")
run_bars(1); assert(not S.want.kick, "kick in during a drop")
key(2, 1); key(2, 0)
key(1, 1); key(3, 1); key(3, 0); key(1, 0)            -- mutate
key(1, 1); key(2, 1); key(2, 0); key(1, 0)            -- strip
run_bars(1); assert(not S.want.snare and not S.want.kick, "strip left the kit in")
key(1, 1); key(2, 1); key(2, 0); key(1, 0)
key(2, 1); enc(2, 1); key(2, 0)                       -- kit next (pending)
assert(S.kit_pending, "hold K2 + E2 didn't queue a kit")
run_bars(1); assert(not S.kit_pending, "kit didn't land on the bar")
key(3, 1); enc(3, 1); key(3, 0)
for pg = 1, 10 do
  key(1, 1); enc(2, 1); key(1, 0)
  enc(1, 2); enc(2, -1); enc(3, 1)
end
-- parts page: mute + solo
key(1, 1); enc(2, 10); key(1, 0)
enc(2, -10)
key(2, 1); key(2, 0); assert(S.mute.kick and (S.gain.kick or 0) == 0, "parts mute")
key(2, 1); key(2, 0)
enc(2, 3)
key(3, 1); key(3, 0); assert(S.solo.hats, "parts solo")
run_bars(1)
assert((S.gain.kick or 0) == 0 and (S.gain.snare or 0) == 0, "solo didn't silence the rest")
key(3, 1); key(3, 0)
key(1, 1); enc(2, -10); key(1, 0)
-- grid
for _, x in ipairs({1, 2, 3, 4, 5, 7, 8, 10, 11, 12}) do grid_dev.key(x, 8, 1) end
grid_dev.key(12, 2, 1); grid_dev.key(16, 3, 1); grid_dev.key(3, 4, 1); grid_dev.key(2, 5, 1)
grid_dev.key(5, 6, 1)
-- the kit row pages: key 16 flips to kits 16-26
B.set_kit(1); run_bars(2)
grid_dev.key(16, 4, 1); grid_dev.key(5, 4, 1); run_bars(2)
assert(S.kit == 20, "grid page 2 key 5 should be kit 20, got " .. S.kit)
run_bars(4)
for _, id in ipairs({"p_drop", "p_fill", "p_mutate", "p_strip", "p_throw", "p_build", "p_break",
    "p_stutter", "p_tapestop", "p_reverse", "p_chop", "p_kit_next", "p_kit_prev"}) do
  P.defs[id].action()
end
run_bars(8)
-- a drop lasts to the end of the next 8-bar block, not a bar short
run_bars(8)
for i = 1, 6 do tick_all() end
local pos = (S.bar - 1 - S.phrase_anchor) % 8
key(2, 1); key(2, 0)
run_bars(16 - pos - 1)
assert(S.drop_bars == 1 and not S.want.kick, "drop ended early")
run_bars(1)
assert(S.drop_bars == 0 and (S.bar - 1 - S.phrase_anchor) % 8 == 0, "drop didn't end on a block downbeat")
-- a kit picked while playing, then stop + another pick: the later pick wins
B.set_kit(2)
key(2, 1); key(3, 1); key(3, 0); key(2, 0)
assert(not S.playing)
B.set_kit(5)
key(2, 1); key(3, 1); key(3, 0); key(2, 0)
run_bars(2)
assert(S.kit == 5, "stale pending kit landed: " .. S.kit)
-- track end = stop, then play again: it plays
params:set("end_action", 1)
params:set("play_mode", 2); params:set("track_minutes", 4)
do local g = 0; while S.playing do tick_all(); g = g + 1; assert(g < 16 * 4 * 700, 'track never ended') end end
assert(not S.playing, "track never ended")
local b1 = S.bar
key(2, 1); key(3, 1); key(3, 0); key(2, 0)
for i = 1, 16 * 8 do tick_all() end
assert(S.playing and S.bar > b1 + 4, "track mode won't play again after its end")
params:set("end_action", 2)
-- track mode runs to its end and rolls on
params:set("play_mode", 2); params:set("track_minutes", 4)
run_bars(300)
print("track mode ok, section", S.section)
-- every frame draws without error, every theme
for th = 1, 8 do
  params:set("theme_mode", 2); params:set("theme", th)
  for i = 1, 40 do polls.out_amp(math.random()); tick_all() end
end
print(string.format("done: %d bars, glitch %d, brk %d, grid refreshes %d",
  S.bar, calls.glitch or 0, calls.brk or 0, calls.grid_refresh or 0))
