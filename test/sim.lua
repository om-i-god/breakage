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
    if k == "tweak" then TWV[(...)] = select(2, ...) end
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
    assert(guard < n * 16 * 4 + 64, "clock stalled")
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
follow_dev.event({0xFA})
assert(S.playing, "midi start not followed")
run_bars(2)

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
for pg = 1, 5 do
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
run_bars(4)
for _, id in ipairs({"p_drop", "p_fill", "p_mutate", "p_strip", "p_throw", "p_build", "p_break",
    "p_stutter", "p_tapestop", "p_reverse", "p_chop", "p_kit_next", "p_kit_prev"}) do
  P.defs[id].action()
end
run_bars(8)
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
