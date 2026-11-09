-- garage. view 1: the top deck of a night bus, looking out of the front window:
-- rain on the glass, the high street streaming past, the seat backs below us
-- and a passenger in headphones in the seat in front.
-- view 2: a car dashboard at night: a stereo with a glowing graphic EQ, the
-- speedo, wipers, hands on the wheel, the rear-view mirror, and the road and
-- its cat's eyes ahead through the windscreen.
-- view 3: the same night bus from across the street, side on: its two lit
-- decks full of dark heads, the shops and the flats above them sliding past
-- behind it, streetlamps over its roof, and its windows doubled in the wet road.
--
-- view 1: the kick bumps the whole bus (the street lurches against the frame),
-- pulses the shop lights and nods the passenger's head; hats sweep streetlamp
-- light through the deck and the open ones brighten the next lamp coming;
-- snares make the lights flare in the raindrops, claps light the rooms above
-- the shops, rims glint one drop; congas, bongos and claves flicker shop neon,
-- toms flare the brake lights of the car ahead, shakers shimmer the rain,
-- ticks blink the bell-push lamp, break slices light the shopfronts one by
-- one, ratchets throw a run of lamp sweeps and a fill sends an oncoming bus
-- streaming past. the next-stop sign marches its dots on the 16ths, brightens
-- on the bar and lights up whole (STOPPING) on the phrase's last bar; the
-- city's glow on the cloud grows through the phrase. energy speeds the bus and
-- lights more of the street; chaos smears the streaks and ghosts the street;
-- kickless stretches stop the bus at a red light with the rain gathering, the
-- wipers going and the passenger's head resting on the glass.
-- view 2: each voice drives its bands of the EQ (kick low, toms, congas and
-- bongos, snares, rims, metal, hats, shaker, ticks on top) with peak dots
-- falling; the kick kicks the speedo needle and the hands grip the wheel;
-- snares swipe the wipers; closed hats tap the right fingers, open ones lift
-- the left thumb and glint the cat's eyes; a fill flares oncoming headlights
-- (and the car behind, in the mirror); ratchets run a chase across the EQ.
-- the station display runs on the 16ths and the bar, the car behind closes
-- in through the phrase and the town ahead lights up. energy is the speed,
-- chaos scatters the EQ into ghosts and wobbles the road, kickless slows the
-- car to a stop with the indicator ticking.
-- view 3: the kick rides the wheels up on their springs and rings the
-- puddles; snares lift the decks' light and flare the rain, claps flash the
-- advert along the side and the flats above the shops; closed hats glint a
-- lamp's light along the roof, open ones a long sweep and the lamps' halos;
-- toms flare the brake lights and their red smear on the road; neon perc
-- blinks the shop signs, metal glints the mirror, ticks light the stopping
-- lamp by the driver, break slices light a window and a shop, ratchets run
-- along the windows; a fill sends a car past close in the foreground. the
-- destination blind marches on the 16ths and the bar; the flats light up
-- and the cloud glows through the phrase. energy speeds the bus and fills it,
-- chaos flickers the windows and ghosts the lower deck along the body,
-- kickless pulls it in to the stop: it kneels, the indicators tick, the
-- passengers lean and rain gathers on the glass.
-- the live bands: view 1: amp thickens the drizzle and the city glow, lo
-- speeds the bus, mid brightens the shop glass, its wet reflections and the
-- light sliding over the seats, hi brings the rain on and lights the lamps,
-- rooms and the passenger's headphones.
-- view 2: amp lights the panel, the hands and the mirror, lo the headlight
-- pool, verges, trees and the car behind, mid the stereo's faceplate,
-- display and label strip, hi the cat's eyes, reflector posts, stars and
-- rain; all four feed the EQ's bands.
-- view 3: amp lights the decks and the cloud, lo speeds the street and the
-- wheels and stretches the reflections, mid lights the shop glass and the
-- body's band, hi brings the rain and the splashes and lights the lamps,
-- the roof edge and the flats.
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
  local tap                           -- view 2: fingers tapping the wheel {closed, open}
  local clapv                         -- claps: the flats light up (1), the ad panel (3)
  -- view 3
  local scr                           -- the street scrolling past the bus, px
  local bob                           -- the bus on its suspension (eased, px)
  local ripples                       -- puddle rings at the wheels {t0, x, v}
  local car3                          -- a car passing in the foreground on a fill {t0}
  local inner3 = 3                    -- the bus's interior light (eased)
  local ph3 = 0                       -- the phrase position (eased)

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
    tap, clapv = {0, 0}, 0
    scr, bob, ripples, car3 = 0, 0, {}, nil
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
    if #ripples >= 6 then table.remove(ripples, 1) end
    ripples[#ripples + 1] = {t0 = K.T, x = 40, v = v}
    ripples[#ripples + 1] = {t0 = K.T + 0.03, x = 86, v = v * 0.8}
  end
  function M.snare(v, n)
    v = K.num(v, 1)
    flarev = max(flarev, 0.5 + 0.5 * v)
    hitb(5, v); hitb(6, 0.8 * v); hitb(4, 0.4 * v)
    if wip2 <= 0 or wip2 > 0.7 then wip2 = 0.001 end
  end
  function M.clap(v)
    v = K.num(v, 1)
    flarev = max(flarev, 0.25 * v)
    clapv = max(clapv, 0.5 + 0.5 * v)
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
    tap[open and 2 or 1] = max(tap[open and 2 or 1], 0.5 + 0.5 * v)
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
    car3 = {t0 = K.T}
    glare = 1
  end

  -- where we are in the phrase, 0..1 (and its length in bars)
  local function phrase(S)
    local n = max(1, K.num(S.phrase_len, 16))
    return clamp(K.num(S.phrase_pos, 0) / n, 0, 1), n
  end

  -- a dot-matrix sign: dots marching on the 16ths, all lit (STOPPING) on
  -- the phrase's last bar, brighter on the bar
  local function dotsign(l, x0, y, cols, S, dim)
    local pp, n = phrase(S)
    local stopping = pp >= 1 - 1 / n - 1e-6
    local st = floor(K.stepf)
    for col = 0, cols - 1 do
      if stopping or K.hash(col + st, 85) < 0.5 then put(min(11, l + (stopping and 3 or 0)), x0 + col * 2, y, 1, 1)
      elseif dim then put(dim, x0 + col * 2, y, 1, 1) end
    end
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
    local ph = phrase(S)
    local bp = K.bar_pulse

    -- the city's glow on the low cloud over the junction, growing through the phrase
    for r = 0, 1 do
      local gl = (0.7 + ph * 0.9 + A[K.AMP] * 0.6) * (1 - r * 0.3)
      K.dashes(gl, VY - 12 - r * 3 + by, 2, 6 + r * 2, T * (1 + r) + r * 2, 30, 98)
    end

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
              if u1 > u0 then put(1.5 + near * 1.5 + hi * 2 * K.hash(sh, 9 + fl2) + clapv * 4 * K.hash(sh, 19 + fl2), x, u0, w2, max(1, u1 - u0)) end
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
    for x = 8, 78, 14 do put(1 + e * 0.5, x, 3, 6, 1) end            -- the ceiling's strip-lights
    -- the next-stop sign: dots marching, STOPPING on the phrase's last bar
    dotsign(2 + bp * 5 + e, 88, 2, 15, S, 1)
    put(1 + bell * 10, 61, 4, 6, 1)                                  -- the bell-push lamp
    line(2 + sw * 2, WX0, WY0 - 1, WX1, WY0 - 1)
    line(2 + sw * 1.5, WX0 - 1, WY0, WX0 - 1, WY1)
    line(2 + sw * 1.5, WX1 + 1, WY0, WX1 + 1, WY1)
    put(1, 63, WY0, 2, WY1 - WY0 + 1)                                -- the centre pillar
    line(1.5 + sw * 3, 63, WY0, 63, WY1)
    put(1, 0, WY1 + 1, 128, 3)                                       -- the ledge
    local phx = floor(32 - kl * 4)                                   -- the passenger (below)
    line(2.5 + sw * 4 + pulse * 1.5, 0, WY1 + 4, phx - 6, WY1 + 4)    -- the handrail, behind him
    line(2.5 + sw * 4 + pulse * 1.5, phx + 6, WY1 + 4, 127, WY1 + 4)
    -- seat backs: moquette, a grab rail across each top
    for k = 0, 1 do
      local x0, x1 = k == 0 and 6 or 72, k == 0 and 56 or 122
      local top = 52
      put(1, x0 + 2, top, x1 - x0 - 4, 1)
      put(1, x0, top + 1, x1 - x0, 1)
      for y = top + 3, 63, 2 do
        K.dashes(1 + mid * 0.8, y, 2, 5, y * 3 + k * 2, x0 + 1, x1 - 1)
      end
      -- a shop's light sliding back over the moquette as we pass it
      local bx = 150 - ((travel * 1100 + k * 77) % 200)
      local b0, b1 = max(x0 + 1, floor(bx - 12)), min(x1 - 1, floor(bx + 12))
      if b1 > b0 then
        for y = top + 3, 63, 2 do K.dashes(1.5 + mid * 1.8 + e * 0.5, y, 2, 5, y * 3 + k * 2, b0, b1) end
      end
      line(2.5 + sw * 3 + lightsup * 0.5, x0 + 3, top - 1, x1 - 3, top - 1)
      line(2, x0 + 3, top - 1, x0 + 3, top + 2)
      line(2, x1 - 3, top - 1, x1 - 3, top + 2)
    end
    -- the passenger in front, in headphones: nods on the kick, rests his
    -- head on the glass at the red light; the lamps catch his outline
    local hx = phx
    local hy = 47 + floor(pe * 1.4 + 0.5)
    local hl = 1.5 + sw * 5 + pe * 1.5 + mid
    K.disc(1, hx, hy, 4.5)
    put(1, hx - 7, hy + 4, 15, 52 - hy - 4)                           -- his shoulders
    K.ring(hl, hx, hy, 5, 12, PI * 1.05, PI * 1.95, 1, 0)
    line(hl * 0.8, hx - 5, hy + 1, hx - 7, hy + 4)
    line(hl * 0.8, hx + 5, hy + 1, hx + 7, hy + 4)
    K.ring(2 + hi * 2 + K.env.hat * 3, hx, hy, 6.5, 10, PI * 1.1 + kl * 0.2, PI * 1.9 + kl * 0.2)
    put(min(10, 2 + hi * 2 + pe * 3), hx - 7, hy - 1, 2, 3)
    put(min(10, 2 + hi * 2 + pe * 3), hx + 6, hy - 1, 2, 3)
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
    pe = K.follow(pe, pulse, 0.05, DT)
    local ph = phrase(S)
    local bp = K.bar_pulse
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
    -- the town ahead: more of its lights come up through the phrase
    local nt = 3 + floor(ph * 6 + 0.5)
    for i = 0, 8 do
      local x = 74 + i * 4 + floor(K.hash(i, 35) * 3)
      local on = (K.hash(i, 37) * 9) < nt
      put((on and 1.5 + (0.5 + 0.5 * sin(T * 0.7 + i * 2)) * (2 + amp) or 0.6), x, RY - 1 + by, 1, 1)
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

    -- the rear-view mirror: the car behind us, closing in through the phrase
    local my = 0
    line(1.5, 64, 0, 64, 2 + my)
    line(1.5 + amp * 0.8, 51, 2 + my, 77, 2 + my)
    K.dashes(1 + amp * 0.5, 8 + my, 2, 4, 0, 51, 77)
    line(1.5, 50, 2 + my, 50, 8 + my); line(1.5, 78, 2 + my, 78, 8 + my)
    local sep = 2 + ph * 4 + kl * 2
    local hlb = min(12, 2.5 + ph * 3 + lo * 2 + glare * 6)
    put(hlb, 64 - sep - 1, 5 + my, 2, 1)
    put(hlb, 64 + sep, 5 + my, 2, 1)
    line(1 + ph * 1.5 + lo, 64 - sep - 4, 6 + my, 64 + sep + 4, 6 + my)

    -- the dash: its top edge, the glow of the panel lights
    local dl = 1 + e * 0.5 + amp * 1.2
    line(1.2 + dl * 0.35, 0, DASH, 127, DASH)
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
    -- hands on the wheel: the right fingers tap the closed hats, the left
    -- thumb lifts on the open ones, both grip on the kick
    for hnd = 1, 2 do
      local a = hnd == 1 and PI * 1.7 or PI * 1.3
      local hxp, hyp = 24 + cos(a) * 28, 82 + sin(a) * 28
      local gl = 1.5 + amp * 0.8 + pe * 1.2 + e * 0.4
      K.disc(gl, hxp, hyp + 1, 2.1)
      local tp = tap[hnd]
      local sgn = hnd == 1 and 1 or -1
      line(min(12, gl + 1 + tp * 7), hxp + sgn * 2, hyp - 1, hxp + sgn * (3 + tp), hyp - 2 - floor(tp * 3 + 0.5))
    end

    -- the stereo: faceplate, knobs, the graphic EQ
    local fp = 1.5 + mid * 1.8
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
      for s = n, SEG - 1 do put(1, x + 1, EY1 + 2 - (s + 1) * 4 + 3, 2, 1) end
      if n > 0 then put(min(8, 3 + v * 4), x, EY1 + 2 - n * 4, 3, 1) end
      local pk = floor(peak[b] * SEG + 0.5)
      if pk > n and pk > 0 then put(5 + e * 3, x, EY1 + 2 - pk * 4, 3, 1) end
      if c > 0.5 and n > 1 then
        put(1.5 + c, x + 1, EY1 + 2 - (n + 1 + floor(sin(T * 11 + b) * 2)) * 4, 1, 1)
      end
    end
    -- the station display: dots running on the 16ths, brighter on the bar
    dotsign(1.5 + bp * 3 + mid, 60, 38, 21, S, nil)
    -- the display's label strip
    K.dashes(1 + mid, 60, 2, 4, 0, EX0, EX0 + NB * 4)
  end

  ---------------------------------------------------------------- view 3
  -- the night bus from across the street, side on, the high street sliding
  -- past behind it and its lit decks doubled in the wet road
  local BX0, BX1, BY0, BYB = 26, 100, 13, 46    -- the bus body
  local DK = 27                                 -- the deck line
  local NW = 7                                  -- windows per deck
  local WU0, WU1, WL0, WL1 = 15, 22, 30, 38     -- upper / lower window rows
  local UNIT = 26                               -- a shopfront's width

  local G3 = 0.8                      -- view 3 sits a shade lower, keeping the top for hits
  local function draw3(S)
    local function g(l) return l * G3 + max(0, l - 6) * (1 - G3) end
    local put = function(l, ...) K.put(g(l), ...) end
    local line = function(l, ...) K.line(g(l), ...) end
    local T, DT, DTS, e, c, kl = K.T, K.DT, K.DTS, K.energy, K.chaos, K.kickless
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    -- the phrase, eased (it steps on the bar)
    local ph_to = phrase(S)
    if ph_to < ph3 - 0.5 then ph3 = ph3 - 1 end           -- wrapped: keep easing forward
    ph3 = K.follow(ph3, ph_to, 0.6, DT)
    local ph = clamp(ph3, 0, 1)
    local bp = K.bar_pulse

    local tgt = (0.3 + 0.55 * e + lo * 0.35) * (1 - kl)
    spd = K.follow(spd, tgt, 0.8, DT)
    scr = (scr + DTS * (4 + spd * 20)) % (UNIT * 4096)
    bump = K.follow(bump, bumpv, 0.03, DT)
    -- the bus rides its springs: up on the kick, settling (a pixel at a time)
    local to = floor(bump * 2 + 0.5)
    if to > bob then bob = bob + 1 elseif to < bob then bob = bob - 1 end
    local by = floor(kl * 1.2 + 0.5)                -- it kneels at the stop
    pe = K.follow(pe, pulse, 0.05, DT)
    inner3 = K.follow(inner3, 1.6 + amp * 1.1 + e * 0.6 + pe * 0.5 + flarev * 1.2, 0.08, DT)
    local inner = inner3

    -- background drawn round the bus (it is dark, so it hides what's behind)
    local function bg(l, x, y, w, h)
      w, h = w or 1, h or 1
      if y + h <= BY0 + by or y > BYB + by then put(l, x, y, w, h); return end
      if x < BX0 then put(l, x, y, min(w, BX0 - x), h) end
      if x + w > BX1 + 1 then local a = max(x, BX1 + 1); put(l, a, y, x + w - a, h) end
    end

    -- the sky: the city's glow on low cloud, the towers far off
    K.haze(0, 0, 128, 9, 0.1 + amp * 0.14 + ph * 0.12, 1, scr * 0.15)
    local far = scr * 0.2
    for i = 0, 9 do
      local x = floor((i * 17 - far) % 170) - 21
      local k = i + floor((far + 21 - i * 17) / 170) * 10
      local h = 4 + floor(K.hash(k, 61) * 7)
      bg(1.2, x, 13 - h, 1, h)
      bg(1.2, x + 5, 13 - h, 1, h)
      bg(1, x + 1, 13 - h, 4, 1)
      for w = 0, 1 do
        if K.hash(k * 3 + w, 62) < 0.3 + ph * 0.5 then
          bg(1.5 + hi * 2 * K.hash(k, 63 + w), x + 2 + w, 15 - h + floor(K.hash(k, 64 + w) * (h - 2)), 1, 1)
        end
      end
      -- one tower's warning light marks the bar
      if i == 4 then bg(min(11, 1.5 + bp * 7 + kl * 2), x + 2, 12 - h, 2, 1) end
    end

    -- the shops across the street, sliding past
    local u0 = floor(scr / UNIT)
    for k = u0 - 1, u0 + 6 do
      local x = k * UNIT - scr
      if x > -UNIT and x < 128 then
        local roof = 13 + floor(K.hash(k, 71) * 5)
        local on = K.hash(k, 72) < 0.45 + e * 0.35 + mid * 0.2
        local gl = on and (1.5 + 2.5 * K.hash(k, 73)) or 0.7
        if neon > 0.05 and k % 6 + 1 == neon_i then gl = gl + neon * 4 end
        if slice_l > 0.05 and k % 8 + 1 == slice_i then gl = gl + slice_l * 2.5 end
        gl = min(8, gl * (0.5 + mid * 0.8 + pe * 0.2))
        bg(1.2, x, roof, 1, 41 - roof)                              -- the party wall
        bg(1.2, x + 1, roof, UNIT - 1, 1)                           -- the parapet
        -- the flats above, lit through the phrase (and by the claps)
        for w = 0, 2 do
          local wx = x + 4 + w * 7
          local lit = K.hash(k * 5 + w, 74) < 0.25 + ph * 0.45 + e * 0.15
          local wl = lit and (1.6 + hi * 2 * K.hash(k * 5 + w, 75) + clapv * 4) or 0.6
          bg(wl, wx, roof + 4, 4, 5)
        end
        -- the sign and the glass, its light spilling on the pavement
        bg(1 + gl * 0.35, x + 2, 29, UNIT - 4, 2)
        bg(gl, x + 3, 32, UNIT - 10, 1)
        bg(gl * 0.7, x + 3, 33, UNIT - 10, 6)
        bg(1 + gl * 0.2, x + UNIT - 6, 33, 3, 6)                     -- the door
        bg(1 + gl * 0.25, x + 2, 40, UNIT - 6, 1)
        if c > 0.35 then bg(gl * 0.4 * c, x + 3 + floor(c * 7), 33, UNIT - 10, 5) end
      end
    end
    bg(1.5, 0, 41, 128, 1)                                          -- the kerb

    -- the streetlamps on the far pavement, their light on the bus roof
    local LS = 52
    local lsc = scr * 1.0
    local roofglow = {}
    for i = -1, 3 do
      local x = floor(i * LS - lsc % LS + LS * 0.5)
      if x > -10 and x < 138 then
        local lid = i + floor(lsc / LS)
        local hl = min(12, 4 + hi * 3 + e * 1.5 + K.env.ohat * 5)
        bg(1.6, x, 6, 1, 35)
        put(hl, x - 2, 5, 4, 1)
        K.ring(1 + hi * 1.5 + K.env.ohat * 3, x, 7, 4 + K.env.ohat * 3, 10, 0.2, PI - 0.2, 0.7)
        roofglow[#roofglow + 1] = x
        local _ = lid
      end
    end

    -- the road: wet, the far lane's dashes sliding, splashes in the rain
    K.dashes(1.4, 50, 5, 12, -scr * 1.3)
    -- the bus's lit windows (and its lights) doubled in the wet road
    local function wlev(i, deck)
      local id = i + deck * 10
      local lvl = inner * (0.75 + 0.35 * K.hash(id, 81))
      if slice_l > 0.05 and deck == 0 and i == slice_i - 1 then lvl = lvl + slice_l * 3 end
      if chase_t >= 0 then
        local ch = floor((T - chase_t) / 0.045)
        if ch >= 0 and ch < NW * 2 and ch % NW == i then lvl = lvl + 3.5 end
      end
      if c > 0.4 and K.hash(id + floor(T * 6) * 13, 82) < (c - 0.4) * 0.6 then lvl = lvl * 0.35 end
      return min(11, lvl)
    end
    for i = 0, NW - 1 do
      local x = BX0 + 3 + i * 10
      local wl = wlev(i, 0)
      -- streaks running down the wet tarmac, trembling, longer with the bass
      for r = 0, 2 do
        local sx = x + 1 + r * 2.5 + floor(sin(T * (1.7 + lo * 2) + r * 1.7 + i * 2.3) * (0.6 + lo) + 0.5)
        local len = 4 + floor(K.hash(i * 3 + r, 83) * 4 + lo * 4 + kl * 2)
        local h1 = floor(len * 0.5)
        put(wl * 0.42, sx, 52, 1, h1)
        put(wl * 0.24, sx, 52 + h1, 1, len - h1)
      end
    end

    -- puddle rings at the wheels on the kick
    for i = #ripples, 1, -1 do
      local R = ripples[i]
      local u = (T - R.t0) / 0.7
      if u >= 1 then table.remove(ripples, i)
      elseif u >= 0 then
        K.ring((2 + 4.5 * R.v) * (1 - u), R.x, 52, 2 + u * 14, 14, 0, TAU, 0.22)
      end
    end
    -- the headlights' wash ahead on the road, the brake lights' red smear behind
    local hlv = 1.5 + lo * 2.5 + e + pe * 2
    for y = 47, 52 do
      local w = (y - 46) * 5 + lo * 6
      put(hlv * (1 - (y - 47) / 7), BX1 + 2, y, w, 1)
    end
    local bk = 1.5 + brake * 9 + kl * 3
    put(bk, BX0 - 1, 41 + by, 2, 3)
    if bk > 3 then
      for r = 0, 3 do put(bk * (0.35 - r * 0.07), BX0 - 2 + sin(T * 3 + r) * 0.8, 53 + r * 2, 3, 1) end
    end

    -- the bus: a dark body, lamp-lit edges, two decks of light
    local sw = 0
    for i = #sweeps, 1, -1 do
      local s = sweeps[i]
      local u = (T - s.t0) / (0.3 + s.v * 0.3)
      if u >= 1 then table.remove(sweeps, i)
      elseif u >= 0 then
        local p = BX1 + 4 - u * (BX1 - BX0 + 12)
        local lv = s.v * (1 - u) * 5
        line(2 + lv, p - 4, BY0 + by, p + 4, BY0 + by)
        put(lv * 0.5, p - 3, DK + by, 6, 1)
        sw = max(sw, s.v * (1 - u))
      end
    end
    local el = 1.2 + e * 0.4 + sw * 2 + hi * 0.6
    line(el, BX0 + 3, BY0 + by, BX1 - 4, BY0 + by)                 -- the roof
    line(el, BX0 + 3, BY0 + by, BX0, BY0 + 3 + by)
    line(el, BX1 - 4, BY0 + by, BX1, BY0 + 4 + by)
    for _, x in ipairs(roofglow) do
      if x > BX0 + 2 and x < BX1 - 3 then put(min(8, 2.5 + hi * 2 + e * 1.5), x - 4, BY0 + by, 9, 1) end
    end
    line(el * 0.8, BX0, BY0 + 3 + by, BX0, BYB + by)                -- the back
    line(el, BX1, BY0 + 4 + by, BX1 + 1, BYB + by)                  -- the front
    line(1 + el * 0.3, BX0, BYB + by, BX1, BYB + by)                -- the skirt
    line(1 + mid * 1.2, BX0 + 1, DK - 3 + by, BX1, DK - 3 + by)     -- the deck band
    -- the advert along its side, flashing on the claps
    K.dashes(min(9, 1.4 + clapv * 6 + mid), DK + by, 3, 5, floor(T * 4), 48, 88)
    -- the destination blind: dots marching on the 16ths, STOPPING at the
    -- phrase's last bar
    dotsign(3 + bp * 4, BX0 + 3, DK - 1 + by, 8, S)
    -- the windows, each with its passengers (dark heads against the light)
    for deck = 0, 1 do
      local y0, y1 = deck == 1 and WU0 or WL0, deck == 1 and WU1 or WL1
      for i = 0, NW - 1 do
        local x = BX0 + 3 + i * 10
        local wl = wlev(i, deck)
        local id = i + deck * 10
        local who = K.hash(id, 86) < 0.3 + e * 0.45
        local hx = x + 2 + floor(K.hash(id, 87) * 3)
        local nod = (K.hash(id, 88) < 0.35 and pe > 0.45) and 1 or 0
        local lean = floor(kl * K.hash(id, 89) * 1.5 + 0.5)
        hx = hx + lean
        local htop = y0 + 2 + nod
        for y = y0, y1 do
          local a, b = 7, 0                       -- the silhouette's span in this row
          if who and y >= htop then
            local r = y - htop
            if r == 0 then a, b = hx - x, hx - x + 2
            elseif r <= 2 then a, b = hx - x - (r == 1 and 0 or 0), hx - x + 3
            elseif r == 3 then a, b = hx - x, hx - x + 2
            else a, b = hx - x - 1, hx - x + 4 end
          end
          a, b = clamp(a, 0, 7), clamp(b, 0, 7)
          local row = wl * (1 - (y - y0) * 0.07)
          if a > 0 then put(row, x, y + by, a, 1) end
          if b < 7 then put(row, x + b, y + by, 7 - b, 1) end
        end
        -- rain gathering on the glass while it waits
        if kl > 0.2 and K.hash(id, 90) < kl then
          put(min(12, wl + 2), x + floor(K.hash(id, 91) * 7), y0 + floor(K.hash(id + floor(T * 0.7), 92) * (y1 - y0)) + by, 1, 1)
        end
      end
    end
    -- chaos: a ghost of the lower deck slipped along the body
    if c > 0.35 then
      local gx = floor(sin(T * 2.3) * c * 8 + 0.5)
      for i = 0, NW - 1 do put(inner * 0.3 * c, BX0 + 3 + i * 10 + gx, WL0 + 2 + by, 7, 4) end
    end
    -- the front: the windscreen, the driver, the stopping lamp, the mirror
    local fw = min(10, inner * 0.8)
    -- the windscreen as glass catching the cab light, the driver's shoulder in it
    for k = 0, 4 do
      local x = BX1 - 7 + k * 1.2
      line(fw * (k == 0 and 0.5 or 0.8), x, WL0 - 1 + by, x + 1, WL1 + 3 + by)
    end
    line(1, BX1 - 6, WL0 + 3 + by, BX1 - 5, WL0 + 7 + by)
    for k = 0, 3 do line(min(8, inner * 0.6), BX1 - 6 + k, WU0 + by, BX1 - 6 + k, WU1 + by) end
    put(1 + bell * 10, BX1 - 5, WU0 + 1 + by, 2, 1)
    put(min(12, 2 + glint * 9 + hi * 2), BX1 + 2, WL0 - 1 + by, 1, 3)
    line(2, BX1 + 1, WL0 - 2 + by, BX1 + 2, WL0 - 1 + by)
    put(min(12, 4 + lo * 3 + e * 2 + glare * 4), BX1 - 1, 41 + by, 2, 2) -- the headlamp
    -- the indicator ticking at the stop
    local blink = kl > 0.3 and ((T * 1.6) % 1 < 0.5) and kl or 0
    put(1 + blink * 9, BX1 - 1, 44 + by, 2, 1); put(1 + blink * 9, BX0, 44 + by, 2, 1)
    -- the wheels, turning, and their arches
    for _, wx in ipairs({40, 86}) do
      local wy = BYB + 1 + by - bob
      K.ring(2 + lo * 1.2 + pe * 1.5, wx, wy, 4, 10)
      local a = scr * 0.25
      line(2 + lo * 2, wx + cos(a) * 3, wy + sin(a) * 3, wx - cos(a) * 3, wy - sin(a) * 3)
      put(1.5 + pe * 5, wx, wy, 1, 1)
    end

    -- the rain, slanting with the bus's speed, catching the light
    local nd = 12 + floor(hi * 14 + kl * 10 + shimmer * 6 + e * 4)
    local sl = 1 + spd * 2
    for i = 0, nd - 1 do
      local x0 = K.hash(i, 93) * 140
      local y = ((K.hash(i, 94) * 72 + T * (60 + K.hash(i, 95) * 30)) % 72) - 6
      local x = (x0 - y * sl * 0.3) % 132 - 2
      local l = 1 + K.hash(i, 96) * 0.8 + hi * 1.4 + shimmer * 2 * K.hash(i + floor(T * 8), 97)
        + (flarev > 0.1 and K.hash(i, 98) < 0.4 and flarev * 4 or 0)
      line(l, x, y, x - sl * 0.6, y + 2)
    end
    K.grain(function(u, v) return u * 128, 48 + v * 15 end, 6 + hi * 30 + kl * 10, 3 + hi * 4)
    if glint > 0.05 then
      put(3 + glint * 9, glint_x, glint_y, 1, 1)
      put(1 + glint * 4, glint_x - 1, glint_y, 3, 1)
    end

    -- a car passing close by in the foreground on a fill
    if car3 then
      local u = (T - car3.t0) / 0.8
      if u >= 1 or u < 0 then car3 = nil
      else
        local x = 150 - u * 210
        put(1.4, x, 57, 34, 1)
        line(2.5, x + 4, 57, x + 9, 53); line(2.5, x + 9, 53, x + 22, 53); line(2.5, x + 22, 53, x + 28, 57)
        put(min(12, 6 + (1 - u) * 6), x - 1, 58, 2, 2)
        line(min(11, 3 + (1 - u) * 6), x - 2, 59, x - 26, 61)
        K.ring(3, x + 7, 61, 2.5, 8); K.ring(3, x + 26, 61, 2.5, 8)
      end
    end
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
    clapv = clapv * exp(-DT / 0.2)
    tap[1] = tap[1] * exp(-DT / 0.08)
    tap[2] = tap[2] * exp(-DT / 0.25)
    if chase_t >= 0 and K.T - chase_t > 1.2 then chase_t = -1 end
    if K.view == 2 then draw2(S) elseif K.view == 3 then draw3(S) else draw1(S) end
  end

  M.init()
  return M
end
