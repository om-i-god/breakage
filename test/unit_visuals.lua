-- visuals: every theme x {silence, mid, peak, kickless, chaos} drawn headless
-- into the raster stand-in (test/raster.lua) at 20 fps of virtual time. each
-- run checks the lit-pixel ratio, that silence is never blank, the frame-to-
-- frame change (no strobe), NaN / inf reaching the screen, level-15 area and
-- the draw-call budget. then: ramping out_hi / out_lo changes every theme,
-- the pulse shows, chaos changes the picture, a theme switch eases, bad
-- input draws cleanly, out-of-range audio draws exactly as the clamped value
-- would, a jittery frame rate tells the same story as a steady one, and
-- brightness / speed scale.
--
--   lua test/unit.lua test/unit_visuals.lua
--   VISONLY=dub,acid   only those themes
--   VISREPORT=1        print the numbers per theme x scenario
local RAST = dofile("test/raster.lua")
local REPORT = os.getenv("VISREPORT")
local ONLY = os.getenv("VISONLY")
local FPS = 20
local BPM = 128
local PV = {}

local function env()
  screen = RAST.screen
  PV = {vis_brightness = 10, vis_speed = 3}
  params = {get = function(_, id) return PV[id] end}
  clock = {get_tempo = function() return BPM end, get_beat_sec = function() return 60 / BPM end}
  util = nil
end

local function mkS()
  return {
    playing = true, step = 0, bar = 0, bpm = BPM, energy = 0, chaos = 0, kit = 1,
    phrase_pos = 0, phrase_len = 16, kickless = false, drop_bars = 0, following = false,
    gain = {kick = 0, snare = 0, clap = 0, hats = 0, ride = 0, perc = 0, toms = 0, ticks = 0, brk = 0},
  }
end

local NAMES = {"dub", "house", "acid", "analord", "syro", "broken", "drill", "gabber"}

