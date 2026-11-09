-- dubstep. view 1: a dripping concrete storm drain in one-point perspective, black water on its floor and a glow at the far end.
-- view 2: a storm over a city at night: lightning forks out of the cloud, rain sheets sweep the skyline, thunder rolls through.
--
-- view 1: the sub kick heaves the black water (ripples run out across it)
-- and shakes the ceiling a pixel; the big snare lights the whole tunnel
-- (eased in, never a flash) and its light runs off down the drain, coming
-- back fainter at the echo time; the clap lights the walls; the wobble
-- stab makes the far glow pulse at the wobble rate; hats, ticks and break
-- slices drip from the ceiling (each drop rings the water); metal clanks a
-- ring of the pipe; a ratchet is a run of drips; a fill throws a train of
-- light down the tunnel. AMP lights the concrete, LO lifts the water, MID
-- brightens the middle of the tunnel, HI glints on the wet ceiling and the
-- water. energy brightens and quickens it; chaos bends the drain and ghosts
-- a second branch beside it; kickless, the water stills and mist fills it.
-- view 2: the snare forks lightning from the cloud to the rooftops (an eased
-- glow, it lights the cloud base and the roofs near it); the kick rolls
-- thunder through the clouds; hats send sheets of rain across; the wobble
-- pulses the radio mast; perc lights windows; ticks flicker one. AMP lights
-- the windows, LO the cloud base, MID the roof edges and the mast, HI the
-- rain. chaos splits the strikes into many and crosses the rain; energy
-- thickens the rain and the lights; kickless, mist rolls between the towers.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local floor, sin, cos, exp, max, min, abs, sqrt = math.floor, math.sin, math.cos, math.exp, math.max,
    math.min, math.abs, math.sqrt
  local TAU = K.TAU

  ---------------------------------------------------------------- view 1
  local VX, VY = 64, 24               -- the vanishing point
  local F = 34                        -- focal scale
  local WY = 0.5                      -- the water surface (world y, down +)
  local WA = math.asin(WY)            -- where the water meets the wall
  local NR = 11
  local RZ = {}
  for k = 0, NR - 1 do RZ[k] = 0.62 * 1.33 ^ k end
  local WALLS = {3.6, 4.1, 4.7, 5.3, 5.9}   -- angles of the long joints

  local ripples, drips, pulses, emits, clank
  local snt, snl, clf, wob, wph, shk, fillf, mist_k
  local MAXRIP, MAXDRIP = 12, 14
  local idle_t = 0

  ---------------------------------------------------------------- view 2
  local GY = 63
  local FAR = K.profile(function(x)
    local h = 12 + floor(K.hash(x // 8, 11) * 10)
    return 40 - h * 0.5
  end)
  local NEAR = K.profile(function(x)
    local b = x // 14
    local h = 10 + floor(K.hash(b, 21) * 16)
    if b == 5 then h = 30 end                       -- the tower with the mast
    if K.hash(b, 22) > 0.7 and x % 14 > 9 then h = h - 6 end
    return GY - 8 - h
  end)
  local MASTX = 5 * 14 + 7
  local forks, rolls, sheets, wins
  local flk, mast

  function M.init()
    ripples, drips, pulses, emits, clank = {}, {}, {}, {}, {}
    for k = 0, NR - 1 do clank[k] = 0 end
    snt, snl, clf, wob, wph, shk, fillf, mist_k = 0, 0, 0, 0, 0, 0, 0, 0
    idle_t = 0
    forks, rolls, sheets, wins = {}, {}, {}, {}
    flk, mast = 0, 0
  end
  M.clear = M.init

  -- world (x across, y down, z ahead) to screen, with the chaos bend
  local bend = 0
  local function proj(x, y, z)
    local s = F / z
    return VX + x * s + bend * z * z * 0.25, VY + y * s, s
  end

  ---------------------------------------------------------------- events
  local function ripple(x, z, v, rmax)
    if #ripples >= MAXRIP then table.remove(ripples, 1) end
    ripples[#ripples + 1] = {x = x, z = z, v = v, t0 = K.T, rmax = rmax or 1.2}
  end

  local function drip(v, k)
    if #drips >= MAXDRIP then table.remove(drips, 1) end
    k = k or (2 + floor(K.rnd() * 6))
    local a = 1.5 * math.pi + (K.rnd() - 0.5) * 1.6
    local z = RZ[clamp(k, 0, NR - 1)] * (0.9 + K.rnd() * 0.2)
    drips[#drips + 1] = {x = cos(a) * 0.97, y0 = sin(a) * 0.97, z = z, t0 = K.T, v = v}
  end

  local function pulse(lv, delay)
    if #pulses >= 8 then table.remove(pulses, 1) end
    pulses[#pulses + 1] = {t0 = K.T + (delay or 0), lv = lv}
  end

  -- (view 2) a lightning fork from the cloud down toward the rooftops
  local function fork(v, x)
    if #forks >= 5 then table.remove(forks, 1) end
    x = x or (10 + K.rnd() * 108)
    local pts = {x, 10 + K.rnd() * 4}
    local px, py = pts[1], pts[2]
    local ground = K.at(NEAR, x) + 1
    local br = {}
    while py < ground and #pts < 24 do
      px = px + (K.rnd() - 0.5) * 9
      py = py + 3 + K.rnd() * 4
      if py > ground then py = ground end
      pts[#pts + 1] = px; pts[#pts + 1] = py
      if #br < 2 and K.rnd() < 0.25 + K.chaos * 0.3 then
        local bx, by = px, py
        local b = {bx, by}
        for _ = 1, 3 do
          bx = bx + (K.rnd() < 0.5 and -1 or 1) * (2 + K.rnd() * 4)
          by = by + 2 + K.rnd() * 3
          b[#b + 1] = bx; b[#b + 1] = by
        end
        br[#br + 1] = b
      end
    end
    forks[#forks + 1] = {pts = pts, br = br, x = x, t0 = K.T, v = v, b = 0}
  end

  function M.kick(v)
    v = K.num(v, 1)
    ripple(K.chaos * (K.rnd() - 0.5), 1.6 + K.rnd() * 0.8, v, 1.4)
    shk = max(shk, 0.5 + 0.5 * v)
    if #rolls >= 4 then table.remove(rolls, 1) end
    rolls[#rolls + 1] = {t0 = K.T, x = K.rnd() * 128, dir = K.rnd() < 0.5 and -1 or 1, v = v}
  end

  function M.snare(v)
    v = K.num(v, 1)
    snt = max(snt, 0.6 + 0.4 * v)
    pulse(0.7 + 0.3 * v)
    if #emits >= 4 then table.remove(emits, 1) end
    emits[#emits + 1] = {lv = 0.7 * v, next = K.NOW + K.echo_t, n = 0}
    local n = 1 + floor(K.chaos * 2.5 + 0.2)
    for i = 1, n do fork(v * (i == 1 and 1 or 0.6)) end
  end

  function M.clap(v)
    v = K.num(v, 1)
    clf = max(clf, 0.5 + 0.5 * v)
    flk = max(flk, 0.6 * v)
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    drip(0.5 + 0.5 * v)
    if #sheets >= 5 then table.remove(sheets, 1) end
    sheets[#sheets + 1] = {t0 = K.T, x = K.rnd() * 128, v = (open and 1 or 0.6) * v, w = open and 40 or 24}
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 14 then
      wob = max(wob, 0.6 + 0.4 * v)
      mast = max(mast, 0.5 + 0.5 * v)
    elseif kind == 6 or kind == 3 then
      local k = 1 + floor(K.rnd() * 6)
      clank[k] = max(clank[k], 0.6 + 0.4 * v)
    elseif kind == 13 or kind == 17 or kind == 1 then
      ripple((K.rnd() - 0.5) * 0.8, 2.5 + K.rnd() * 3, 0.6 * v, 0.9)
    else
      drip(0.6 * v)
    end
    if #wins >= 8 then table.remove(wins, 1) end
    wins[#wins + 1] = {x = floor(K.rnd() * 60) * 2 + 4, t0 = K.T, v = v, r = K.rnd()}
  end
  function M.tom(v) M.perc(13, v) end

  function M.tick() drip(0.4); flk = max(flk, 0.3) end
  function M.brk(s, n)
    s, n = K.num(s, 1), max(1, K.num(n, 8))
    drip(0.5, 1 + floor((s - 1) / n * 8))
  end
  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    for i = 1, min(n, 6) do drip(0.8, 1 + i) end
    for i = 0, min(n, 4) - 1 do pulse(0.6 - i * 0.1, i * 0.07) end
    snt = max(snt, 0.5)
  end
  function M.fill()
    fillf = 1
    for i = 0, 3 do pulse(0.8 - i * 0.15, i * 0.12) end
    fork(1, 64)
  end

  ---------------------------------------------------------------- view 1 drawing
  local function fog(z) return exp(-z / (6 + 4 * K.energy - 2.5 * K.kickless)) end

  local function draw1(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]
    bend = c * 0.9 * sin(T * 0.25)
    -- the drain drips on its own, a slow irregular drip
    if T >= idle_t then
      drip(0.35 + 0.2 * K.rnd())
      idle_t = T + 0.6 + K.rnd() * 1.4
    end
    -- the echoes of the snare light, at the echo time
    for i = #emits, 1, -1 do
      local em = emits[i]
      if K.NOW >= em.next then
        em.lv = em.lv * K.echo_fb
        em.n = em.n + 1
        if em.lv > 0.12 then pulse(em.lv) end
        em.next = em.next + K.echo_t
      end
      if em.lv <= 0.12 or em.n > 6 then table.remove(emits, i) end
    end
    local glow = 0.35 + 0.25 * amp + 0.15 * e + kl * 0.25
      + wob * (0.5 + 0.5 * sin(wph)) * 1.1
    local heave = lo * 1.2 + shk * 0.5
    local sy = floor(shk * 1.3 + 0.3)                       -- the lip's shudder, px

    -- the far end: an outfall glow beyond the last ring
    local fx, fy = proj(0, 0, RZ[NR - 1] * 1.2)
    K.disc(min(12, 2 + glow * 7), fx, fy, 1.5 + glow * 1.5)
    K.ring(min(8, 1 + glow * 4), fx, fy, 4 + glow * 3, 12)
    if glow > 0.6 then K.ring(min(5, glow * 2), fx, fy, 8 + glow * 4, 14) end

    -- the rings of the pipe, nearest first; lit by the snare, its echoes,
    -- the wobble glow (far ones), the mids (middle ones) and the clanks
    for k = 0, NR - 1 do
      local z = RZ[k]
      local cx, cy, s = proj(0, 0, z)
      local f = fog(z)
      local lv = (0.8 + 1.2 * f) * (0.7 + 0.6 * amp + 0.3 * e)
      lv = lv + snl * 3 * (0.3 + 0.7 * f)
      for p = 1, #pulses do
        local P = pulses[p]
        local age = K.T - P.t0
        if age >= 0 then
          local zp = 0.5 + age * 7
          local d = abs(z - zp) / (0.4 + zp * 0.25)
          if d < 1 then lv = lv + P.lv * 3 * (1 - d) * (0.4 + 0.6 * f) end
        end
      end
      if k >= 3 and k <= 7 then lv = lv + mid * 2.5 * f end
      lv = lv + glow * 3 * (1 - f) * (k / NR)
      lv = lv + clank[k] * 5
      lv = min(12, lv)
      local yy = cy + (k == 0 and sy or 0)
      K.ring(lv, cx, yy, s, k < 3 and 22 or 14, math.pi - WA, TAU + WA)
      if k == 0 then K.ring(lv * 0.7, cx, yy, s - 3, 22, math.pi - WA + 0.05, TAU + WA - 0.05) end
      -- its reflection in the black water: the wall feet, wobbling
      local wl = cy + WY * s
      local wo = sin(T * 2.1 + k * 1.3) * (0.4 + heave * 1.5) * min(1, s / 12)
      for side = -1, 1, 2 do
        local x0 = cx + side * cos(WA) * s
        local x1 = cx + side * cos(WA + 0.45) * s
        local y1 = wl + s * 0.22
        line(lv * 0.35, x0 + wo, wl + 1, x1 + wo, y1)
      end
    end

    -- the long joints down the pipe walls
    local nearz, farz = RZ[1], RZ[NR - 1]
    for i = 1, #WALLS do
      local a = WALLS[i]
      local xa, ya = proj(cos(a), sin(a), nearz)
      local xb, yb = proj(cos(a), sin(a), farz)
      line(1 + clf * 4 + amp * 0.8, xa, ya, xb, yb)
    end

    -- the water: its edges along the walls, heaving with the sub
    local hv = floor(heave * 1.5 * sin(T * 3.1) + 0.5)
    for side = -1, 1, 2 do
      local xa, ya = proj(side * cos(WA), WY, RZ[0])
      local xb, yb = proj(side * cos(WA), WY, farz)
      line(1.5 + lo * 2 + e, xa, ya + hv, xb, yb)
    end
    -- the far glow's reflection: a broken column of light on the water
    local _, wy0 = proj(0, WY, farz)
    for y = floor(wy0) + 1, 63, 2 do
      local u = (y - wy0) / (63 - wy0)
      local w = 1 + u * (3 + glow * 6)
      local dx = sin(y * 0.6 + T * 2.3) * (0.5 + heave * 2 + u * 2)
      local lv = (glow * 4 + hi * 2.5) * (1 - u * 0.6) * (0.6 + 0.4 * sin(y * 1.3 - T * 4))
      if lv > 0.6 then put(min(9, lv), VX + bend * 0.5 + dx - w / 2, y + hv, w, 1) end
    end
    -- glints on the water (HI)
    for i = 0, 9 do
      local z = 1 + K.hash(i, 5) * 6
      local x = (K.hash(i, 6) - 0.5) * 1.4
      local px, py = proj(x, WY, z)
      local tw = 0.5 + 0.5 * sin(T * (2 + K.hash(i, 7) * 3) + i * 2)
      put(tw * (1 + hi * 6), px, py + hv, 2, 1)
    end

    -- ripples spreading over the water
    for i = #ripples, 1, -1 do
      local R = ripples[i]
      local age = K.T - R.t0
      local life = 1.6 * (1 - kl * 0.4)
      if age > life then table.remove(ripples, i)
      elseif age >= 0 then
        local u = age / life
        local rr = 0.05 + R.rmax * (1 - (1 - u) ^ 2)
        local lv = (2 + 6 * R.v) * (1 - u) * (1 - kl * 0.5) * fog(R.z * 0.6)
        local px, py, pok
        for j = 0, 16 do
          local a = TAU * j / 16
          local x, z = R.x + cos(a) * rr, R.z + sin(a) * rr
          local ok = abs(x) < cos(WA) - 0.02 and z > 0.7
          local sx, syy = proj(x, WY, max(0.7, z))
          if px and ok and pok then line(lv, px, py + hv, sx, syy + hv) end
          px, py, pok = sx, syy, ok
        end
      end
    end

    -- drips: fall from the ceiling, ring the water where they land
    for i = #drips, 1, -1 do
      local D = drips[i]
      local age = K.T - D.t0
      local y = D.y0 + 0.5 * 9 * age * age
      if y >= WY then
        ripple(D.x * 0.85, D.z, D.v * 0.6, 0.35)
        table.remove(drips, i)
      else
        local x, sy2, s = proj(D.x, y, D.z)
        local f = fog(D.z)
        put(min(11, (3 + 6 * D.v + hi * 2) * (0.5 + 0.5 * f)), x, sy2, 1, s > 20 and 3 or 2)
      end
    end

    -- the branch: chaos ghosts a second drain off to one side
    if c > 0.35 then
      local cl = (c - 0.35) / 0.65
      local off = 34 * (sin(T * 0.13) > 0 and 1 or -1)
      for k = 3, NR - 1, 2 do
        local cx, cy, s = proj(0, 0, RZ[k])
        K.ring((1 + 2 * fog(RZ[k])) * cl, cx + off * fog(RZ[k] * 0.5), cy, s * 0.6, 10, math.pi - WA, TAU + WA)
      end
    end

    -- the hanging weed at the pipe's lip, swinging with the sub
    for i = 0, 6 do
      local x = 6 + i * 19 + floor(K.hash(i, 9) * 8)
      local len = 3 + floor(K.hash(i, 10) * 6)
      local sw = sin(T * 0.9 + i) * (0.5 + lo * 1.5)
      line(1.5 + amp, x, 0, x + sw, len)
      if K.hash(i, 11) > 0.5 then put(2 + hi * 4 + K.env.hat * 4, x + sw, len + 1, 1, 1) end
    end

    -- mist, and the drain's wet air glinting (HI)
    K.haze(16, 6, 112, 40, 0.1 + 0.45 * kl + 0.1 * e, 1, T * 4)
    K.grain(function(u, v) return 24 + u * 80, 2 + v * 20 end, 2 + hi * 14 + e * 3, 2 + hi * 5)
  end

  ---------------------------------------------------------------- view 2 drawing
  local function draw2(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]

    -- lightning strength (eased in and out)
    local bolt, bx = 0, 64
    for i = #forks, 1, -1 do
      local Fk = forks[i]
      local age = K.T - Fk.t0
      local to = age < 0.08 and Fk.v or Fk.v * exp(-(age - 0.08) / 0.3)
      Fk.b = K.follow(Fk.b, to, 0.07, DT)
      if age > 1.6 then table.remove(forks, i)
      elseif Fk.b > bolt then bolt, bx = Fk.b, Fk.x end
    end

    -- thunder rolling along the clouds on the kick
    for i = #rolls, 1, -1 do
      local R = rolls[i]
      local age = K.T - R.t0
      if age > 1.4 then table.remove(rolls, i)
      else
        R.cx = R.x + R.dir * age * 55
        R.b = sin(math.pi * min(1, age / 1.4)) * R.v * (1 - kl * 0.6)
        R.w = 14 + age * 14
      end
    end
    -- the cloud deck: solid banks hanging over the city, drifting; their
    -- underside lit by the city (LO), by the strikes and the thunder
    for col = 0, 63 do
      local x = col * 2
      local cb = 8 + 4 * sin(x * 0.045 + T * 0.12) + 2.5 * sin(x * 0.11 - T * 0.2)
      if c > 0.3 and sin(x * 0.21 + T * 0.15) > 1.3 - c then cb = cb - 5 * c end   -- torn
      cb = floor(cb + 0.5)
      local lit = bolt * max(0, 1 - abs(x - bx) / (24 + bolt * 20))
      for r = 1, #rolls do
        local R = rolls[r]
        if R.b and R.b > 0 then lit = lit + R.b * 0.6 * max(0, 1 - abs(x - R.cx) / R.w) end
      end
      if cb > 1 then put(1 + lit * 2.5, x, 0, 2, cb) end
      put(min(11, 1 + lo * 2 + e * 0.5 + lit * 5), x, cb, 2, 1)
      -- a ragged lower scud layer, faster
      local sb = 15 + 3 * sin(x * 0.07 + T * 0.35) + 2 * sin(x * 0.19 - T * 0.5)
      if sb > 15.5 then put(1 + lo * 0.8 + lit * 2, x, floor(sb), 2, 1) end
    end

    -- the far skyline: outlines in the rain
    for col = 0, 63 do
      local top = FAR[col]
      if top < NEAR[col] - 1 then put(1 + mid * 1.2, col * 2, top, 2, 1) end
    end
    -- the near skyline: black towers, their roof edges caught by the
    -- lightning and the mids, windows lit by the level (AMP)
    for col = 0, 63 do
      local x = col * 2
      local top = NEAR[col]
      local near = bolt * max(0, 1 - abs(x - bx) / 40)
      put(min(11, 1.2 + mid * 1.8 + near * 8), x, top, 2, 1)
      local nx = NEAR[min(63, col + 1)]
      if nx ~= top then line(1.2 + mid * 1.8 + near * 5, x + 1.5, top, x + 1.5, nx) end
    end
    for b = 0, 9 do
      if K.hash(b, 23) < 0.3 then
        local x0 = b * 14
        for col = x0 // 2, min(63, (x0 + 13) // 2) do
          local top = NEAR[col]
          put(1, col * 2, top + 1, 2, GY - 8 - top)
        end
      end
    end
    -- the windows: how many are lit follows the level (AMP)
    local wl = 0.25 + 0.4 * amp + 0.25 * e
    for b = 0, 9 do
      local x0 = b * 14
      local top = NEAR[min(63, (x0 + 4) // 2)]
      for r = 0, 4 do
        local y = top + 4 + r * 5
        if y < GY - 9 then
          for cc = 0, 2 do
            local h = K.hash(b * 31 + r * 5 + cc, 41)
            if h < wl then
              local lv = 1 + 1.3 * K.hash(b + r * 7 + cc, 42) + amp * 1.5
              put(lv, x0 + 3 + cc * 4, y, 1, 1)
            end
          end
        end
      end
    end
    -- windows the perc switch on, and one that flickers on the ticks
    for i = #wins, 1, -1 do
      local W = wins[i]
      local age = K.T - W.t0
      if age > 0.9 then table.remove(wins, i)
      else
        local top = K.at(NEAR, W.x)
        local y = floor(top + 4 + W.r * (GY - 14 - top))
        put(min(11, 2 + 8 * W.v * sin(math.pi * min(1, age / 0.9))), W.x, y, 2, 1)
      end
    end
    put(min(10, 1 + flk * 8), 33, 46, 2, 1)

    -- the radio mast on the tall tower: its lamps pulse with the wobble
    local mtop = NEAR[MASTX // 2]
    line(1.5 + mid, MASTX, mtop, MASTX, mtop - 10)
    line(1, MASTX - 3, mtop, MASTX, mtop - 7); line(1, MASTX + 3, mtop, MASTX, mtop - 7)
    local mp = 0.3 + 0.2 * sin(T * 1.2) + mast * (0.5 + 0.5 * sin(wph)) + mid * 0.4
    put(min(12, 2 + mp * 9), MASTX - 1, mtop - 11, 3, 1)
    put(min(9, 1 + mp * 6), MASTX, mtop - 5, 1, 1)

    -- the lightning itself
    for i = 1, #forks do
      local Fk = forks[i]
      if Fk.b > 0.05 then
        local P = Fk.pts
        local lv = min(12, 2 + Fk.b * 10)
        for j = 1, #P - 3, 2 do
          line(lv, P[j], P[j + 1], P[j + 2], P[j + 3])
          line(lv * 0.5, P[j] + 1, P[j + 1], P[j + 2] + 1, P[j + 3])
        end
        for _, b in ipairs(Fk.br) do
          for j = 1, #b - 3, 2 do line(lv * 0.55, b[j], b[j + 1], b[j + 2], b[j + 3]) end
        end
        -- the strike's reflection in the wet street
        local gx = P[#P - 1]
        line(lv * 0.4, gx, GY - 6, gx + 1, GY)
      end
    end

    -- rain: a steady fall, sheets sweeping across on the hats (HI)
    local slant = 0.35 + 0.3 * sin(T * 0.1)
    local n = 22 + floor(e * 14 + kl * 10)
    for i = 0, n - 1 do
      local sp = 70 + K.hash(i, 51) * 30
      local x0 = K.hash(i, 52) * 150 - 10
      local y = (K.hash(i, 53) * 80 + T * sp) % 80 - 10
      local x = x0 + y * slant
      local sl = 0.8 + hi * 1.4
      for s = 1, #sheets do
        local Sh = sheets[s]
        local age = K.T - Sh.t0
        local cxs = Sh.x + age * 60 - 20
        local d = abs(x - cxs)
        if d < Sh.w and age < 1 then sl = sl + 3 * Sh.v * (1 - d / Sh.w) * (1 - age) end
      end
      line(min(8, sl * (1 - kl * 0.3)), x, y, x + 3 * slant, y + 3)
      if c > 0.5 and i % 3 == 0 then line(sl * 0.6, x + 20, y, x + 20 - 3 * slant, y + 3) end
    end
    for s = #sheets, 1, -1 do if K.T - sheets[s].t0 > 1 then table.remove(sheets, s) end end

    -- the wet street: reflections of the windows, rain rings
    for i = 0, 11 do
      local x = floor(K.hash(i, 61) * 124)
      local y = GY - 5 + floor(K.hash(i, 62) * 5)
      local tw = 0.5 + 0.5 * sin(T * (1.5 + K.hash(i, 63) * 3) + i)
      put((0.8 + tw) * (0.7 + amp * 1.2 + hi * 0.8), x, y, 2 + floor(K.hash(i, 64) * 3), 1)
    end

    if kl > 0.05 then K.haze(0, 24, 128, 56, 0.32 * kl, 1, T * 3) end
    K.grain(function(u, v) return u * 128, GY - 6 + v * 6 end, 2 + hi * 12 + e * 3, 2 + hi * 4)
  end

  function M.draw(S)
    local DT = K.DT
    snt = snt * exp(-DT / 0.3)
    snl = K.follow(snl, snt, 0.1, DT)
    clf = clf * exp(-DT / 0.2)
    wob = wob * exp(-DT / 0.7)
    wph = (wph + DT * TAU * 2 / max(0.1, K.beat_sec)) % TAU
    shk = shk * exp(-DT / 0.25)
    fillf = fillf * exp(-DT / 0.8)
    flk = flk * exp(-DT / 0.12)
    mast = mast * exp(-DT / 0.7)
    for k = 0, NR - 1 do clank[k] = clank[k] * exp(-DT / 0.2) end
    for i = #pulses, 1, -1 do if K.T - pulses[i].t0 > 2.5 then table.remove(pulses, i) end end
    if K.view == 2 then draw2(S) else draw1(S) end
  end

  M.init()
  return M
end
