-- breakage / conductor
-- runs once a bar. owns the energy (its own arc when solo, gradient's when
-- following), the phrase, who plays, fills, the bar's micro-edit and
-- halftime flips, mutation and kit changes. it never touches chaos: chaos is
-- the player's.

local G  = include("lib/gen")
local KT = include("lib/kits")

local C = {}

local BLOCK = 8

C.SECTIONS = {
  {name = "intro",     len = 0.12, e0 = 0.10, e1 = 0.30},
  {name = "build",     len = 0.16, e0 = 0.30, e1 = 0.65},
  {name = "peak",      len = 0.20, e0 = 0.70, e1 = 0.90},
  {name = "breakdown", len = 0.14, e0 = 0.35, e1 = 0.22, kickless = true},
  {name = "return",    len = 0.22, e0 = 0.70, e1 = 1.00},
  {name = "outro",     len = 0.16, e0 = 0.80, e1 = 0.00},
}

-- part -> energy to enter
local TH = {hats = 0.04, perc = 0.12, kick = 0.2, ticks = 0.3, snare = 0.32, toms = 0.4,
  brk = 0.4, clap = 0.5, shaker = 0.45, ride = 0.68}
C.PARTS = {"kick", "snare", "clap", "hats", "ride", "perc", "toms", "ticks", "brk"}

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function chance(p) return math.random() < p end
local function plen(S) return S.phrase_len or 16 end

function C.kit(S) return KT.list[S.kit] or KT.list[1] end

------------------------------------------------------------------------
-- material
------------------------------------------------------------------------

function C.new_material(S, seed)
  if seed then
    S.seed = seed
    math.randomseed(seed)
  end
  S.pat = G.build(C.kit(S), S.chaos)
end

-- on a phrase edge: keep the groove sometimes, swap pieces of it, or rebuild.
-- the kick and snare move together (they are the groove)
function C.mutate(S, full)
  local N = G.build(C.kit(S), S.chaos, (not full and chance(0.6)) and S.pat.family or nil)
  if full or chance(0.3) then S.pat = N; return end
  local P = S.pat
  if chance(0.35) then P.kick, P.snare, P.rim, P.family = N.kick, N.snare, N.rim, N.family end
  for _, k in ipairs({"hats", "clap", "ride", "shaker", "toms", "perc", "ticks", "brk"}) do
    if chance(0.4) then
      P[k] = N[k]
      if k == "hats" then P.open, P.hat_shuffle = N.open, N.hat_shuffle end
    end
  end
end

------------------------------------------------------------------------
-- energy
------------------------------------------------------------------------

local function track_total(S)
  local bars = S.track_minutes * (S.bpm or 120) / 4
  local P = plen(S)
  return math.max(P * 6, math.floor(bars / P + 0.5) * P)
end