-- one 16th of the groove. o: kick, snare, hats, perc, ticks, brk, ratchet
-- (probability per step of a burst), glitch, energy
local function groove(S, VIS, k, o)
  local s = k % 16 + 1
  if s == 1 then
    S.bar = S.bar + 1
    S.phrase_pos = S.bar % S.phrase_len
    VIS.event("bar", S)
    if S.phrase_pos == S.phrase_len - 1 then VIS.event("fill", "roll") end
  end
  if o.kick and not S.kickless and (s - 1) % 4 == 0 then VIS.event("kick", 0.9) end
  if o.snare and (s == 5 or s == 13) then
    VIS.event("snare", 0.85, 1)
    if o.clap then VIS.event("clap", 0.7) end
  end
  if o.rim and s % 6 == 3 then VIS.event("rim", 0.6) end
  if o.hats then
    if (s - 1) % 4 == 2 then VIS.event("hat", 0.7, s == 7 or s == 15)
    elseif o.dense and s % 2 == 0 then VIS.event("hat", 0.4, false) end
  end
  if o.ride and s % 4 == 1 then VIS.event("ride", 0.5) end
  if o.perc then
    if s % 3 == 1 then VIS.event("perc", (s % 5) + 1, 0.7) end
    if s == 11 then VIS.event("tom", 0.8, 110) end
    if s == 9 then VIS.event("shaker", 0.5) end
  end
  if o.ticks and s % 5 == 2 then VIS.event("tick", s % 6 + 1) end
  if o.brk then VIS.event("brk", (k * 5) % 16 + 1, 16, k % 7 == 3) end
  if o.ratchet and math.random() < o.ratchet then
    local n = ({2, 3, 4, 6, 8})[math.random(5)]
    local voice = ({"snare", "hat", "kick", "tick", "brk"})[math.random(5)]
    VIS.event("ratchet", n, voice)
    if voice == "snare" then VIS.event("snare", 0.7, n)
    elseif voice == "hat" then VIS.event("hat", 0.6, false)
    elseif voice == "kick" then VIS.event("kick", 0.6)
    elseif voice == "tick" then VIS.event("tick", 3)
    else VIS.event("brk", math.random(16), 16, true) end
  end
  if o.glitch and k % 48 == 12 then VIS.event("glitch", (k // 48) % 5 + 1, 0.25 + (k // 48) % 3 * 0.2) end
end

local SCEN = {}
SCEN.silence = {
  setup = function(S) S.playing = false end,
  on_step = function() end,
  audio = nil,
}
SCEN.mid = {
  setup = function(S)
    S.energy, S.chaos = 0.5, 0.15
    S.gain.kick, S.gain.snare, S.gain.hats, S.gain.perc = 0.8, 0.7, 0.6, 0.4
  end,
  on_step = function(S, VIS, k) groove(S, VIS, k, {kick = true, snare = true, hats = true, rim = true}) end,
  audio = function(t)
    local b = (t * BPM / 60) % 1
    local p = math.exp(-b * 6)
    return {out_amp = 0.45 + 0.2 * p, out_lo = 0.35 + 0.45 * p, out_mid = 0.4, out_hi = 0.3 + 0.2 * ((b * 2) % 1 < 0.2 and 1 or 0)}
  end,
}
SCEN.peak = {
  setup = function(S)
    S.energy, S.chaos = 1, 0.4
    for p in pairs(S.gain) do S.gain[p] = 1 end
  end,
  on_step = function(S, VIS, k)
    groove(S, VIS, k, {kick = true, snare = true, clap = true, hats = true, dense = true, rim = true,
      ride = true, perc = true, ticks = true, brk = true, glitch = true, ratchet = 0.06})
  end,
  audio = function() return {out_amp = 1, out_lo = 1, out_mid = 1, out_hi = 1} end,
}
SCEN.kickless = {
  setup = function(S)
    S.energy, S.chaos = 0.3, 0.2
    S.kickless = true; S.drop_bars = 8
    S.gain.snare, S.gain.hats, S.gain.perc = 0.6, 0.5, 0.5
  end,
  on_step = function(S, VIS, k) groove(S, VIS, k, {snare = true, hats = true, perc = true, rim = true}) end,
  audio = function(t)
    local b = (t * BPM / 60) % 1
    return {out_amp = 0.3, out_lo = 0.2 + 0.1 * math.exp(-b * 4), out_mid = 0.35, out_hi = 0.15}
  end,
}
-- drill'n'bass: chaos up, ratchet bursts every few steps, break slices
SCEN.chaos = {
  setup = function(S)
    S.energy, S.chaos = 0.75, 0.95
    for p in pairs(S.gain) do S.gain[p] = 0.8 end
  end,
  on_step = function(S, VIS, k)
    groove(S, VIS, k, {kick = true, snare = true, hats = true, dense = true, ticks = true, brk = true,
      perc = true, ratchet = 0.35, glitch = true})
  end,
  audio = function(t)
    local b = (t * BPM / 60 * 4) % 1
    return {out_amp = 0.7, out_lo = 0.4 + 0.4 * math.exp(-b * 5), out_mid = 0.6, out_hi = 0.5 + 0.4 * ((b * 3) % 1)}
  end,
}

local function lit_stats()
  local lit, l15, sum = 0, 0, 0
  local buf = RAST.buf
  for i = 0, 128 * 64 - 1 do
    local v = buf[i] or 0
    if v > 0 then lit = lit + 1; sum = sum + v end
    if v >= 15 then l15 = l15 + 1 end
  end
  return lit / 8192, l15, sum
end

local function copybuf()
  local c = {}
  for i = 0, 128 * 64 - 1 do c[i] = RAST.buf[i] or 0 end
  return c
end

local function bufdiff(a, b)
  local d = 0
  for i = 0, 128 * 64 - 1 do d = d + math.abs(a[i] - b[i]) end
  return d / 8192
end

local function run(theme, scen, opts)
  opts = opts or {}
  env()
  local VIS = include("lib/visuals")
  VIS.init()
  math.randomseed(opts.seed or 11)
  local SC = SCEN[scen]
  local S = mkS()
  SC.setup(S, VIS)
  if opts.setup then opts.setup(S) end
  local audio = opts.audio or SC.audio
  local st = {ops_max = 0, ops_sum = 0, lit_min = 1, lit_max = 0, lit_sum = 0,
    diff_max = 0, diff_sum = 0, l15_max = 0, bad = 0, n = 0, frames = {}}
  local prev
  local next_step, k = 0, 0
  local th = theme
  local t = 0
  for f = 1, opts.frames or 300 do
    local dt = opts.dt and opts.dt(f) or 1 / FPS
    t = t + dt
    while t >= next_step do
      if S.playing then
        SC.on_step(S, VIS, k)
        S.step = S.step + 1
      end
      k = k + 1
      next_step = next_step + 60 / S.bpm / 4
    end
    if opts.tempo_jitter then S.bpm = (f % 2 == 0) and 40 or 200 end
    if audio then
      for name, v in pairs(audio(t)) do VIS.audio(name, v) end
    end
    if opts.switch_every and f % opts.switch_every == 0 then th = th % #NAMES + 1 end
    if opts.at then opts.at(f, VIS, S) end
    screen.clear()
    RAST.reset_ops()
    VIS.draw(th, S, dt)
    local lit, l15, sum = lit_stats()
    local cur = copybuf()
    st.bad = st.bad + RAST.bad
    if t > 1 then
      st.ops_max = math.max(st.ops_max, RAST.ops)
      st.ops_sum = st.ops_sum + RAST.ops
      st.lit_min = math.min(st.lit_min, lit)
      st.lit_max = math.max(st.lit_max, lit)
      st.lit_sum = st.lit_sum + lit
      st.l15_max = math.max(st.l15_max, l15)
      st.n = st.n + 1
      if prev then
        local d = bufdiff(prev, cur)
        st.diff_max = math.max(st.diff_max, d)
        st.diff_sum = st.diff_sum + d
      end
    end
    if opts.keep then st.frames[#st.frames + 1] = cur end
    if opts.snap and f == opts.frames then RAST.snap(opts.snap) end
    prev = cur
  end
  st.t = t
  st.ops_mean = st.ops_sum / math.max(1, st.n)
  st.lit_mean = st.lit_sum / math.max(1, st.n)
  st.diff_mean = st.diff_sum / math.max(1, st.n - 1)
  return st, VIS
end

VIS_HARNESS = {run = run, bufdiff = bufdiff, NAMES = NAMES, RAST = RAST, SCEN = SCEN}
if not test then return end

local SCENS = {"silence", "mid", "peak", "kickless", "chaos"}

local OPS_BUDGET = 1200
local LIT_MAX = 0.40
local LIT_MIN_SILENT = 0.01
local LIT_MIN_LIVE = 0.04
local DIFF_MAX = 0.7
local L15_MAX = 12

local function wanted(name)
  if not ONLY then return true end
  for n in ONLY:gmatch("[^,]+") do if n == name then return true end end
  return false
end

if REPORT then
  print(string.format("%-9s %-8s %7s %7s %7s %7s %7s %7s %5s %4s",
    "theme", "scen", "opsMax", "opsMean", "litMin", "litMean", "litMax", "diffMax", "l15", "bad"))
end

for th, name in ipairs(NAMES) do
  if wanted(name) then
    for _, sc in ipairs(SCENS) do
      test(string.format("visuals %s %s", name, sc), function()
        local st = run(th, sc)
        if REPORT then
          print(string.format("%-9s %-8s %7d %7.1f %7.3f %7.3f %7.3f %7.3f %5d %4d",
            name, sc, st.ops_max, st.ops_mean, st.lit_min, st.lit_mean, st.lit_max, st.diff_max, st.l15_max, st.bad))
        end
        assert(st.bad == 0, st.bad .. " NaN / inf coordinates or levels")
        assert(st.ops_max <= OPS_BUDGET, "draw calls " .. st.ops_max .. " > " .. OPS_BUDGET)
        assert(st.lit_max <= LIT_MAX, string.format("lit %.3f > %.2f", st.lit_max, LIT_MAX))
        assert(st.lit_min > (sc == "silence" and LIT_MIN_SILENT or LIT_MIN_LIVE),
          string.format("near blank: lit %.4f", st.lit_min))
        assert(st.diff_max <= DIFF_MAX, string.format("frame jump %.3f > %.2f", st.diff_max, DIFF_MAX))
        assert(st.l15_max <= L15_MAX, st.l15_max .. " pixels at level 15")
      end)
    end

    test("visuals " .. name .. " moves at silence", function()
      local st = run(th, "silence", {frames = 120, keep = true})
      local moved = 0
      for i = 22, 120 do if bufdiff(st.frames[i - 1], st.frames[i]) > 0 then moved = moved + 1 end end
      if REPORT then print(string.format("still %-9s moved %d/99 meanDiff %.4f", name, moved, st.diff_mean)) end
      assert(moved >= 80, "frozen at silence: " .. moved .. " of 99 frames moved")
    end)

    -- the pulse shows: the picture changes more on the beat than off it
    test("visuals " .. name .. " shows the pulse", function()
      local st = run(th, "mid", {frames = 240, keep = true})
      local on, off, non, noff = 0, 0, 0, 0
      local spb = 60 / BPM
      for i = 41, 240 do
        local tt = i / FPS
        local b = (tt / spb) % 1
        local d = bufdiff(st.frames[i - 1], st.frames[i])
        if b < 0.2 then on, non = on + d, non + 1 elseif b > 0.45 and b < 0.95 then off, noff = off + d, noff + 1 end
      end
      on, off = on / math.max(1, non), off / math.max(1, noff)
      if REPORT then print(string.format("pulse %-9s on %.4f off %.4f", name, on, off)) end
      assert(on > off * 1.15, string.format("no visible pulse: on-beat %.4f vs off-beat %.4f", on, off))
    end)

    local function paired(a, b, frames)
      frames = frames or 160
      local d = 0
      for i = 21, frames do d = d + bufdiff(a.frames[i], b.frames[i]) end
      return d / (frames - 20)
    end

    test("visuals " .. name .. " reacts to out_hi and out_lo", function()
      local function with(over)
        return function(t)
          local v = SCEN.mid.audio(t)
          for kk, x in pairs(over) do v[kk] = x end
          return v
        end
      end
      local function pr(a, b)
        return paired((run(th, "mid", {frames = 160, audio = a, keep = true})),
          (run(th, "mid", {frames = 160, audio = b, keep = true})))
      end
      local same = pr(with({}), with({}))
      assert(same == 0, "two identical runs differ: " .. same)
      local dhi = pr(with({out_hi = 0}), with({out_hi = 1}))
      local dlo = pr(with({out_lo = 0}), with({out_lo = 1}))
      if REPORT then print(string.format("react %-9s hi %.3f lo %.3f", name, dhi, dlo)) end
      assert(dhi > 0.01, string.format("out_hi barely changes it: %.4f", dhi))
      assert(dlo > 0.02, string.format("out_lo barely changes it: %.4f", dlo))
    end)

    -- chaos (same groove, same audio) visibly changes the picture, and
    -- energy does too
    test("visuals " .. name .. " reacts to chaos and energy", function()
      local base = run(th, "mid", {frames = 160, keep = true})
      local hc = run(th, "mid", {frames = 160, keep = true, setup = function(S) S.chaos = 1 end})
      local he = run(th, "mid", {frames = 160, keep = true, setup = function(S) S.energy = 1 end})
      local dc, de = paired(base, hc), paired(base, he)
      if REPORT then print(string.format("axes  %-9s chaos %.3f energy %.3f", name, dc, de)) end
      assert(dc > 0.03, string.format("chaos barely changes it: %.4f", dc))
      assert(de > 0.03, string.format("energy barely changes it: %.4f", de))
    end)

    -- a ratchet burst reads: the picture changes more right after one
    test("visuals " .. name .. " ratchets read", function()
      local base = run(th, "mid", {frames = 100, keep = true, seed = 4})
      local r = run(th, "mid", {frames = 100, keep = true, seed = 4, at = function(f, VIS)
        if f == 60 then VIS.event("ratchet", 6, "snare"); VIS.event("snare", 0.8, 6) end
      end})
      local d = 0
      for i = 61, 70 do d = d + bufdiff(base.frames[i], r.frames[i]) end
      d = d / 10
      if REPORT then print(string.format("ratch %-9s %.3f", name, d)) end
      assert(d > 0.03, string.format("a ratchet burst barely shows: %.4f", d))
    end)

    test("visuals " .. name .. " bad input", function()
      local junk = {nil, 0 / 0, -1, 5, math.huge, -math.huge, 0.5}
      local st, VIS = run(th, "peak", {frames = 60, tempo_jitter = true, audio = function(t)
        local v = junk[math.floor(t * FPS) % 7 + 1]
        return {out_amp = v, out_lo = v, out_mid = v, out_hi = v}
      end})
      assert(st.bad == 0, st.bad .. " bad draw values")
      VIS.audio("out_amp", nil); VIS.audio("nope", 1); VIS.audio("out_hi", "x")
      local S = mkS()
      for f = 1, 10 do
        VIS.event("kick", 0 / 0); VIS.event("snare", nil, 0 / 0); VIS.event("snare", 9, 1e9)
        VIS.event("hat", "x", "open"); VIS.event("tom", 1, 0 / 0); VIS.event("perc", 99, -1)
        VIS.event("tick", nil); VIS.event("brk", 0 / 0, -4, 1); VIS.event("brk", 99, 3, true)
        VIS.event("ratchet", math.huge, 7); VIS.event("ratchet", -2, nil); VIS.event("fill", 3)
        VIS.event("kit", "x"); VIS.event("bar", S); VIS.event("bar", nil); VIS.event("rim"); VIS.event("ride")
        RAST.reset_ops(); screen.clear()
        VIS.draw(th, S, 1 / FPS)
        assert(RAST.bad == 0, "bad draw after junk events")
      end
      S.gain = nil; S.bpm = nil; S.step = nil; S.energy = 0 / 0; S.chaos = "x"; S.kickless = 3
      S.phrase_pos = 0 / 0; S.phrase_len = 0; S.bar = math.huge
      VIS.draw(th, S, 1 / FPS)
      VIS.draw(th, S, 0)
      VIS.draw(th, S, 5)
      VIS.draw(th, {}, 1 / FPS)
      assert(RAST.bad == 0, "bad draw with junk state")
    end)

    test("visuals " .. name .. " out-of-range audio == clamped", function()
      local over = run(th, "mid", {frames = 60, keep = true, audio = function(t)
        local w = math.sin(t * 3)
        return {out_amp = 5, out_lo = -3, out_mid = w * 4, out_hi = 1.5}
      end})
      local clamped = run(th, "mid", {frames = 60, keep = true, audio = function(t)
        local w = math.sin(t * 3)
        return {out_amp = 1, out_lo = 0, out_mid = math.max(0, math.min(1, w * 4)), out_hi = 1}
      end})
      for i = 1, 60 do
        assert(bufdiff(over.frames[i], clamped.frames[i]) == 0, "frame " .. i .. " differs")
      end
    end)

    test("visuals " .. name .. " variable dt", function()
      local steady = run(th, "mid", {frames = 200})
      local jit = run(th, "mid", {frames = 200, dt = function(f)
        return ({0.025, 0.06, 0.04, 0.03, 0.055, 0.045})[f % 6 + 1]
      end})
      assert(jit.bad == 0, "bad draw values with a jittery dt")
      local r = jit.lit_mean / steady.lit_mean
      assert(r > 0.7 and r < 1.4, string.format("lit %.3f at jittery dt vs %.3f steady", jit.lit_mean, steady.lit_mean))
      assert(jit.diff_max <= DIFF_MAX * 1.3, string.format("jump %.3f at jittery dt", jit.diff_max))
    end)

    test("visuals " .. name .. " brightness and speed", function()
      local function total(b)
        env(); PV.vis_brightness = b
        local VIS = include("lib/visuals"); VIS.init()
        local S = mkS(); SCEN.mid.setup(S)
        local s = 0
        for f = 1, 40 do
          for n, v in pairs(SCEN.mid.audio(f / FPS)) do VIS.audio(n, v) end
          screen.clear(); VIS.draw(th, S, 1 / FPS)
          local _, _, sum = lit_stats(); s = s + sum
        end
        return s
      end
      local a, b = total(3), total(15)
      assert(b > a * 1.5, string.format("brightness 15 vs 3 = %d vs %d", b, a))
      local function moved(sp)
        env(); PV.vis_speed = sp
        local VIS = include("lib/visuals"); VIS.init()
        local S = mkS(); SCEN.silence.setup(S)
        local prev, d = nil, 0
        for f = 1, 100 do
          screen.clear(); VIS.draw(th, S, 1 / FPS)
          local c = copybuf()
          if prev and f > 40 then d = d + bufdiff(prev, c) end
          prev = c
        end
        return d
      end
      local slow, fast = moved(1), moved(9)
      if REPORT then print(string.format("speed %-9s 1: %.3f  9: %.3f", name, slow, fast)) end
      assert(fast > slow * 1.5, string.format("speed 9 moves %.3f vs speed 1 %.3f", fast, slow))
    end)
  end
end

if not ONLY then
  test("visuals theme switch eases", function()
    local st = run(1, "mid", {frames = 400, switch_every = 25})
    if REPORT then print(string.format("switch diffMax %.3f", st.diff_max)) end
    assert(st.diff_max <= DIFF_MAX * 0.8, string.format("theme switch jump %.3f", st.diff_max))
    assert(st.bad == 0)
  end)
  test("visuals names in kit order", function()
    env()
    local VIS = include("lib/visuals")
    assert(#VIS.names == #NAMES, #VIS.names .. " themes")
    for i, n in ipairs(NAMES) do assert(VIS.names[i] == n, i .. ": " .. tostring(VIS.names[i])) end
  end)
  test("visuals every theme loads its own module (no fallback)", function()
    env()
    local saved_print = print
    local logs = {}
    print = function(...) logs[#logs + 1] = table.concat({...}, " ") end
    local VIS = include("lib/visuals")
    print = saved_print
    assert(#logs == 0, "load errors: " .. table.concat(logs, " | "))
  end)

  test("visuals glitch: every mode bounded, every theme, and released", function()
    for th = 1, #NAMES do
      for mode = 1, 5 do
        local st = run(th, "mid", {frames = 60, seed = 3, at = function(f, VIS)
          if f == 30 then VIS.event("glitch", mode, 0.6) end
        end, keep = true})
        assert(st.bad == 0, NAMES[th] .. " glitch " .. mode .. ": bad draw values")
        assert(st.lit_max <= LIT_MAX, NAMES[th] .. " glitch " .. mode .. string.format(" lit %.3f", st.lit_max))
        assert(st.l15_max <= L15_MAX, NAMES[th] .. " glitch " .. mode .. " l15 " .. st.l15_max)
        assert(st.diff_max <= DIFF_MAX, NAMES[th] .. " glitch " .. mode .. string.format(" jump %.3f", st.diff_max))
        assert(st.ops_max <= OPS_BUDGET, NAMES[th] .. " glitch ops " .. st.ops_max)
      end
    end
  end)

  -- (the band lands where the dice put it, so a sparse theme may have
  -- little in it: every theme must tear in some mode, and the reverse must
  -- tear clearly on average)
  test("visuals glitch tears the picture while it runs, then lets go", function()
    local rev_sum = 0
    for th = 1, #NAMES do
      local a = run(th, "mid", {frames = 80, seed = 5, keep = true})
      local best = 0
      for _, mode in ipairs({1, 2, 3, 4, 5}) do
        local b = run(th, "mid", {frames = 80, seed = 5, keep = true, at = function(f, VIS)
          if f == 30 then VIS.event("glitch", mode, 0.6) end
        end})
        local d = 0
        for i = 33, 40 do d = d + bufdiff(a.frames[i], b.frames[i]) end
        d = d / 8
        best = math.max(best, d)
        if mode == 3 then rev_sum = rev_sum + d end
        -- released: a second after it ends the picture is the same scene
        local lit_a, lit_b = 0, 0
        for k = 0, 8191 do
          if a.frames[80][k] > 0 then lit_a = lit_a + 1 end
          if b.frames[80][k] > 0 then lit_b = lit_b + 1 end
        end
        assert(math.abs(lit_a - lit_b) / 8192 < 0.08, NAMES[th] .. " glitch " .. mode .. " never let go")
      end
      assert(best > 0.02, NAMES[th] .. " no glitch mode tore anything")
    end
    assert(rev_sum / #NAMES > 0.02, string.format("the reverse barely tears: %.4f", rev_sum / #NAMES))
  end)

  test("visuals garbage events never throw", function()
    env()
    local VIS = include("lib/visuals"); VIS.init()
    local S = mkS()
    for th = 1, #NAMES do
      for _, ev in ipairs({{"clap"}, {"perc", 2, 0.6}, {"perc", "x", nil}, {"tick", 9},
                           {"glitch", 0 / 0, 1e9}, {"glitch", -3, -1}, {"glitch"}, {42}, {nil},
                           {"nonsense", {}, {}}, {"perc", math.huge, -math.huge}, {"kit", 3},
                           {"brk", {}, {}, {}}, {"ratchet", "x", {}}, {"fill", nil}}) do
        VIS.event(ev[1], ev[2], ev[3], ev[4])
      end
      screen.clear(); RAST.reset_ops()
      VIS.draw(th, S, 1 / FPS)
      assert(RAST.bad == 0, NAMES[th] .. " bad draw after garbage events")
    end
    for _, i in ipairs({0, -5, 99, 0 / 0, "3", nil}) do
      screen.clear(); RAST.reset_ops()
      VIS.draw(i, S, 1 / FPS)
      assert(RAST.bad == 0)
    end
    screen.clear(); VIS.draw(1, nil, 1 / FPS)
    screen.clear(); VIS.draw(1, {energy = "loud", gain = 3, step = {}, chaos = {}}, 1 / FPS)
  end)

  test("visuals a broken theme falls back instead of failing", function()
    env()
    local VIS = include("lib/visuals"); VIS.init()
    local S = mkS(); SCEN.mid.setup(S)
    local saved_print = print
    local logs = 0
    print = function() logs = logs + 1 end
    local ok = pcall(function()
      local reached
      for j = 1, 80 do
        local name, val = debug.getupvalue(VIS.draw, j)
        if not name then break end
        if name == "THEMES" then reached = val end
      end
      assert(reached, "THEMES not reachable")
      local th = reached[2]
      local d, sn = th.draw, th.snare
      th.draw = function() error("boom") end
      th.snare = function() error("snare boom") end
      for f = 1, 40 do
        VIS.event("snare", 0.8, 1)
        screen.clear(); RAST.reset_ops()
        VIS.draw(2, S, 1 / FPS)
      end
      local lit = lit_stats()
      assert(lit > 0.01, string.format("fallback scene lit only %.3f", lit))
      th.draw, th.snare = d, sn
    end)
    print = saved_print
    assert(ok, "a broken theme threw out of VIS")
    assert(logs == 1, "broken theme logged " .. logs .. " times, wanted once")
  end)

  test("visuals per-frame draw budget holds against a runaway theme", function()
    env()
    local VIS = include("lib/visuals"); VIS.init()
    local THEMES
    for j = 1, 80 do
      local name, val = debug.getupvalue(VIS.draw, j)
      if not name then break end
      if name == "THEMES" then THEMES = val end
    end
    local d = THEMES[1].draw
    local KK
    for j = 1, 80 do
      local name, val = debug.getupvalue(d, j)
      if not name then break end
      if name == "K" then KK = val end
    end
    assert(KK, "K not reachable from theme 1's draw")
    THEMES[1].draw = function() for n = 1, 50000 do KK.put(3, n % 128, n % 64, 1, 1) end end
    screen.clear(); RAST.reset_ops()
    VIS.draw(1, mkS(), 1 / FPS)
    THEMES[1].draw = d
    assert(RAST.ops <= OPS_BUDGET + 40, "runaway theme made " .. RAST.ops .. " draw calls")
  end)
end
