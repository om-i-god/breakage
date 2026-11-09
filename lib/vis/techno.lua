-- techno. view 1: a motorway at night in one-point perspective: gantries and sodium lamps rush at you, cats' eyes tick past on the 16ths.
-- view 2: a city grid at night from high above: signals change in sequence with the steps, light trails stream down the avenues.
--
-- view 1: we drive at one cat's eye per 16th; the kick surges the road
-- forward and blooms the city glow on the horizon; rimshots flash the lane
-- markings; the ride glints along the gantry beams; clave / metal / cowbell
-- light the gantry signs; the snare and clap brake the cars ahead (their
-- tail lights flare); hats glint the cats' eyes; ticks blink the radio mast;
-- break slices change lanes; a ratchet sends a run of eyes rushing at us;
-- a fill lights every sign and lamp. energy lights more lamps and puts more
-- cars on the road; chaos splits every lane line in two, doubles the lamps
-- and opens a second carriageway of oncoming headlights; kickless, the drive
-- slows to a crawl and the fog comes down.
-- view 2: each 16th flips the signals on one diagonal of the grid, a wave
-- that sweeps the city every bar; hats send light trails streaming along the
-- avenues (open hats and rides, long ones across the streets); the kick
-- pulses every road at once; the snare sends a wave of light out through the
-- streets from one crossing; perc lights a rooftop beacon; ticks blink the
-- plane overhead; ratchets send a convoy. energy lights the windows and the
-- traffic; chaos shears the grid along fault lines and cuts diagonal
-- avenues through it; kickless, low cloud drifts over and the city dims.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local floor, sin, cos, exp, max, min, abs = math.floor, math.sin, math.cos, math.exp, math.max, math.min, math.abs

  local TH8 = {0, 4, 2, 6, 1, 5, 3, 7}
  -- one dithered row at value v (levels, fractional part ordered-dithered)
  local function drow(v, y, x0, x1)
    if not (v > 0.05) then return end
    y = floor(y)
    local th = (TH8[y % 8 + 1] + 0.5) / 8
    local l
    if v < 1 then l = (v > th) and 1 or 0
    else
      l = floor(v)
      if v - l > th then l = l + 1 end
    end
    if l <= 0 then return end
    x0, x1 = max(0, floor(x0)), min(128, floor(x1))
    if x1 > x0 then put(l, x0, y, x1 - x0, 1) end
  end

  ---------------------------------------------------------------- view 1
  local VX, VY = 64, 22               -- the vanishing point
  local F = 41                        -- focal scale: road y = VY + F / z
  local ZN, ZF = 0.9, 36
  local EYE, DASH, LAMP, GANT = 0.5, 2, 4, 18
  local RW = 2.1                      -- the carriageway's half width
  local LANES = {-1.05, 0, 1.05}      -- the dashed lines
  local CARL = {-1.57, -0.52, 0.52, 1.57}

  local SKY = K.profile(function(x)
    local h = 1 + floor(K.hash(x // 6, 41) * 5)
    if K.hash(x // 6, 42) > 0.78 then h = h + 3 + floor(K.hash(x // 6, 43) * 4) end
    if x > 96 and x < 106 then h = h + 2 end
    local d = abs(x - VX)
    if d < 12 then h = min(h, 1 + d // 4) end
    return VY - h
  end)

  local drive, surge, camx, camx_to, cam
  local ratf, rimf, ridef, ride_x, percf, brake, fillf, beacon, bloom, blooms, hatf
  local bursts
  local lane_t = -99
  local fd = 14                       -- this frame's fog depth

  ---------------------------------------------------------------- view 2
  local AV, ST = 24, 16               -- avenue / street spacing, px
  local trails, waves, tops
  local ox, oy, planef, gpulse, gps, flip
  local MAXT = 14
  local los = 0

  function M.init()
    drive, surge, camx, camx_to, cam = 0, 0, 0, 0, 0
    ratf = 0
    rimf, ridef, ride_x, percf, brake, fillf, beacon, bloom, blooms, hatf = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    bursts = {}
    lane_t = -99
    trails, waves, tops = {}, {}, {}
    ox, oy, planef, gpulse, gps, flip = 8, 4, 0, 0, 0, 0
    los = 0
  end
  M.clear = M.init

  local function fog(z) return exp(-z / fd) end

  -- world (x across, h up, z ahead) to screen
  local function proj(x, h, z)
    local s = F / z
    return VX + (x - cam) * s, VY + (1 - h) * s, s
  end

  ---------------------------------------------------------------- events
  -- (view 2) a light trail along avenue / street gi, from world pos p0
  local function trail(axis, gi, p0, dir, sp, len, lv, delay)
    if #trails >= MAXT then table.remove(trails, 1) end
    trails[#trails + 1] = {axis = axis, gi = gi, p0 = p0, dir = dir, sp = sp, len = len, lv = lv,
      t0 = K.T + (delay or 0), life = 1.1 + K.rnd() * 0.5}
  end
  local function rand_trail(axis, lv, len, sp, delay, gi)
    local dir = K.rnd() < 0.5 and -1 or 1
    if axis == 1 then
      gi = gi or (floor(ox / AV) + floor(K.rnd() * 6))
      trail(1, gi, oy + (dir > 0 and -10 or 74), dir, sp, len, lv, delay)
    else
      gi = gi or (floor(oy / ST) + 1 + floor(K.rnd() * 4))
      trail(2, gi, ox + (dir > 0 and -10 or 138), dir, sp, len, lv, delay)
    end
  end

  function M.kick(v)
    v = K.num(v, 1)
    surge = surge + 2.8 * v
    bloom = max(bloom, 0.6 + 0.4 * v)
    gpulse = max(gpulse, 0.6 + 0.4 * v)
  end

  function M.snare(v)
    v = K.num(v, 1)
    brake = max(brake, 0.6 + 0.4 * v)
    if #waves >= 5 then table.remove(waves, 1) end
    waves[#waves + 1] = {ci = floor(ox / AV) + 1 + floor(K.rnd() * 4), cj = floor(oy / ST) + 1 + floor(K.rnd() * 3),
      t0 = K.T, lv = 0.6 + 0.4 * v}
  end
  function M.clap(v)
    v = K.num(v, 1)
    brake = max(brake, 0.5 * v + 0.3)
    gpulse = max(gpulse, 0.3 * v)
  end

  function M.rim(v)
    v = K.num(v, 1)
    rimf = max(rimf, 0.5 + 0.5 * v)
    flip = max(flip, 0.6 * v)
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    hatf = max(hatf, 0.4 + 0.6 * v)
    if open then rand_trail(2, 7 + 4 * v, 40, 80)
    else rand_trail(1, 6 + 4 * v, 22 + 10 * v, 95 + K.chaos * 40) end
  end

  function M.ride(v)
    v = K.num(v, 1)
    ridef = max(ridef, 0.5 + 0.5 * v)
    ride_x = K.rnd() * 2 - 1
    rand_trail(2, 4 + 3 * v, 30, 55)
  end
  function M.shaker(v) M.hat(K.num(v, 1) * 0.6, false) end

  function M.perc(kind, v)
    v = K.num(v, 1)
    percf = max(percf, (kind == 4 or kind == 6 or kind == 3) and (0.5 + 0.5 * v) or 0.5 * v)
    if #tops >= 6 then table.remove(tops, 1) end
    tops[#tops + 1] = {gi = floor(ox / AV) + floor(K.rnd() * 6), gj = floor(oy / ST) + floor(K.rnd() * 5),
      t0 = K.T, lv = 0.5 + 0.5 * v}
  end
  function M.tom(v) M.perc(7, v) end

  function M.tick()
    beacon = 1
    planef = 1
  end

  function M.brk(s, n)
    s, n = K.num(s, 1), max(1, K.num(n, 8))
    local u = n > 1 and (s - 1) / (n - 1) or 0.5
    if K.NOW - lane_t > K.beat_sec * 2 then
      camx_to = (floor(u * 3.99) - 1.5) * 1.05
      lane_t = K.NOW
    end
    rand_trail(1, 5, 12, 100, 0, floor(ox / AV) + floor(u * 5.99))
  end

  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    if #bursts >= 4 then table.remove(bursts, 1) end
    bursts[#bursts + 1] = {t0 = K.T, n = n}
    ratf = 1
    local gi = floor(ox / AV) + floor(K.rnd() * 6)
    for k = 0, min(n, 8) - 1 do rand_trail(1, 8 - k * 0.5, 8, 110, k * 0.05, gi) end
  end

  function M.fill()
    fillf = 1
    flip = 1
  end

  ---------------------------------------------------------------- view 1 drawing
  local function lamp(x, z, side, lv, near_hi)
    local x0, y0, s = proj(x, 0, z)
    local x1, y1 = proj(x, 2.3, z)
    local xa, ya = proj(x - side * 0.55, 2.3, z)
    local f = fog(z) * clamp((z - 1) / 1.2, 0, 1)
    line((1 + 1.5 * f) * (0.6 + 0.4 * lv), x0, y0, x1, y1)
    line((1 + 2 * f) * (0.6 + 0.4 * lv), x1, y1, xa, ya)
    if lv <= 0 then return end
    local hw = max(1, s * 0.2)
    local hh = max(1, s * 0.06)
    put(min(12, (3 + 7 * f + near_hi + A[K.MID] * 3) * lv), xa - hw / 2, ya, hw, hh)
    if z < 9 then
      local gw = hw + 2 + K.kickless * 2
      put((1 + f + K.kickless) * lv, xa - gw / 2, ya - 1, gw, hh + 2)
      -- the sodium pool on the road under it
      local px = x - side * 0.75
      for k = -3, 3 do
        local zz = z + k * 0.24
        if zz > 0.95 then
          local cx, cy, ss = proj(px, 0, zz)
          local hw2 = 0.85 * ss * math.sqrt(max(0, 1 - (k / 3.6) ^ 2))
          put((0.7 + 0.6 * K.energy + A[K.MID] * 2.2) * lv * f, cx - hw2, cy, hw2 * 2, 1)
        end
      end
    end
  end

  local function gantry(z, e, c)
    local f = fog(z)
    local near = clamp((z - 1.8) / 2, 0, 1)
    local lv = (1.5 + 2.5 * f + e) * near
    for side = -1, 1, 2 do
      local x0, y0 = proj(side * 2.6, 0, z)
      local x1, y1 = proj(side * 2.6, 2.05, z)
      line(lv * 0.8, x0, y0, x1, y1)
    end
    local ax, ay, s = proj(-2.6, 2.05, z)
    local bx = proj(2.6, 2.05, z)
    line(lv, ax, ay, bx, ay)
    local _, ay2 = proj(0, 1.97, z)
    line(lv * 0.7, ax, ay2, bx, ay2)
    -- the ride: a glint running along the beam
    if ridef > 0.05 then
      local gx = proj(ride_x * 2.4, 2.05, z)
      put(min(13, (3 + 9 * ridef) * (0.4 + 0.6 * f) * near), gx - 1, ay - 1, 3, 1)
      put(min(9, (2 + 6 * ridef) * f * near), gx, ay - 2, 1, 3)
    end
    -- the signs: dark panels with a line of lit text
    local sl = 0.6 + percf * 0.7 + fillf
    for k = -1, 1, 2 do
      local xa, ya = proj(k * 0.25, 1.92, z)
      local xb, yb = proj(k * 1.55, 1.38, z)
      if xa > xb then xa, xb = xb, xa end
      line(lv * 0.9, xa, ya, xb, ya)
      line(lv * 0.9, xa, yb, xb, yb)
      line(lv * 0.9, xa, ya, xa, yb)
      line(lv * 0.9, xb, ya, xb, yb)
      if s < 14 then put(1, xa + 1, ya + 1, xb - xa - 1, yb - ya - 1) end
      local ty = ya + (yb - ya) * 0.35
      local tl = (1.5 + 3 * sl + c * 2 * sin(K.T * 9 + k) + A[K.HI] * 1.5) * (0.4 + 0.6 * f) * near
      K.dashes(tl, ty, max(1, floor(s * 0.06)), max(2, floor(s * 0.1)), k * 3, xa + 2, xb - 1)
      if s > 8 then
        K.dashes(tl * 0.7, ty + max(2, s * 0.12), max(1, floor(s * 0.05)), max(2, floor(s * 0.08)), k * 5, xa + 2, xb - s * 0.2)
      end
    end
  end

  local function draw1(S)
    local T, DT, DTS = K.T, K.DT, K.DTS
    local e, c, kl = K.energy, K.chaos, K.kickless
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    fd = 12 + 10 * e - 7 * kl
    -- the drive: one cat's eye per 16th, the kick surging it on
    local base = K.playing and (EYE / max(0.05, K.beat_sec / 4)) or 1.4
    base = base * (1 - 0.65 * kl)
    drive = drive + (base + surge) * DTS
    local dc = clamp(K.follow(camx, camx_to, 0.6, DT) - camx, -0.7 * DT, 0.7 * DT)
    camx = camx + dc
    camx_to = camx_to * exp(-DT / 6)
    cam = camx + c * 0.22 * sin(T * 0.6) + 0.05 * sin(T * 0.37)
    local g = blooms

    -- the sky: city glow on the horizon behind a skyline, a few stars
    for i = 0, 11 do
      local x, y = floor(K.hash(i, 1) * 127), 1 + floor(K.hash(i, 2) * 11)
      local tw = 0.5 + 0.5 * sin(T * (0.4 + K.hash(i, 3)) + i * 2.1)
      put((1 + tw * (0.5 + hi * 3)) * (1 - kl * 0.6), x, y, 1, 1)
    end
    K.gradient(VY - 9, VY, function(y)
      local u = (y - VY + 9) / 9
      return 0.15 + u * u * (0.9 + A[K.AMP] * 0.8 + e * 0.6 + g * 1.8 + lo * 0.4 + mid * 1.6) + kl * 0.4
    end, SKY)
    for i = 0, 7 do
      local x = floor(K.hash(i, 31) * 124) + 2
      local y = floor(K.at(SKY, x) + 1 + K.hash(i, 32) * 3)
      if y < VY - 1 then put(1.5 + e * 2 + sin(T * 0.3 + i) ^ 2, x, y, 1, 1) end
    end
    -- the radio mast and its blinking light
    line(1.5, 101, VY - 3, 101, VY - 15)
    line(1, 99, VY - 3, 101, VY - 12)
    put(min(12, 2 + beacon * 9 + 2 * (0.5 + 0.5 * sin(T * 1.3))), 100, VY - 16, 3, 1)

    -- the road: black asphalt, our headlights pooled ahead (the kick
    -- surges them), a faint sheen toward us
    for y = VY + 1, 63 do
      local s = y - VY
      local u = s / F
      local cx = VX - cam * s
      if s > 5 then
        local hw = s * (0.4 + 0.3 * u)
        local fade = clamp((s - 5) / 10, 0, 1)
        drow(min(0.9, fade * (0.2 + 0.4 * g + 0.15 * e + 0.4 * lo) * (1 - 0.4 * kl)), y, VX - hw, VX + hw)
      end
    end
    -- the hard shoulders, solid, fading into the fog
    for side = -1, 1, 2 do
      local zs = {ZN, 3, 8, ZF}
      for k = 1, 3 do
        local xa, ya = proj(side * RW, 0, zs[k])
        local xb, yb = proj(side * RW, 0, zs[k + 1])
        line((2 + 4 * fog(zs[k])) * (1 + rimf * 0.4) + hi * 3, xa, ya, xb, yb)
      end
    end

    -- the lane markings: dashes rushing at us, split in two by chaos
    local split = c * 0.3
    local pd = drive % DASH
    for li = 1, #LANES do
      for half = -1, 1, 2 do
        if half == -1 or split > 0.04 then
          local lx = LANES[li] + (split > 0.04 and half * split * (0.7 + 0.3 * sin(T * 0.8 + li * 2)) or 0)
          for k = 0, 17 do
            local z0 = k * DASH + DASH - pd + 0.4
            local z1 = z0 + 0.9
            if z0 > 0.9 and z0 < ZF then
              local xa, ya = proj(lx, 0, z0)
              local xb, yb = proj(lx, 0, z1)
              line((1.5 + 3 * fog(z0) + (rimf * 7 + ratf * 5) * fog(z0 * 0.5) + e + hi) * (split > 0.04 and 0.8 or 1), xa, ya, xb, yb)
            end
          end
        end
      end
    end

    -- the cats' eyes: one row passes per 16th; hats glint them
    local pe = drive % EYE
    for k = 0, 22 do
      local z = k * EYE + EYE - pe + 0.6
      local gi = floor((drive + z) / EYE + 0.5)
      local f = fog(z)
      local u = 1 / z
      local bl = 0
      for b = 1, #bursts do
        local B = bursts[b]
        local front = 12 - (T - B.t0) * 22
        local d = abs(z - front)
        local bw = 0.6 + B.n * 0.25
        if d < bw then bl = max(bl, 9 * (1 - d / bw)) end
      end
      local lv = (2.5 + 6 * u + hatf * 5 * u + hi * 4) * f + bl * f
      for li = 0, #LANES + 1 do
        local lx = li == 0 and -RW + 0.08 or (li > #LANES and RW - 0.08 or LANES[li])
        if li > 0 and li <= #LANES and split > 0.04 then lx = lx + split * 0.7 end
        local x, y, s = proj(lx, 0, z)
        local edge = (li == 0 or li > #LANES)
        local w = (s > 20 or bl > 2) and 2 or 1
        if (gi + li) % 2 == 0 or not edge then put(min(12, edge and lv * 0.6 or lv), x - w / 2, y - (w - 1), w, w) end
      end
    end

    -- the cars ahead: tail lights, braking on the snare
    local ncar = 1 + floor(e * 2.5 + 0.3)
    for i = 1, ncar do
      local z = 5 + 6 * i + 2.5 * sin(T * (0.11 + 0.05 * i) + i * 2) - min(3, surge * 0.3)
      local lx = CARL[(i * 3) % 4 + 1]
      local x, y, s = proj(lx, 0, z)
      local f = fog(z)
      local w = max(2, s * 0.75)
      local h = max(1, s * 0.35)
      put(1 + f, x - w / 2, y - h, w, h)
      local tl = min(12, (3 + 4 * f + brake * 7 * (0.4 + 0.6 * f)))
      local tw = max(1, s * 0.12)
      put(tl, x - w / 2, y - h * 0.6, tw, 1)
      put(tl, x + w / 2 - tw, y - h * 0.6, tw, 1)
      if brake > 0.15 then
        put(brake * 4 * f, x - w / 2 - 1, y + 1, w + 2, 1)          -- the glow on the road
      end
    end

    -- the oncoming carriageway (chaos): headlights in pairs
    if c > 0.35 then
      local cl = (c - 0.35) / 0.65
      for side = -1, 1, 2 do
        local xa, ya = proj(side * (RW + 1.2), 0, ZN)
        local xb, yb = proj(side * (RW + 1.2), 0, ZF)
        line(1 + 2 * cl, xa, ya, xb, yb)
      end
      for i = 0, 3 do
        local z = ((i * 7.3 - drive * 1.8) % 26) + 1.2
        local x, y, s = proj(-(RW + 2.2), 0, z)
        local hl = min(12, (3 + 6 / z * 3) * cl * fog(z))
        local w = max(1, s * 0.1)
        put(hl, x - s * 0.3, y - s * 0.2, w, 1)
        put(hl, x + s * 0.3, y - s * 0.2, w, 1)
      end
    end

    -- the sodium lamps both sides; energy lights more of them, chaos doubles them
    local pl = drive % LAMP
    local litfrac = 0.3 + 0.4 * e + 0.4 * A[K.AMP]
    for k = 0, 9 do
      local z = k * LAMP + LAMP - pl + 0.5
      if z > 0.95 and z < ZF then
        local gi = floor((drive + z) / LAMP + 0.5)
        for side = -1, 1, 2 do
          local on = K.hash(gi * 2 + (side + 1) / 2, 51) < litfrac and 1 or 0.25
          on = on * (1 + fillf * 0.4)
          lamp(side * 2.75, z, side, on, ridef * 2)
          if c > 0.2 then
            local cz = z + LAMP * 0.5
            if cz < ZF then lamp(side * (2.75 + c * 1.2), cz, side, on * c, 0) end
          end
        end
      end
    end

    -- the gantries
    local pg = drive % GANT
    for k = 0, 1 do
      local z = k * GANT + GANT - pg + 1.2
      if z > 1.1 and z < ZF then gantry(z, e, c) end
    end

    -- fog: a bank on the horizon, and kickless the whole road goes under
    K.haze(0, VY - 5, 128, VY + 7, 0.18 + 0.5 * kl + 0.1 * e, 1 + mid * 1.6, drive * 2)
    if kl > 0.1 then K.haze(0, VY + 6, 128, 50, 0.4 * kl, 1, drive * 3 + 40) end
    K.grain(function(u, v) return u * 128, VY - 6 + v * 12 end, 2 + hi * 8 + e * 4, 2 + hi * 3)
  end

  ---------------------------------------------------------------- view 2 drawing
  -- the fault-line shift of street band j (chaos shears the grid)
  local function shift(j, c)
    if c < 0.05 then return 0 end
    return floor(c * 9 * sin(j * 1.9 + K.T * 0.15) + 0.5)
  end

  -- the river winding across the city (screen space: the camera hovers)
  local function riv(x) return 41 + 7 * sin(x * 0.03 + 0.6) end
  local RH = 4                          -- its half width

  -- a building seen from high above: the roof leans away from the nadir,
  -- the walls facing us show their floors and lit windows
  local function tower(bx0, bx1, by0, by1, ht, e, gi, gj)
    local mx, my = (bx0 + bx1) / 2, (by0 + by1) / 2
    if ht < 0.45 then
      -- low-rise: dark, a couple of lit rooftops
      for w = 0, 1 do
        local u, v = K.hash(gi * 3 + w, gj * 7 + 5), K.hash(gi * 5 + w, gj * 3 + 6)
        if v < 0.25 + 0.35 * e + 0.4 * A[K.AMP] then
          put(1.5 + e * 1.5 + w, bx0 + (bx1 - bx0 - 2) * u, by0 + (by1 - by0 - 1) * v, 2, 1)
        end
      end
      return
    end
    local k = (ht - 0.35) * 0.4
    local dx, dy = (mx - 64) * k, (my - 32) * k
    local rx0, rx1, ry0, ry1 = bx0 + dx + 1, bx1 + dx - 1, by0 + dy + 1, by1 + dy - 1
    local rl = 1 + ht * 1.6 + e * 0.5 + gps * ht * 0.5 + A[K.MID] * 1.5
    local rh = 0.8 + ht * 0.9
    line(rh, rx0, ry0, rx1, ry0)
    line(rh, rx0, ry1, rx1, ry1)
    line(rl, rx0, ry0, rx0, ry1)
    line(rl, rx1, ry0, rx1, ry1)
    bx0, bx1, by0, by1 = bx0 + 1, bx1 - 1, by0 + 1, by1 - 1
    -- the wall facing the nadir across x, and across y: floor lines
    local wx = dx > 0 and bx0 or bx1
    local rwx = dx > 0 and rx0 or rx1
    local wy = dy > 0 and by0 or by1
    local rwy = dy > 0 and ry0 or ry1
    local nf = abs(dx) > 3 and 2 or (abs(dx) > 1.5 and 1 or 0)
    for f = 1, nf do
      local u = f / (nf + 1)
      line(1, wx + (rwx - wx) * u, by0 + dy * u, wx + (rwx - wx) * u, by1 + dy * u)
    end
    local nf2 = 0
    for f = 1, nf2 do
      local u = f / (nf2 + 1)
      line(1, bx0 + dx * u, wy + (rwy - wy) * u, bx1 + dx * u, wy + (rwy - wy) * u)
    end
    line(1, wx, wy, rwx, rwy)
    -- lit windows on those walls, more with energy
    local nw = floor((0.15 + e * 0.6 + A[K.AMP] * 0.6) * 4 * K.hash(gi + gj * 13, 62) + 0.5)
    for w = 1, nw do
      local u = 0.2 + 0.6 * K.hash(gi * 3 + w, gj * 7 + 1)
      local v = K.hash(gi * 5 + w, gj * 3 + 2)
      local wl = 2 + e * 2.5 + 1.5 * sin(K.T * 0.2 + gi + gj + w) ^ 2
      if w % 2 == 0 then
        put(wl, wx + (rwx - wx) * u, by0 + (by1 - by0) * v + dy * u, 1, 1)
      else
        put(wl, bx0 + (bx1 - bx0) * v + dx * u, wy + (rwy - wy) * u, 1, 1)
      end
    end
  end

  local function draw2(S)
    local T, DT, DTS = K.T, K.DT, K.DTS
    local e, c, kl = K.energy, K.chaos, K.kickless
    local lo, hi = A[K.LO], A[K.HI]
    -- (the camera hovers still: the city moves, not the view)
    local clk = K.playing and K.stepf or T * 2.5
    los = K.follow(los, lo, 0.15, DT)
    local roadl = (1.2 + gps * 1.1 + e * 0.6 + los * 0.6) * (1 - 0.35 * kl)
    local i0, j0 = floor(ox / AV) - 1, floor(oy / ST) - 1

    -- the street bands, top to bottom: streets, avenues, blocks, signals
    for j = j0, j0 + 6 do
      local y0 = j * ST - oy
      local y1 = y0 + ST
      if y1 >= 0 and y0 <= 63 then
        local sh = shift(j, c)
        -- the street, broken where it meets the river
        local run
        for x = 0, 128, 4 do
          local wet = x < 128 and abs(y0 - riv(x)) < RH + 1
          if not wet and x < 128 then run = run or x
          elseif run then line(roadl * 0.5, run, y0, x - 1, y0); run = nil end
        end
        for i = i0, i0 + 7 do
          local x = i * AV - ox + sh
          if x > -AV and x < 128 + AV then
            line(roadl, x, y0 + 1, x, y1 - 1)
            put(roadl * 1.4, x, y0 + 5, 1, 1); put(roadl * 1.4, x, y0 + 10, 1, 1)
            local h = K.hash(i * 97 + j, 61)
            local mx = x + AV / 2
            if abs(y0 + ST / 2 - riv(mx)) < RH + ST / 2 - 1 then
              -- (the block is on the water: no building)
            elseif h < 0.16 then
              for t = 0, 3 do                                   -- a park
                put(1 + (t % 2), x + 5 + floor(K.hash(i * 7 + t, j + 3) * (AV - 12)),
                  y0 + 4 + floor(K.hash(j * 5 + t, i + 9) * (ST - 9)), 2, 2)
              end
            elseif K.hash(i * 31 + j, 64) < 0.45 then
              tower(x + 3, x + AV / 2 - 1, y0 + 3, y1 - 3, K.hash(i * 5 + j, 65), e, i * 2, j)
              tower(x + AV / 2 + 1, x + AV - 3, y0 + 3, y1 - 3, K.hash(i * 9 + j, 66), e, i * 2 + 1, j)
            else
              tower(x + 3, x + AV - 3, y0 + 3, y1 - 3, (h - 0.16) / 0.84, e, i * 2, j)
            end
          end
        end
        -- the signals at each crossing on this street: a diagonal flips per 16th
        for i = i0, i0 + 7 do
          local x = i * AV - ox + sh
          if x >= -2 and x <= 130 and y0 >= -2 and y0 <= 66 then
            local q = (clk - (i + j)) / 4
            local ph = floor(q) % 2
            local just = q - floor(q)
            local fl = max(0, 1 - just * 2.5)
            fl = fl * fl
            local wv = 0
            for w = 1, #waves do
              local W = waves[w]
              local age = T - W.t0
              local d = abs(i - W.ci) + abs(j - W.cj)
              local fr = age * 7
              local b = 1 - abs(d - fr) / 1.3
              if b > 0 then wv = max(wv, b * W.lv * max(0, 1 - age / 1.6)) end
            end
            local gl = min(12, 3 + 6 * fl + wv * 6 + flip * 3 + hi * 1.5)
            if ph == 0 then put(gl, x, y0 - 2, 1, 5); put(2, x - 2, y0, 1, 1)
            else put(gl, x - 2, y0, 5, 1); put(2, x, y0 - 2, 1, 1) end
            if wv > 0.1 then
              local wl = wv * 5
              put(wl, x - 6, y0, 4, 1); put(wl, x + 3, y0, 4, 1)
              put(wl, x, y0 - 6, 1, 3); put(wl, x, y0 + 4, 1, 3)
            end
          end
        end
      end
    end

    -- the river: dark water between lit embankments, shimmer drifting on it
    local bank = 1 + e * 0.5
    for x = 0, 120, 8 do
      line(bank, x, riv(x) - RH, x + 8, riv(x + 8) - RH)
      line(bank, x, riv(x) + RH, x + 8, riv(x + 8) + RH)
    end
    for k = 0, 21 do
      local x = (k * 6 + T * (3 + K.hash(k, 81) * 4)) % 132 - 2
      local dy = floor((K.hash(k, 82) - 0.5) * (RH * 2 - 2))
      local tw = 0.5 + 0.5 * sin(T * (1 + K.hash(k, 83) * 2) + k)
      put(1 + tw * (1 + hi * 3 + gps * 2), x, riv(x) + dy, 2 + floor(K.hash(k, 84) * 3), 1)
    end

    -- chaos cuts diagonal avenues through the grid
    if c > 0.3 then
      local cl = 1 + 1.5 * (c - 0.3) / 0.7
      for d = 0, 1 do
        local b = ((ox * 0.55 - oy + d * 70) % 140) - 72
        line(cl, 0, b, 127, b + 70)
      end
    end

    -- rooftop beacons (perc)
    for k = #tops, 1, -1 do
      local P = tops[k]
      local age = T - P.t0
      if age > 0.8 then table.remove(tops, k)
      else
        local x = P.gi * AV - ox + shift(P.gj, c) + AV / 2
        local y = P.gj * ST - oy + ST / 2
        local ht = 0.8
        x, y = x + (x - 64) * ht * 0.09, y + (y - 32) * ht * 0.09
        local b = sin(math.pi * min(1, age / 0.8))
        put(min(12, 2 + 9 * b * P.lv), x - 1, y, 3, 1)
        put(min(9, 1 + 6 * b * P.lv), x, y - 1, 1, 3)
      end
    end

    -- light trails along the avenues and streets
    for k = #trails, 1, -1 do
      local R = trails[k]
      local age = T - R.t0
      if age > R.life then table.remove(trails, k)
      elseif age >= 0 then
        local fade = min(1, (R.life - age) / 0.35) * min(1, age / 0.06 + 0.3)
        local p = R.p0 + R.dir * R.sp * age
        local tl = min(R.len, R.sp * age + 1)
        for g = 0, (c > 0.6 and 1 or 0) do
          local off = g * 2
          if R.axis == 1 then
            local hy = p - oy
            local jb = floor(p / ST)
            local x = R.gi * AV - ox + shift(jb, c) + 1 + off
            line(R.lv * 0.35 * fade, x, hy - R.dir * tl, x, hy - R.dir * tl * 0.45)
            line(R.lv * 0.7 * fade, x, hy - R.dir * tl * 0.45, x, hy)
            put(min(12, R.lv * 1.3 * fade), x, hy, 1, 1)
          else
            local hx = p - ox
            local y = R.gi * ST - oy + 1 + off
            line(R.lv * 0.35 * fade, hx - R.dir * tl, y, hx - R.dir * tl * 0.45, y)
            line(R.lv * 0.7 * fade, hx - R.dir * tl * 0.45, y, hx, y)
            put(min(12, R.lv * 1.3 * fade), hx, y, 1, 1)
          end
        end
      end
    end

    -- the steady traffic: cars always moving along a few roads
    local ncar = 4 + floor(e * 6)
    for k = 1, ncar do
      local sp = 18 + 10 * K.hash(k, 71)
      if K.hash(k, 72) < 0.5 then
        local gi = i0 + 1 + floor(K.hash(k, 73) * 6)
        local y = ((T * sp + K.hash(k, 74) * 90) % 90) - 12
        local jb = floor((y + oy) / ST)
        local x = gi * AV - ox + shift(jb, c) - 1
        line(2 + e, x, y - 3, x, y); put(4 + e * 2, x, y, 1, 1)
      else
        local gj = j0 + 1 + floor(K.hash(k, 73) * 5)
        local x = 140 - ((T * sp + K.hash(k, 74) * 160) % 160)
        local y = gj * ST - oy - 1
        line(2 + e, x, y, x + 3, y); put(4 + e * 2, x, y, 1, 1)
      end
    end

    -- the plane overhead: its strobe blinks on the ticks
    local pu = (T * 6) % 220
    local px, py = pu - 40, 52 - pu * 0.18
    put(min(10, 2 + planef * 8 + 1.5 * (0.5 + 0.5 * sin(T * 4))), px, py, 2, 1)
    put(2, px - 2, py + 1, 1, 1); put(2, px + 3, py - 1, 1, 1)

    -- kickless: a deck of low cloud drifts in under us
    if kl > 0.05 then K.haze(0, 0, 128, 64, 0.45 * kl, 1, T * 14) end
    K.grain(function(u, v) return u * 128, v * 64 end, 3 + hi * 10 + e * 4, 2 + hi * 4)
  end

  function M.draw(S)
    local DT = K.DT
    surge = surge * exp(-DT / 0.22)
    bloom = bloom * exp(-DT / 0.3)
    blooms = K.follow(blooms, bloom, 0.06, DT)
    rimf = rimf * exp(-DT / 0.14)
    ratf = ratf * exp(-DT / 0.4)
    ridef = ridef * exp(-DT / 0.3)
    percf = percf * exp(-DT / 0.2)
    brake = brake * exp(-DT / 0.35)
    fillf = fillf * exp(-DT / 0.7)
    beacon = beacon * exp(-DT / 0.15)
    hatf = hatf * exp(-DT / 0.08)
    gpulse = gpulse * exp(-DT / 0.25)
    gps = K.follow(gps, gpulse, 0.1, DT)
    planef = planef * exp(-DT / 0.15)
    flip = flip * exp(-DT / 0.3)
    for b = #bursts, 1, -1 do if K.T - bursts[b].t0 > 0.9 then table.remove(bursts, b) end end
    for w = #waves, 1, -1 do if K.T - waves[w].t0 > 1.6 then table.remove(waves, w) end end
    if K.view == 2 then draw2(S) else draw1(S) end
  end

  M.init()
  return M
end
