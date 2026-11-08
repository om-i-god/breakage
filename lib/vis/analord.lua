-- analord: the front of an old analog drum machine at night, seen close.
-- three VU meters across the top, one each for the kick, the snare and the
-- hats, their needles thrown by the hits and settling with a little
-- overshoot; a patch bay below with cables hanging between the jacks,
-- swaying with the swing and shaken by the kick; a lamp over each meter
-- blinks with its voice. energy patches in more cables and lifts the
-- needles' rest, chaos makes the needles chatter and re-patches the bay,
-- and a ratchet rattles a needle once for every repeat
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  local MW, MH, MY = 38, 27, 2            -- a meter's box, its top
  local MX = {4, 45, 86}                  -- each meter's left
  local JY = {41, 56}                     -- the patch bay's two rows of jacks
  local NJ = 8
  local JX = {}
  for j = 1, NJ do JX[j] = 8 + (j - 1) * 16 end

  local ndl, vel, buzz, lamp
  local ghost, ghost_a, buzz_t = {0, 0, 0}, {0, 0, 0}, {0, 0, 0}
  local cables, extra_t

  -- a cable: from jack (row a, col i) to (row b, col j), its slack
  local BASE = {{1, 1, 2, 3, 9}, {1, 4, 2, 2, 7}, {1, 6, 2, 8, 11}, {2, 5, 1, 8, 8},
    {1, 2, 1, 5, 12}, {2, 1, 2, 6, 10}, {1, 3, 2, 7, 13}}

  function M.init()
    ndl, vel, buzz, lamp = {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}
    ghost, ghost_a, buzz_t = {0, 0, 0}, {0, 0, 0}, {0, 0, 0}
    cables = {}
    for i, c in ipairs(BASE) do cables[i] = {a = c[1], i = c[2], b = c[3], j = c[4], sag = c[5], ph = i * 1.7} end
    extra_t = 0
  end
  M.clear = M.init

  local function throw(m, v)
    vel[m] = vel[m] + (2.5 + 5 * v)
    lamp[m] = 1
  end
  function M.kick(v) throw(1, K.num(v, 1)) end
  function M.snare(v) throw(2, K.num(v, 1)) end
  function M.clap(v) throw(2, K.num(v, 1) * 0.8) end
  function M.rim(v) throw(2, K.num(v, 1) * 0.4) end
  function M.hat(v, open) throw(3, K.num(v, 1) * (open and 0.9 or 0.5)) end
  function M.perc(_, v) throw(3, K.num(v, 1) * 0.3); lamp[2] = math.max(lamp[2], 0.5) end
  function M.tom(v) throw(1, K.num(v, 1) * 0.5) end

  function M.ratchet(n, voice)
    local m = voice == "kick" and 1 or ((voice == "hat" or voice == "tick") and 3 or 2)
    n = clamp(math.floor(K.num(n, 2)), 1, 16)
    buzz[m], buzz_t[m] = n, 0
    ghost[m], ghost_a[m] = n, 1
    lamp[m] = 1
  end

  -- chaos re-patches the bay on the bar
  function M.bar()
    if K.chaos > 0.35 then
      local c = cables[1 + math.floor(K.rnd() * #cables)]
      c.i = 1 + math.floor(K.rnd() * NJ)
      c.j = 1 + math.floor(K.rnd() * NJ)
      c.b = K.rnd() < 0.5 and 1 or 2
      if c.a == c.b and c.i == c.j then c.j = c.j % NJ + 1 end
    end
  end

  local SPAN = 0.75
  local function meter(m, x0, val, lv)
    local cx, cy = x0 + MW / 2, MY + MH + 9
    local R = 27
    local yb = MY + MH
    -- the box, its face lit faintly from behind, and the scale: an arc of
    -- ticks, the last third hot
    line(1.5, x0, MY, x0 + MW, MY)
    line(1.5, x0, yb, x0 + MW, yb)
    line(1.5, x0, MY, x0, yb)
    line(1.5, x0 + MW, MY, x0 + MW, yb)
    local glow = 0.25 + lamp[m] * 0.5 + val * 0.4 + 0.08 * math.sin(K.T * 7.3 + m)
    K.gradient(MY + 2, yb - 2, function(y) return glow * (1 - (y - MY) / MH * 0.6) end, nil, x0 + 2, x0 + MW - 1)
    K.ring(1.5 + lv * 0.3, cx, cy, R - 4, 12, -math.pi / 2 - SPAN, -math.pi / 2 + SPAN)
    for k = 0, 10 do
      local a = -math.pi / 2 - SPAN + 2 * SPAN * k / 10
      local hot = k >= 7
      local r1 = R - 4
      local r0 = r1 + (k % 5 == 0 and 3 or 1.5)
      line(hot and 3.5 or 1.5, cx + math.cos(a) * r1, cy + math.sin(a) * r1, cx + math.cos(a) * r0, cy + math.sin(a) * r0)
    end
    -- ghost needles: a ratchet's repeats, fanned behind the needle
    for k = 1, math.min(ghost[m], 8) do
      local gv = val - k * 0.07 * ghost_a[m]
      local ga = -math.pi / 2 - SPAN - 0.05 + (2 * SPAN + 0.1) * clamp(gv, 0, 1.08)
      line((4 - k * 0.4) * ghost_a[m], cx + math.cos(ga) * 11, cy + math.sin(ga) * 11, cx + math.cos(ga) * (R - 2), cy + math.sin(ga) * (R - 2))
    end
    -- the needle, from its pivot below the face
    local a = -math.pi / 2 - SPAN - 0.05 + (2 * SPAN + 0.1) * clamp(val, 0, 1.08)
    line(5 + lv * 0.5, cx + math.cos(a) * 11, cy + math.sin(a) * 11, cx + math.cos(a) * (R - 1), cy + math.sin(a) * (R - 1))
    put(2, cx - 3, yb - 1, 7, 1)
    -- the lamp over it
    put(1 + lamp[m] * 9, x0 + MW - 4, MY + 2, 2, 2)
  end

  -- a cable hanging from (x0, y0) to (x1, y1) with slack, swaying
  local function cable(lv, x0, y0, x1, y1, sag, sway)
    local mx, my = (x0 + x1) / 2 + sway, math.max(y0, y1) + sag
    local px, py = x0, y0
    for k = 1, 8 do
      local t = k / 8
      local x = (1 - t) ^ 2 * x0 + 2 * (1 - t) * t * mx + t * t * x1
      local y = (1 - t) ^ 2 * y0 + 2 * (1 - t) * t * my + t * t * y1
      line(lv, px, py, x, y)
      px, py = x, y
    end
  end

  function M.draw(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi = A[K.LO], A[K.HI]
    -- the needles: a spring toward the meter's level, thrown by the hits
    local target = {lo * 0.6 + K.env.kick * 0.3, A[K.MID] * 0.5 + K.env.snare * 0.3, hi * 0.6 + K.env.hat * 0.3}
    for m = 1, 3 do
      local to = target[m] * (0.6 + 0.5 * e) + 0.03
      if buzz[m] > 0 then
        buzz_t[m] = buzz_t[m] - DT
        if buzz_t[m] <= 0 then vel[m] = vel[m] + 4; buzz[m] = buzz[m] - 1; buzz_t[m] = 0.05; lamp[m] = 1 end
      end
      ghost_a[m] = ghost_a[m] * math.exp(-DT / 0.35)
      to = to + 0.012 * math.sin(T * 5.1 + m * 2)        -- the needles never quite rest
      if c > 0.2 then to = to + (K.hash(math.floor(T * 14) + m * 31, 2) - 0.5) * c * 0.25 end
      local acc = (to - ndl[m]) * 260 - vel[m] * 15
      vel[m] = vel[m] + acc * DT
      ndl[m] = clamp(ndl[m] + vel[m] * DT, -0.05, 1.1)
      lamp[m] = lamp[m] * math.exp(-DT / 0.08)
    end
    for m = 1, 3 do meter(m, MX[m], ndl[m], e * 2) end

    -- the panel: a seam and its screws
    line(1, 0, 33, 127, 33)
    for _, x in ipairs({2, 125}) do put(2, x, 35, 1, 1); put(2, x, 61, 1, 1) end
    -- the patch bay: the jacks
    for r = 1, 2 do
      for j = 1, NJ do
        local lv = 2 + (r == 1 and lamp[1 + (j - 1) % 3] * 3 or 0)
        K.ring(lv, JX[j], JY[r], 2, 6)
        put(1, JX[j] - 2, JY[r] + 4, 5, 1)
      end
    end
    -- the cables: more patched in with energy, swaying with the swing
    local n = clamp(math.floor(3 + e * 4 + 0.5), 3, #cables)
    local sw = 2.5 + K.swing * 6 + e * 2
    local shake = K.env.kick * (1.5 + e * 2) + K.duck * 0.8
    for k = 1, n do
      local C = cables[k]
      local x0, y0 = JX[C.i], JY[C.a] + 2
      local x1, y1 = JX[C.j], JY[C.b] + 2
      local sway = math.sin(T * (1.3 + K.swing) + C.ph) * sw + math.sin(T * 9 + C.ph) * shake
      local sag = C.sag * (0.6 + 0.4 * math.max(0, (64 - math.max(y0, y1)) / 22)) + shake * 0.6 + lo * 2
      local lv = 2 + (k % 3) * 0.7 + K.env.perc * 2 + hi * 1.5
      cable(lv, x0, y0, x1, y1, math.min(sag, 62 - math.max(y0, y1)), sway)
      put(lv + 2, x0, y0 - 1, 1, 1); put(lv + 2, x1, y1 - 1, 1, 1)
    end
    -- the power lamp, breathing
    put(1.5 + 2 * (0.5 + 0.5 * math.sin(T * 0.9)), 122, 39, 2, 1)
  end

  M.init()
  return M
end
