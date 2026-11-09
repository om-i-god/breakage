-- garage. view 1: the top deck of a night bus, looking out of the front window:
-- rain on the glass, the high street streaming past, the seat backs below us.
-- view 2: a car dashboard at night: a stereo with a glowing graphic EQ, the
-- speedo, wipers, and the road and its cat's eyes ahead through the windscreen.
--
-- view 1: the kick bumps the whole bus (the street lurches against the frame)
-- and pulses the shop lights; hats sweep streetlamp light through the deck and
-- the open ones brighten the next lamp coming; snares and claps make the
-- lights flare in the raindrops, rims glint one drop; congas, bongos and
-- claves flicker shop neon, toms flare the brake lights of the car ahead,
-- shakers shimmer the rain, ticks blink the bell-push lamp, break slices light
-- the shopfronts one by one, ratchets throw a run of lamp sweeps and a fill
-- sends an oncoming bus streaming past. energy speeds the bus and lights more
-- of the street; chaos smears the streaks and ghosts the street; kickless
-- stretches stop the bus at a red light with the rain gathering and the
-- wipers going.
-- view 2: each voice drives its bands of the EQ (kick low, toms, congas and
-- bongos, snares, rims, metal, hats, shaker, ticks on top) with peak dots
-- falling; the kick kicks the speedo needle and bumps the road; snares swipe
-- the wipers; hats glint the cat's eyes; a fill flares oncoming headlights;
-- ratchets run a chase across the EQ. energy is the speed, chaos scatters the
-- EQ into ghosts and wobbles the road, kickless slows the car to a stop with
-- the indicator ticking.
-- the live bands: view 1: amp thickens the drizzle in the street light, lo
-- speeds the bus, mid brightens the shop glass and its wet reflections, hi
-- brings the rain on (more drops, sparkling) and lights the lamps and rooms.
-- view 2: amp lights the panel, lo the headlight pool, verges and trees, mid
-- the stereo's faceplate and label strip, hi the cat's eyes, reflector posts,
-- stars and rain; all four feed the EQ's bands.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, exp = math.sin, math.cos, math.floor, math.max, math.min, math.abs, math.exp
  local PI, TAU = math.pi, K.TAU

  ---------------------------------------------------------------- state
  local travel, spd                   -- the street's travel and speed
  local bump, bumpv                   -- the bus's bump (eased)
  local pulse, flarev, glint, glint_x, glint_y, shimmer
  local neon, neon_i, brake, bell, slice_l, slice_i
  local sweeps                        -- lamp light sweeping the deck {t0, v, side}
  local oncoming                      -- a bus going the other way {t0}
  local wipe                          -- wipers: phase (0 rest .. 1 back at rest)
  local rest_t                        -- the red light, eased in
  local pe = 0                        -- the kick's pulse, eased

  -- view 2
  local NB = 12
  local band, peak, pv                -- EQ bands, peak dots, peak velocity
  local disp = {}                     -- what the EQ shows, eased
  local needle, needlev
  local wip2                          -- the car's wipers
  local glare, chase_t, chase_n
  local ind                           -- indicator phase
  local drops2                        -- the car's windscreen rain (age since a wipe)

  function M.init()
    travel, spd = 0, 0.5
    bump, bumpv = 0, 0
    pulse, flarev, glint, glint_x, glint_y, shimmer = 0, 0, 0, 30, 20, 0
    pe = 0
    neon, neon_i, brake, bell, slice_l, slice_i = 0, 1, 0, 0, 0, 1
    sweeps, oncoming = {}, nil
    wipe, rest_t = 0, 0
    band, peak, pv = {}, {}, {}
    for b = 1, NB do band[b], peak[b], pv[b], disp[b] = 0, 0, 0, 0 end
    needle, needlev = 0.3, 0
    wip2 = 0
    glare, chase_t, chase_n = 0, -1, 0
    ind = 0
    drops2 = 0
  end
  M.clear = M.init

  local function hitb(b, v) if b >= 1 and b <= NB then band[b] = max(band[b], clamp(v, 0, 1)) end end
  local function sweep(v, side)
    if #sweeps >= 6 then table.remove(sweeps, 1) end
    sweeps[#sweeps + 1] = {t0 = K.T, v = v, side = side or (K.rnd() < 0.5 and -1 or 1)}
  end

  ---------------------------------------------------------------- events
  function M.kick(v)
    v = K.num(v, 1)
    bumpv = max(bumpv, v)
    pulse = max(pulse, v)
    hitb(1, v); hitb(2, 0.85 * v)
    needlev = needlev + 1.2 * v
  end
  function M.snare(v, n)
    v = K.num(v, 1)
    flarev = max(flarev, 0.5 + 0.5 * v)
    hitb(5, v); hitb(6, 0.8 * v); hitb(4, 0.4 * v)
    if wip2 <= 0 or wip2 > 0.7 then wip2 = 0.001 end
  end
  function M.clap(v)
    v = K.num(v, 1)
    flarev = max(flarev, 0.4 + 0.4 * v)
    hitb(6, v); hitb(7, 0.6 * v)
  end
  function M.rim(v)
    v = K.num(v, 1)
    glint, glint_x, glint_y = max(glint, v), 10 + floor(K.rnd() * 108), 9 + floor(K.rnd() * 32)
    hitb(7, v)
  end
  function M.hat(v, open)
    v = K.num(v, 1)
    sweep((open and 0.9 or 0.45) * (0.5 + 0.5 * v))
    hitb(open and 11 or 10, v); hitb(9, 0.6 * v)
    if open then hitb(12, 0.6 * v) end
  end
  function M.ride(v) M.hat(v, true) end
  function M.shaker(v)
    v = K.num(v, 1)
    shimmer = max(shimmer, 0.5 + 0.5 * v)
    hitb(11, 0.8 * v)
  end
  function M.tom(v, hz)
    v = K.num(v, 1)
    brake = max(brake, v)
    hitb(hz and hz < 150 and 3 or 4, v)
  end
  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 17 then M.tom(v, 100); return end
    if kind == 16 then
      -- a vocal chop: a shop sign blinks on, the mids jump
      neon, neon_i = max(neon, v), floor(K.rnd() * 6) + 1
      hitb(5, v); hitb(6, 0.7 * v); flarev = max(flarev, 0.3 * v)
      return
    end
    if kind == 1 or kind == 2 or kind == 4 or kind == 13 then
      neon, neon_i = max(neon, v), floor(K.rnd() * 6) + 1
      hitb(kind == 1 and 4 or kind == 2 and 5 or 8, v)
    elseif kind == 3 or kind == 6 or kind == 11 or kind == 8 then
      glint, glint_x, glint_y = max(glint, v), 10 + floor(K.rnd() * 108), 9 + floor(K.rnd() * 32)
      hitb(8, v)
    elseif kind == 10 then
      shimmer = max(shimmer, v); hitb(11, v)
    elseif kind == 14 or kind == 5 then
      pulse = max(pulse, 0.5 * v); hitb(2, v); hitb(3, v)
    else
      neon, neon_i = max(neon, 0.6 * v), floor(K.rnd() * 6) + 1
      hitb(9, 0.7 * v)
    end
  end
  function M.tick(kind)
    bell = 1
    hitb(12, 0.7)
  end
  function M.brk(s, n)
    s, n = K.num(s, 1), max(1, K.num(n, 8))
    slice_l, slice_i = 1, floor(s) % 8 + 1
    hitb(clamp(floor((s - 1) / n * NB) + 1, 1, NB), 0.7)
  end
  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 10)
    for k = 0, min(n, 5) - 1 do
      if #sweeps >= 6 then table.remove(sweeps, 1) end
      sweeps[#sweeps + 1] = {t0 = K.T + k * 0.05, v = 0.8, side = (k % 2 == 0) and -1 or 1}
    end
    chase_t, chase_n = K.T, n
    flarev = max(flarev, 0.5)
  end
  function M.fill()
    oncoming = {t0 = K.T}
    glare = 1
  end

  ---------------------------------------------------------------- view 1
  local VX, VY = 64, 23               -- vanishing point
  local WX0, WX1, WY0, WY1 = 3, 125, 7, 43   -- the front window
  local F = 7
  local ZN, ZF = 0.32, 11
  local NS = 7                        -- shop slots per side
  local NL = 4                        -- lamp slots
  local ND = 7                        -- road dash slots

  local function sx(X, z) return VX + X * F / z end
  local function sy(Y, z) return VY + Y * F / z end
  local function inwin(y) return y >= WY0 and y <= WY1 end
  -- a line clipped to the window (both ends pulled in, roughly)
  local function wline(l, x0, y0, x1, y1)
    if x0 < WX0 then if x1 ~= x0 then y0 = y0 + (y1 - y0) * (WX0 - x0) / (x1 - x0) end; x0 = WX0 end
    if x1 > WX1 then if x1 ~= x0 then y1 = y1 - (y1 - y0) * (x1 - WX1) / (x1 - x0) end; x1 = WX1 end
    if x0 > WX1 or x1 < WX0 then return end
    y0, y1 = clamp(y0, WY0, WY1), clamp(y1, WY0, WY1)
    line(l, x0, y0, x1, y1)
  end
  -- depth of slot i (0..n-1) along the street at this travel
  local function slotz(i, n, rate)
    local u = (i / n + travel * rate) % 1
    return ZF - u * (ZF - ZN), floor(i + n * (travel * rate - (i / n + travel * rate) % 1 + i / n) + 0.5)
  end

  local function draw1(S)
    local T, DT, DTS, e, c, kl = K.T, K.DT, K.DTS, K.energy, K.chaos, K.kickless
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]

    -- the bus: its speed, its bump
    local tgt = (0.35 + 0.55 * e + lo * 0.15) * (1 - kl)
    spd = K.follow(spd, tgt, 0.8, DT)
    travel = travel + spd * DTS * 0.11
    bump = K.follow(bump, bumpv, 0.03, DT)
    local by = floor(bump * 1.6 + 0.5)                -- the street lurches
    pe = K.follow(pe, pulse, 0.05, DT)
    local gx = c > 0.25 and floor(sin(T * 9.1) * c * 3 + 0.5) or 0
    local smear = 1 + c * 1.8 + spd * 0.6
    local lightsup = 1 + pe * 0.35 + e * 0.3 + mid * 0.4

    -- the far city: a skyline of towers at the vanishing point with lit windows
    for i = 0, 11 do
      local x = 34 + i * 5 + floor(K.hash(i, 1) * 3)
      local h = 3 + floor(K.hash(i, 2) * 9)
      if x < 58 or x > 70 then
        line(1, x, VY - h + by, x, VY + by)
        if K.hash(i, 3) > 0.4 then
          put(1 + 1.5 * (0.5 + 0.5 * sin(T * 0.3 + i * 2)) + hi, x + 1, VY - h + 2 + by, 1, 1)
        end
      end
    end
    -- a red light hanging over the junction ahead, when we're stopped
    if kl > 0.05 then
      local tx, ty = 82, VY - 7 + by
      line(1 + kl, tx + 2, ty + 3, tx + 2, VY + 8 + by)
      put(1 + kl, tx, ty - 4, 5, 9)
      K.disc(1 + kl * 9, tx + 2, ty - 2, 1.3)
      put(1 + kl * 0.5, tx + 2, ty + 2, 1, 1)
      K.ring(kl * (2 + 0.6 * sin(T * 2)), tx + 2, ty - 2, 4, 8)
    end

    -- drizzle hanging in the sodium light over the street
    K.haze(WX0, WY0 + 2, WX1, VY + 4, 0.14 + 0.15 * kl + 0.1 * e + A[K.AMP] * 0.2 + hi * 0.25, 1 + hi, T * (3 + spd * 10))
    -- the road: kerbs to the corners, the centre dashes streaming at us
    wline(2, VX - 2, VY + 1 + by, WX0, WY1 + by)
    wline(2, VX + 2, VY + 1 + by, WX1, WY1 + by)
    for i = 0, ND - 1 do
      local z = (ZF - ((i / ND + travel) % 1) * (ZF - ZN))
      local z1 = z + 0.6 * smear
      local y0, y1 = sy(2, z) + by, sy(2, z1) + by
      if y0 <= WY1 + 2 then wline(1.5 + 2 / z, VX - 0.2 * F / z, y0, VX - 0.2 * F / z1, y1) end
    end
    -- the car ahead: tail lights swaying, flaring on toms
    local cx = VX + 3 + sin(T * 0.35) * 3 - kl * 2
    local cy = VY + 6 + by
    put(1.5, cx - 4, cy - 3, 9, 3)
    put(2 + brake * 10 + kl * 3, cx - 4, cy, 2, 1)
    put(2 + brake * 10 + kl * 3, cx + 3, cy, 2, 1)
    if brake > 0.3 then
      line(brake * 3, cx - 6, cy + 1, cx - 9, cy + 6)
      line(brake * 3, cx + 6, cy + 1, cx + 9, cy + 6)
    end

    -- the shops: both sides of the high street as walls of lit glass and
    -- windows, streaming past (each column is a slice of the street)
    local W = travel * (ZF - ZN)
    local SL = 1.3
    for side = -1, 1, 2 do
      local X = side * 3.2
      local xs, xe, st = side < 0 and WX0 or VX + 3, side < 0 and VX - 3 or WX1, 3
      for x = xs, xe - 1, st do
        local d = (x + 1.5 - VX)
        local z = X * F / d
        if z > ZN * 0.5 and z < ZF then
          local w = z + W
          local sh = floor(w / SL)
          local f = (w / SL) % 1
          local near = clamp(1.3 - z / 5, 0, 1)
          local function shop(k)
            local on = K.hash(k * 2 + side, 5) < 0.5 + e * 0.4
            local lv = on and (1.5 + 3 * K.hash(k, 6)) or 0.6
            if neon > 0.05 and (k % 6) + 1 == neon_i then lv = lv + neon * 6 end
            if slice_l > 0.05 and (k % 8) + 1 == slice_i then lv = lv + slice_l * 5 end
            return lv
          end
          -- blend shop to shop so a near column never jumps
          local bl = f > 0.75 and K.ease((f - 0.75) / 0.25) or 0
          local glass = min(10, (shop(sh) * (1 - bl) + shop(sh + 1) * bl) * (0.55 + 0.5 * near) * lightsup)
          local fy = c > 0.3 and floor(sin(T * 6 + x * 0.7) * c * 3 + 0.5) or 0
          local ytop, yg0, yg1, ybot = sy(-3.4, z), sy(0.3, z), sy(1.8, z), sy(2, z)
          local w2 = min(st, xe - x)
          -- the wall stays dark; the glass glows at street level, and the
          -- near shops rush past as a blur of streaks
          local a0 = clamp(ytop + by + fy, WY0, WY1 + 1)
          local g0, g1 = clamp(yg0 + by + fy, WY0, WY1 + 1), clamp(yg1 + by + fy, WY0, WY1 + 1)
          if z > 0.9 then
            if g1 > g0 then put(glass, x, g0, w2, g1 - g0) end
            -- its reflection smeared down the wet pavement
            local r1 = clamp(g1 + (g1 - g0) * (0.8 + spd) , WY0, WY1 + 1)
            if glass > 1.6 and r1 > g1 + 1 then put(glass * 0.35 + mid * 0.8, x + 1, g1 + 1, 1, r1 - g1 - 1) end
            if f < 0.12 then put(1.5 + near, x, a0, 1, g1 - a0) end   -- the gap between shops
          else
            local gm = floor((g0 + g1) / 2)
            put(glass * 0.8, x, g0, w2, 1)
            put(glass * 0.6, x, gm, w2, 1)
            if g1 - 1 > gm then put(glass * 0.4, x, g1 - 1, w2, 1) end
          end
          -- upper windows: lit rooms on two floors
          for fl2 = 0, 1 do
            if z > 0.9 and K.hash(sh * 4 + fl2 * 2 + side, 7) > 0.5 - e * 0.15 and f > 0.2 and f < 0.8 then
              local u0, u1 = sy(-2.6 + fl2 * 1.3, z), sy(-1.9 + fl2 * 1.3, z)
              u0, u1 = clamp(u0 + by + fy, WY0, WY1 + 1), clamp(u1 + by + fy, WY0, WY1 + 1)
              if u1 > u0 then put(1.5 + near * 1.5 + hi * 2 * K.hash(sh, 9 + fl2), x, u0, w2, max(1, u1 - u0)) end
            end
          end
          -- chaos: the glass band smeared into a ghost beside it
          if c > 0.35 and glass > 2 and z > 0.9 then
            put(glass * 0.4 * c, x + side * floor(c * 8), g0 + 1, w2, max(1, g1 - g0 - 1))
          end
        end
      end
    end

    -- the streetlamps: posts and heads coming at us, their light sweeping
    for i = 0, NL - 1 do
      local u = (i / NL + travel) % 1
      local z = ZF - u * (ZF - ZN)
      local side = (i % 2 == 0) and -1 or 1
      local X = side * 2.4
      local x = sx(X, z) + gx
      local yh, yb2 = sy(-2.8, z) + by, sy(2, z) + by
      local near = clamp(1.2 - z / 5, 0, 1)
      if x >= WX0 and x <= WX1 then
        line(1 + near * 1.5, x, clamp(yh, WY0, WY1), x, clamp(yb2, WY0, WY1))
        if inwin(yh) then
          local hl = min(12, 3 + near * 6 + hi * 3)
          put(hl, x - side * 1, yh, 2, 1)
          if near > 0.3 then K.ring(near * 2.5, x, yh + 1, 2 + near * 5, 10, 0, TAU, 0.6) end
          if smear > 1.5 then line(hl * 0.3, x, yh, x - side * smear * 3, yh - smear) end
        end
      end
    end

    -- an oncoming bus on a fill: a long lit box streaming past on the right
    if oncoming then
      local u = (T - oncoming.t0) / 0.9
      if u >= 1 or u < 0 then oncoming = nil
      else
        local z = ZF * (1 - u) + ZN * u
        local z1 = z + 3
        local X = 1.6
        for k = 0, 2 do
          local Y = -0.6 + k * 0.6
          wline(3 + 6 * u, sx(X, z), sy(Y, z) + by, sx(X, z1), sy(Y, z1) + by)
        end
        line(5 + 6 * u, sx(X, z), clamp(sy(-0.6, z) + by, WY0, WY1), sx(X, z), clamp(sy(1.4, z) + by, WY0, WY1))
      end
    end

    -- the rain on the glass: drops sliding down, gathering when we stop,
    -- flaring with the snares and catching the lamps
    local nd = 26 + floor(kl * 14 + hi * 22)
    local fl = flarev
    for i = 0, nd - 1 do
      local x0 = WX0 + 1 + K.hash(i, 11) * (WX1 - WX0 - 2)
      local rate = 0.6 + K.hash(i, 12) * 2.2 + spd * 2
      local y = WY0 + ((K.hash(i, 13) * 36 + T * rate) % 36)
      local x = x0 + (x0 - VX) * (y - WY0) / 36 * spd * 0.25
      local near = (fl > 0.05 and K.hash(i, 14) < 0.6) and fl or 0
      local l = 1 + K.hash(i, 15) * 1.2 + near * 7 + (shimmer * 4 + hi * 3) * K.hash(i + floor(T * 8), 16) + hi
      put(l, x, y, 1, 1)
      if c > 0.3 or spd > 0.7 then line(l * 0.5, x, y - 1, x - (x - VX) * 0.02 * smear, y - 1 - smear * 1.5) end
      if near > 0.5 and K.hash(i, 17) < 0.25 then
        put(near * 4, x - 1, y, 3, 1); put(near * 4, x, y - 1, 1, 3)
      end
    end
    -- rivulets running down
    for i = 0, 4 do
      local x = 12 + i * 24 + floor(K.hash(i, 21) * 10)
      local y = WY0 + ((K.hash(i, 22) * 40 + T * (6 + i)) % 40)
      local len = 3 + floor(K.hash(i, 23) * 4) + floor(kl * 3)
      line(1.5 + fl * 4 + hi, x + sin(y * 0.4) * 0.8, y - len, x, y)
    end
    if glint > 0.05 then
      put(3 + glint * 9, glint_x, glint_y, 1, 1)
      put(1 + glint * 4, glint_x - 1, glint_y, 3, 1)
      put(1 + glint * 4, glint_x, glint_y - 1, 1, 3)
    end
    -- the wipers, waiting at the red light
    if kl > 0.3 then
      local ph = (T * 0.9) % 1
      local a = ph < 0.5 and ph * 2 or 2 - ph * 2
      for _, p in ipairs({{34, 1}, {94, 1}}) do
        local ang = PI - a * 2.4 - 0.25
        local len = 30
        line(1.5 + kl * 2, p[1], WY1, p[1] + cos(ang) * len, WY1 - abs(sin(ang)) * len * 0.75)
      end
    end

    -- the deck: ceiling, window frame, the pillar, the ledge and the seats
    -- (the street lurches on a kick; the bus frame stays put)
    local sw = 0
    for i = #sweeps, 1, -1 do
      local s = sweeps[i]
      local u = (T - s.t0) / 0.35
      if u >= 1 then table.remove(sweeps, i)
      elseif u >= 0 then
        -- a band of lamplight across the ceiling and the ledge
        local p = 64 + s.side * (u * 80 - 10)
        local lv = s.v * (1 - u) * 6
        put(lv, p - 6, 1, 12, 2)
        put(lv * 0.6, p - 8, 45, 16, 1)
        put(lv * 0.4, p - 5, 51, 10, 1)
        sw = max(sw, s.v * (1 - u))
      end
    end
    line(1, 0, 0, 127, 0)
    for x = 8, 120, 14 do put(1 + e * 0.5, x, 3, 6, 1) end           -- the ceiling's strip-lights
    put(1 + bell * 10, 61, 4, 6, 1)                                  -- the bell-push lamp
    line(2 + sw * 2, WX0, WY0 - 1, WX1, WY0 - 1)
    line(2 + sw * 1.5, WX0 - 1, WY0, WX0 - 1, WY1)
    line(2 + sw * 1.5, WX1 + 1, WY0, WX1 + 1, WY1)
    put(1, 63, WY0, 2, WY1 - WY0 + 1)                                -- the centre pillar
    line(1.5 + sw * 3, 63, WY0, 63, WY1)
    put(1, 0, WY1 + 1, 128, 3)                                       -- the ledge
    line(2.5 + sw * 4 + pulse * 1.5, 0, WY1 + 4, 127, WY1 + 4)        -- the handrail
    -- seat backs: moquette, a grab rail across each top
    for k = 0, 1 do
      local x0, x1 = k == 0 and 6 or 72, k == 0 and 56 or 122
      local top = 52
      put(1, x0 + 2, top, x1 - x0 - 4, 1)
      put(1, x0, top + 1, x1 - x0, 1)
      for y = top + 3, 63, 2 do
        K.dashes(1 + mid * 0.8, y, 2, 5, y * 3 + k * 2, x0 + 1, x1 - 1)
      end
      line(2.5 + sw * 3 + lightsup * 0.5, x0 + 3, top - 1, x1 - 3, top - 1)
      line(2, x0 + 3, top - 1, x0 + 3, top + 2)
      line(2, x1 - 3, top - 1, x1 - 3, top + 2)
    end
  end

  ---------------------------------------------------------------- view 2
  local RX, RY = 64, 12               -- the road's vanishing point
  local DASH = 33                     -- the dash's top edge
  local SPX, SPY, SPR = 23, 47, 11    -- speedo
  local EX0, EY1 = 56, 58             -- EQ: left x, bottom y
  local SEG = 5                       -- segments per band

  local function draw2(S)
    local T, DT, DTS, e, c, kl = K.T, K.DT, K.DTS, K.energy, K.chaos, K.kickless
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]

    local tgt = (0.35 + 0.55 * e + lo * 0.1) * (1 - 0.85 * kl)
    spd = K.follow(spd, tgt, 0.8, DT)
    travel = travel + spd * DTS * 0.5
    bump = K.follow(bump, bumpv, 0.03, DT)
    local by = 0                      -- (the shake setting jolts the car)
    local wob = c > 0.2 and sin(T * 3.1) * c * 4 or 0

    -- the night: a few stars, the hills, a town's lights on the horizon
    for i = 0, 14 do
      local x, y = floor(K.hash(i, 31) * 128), 2 + floor(K.hash(i, 32) * 8)
      put(1 + (0.5 + 0.5 * sin(T * (0.5 + K.hash(i, 33)) + i)) * (1 + hi), x, y, 1, 1)
    end
    for x = 0, 124, 4 do
      local h = 2 + 2 * sin(x * 0.05 + 1) + K.hash(x // 8, 34) * 2
      line(1.2, x, RY - h + by, x + 4, RY - (2 + 2 * sin((x + 4) * 0.05 + 1) + K.hash((x + 4) // 8, 34) * 2) + by)
    end
    for i = 0, 7 do
      local x = 76 + i * 4 + floor(K.hash(i, 35) * 3)
      put(1.5 + (0.5 + 0.5 * sin(T * 0.7 + i * 2)) * 2, x, RY - 1 + by, 1, 1)
    end

    -- the road: edges, lane line, cat's eyes streaming at us, the headlight pool
    local rvx = RX + wob
    line(1.5, rvx - 2, RY + 1 + by, -20, DASH + 8 + by)
    line(1.5, rvx + 2, RY + 1 + by, 148, DASH + 8 + by)
    for y = RY + 4, DASH - 1 do
      local u = (y - RY) / (DASH - RY)
      local w = 4 + u * 70
      local lv = (u * u * 2.2 + 0.3) * (0.5 + 0.3 * (1 - kl * 0.5) + lo * 0.6)
      if lv > 0.5 then put(lv, rvx - w * u, y + by, 2 * w * u, 1) end
    end
    local NC = 8
    for i = 0, NC - 1 do
      local u = (i / NC + travel) % 1
      local z = 10 - u * 9.6
      local y = RY + 22 / z * 1.05
      if y < DASH then
        local x = rvx + (wob * (1 - 1 / z))
        local l = min(12, 2 + 6 / z + hi * 3 + K.env.hat * 6 / z)
        put(l, x, y + by, 1 + floor(2 / z), 1)
        -- the dashed centre line between the cat's eyes
        local z1 = z + 0.5 + spd * 0.8 + c
        local y1 = RY + 22 / z1 * 1.05
        line(1.5 + 1.5 / z, x, y + by - 1, rvx, y1 + by)
      end
    end
    -- reflector posts and trees along the verges, caught in the headlights
    for i = 0, 5 do
      local u = (i / 6 + travel * 0.8) % 1
      local z = 10 - u * 9.3
      for side = -1, 1, 2 do
        local x = rvx + side * 26 / z + wob * (1 - 1 / z)
        local yb = RY + 22 / z * 1.05 + by
        if yb < DASH and x > 0 and x < 128 then
          local ph = min(4, 6 / z)
          line(1.5 + 2 / z + lo, x, yb, x, yb - ph)
          put(min(12, 2 + 5 / z + hi * 5 + K.env.hat * 4), x, yb - ph, 1, 1)
          -- a tree behind each post on the far side of the verge
          if z < 3.2 and K.hash((floor(i / 6 + travel * 0.8) * 6 + i) * 2 + side, 36) > 0.4 then
            local tx = rvx + side * 44 / z
            local th = 9 / z + 2
            local tl = 1 + 1.5 / z + lo * 0.8
            line(tl, tx, yb - 1, tx, yb - th)
            K.ring(tl, tx, yb - th - 1.5 / z - 1, 1.5 + 2.5 / z, 8, 0, TAU, 1.2)
          end
        end
      end
    end
    -- oncoming headlights on a fill
    if glare > 0.04 then
      local u = 1 - glare
      local x = rvx + 4 + u * 50
      local y = RY + 2 + u * 14 + by
      K.disc(min(12, 3 + glare * 9), x, y, 1 + u * 2)
      K.disc(min(12, 3 + glare * 9), x + 3 + u * 6, y, 1 + u * 2)
      line(glare * 4, x - 12, y, x + 18, y)
    end

    -- the windscreen: A-pillars, rain, and the wipers on the snares
    line(2, 0, 2, 12, DASH)
    line(2, 127, 2, 115, DASH)
    line(1, 10, 1, 117, 1)
    drops2 = drops2 + DT
    local nd = min(28, 6 + floor(drops2 * 6))
    for i = 0, nd - 1 do
      local x = 12 + K.hash(i, 41) * 104
      local y = 3 + K.hash(i, 42) * (DASH - 5)
      local l = 1 + K.hash(i, 43) * 1.5 + hi * 0.8 + K.env.snare * 3 * K.hash(i, 44)
      put(l, x, y, 1, 1)
    end
    local wa = 0
    if wip2 > 0 then
      wip2 = wip2 + DT / 0.55
      if wip2 >= 1 then wip2 = 0 else
        wa = wip2 < 0.5 and wip2 * 2 or 2 - wip2 * 2
        if wip2 > 0.45 and wip2 < 0.55 then drops2 = 0 end
      end
    end
    if kl > 0.4 and wip2 == 0 then
      local ph = (T * 0.5) % 1
      if ph < 0.4 then wa = (ph < 0.2 and ph / 0.2 or 2 - ph / 0.2) * kl end
    end
    for _, px in ipairs({40, 90}) do
      local ang = PI + 0.12 + wa * 2.5
      local len = 34
      local ex, ey = px + cos(ang) * len, DASH - 1 + sin(ang) * len * 0.75
      line(3 + wa * 2, px, DASH - 1, ex, ey)
      if c > 0.4 then line(1.5, px, DASH - 1, px + cos(ang - 0.2 * c) * len, DASH - 1 + sin(ang - 0.2 * c) * len * 0.75) end
    end

    -- the dash: its top edge, the glow of the panel lights
    local dl = 1 + e * 0.5 + amp * 1.2
    line(1.5 + dl * 0.4, 0, DASH, 127, DASH)
    K.dashes(1 + mid * 1.5, DASH + 2, 6, 9, 0, 14, 114)

    -- the speedo: ticks, numbers as dots, the needle with the speed
    needlev = needlev * exp(-DT / 0.12)
    local ntgt = clamp(spd * 0.95 + needlev * 0.15, 0, 1.05)
    needle = K.follow(needle, ntgt, 0.15, DT)
    K.ring(1.5 + dl * 0.6, SPX, SPY, SPR, 16, PI * 0.75, PI * 2.25)
    for k = 0, 8 do
      local a = PI * 0.75 + PI * 1.5 * k / 8
      line(k >= 7 and 2 + lo * 3 or 2, SPX + cos(a) * (SPR - 3), SPY + sin(a) * (SPR - 3), SPX + cos(a) * (SPR - 1), SPY + sin(a) * (SPR - 1))
    end
    local na = PI * 0.75 + PI * 1.5 * needle
    line(min(12, 7 + needlev * 4), SPX, SPY, SPX + cos(na) * (SPR - 2), SPY + sin(na) * (SPR - 2))
    put(4, SPX - 1, SPY - 1, 2, 2)
    -- the indicator, ticking when we're stopped (and on the ticks)
    local blink = kl > 0.3 and ((T * 1.6) % 1 < 0.5) and kl or 0
    blink = max(blink, bell)
    put(1 + blink * 9, SPX - 3, SPY + 6, 1, 1)
    line(1 + blink * 9, SPX - 2, SPY + 5, SPX - 2, SPY + 7)
    line(1 + blink * 7, SPX - 1, SPY + 6, SPX + 2, SPY + 6)
    -- the steering wheel's rim across the bottom
    K.ring(1.5 + dl * 0.5, 24, 82, 28, 12, PI * 1.2, PI * 1.8)
    K.ring(1, 24, 82, 25, 10, PI * 1.25, PI * 1.75)

    -- the stereo: faceplate, knobs, the graphic EQ
    local fp = 2 + mid * 2.5
    line(fp, 50, 36, 110, 36)
    line(fp, 50, 36, 50, 62)
    line(fp, 110, 36, 110, 62)
    line(1.5, 50, 62, 110, 62)
    local vol = PI * 0.75 + PI * 1.5 * (0.3 + e * 0.6)
    K.ring(2, 116, 46, 4, 8)
    line(4 + e * 3, 116, 46, 116 + cos(vol) * 4, 46 + sin(vol) * 4)
    K.ring(2, 116, 57, 3, 8)
    -- the air vent on the right edge and the hazard button
    for y = 38, 42, 2 do line(1.2, 113, y, 126, y) end
    put(2 + glare * 6, 54, 38, 3, 2)

    -- the bands: eased up from their envelopes and the engine's bands
    local au = {lo, lo * 0.8, lo * 0.5 + mid * 0.3, mid * 0.6, mid * 0.8, mid * 0.7,
      mid * 0.5 + hi * 0.2, hi * 0.4 + mid * 0.2, hi * 0.6, hi * 0.8, hi * 0.7, hi * 0.5}
    local ch = chase_t >= 0 and floor((T - chase_t) / 0.04) or -1
    if ch >= NB * 2 then chase_t = -1 end
    for b = 1, NB do
      band[b] = band[b] * exp(-DT / 0.12)
      local v = max(band[b], au[b] * 0.65)
      if ch >= 0 and ch < NB * 2 and (ch % NB) + 1 == b then v = max(v, 0.9) end
      disp[b] = K.follow(disp[b], v, v > disp[b] and 0.035 or 0.02, DT)
      v = disp[b]
      if v > peak[b] then peak[b], pv[b] = v, 0 else
        pv[b] = pv[b] + DT * 1.6
        peak[b] = max(0, peak[b] - pv[b] * DT)
      end
      local x = EX0 + (b - 1) * 4
      if c > 0.3 then x = x + floor(sin(T * 7 + b * 2.3) * c * 2 + 0.5) end
      local n = floor(v * SEG + 0.5)
      -- a lit stack of segments (one solid bar, the seams a shade dimmer)
      if n > 0 then
        local lv = min(8, 2.5 + v * 3.5)
        put(lv, x, EY1 + 2 - n * 4, 3, n * 4)
        for s = 1, n - 1 do put(lv * 0.75, x, EY1 + 2 - s * 4, 3, 1) end
      end
      for s = n, SEG - 1 do put(1, x, EY1 + 2 - (s + 1) * 4 + 3, 3, 1) end
      if n > 0 then put(min(8, 3 + v * 4), x, EY1 + 2 - n * 4, 3, 1) end
      local pk = floor(peak[b] * SEG + 0.5)
      if pk > n and pk > 0 then put(5 + e * 3, x, EY1 + 2 - pk * 4, 3, 1) end
      if c > 0.5 and n > 1 then
        put(1.5 + c, x + 1, EY1 + 2 - (n + 1 + floor(sin(T * 11 + b) * 2)) * 4, 1, 1)
      end
    end
    -- the display's label strip
    K.dashes(1 + mid, 60, 2, 4, 0, EX0, EX0 + NB * 4)
  end

  ---------------------------------------------------------------- draw
  function M.draw(S)
    local DT = K.DT
    bumpv = bumpv * exp(-DT / 0.09)
    pulse = pulse * exp(-DT / 0.2)
    flarev = flarev * exp(-DT / 0.18)
    glint = glint * exp(-DT / 0.15)
    shimmer = shimmer * exp(-DT / 0.12)
    neon = neon * exp(-DT / 0.3)
    brake = brake * exp(-DT / 0.3)
    bell = bell * exp(-DT / 0.12)
    slice_l = slice_l * exp(-DT / 0.12)
    glare = glare * exp(-DT / 0.5)
    if K.view == 2 then draw2(S) else draw1(S) end
  end

  M.init()
  return M
end
