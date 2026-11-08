-- breakage / gen
-- pattern material. one bar = 16 steps; every pattern is a 16-long table of
-- velocities (0 = rest) unless noted. a phrase's material is built once from
-- the kit, a groove family and the chaos at that moment; chaos then keeps
-- working on it live, hit by hit (see G.ratchet and the edits in
-- lib/conductor).
--
-- families
--   four     four on the floor, offbeat hats            dub techno / house
--   dub      broken dub: kick 1 + syncopation, rim into the echo
--   acid     four, running 16th hats with accents, squelch perc
--   electro  syncopated kick, snare on 2 and 4, 8th hats
--   broken   2-step / broken beat, ghost snares, swung hats
--   brk      a breakbeat skeleton (kick 1, 3, 11, 12; snare 5, 8, 10, 13)

local G = {}

G.FAMILIES = {"four", "dub", "acid", "electro", "broken", "brk"}

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function chance(p) return math.random() < p end

function G.pick(t) return t[math.random(#t)] end

-- weighted pick from {key = weight}
function G.wpick(w)
  local keys, total = {}, 0
  for k, v in pairs(w) do keys[#keys + 1] = k; total = total + v end
  table.sort(keys)        -- pairs order is not stable; seeds must be
  local r = math.random() * total
  for _, k in ipairs(keys) do
    r = r - w[k]
    if r <= 0 then return k end
  end
  return keys[#keys]
end

local function zeros(n)
  local t = {}
  for i = 1, (n or 16) do t[i] = 0 end
  return t
end

-- bjorklund-style euclid: k hits over n steps, rotated by r
function G.euclid(k, n, r)
  local t = {}
  for i = 0, n - 1 do
    t[i + 1] = (((i + (r or 0)) * k) % n) < k and 1 or 0
  end
  return t
end

local function set(t, steps, v)
  for _, s in ipairs(steps) do t[s] = v end
  return t
end

------------------------------------------------------------------------
-- skeletons per family: kick, snare (backbeat), hats
------------------------------------------------------------------------

local SKEL = {}

SKEL.four = function(c)
  local k = set(zeros(), {1, 5, 9, 13}, 1)
  local s = zeros()
  local h = set(zeros(), {3, 7, 11, 15}, 0.85)
  return k, s, h
end

SKEL.dub = function(c)
  local k = zeros()
  local v = G.pick({{1, 5, 9, 13}, {1, 7, 11}, {1, 9, 12}, {1, 5, 9, 13}, {1, 4, 9, 11}})
  set(k, v, 1)
  local s = zeros()
  set(s, G.pick({{5, 13}, {7, 15}, {13}, {4, 12}, {11}}), 0.7)
  local h = set(zeros(), {3, 7, 11, 15}, 0.6)
  return k, s, h
end

SKEL.acid = function(c)
  local k = set(zeros(), {1, 5, 9, 13}, 1)
  local s = zeros()
  local h = zeros()
  for i = 1, 16 do h[i] = (i % 4 == 3) and 0.9 or (i % 2 == 0 and 0.45 or 0.3) end
  return k, s, h
end

SKEL.electro = function(c)
  local k = set(zeros(), G.pick({{1, 4, 11}, {1, 7, 11}, {1, 4, 7, 11, 14}, {1, 11, 12}}), 1)
  local s = set(zeros(), {5, 13}, 1)
  local h = set(zeros(), {1, 3, 5, 7, 9, 11, 13, 15}, 0.55)
  return k, s, h
end

SKEL.broken = function(c)
  local k = set(zeros(), G.pick({{1, 8, 11}, {1, 6, 11}, {1, 4, 10, 14}, {1, 11}}), 1)
  local s = set(zeros(), {5, 13}, 1)
  set(s, {G.pick({8, 10, 15, 16})}, 0.35)
  local h = zeros()
  for _, i in ipairs({3, 7, 11, 15}) do h[i] = 0.8 end
  for _, i in ipairs({2, 6, 10, 14}) do h[i] = 0.3 end
  return k, s, h
end

SKEL.brk = function(c)
  local k = set(zeros(), {1, 3, 11, 12}, 1)
  local s = set(zeros(), {5, 13}, 1)
  set(s, {8, 10}, 0.55)
  set(s, {16}, 0.3)
  local h = zeros()
  for i = 1, 16 do h[i] = (i % 2 == 1) and 0.7 or 0.35 end
  return k, s, h
end

------------------------------------------------------------------------
-- the phrase's material
------------------------------------------------------------------------

-- kit: an entry of lib/kits; chaos 0..1 at the moment of building
function G.build(kit, chaos, family)
  family = family or G.wpick(kit.grooves)
  -- high chaos leans every kit toward the break skeleton
  if family ~= "brk" and chance(clamp((chaos - 0.55) * 1.2, 0, 0.7)) then family = "brk" end
  local k, s, h = SKEL[family](chaos)
  local P = {family = family, kick = k, snare = s, hats = h}

  -- ghost kicks / displacement grow with chaos
  for i = 2, 16 do
    if k[i] == 0 and chance(0.04 + chaos * 0.18) and family ~= "four" and family ~= "acid" then
      k[i] = 0.45 + math.random() * 0.3
    end
  end
  if chaos > 0.35 and family ~= "four" then
    -- push one kick a 16th early or late
    local hits = {}
    for i = 2, 16 do if k[i] > 0 then hits[#hits + 1] = i end end
    if #hits > 0 and chance(chaos * 0.7) then
      local i = G.pick(hits)
      local j = clamp(i + G.pick({-1, 1}), 2, 16)
      if k[j] == 0 then k[j], k[i] = k[i], 0 end
    end
  end

  -- rim vs snare on the backbeat; the backbeat itself
  P.rim = chance(kit.rim)
  -- four-on-floor families get a backbeat from the clap (if any), and
  -- rim ghosts on syncopated 16ths
  if family == "four" or family == "acid" then
    if P.rim or chance(0.4) then
      set(s, G.pick({{4, 12}, {7, 15}, {11}, {6, 14}, {4, 7, 12}}), 0.55)
      P.rim = true
    end
  end
  -- ghost snares with chaos
  for i = 1, 16 do
    if s[i] == 0 and k[i] == 0 and chance(chaos * 0.22) then s[i] = 0.2 + math.random() * 0.25 end
  end

  -- clap: on the backbeat for some phrases
  P.clap = zeros()
  if chance(kit.clap) then
    set(P.clap, G.pick({{5, 13}, {5, 13}, {13}, {5, 13, 16}}), 1)
  end

  -- hats: ghost 16ths and open marks
  P.open = zeros()
  for i = 1, 16 do
    if h[i] == 0 and chance(0.15 + chaos * 0.3) then h[i] = 0.18 + math.random() * 0.15 end
  end
  if chance(0.6) then
    for _, i in ipairs({3, 7, 11, 15}) do if chance(0.35) then P.open[i] = 1 end end
  end
  P.hat_shuffle = chance(0.35) and (0.15 + math.random() * 0.2) or 0

  -- ride, shaker: in for this phrase or not
  P.ride = chance(kit.ride) and set(zeros(), G.pick({{1, 5, 9, 13}, {3, 7, 11, 15},
    {1, 3, 5, 7, 9, 11, 13, 15}}), 0.7) or nil
  if chance(kit.shaker) then
    P.shaker = zeros()
    for i = 1, 16 do P.shaker[i] = (i % 2 == 1) and 0.35 or 0.6 end
  end

  -- toms: a hit or two a bar on some phrases (fills use their own runs)
  if chance(kit.toms * 0.6) then
    P.toms = zeros()
    for _ = 1, G.pick({1, 1, 2}) do P.toms[G.pick({4, 7, 8, 11, 12, 15, 16})] = 0.7 end
  end

  -- perc: an odd-length lane that phases against the bar
  local plen = G.pick({5, 6, 7, 9, 10, 11, 12, 13})
  local hits = clamp(math.floor(plen * (0.3 + chaos * 0.35) + 0.5), 2, plen - 1)
  local e = G.euclid(hits, plen, math.random(0, plen - 1))
  P.perc = {len = plen, steps = {}}
  for i = 1, plen do
    if e[i] == 1 then
      P.perc.steps[i] = {kind = G.pick(kit.perc), vel = 0.5 + math.random() * 0.5,
        deg = G.pick({0, 0, 7, 12, 5, 10, 3})}
    end
  end

  -- ticks: a euclidean scatter of glitch voices
  local tn = clamp(math.floor(2 + chaos * 9 + math.random() * 2), 1, 13)
  local te = G.euclid(tn, 16, math.random(0, 15))
  P.ticks = zeros()
  for i = 1, 16 do if te[i] == 1 then P.ticks[i] = G.pick(kit.ticks) end end

  -- break: which slice each step plays (offset within the loop) and per-step
  -- edits, built at this chaos. identity at zero chaos
  P.brk = G.brk_map(chaos)
  return P
end

-- the break slice map for 16 steps: {slice = 0-based step offset or nil
-- (= play straight), rev = bool, pitch = semitones, rest = bool}
function G.brk_map(chaos)
  local m = {}
  for i = 1, 16 do
    local st = {}
    if chance(chaos * 0.55) then st.slice = math.random(0, 15) end
    if i > 1 and chance(chaos * 0.25) then st.slice = -1 end          -- -1 = repeat the last slice
    if chance(chaos * 0.15) then st.rev = true end
    if chance(chaos * 0.12) then st.pitch = G.pick({-12, -5, 7, 12, 5}) end
    if chance(chaos * 0.1) then st.rest = true end
    m[i] = st
  end
  return m
end

------------------------------------------------------------------------
-- live chaos: per hit
------------------------------------------------------------------------

-- how likely each voice is to ratchet at full chaos
local RATCH = {kick = 0.12, snare = 0.55, clap = 0.2, hats = 0.3, perc = 0.25, toms = 0.3,
  ticks = 0.6, brk = 0.45}

-- returns n (1 = a single hit), span in steps, bend per repeat (semitones)
function G.ratchet(part, chaos, energy)
  local p = (RATCH[part] or 0) * (chaos ^ 1.4) * (0.5 + energy * 0.5)
  if not chance(p) then return 1, 1, 0 end
  local n
  if chaos < 0.4 then n = G.pick({2, 2, 3})
  elseif chaos < 0.75 then n = G.pick({2, 3, 4, 4, 6})
  else n = G.pick({4, 6, 8, 8, 12, 16}) end
  local span = (chaos > 0.7 and chance(0.4)) and 2 or 1
  local bend = 0
  if part == "snare" or part == "toms" or part == "ticks" then
    if chaos > 0.45 and chance(0.6) then bend = G.pick({0.5, 1, 1, 2, -1}) end
  end
  return n, span, bend
end

-- the bar's micro-edit (or nil): at chaos, one beat of the bar is reworked
--   repeat   the beat replays the beat before
--   shuffle  its four 16ths play in a new order
--   skip     it goes silent but for the kick
--   roll     a snare roll over the beat, rising
--   stutter / reverse / tapestop   the glitch insert on that beat
function G.edit(chaos)
  if not chance(clamp(chaos * 0.85, 0, 0.9)) then return nil end
  local kinds
  if chaos < 0.4 then kinds = {"repeat", "skip", "stutter"}
  elseif chaos < 0.7 then kinds = {"repeat", "shuffle", "skip", "roll", "stutter", "reverse"}
  else kinds = {"repeat", "shuffle", "roll", "roll", "stutter", "reverse", "tapestop", "shuffle"} end
  local e = {kind = G.pick(kinds), beat = math.random(2, 4)}
  if e.kind == "shuffle" then
    local o = {0, 1, 2, 3}
    for i = 4, 2, -1 do local j = math.random(i); o[i], o[j] = o[j], o[i] end
    e.order = o
  end
  return e
end

return G
