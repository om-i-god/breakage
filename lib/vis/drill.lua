-- drill. view 1: a drill bit boring down through layered rock strata in cross-section.
-- view 2: a spinning wireframe icosahedron over a grid that bursts into its faces on ratchets.
--
-- view 1: the camera rides with the bit, so the strata climb past it as it
-- cuts. the kick bites: the bit jolts into the rock and a pressure ring
-- runs out through it; snares crack the layer at the cutting face, the
-- cracks staying in the rock as it climbs away; a ratchet winds the bit up
-- (faster flutes, a hotter tip, faster cutting) and sprays debris out of
-- the face, and each hit of the burst throws harder. the core tube at the
-- left lights the break slice playing. chaos opens faults that shear the
-- strata sideways and splits every hit into more cracks; energy cuts
-- faster and lifts the rock; in a kickless stretch the bit lifts off the
-- face and idles in its own dust.
-- view 2: the kick spins it about the vertical, snares about the
-- horizontal, hats roll it; a ratchet throws the faces apart (harder the
-- longer the burst) and they pull back together; energy grows it and wakes
-- a counter-turning core; chaos trails ghost copies and wrenches vertices
-- off true; break slices light one face each.
--
-- the ears: view 1, the lows brighten the pipe, the walls and the front
-- flutes, the mids light the seams, the back flutes, the dust and the core
-- tube, the highs lift the strata and glint the coal; view 2, the lows swell
-- the glow and the solid, the mids wake the core and light a halo,
-- the highs stream the stars and glitter a far star field.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  ---------------------------------------------------------------- view 1
  local BX = 66                         -- the hole being bored (screen x)
  local BW = 10                         -- a hole's half-width
  local BOTTOM = 57                     -- how deep a hole goes (screen y)
  local STEP = 46                       -- how far the rig slides to the next hole
  local LEFT = 10                       -- the rock starts right of the core tube
  local CORE_X, CORE_Y0, CORE_Y1 = 3, 6, 58

  ---------------------------------------------------------------- view 2
  local PHI = (1 + math.sqrt(5)) / 2
  local IV, IE, IF = {}, {}, {}         -- icosahedron: vertices, edges, faces
  local OV, OE = {}, {}                 -- octahedron (the core)
  local EF, FZ = {}, {}                 -- each edge's two faces; each face's depth

  do
    local s = 1 / math.sqrt(1 + PHI * PHI)
    local raw = {{0, 1, PHI}, {0, -1, PHI}, {0, 1, -PHI}, {0, -1, -PHI},
      {1, PHI, 0}, {-1, PHI, 0}, {1, -PHI, 0}, {-1, -PHI, 0},
      {PHI, 0, 1}, {-PHI, 0, 1}, {PHI, 0, -1}, {-PHI, 0, -1}}
    for i, v in ipairs(raw) do IV[i] = {v[1] * s, v[2] * s, v[3] * s} end
    local adj = {}
    for i = 1, 12 do
      adj[i] = {}
      for j = i + 1, 12 do
        local dx, dy, dz = raw[i][1] - raw[j][1], raw[i][2] - raw[j][2], raw[i][3] - raw[j][3]
        if math.abs(dx * dx + dy * dy + dz * dz - 4) < 0.01 then
          IE[#IE + 1] = {i, j}
          adj[i][j] = true
        end
      end
    end
    for i = 1, 12 do for j = i + 1, 12 do if adj[i][j] then
      for k = j + 1, 12 do if adj[i][k] and adj[j][k] then IF[#IF + 1] = {i, j, k} end end
    end end end
    for ei, E in ipairs(IE) do
      EF[ei] = {}
      for fi, F in ipairs(IF) do
        local has = 0
        for _, v in ipairs(F) do if v == E[1] or v == E[2] then has = has + 1 end end
        if has == 2 then EF[ei][#EF[ei] + 1] = fi end
      end
    end
    OV = {{1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1}}
    for i = 1, 6 do for j = i + 1, 6 do
      local a, b = OV[i], OV[j]
      if a[1] * b[1] + a[2] * b[2] + a[3] * b[3] == 0 then OE[#OE + 1] = {i, j} end
    end end
  end

  -- state
  local rot, spin, bite, lift, heat
  local cam, cam0, phase, ph_t, bd, holes
  local cracks, chips, rings, slit, nsl
  local burst_k
  local ax, ay, az, wx, wy, wz, ex, exv, flash_f, flash_t, core_a
  local trail, stars, grid_z, sparks2
  local P = {}                          -- projected vertices (scratch)

  function M.init()
    rot, spin, bite, lift, heat = 0, 0, 0, 0, 0
    cam, cam0, phase, ph_t, bd = 0, 0, 1, 0, 24
    holes = {{x = BX - STEP * 2, d = BOTTOM + 1}, {x = BX - STEP, d = BOTTOM + 1}, {x = BX, d = 25}}
    cracks, chips, rings, slit, nsl = {}, {}, {}, {}, 8
    burst_k = 0
    ax, ay, az, wx, wy, wz = 0.4, 0, 0.2, 0.25, 0.6, 0.1
    ex, exv, flash_f, flash_t, core_a = 0, 0, 1, -9, 0
    trail, stars, sparks2, grid_z = {}, {}, {}, 0
    for i = 1, 22 do
      stars[i] = {a = K.hash(i, 40) * K.TAU, r = 4 + K.hash(i, 41) * 70, s = 0.5 + K.hash(i, 42)}
    end
  end
  M.clear = M.init

  ---------------------------------------------------------------- the rock
  -- the strata are fixed in the world (horizontal bands, a boundary somewhere
  -- in every 14 rows); the camera only ever slides sideways between holes
  local function boundary(c) return c * 14 + math.floor(K.hash(c, 11) * 8) end
  local function layer_of(w)
    local c = w // 14
    if w >= boundary(c) then return c end
    return c - 1
  end
  -- what each layer is: 1 shale 2 sandstone 3 clay 4 limestone 5 coal
  -- 6 conglomerate (neighbours never match)
  local function ltype(c) return 1 + (c * 2 + math.floor(K.hash(c + 50, 12) * 2)) % 6 end
  local TYPE_L = {1, 2, 1, 3, 1, 1}
  -- the pattern of row w of the rock: a level, or 0
  local function row_level(w, up)
    local c = layer_of(w)
    local ty = ltype(c)
    local L = TYPE_L[ty] + up
    if ty == 1 then return (w % 3 == 0) and L or 0           -- shale: dense laminae
    elseif ty == 2 then return (w % 4 == 2) and L or 0       -- sandstone
    elseif ty == 3 then return (w % 8 == 1) and L or 0       -- clay
    elseif ty == 4 then return (w % 5 == 0) and L or 0       -- limestone courses
    elseif ty == 6 then return (w % 7 == 0) and L or 0 end   -- conglomerate
    return 0                                                 -- coal
  end

  -- faults: chaos drops blocks of rock between pairs of faults (world x),
  -- each block by its own throw, so they shear one at a time
  local FAULTS = {}
  local function fault_x(k, y)
    return k * 64 + 14 + K.hash(k, 61) * 24 + (y - 32) * (K.hash(k, 62) - 0.5) * 0.8 - cam
  end
  local function faults_for(y, dmax)
    if dmax < 0.5 then return 0 end
    local n = 0
    local k0 = math.floor((cam - 40) / 64)
    for k = k0, k0 + 3 do
      local d = math.floor(dmax * (0.3 + K.hash(k, 63) * 0.7) + 0.5) * (K.hash(k, 64) < 0.5 and -1 or 1)
      if d ~= 0 then
        n = n + 1
        local F = FAULTS[n] or {}
        F.x, F.k = fault_x(k, y), k
        F.x2 = F.x + 22 + K.hash(k, 65) * 12
        F.d = d
        FAULTS[n] = F
      end
    end
    return n
  end

  local function piece(y, a, b, off, up)
    local lv = row_level(y + off, up)
    if lv > 0 then put(lv, a, y, b - a, 1) end
  end

  -- row y from x0 to x1, the blocks dropped
  local function emit(y, x0, x1, up, nf)
    if x1 <= x0 then return end
    local a = x0
    for k = 1, nf do
      local F = FAULTS[k]
      local b0, b1 = math.floor(F.x), math.floor(F.x2)
      if b1 > a and b0 < x1 then
        local p = math.max(a, b0)
        if p > a then piece(y, a, p, 0, up) end
        local q = math.min(x1, b1)
        if q > p then piece(y, p, q, F.d, up) end
        a = math.max(a, q)
      end
    end
    if x1 > a then piece(y, a, x1, 0, up) end
  end

  local function in_hole(x, y)
    for _, H in ipairs(holes) do
      local hx = H.x - cam
      if y < H.d and x > hx - BW - 1 and x < hx + BW + 1 then return true end
    end
    return false
  end

  local function crack(v, chaos_extra)
    local H = holes[#holes]
    local dir = K.rnd() < 0.5 and -1 or 1
    local y = clamp(bd - 3 + (K.rnd() - 0.5) * 10, 3, 60)
    if #cracks >= 10 then table.remove(cracks, 1) end
    cracks[#cracks + 1] = {x = H.x + dir * (BW + 1), y = y, dir = dir, t0 = K.T, v = v,
      seed = math.floor(K.rnd() * 9999), len = 18 + K.rnd() * 26 + K.chaos * 26 + (chaos_extra or 0)}
  end

  local function spray(n, force)
    local tip = bd - lift * 7
    for _ = 1, n do
      if #chips >= 40 then table.remove(chips, 1) end
      local side = K.rnd() < 0.5 and -1 or 1
      chips[#chips + 1] = {x = BX + side * (2 + K.rnd() * 4), y = tip - 2,
        vx = side * (25 + K.rnd() * 60) * force, vy = -(30 + K.rnd() * 70) * force,
        t0 = K.T, life = 0.5 + K.rnd() * 0.5}
    end
  end

  ---------------------------------------------------------------- events
  function M.kick(v)
    v = K.num(v, 1)
    bite = math.max(bite, v)
    if #rings >= 6 then table.remove(rings, 1) end
    rings[#rings + 1] = {t0 = K.T, v = v}
    wy = clamp(wy + (0.6 + v * 0.8) * (K.rnd() < 0.5 and 1 or -1) * (0.6 + K.chaos), -3, 3)
  end

  function M.snare(v, n)
    v, n = K.num(v, 1), K.num(n, 1)
    if n > 1 then
      -- one hit of a ratchet burst: each throws harder, the bit winds up
      burst_k = burst_k + 1
      spin = math.min(14, spin + 0.35)
      spray(1, 0.6 + math.min(burst_k, 16) * 0.08)
      if burst_k % 4 == 1 then crack(v * 0.6) end
    else
      burst_k = 0
      crack(v)
      if K.chaos > 0.4 then crack(v * 0.7, 18) end
      if K.chaos > 0.35 then
        table.insert(trail, 1, {ax, ay, az, K.rnd() < 0.5 and -1 or 1, K.rnd() - 0.5})
        if #trail > 2 then trail[3] = nil end
      end
      if K.chaos > 0.75 then crack(v * 0.5, 28) end
    end
    wx = clamp(wx + (0.5 + v * 0.6) * (K.rnd() < 0.5 and 1 or -1), -2.5, 2.5)
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8, 1) end

  function M.hat(v)
    spray(1, 0.4)
    wz = clamp(wz + 0.2 * K.num(v, 1) * (K.rnd() < 0.5 and 1 or -1), -1.5, 1.5)
  end

  function M.tick()
    spray(2, 0.5)
    if #sparks2 >= 10 then table.remove(sparks2, 1) end
    sparks2[#sparks2 + 1] = {i = 1 + math.floor(K.rnd() * 12), t0 = K.T}
  end

  function M.perc(kind, v) M.hat(K.num(v, 1) * 0.6) end

  function M.brk(i, n, rev)
    nsl = clamp(math.floor(K.num(n, 8)), 1, 32)
    i = clamp(math.floor(K.num(i, 1)), 1, nsl)
    slit[i] = {t0 = K.T, rev = rev == true}
    flash_f, flash_t = (i - 1) % #IF + 1, K.T
  end

  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 16)
    spin = math.min(14, spin + 1.5 + n * 0.5)
    heat = math.min(1, heat + 0.2 + n * 0.05)
    spray(4 + n, 0.8 + n * 0.04)
    exv = exv + 2 + n * 0.35
    burst_k = 0
  end

  function M.fill() spin = math.min(14, spin + 2) end

  ---------------------------------------------------------------- view 1 draw
  local function draw_bore(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    local kl = K.kickless
    local playing = K.playing

    bite = bite * math.exp(-DT / 0.1)
    spin = spin * math.exp(-DT / 0.9)
    heat = heat * math.exp(-DT / 1.2)
    lift = K.follow(lift, kl, 0.5, DT)
    local omega = (playing and (2 + e * 4) or 0.8) + spin * 1.6
    rot = (rot + omega * K.DTS) % (K.TAU * 1000)

    -- the cycle: bore down to the bottom, pull out, slide over, bore again
    local H = holes[#holes]
    local tip
    if phase == 1 then
      local rate = playing and (1.4 + e * 3 + spin * 0.35) * (1 - lift * 0.97) or 0.4
      bd = math.min(BOTTOM, bd + rate * K.DTS)
      H.d = math.floor(bd) + 1
      tip = bd + bite * 2 - lift * 7
      if bd >= BOTTOM then phase, ph_t = 2, 0 end
    elseif phase == 2 then
      ph_t = ph_t + K.DTS
      local u = clamp(ph_t / 1.6, 0, 1)
      tip = BOTTOM - (BOTTOM + 22) * K.ease(u)
      if u >= 1 then phase, ph_t, cam0 = 3, 0, cam end
    else
      ph_t = ph_t + K.DTS
      local u = clamp(ph_t / 4.5, 0, 1)
      cam = cam0 + STEP * K.ease(u)
      tip = -22
      if u >= 1 then
        cam = cam0 + STEP
        phase, bd = 1, -4
        if #holes >= 4 then table.remove(holes, 1) end
        holes[#holes + 1] = {x = cam + BX, d = 0}
        H = holes[#holes]
        tip = bd
      end
    end
    local camf = math.floor(cam + 0.5)
    local hx = H.x - camf

    -- faults: chaos shears the strata
    local dmax = c > 0.3 and (c - 0.3) / 0.7 * 7 or 0
    local up = math.floor(e * 1.2 + lo * 0.6 + hi * 0.9 + 0.2)

    -- the strata, row by row, with the holes cut out of them
    for y = 0, 63 do
      local nf = faults_for(y, dmax)
      local a = LEFT
      for _, Hh in ipairs(holes) do
        local x = Hh.x - camf
        if y < Hh.d and x + BW >= LEFT and x - BW < 128 then
          emit(y, a, math.max(LEFT, x - BW), up, nf)
          a = math.max(a, x + BW + 1)
        end
      end
      emit(y, a, 128, up, nf)
    end

    -- layer boundaries: wavy seams, brighter, sheared at the faults
    local nf = faults_for(32, dmax)
    for cc = -1, 5 do
      local by = boundary(cc)
      local px, py
      for x = LEFT, 128, 8 do
        local off = 0
        for k = 1, nf do
          local F = FAULTS[k]
          if x - 4 >= F.x and x - 4 < F.x2 then off = F.d end
        end
        local yy = by - off + 1.6 * math.sin((x + camf) * 0.07 + cc * 2.3)
        if px and math.abs(yy - py) < 4 and not in_hole(x - 4, (yy + py) / 2) then
          line(1.4 + e * 1.5 + lo + mid * 2.2 + hi * 1.5, px, py, x, yy)
        end
        px, py = x, yy
      end
    end
    for k = 1, nf do
      local F = FAULTS[k]
      local x0, x1 = fault_x(F.k, 0), fault_x(F.k, 63)
      local w = F.x2 - F.x
      local fl = 1 + (c - 0.3) / 0.7 * 4
      if x0 > LEFT and x1 > LEFT then line(fl, x0, 0, x1, 63) end
      if x0 + w > LEFT and x1 + w > LEFT then line(fl, x0 + w, 0, x1 + w, 63) end
    end

    -- what sits in the layers: limestone joints, conglomerate pebbles,
    -- coal glinting with the highs
    for cc = layer_of(-6), layer_of(70) do
      local ty = ltype(cc)
      if ty == 4 or ty == 5 or ty == 6 then
        local top, bot = boundary(cc), boundary(cc + 1)
        local cw = ty == 4 and 14 or 18
        local k0 = math.floor((camf + LEFT) / cw)
        for k = k0, k0 + math.ceil((128 - LEFT) / cw) do
          local id = k * 37 + cc * 101
          local x = k * cw + math.floor(K.hash(id, 21) * cw) - camf
          local y = top + 1 + math.floor(K.hash(id, 22) * math.max(1, bot - top - 2))
          if x >= LEFT and x < 127 and not in_hole(x, y) then
            if ty == 4 then
              local yc = y - y % 5 + 1
              put(2 + up, x, yc, 1, 3)
            elseif ty == 5 then
              local tw = 0.5 + 0.5 * math.sin(T * (1 + K.hash(id, 23) * 2) + id)
              put(1 + tw * (1.5 + hi * 6), x, y, 1, 1)
            else
              put(2 + up, x, y, 3, 2)
              put(1, x - 1, y + 2, 5, 1)
            end
          end
        end
      end
    end

    -- cracks: they spread out of the hole wall and stay in the rock
    for i = #cracks, 1, -1 do
      local C = cracks[i]
      local age = K.T - C.t0
      if age > 6 then table.remove(cracks, i)
      else
        local grow = clamp(age / 0.12, 0, 1)
        local lv = (C.v * 9) * math.exp(-age / 0.35) + 3 * math.exp(-age / 2.5)
        local px, py = C.x - camf, C.y
        for j = 1, 6 do
          local f = j / 6
          if f > grow then break end
          local x = C.x - camf + C.dir * f * C.len
          local y = C.y + (K.hash(C.seed + j, 5) - 0.5) * 7
          line(lv * (1 - f * 0.4), px, py, x, y)
          if j == 3 and C.len > 32 then
            line(lv * 0.6, x, y, x + C.dir * 8, y + (K.hash(C.seed, 6) - 0.5) * 12)
          end
          px, py = x, y
        end
      end
    end

    -- pressure rings from the kick, running out through the rock
    for i = #rings, 1, -1 do
      local R = rings[i]
      local u = (K.T - R.t0) / 0.45
      if u >= 1 then table.remove(rings, i)
      elseif phase == 1 then
        K.ring((3 + R.v * 5) * (1 - u) ^ 1.3, hx, H.d + 1, 6 + u * 40, 20, 0, K.TAU, 0.55)
      end
    end

    -- the hole walls: the old holes dim, settled with dust at the bottom
    for n, Hh in ipairs(holes) do
      local x = Hh.x - camf
      local cur = n == #holes
      if Hh.d > 1 and x + BW >= LEFT and x - BW < 128 then
        local wl = cur and (2.5 + lo * 1.5) or 1.5
        if x - BW >= LEFT then line(wl, x - BW, 0, x - BW, Hh.d - 2) end
        line(wl, x + BW, 0, x + BW, Hh.d - 2)
        K.ring(wl + (cur and bite * 4 or 0), x, Hh.d - 2, BW, 8, 0, math.pi)
        if not cur then
          -- backfilled with rubble
          for y = 2 + (camf % 2), Hh.d - 3, 4 do
            local h = K.hash(y + n * 7 + math.floor(Hh.x), 81)
            put(1, x - BW + 2 + math.floor(h * 6), y, 3 + math.floor(h * 8), 1)
          end
          for k = 0, 4 do put(2, x - 5 + k * 2 + (k % 2), Hh.d - 3 - (k % 2), 2, 1) end
        end
      end
    end

    -- dust in the hole: thicker with energy, thick when the bit idles
    if H.d > 2 then
      K.haze(hx - BW + 1, 0, hx + BW, H.d, 0.08 + mid * 0.3 + e * 0.15 + lift * 0.4 + (phase == 2 and 0.3 or 0), 1 + mid, T * 5)
    end

    -- the drill string: pipe with couplings, sliding as it cuts
    local tb = tip - 25                       -- top of the fluted body
    if tb > 0 then
      line(3 + lo, BX - 3, 0, BX - 3, tb)
      line(3 + lo, BX + 3, 0, BX + 3, tb)
      for k = 0, 3 do
        local y = (k * 18 + tip) % 72 - 6
        if y < tb - 3 then put(3 + e, BX - 5, y, 11, 3) end
      end
      put(2 + hi * 4, BX - 2 + math.floor((rot * 2) % 4), (T * 30) % math.max(1, tb), 1, 2)
    end

    if tip > -2 then
      -- the fluted body: a helix, front flutes bright, back ones dim
      local blur = omega > 9 and 1 or 0
      local nfl = 2 + blur
      local hot = math.min(1, heat + spin / 14)
      for f = 0, nfl - 1 do
        local px, py, pf
        for q = 0, 9 do
          local yy = tb + q * 1.75
          local th = rot + f * K.TAU / nfl + q * 0.5
          local x = BX + 7.5 * math.sin(th)
          local front = math.cos(th) > 0
          if px then
            local l = (front and pf) and (6 + lo * 3 + hot * 3) or (1.2 + mid * 3)
            line(l * (blur == 1 and 0.75 or 1), px, py, x, yy)
          end
          px, py, pf = x, yy, front
        end
      end
      line(3.5, BX - 8, tb, BX - 8, tb + 16)
      line(3.5, BX + 8, tb, BX + 8, tb + 16)
      line(4, BX - 8, tb, BX + 8, tb)
      -- the head: a cone onto the tip, the cutters glowing with heat
      local hl = 4 + bite * 6 + hot * 4
      line(hl, BX - 8, tb + 16, BX, tip)
      line(hl, BX + 8, tb + 16, BX, tip)
      line(3 + hot * 5, BX - 5, tb + 19, BX + 5, tb + 19)
      line(2 + hot * 4, BX - 3, tb + 22, BX + 3, tb + 22)
      if hot > 0.2 then K.disc(1 + hot * 2, BX, tip - 3, 2 + hot * 5) end
      put(math.min(13, 5 + bite * 8 + hot * 5), BX - 1, tip - 1, 2, 2)
    end

    -- crushed rock at the face, kicked up by the bite
    if phase == 1 and lift < 0.5 then
      for k = 1, 5 do
        local a = K.hash(k + math.floor(T * 8) * 5, 31) * math.pi
        local r = 2 + K.hash(k + math.floor(T * 8) * 5, 32) * (5 + bite * 6)
        put(2 + bite * 6 + hi * 2, hx + math.cos(a) * r * 1.4, H.d - math.sin(a) * r * 0.5, 1, 1)
      end
    end

    -- debris: flung from the face, falling
    for i = #chips, 1, -1 do
      local D = chips[i]
      local age = K.T - D.t0
      local u = age / D.life
      if u >= 1 then table.remove(chips, i)
      else
        local x = D.x + D.vx * age
        local y = D.y + D.vy * age + 90 * age * age
        local vy = D.vy + 180 * age
        line(4 + 8 * (1 - u), x, y, x - D.vx * 0.03, y - vy * 0.03)
      end
    end

    -- the core tube at the left: the break, slice by slice
    local n = nsl
    local hgt = (CORE_Y1 - CORE_Y0) / n
    line(2, CORE_X - 1, CORE_Y0 - 1, CORE_X - 1, CORE_Y1)
    line(2, CORE_X + 4, CORE_Y0 - 1, CORE_X + 4, CORE_Y1)
    for i = 1, n do
      local L = slit[i]
      local lv = 0.7 + mid * 1.6
      if L then
        local age = K.T - L.t0
        lv = 1 + 9 * math.exp(-age / 0.2) + 2 * math.exp(-age / 1.5)
        if age > 6 then slit[i] = nil end
      end
      put(lv, CORE_X, CORE_Y0 + (i - 1) * hgt, 4, math.max(1, hgt - 1))
    end
  end

  ---------------------------------------------------------------- view 2 draw
  local function rotm(a, b, g)
    local ca, sa, cb, sb, cg, sg = math.cos(a), math.sin(a), math.cos(b), math.sin(b), math.cos(g), math.sin(g)
    return ca, sa, cb, sb, cg, sg
  end

  -- rotate (yaw b, pitch a, roll g) and project; returns x, y, z
  local function proj(v, a, b, g, sc, cx, cy, jit, seed)
    local ca, sa, cb, sb, cg, sg = rotm(a, b, g)
    local x, y, z = v[1], v[2], v[3]
    x, z = x * cb + z * sb, -x * sb + z * cb
    y, z = y * ca - z * sa, y * sa + z * ca
    x, y = x * cg - y * sg, x * sg + y * cg
    if jit > 0 then
      x = x + (K.hash(seed, 51) - 0.5) * jit
      y = y + (K.hash(seed, 52) - 0.5) * jit
    end
    local f = 3.4 / (3.4 - z)
    return cx + x * sc * f, cy + y * sc * f, z
  end

  local function solid(lv_scale, a, b, g, sc, cx, cy, explode, jit, hi_face)
    local nt = math.floor(K.T * 6)
    for i = 1, 12 do
      local x, y, z = proj(IV[i], a, b, g, sc, cx, cy, jit, i + nt * 13)
      local p = P[i] or {}
      p[1], p[2], p[3] = x, y, z
      P[i] = p
    end
    -- which faces look at us (a convex solid: its centre is in front)
    for fi, F in ipairs(IF) do
      FZ[fi] = (P[F[1]][3] + P[F[2]][3] + P[F[3]][3]) / 3
    end
    if explode < 0.03 then
      for ei, E in ipairs(IE) do
        local p, q = P[E[1]], P[E[2]]
        local f1, f2 = EF[ei][1], EF[ei][2]
        local fz = math.max(FZ[f1], FZ[f2])
        local l
        if fz > 0 then
          l = lv_scale * (2.4 + (p[3] + q[3] + 0.6) * 1.3)
          if f1 == hi_face or f2 == hi_face then l = l + 2.5 end
        else
          l = lv_scale * 0.8
        end
        line(l, p[1], p[2], q[1], q[2])
      end
      return
    end
    -- exploded: each face on its own, pushed out along its centre
    local fade = 1 - math.min(0.45, explode * 0.3)
    for fi, F in ipairs(IF) do
      local p, q, r = P[F[1]], P[F[2]], P[F[3]]
      local mx, my = (p[1] + q[1] + r[1]) / 3, (p[2] + q[2] + r[2]) / 3
      local z = FZ[fi]
      local k = explode * (0.6 + K.hash(fi, 53) * 0.9)
      local dx, dy = (mx - cx) * k * 1.3, (my - cy) * k * 1.3
      local shrink = 1 - math.min(0.5, explode * 0.35)
      local function at(v) return mx + dx + (v[1] - mx) * shrink, my + dy + (v[2] - my) * shrink end
      local x1, y1 = at(p)
      local x2, y2 = at(q)
      local x3, y3 = at(r)
      local l = z > 0 and lv_scale * (2.4 + z * 3) * fade or lv_scale * 0.8
      if fi == hi_face then l = l + 2.5 end
      line(l, x1, y1, x2, y2)
      line(l, x2, y2, x3, y3)
      line(l, x3, y3, x1, y1)
    end
  end

  local function draw_solid(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    -- the highs glitter between the kicks (the hats' place)
    local hiq = hi * (1 - K.env.kick) ^ 3
    local kl = K.kickless
    -- spin: drums push it, drag pulls it back to an idle turn
    local idle = K.playing and (0.35 + e * 0.5) or 0.25
    local drag = math.exp(-DT / 0.8)
    wx = wx * drag + 0.18 * (1 - drag)
    wy = wy * drag + idle * (1 - drag)
    wz = wz * drag + 0.06 * (1 - drag)
    wx, wy, wz = clamp(wx, -2.5, 2.5), clamp(wy, -3, 3), clamp(wz, -1.5, 1.5)
    ax = (ax + wx * K.DTS) % (K.TAU * 100)
    ay = (ay + wy * K.DTS) % (K.TAU * 100)
    az = (az + wz * K.DTS) % (K.TAU * 100)
    -- the explosion: a spring that ratchets kick open
    exv = exv - ex * 40 * DT - exv * 6 * DT
    ex = clamp(ex + exv * DT, 0, 2.2)
    if ex == 0 and exv < 0 then exv = 0 end
    bite = bite * math.exp(-DT / 0.1)
    local wmag = math.abs(wx) + math.abs(wy) + math.abs(wz)
    core_a = core_a - (0.8 + e * 2 + wmag * 0.3) * K.DTS

    local cx, cy = 64, 29 - kl * 3
    local sc = 16 + e * 4 + lo * 1.5

    -- a glow behind it, swelling with the lows and the kick
    K.disc(1, cx, cy, 21 + e * 3 + lo * 2)
    K.disc(1 + lo * 0.6 + bite * 1.2 + e * 0.5, cx, cy, 11 + bite * 3)

    -- the stars streaming past, faster as it spins
    local sp = (8 + wmag * 6 + e * 10) * (1 - kl * 0.6)
    for _, st in ipairs(stars) do
      st.r = st.r + sp * st.s * (0.2 + st.r / 40) * K.DTS
      if st.r > 80 then st.r = 3 + K.rnd() * 6; st.a = K.rnd() * K.TAU end
      local ca, sa = math.cos(st.a), math.sin(st.a)
      local len = 1 + sp * 0.04 * st.s * (st.r / 30)
      line(0.8 + st.r / 40 + hi * 2.2, cx + ca * st.r, cy + sa * st.r * 0.6,
        cx + ca * (st.r + len), cy + sa * (st.r + len) * 0.6)
    end

    -- the highs: a far field of stars glittering
    if hiq > 0.05 then
      for i = 0, 27 do
        local x, y = math.floor(K.hash(i, 81) * 127), math.floor(K.hash(i, 82) * 44)
        local tw = 0.5 + 0.5 * math.sin(T * (4 + K.hash(i, 83) * 7) + i * 2.3)
        put(hiq * (1 + tw * 4), x, y, 1 + (i % 3 == 0 and 1 or 0), 1)
      end
    end
    -- the mids: a halo round the glow
    K.ring(mid * 3.2, cx, cy, 24 + e * 3 + lo * 2, 20)

    -- the grid floor rolling toward us
    local HZ = 47
    grid_z = (grid_z + (0.25 + e * 0.5 + wmag * 0.06) * (1 - kl * 0.9) * K.DTS) % 1
    for i = -3, 3 do
      line(1, 64 + i * 10, HZ, 64 + i * 40, 64)
      -- studs rolling down each rail toward us
      for j = 0, 2 do
        local u = ((j + grid_z + K.hash(i, 71) * 0.3) / 3) % 1
        local uu = u * u
        put(1.5 + uu * 4 + bite * 3 + lo * 2, 64 + i * (10 + 30 * uu) - 1, HZ + 17 * uu, 2, 1)
      end
    end
    K.dashes(1 + lo * 1.5, HZ, 4, 9, -grid_z * 9)
    -- the shadow, breathing with the kick
    K.ring(2 + bite * 3, 64, 56, 16 + sc * 0.3, 16, 0, K.TAU, 0.18)

    -- chaos: frozen ghosts of poses the hits knocked it through, off to the sides
    local jit = c > 0.3 and (c - 0.3) * 0.3 or 0
    if c > 0.35 then
      for gi, g in ipairs(trail) do
        if gi == 1 or c > 0.7 then
          solid(0.3, g[1], g[2], g[3], sc * 0.85, cx + g[4] * (8 + c * 18), cy + g[5] * 4, ex * 0.6, 0, -1)
        end
      end
    end

    -- the core: an octahedron turning the other way, woken by energy
    -- (the mids wake it too)
    local cv = e * (1 - kl) + bite * 0.4 + mid * 0.2
    if cv > 0.15 then
      for _, E in ipairs(OE) do
        local x1, y1, z1 = proj(OV[E[1]], ax * 0.5, core_a, az, sc * 0.42, cx, cy, 0, 0)
        local x2, y2, z2 = proj(OV[E[2]], ax * 0.5, core_a, az, sc * 0.42, cx, cy, 0, 0)
        line(cv * (1.5 + (z1 + z2 + 2) * 0.8) + hi * 1.5, x1, y1, x2, y2)
      end
    end

    -- the solid itself
    local hf = (K.T - flash_t) < 0.3 and flash_f or -1
    solid(1 + bite * 0.25 + hi * 0.2, ax, ay, az, sc, cx, cy, ex, jit, hf)

    -- ticks spark a vertex
    for i = #sparks2, 1, -1 do
      local Sp = sparks2[i]
      local u = (K.T - Sp.t0) / 0.25
      if u >= 1 then table.remove(sparks2, i)
      else
        local p = P[Sp.i]
        local r = 1 + u * 4
        local l = 9 * (1 - u)
        line(l, p[1] - r, p[2], p[1] + r, p[2])
        line(l, p[1], p[2] - r, p[1], p[2] + r)
      end
    end
  end

  function M.draw(S)
    if K.view == 2 then draw_solid(S) else draw_bore(S) end
  end

  M.init()
  return M
end
