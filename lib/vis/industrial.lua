-- industrial. view 1: a long concrete housing-estate corridor in one-point perspective, fluorescent tubes buzzing over a CRT at the far end.
-- view 2: grinding machinery: interlocking gears that advance a tooth per step, a drive chain, sparks where the teeth meet.
--
-- view 1: we creep down the corridor; doors and tubes slide past. the kick
-- browns the tubes out for a moment (they dip and come back, they don't
-- flash); hats and ticks make single tubes buzz; a ratchet stutters one
-- tube; the snare flares the static on the CRT and throws its glow down
-- the corridor; break slices roll a bar through the picture. energy lights
-- more tubes and widens their pools; chaos kills tubes, doubles the
-- corridor off true and spills the static; kickless, the tubes sink low and
-- the set is the light.
-- view 2: every 16th turns the train on by a tooth (a quick shove, then
-- still); the kick clunks the big gear and lights its hub; snares throw
-- sparks off the mesh, ticks off the small pair; hats glint the chain;
-- metal perc rings the little gear. chaos slips the teeth, breaks some off
-- and ghosts the train; energy speeds the chain and brightens the plate;
-- kickless, the gears free-wheel smooth and the chain sags.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  ---------------------------------------------------------------- view 1
  local VX, VY = 64, 27                 -- the vanishing point
  local FX, FY = 70, 40                 -- focal scale (x, y)
  local YC, YF = -0.68, 0.92            -- ceiling, floor (world y)
  local ZEND = 4.6                      -- the end wall
  local ZCRT = 3.7
  local NT = 6                          -- tubes in view

  ---------------------------------------------------------------- view 2
  -- the gear train: centre, pitch radius, teeth; each meshes the one before
  local GEARS = {
    {x = 42, y = 38, r = 21, n = 16},
    {x = 0, y = 0, r = 12, n = 9, a = -0.55},
    {x = 0, y = 0, r = 8, n = 6, a = 0.75},
    {x = 0, y = 0, r = 14, n = 10, a = 0.3},
  }
  do
    for i = 2, #GEARS do
      local G, P = GEARS[i], GEARS[i - 1]
      local d = P.r + G.r
      G.x, G.y = P.x + math.cos(G.a) * d, P.y + math.sin(G.a) * d
    end
  end
  local CH_Y0, CH_Y1, CH_X0, CH_X1 = 5, 13, 10, 118   -- the chain loop

  local walk, dip, buzz, stut, crt, roll, roll_t, faults
  local TZ, TL, TID = {}, {}, {}
  local turn, clunk, hub, sparks, glint, ring3, slip, chain_off

  function M.init()
    walk, crt, roll, roll_t = 0, 0, 0, -9
    dip, buzz, stut = {}, {}, {}
    for i = 0, 63 do dip[i], buzz[i] = 0, 0 end
    faults = 0
    turn, clunk, hub, sparks, glint, ring3, slip, chain_off = 0, 0, 0, {}, 0, 0, 0, 0
  end
  M.clear = M.init

  -- the tube ids in view, nearest first: id k sits at depth k - walk
  local function tube_z(k) return k - walk end

  local function nearest_tube(off)
    local k = math.floor(walk) + 2 + (off or 0)
    return k % 64
  end

  ---------------------------------------------------------------- events
  local function spark(x, y, n, v, dir)
    for _ = 1, n do
      if #sparks >= 30 then table.remove(sparks, 1) end
      sparks[#sparks + 1] = {x = x, y = y, vx = (K.rnd() - 0.5) * 70 + (dir or 0) * 30,
        vy = -(15 + K.rnd() * 45), t0 = K.T, v = v}
    end
  end

  local function mesh_point(i)
    local G, P = GEARS[i], GEARS[i - 1]
    return P.x + math.cos(G.a) * P.r, P.y + math.sin(G.a) * P.r
  end

  function M.kick(v)
    v = K.num(v, 1)
    for k = 0, 3 do
      local id = nearest_tube(k)
      dip[id] = math.max(dip[id], v * (0.55 - k * 0.1))
    end
    clunk = math.max(clunk, v)
    hub = math.max(hub, v)
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    crt = math.max(crt, v)
    local x, y = mesh_point(2)
    spark(x, y, (n or 1) > 1 and 2 or 4 + math.floor(v * 4), v)
    if K.chaos > 0.5 then slip = math.max(slip, K.chaos) end
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8, 1) end

  function M.hat(v, open)
    local id = nearest_tube(math.floor(K.rnd() * 4))
    buzz[id] = math.max(buzz[id], K.num(v, 1) * (open and 1 or 0.6))
    glint = math.max(glint, K.num(v, 1))
  end

  function M.tick(kind)
    local id = nearest_tube(2 + math.floor(K.rnd() * 3))
    buzz[id] = math.max(buzz[id], 0.8)
    local x, y = mesh_point(3)
    spark(x, y, 2, 0.6)
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 6 or kind == 3 or kind == 4 then ring3 = math.max(ring3, v) end
    M.hat(v * 0.7, false)
  end

  function M.brk(i, n, rev)
    n = clamp(math.floor(K.num(n, 8)), 1, 64)
    i = clamp(math.floor(K.num(i, 1)), 1, n)
    roll, roll_t = (i - 1) / n, K.T
  end

  function M.ratchet(n, voice)
    n = clamp(math.floor(K.num(n, 2)), 1, 16)
    for j = 0, 1 do
      local id = nearest_tube(j * 2 + math.floor(K.rnd() * 2))
      stut[#stut + 1] = {id = id, t0 = K.T, n = n}
      if #stut > 4 then table.remove(stut, 1) end
    end
    crt = math.max(crt, 0.6 + n * 0.04)
    roll, roll_t = K.rnd(), K.T
    slip = math.max(slip, 0.3 + n * 0.04)
    local x, y = mesh_point(2)
    spark(x, y, math.min(8, n), 0.7)
  end

  function M.fill()
    for k = 0, 5 do
      local id = nearest_tube(k)
      dip[id] = math.max(dip[id], 0.7 - k * 0.05)
    end
  end

  ---------------------------------------------------------------- view 1 draw
  local function px(X, z) return VX + X * FX / z end
  local function py(Y, z) return VY + Y * FY / z end

  -- a tube's level (0..~10): its own life (some dead, some failing), the
  -- dips and buzzes laid on it; never more than a few levels a frame
  local function tube_level(id, base)
    local h = K.hash(id, 91)
    local dead = h < 0.08 + K.chaos * 0.3
    local failing = h > 0.82 - K.chaos * 0.2
    local l = base
    if dead then l = 0.6 end
    if failing then
      local w = 0.5 + 0.5 * math.sin(K.T * (2.3 + h * 3) + id) * math.sin(K.T * 0.9 + id * 2)
      l = l * (0.45 + 0.55 * w)
    end
    l = l * (1 - dip[id] * 0.6) * (1 - buzz[id] * 0.25 * (0.5 + 0.5 * math.sin(K.T * 60 + id)))
    for _, St in ipairs(stut) do
      if St.id == id then
        local u = (K.T - St.t0) / (0.1 * St.n)
        if u < 1 then l = l * (0.45 + 0.55 * math.cos(u * St.n * math.pi) ^ 2) end
      end
    end
    return l
  end

  local function draw_corridor(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md = A[K.LO], A[K.HI], A[K.MID]
    local mb = 1 + md * 0.7                -- the body of the mix lifts the concrete
    local kl = K.kickless
    for i = 0, 63 do
      dip[i] = dip[i] * math.exp(-DT / 0.18)
      buzz[i] = buzz[i] * math.exp(-DT / 0.12)
    end
    for i = #stut, 1, -1 do if K.T - stut[i].t0 > 1.7 then table.remove(stut, i) end end
    crt = crt * math.exp(-DT / 0.25)
    walk = (walk + (K.playing and (0.1 + e * 0.12) or 0.05) * K.DTS) % 64

    local base = (4 + e * 4 + lo) * (1 - kl * 0.6)
    local glow = 0.4 + crt * 0.8 + kl * 0.5 + hi * 0.2     -- the CRT's own light

    -- chaos: the corridor knocked off true, a second set of edges
    local sh = c > 0.45 and (c - 0.45) * 14 or 0
    local function edges(l, dx, dy)
      local zn = 0.9
      local xl, xr = px(-1, zn) + dx, px(1, zn) + dx
      local yc, yf = py(YC, zn) + dy, py(YF, zn) + dy
      local el, er = px(-1, ZEND) + dx, px(1, ZEND) + dx
      local ec, ef = py(YC, ZEND) + dy, py(YF, ZEND) + dy
      line(l, xl, yc, el, ec)
      line(l, xr, yc, er, ec)
      line(l, xl, yf, el, ef)
      line(l, xr, yf, er, ef)
      return el, er, ec, ef
    end
    local el, er, ec, ef = edges(2.5 + lo, 0, 0)
    if sh > 0.5 then edges(1 + c * 2, sh * math.sin(T * 0.7), sh * 0.4 * math.cos(T * 0.9)) end

    -- the tubes: where they hang and how lit they are this frame
    local nl = 0
    for k = math.floor(walk) + 1, math.floor(walk) + NT do
      local z = tube_z(k) + 0.55
      if z > 0.85 and z < ZEND - 0.1 then
        nl = nl + 1
        local id = k % 64
        TZ[nl], TID[nl] = z, id
        TL[nl] = tube_level(id, base) * clamp((z - 0.85) / 0.5, 0, 1)
      end
    end
    -- light at depth z: the tubes' pools, the set's glow toward the end
    local function light(z)
      local L = 0
      for i = 1, nl do
        local d = z - TZ[i]
        L = L + TL[i] * math.exp(-d * d * 9)
      end
      local g = z - ZCRT
      return L * 0.22 + glow * 1.5 * math.exp(-g * g * 2)
    end

    -- the surfaces: concrete walls in strips, the lino and the ceiling in
    -- rows, every one lit by the tubes above it
    for x = 1, math.floor(el) - 1, 4 do
      local z = FX / (VX - x)
      local l = math.min(4, light(z) * 1.1 * clamp((z - 1) / 0.8, 0.35, 1))
      if l > 0.6 then
        l = math.min(5.5, l * mb)
        line(l, x, py(YC, z) + 1, x, py(YF, z) - 1)
        line(l, 127 - x, py(YC, z) + 1, 127 - x, py(YF, z) - 1)
      end
    end
    for y = math.floor(ef) + 2, 63, 2 do
      if y > 52 then y = y + (y % 4 == 0 and 1 or 0) end
      local z = FY * YF / (y - VY)
      local hw = FX / z
      local l = math.min(5, light(z) * 1.1)
      if l > 0.6 then put(math.min(6.5, l * mb), VX - hw * 0.8, y, hw * 1.6, 1) end
    end
    for y = 1, math.floor(ec) - 1, 3 do
      local z = FY * YC / (y - VY)
      local hw = FX / z
      local l = math.min(3, light(z) * 0.6)
      if l > 0.6 then put(math.min(4, l * mb), VX - hw, y, hw * 2, 1) end
    end

    -- the end wall: dim, lit by the set
    for y = math.floor(ec) + 1, math.floor(ef) - 1, 2 do
      put(1 + glow * 1.2, el + 1, y, er - el - 1, 1)
    end
    line(2, el, ec, er, ec)
    line(2, el, ec, el, ef)
    line(2, er, ec, er, ef)

    -- the walls: concrete panels with doors, sliding past as we walk
    for k = math.floor(walk), math.floor(walk) + 5 do
      local z0 = k + 0.15 - walk
      if z0 > 0.75 and z0 < ZEND then
        local fade = clamp((z0 - 0.75) / 0.6, 0, 1)
        for side = -1, 1, 2 do
          -- the panel joint
          local x = px(side, z0)
          line((1.5 + e * 0.5) * fade, x, py(YC, z0), x, py(YF, z0))
          -- a door in the bay: its frame on the wall
          local zd0, zd1 = z0 + 0.3, z0 + 0.62
          if zd1 < ZEND then
            local xa, xb = px(side, zd0), px(side, zd1)
            local ta, tb = py(-0.25, zd0), py(-0.25, zd1)
            local fa, fb = py(YF, zd0), py(YF, zd1)
            local dl = (2.5 + lo * 0.8) * fade
            line(dl, xa, ta, xb, tb)
            line(dl, xa, ta, xa, fa)
            line(dl, xb, tb, xb, fb)
            -- the number plate and the handle
            local hk = K.hash(k * 2 + (side + 1) // 2, 93)
            put((2 + hi * 2) * fade, (xa + xb) / 2 - 1, (ta + tb) / 2 + 2, 2, 1)
            put((1.5 + hk * 2) * fade, xb - side * 1.5, (tb + fb) / 2, 1, 2)
          end
        end
      end
    end

    -- the ceiling tubes: a bright bar with a lit diffuser under it
    for i = 1, nl do
      local z, l = TZ[i], TL[i]
      local y = py(YC, z) + 1
      local hw = 0.34 * FX / z
      -- the air (hi): the tubes sing, their diffusers shimmer
      local sing = hi * (0.6 + 0.4 * math.sin(T * 11 + TID[i] * 1.7))
      line(math.min(12, 1 + l + sing * 4), VX - hw, y, VX + hw, y)
      if z < 2.4 then
        line(math.min(9, l * 0.55 + sing * 3.5), VX - hw, y + 1, VX + hw, y + 1)
        put(math.min(5, l * 0.3 + sing * 2.5), VX - hw - 2, y - 1, hw * 2 + 4, 1)
      end
    end

    -- the set at the end: on a crate, its static flaring on the snare
    local cx0, cx1 = px(-0.5, ZCRT), px(0.5, ZCRT)
    local cy0, cy1 = py(-0.3, ZCRT), py(0.55, ZCRT)
    local sx0, sx1, sy0, sy1 = cx0 + 2, cx1 - 2, cy0 + 2, cy1 - 2
    line(4, cx0, cy0, cx1, cy0)
    line(4, cx0, cy1, cx1, cy1)
    line(4, cx0, cy0, cx0, cy1)
    line(4, cx1, cy0, cx1, cy1)
    put(2, cx0 + 1, cy1 + 1, cx1 - cx0 - 1, py(YF, ZCRT) - cy1 - 1)
    -- the static: a field of points re-dealt a dozen times a second
    local fr = math.floor(T * 12)
    local sw, shh = sx1 - sx0, sy1 - sy0
    local np = math.floor(10 + crt * 22 + kl * 8 + c * 6 + hi * 18)   -- the hiss is the air (hi)
    for i = 1, np do
      local x = sx0 + math.floor(K.hash(i + fr * 61, 95) * sw)
      local y = sy0 + math.floor(K.hash(i + fr * 61, 96) * shh)
      put(math.min(12, 3 + K.hash(i, 97) * 4 + crt * 5), x, y, 1 + (i % 3 == 0 and 1 or 0), 1)
    end
    put(1.5 + glow, sx0, sy0, sw, shh)
    -- the rolling bar: where the break is
    if K.T - roll_t < 3 then
      local ry = sy0 + roll * shh
      put(math.min(10, 4 + 4 * math.exp(-(K.T - roll_t) / 0.3)), sx0, ry, sw, 1)
    end
    -- its glow, down the floor toward us
    local gl = crt * 3 + kl * 1.5 + 0.5
    for r = 1, 6 do
      local y = py(YF, ZCRT) + r * 2
      local w = (sw + r * 6) * 0.5
      if gl * (1 - r / 7) > 0.6 then put(gl * (1 - r / 7), VX - w, y, w * 2, 1) end
    end
    -- chaos: static spilling out of the set along the corridor
    if c > 0.4 then
      for i = 1, math.floor((c - 0.4) * 20) do
        local a = K.hash(i + fr * 7, 98) * K.TAU
        local d = 8 + K.hash(i + fr * 7, 99) * 30 * c
        put(2 + crt * 4, VX + math.cos(a) * d * 1.6, (sy0 + sy1) / 2 + math.sin(a) * d * 0.6, 2, 1)
      end
    end

    -- dust in the corridor, a little haze at the far end
    K.haze(math.floor(el) - 10, math.floor(ec) - 4, math.floor(er) + 11, math.floor(ef) + 6, 0.25 + e * 0.2, 1, T * 3)
    K.grain(function(u, v) return 30 + u * 68, 8 + v * 40 end, 2 + hi * 10, 3 + hi * 3)
  end

  ---------------------------------------------------------------- view 2 draw
  -- gear outline: n teeth, pitch r, rotated by a; chaos breaks teeth off
  local function gear(l, G, a, broken)
    local n = G.n
    local rr, rt = G.r - 2, G.r + 2
    local step = K.TAU / n
    local pxx, pyy
    for k = 0, n - 1 do
      local a0 = a + k * step
      local pts
      if broken and K.hash(k + G.n * 7, 103) < broken then
        pts = {{a0, rr}, {a0 + step, rr}}
      else
        pts = {{a0, rr}, {a0 + step * 0.18, rt}, {a0 + step * 0.5, rt}, {a0 + step * 0.68, rr}, {a0 + step, rr}}
      end
      for _, p in ipairs(pts) do
        local x, y = G.x + math.cos(p[1]) * p[2], G.y + math.sin(p[1]) * p[2]
        if pxx then line(l, pxx, pyy, x, y) end
        pxx, pyy = x, y
      end
    end
  end

  local function draw_gears(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md = A[K.LO], A[K.HI], A[K.MID]
    local kl = K.kickless
    clunk = clunk * math.exp(-DT / 0.12)
    hub = hub * math.exp(-DT / 0.25)
    glint = glint * math.exp(-DT / 0.1)
    ring3 = ring3 * math.exp(-DT / 0.3)
    slip = slip * math.exp(-DT / 0.3)

    -- the drive: a tooth per 16th, shoved on fast then held; kickless (or
    -- stopped) it free-wheels smoothly
    local sf = K.stepf
    local whole = math.floor(sf)
    local u = sf - whole
    local stepped = whole + K.ease(math.min(1, u * 4))
    local smooth = sf
    local pos = stepped + (smooth - stepped) * kl
    turn = pos + T * 0.15 + clunk * 0.15
    local a1 = turn * K.TAU / GEARS[1].n
    if c > 0.3 then a1 = a1 + (K.hash(math.floor(T * 6), 101) - 0.5) * slip * 0.12 end

    -- the back plate: riveted panels, dim, lit a little by the energy
    local pl = 1 + e * 0.6 + md * 1.2
    for k = 0, 3 do
      local x0 = k * 32
      line(pl, x0, 0, x0, 63)
      for y = 4, 60, 8 do put(pl + 0.5, x0 + 2, y, 1, 1) end
      put(1, x0 + 4, 30, 24, 1)
    end
    -- a pipe running across behind, with a gauge on it
    line(2 + lo, 0, 58, 22, 58)
    line(2 + lo, 0, 61, 22, 61)
    K.ring(2.5, 12, 52, 4, 10)
    line(4, 12, 52, 12 + math.cos(-1 - e * 2) * 3, 52 + math.sin(-1 - e * 2) * 3)

    -- the chain over the top, its links running; kickless, it sags
    local cs = (K.playing and (6 + e * 14) or 2) * (1 + kl * 0.2)
    chain_off = (chain_off + cs * K.DTS) % 6
    local sag = kl * 3 + (1 - e) * 1
    K.ring(3, CH_X0, (CH_Y0 + CH_Y1) / 2, (CH_Y1 - CH_Y0) / 2 + 1, 8, math.pi * 0.5, math.pi * 1.5)
    K.ring(3, CH_X1, (CH_Y0 + CH_Y1) / 2, (CH_Y1 - CH_Y0) / 2 + 1, 8, -math.pi * 0.5, math.pi * 0.5)
    -- the air (hi) glints along the links
    K.dashes(2 + glint * 3 + hi * 2.5, CH_Y0, 4, 6, chain_off, CH_X0, CH_X1)
    K.dashes(1.2 + glint * 2 + hi * 1.5, CH_Y0 + 1, 2, 6, chain_off + 1, CH_X0, CH_X1)
    local mid = math.floor(CH_Y1 + sag)
    K.dashes(2 + hi * 2.5, mid, 4, 6, -chain_off, CH_X0, CH_X1)
    K.dashes(1.2 + hi * 1.5, mid - 1, 2, 6, -chain_off + 1, CH_X0, CH_X1)
    K.disc(1.5, CH_X0, (CH_Y0 + CH_Y1) / 2, 3)
    K.disc(1.5, CH_X1, (CH_Y0 + CH_Y1) / 2, 3)

    -- the gears: bodies dim, outlines bright; each turns against the last
    local broken = c > 0.55 and (c - 0.55) * 0.5 or nil
    local ang = {a1}
    for i = 2, #GEARS do
      local G, P = GEARS[i], GEARS[i - 1]
      -- mesh: the angle at the contact flips sign and scales by the ratio
      ang[i] = -(ang[i - 1] - G.a) * P.n / G.n + G.a + math.pi + math.pi / G.n
    end
    for i, G in ipairs(GEARS) do
      local a = ang[i]
      -- the bodies warm with the load (mid)
      local body = 1 + md * (1.1 + 0.3 * math.sin(T * 1.3 + i))
      K.disc(body, G.x, G.y, G.r - 2)
      local gl = 2.5 + lo + e * 0.5 + (i == 3 and ring3 * 2 or 0)
      gear(gl, G, a, broken)
      -- spokes and hub
      local ns = (i == 1 or i == 4) and 5 or (i == 2 and 4 or 3)
      for k = 0, ns - 1 do
        local sa = a + k * K.TAU / ns
        line(math.max(1.5 + lo * 0.5, body + 1.2), G.x + math.cos(sa) * 3, G.y + math.sin(sa) * 3,
          G.x + math.cos(sa) * (G.r - 3), G.y + math.sin(sa) * (G.r - 3))
      end
      K.ring(2.5, G.x, G.y, G.r - 3, 16)
      local hl = 3 + lo * 2 + (i == 1 and hub * 7 or 0) + (i == 3 and ring3 * 6 or 0)
      K.disc(hl, G.x, G.y, (i == 1 or i == 4) and 3 or 2)
    end
    -- chaos: a ghost train, slipped a tooth
    if c > 0.45 then
      local G = GEARS[1]
      local ghost = {x = G.x + 6 * math.sin(T * 0.5), y = G.y - 3, r = G.r, n = G.n}
      gear(1 + (c - 0.45) * 3, ghost, a1 - K.TAU / G.n * (1 + slip * 2), nil)
    end

    -- sparks off the mesh, falling
    for i = #sparks, 1, -1 do
      local P = sparks[i]
      local age = K.T - P.t0
      local u = age / 0.7
      local x = P.x + P.vx * age
      local y = P.y + P.vy * age + 80 * age * age
      if u >= 1 or y > 63 then table.remove(sparks, i)
      else
        local vx, vy = P.vx, P.vy + 160 * age
        local m = math.sqrt(vx * vx + vy * vy) + 0.01
        line((4 + 6 * P.v) * (1 - u) + hi, x - vx / m * 2.5, y - vy / m * 2.5, x, y)
      end
    end
    -- the contact points glow under load
    for i = 2, #GEARS do
      local x, y = mesh_point(i)
      put(2 + clunk * 4 + K.env.snare * 4, x - 1, y - 1, 2, 2)
    end

    K.grain(function(u, v) return u * 128, 20 + v * 44 end, 3 + e * 6 + hi * 8, 3 + hi * 3)
  end

  function M.draw(S)
    if K.view == 2 then draw_gears(S) else draw_corridor(S) end
  end

  M.init()
  return M
end
