-- industrial. view 1: a long concrete housing-estate corridor in one-point
-- perspective, fluorescent tubes buzzing over a CRT at the far end; view 2:
-- grinding machinery, interlocking gears that advance a tooth per step under
-- a drive chain, sparks where the teeth meet; view 3: a drop forge at night,
-- a press stamping a white-hot billet between the furnace and the conveyor.
--
-- view 1: we creep down the corridor; doors and tubes slide past and their
-- light shines back off the lino. the kick browns the tubes out for a moment
-- (they dip and come back, they don't flash); closed hats and ticks make
-- single tubes buzz, an open hat sends one tube into its starter flicker; a
-- ratchet stutters one tube; the snare flares the static on the CRT and
-- throws its glow down the corridor, a clap slams a door; toms and congas
-- knock on a door, bells and metal clank a glint down the pipe along the
-- ceiling; break slices roll a bar through the picture. every bar a door
-- opens a crack and spills its light on the floor, and over the phrase the
-- CRT tunes in from static toward a test card. energy lights more tubes and
-- widens their pools; chaos kills tubes, doubles the corridor off true and
-- spills the static; kickless, the tubes sink low and the set is the light.
-- view 2: every 16th turns the train on by a tooth (a quick shove, then
-- still); big dim gears turn behind it. the kick clunks the big gear and
-- lights its hub; snares throw sparks off the mesh, ticks off the small
-- pair; closed hats glint the chain, open hats and claps blow steam from the
-- vent; metal perc rings the little gear, toms thump the far gear's hub. the
-- gauge climbs through the phrase and the warning lamp warms as it tops
-- out. chaos slips the teeth, breaks some off and ghosts the train; energy
-- speeds the chain and brightens the plate; kickless, the gears free-wheel
-- smooth and the chain sags.
-- view 3: the kick drops the ram onto the billet and scale bursts off it;
-- each bar a new billet comes under the press and the stamped plate rides
-- the conveyor away, cooling. the snare showers slag sparks, claps a puff of
-- steam off the valve; closed hats glint the crane's chain, open hats hiss
-- steam; bells and metal swing the hammer down on the side anvil; toms and
-- congas make the furnace roar; a ratchet stutters the ram; a fill throws
-- the furnace door open. the warning beacon on the crown sweeps the back
-- wall once a bar and the furnace heats through the phrase. energy speeds
-- the belt and heats the steel, chaos knocks the ram and the columns out of
-- true and scatters the sparks; kickless the ram waits up top, the billet
-- cools and steam drifts.
--
-- the ears: the lows warm the edges, the hubs, the billet and the furnace;
-- the mids lift the concrete, the gear bodies and the back wall; the highs
-- make the tubes sing, hiss in the static and glint on the chain, the
-- sparks and the steam; the level lights the tubes and the beacon.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, exp = math.sin, math.cos, math.floor, math.max, math.min,
    math.abs, math.exp

  -- a long line in short pieces, so a glitch tears only the rows it holds
  local function seg(l, x0, y0, x1, y1)
    local n = max(1, floor(max(abs(x1 - x0), abs(y1 - y0)) / 8))
    local px, py = x0, y0
    for k = 1, n do
      local nx, ny = x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n
      line(l, px, py, nx, ny)
      px, py = nx, ny
    end
  end

  local function phrase(S)
    local pl = K.num(S.phrase_len, 16)
    if not (pl >= 1 and pl < 1e4) then pl = 16 end
    local pp = K.num(S.phrase_pos, 0)
    if not (pp >= 0 and pp < 1e4) then pp = 0 end
    return clamp((pp + K.bar_ph) / pl, 0, 1)
  end

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
  local flick, slam, knock, ajar, pipe_g          -- view 1
  local steam, thump, back_rot                     -- view 2
  local ram_t0, ram_n, billet, plates, roar, door, hammer, hiss, crane_a, crane_v, belt  -- view 3
  local sm_tube                                    -- eased tube base

  function M.init()
    walk, crt, roll, roll_t = 0, 0, 0, -9
    dip, buzz, stut = {}, {}, {}
    for i = 0, 63 do dip[i], buzz[i] = 0, 0 end
    faults = 0
    turn, clunk, hub, sparks, glint, ring3, slip, chain_off = 0, 0, 0, {}, 0, 0, 0, 0
    flick, slam, knock, ajar, pipe_g = {}, {}, {}, {}, {}
    steam, thump, back_rot = {}, 0, 0
    ram_t0, ram_n, billet, plates, roar, door, hammer, hiss = -9, 1, 1, {}, 0, 0, 0, 0
    crane_a, crane_v, belt = 0.2, 0, 0
    sm_tube = 4
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

  local function puff(x, y, v, dir)
    if #steam >= 10 then table.remove(steam, 1) end
    steam[#steam + 1] = {x = x, y = y, t0 = K.T, v = v, dir = dir or 1}
  end

  function M.kick(v)
    v = K.num(v, 1)
    if K.T - ram_t0 > 0.12 then ram_t0, ram_n = K.T, 1 end
    billet = math.max(0.35, billet - 0.08 * v)
    if K.view == 3 then
      for _ = 1, 3 + math.floor(v * 3 + K.energy * 3) do
        if #sparks >= 30 then table.remove(sparks, 1) end
        local dir = K.rnd() < 0.5 and -1 or 1
        sparks[#sparks + 1] = {x = 64 + dir * 8, y = 44, vx = dir * (20 + K.rnd() * 50), vy = -(10 + K.rnd() * 35), t0 = K.T, v = v}
      end
    end
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
    if K.view == 3 then x, y = 64, 42 end
    spark(x, y, (n or 1) > 1 and 2 or 4 + math.floor(v * 4), v)
    if K.chaos > 0.5 then slip = math.max(slip, K.chaos) end
  end
  function M.clap(v)
    v = K.num(v, 1)
    crt = math.max(crt, 0.5 * v)
    if #slam >= 3 then table.remove(slam, 1) end
    slam[#slam + 1] = {k = math.floor(walk) + 1 + math.floor(K.rnd() * 3), side = K.rnd() < 0.5 and -1 or 1, t0 = K.T, v = v}
    for k = 0, 2 do
      local id = nearest_tube(k)
      dip[id] = math.max(dip[id], v * 0.2)
    end
    puff(K.view == 3 and 88 or 22, K.view == 3 and 8 or 56, v)
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    local id = nearest_tube(math.floor(K.rnd() * 4))
    if open then
      if #flick >= 3 then table.remove(flick, 1) end
      flick[#flick + 1] = {id = id, t0 = K.T}
      hiss = math.max(hiss, v)
      puff(K.view == 3 and 88 or 22, K.view == 3 and 8 or 56, v * 0.8)
    else
      buzz[id] = math.max(buzz[id], v * 0.6)
      glint = math.max(glint, v)
    end
  end

  function M.tick(kind)
    local id = nearest_tube(2 + math.floor(K.rnd() * 3))
    buzz[id] = math.max(buzz[id], 0.8)
    local x, y = mesh_point(3)
    spark(x, y, 2, 0.6)
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    kind = math.floor(K.num(kind, 1))
    if kind == 6 or kind == 3 or kind == 4 or kind == 10 or kind == 21 then
      ring3 = math.max(ring3, v)
      hammer = math.max(hammer, v)
      if #pipe_g >= 4 then table.remove(pipe_g, 1) end
      pipe_g[#pipe_g + 1] = {t0 = K.T, v = v}
    elseif kind == 1 or kind == 2 or kind == 7 or kind == 13 or kind == 17 or kind == 18 then
      M.tom(v)
    else
      local id = nearest_tube(math.floor(K.rnd() * 4))
      buzz[id] = math.max(buzz[id], v * 0.5)
      glint = math.max(glint, v * 0.7)
    end
  end

  function M.tom(v)
    v = K.num(v, 1)
    thump = math.max(thump, v)
    roar = math.max(roar, v)
    if #knock >= 3 then table.remove(knock, 1) end
    knock[#knock + 1] = {k = math.floor(walk) + 1 + math.floor(K.rnd() * 3), side = K.rnd() < 0.5 and -1 or 1, t0 = K.T, v = v}
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
    if K.view == 3 then x, y = 64, 42 end
    spark(x, y, math.min(8, n), 0.7)
    ram_t0, ram_n = K.T, n
  end

  function M.fill()
    for k = 0, 5 do
      local id = nearest_tube(k)
      dip[id] = math.max(dip[id], 0.7 - k * 0.05)
    end
    door = 1
    slip = math.max(slip, 0.4)
  end

  function M.bar()
    -- a door opens a crack somewhere ahead and stays ajar a while
    local k = math.floor(walk) + 1 + math.floor(K.rnd() * 4)
    ajar[#ajar + 1] = {k = k, side = K.rnd() < 0.5 and -1 or 1, t0 = K.T}
    if #ajar > 4 then table.remove(ajar, 1) end
    -- the press: a fresh billet, the stamped one rides away
    if #plates >= 5 then table.remove(plates, 1) end
    plates[#plates + 1] = {t0 = K.T, h = billet}
    billet = 1
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
    for _, Fl in ipairs(flick) do
      if Fl.id == id then
        local u = (K.T - Fl.t0) / 0.6
        if u < 1 then l = l * (0.25 + 0.75 * K.ease(u) * (0.75 + 0.25 * math.cos(u * 9))) end
      end
    end
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

    sm_tube = K.follow(sm_tube, (3.6 + e * 4 + lo + A[K.AMP] * 1.2) * (1 - kl * 0.6), 0.12, DT)
    local base = sm_tube
    local ph = phrase(S)
    for i = #flick, 1, -1 do if K.T - flick[i].t0 > 0.6 then table.remove(flick, i) end end
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
        seg(l, x, py(YC, z) + 1, x, py(YF, z) - 1)
        seg(l, 127 - x, py(YC, z) + 1, 127 - x, py(YF, z) - 1)
      end
    end
    for y = math.floor(ef) + 2, 63, 2 do
      if y > 52 then y = y + (y % 4 == 0 and 1 or 0) end
      local z = FY * YF / (y - VY)
      local hw = FX / z
      local l = math.min(5, light(z) * 1.1)
      if l > 0.8 then put(math.min(6.5, l * mb), VX - hw * 0.65, y, hw * 1.3, 1) end
    end
    for y = 1, math.floor(ec) - 1, 3 do
      local z = FY * YC / (y - VY)
      local hw = FX / z
      local l = math.min(3, light(z) * 0.6)
      if l > 0.8 then put(math.min(4, l * mb), VX - hw * 0.8, y, hw * 1.6, 1) end
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
            local sd = (side + 1) // 2
            for _, Kn in ipairs(knock) do
              if Kn.k == k and (Kn.side + 1) // 2 == sd then
                dl = dl + Kn.v * 6 * math.max(0, 1 - (K.T - Kn.t0) / 0.35) * fade
              end
            end
            local sl_open = 0
            for _, Sl in ipairs(slam) do
              if Sl.k == k and (Sl.side + 1) // 2 == sd then
                local u = (K.T - Sl.t0) / 0.3
                if u < 1 then sl_open = math.max(sl_open, Sl.v * (1 - u)); dl = dl + Sl.v * 5 * (1 - u) * fade end
              end
            end
            local aj = 0
            for _, Aj in ipairs(ajar) do
              if Aj.k == k and (Aj.side + 1) // 2 == sd then
                aj = math.max(aj, clamp((K.T - Aj.t0) / 0.6, 0, 1) * clamp((8 - (K.T - Aj.t0)) / 2, 0, 1))
              end
            end
            aj = math.max(aj, sl_open)
            line(dl, xa, ta, xb, tb)
            seg(dl, xa, ta, xa, fa)
            seg(dl, xb, tb, xb, fb)
            -- a door ajar: a sliver of light in the gap and a wedge on the lino
            if aj > 0.05 then
              local la = (2 + aj * 4 + md * 1.5) * fade
              seg(la, xa + side * -1, ta + 1, xa + side * -1, fa - 1)
              local xm, ym = xa, fa + 1
              for q = 0, 3 do
                local w = (3 + q * 4) * aj
                line(la * (1 - q * 0.2), xm - side * q * 2, ym + q, xm - side * (q * 2 + w), ym + q)
              end
            end
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

    -- the tubes shine back off the lino
    for i = 1, nl do
      local z, l = TZ[i], TL[i]
      if z < 3.2 then
        local y = py(YF, z) - 1
        local hw = 0.22 * FX / z
        put(math.min(5, l * 0.3), VX - hw, y, hw * 2, 1)
      end
    end
    -- the pipe along the ceiling's corner: bells and metal clank a glint down it
    do
      local x0, y0 = px(-0.88, 0.9), py(YC + 0.07, 0.9)
      local x1, y1 = px(-0.88, ZEND), py(YC + 0.07, ZEND)
      seg(1.5 + md * 1.2, x0, y0, x1, y1)
      for i = #pipe_g, 1, -1 do
        local G = pipe_g[i]
        local u = (K.T - G.t0) / 0.8
        if u >= 1 then table.remove(pipe_g, i)
        else
          local z = 0.95 + u * (ZEND - 1)
          local gx, gy = px(-0.88, z), py(YC + 0.07, z)
          put((4 + G.v * 6) * (1 - u * 0.7), gx - 1, gy, 3, 1)
        end
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
    -- over the phrase the set tunes in: a test card's bars come up under the static
    if ph > 0.15 then
      local tl = (ph - 0.15) / 0.85
      for b = 0, 5 do
        local bl = (2 + (5 - b) * 0.9) * tl * (1 - crt * 0.6)
        if bl >= 0.6 then put(bl, sx0 + b * sw / 6, sy0 + 1, sw / 6, shh - 2) end
      end
    end
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
    local amp = A[K.AMP]
    local ph = phrase(S)
    thump = thump * math.exp(-DT / 0.25)
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
    -- big dim gears behind, turning slow the other way
    back_rot = back_rot + (0.05 + e * 0.08 + md * 0.05) * K.DTS * (1 - kl * 0.5)
    for b = 0, 1 do
      local bx, by, br, bn = b == 0 and 100 or 8, b == 0 and 6 or 20, b == 0 and 30 or 22, b == 0 and 20 or 14
      local a0 = (b == 0 and -1 or 1) * back_rot * 2 * math.pi / bn * 3
      for k = 0, bn - 1 do
        local a = a0 + k * 2 * math.pi / bn
        local ca, sa = math.cos(a), math.sin(a)
        line(1, bx + ca * (br - 2), by + sa * (br - 2), bx + ca * (br + 2), by + sa * (br + 2))
      end
      K.ring(1, bx, by, br - 2, 24)
    end
    -- a pipe running across behind, with a gauge on it: the pressure climbs
    -- through the phrase, the lamp warms as it tops out
    line(2 + lo, 0, 58, 22, 58)
    line(2 + lo, 0, 61, 22, 61)
    K.ring(2.5, 12, 52, 4, 10)
    local ga = -2.7 + ph * 2.4 + lo * 0.3 + math.sin(K.T * 7) * 0.04 * (1 + e)
    line(4 + amp * 2, 12, 52, 12 + math.cos(ga) * 3, 52 + math.sin(ga) * 3)
    put(1.5 + math.max(0, ph - 0.75) * 24 + amp, 19, 47, 2, 2)
    -- the vent at the pipe's end: open hats and claps blow steam; kickless it leaks
    if kl > 0.3 and K.hash(math.floor(K.T * 2), 141) < kl * 0.5 and #steam < 10
      and (#steam == 0 or K.T - steam[#steam].t0 > 0.4) then
      steam[#steam + 1] = {x = 22, y = 56, t0 = K.T, v = 0.4, dir = 1}
    end
    for i = #steam, 1, -1 do
      local P = steam[i]
      local u = (K.T - P.t0) / 1.4
      if u >= 1 then table.remove(steam, i)
      else
        local r = 1.5 + u * 7
        K.ring((2 + P.v * 3 + hi * 2) * (1 - u), P.x + u * 10 * P.dir, P.y - u * 22, r, 8, 0, 2 * math.pi, 0.7)
      end
    end

    -- the chain over the top, its links running; kickless, it sags
    local cs = (K.playing and (6 + e * 14) or 2) * (1 + kl * 0.2)
    chain_off = (chain_off + cs * K.DTS) % 6
    local sag = kl * 3 + (1 - e) * 1
    K.ring(3, CH_X0, (CH_Y0 + CH_Y1) / 2, (CH_Y1 - CH_Y0) / 2 + 1, 8, math.pi * 0.5, math.pi * 1.5)
    K.ring(3, CH_X1, (CH_Y0 + CH_Y1) / 2, (CH_Y1 - CH_Y0) / 2 + 1, 8, -math.pi * 0.5, math.pi * 0.5)
    -- the air (hi) glints along the links
    K.dashes(2 + glint * 2.5 + hi * 1.2, CH_Y0, 4, 6, chain_off, CH_X0, CH_X1)
    K.dashes(1 + glint * 1.5 + hi * 0.8, CH_Y0 + 1, 2, 6, chain_off + 1, CH_X0, CH_X1)
    local mid = math.floor(CH_Y1 + sag)
    K.dashes(2 + hi * 1.2, mid, 4, 6, -chain_off, CH_X0, CH_X1)
    K.dashes(1 + hi * 0.8, mid - 1, 2, 6, -chain_off + 1, CH_X0, CH_X1)
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
      -- the body: a dark web inside the rim
      K.disc(body, G.x, G.y, G.r - 4)
      local gl = 2.2 + lo * 0.7 + e * 0.4 + (i == 3 and ring3 * 2 or 0)
      gear(gl, G, a, broken)
      -- spokes and hub
      local ns = (i == 1 or i == 4) and 5 or (i == 2 and 4 or 3)
      for k = 0, ns - 1 do
        local sa = a + k * K.TAU / ns
        line(math.max(1.5 + lo * 0.5, body + 1.2), G.x + math.cos(sa) * 3, G.y + math.sin(sa) * 3,
          G.x + math.cos(sa) * (G.r - 3), G.y + math.sin(sa) * (G.r - 3))
      end
      K.ring(1.8, G.x, G.y, G.r - 3, 16)
      local hl = 3 + lo * 2 + (i == 1 and hub * 7 or 0) + (i == 3 and ring3 * 6 or 0) + (i == 4 and thump * 6 or 0)
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

  ---------------------------------------------------------------- view 3 draw
  local PX0, PX1 = 44, 84               -- the press: crown and columns
  local RAM0, RAM1 = 53, 75             -- the ram's width
  local UP, DOWN = 20, 38               -- the ram's bottom, raised / on the billet
  local BED = 48                        -- the bed's top
  local BELT = 56                       -- the conveyor's top
  local FX0, FX1, FY0 = 5, 27, 26       -- the furnace

  -- where the ram's bottom is now: a fast drop, a hold, a slower lift
  local function ram_y()
    local age = (K.T - ram_t0)
    local n = math.max(1, ram_n)
    local per = n > 1 and 0.07 or 0.5
    if n > 1 then
      local k = math.floor(age / per)
      if k < n then age = age - k * per end
    end
    local down = DOWN + (1 - billet) * 4
    local lift = UP + K.kickless * -2
    if age < 0 then return lift end
    if age < 0.05 then return lift + (down - lift) * K.ease(age / 0.05) end
    if age < 0.09 then return down end
    local u = clamp((age - 0.09) / (n > 1 and 0.03 or 0.4), 0, 1)
    return down + (lift - down) * K.ease(u)
  end

  local function draw_press(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    local ph = phrase(S)
    roar = roar * math.exp(-DT / 0.35)
    door = door * math.exp(-DT / 1.2)
    hammer = hammer * math.exp(-DT / 0.25)
    hiss = hiss * math.exp(-DT / 0.4)
    glint = glint * math.exp(-DT / 0.12)

    -- the hall: steel columns and a roof beam in the dark, the beacon's beam
    -- sweeping the back wall once a bar
    local bw = 1 + md * 1.2
    for _, x in ipairs({3, 34, 94, 124}) do
      seg(bw, x, 4, x, BELT - 1)
      seg(bw * 0.7, x + 2, 4, x + 2, BELT - 1)
    end
    line(1 + md * 0.6, 0, 3, 127, 3)
    for x = 6, 122, 12 do line(bw * 0.7, x, 3, x + 6, 0) end
    local ba = K.bar_ph * 2 * math.pi
    local bc = 64 + math.sin(ba) * 70
    local face = math.cos(ba)
    if face > -0.2 then
      local bl = math.min(2.2, 1 + amp * 0.8 + md * 0.6) * clamp(face + 0.2, 0, 1)
      for dx = -9, 9 do
        local x = math.floor(bc + dx)
        local l = bl * (1 - math.abs(dx + bc - math.floor(bc)) / 10)
        if l >= 0.6 and (x < PX0 - 1 or x > PX1 + 1) then seg(l, x, 14, x, 46) end
      end
    end

    -- the furnace: brick mouth, the fire inside; the lows and the phrase heat
    -- it, toms make it roar, a fill throws the door open
    local heat = 0.4 + ph * 0.4 + lo * 0.5 + roar * 0.9 + e * 0.3 + amp * 0.3
    line(2, FX0, FY0, FX1, FY0)
    seg(2, FX0, FY0, FX0, BELT - 1)
    seg(2, FX1, FY0, FX1, BELT - 1)
    for y = FY0 + 3, BELT - 2, 4 do
      for x = FX0 + 2 + ((y // 4) % 2) * 3, FX1 - 3, 6 do put(1, x, y, 3, 1) end
    end
    local mo = 9 + math.floor(door * 6)         -- the mouth's height
    local my1 = BELT - 5
    local my0 = my1 - mo
    for y = my0, my1 - 1 do
      local u = (y - my0) / mo
      local fl = math.sin(T * 7 + y * 0.9) * 0.6 + math.sin(T * 3.1 - y * 0.4) * 0.5
      put(math.min(11, (2 + heat * 5) * (0.55 + 0.45 * u) + fl), FX0 + 4, y, FX1 - FX0 - 8, 1)
    end
    -- flames lick up out of the mouth when it roars
    if roar > 0.1 or door > 0.2 then
      for k = 0, 3 do
        local x = FX0 + 6 + k * 4
        local h = (roar + door * 0.6) * (4 + 4 * K.hash(k + math.floor(T * 8), 151))
        seg((3 + roar * 6) * (0.6 + 0.4 * math.sin(T * 9 + k)), x, my0 - 1, x + math.sin(T * 5 + k) * 1.5, my0 - 1 - h)
      end
    end
    put(1.5 + heat, FX0 + 2, my0 - 2, FX1 - FX0 - 4, 1)

    -- the crane: a trolley on the rail, the chain and hook swinging
    crane_v = crane_v + (-crane_a * 6 - crane_v * 0.5) * DT + math.sin(T * 0.4) * 0.06 * DT
    crane_a = clamp(crane_a + crane_v * DT, -0.8, 0.8)
    local cx = 30 + math.sin(T * 0.07) * 6
    line(2, 0, 7, 40, 7)
    put(2.5, cx - 3, 6, 7, 2)
    local hx, hy = cx + math.sin(crane_a) * 18, 8 + math.cos(crane_a) * 18
    for k = 0, 8 do
      local u0, u1 = k / 9, (k + 0.6) / 9
      local gl = (K.hash(k, math.floor(T * 6)) < glint * 0.8) and 6 or 0
      line(1.5 + hi * 2 + gl, cx + (hx - cx) * u0, 8 + (hy - 8) * u0, cx + (hx - cx) * u1, 8 + (hy - 8) * u1)
    end
    K.ring(2 + hi, hx, hy + 2, 2, 6, -0.5, math.pi + 0.5)

    -- the press: crown, columns and bed; chaos knocks it out of true
    local lean = c > 0.4 and (c - 0.4) * 5 * math.sin(T * 0.6) or 0
    local edge = 2 + lo * 0.8 + md * 0.5
    put(1, PX0, 4, PX1 - PX0, 8)
    line(edge + 0.5, PX0, 4, PX1, 4)
    line(edge, PX0, 12, PX1, 12)
    for x = PX0 + 4, PX1 - 4, 8 do put(edge, x, 7, 2, 2) end
    seg(edge, PX0 + 2, 12, PX0 + 2 + lean, BED)
    seg(edge * 0.7, PX0 + 5, 12, PX0 + 5 + lean, BED)
    seg(edge * 0.7, PX1 - 5, 12, PX1 - 5 + lean, BED)
    seg(edge, PX1 - 2, 12, PX1 - 2 + lean, BED)
    put(1.5 + md * 0.5, PX0 - 2, BED, PX1 - PX0 + 4, 5)
    line(edge + 0.5, PX0 - 2, BED, PX1 + 2, BED)
    -- the warning beacon on the crown
    put(math.min(10, 3 + amp * 3 + math.max(0, face) * 4), 63, 1, 3, 3)

    -- the billet on the die: white hot when it comes in, cooling as it's
    -- struck; the lows keep it glowing
    local bh = math.max(2, math.floor(6 * billet + 0.5))
    local bwid = 14 + math.floor((1 - billet) * 10)
    local glow = (5 + lo * 3 + e * 2) * (0.5 + 0.5 * billet) * (1 - kl * 0.45)
    put(math.min(11, glow), 64 - bwid / 2, BED - bh, bwid, bh)
    put(math.min(5, glow * 0.4), 64 - bwid / 2 - 3, BED - 1, bwid + 6, 1)

    -- the ram: dropped by the kick, stuttered by a ratchet
    local ry = ram_y()
    local roff = c > 0.5 and math.floor(math.sin(T * 1.3) * (c - 0.5) * 6 + 0.5) or 0
    seg(edge, 62, 12, 62 + roff, ry - 6)
    seg(edge, 66, 12, 66 + roff, ry - 6)
    put(1.5 + md * 0.5, RAM0 + roff, ry - 6, RAM1 - RAM0, 6)
    line(edge + 1, RAM0 + roff, ry - 6, RAM1 + roff, ry - 6)
    -- its face: lit by the billet's glow as it closes on it
    local close = clamp(1 - (BED - bh - ry) / 20, 0, 1)
    line(2 + glow * close * 0.8, RAM0 + roff, ry, RAM1 + roff, ry)
    if c > 0.6 then put(1 + (c - 0.6) * 4, RAM0 - roff * 2, ry - 5, RAM1 - RAM0, 1) end
    -- the impact: a white line at the contact while the ram holds
    local age = K.T - ram_t0
    if age >= 0.04 and age < 0.2 then
      local f = 1 - (age - 0.04) / 0.16
      line(4 + 8 * f, 64 - bwid / 2 - 4, BED - bh - 1, 64 + bwid / 2 + 4, BED - bh - 1)
    end

    -- the valve on the crown: steam on open hats and claps, a wisp kickless
    if kl > 0.3 and (#steam == 0 or K.T - steam[#steam].t0 > 0.7) then
      steam[#steam + 1] = {x = 88, y = 8, t0 = K.T, v = 0.3, dir = 1}
      if #steam > 10 then table.remove(steam, 1) end
    end
    put(2 + hiss * 6, PX1, 7, 4, 2)
    for i = #steam, 1, -1 do
      local P = steam[i]
      local u = (K.T - P.t0) / 1.5
      if u >= 1 then table.remove(steam, i)
      else
        K.ring((2 + P.v * 3 + hi * 2) * (1 - u), P.x + u * 14, P.y - u * 6 + u * u * 4, 1.5 + u * 6, 8, 0, 2 * math.pi, 0.6)
      end
    end

    -- the side anvil and its hammer: bells and metal swing it down
    local ax0, ax1, ay = 100, 116, 46
    put(2, ax0, ay, ax1 - ax0, 2)
    put(1.5, ax0 + 4, ay + 2, ax1 - ax0 - 8, BELT - ay - 2)
    local ha = 3.05 - hammer * 0.95 + math.sin(T * 0.8) * 0.03
    local pvx, pvy = 121, 22
    local hx2, hy2 = pvx + math.cos(ha) * 24, pvy + math.sin(ha) * 24
    line(2 + md, pvx, pvy, hx2, hy2)
    put(2.5 + hammer * 7, hx2 - 3, hy2 - 2, 6, 4)
    put(2, pvx - 1, pvy - 1, 3, 3)
    seg(1.5, pvx + 1, 4, pvx + 1, pvy)
    if hammer > 0.5 then put(4 + hammer * 7, ax0 + 6, ay - 1, 4, 1) end

    -- the conveyor: belt, rollers turning, plates riding away and cooling
    belt = (belt + (K.playing and (8 + e * 12) or 2) * K.DTS) % 10
    local bl = 1.5 + lo * 0.5
    line(bl, PX1 + 2, BELT, 127, BELT)
    line(bl * 0.7, PX1 + 2, BELT + 4, 127, BELT + 4)
    line(bl, 0, BELT, PX0 - 2, BELT)
    for x = PX1 + 6 - belt, 128, 10 do
      if x > PX1 + 3 then
        K.ring(1.5, x, BELT + 2, 1.6, 6)
        local ra = -belt / 1.6
        put(2 + hi * 2, x + math.cos(ra) * 1.5, BELT + 2 + math.sin(ra) * 1.5, 1, 1)
      end
    end
    for i = #plates, 1, -1 do
      local P = plates[i]
      local a2 = K.T - P.t0
      local x = PX1 + 2 + a2 * (8 + e * 12)
      if x > 130 then table.remove(plates, i)
      else
        local cool = math.exp(-a2 / 2.5)
        local w = 12 + (1 - P.h) * 8
        put(math.max(1.5, 8 * cool + lo), x, BELT - 2, w, 2)
        if c > 0.5 then line(3, x + 2, BELT - 3, x + w - 3, BELT - 2) end
      end
    end

    -- sparks and scale: off the billet on the kick and the snare
    for i = #sparks, 1, -1 do
      local P = sparks[i]
      local age2 = K.T - P.t0
      local u = age2 / 0.8
      local x = P.x + P.vx * age2 * (1 + c * 0.6)
      local y = P.y + P.vy * age2 + 70 * age2 * age2
      if u >= 1 or y > BELT then table.remove(sparks, i)
      else
        local vx, vy = P.vx, P.vy + 140 * age2
        local m = math.sqrt(vx * vx + vy * vy) + 0.01
        line((3 + 6 * P.v) * (1 - u) + hi * 2, x - vx / m * 2, y - vy / m * 2, x, y)
      end
    end
    K.grain(function(u, v) return 20 + u * 90, 10 + v * 40 end, 2 + hi * 6 + e * 3, 3 + hi * 3)
  end

  function M.draw(S)
    if K.view == 2 then draw_gears(S)
    elseif K.view == 3 then draw_press(S)
    else draw_corridor(S) end
  end

  M.init()
  return M
end
