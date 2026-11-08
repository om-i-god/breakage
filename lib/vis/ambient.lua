-- ambient. view 1: still water at dusk under a big sky, a low sun on the
-- horizon with its path broken on the water, cloud strata drifting over.
-- view 2: aurora curtains folding over a dark ridge and a lake that holds
-- their light, stars above.
--
-- view 1: the kick swells the sun and lifts a slow swell across the tide
-- lines; snares drop rings on the water that spread for seconds; hats,
-- rides and shakers glint and ripple the sun's path; percussion lights stars;
-- a ratchet skips a stone across the water; a fill sends birds over. energy
-- warms the sky and brings in more tide lines, chaos breaks the sun's path
-- into several and doubles the sun as a mirage, and kickless stretches let
-- the sun sink and the stars come out.
-- view 2: the kick swells the curtains, a snare sends a fold along them, hats
-- and rides shimmer rays up through them, percussion throws a falling star,
-- a ratchet runs a train of rays, a fill surges the whole sky. energy adds a
-- second curtain and height, chaos tears and kinks them, kickless fades them
-- to one faint band.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  local HY = 31                         -- the horizon
  local SX = 82                         -- the sun's x
  local MAXR, MAXS = 10, 10

  -- the far shore: low hills on the left, an island on the right
  local SHORE = K.profile(function(x)
    local h = 0
    if x < 56 then h = 3.5 * math.sin(x / 56 * math.pi) ^ 0.7 + 1.5 * math.sin(x * 0.21) ^ 2 end
    if x > 104 and x < 122 then h = 1.6 * math.sin((x - 104) / 18 * math.pi) end
    return HY - h
  end)
  -- view 2's ridge
  local RIDGE = K.profile(function(x)
    return 49 - 9 * math.sin(x / 128 * math.pi * 1.3 + 0.4) ^ 2 - 3 * math.sin(x * 0.11 + 1) * math.sin(x * 0.037)
      - 1.5 * math.sin(x * 0.29) ^ 2
  end)

  local function at_ridge(x) return K.at(RIDGE, x) end

  local rings, stars, birds, rays, falls
  local swell, sw_s                     -- the kick's swell, eased
  local glint, sink, surge, fold, fold_t

  function M.init()
    rings, stars, birds, rays, falls = {}, {}, {}, {}, {}
    swell, sw_s = 0, 0
    glint, sink, surge = 0, 0, 0
    fold, fold_t = 0, -99
  end
  M.clear = M.init

  local function drop(x, y, lv, sp, t0)
    if #rings >= MAXR then table.remove(rings, 1) end
    rings[#rings + 1] = {x = x, y = y, lv = lv, sp = sp, t0 = t0 or K.T, seed = math.floor(K.rnd() * 999)}
  end

  local function star(lv)
    if #stars >= MAXS then table.remove(stars, 1) end
    stars[#stars + 1] = {x = 4 + K.rnd() * 120, y = 2 + K.rnd() * 18, lv = lv, t0 = K.T}
  end

  function M.kick(v) swell = math.max(swell, 0.5 + 0.5 * K.num(v, 1)) end

  function M.snare(v, n)
    v = K.num(v, 1)
    local y = HY + 4 + K.rnd() ^ 1.5 * 26
    local x = 10 + K.rnd() * 108
    if K.chaos > 0.4 then x = x + (K.rnd() - 0.5) * 20 end
    drop(x, y, 4 + 6 * v, 7)
    drop(x, y, 2.5 + 3 * v, 7, K.T + 0.45)
    fold, fold_t = math.max(fold, 0.5 + 0.5 * v), K.T
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8) end
  function M.rim(v) v = K.num(v, 1); drop(10 + K.rnd() * 108, HY + 3 + K.rnd() * 10, 2 + 3 * v, 4) end

  function M.hat(v, open)
    v = K.num(v, 1)
    glint = math.max(glint, (open and 0.7 or 0.4) * v)
    if #rays < 12 then rays[#rays + 1] = {x = K.rnd() * 128, t0 = K.T, lv = (open and 4 or 2.5) * v} end
  end
  function M.ride(v) M.hat(K.num(v, 1), true) end
  function M.shaker(v) glint = math.max(glint, 0.3 * K.num(v, 1)) end

  function M.perc(kind, v)
    v = K.num(v, 1)
    star(3 + 5 * v)
    if (kind == 8 or kind == 4) and #falls < 3 then
      falls[#falls + 1] = {x = 20 + K.rnd() * 90, y = 2 + K.rnd() * 8, t0 = K.T, dx = K.rnd() < 0.5 and -1 or 1}
    end
  end
  function M.tom(v)
    v = K.num(v, 1)
    drop(20 + K.rnd() * 88, HY + 8 + K.rnd() * 16, 2 + 3 * v, 12)
  end
  function M.tick() glint = math.max(glint, 0.25) end
  function M.brk(s) if K.num(s, 1) % 3 == 1 then star(3) end end

  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 10)
    -- a skipping stone: drops along a line, closer and closer together
    local x, y = 16 + K.rnd() * 30, HY + 20 + K.rnd() * 8
    local dx, dy = 9 + K.rnd() * 4, -1.6
    for k = 0, n - 1 do
      drop(x, y, 7 - k * 0.5, 5, K.T + k * 0.09)
      x, y = x + dx, y + dy
      dx, dy = dx * 0.8, dy * 0.8
    end
    for k = 1, math.min(n, 6) do
      if #rays < 12 then rays[#rays + 1] = {x = 10 + k * 18, t0 = K.T + k * 0.06, lv = 6} end
    end
  end

  function M.fill()
    surge = 1
    if #birds < 6 then
      local y = 8 + K.rnd() * 10
      for k = 0, 2 do
        birds[#birds + 1] = {x = -6 - k * 7, y = y + k * 2 + K.rnd() * 2, t0 = K.T, ph = K.rnd() * 6}
      end
    end
  end

  ---------------------------------------------------------------- view 1
  local function sun(lv, x, y, r)
    for dy = -math.floor(r), math.floor(r) do
      local yy = y + dy
      if yy < HY then
        local hw = math.sqrt(math.max(0, r * r - dy * dy))
        if hw >= 0.5 then put(lv, x - hw, yy, hw * 2, 1) end
      end
    end
  end

  local function wring(lv, cx, cy, r, jit, seed)
    local u = (cy - HY) / (63 - HY)
    local sq = 0.14 + u * 0.22
    local segs = clamp(math.floor(10 + r * 0.3), 10, 20)
    local px, py
    for k = 0, segs do
      local a = K.TAU * k / segs
      local rr = r + (jit > 0 and (K.hash(k % segs + seed * 61, 7) - 0.5) * 2 * jit or 0)
      local x, y = cx + math.cos(a) * rr, cy + math.sin(a) * rr * sq
      if y < HY + 1 then y = HY + 1 end
      if px then line(lv, px, py, x, y) end
      px, py = x, y
    end
  end

  local function draw1(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl, mid = A[K.LO], A[K.HI], K.kickless, A[K.MID]
    local sy = HY + 1 + sink * 4 - e * 1.5
    local sr = 7.5 + sw_s * 1.6 + lo * 0.6

    -- the sky: deepening upward, warm around the sun
    K.gradient(5, HY - 1, function(y)
      local u = (y - 5) / (HY - 6)
      return u * u * (1.05 + e * 0.4 + sw_s * 0.15) * (1 - sink * 0.35)
    end, SHORE)
    K.gradient(HY - 14, HY - 1, function(y)
      local u = (y - HY + 14) / 14
      return u * (1.2 + e * 0.6 + sw_s * 0.6 + lo * 0.3) * (1 - sink * 0.4)
    end, SHORE, SX - 34, SX + 34)
    -- stars: a few always, more as the dusk deepens; percussion adds some
    for i = 0, 13 do
      local x, y = math.floor(K.hash(i, 1) * 127), 1 + math.floor(K.hash(i, 2) * 12)
      local tw = 0.5 + 0.5 * math.sin(T * (0.3 + K.hash(i, 3) * 0.6) + i)
      local show = i < 4 + sink * 10
      if show then put(0.8 + tw * (0.7 + sink * 2) + hi * 1.5, x, y, 1, 1) end
    end
    for i = #stars, 1, -1 do
      local s = stars[i]
      local u = (K.T - s.t0) / 2.5
      if u >= 1 then table.remove(stars, i)
      else put(s.lv * math.sin(math.pi * math.min(1, u * 4)) * (1 - u), s.x, s.y, 1, 1) end
    end
    -- cloud strata, lit from below
    for k = 0, 3 do
      local cy = 7 + k * 5 + math.floor(K.hash(k, 11) * 3)
      local len = 26 + K.hash(k, 12) * 34
      local x = (K.hash(k, 13) * 200 + T * (0.6 + k * 0.25)) % (128 + len) - len
      local near = 1 - math.min(1, math.abs(x + len / 2 - SX) / 70)
      local cl = 1.5 + near * (2 + sw_s) + e * 0.8 + k * 0.3
      put(cl, x, cy, len, 1)
      put(cl * 0.6, x + 4, cy - 1, len - 10, 1)
      put(cl * 0.5, x + len * 0.3, cy + 1, len * 0.5, 1)
    end
    -- birds on a fill
    for i = #birds, 1, -1 do
      local b = birds[i]
      local x = b.x + (K.T - b.t0) * 14
      if x > 134 then table.remove(birds, i)
      else
        local f = math.sin(K.T * 5 + b.ph) * 1.5
        line(5, x - 2, b.y - f, x, b.y)
        line(5, x, b.y, x + 2, b.y - f)
      end
    end
    -- the sun, swelling on the kick; chaos lifts a mirage beside it
    K.ring(1.5 + sw_s * 2 + e, SX, sy, sr + 4 + sw_s * 2, 18, math.pi, K.TAU)
    sun(4 + sw_s * 2 + e * 1.5 - sink * 1.5, SX, sy, sr)
    sun(7 + sw_s * 3 + e * 1.5 - sink * 2, SX, sy + 1, sr - 2.5)
    if c > 0.35 then sun(2 + c * 3, SX + 3 + c * 10, sy - 1 - c * 2, sr * 0.6) end
    -- the far shore line
    line(2 + sw_s * 1.5, 0, HY, 127, HY)

    -- the water: the sky's glow held near the horizon, slow tide lines
    -- running toward us (more with energy), a swell lifting them on the kick
    K.gradient(HY + 1, HY + 6, function(y) return (0.9 - (y - HY) * 0.15) * (1 - sink * 0.4) + sw_s * 0.2 end)
    local nt = math.floor(6 + e * 5)
    for k = 0, nt - 1 do
      local p = ((k + T * 0.06) % nt) / nt
      local y = HY + 3 + p * p * 30
      local len = 10 + p * 40
      local x = (K.hash(k, 21) * 128 + T * (0.5 + p) * (K.hash(k, 22) - 0.5) * 4) % 128
      local l = (1 + p * 1.5 + sw_s * 1.5 * p) * (0.5 + 0.5 * math.sin(p * math.pi))
      put(l, x - len / 2, y + sw_s * p * 1.2, len, 1)
      if p > 0.5 then put(l * 0.7, x + len * 0.4, y + 1, len * 0.3, 1) end
    end
    -- the sun's path on the water, broken by ripples (hats shake it)
    local npath = c > 0.4 and 2 or 1
    local wob = 0.6 + hi * 2.5 + glint * 3
    for j = 0, npath - 1 do
      local ox = j == 0 and 0 or (12 + c * 14) * (K.hash(j, 5) < 0.5 and -1 or 1)
      for y = HY + 1, 63, 2 do
        local u = (y - HY) / (63 - HY)
        local w = (sr * 0.9 + u * 7) * (0.65 + 0.35 * math.sin(y * 0.9 + T * 1.7))
        local x = SX + ox + math.sin(y * 0.55 + T * 1.3) * wob * (0.4 + u)
        local l = (7 + sw_s * 2 + e - u * 5) * (1 - sink * 0.4) * (j == 0 and 1 or 0.5)
        if l > 0.6 then
          local gap = (math.sin(y * 1.7 - T * 2.1) > 0.3) and w * 0.3 or 0
          put(l, x - w / 2, y, w / 2 - gap / 2, 1)
          put(l * 0.85, x + gap / 2, y, w / 2 - gap / 2, 1)
        end
      end
    end
    -- glints on the path
    K.grain(function(u, v)
      local y = HY + 2 + v * 30
      return SX + (u - 0.5) * (14 + v * 26), y
    end, 2 + hi * 16 + glint * 30 + e * 4, 5 + hi * 4 + glint * 4)

    -- rings where the snares drop
    for i = #rings, 1, -1 do
      local R = rings[i]
      local age = K.T - R.t0
      local life = 3.2 + e
      if age > life then table.remove(rings, i)
      elseif age >= 0 then
        local u = age / life
        local r = 1.5 + age * R.sp * (1 - u * 0.4)
        wring(R.lv * (1 - u) ^ 1.3 + hi * (1 - u), R.x, R.y, r, c * 2.5 * (1 - u), R.seed)
      end
    end
  end

  ---------------------------------------------------------------- view 2
  local LK = 51                         -- the lake's far edge
  local foot = {}                       -- this frame's curtain foot per column (for the lake)

  local function draw2(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl = A[K.LO], A[K.HI], K.kickless
    local inten = math.min(1.25, (0.5 + e * 0.3 + sw_s * 0.4 + surge * 0.5 + lo * 0.15) * (1 - kl * 0.45))

    -- stars
    for i = 0, 23 do
      local x, y = math.floor(K.hash(i, 31) * 127), 1 + math.floor(K.hash(i, 32) * 30)
      local tw = 0.5 + 0.5 * math.sin(T * (0.4 + K.hash(i, 33)) + i * 2.3)
      put(0.8 + tw * (0.8 + kl * 1.5) + glint * 2 * tw, x, y, 1, 1)
    end
    for i = #stars, 1, -1 do
      local s = stars[i]
      local u = (K.T - s.t0) / 2.5
      if u >= 1 then table.remove(stars, i)
      else put(s.lv * (1 - u), s.x, s.y, 1, 1) end
    end
    for i = #falls, 1, -1 do
      local f = falls[i]
      local u = (K.T - f.t0) / 0.9
      if u >= 1 then table.remove(falls, i)
      else
        local x, y = f.x + f.dx * u * 30, f.y + u * 14
        line(9 * (1 - u), x, y, x - f.dx * 6, y - 3)
      end
    end

    -- the curtains: rays hanging from a wavy foot, the foot the brightest;
    -- a snare's fold runs along them. back layers first, higher and fainter
    local layers = 1 + (e > 0.3 and 1 or 0) + (e > 0.75 and 1 or 0)
    local fu = K.T - fold_t
    local fx = fu * 70 - 10
    for x = 0, 127 do foot[x] = 0 end
    for L = layers, 1, -1 do
      local base = 41 - (L - 1) * 9
      local li = inten * (L == 1 and 1 or 0.5 - (L - 2) * 0.15)
      local sx = L == 1 and 1 or 2
      for x = 0, 127, sx do
        local tear = 0
        if c > 0.3 then tear = math.sin(x * 0.07 + T * 0.9 + L) * c * 5 + (K.hash(x // 12 + L * 9, 4) - 0.5) * c * 7 end
        local yb = base + 4 * math.sin(x * 0.04 + T * 0.21 + L * 1.7) + 2 * math.sin(x * 0.1 - T * 0.29 + L) + tear
        local d = x - fx
        if fu < 2.2 and math.abs(d) < 18 then
          yb = yb - fold * (1 - fu / 2.2) * 6 * math.cos(d / 18 * math.pi / 2)
        end
        local bright = li * (0.45 + 0.55 * (0.5 + 0.5 * math.sin(x * 0.11 + T * 0.37 + L)) ^ 2)
        local l = 1 + bright * 5.5
        local rr = K.at(RIDGE, x) - 1
        local yc = math.min(yb, rr)
        -- the foot: a bright ribbon
        if yb - 2 < rr then put(l, x, yb - 2, sx, math.max(1, yc - yb + 2)) end
        if L == 1 then
          foot[x] = l
          -- rays above it, uneven, fading up in two steps
          local hx = K.hash(x, 51)
          if x % 2 == 0 or hx < 0.15 then
            local h = (6 + 20 * hx * (0.4 + 0.6 * (0.5 + 0.5 * math.sin(x * 0.083 - T * 0.17)))) * (0.7 + 0.45 * inten)
            local y0 = math.min(rr, yb - 3)
            line(l * 0.5, x, y0 - h * 0.5, x, y0)
            line(l * 0.28, x, y0 - h, x, y0 - h * 0.5 - 1)
          end
        end
      end
    end
    -- rays: hats and rides shimmer up through the curtain
    for i = #rays, 1, -1 do
      local r = rays[i]
      local u = (K.T - r.t0) / 0.6
      if u >= 1 then table.remove(rays, i)
      elseif u >= 0 then
        local x = math.floor(r.x)
        local yb = math.min(41 + 4 * math.sin(x * 0.04 + T * 0.21 + 1.7), K.at(RIDGE, x) - 2)
        line(r.lv * (1 - u) * (0.6 + inten * 0.6), x, yb - 24 * (0.5 + u * 0.5), x, yb)
      end
    end

    -- the ridge: black, with snow along its crest and down a few gullies
    for c2 = 0, 63 do
      local top = math.floor(RIDGE[c2] + 0.5)
      put(1.2 + sw_s * 0.8 + inten * 0.6, c2 * 2, top, 2, 1)
      if K.hash(c2, 41) < 0.35 then put(1, c2 * 2, top + 2 + math.floor(K.hash(c2, 42) * 3), 1, 2) end
    end
    -- the lake: the far shore, then the curtain's foot held in the water,
    -- broken by slow ripples
    line(1 + inten * 0.5, 0, LK, 127, LK)
    for y = LK + 3, 63, 3 do
      local u = (y - LK) / (63 - LK)
      local off = math.sin(y * 0.7 + T * 0.9) * (1 + glint * 3 + hi * 2) * (0.5 + u)
      local run
      for x = 0, 127, 4 do
        local v = foot[x] * (0.55 - u * 0.35)
        local on = v > 1.6 and math.sin(x * 0.3 + y * 1.3 + T * 0.6) > -0.1
        if on and not run then run = x
        elseif not on and run then put(1.4, run + off, y, x - run - 1, 1); run = nil end
      end
      if run then put(1.4, run + off, y, 128 - run, 1) end
    end
    K.grain(function(u, v) return u * 128, 2 + v * 30 end, 1 + hi * 10 + glint * 20, 3 + hi * 4)
  end

  function M.draw(S)
    local DT = K.DT
    swell = swell * math.exp(-DT / 0.6)
    sw_s = K.follow(sw_s, swell, 0.08, DT)
    glint = glint * math.exp(-DT / 0.25)
    surge = surge * math.exp(-DT / 1.2)
    fold = fold * math.exp(-DT / 1.5)
    sink = K.follow(sink, K.kickless, 2, DT)
    if K.view == 2 then draw2(S) else draw1(S) end
  end

  M.init()
  return M
end
