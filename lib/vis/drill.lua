-- drill. view 1: a drill bit boring down through layered rock strata in cross-section.
-- view 2: a spinning wireframe icosahedron over a grid that bursts into its faces on ratchets.
-- view 3: the rig at night: the derrick over the hole, a flare burning off,
-- and the ground cut away so the bit shows working down through the strata.
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
-- face and idles in its own dust. open hats puff dust plumes up the hole,
-- closed hats chip it; drums (congas, toms, log drums) run a tremor along a
-- seam, metal (cowbell, bells) sparks off the pipe. the depth log at the
-- right fills over the phrase and ticks on each bar.
-- view 2: the kick spins it about the vertical, snares about the
-- horizontal, hats roll it; a ratchet throws the faces apart (harder the
-- longer the burst) and they pull back together; energy grows it and wakes
-- a counter-turning core; chaos trails ghost copies and wrenches vertices
-- off true; break slices light one face each. closed hats glint a vertex,
-- open hats ring a halo out, metal sparks a vertex, drums shake the grid;
-- an orbit ring tilts round it with a bead going round over the phrase,
-- flashing on each bar.
-- view 3: the kick bites (the travelling block jolts, the rotary table and
-- the bit flash, a pressure ring runs out under the ground); snares crack
-- the face and throw mud over the shaker; hats flicker the floodlights,
-- open hats puff the engine stacks; a ratchet spins the rotary up and
-- flares the stack, a fill flares it hard. the travelling block goes down
-- a stand every two bars, a stand is racked in the derrick each bar, the
-- bit works down through the phrase and the floor lamps count it off.
-- energy turns it faster, chaos sways the derrick and whips the flame,
-- kickless lets the rig idle in a ground fog.
--
-- the ears: view 1, the lows brighten the pipe, the walls and the front
-- flutes, the mids light the seams, the back flutes, the dust and the core
-- tube, the highs lift the strata and glint the coal; view 2, the lows swell
-- the glow and the solid, the mids wake the core and light a halo,
-- the highs stream the stars and glitter a far star field; view 3, the
-- lows glow the bit, the ground line and the flare, the mids light the
-- derrick, the seams and the floodlights, the highs the stars, the flame's
-- sparks and the mud pit, the level the rig's lights and the orbit (view 2).
return function(K)
  local M = {}
  local A, clamp = K.A, K.clamp
  -- every level goes through GAIN: the busier views draw a touch dimmer
  local GAIN = 1
  local kput, kline, kring, kdisc = K.put, K.line, K.ring, K.disc
  local function put(l, x, y, w, h) return kput(l * GAIN, x, y, w, h) end
  local function line(l, x0, y0, x1, y1) return kline(l * GAIN, x0, y0, x1, y1) end
  local function ring(l, ...) return kring(l * GAIN, ...) end
  local function disc(l, ...) return kdisc(l * GAIN, ...) end

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
  local plumes, tremors, pipesp, glints, halo2
  local bars, d3, trip, blk, flare, flick, quake
  local spurts, rot3, puffs3

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
    plumes, tremors, pipesp, glints, halo2 = {}, {}, {}, {}, 0
    bars, d3, trip, blk, flare, flick, quake = 0, 0.2, 0, 0, 0, 0, 0
    spurts, rot3, puffs3 = {}, 0, {}
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
  local THROW = {}                      -- each fault's throw as drawn: k -> {d, t}
  -- step each fault's throw toward where chaos wants it, a row at a time,
  -- one fault at a time, so a block never jumps
  local function throw_step(dmax)
    local k0 = math.floor((cam - 40) / 64)
    local moved = false
    for k = k0, k0 + 3 do
      local want = 0
      -- (a fault slips once, all the way, when chaos passes its own point)
      if dmax >= 1.5 + K.hash(k, 66) * 2.5 then
        want = math.floor(7 * (0.3 + K.hash(k, 63) * 0.7) + 0.5) * (K.hash(k, 64) < 0.5 and -1 or 1)
      end
      local Th = THROW[k]
      if not Th then Th = {d = want, t = 0}; THROW[k] = Th end
      if Th.d ~= want and not moved and K.T - Th.t > 0.4 then
        Th.d = want
        Th.t = K.T
        moved = true
      end
    end
    for k in pairs(THROW) do if k < k0 - 2 or k > k0 + 6 then THROW[k] = nil end end
  end
  local function fault_x(k, y)
    return k * 64 + 14 + K.hash(k, 61) * 24 + (y - 32) * (K.hash(k, 62) - 0.5) * 0.8 - cam
  end
  local function faults_for(y)
    local n = 0
    local k0 = math.floor((cam - 40) / 64)
    for k = k0, k0 + 3 do
      local d = THROW[k] and THROW[k].d or 0
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
    if #cracks >= 8 then table.remove(cracks, 1) end
    cracks[#cracks + 1] = {x = H.x + dir * (BW + 1), y = y, dir = dir, t0 = K.T, v = v,
      seed = math.floor(K.rnd() * 9999), len = 16 + K.rnd() * 22 + K.chaos * 18 + (chaos_extra or 0) * 0.7}
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
    quake = math.max(quake, v * 0.5)
    if #rings >= 6 then table.remove(rings, 1) end
    rings[#rings + 1] = {t0 = K.T, v = v}
    wy = clamp(wy + (0.45 + v * 0.6) * (K.rnd() < 0.5 and 1 or -1) * (0.6 + K.chaos), -3, 3)
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
    if #spurts >= 5 then table.remove(spurts, 1) end
    spurts[#spurts + 1] = {t0 = K.T, v = v, seed = math.floor(K.rnd() * 999), n = n}
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8, 1) end

  local function plume(v)
    if #plumes >= 6 then table.remove(plumes, 1) end
    plumes[#plumes + 1] = {t0 = K.T, v = v, dx = (K.rnd() - 0.5) * 10}
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    if open then
      plume(v)
      if #puffs3 >= 6 then table.remove(puffs3, 1) end
      puffs3[#puffs3 + 1] = {t0 = K.T, v = v, k = math.floor(K.rnd() * 2)}
      halo2 = math.max(halo2, 0.6 + 0.4 * v)
    else
      spray(1, 0.4)
      if #glints >= 8 then table.remove(glints, 1) end
      glints[#glints + 1] = {i = 1 + math.floor(K.rnd() * 12), t0 = K.T, v = v}
    end
    flick = math.max(flick, open and 0.8 or 0.35 * v)
    wz = clamp(wz + 0.2 * v * (K.rnd() < 0.5 and 1 or -1), -1.5, 1.5)
  end
  function M.ride(v) M.hat(K.num(v, 1) * 0.7, true) end

  function M.tick()
    spray(2, 0.5)
    if #sparks2 >= 10 then table.remove(sparks2, 1) end
    sparks2[#sparks2 + 1] = {i = 1 + math.floor(K.rnd() * 12), t0 = K.T}
  end

  -- percussion: drums shake the ground, metal rings off the pipe, the rest chips
  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 1 or kind == 2 or kind == 7 or kind == 13 or kind == 17 or kind == 18 or kind == 20 then
      if #tremors >= 4 then table.remove(tremors, 1) end
      tremors[#tremors + 1] = {t0 = K.T, v = v, y = 8 + K.rnd() * 48}
      quake = math.max(quake, v)
      wx = clamp(wx + 0.4 * v * (K.rnd() < 0.5 and 1 or -1), -2.5, 2.5)
    elseif kind == 3 or kind == 6 or kind == 21 or kind == 11 or kind == 8 then
      if #pipesp >= 6 then table.remove(pipesp, 1) end
      pipesp[#pipesp + 1] = {t0 = K.T, v = v, y = 4 + K.rnd() * 20}
      if #sparks2 >= 10 then table.remove(sparks2, 1) end
      sparks2[#sparks2 + 1] = {i = 1 + math.floor(K.rnd() * 12), t0 = K.T}
    else
      M.hat(v * 0.6, false)
    end
  end
  function M.tom(v) M.perc(17, K.num(v, 1)) end

  function M.bar(S)
    bars = bars + 1
    blk = 1
  end

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
    flare = math.max(flare, 0.4 + n * 0.06)
    burst_k = 0
  end

  function M.fill()
    spin = math.min(14, spin + 2)
    flare = 1
    exv = exv + 1.2
  end

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
    throw_step(dmax)
    local amp = A[K.AMP]
    local up = math.min(1, math.floor(e * 0.8 + lo * 0.4 + hi * 0.6 + 0.2))

    -- the strata, row by row, with the holes cut out of them
    for y = 0, 63 do
      local nf = faults_for(y)
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
    local nf = faults_for(32)
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
      local fl = 1 + math.max(0, c - 0.3) / 0.7 * 4
      -- dashed, so a sheared pane full of faults stays inside the light budget
      for y = 0, 56, 8 do
        local u0, u1 = y / 63, math.min(63, y + 5) / 63
        local xa, xb = x0 + (x1 - x0) * u0, x0 + (x1 - x0) * u1
        if xa > LEFT and xb > LEFT then line(fl, xa, y, xb, y + 5) end
        if xa + w > LEFT and xb + w > LEFT then line(fl, xa + w, y, xb + w, y + 5) end
      end
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
        local lv = (C.v * 6) * math.exp(-age / 0.35) + 2.5 * math.exp(-age / 2.5)
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
        ring((2 + R.v * 3.5) * (1 - u) ^ 1.3, hx, H.d + 1, 6 + u * 40, 20, 0, K.TAU, 0.55)
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
        ring(wl + (cur and bite * 4 or 0), x, Hh.d - 2, BW, 8, 0, math.pi)
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
      K.haze(hx - BW + 1, 0, hx + BW, H.d, 0.05 + mid * 0.2 + e * 0.1 + lift * 0.4 + (phase == 2 and 0.3 or 0), 1 + mid, T * 5)
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
            local l = (front and pf) and (4 + lo * 2 + hot * 2) or (1.2 + mid * 2)
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
      if hot > 0.2 then disc(1 + hot * 2, BX, tip - 3, 2 + hot * 5) end
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
        line(3 + 6 * (1 - u), x, y, x - D.vx * 0.03, y - vy * 0.03)
      end
    end

    -- open hats: dust plumes climbing out of the hole
    for i = #plumes, 1, -1 do
      local Pl = plumes[i]
      local u = (K.T - Pl.t0) / 1.6
      if u >= 1 then table.remove(plumes, i)
      else
        local y = (H.d - 4) * (1 - u) - 4 * u
        ring((1.5 + Pl.v * 4) * (1 - u), hx + Pl.dx * u, y, 2 + u * (BW - 2) + u * u * 6, 10, 0, K.TAU, 0.6)
      end
    end
    -- drums: a tremor running through the rock, a wave along one seam
    for i = #tremors, 1, -1 do
      local Tr = tremors[i]
      local u = (K.T - Tr.t0) / 0.7
      if u >= 1 then table.remove(tremors, i)
      else
        local px, py
        local a = (1 - u) * 3 * Tr.v
        for x = LEFT, 128, 6 do
          local d = math.abs(x - hx)
          local env = math.max(0, 1 - math.abs(d - u * 90) / 22)
          local y = Tr.y + math.sin(d * 0.35 - u * 20) * a * env
          if px and not in_hole(x, y) then line((1 + Tr.v * 5) * (1 - u) * (0.3 + env), px, py, x, y) end
          px, py = x, y
        end
      end
    end
    -- metal: sparks off the pipe
    for i = #pipesp, 1, -1 do
      local Ps = pipesp[i]
      local u = (K.T - Ps.t0) / 0.3
      if u >= 1 or Ps.y > tb then table.remove(pipesp, i)
      else
        for k = 0, 3 do
          local a = k * 1.3 + Ps.t0 * 7
          local r0, r1 = 4 + u * 4, 6 + u * 9
          line(9 * (1 - u) * Ps.v, BX + math.cos(a) * r0, Ps.y + math.sin(a) * r0 * 0.6,
            BX + math.cos(a) * r1, Ps.y + math.sin(a) * r1 * 0.6)
        end
      end
    end
    -- the depth log at the right: the phrase fills it, a tick on each bar
    local pl = math.max(1, math.floor(K.num(S.phrase_len, 16)))
    local phr = clamp((K.num(S.phrase_pos, 0) % pl + K.bar_ph) / pl, 0, 1)
    put(1.5 + amp * 2 + blk * 4, 126, 61 - phr * 58, 1, math.max(1, phr * 58))
    for k = 0, 7 do put(1.5 + blk * 2, 124, 3 + k * 8, 1, 1) end
    put(4 + blk * 7, 123, 60 - phr * 58, 5, 1)

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
          l = lv_scale * (2.2 + (p[3] + q[3] + 0.6) * 1.1)
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
    disc(1, cx, cy, 21 + e * 3 + lo * 2)
    disc(1 + lo * 0.6 + bite * 1.2 + e * 0.5, cx, cy, 11 + bite * 3)

    -- the stars streaming past, faster as it spins
    local sp = (8 + wmag * 6 + e * 10) * (1 - kl * 0.6)
    for _, st in ipairs(stars) do
      st.r = st.r + sp * st.s * (0.2 + st.r / 40) * K.DTS
      if st.r > 80 then st.r = 3 + K.rnd() * 6; st.a = K.rnd() * K.TAU end
      local ca, sa = math.cos(st.a), math.sin(st.a)
      local len = 1 + sp * 0.04 * st.s * (st.r / 30)
      line(0.8 + st.r / 60 + hi * 1.3, cx + ca * st.r, cy + sa * st.r * 0.6,
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
    ring(mid * 2.2, cx, cy, 24 + e * 3 + lo * 2, 20)

    -- the grid floor rolling toward us
    local HZ = 47
    grid_z = (grid_z + (0.25 + e * 0.5 + wmag * 0.06) * (1 - kl * 0.9) * K.DTS) % 1
    for i = -3, 3 do
      local qx = quake * math.sin(T * 47 + i) * 2
      line(1 + quake * 2, 64 + i * 10, HZ, 64 + i * 40 + qx, 64)
      -- studs rolling down each rail toward us
      for j = 0, 2 do
        local u = ((j + grid_z + K.hash(i, 71) * 0.3) / 3) % 1
        local uu = u * u
        put(1.5 + uu * 4 + bite * 3 + lo * 2, 64 + i * (10 + 30 * uu) - 1, HZ + 17 * uu, 2, 1)
      end
    end
    K.dashes(1 + lo * 1.5, HZ, 4, 9, -grid_z * 9)
    -- the shadow, breathing with the kick
    ring(2 + bite * 3, 64, 56, 16 + sc * 0.3, 16, 0, K.TAU, 0.18)

    -- chaos: frozen ghosts of poses the hits knocked it through, off to the sides
    local jit = c > 0.3 and (c - 0.3) * 0.3 or 0
    if c > 0.5 then
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
    -- the orbit: a tilted ring round it, the phrase a bead going round,
    -- each bar a flash on it
    local pl = math.max(1, math.floor(K.num(S.phrase_len, 16)))
    local phr = clamp((K.num(S.phrase_pos, 0) % pl + K.bar_ph) / pl, 0, 1)
    local orr = sc * 1.75 + A[K.AMP] * 3
    local tilt = 0.28 + 0.06 * math.sin(T * 0.3)
    ring(0.8 + A[K.AMP] * 0.5 + blk * 2, cx, cy, orr, 28, 0, math.pi, tilt)
    local ba = phr * K.TAU - math.pi / 2
    local bxp, byp = cx + math.cos(ba) * orr, cy + math.sin(ba) * orr * tilt
    disc(3 + blk * 6 + mid * 2, bxp, byp, 1.5 + blk)
    -- open hats: a halo ringing out
    if halo2 > 0.05 then ring(halo2 * 4, cx, cy, sc * 1.2 + (1 - halo2) * 18, 20) end

    local hf = (K.T - flash_t) < 0.3 and flash_f or -1
    solid(1 + bite * 0.25 + hi * 0.2, ax, ay, az, sc, cx, cy, ex, jit, hf)

    -- the near half of the orbit, in front of it
    ring(1 + A[K.AMP] * 0.8 + blk * 2.5, cx, cy, orr, 28, math.pi, K.TAU, tilt)
    -- closed hats glint a vertex
    for i = #glints, 1, -1 do
      local G = glints[i]
      local u = (K.T - G.t0) / 0.15
      if u >= 1 then table.remove(glints, i)
      else
        local p = P[G.i]
        if p then put((3 + G.v * 7) * (1 - u), p[1] - 0.5, p[2] - 0.5, 2, 2) end
      end
    end
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

  ---------------------------------------------------------------- view 3 draw
  -- the rig at night: the derrick over the hole, the string turning in the
  -- rotary table, a flare burning off at the side, and the ground cut away
  -- below so the bit shows working down through the strata
  local GY3 = 43                        -- the ground
  local FL3 = 36                        -- the rig floor
  local DX = 64                         -- the derrick's centre line
  local function leg(y)                 -- the derrick's half-width at y
    return 4 + (y - 3) / (FL3 - 3) * 12
  end

  local function draw_rig(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    local playing = K.playing
    bite = bite * math.exp(-DT / 0.1)
    spin = spin * math.exp(-DT / 0.9)
    heat = heat * math.exp(-DT / 1.2)
    local omega = ((playing and (1.5 + e * 3.5) or 0.6) + spin * 1.2) * (1 - kl * 0.6)
    rot3 = (rot3 + omega * K.DTS) % (K.TAU * 1000)
    -- the bit cuts on; the strata climb past it
    d3 = d3 + ((playing and (0.8 + e * 2.2 + spin * 0.3) or 0.15) * (1 - kl * 0.8)) * K.DTS
    local pl = math.max(1, math.floor(K.num(S.phrase_len, 16)))
    local phr = clamp((K.num(S.phrase_pos, 0) % pl + K.bar_ph) / pl, 0, 1)
    local sway = math.sin(T * 1.1) * c * 2.5 + math.sin(T * 0.3) * 0.4

    -- the sky: stars, a glow over the flare
    for i = 0, 19 do
      local x, y = math.floor(K.hash(i, 91) * 127), 1 + math.floor(K.hash(i, 92) * 26)
      local tw = 0.5 + 0.5 * math.sin(T * (0.5 + K.hash(i, 93)) + i * 1.7)
      put(0.6 + tw * (0.6 + hi * 2.5), x, y, 1, 1)
    end
    local fh = 6 + e * 5 + flare * 8 + lo * 2 - kl * 3
    local fx, fy = 12, 16
    local whip = math.sin(T * 2.3) * (1 + c * 4) + math.sin(T * 5.1) * c * 2
    local gr = 6 + fh * 0.5
    ring(1 + flare * 1.5 + amp, fx, fy - fh * 0.4, gr, 16, 0, K.TAU, 1, 1 + c, math.floor(T * 4))
    ring(1 + flare + amp * 0.5, fx, fy - fh * 0.4, gr + 4, 18, 0, K.TAU, 1, 1.5 + c, math.floor(T * 3) + 7)
    line(2.5, fx, fy, fx, GY3)
    line(2, fx - 2, GY3, fx, fy + 6)
    put(3, fx - 2, fy, 5, 1)
    for k = -2, 2 do
      local fl = math.sin(T * (9 + math.abs(k) * 3) + k) * 1.5
      local hh = fh * (1 - math.abs(k) * 0.25)
      local tipx = fx + whip * (hh / fh) + fl * 0.6
      line(math.min(13, 4 + flare * 5 + hi * 2 - math.abs(k) * 1.5), fx + k * 0.7, fy - 1, tipx, fy - hh)
    end
    K.grain(function(u, v) return fx + whip + (u - 0.5) * 6, fy - fh - v * 8 end, 2 + hi * 10 + flare * 20, 4 + hi * 4)

    -- the ground: cut away below, the strata in broken runs; the bit works
    -- down through them over the phrase
    local off = 40
    for y = GY3 + 2, 63 do
      local lv = math.min(1, row_level(y + off, 0))
      if lv > 0 then
        local x = -math.floor(K.hash(y, 71) * 20)
        while x < 128 do
          local w = 8 + math.floor(K.hash(x + y * 131, 72) * 22)
          local a, b = math.max(0, x), math.min(128, x + w)
          if b > a and (a > DX + 3 or b < DX - 3) then put(lv, a, y, b - a, 1)
          elseif b > a then
            if a < DX - 3 then put(lv, a, y, DX - 3 - a, 1) end
            if b > DX + 3 then put(lv, DX + 4, y, b - DX - 4, 1) end
          end
          x = x + w + 3 + math.floor(K.hash(x + y * 17, 73) * 8)
        end
      end
    end
    line(1.5 + lo * 0.8 + bite, 0, GY3, 127, GY3)
    K.dashes(1 + mid * 1.5, GY3 + 1, 3, 7, 0)
    -- seams crossing the cut
    for cc = layer_of(GY3 + off) + 1, layer_of(63 + off) do
      local yy = boundary(cc) - off
      if yy > GY3 + 1 and yy < 63 then
        line(1 + mid * 1.3 + lo * 0.5, 0, yy, DX - 3, yy + math.sin(cc) * 2)
        line(1 + mid * 1.3 + lo * 0.5, DX + 3, yy - math.sin(cc) * 2, 127, yy)
      end
    end
    -- the hole and the bit at its foot, glowing with the bite and the lows
    local bit_y = GY3 + 5 + (playing and phr or (0.5 + 0.5 * math.sin(T * 0.1))) * (60 - GY3 - 5)
    line(2 + lo, DX - 3, GY3 + 1, DX - 3, bit_y)
    line(2 + lo, DX + 3, GY3 + 1, DX + 3, bit_y)
    line(3 + lo, DX, FL3, DX, bit_y - 2)
    local hot = math.min(1, heat + spin / 14)
    disc(1.5 + lo * 2.5 + bite * 2 + hot * 2, DX, bit_y, 2.5 + lo * 1.5)
    put(math.min(13, 6 + bite * 6 + hot * 3), DX - 1, bit_y - 1, 2, 2)
    for i = #rings, 1, -1 do
      local R = rings[i]
      local u = (K.T - R.t0) / 0.45
      if u >= 1 then table.remove(rings, i)
      else ring((2 + R.v * 3.5) * (1 - u) ^ 1.3, DX, bit_y, 5 + u * 30, 18, math.pi, K.TAU, 0.5) end
    end
    -- snares: a crack off the face, and mud kicked out over the shaker
    for i = #spurts, 1, -1 do
      local Sp = spurts[i]
      local age = K.T - Sp.t0
      if age > 1.2 then table.remove(spurts, i)
      else
        local u = age / 1.2
        local dir = (Sp.seed % 2 == 0) and 1 or -1
        local px, py = DX + dir * 3, bit_y - 2
        for j = 1, 4 do
          local x = DX + dir * (3 + j * 6 + (Sp.n or 1) * 2)
          local y = bit_y - 2 + (K.hash(Sp.seed + j, 5) - 0.5) * 6
          line((2 + Sp.v * 5) * (1 - u), px, py, x, y)
          px, py = x, y
        end
        for k = 0, 4 do
          local a = age * 1.6
          local vx = (K.hash(Sp.seed + k, 6) - 0.3) * 30
          local x = 104 + vx * a
          local y = GY3 - 6 - (25 + k * 6) * a + 40 * a * a
          if y < GY3 then put((3 + Sp.v * 6) * (1 - u), x, y, 1, 1) end
        end
      end
    end

    -- the derrick: two legs, girts and braces, swaying a touch with chaos
    local lw = 2 + mid * 2 + amp
    local function at(y, side) return DX + side * leg(y) + sway * (FL3 - y) / FL3 end
    line(lw, at(FL3, -1), FL3, at(3, -1), 3)
    line(lw, at(FL3, 1), FL3, at(3, 1), 3)
    local prev
    for y = 4, FL3, 8 do
      line(lw * 0.8, at(y, -1), y, at(y, 1), y)
      if prev then
        line(lw * 0.5, at(prev, -1), prev, at(y, 1), y)
        line(lw * 0.5, at(prev, 1), prev, at(y, -1), y)
      end
      prev = y
    end
    -- the crown light: a slow red beacon
    local bc = 0.5 + 0.5 * math.sin(T * 1.6)
    put(2 + bc * 5 + amp, at(2, 0) - 1, 1, 3, 2)
    -- the stands racked in the derrick: one more each bar
    for k = 0, bars % 8 do
      local x = at(30, 1) - 3 - k * 1.2
      line(1.5 + blk * (k == bars % 8 and 6 or 0), x, FL3 - 1, x - 2 + sway * 0.6, 9)
    end
    -- the travelling block going down a stand over two bars, the cables
    local tb = 6 + ((bars % 2) + K.bar_ph) / 2 * 22 + bite * 1.5
    if not playing then tb = 6 + (0.5 + 0.5 * math.sin(T * 0.2)) * 22 end
    local tx = at(tb, 0)
    line(1.5, at(3, 0) - 1, 4, tx - 1, tb)
    line(1.5, at(3, 0) + 1, 4, tx + 1, tb)
    put(3 + mid * 2 + bite * 3, tx - 2, tb, 5, 3)
    line(3 + lo + bite * 2, tx, tb + 3, DX, FL3)
    -- the rig floor and the rotary table, turning
    line(2.5 + amp, 36, FL3, 92, FL3)
    for k = 0, 3 do line(2, 40 + k * 16, FL3 + 1, 40 + k * 16, GY3) end
    line(1.5, 40, FL3 + 1, 56, GY3)
    line(1.5, 88, FL3 + 1, 72, GY3)
    ring(3 + bite * 5 + hot * 3, DX, FL3 - 1, 7, 14, 0, K.TAU, 0.3)
    for k = 0, 3 do
      local a = rot3 + k * math.pi / 2
      if math.sin(a) > -0.3 then
        put(4 + bite * 5 + hot * 3, DX + math.cos(a) * 6, FL3 - 1 + math.sin(a) * 1.8, 1, 1)
      end
    end
    -- the floodlights, washing the floor (hats flicker them)
    local fl = (1 + amp * 1.5 + mid * 1.5 + e * 0.5) * (1 - flick * 0.4 * (0.5 + 0.5 * math.sin(T * 31)))
    for side = -1, 1, 2 do
      local lx, ly = at(16, side), 16
      put(math.min(12, 3 + fl * 2), lx - 1, ly, 2, 1)
      for r = 0, 3 do
        line(fl * (0.8 - r * 0.15), lx, ly + 1, lx - side * (2 + r * 5), FL3 - 1)
      end
    end
    -- the drawworks house on the left, the engines and their stacks on the right
    line(2, 24, 30, 36, 30)
    line(2, 24, 30, 24, GY3)
    put(1.5 + mid * 2, 27, 33, 3, 2)
    put(1.5 + mid * 2 + bite * 2, 31, 33, 3, 2)
    line(2, 96, 32, 112, 32)
    line(2, 112, 32, 112, GY3)
    line(2, 96, 32, 96, GY3)
    for k = 0, 1 do
      local sx = 100 + k * 8
      line(2, sx, 32, sx, 26)
    end
    -- exhaust: always a little, a puff on open hats, steady when kickless
    for k = 0, 1 do
      local sx = 100 + k * 8
      for q = 0, 2 do
        local u = (T * (0.4 + e * 0.4) + q / 3 + k * 0.5) % 1
        ring((1 + kl * 1.2 + lo * 0.8) * (1 - u), sx + u * 6, 25 - u * 16, 1 + u * 4, 8)
      end
    end
    for i = #puffs3, 1, -1 do
      local Pf = puffs3[i]
      local u = (K.T - Pf.t0) / 1.2
      if u >= 1 then table.remove(puffs3, i)
      else disc((1.5 + Pf.v * 3) * (1 - u) + 0.4, 100 + Pf.k * 8 + u * 8, 24 - u * 18, 1.5 + u * 5) end
    end
    -- the mud pit by the engines, its surface glinting with the highs
    line(2, 114, GY3 - 3, 126, GY3 - 3)
    for k = 0, 5 do
      put(0.8 + hi * 3 * (0.5 + 0.5 * math.sin(T * 5 + k * 2)), 115 + k * 2, GY3 - 2, 1, 1)
    end
    -- the phrase: the depth readout lamps along the floor's edge
    for k = 0, 7 do
      local on = k < phr * 8
      put(on and (2 + blk * 4 + amp) or 1, 38 + k * 3, FL3 + 2, 2, 1)
    end
    -- kickless: a ground fog over everything
    K.haze(0, GY3 - 8, 128, GY3 + 3, 0.15 + kl * 0.5 + e * 0.1, 1 + kl, T * 3)
  end

  function M.draw(S)
    blk = blk * math.exp(-K.DT / 0.35)
    flare = flare * math.exp(-K.DT / 0.9)
    flick = flick * math.exp(-K.DT / 0.12)
    quake = quake * math.exp(-K.DT / 0.25)
    halo2 = halo2 * math.exp(-K.DT / 0.3)
    GAIN = K.view == 1 and 1 or 0.88
    if K.view == 2 then draw_solid(S) elseif K.view == 3 then draw_rig(S) else draw_bore(S) end
  end

  M.init()
  return M
end