local function track_section(S)
  local total = track_total(S)
  local start = 0
  for i, sec in ipairs(C.SECTIONS) do
    local P = plen(S)
    local len = math.max(P, math.floor(sec.len * total / P + 0.5) * P)
    if i == #C.SECTIONS then len = total - start end
    if S.track_bar < start + len then
      return sec, (S.track_bar - start) / math.max(1, len), total
    end
    start = start + len
  end
  return C.SECTIONS[#C.SECTIONS], 1, total
end

-- the solo arc (set / track / hold), before the nudge
local function solo_energy(S)
  if S.mode_play == 2 then
    local sec, prog, total = track_section(S)
    S.section = sec.name
    S.kickless_section = sec.kickless or false
    S.progress = S.track_bar / total
    S.total_bars = total
    return sec.e0 + (sec.e1 - sec.e0) * prog
  elseif S.mode_play == 3 then
    S.section = "hold"
    S.kickless_section = false
    return S.hold_energy or 0.6
  else
    local ph = (S.track_bar % S.cycle_bars) / S.cycle_bars
    S.walk = clamp((S.walk or 0) + (math.random() - 0.5) * 0.04, -0.15, 0.15)
    local e = 0.52 - 0.40 * math.cos(ph * 2 * math.pi) + S.walk
    S.progress = ph
    S.kickless_section = e < 0.3 and S.track_bar > 16
    S.section = (e < 0.3) and "drift" or (e < 0.6) and "rise" or "peak"
    return e
  end
end

-- following: gradient's energy and kickless as they arrive. when the follow
-- signal goes, the solo arc takes over from wherever the energy was: the gap
-- between the two is carried as an offset that relaxes over ~32 bars
local function base_energy(S)
  local solo = solo_energy(S)
  if S.following then
    S.section = "follow"
    S.kickless_section = S.f_kickless or false
    S.solo_off = clamp((S.f_energy or solo) - solo, -1, 1)
    return S.f_energy or solo
  end
  S.solo_off = (S.solo_off or 0) * 0.93
  if math.abs(S.solo_off) < 0.01 then S.solo_off = 0 end
  return solo + S.solo_off
end

------------------------------------------------------------------------
-- fills
--   low chaos   toms (a run down)  throw (echo thrown)  gap (drums out)
--               open (open hats)   dip (filter dip)
--   mid         roll (snare roll, rising)  stutter  brkroll (break slice roll)
--   high        drill (two beats of accelerating ratchets)  reverse  tapestop
------------------------------------------------------------------------

function C.pick_fill(S, big)
  local c = S.chaos
  local w = {toms = 2, throw = 2, gap = 1.5, open = 1.5, dip = 1}
  if c > 0.25 then w.roll = 1 + c * 3; w.stutter = c * 2 end
  if c > 0.5 then w.drill = (c - 0.4) * 6; w.reverse = c * 1.5; w.tapestop = c end
  if c > 0.6 then w.toms, w.open, w.dip = 1, 0.5, 0.5 end
  if S.brk_ready and c > 0.2 then w.brkroll = 1 + c * 2 end
  if (S.glitch_amt or 3) == 1 then w.stutter, w.reverse, w.tapestop = nil, nil, nil end
  local kind = G.wpick(w)
  local start = 13
  if kind == "drill" or (big and (kind == "roll" or kind == "brkroll") and chance(0.5)) then start = 9 end
  if kind == "gap" and chance(0.3) then start = 9 end
  return {kind = kind, start = start}
end

local function roll_fill(S, pos)
  S.fill = nil
  if S.fills == 3 or next(S.solo or {}) then return end
  local busy = S.fills == 2
  local P = plen(S)
  if pos == P - 1 then
    if chance(busy and 1 or 0.9) then S.fill = C.pick_fill(S, true) end
  elseif pos % BLOCK == BLOCK - 1 then
    if chance((busy and 0.6 or 0.3) + S.chaos * 0.3) then S.fill = C.pick_fill(S, false) end
  elseif busy and pos % 4 == 3 and chance(0.25 + S.chaos * 0.3) then
    S.fill = C.pick_fill(S, false)
  end
end

------------------------------------------------------------------------
-- the bar
------------------------------------------------------------------------

function C.phrase_pos(S)
  return (S.bar - (S.phrase_anchor or 0)) % plen(S)
end

function C.bar(S)
  -- nudge relaxes back over ~16 bars (hold mode: E1 moves the hold itself)
  S.nudge = S.nudge * 0.9
  if math.abs(S.nudge) < 0.01 then S.nudge = 0 end

  local prev = S.energy
  S.energy = clamp(base_energy(S) + S.nudge, 0, 1)
  S.trend = (S.trend or 0) * 0.85 + (S.energy - prev) * 0.15

  if S.drop_bars > 0 then S.drop_bars = S.drop_bars - 1 end
  if S.strip_bars > 0 then S.strip_bars = S.strip_bars - 1 end
  if S.hand_throw > 0 then S.hand_throw = S.hand_throw - 1 end

  -- a kit change lands here: new material in the new kit
  if S.kit_pending then
    S.kit = S.kit_pending
    S.kit_pending = nil
    S.kit_changed = true
    C.mutate(S, true)
  end

  local pos = C.phrase_pos(S)
  S.phrase_pos = pos
  if pos == 0 then
    C.phrase(S)
  elseif pos % 4 == 0 then
    C.decide(S)
  end

  -- fades: drums come and go over ~2 bars
  for _, k in ipairs(C.PARTS) do
    local t = S.want[k] and 1 or 0
    local g = S.gain[k] or 0
    if t > g then g = math.min(1, g + 0.5) else g = math.max(0, g - 0.5) end
    S.gain[k] = g
  end

  -- dub throw at the end of some 8-bar blocks
  S.throw = pos % BLOCK == BLOCK - 1 and chance(0.15 + S.dub * 0.35)

  roll_fill(S, pos)

  -- the bar's micro-edit and halftime, both from chaos
  S.edit = (not S.fill and pos ~= 0) and G.edit(S.chaos) or nil
  if S.half_bars > 0 then
    S.half_bars = S.half_bars - 1
  elseif S.chaos > 0.55 and pos % 2 == 0 and chance((S.chaos - 0.5) * 0.3) then
    S.half_bars = G.pick({1, 2, 2, 4})
  end
  S.halftime = S.half_bars > 0

  -- the solo track's clock waits while gradient leads
  if not S.following then S.track_bar = S.track_bar + 1 end
  S.bar = S.bar + 1

  if S.mode_play == 2 and not S.following and S.track_bar >= (S.total_bars or math.huge) then
    if S.end_action == 1 then
      S.track_bar = 0
      return "stop"
    end
    S.track_bar = 0
    C.mutate(S, true)
    return "next"
  end
end

-- phrase edge: fresh dice, decide, mutate, maybe a new kit
function C.phrase(S)
  for k, _ in pairs(TH) do S.jitter[k] = (math.random() - 0.5) * 0.14 end
  S.roll_kickless = chance(0.2)
  S.roll_hats_drop = chance(0.6)
  S.roll_clap_kl = chance(0.7)
  S.roll_brk_kl = chance(0.5)
  if S.kit_auto == 2 and S.bar > 0 and chance(0.35) then
    local k = S.kit
    while k == S.kit do k = math.random(#KT.list) end
    S.kit = k
    S.kit_changed = true
    C.mutate(S, true)
  elseif not S.freeze and S.bar > 0 then
    C.mutate(S)
  end
  C.decide(S)
end

-- who plays. cheap; re-run whenever a hand or the arc moves something
function C.decide(S)
  local e = S.energy
  local function over(k) return e > TH[k] + (S.jitter[k] or 0) end
  local drop = S.drop_bars > 0
  local strip = S.strip_bars > 0

  local kickless = S.kickless_section or drop or S.kick_style == 3
  if S.kick_style == 1 and not kickless and not S.following and e > 0.4 and e < 0.75 then
    kickless = S.roll_kickless
  end
  if S.kick_style == 2 then kickless = false end
  S.kickless = kickless

  local W = S.want
  W.kick   = over("kick") and not kickless
  W.snare  = over("snare") and not (kickless and S.roll_clap_kl)
  W.clap   = over("clap") and not drop and not (kickless and S.roll_clap_kl)
  W.hats   = over("hats") and S.hat_style ~= 3
             and (S.hat_style == 2 or not (drop and S.roll_hats_drop))
  W.ride   = over("ride") and not drop
  W.shaker = over("shaker")
  W.perc   = over("perc") or (kickless and e > 0.12)
  W.toms   = over("toms")
  W.ticks  = (S.glitch_amt or 3) > 1 and (over("ticks") or (kickless and e > 0.2) or S.chaos > 0.6)
  -- the break: in at its threshold (lower with chaos), out when off
  W.brk    = S.brk_ready and S.break_mode > 1
             and (e > TH.brk - S.chaos * 0.25 + (S.jitter.brk or 0) or S.break_mode == 4)
             and not (kickless and S.roll_brk_kl and S.break_mode ~= 4)
  -- break mode 3 replaces the synth snare + hats, 4 replaces the whole kit
  if W.brk and S.break_mode >= 3 then W.snare, W.clap, W.hats = false, false, false end
  if W.brk and S.break_mode == 4 then W.kick, W.ride, W.shaker, W.toms = false, false, false, false end

  -- strip: only the break, perc and glitch ticks
  if strip then
    W.kick, W.snare, W.clap, W.hats, W.ride, W.shaker, W.toms = false, false, false, false, false, false, false
    W.ticks = (S.glitch_amt or 3) > 1
    W.perc = true
    W.brk = S.brk_ready or false
  end

  local m = S.mute or {}
  for k, _ in pairs(W) do if m[k] then W[k] = false end end
  if m.hats then W.shaker = false end
  if next(S.solo or {}) then
    for k, _ in pairs(W) do
      if not S.solo[k] and not (k == "shaker" and S.solo.hats) then W[k] = false end
    end
  end
end

return C
