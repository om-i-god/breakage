-- trap. view 1: a night car park under one sodium lamp, drizzle in its light, a lowered car's rear with the sub rattling the plate and the puddles.
-- view 2: a city skyline at night under a big moon: hat rolls run along the lit windows, the 808 swells a haze glow, snares flick a searchlight.
-- view 3: from the driver's seat in the rain: city lights blurred to rings through a wet windscreen, the wipers, the dash and the headunit glowing.
--
-- view 1: the long 808 shakes the car (it squats on its springs with the sub,
-- the plate rattles, the underglow pools on the wet tarmac) and rings the
-- puddles, whose lamp reflections wobble with the low end; the snare and
-- clap flare the lamp and its pool; closed hats run glints along the chrome
-- trim, open hats drop a fat drip into a puddle, and a roll sends a train of
-- glints; the cowbell blinks the taillights; ticks buzz the lamp; break
-- slices drip into the puddles; a fill sweeps a passing car's headlights
-- across the wall. behind the wall the towers' windows change bar by bar and
-- low cloud drifts, lit from below by the city; the rain thickens through
-- the phrase. out_amp is the lamp's strength and the cloud's glow, out_lo
-- the car's bounce, plate and puddles, out_mid the glow in the rear window,
-- the taillights and the towers' windows, out_hi the drizzle and the chrome.
-- energy brightens the lamp and thickens the rain, chaos doubles the car and
-- slants the rain, kickless stretches idle the car (exhaust curling up) and
-- let fog in.
-- view 2: closed hats light a window, open hats a run of three, rolls race
-- along a floor; the 808 raises a haze glow over the skyline (out_lo holds
-- it up); snares and claps flick the searchlight across the sky; the cowbell
-- blinks the mast beacon; more windows come on through the phrase and a
-- plane's lights cross on each bar. out_amp lights the moon and the city,
-- out_mid the near towers' edges, out_hi the stars and the window flicker.
-- chaos scrambles windows and multiplies the beams, kickless lets cloud
-- drift over the moon.
-- view 3: the 808 swells the blurred lights and swings the mirror; snares
-- and claps sweep the wipers across, clearing the drops; closed hats bead
-- new drops on the glass, open hats send one running down, rolls a whole
-- trail of them; the cowbell blinks the hazard light on the dash, ticks the
-- indicator; toms and syntoms pump the headunit's bars; a fill floods the
-- glass with a passing car's headlights. the traffic light ahead holds red
-- through the phrase, turns amber near its end and green as the next
-- begins. out_lo swells the lights' rings, out_mid lights the headunit and
-- the dials, out_hi glints the drops, out_amp brightens the city. chaos
-- doubles the rings and scatters drops, kickless stretches mist the glass.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs = math.sin, math.cos, math.floor, math.max, math.min, math.abs
  local PI = math.pi

  ---------------------------------------------------------------- state
  local LX, LY = 38, 8                           -- the lamp head
  local GY = 44                                  -- the far edge of the tarmac
  local CX0, CX1, CB = 70, 122, 52               -- the car: left, right, body bottom
  local PUD = {{x = 22, y = 56, w = 13}, {x = 52, y = 49, w = 9}, {x = 96, y = 60, w = 15}}

  local flare, buzz, sub, tail, sweep
  local fs, ss                                   -- eased flare and sub
  local glints, rings, drips, puffs
  -- view 2
  local runs, beams, haze, hs, beacon, swing
  local NB = 9                                   -- near buildings
  local bars, plane, fat
  -- view 3
  local beads, runsd, wipe, wdir, mirror, mv, haz3, ind, eq, flood

  function M.init()
    flare, buzz, sub, tail, sweep = 0, 0, 0, 0, -1
    fs, ss = 0, 0
    glints, rings, drips, puffs = {}, {}, {}, {}
    runs, beams = {}, {{a = -0.5, va = 0, lv = 0, b = 2}, {a = 0.4, va = 0, lv = 0, b = 7}}
    haze, hs, beacon, swing = 0, 0, 0, 0
    bars, plane, fat = 0, -1, {}
    beads, runsd = {}, {}
    wipe, wdir, mirror, mv, haz3, ind, flood = 9, 1, 0, 0, 0, 0, -1
    eq = {0, 0, 0, 0, 0, 0, 0, 0}
  end
  M.clear = M.init

  local function ring(p, lv)
    if #rings >= 10 then table.remove(rings, 1) end
    local P = PUD[p]
    rings[#rings + 1] = {x = P.x + (K.rnd() - 0.5) * P.w, y = P.y, t0 = K.T, lv = lv, w = P.w}
  end

  local function glint(t0, sp, lv)
    if #glints >= 12 then table.remove(glints, 1) end
    glints[#glints + 1] = {t0 = t0, sp = sp, lv = lv}
  end

  local function run(lv, n, fast)
    if #runs >= 6 then table.remove(runs, 1) end
    local b = 1 + floor(K.rnd() * NB)
    runs[#runs + 1] = {b = b, row = floor(K.rnd() * 6), t0 = K.T, lv = lv, sp = fast and 60 or 30, n = n or 1}
  end

  local function bead(x, y, lv)
    if #beads >= 34 then table.remove(beads, 1) end
    beads[#beads + 1] = {x = x or (6 + K.rnd() * 116), y = y or (6 + K.rnd() * 38), lv = lv or 1, t0 = K.T}
  end
  local function trickle(v, x)
    if #runsd >= 8 then table.remove(runsd, 1) end
    runsd[#runsd + 1] = {x = x or (8 + K.rnd() * 112), y0 = 4 + K.rnd() * 18, t0 = K.T, v = v, sp = 14 + K.rnd() * 10}
  end
  local function bump(i, v)
    i = clamp(floor(i), 1, 8)
    eq[i] = max(eq[i], v)
  end

  function M.kick(v)
    v = K.num(v, 1)
    mv = mv + (K.rnd() < 0.5 and -1 or 1) * 2.5 * v
    bump(1, v); bump(2, 0.8 * v)
    sub = max(sub, 0.6 + 0.4 * v)
    for p = 1, 3 do ring(p, 3 + 4 * v) end
    haze = min(1.3, haze + 0.6 * v)
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    flare = max(flare, 0.6 + 0.4 * v)
    if wipe > 1 then wipe, wdir = 0, -wdir end
    bump(4, 0.8 * v); bump(5, 0.6 * v)
    for _, b in ipairs(beams) do
      b.va = b.va + (K.rnd() < 0.5 and -1 or 1) * (2.5 + 2 * v)
      b.lv = max(b.lv, 0.7 + 0.3 * v)
    end
    swing = 1
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.85) end

  function M.hat(v, open)
    v = K.num(v, 1)
    glint(K.T, open and 45 or 80, 4 + 6 * v)
    run(3 + 6 * v, open and 3 or 1, false)
    if open then
      if #fat < 3 then fat[#fat + 1] = {p = 1 + floor(K.rnd() * 3), t0 = K.T, v = v} end
      trickle(v)
    else
      bead(nil, nil, 0.5 + v)
    end
    bump(7, 0.5 * v); bump(8, (open and 0.8 or 0.5) * v)
  end
  function M.rim(v) M.hat(K.num(v, 1) * 0.7, false) end
  function M.ride(v) M.hat(K.num(v, 1) * 0.6, true) end
  function M.shaker(v) glint(K.T, 110, 3 + 3 * K.num(v, 1)) end

  function M.ratchet(n, voice)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    for k = 0, n - 1 do glint(K.T - k * 0.05, 90, 9 - k * 0.4) end
    local x = 10 + K.rnd() * 100
    for k = 0, min(n, 6) - 1 do bead(x + k * 3, 8 + K.rnd() * 30, 1.5) end
    trickle(1, x)
    for i = 1, 8 do bump(i, 0.5 + 0.06 * n) end
    run(9, n, true)
    run(7, n, true)
    for p = 1, 3 do ring(p, 4) end
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 3 then
      tail = max(tail, 0.8 + 0.2 * v)
      beacon = 1
      haz3 = 1
    elseif kind == 14 or kind == 17 or kind == 13 then
      sub = max(sub, 0.5 * v)
      haze = min(1.3, haze + 0.3 * v)
      bump(2 + floor(K.rnd() * 4), 0.7 + 0.3 * v)
    else
      tail = max(tail, 0.4 * v)
      bump(5 + floor(K.rnd() * 3), 0.6 * v)
      run(2 + 5 * v, 2, false)
      ring(1 + floor(K.rnd() * 3), 2 + 3 * v)
    end
  end
  function M.tom(v) M.perc(17, K.num(v, 1)) end

  function M.tick() buzz = max(buzz, 0.6); ind = 1 end

  function M.brk(s, n)
    s = K.num(s, 1)
    if #drips < 6 then drips[#drips + 1] = {p = (floor(s) % 3) + 1, t0 = K.T} end
    if s % 2 == 1 then run(4, 1, true) end
  end

  function M.bar()
    bars = bars + 1
    if plane < 0 then plane = 0 end
  end

  local function phrase()
    local S = K.S or {}
    local len = max(1, K.num(S.phrase_len, 16))
    return clamp(K.num(S.phrase_pos, 0) / len + K.bar_ph / len, 0, 1)
  end

  function M.fill()
    sweep = 0
    flood = 0
    for _, b in ipairs(beams) do b.lv = 1; b.va = b.va + 3 end
    beacon = 1
  end

  ---------------------------------------------------------------- view 1
  local WALL = K.profile(function(x)
    local h = 10
    if x > 84 and x < 112 then h = 16 end
    if x < 14 then h = 13 end
    return GY - h
  end)

  local function car(dx, dy, lv, mid, hi, lo, ghost)
    local x0, x1 = CX0 + dx, CX1 + dx
    local b = CB + dy
    local w = x1 - x0
    local cx = (x0 + x1) / 2
    -- the tyres, black under the sills, the sub's glow on the tarmac
    if not ghost then
      local ug = 1 + lo * 4 + ss * 4
      put(ug, x0 + 6, CB + 3, w - 12, 1)
      put(ug * 0.5, x0 + 2, CB + 4, w - 4, 1)
      put(1.5, x0 + 2, b, 7, 3)
      put(1.5, x1 - 9, b, 7, 3)
    end
    -- the body: roof, rear window, boot, bumper
    local rt = b - 21
    line(lv * 0.9, x0 + 12, rt, x1 - 12, rt)                       -- roof
    line(lv * 0.7, x0 + 12, rt, x0 + 7, rt + 8)
    line(lv * 0.7, x1 - 12, rt, x1 - 7, rt + 8)
    if not ghost then
      -- the rear window: the dash and the headunit glowing inside
      for y = rt + 1, rt + 7 do
        local u = (y - rt) / 8
        local a, c = x0 + 12 - u * 5, x1 - 12 + u * 5
        put(1 + mid * 2.2 + (y == rt + 6 and mid * 2 or 0), a + 1, y, c - a - 1, 1)
      end
      put(2 + mid * 6 + K.env.kick * 2, cx - 3, rt + 6, 6, 1)
    end
    line(lv, x0 + 6, rt + 8, x1 - 6, rt + 8)                       -- the boot lid
    line(lv * 0.8, x0 + 1, rt + 10, x0 + 6, rt + 8)
    line(lv * 0.8, x1 - 1, rt + 10, x1 - 6, rt + 8)
    line(lv * 0.8, x0, rt + 10, x0, b - 1)
    line(lv * 0.8, x1, rt + 10, x1, b - 1)
    if ghost then return end
    put(1, x0 + 1, rt + 10, w - 1, b - rt - 10)                     -- the panel
    -- taillights
    local tl = 2.5 + mid * 2.5 + tail * 8
    put(tl, x0 + 2, rt + 11, 10, 2)
    put(tl, x1 - 11, rt + 11, 10, 2)
    -- the chrome trim, glints running along it
    local ty = rt + 14
    line(2.5 + hi * 2, x0 + 2, ty, x1 - 2, ty)
    for i = #glints, 1, -1 do
      local G = glints[i]
      local age = K.T - G.t0
      local gx = x0 + 2 + age * G.sp
      if gx > x1 - 2 then table.remove(glints, i)
      elseif age >= 0 then
        put(min(13, G.lv + hi * 3), gx, ty, 2, 1)
        put(G.lv * 0.4, gx - 3, ty, 3, 1)
      end
    end
    -- the plate: rattling with the sub
    local rat = (lo > 0.35 or ss > 0.3) and ((floor(K.T * 24) % 2) * 2 - 1) * min(1, lo + ss) or 0
    local px, py = cx - 7 + rat * 0.6, rt + 16 + floor(abs(rat) * 0.6 + 0.5)
    put(3 + lo * 2 + fs * 2, px, py, 14, 4)
    for k = 0, 4 do put(1, px + 2 + k * 2.2, py + 1, 1, 2) end
    -- the taillights' red smear on the wet tarmac
    for k = 0, 1 do
      local tx = k == 0 and x0 + 6 or x1 - 6
      for j = -1, 1 do line((mid * 3 + tail * 5) * (1 - abs(j) * 0.4), tx + j * 2, CB + 4, tx + j * 2, CB + 9 + mid * 3) end
    end
    -- the bumper
    line(2 + hi * 1.5, x0 + 1, b - 1, x1 - 1, b - 1)
    -- exhaust (kickless: idling vapour)
    put(2, x1 - 14, b, 3, 1)
  end

  local function draw1(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local lamp = 0.45 + amp * 0.5 + fs * 0.5 + e * 0.15
    -- sodium buzz: a little uneven, never a strobe
    lamp = lamp * (1 - buzz * 0.25 * (0.5 + 0.5 * sin(T * 37))) * (1 - c * 0.12 * (0.5 + 0.5 * sin(T * 13.7)))

    -- beyond the wall: low cloud lit from below by the city, two tower
    -- blocks whose windows change bar by bar, a plane's light crossing
    local ph = phrase()
    K.haze(0, 1, 128, 14, 0.18 + amp * 0.18 + e * 0.06, 1, T * 2.5)
    for t = 0, 1 do
      local x0, x1, top = t == 0 and 58 or 98, t == 0 and 74 or 110, t == 0 and 14 or 19
      local base = floor(K.at(WALL, (x0 + x1) / 2))
      line(1 + amp * 0.6, x0, top, x0, base)
      line(1 + amp * 0.6, x1, top, x1, base)
      line(1 + amp * 0.6, x0, top, x1, top)
      for wy = top + 2, base - 2, 3 do
        for wx = x0 + 2, x1 - 2, 3 do
          local h = K.hash(wx * 7 + wy * 131, bars + t * 5)
          if h < 0.3 + ph * 0.2 then put(1 + mid * 2.5 * h * 3, wx, wy, 1, 1) end
        end
      end
    end
    if plane >= 0 then
      local px = -4 + plane * 140
      put(1.5 + 4 * max(0, sin(T * 9)), px, 6 + plane * 4, 1, 1)
      put(1.5, px - 2, 6 + plane * 4, 1, 1)
    end
    -- the wall behind the lot: panel seams, a few lit windows, the passing
    -- car's headlight sweep on a fill
    for x = 2, 126, 8 do
      local top = floor(K.at(WALL, x))
      local d = abs(x - LX) / 90
      line(1 + lamp * 1.5 * max(0, 1 - d), x, top, x, GY - 1)
    end
    for c2 = 0, 63 do
      local top = WALL[c2]
      if c2 % 2 == 0 then put(1 + lamp * 0.8 * max(0, 1 - abs(c2 * 2 - LX) / 70), c2 * 2, top, 3, 1) end
    end
    for i = 0, 6 do
      local x = 6 + floor(K.hash(i, 3) * 116)
      local y = floor(K.at(WALL, x)) + 3 + floor(K.hash(i, 4) * 4)
      put(1.5 + 2 * K.hash(i, 5) + mid * 1.5, x, y, 3, 2)
    end
    if sweep >= 0 then
      sweep = sweep + K.DTS / 1.6
      if sweep > 1 then sweep = -1
      else
        local sx = -10 + sweep * 148
        for k = -3, 3 do
          line(6 * (1 - abs(k) / 4) * sin(PI * sweep), sx + k * 2, floor(K.at(WALL, sx + k * 2)) + 1, sx + k * 2, GY - 1)
        end
      end
    end

    -- the tarmac: bay lines running toward us, the lamp's pool
    for k = -3, 4 do
      local xb = 20 + k * 30
      line(1.5 + lamp * 1.2, 64 + (xb - 64) * 0.55, GY + 1, xb, 63)
    end
    for y = GY + 1, 63 do
      local u = (y - GY) / (63 - GY)
      local hw = 8 + u * 26 + lamp * 6
      local l = (1 + lamp * 3.5 + fs * 2) * (1 - abs(y - 52) / 20)
      if l >= 1 then put(min(7, l), LX - hw, y, hw * 2, 1) end
    end

    -- the puddles: dark mirrors holding the lamp's reflection, which
    -- wobbles with the low end; rings on the 808
    for p, P in ipairs(PUD) do
      local wob = sin(T * 23 + p) * (lo * 1.6 + ss * 1.5)
      K.ring(1.5 + lamp * 1.5, P.x, P.y, P.w * 0.5, 14, 0, K.TAU, 0.25)
      local rx = P.x + (LX - P.x) * 0.15
      for k = -1, 1 do
        local x = rx + k + wob * (1 - abs(k) * 0.5)
        line((3 + lamp * 6 + fs * 4) * (1 - abs(k) * 0.45), x, P.y - 2, x, P.y + 1)
      end
    end
    for i = #rings, 1, -1 do
      local R = rings[i]
      local age = T - R.t0
      local life = 0.9 + e * 0.5
      if age > life then table.remove(rings, i)
      else
        local u = age / life
        K.ring(R.lv * (1 - u) + lo, R.x, R.y, 1 + age * 14, 12, 0, K.TAU, 0.25)
      end
    end
    for i = #fat, 1, -1 do
      local F = fat[i]
      local age = T - F.t0
      local P = PUD[F.p]
      if age > 0.8 then table.remove(fat, i)
      elseif age < 0.18 then
        local y = P.y - 16 + age / 0.18 * 16
        line(4 + 6 * F.v, P.x - 3, y - 3, P.x - 3, y)
      else
        local u = (age - 0.18) / 0.62
        K.ring((3 + 6 * F.v) * (1 - u), P.x - 3, P.y, 2 + u * P.w * 0.8, 14, 0, K.TAU, 0.25)
        K.ring((2 + 3 * F.v) * (1 - u), P.x - 3, P.y, 1 + u * P.w * 0.4, 10, 0, K.TAU, 0.25)
      end
    end
    for i = #drips, 1, -1 do
      local D = drips[i]
      local age = T - D.t0
      if age > 0.5 then table.remove(drips, i)
      else
        local P = PUD[D.p]
        if age < 0.15 then line(6, P.x + 2, P.y - 8 + age * 50, P.x + 2, P.y - 6 + age * 50)
        else K.ring(5 * (1 - age / 0.5), P.x + 2, P.y, 1 + (age - 0.15) * 20, 10, 0, K.TAU, 0.25) end
      end
    end

    -- the car, squatting on its springs with the sub
    local dy = floor(lo * 1.4 + ss * 1.2 + 0.5)
    if c > 0.35 then car(-6 - c * 10, dy, 1.5 + c * 1.5, mid, hi, lo, true) end
    car(0, dy, 3 + amp * 1.5 + e, mid, hi, lo, false)
    -- idling vapour when the kick's gone
    for i = #puffs, 1, -1 do
      local P = puffs[i]
      local age = T - P.t0
      if age > 2 then table.remove(puffs, i)
      else put(2.5 * (1 - age / 2), CX1 - 14 - age * 6 + sin(age * 4 + P.s) * 2, CB - age * 9, 2, 2) end
    end
    if kl > 0.3 and #puffs < 8 and K.rnd() < 0.12 * K.SP then puffs[#puffs + 1] = {t0 = T, s = K.rnd() * 6} end

    -- the lamp: pole, arm, head and the drizzle in its light
    line(2.5, 26, LY, 26, GY + 4)
    line(2.5, 26, LY, LX - 3, LY)
    put(min(12, 5 + lamp * 7), LX - 4, LY, 9, 2)
    K.ring(1 + lamp * 2, LX, LY + 1, 6 + lamp * 3, 12, 0, PI)
    local slant = c * 3 + 1
    local nr = floor(8 + e * 6 + hi * 16 + ph * 8)
    for i = 0, nr - 1 do
      local spd = 40 + K.hash(i, 1) * 20
      local yy = (K.hash(i, 2) * 50 + T * spd) % 46 + LY + 3
      local u = (yy - LY) / (GY + 10 - LY)
      local xx = LX + (K.hash(i, 3) - 0.5) * (8 + u * 60) - (yy - LY) * 0.05 * slant
      line((1.2 + hi * 4 + lamp * 1.5) * (1 - u * 0.5), xx, yy, xx - slant * 0.5, yy + 3)
    end
    if kl > 0.2 then K.haze(0, GY - 6, 128, GY + 8, kl * 0.4, 1, T * 4) end
    K.grain(function(u, v) return u * 128, GY + 2 + v * 19 end, 1 + hi * 30, 3 + hi * 6)
  end

  ---------------------------------------------------------------- view 2
  local HZ = 40                                  -- the skyline's base glow line
  local FAR = K.profile(function(x)
    return HZ - 6 - floor(K.hash(x // 6, 11) * 8) - (x > 40 and x < 52 and 8 or 0)
  end)
  local BLD = {}                                 -- near buildings: x, w, top
  do
    local x = -2
    for i = 1, NB do
      local w = 10 + floor(K.hash(i, 21) * 8)
      local top = 22 + floor(K.hash(i, 22) * 16)
      if i == 4 then top = 12; w = 12 end       -- the tower with the mast
      BLD[i] = {x = x, w = w, top = top}
      x = x + w + 3
    end
  end
  -- the near and far skylines together: the haze glows only above both
  local SKY2 = K.profile(function(x)
    local t = FAR[math.min(64, x // 2)]
    for _, B in ipairs(BLD) do
      if x >= B.x and x <= B.x + B.w then t = math.min(t, B.top) end
    end
    return t
  end)

  local function draw2(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    haze = haze * math.exp(-DT / 1.1)
    hs = K.follow(hs, clamp(haze * 0.45 + lo * 0.8, 0, 1.3), 0.12, DT)
    beacon = beacon * math.exp(-DT / 0.3)
    swing = swing * math.exp(-DT / 0.4)

    -- stars and the moon
    for i = 0, 22 do
      local x, y = floor(K.hash(i, 1) * 128), floor(K.hash(i, 2) * 24)
      local tw = 0.5 + 0.5 * sin(T * (1 + K.hash(i, 3) * 2) + i)
      put(1 + tw * (0.5 + hi * 3.5), x, y, 1, 1)
    end
    local mx, my, mr = 98, 15, 11
    local ml = 2 + amp * 2 + kl * 1.5 + e * 0.5
    K.disc(ml, mx, my, mr)
    K.disc(ml + 1.5, mx - 2, my - 2, mr * 0.55)
    for k = 1, 4 do
      K.disc(ml - 0.8, mx + (K.hash(k, 7) - 0.5) * 12, my + (K.hash(k, 8) - 0.5) * 12, 1.2 + K.hash(k, 9) * 1.8)
    end
    if c > 0.4 then K.ring(1 + c * 2, mx - c * 8, my + 2, mr, 16) end
    -- cloud drifting over the moon in the kickless stretches
    if kl > 0.1 then
      for k = 0, 2 do
        local cx = (T * 4 + k * 40) % 170 - 20
        local x0 = floor(clamp(cx, 0, 127))
        local x1 = floor(clamp(cx + 30, 0, 128))
        if x1 > x0 + 1 then
          K.row_above(1 + kl, 8 + k * 6, SKY2, x0, x1)
          K.row_above(1 + kl, 9 + k * 6, SKY2, x0, x1)
        end
      end
    end

    -- the searchlights: beams from behind the skyline swinging over the sky
    local nbm = c > 0.6 and 2 or 1
    for i, b in ipairs(beams) do
      b.va = b.va - b.a * 0.8 * DT - b.va * 0.9 * DT
      b.a = clamp(b.a + (b.va + sin(T * 0.25 + i * 2) * 0.12) * K.DTS, -0.75, 0.75)
      b.lv = b.lv * math.exp(-DT / 0.6)
      local l = 1.2 + amp * 0.5 + b.lv * 4
      local B = BLD[b.b]
      for m = 0, nbm - 1 do
        local a = b.a + m * 0.35
        local x0, y0 = B.x + B.w / 2, B.top - 1
        local x1, y1 = x0 + sin(a) * 70, y0 - cos(a) * 70
        line(l, x0, y0, x1, y1)
        line(l * 0.45, x0 + 1, y0, x1 + 6, y1)
        put(3 + b.lv * 6, x0 - 1, y0, 3, 1)
      end
    end

    -- the haze over the skyline: three solid bands, lifted by the 808
    local hh = 4 + hs * 12 + e * 2
    for k = 0, 2 do
      local y0 = floor(HZ - hh * (1 - k / 3))
      local l = 1 + k * 0.5 + hs * (0.8 + k * 0.8) + amp * 0.4
      for y = y0, floor(HZ - hh * (1 - (k + 1) / 3)) do K.row_above(min(6, l), y, SKY2) end
    end

    -- the far skyline: dark, with a few dim windows; the near towers in
    -- front with their windows and lit edges
    for i = 0, 30 do
      local x = floor(K.hash(i, 31) * 126)
      local y = floor(K.at(FAR, x) + 2 + K.hash(i, 32) * 6)
      if y < HZ + 6 then put(1 + K.hash(i, 33) * 1.5 + amp, x, y, 1, 1) end
    end
    for i, B in ipairs(BLD) do
      local x0, x1, top = B.x, B.x + B.w, B.top
      local edge = 1.5 + mid * 3 + hs
      line(edge, x0, top, x0, 63)
      line(edge * 0.6, x1, top, x1, 63)
      line(edge, x0, top, x1, top)
      -- windows: a grid; some always lit, runs travel along a floor
      for row = 0, 7 do
        local wy = top + 3 + row * 4
        if wy > 61 then break end
        for col = 0, floor((B.w - 3) / 3) do
          local wx = x0 + 2 + col * 3
          local h = K.hash(i * 97 + row * 13 + col, 41)
          local l = 0
          if h < 0.3 + e * 0.15 + phrase() * 0.12 then
            l = 1 + h * 2 + amp * 0.8 + hi * 2.5 * (0.5 + 0.5 * sin(T * 3 + h * 40))
          end
          if c > 0.4 and K.hash(i * 97 + row * 13 + col + floor(T * 4), 43) < c * 0.12 then l = l + 2.5 end
          if l > 0.5 then put(l, wx, wy, 2, 2) end
        end
      end
      if i == 4 then
        line(2 + mid * 2, x0 + B.w / 2, top - 8, x0 + B.w / 2, top)
        put(2 + beacon * 10 + (0.5 + 0.5 * sin(T * 2)) * 2, x0 + B.w / 2 - 1, top - 9, 3, 1)
      end
    end
    -- the runs: a light travelling along one floor of a tower
    for j = #runs, 1, -1 do
      local R = runs[j]
      local B = BLD[R.b]
      local age = T - R.t0
      local n = floor((B.w - 3) / 3) + 1
      local pos = age * R.sp / 3
      if pos > n + R.n + 2 then table.remove(runs, j)
      else
        local wy = B.top + 3 + R.row * 4
        for k = 0, R.n - 1 do
          local col = floor(pos) - k * 2
          if col >= 0 and col < n and wy < 62 then
            put(min(13, R.lv * (1 - k / (R.n + 1))), B.x + 2 + col * 3, wy, 2, 2)
          end
        end
      end
    end
    -- a plane crossing on the bar
    if plane >= 0 then
      local px = -4 + plane * 140
      put(1.5 + 4 * max(0, sin(T * 9)), px, 4 + plane * 5, 1, 1)
      put(1.5 + hi, px - 2, 4 + plane * 5, 1, 1)
    end
    -- the rooftop we stand on: a rail and its posts
    line(1.5 + amp * 0.5, 0, 58, 127, 58)
    for x = 3, 127, 9 do line(1.5 + mid, x, 58, x, 63) end
    K.grain(function(u, v) return u * 128, v * 30 end, 2 + hi * 12, 3 + hi * 5)
  end


  ---------------------------------------------------------------- view 3
  local DY3 = 46                                 -- the dash's top edge, middle
  local function dash_y(x) return DY3 + ((x - 64) / 64) ^ 2 * 6 end
  local BOK = {}
  for i = 1, 18 do
    BOK[i] = {x = K.hash(i, 91) * 150, y = 8 + K.hash(i, 92) * 28, r = 1.5 + K.hash(i, 93) ^ 2 * 5, l = K.hash(i, 94)}
  end
  local WP = {{x = 20, y = 50, len = 46}, {x = 68, y = 50, len = 44}}
  local A_REST = -0.06
  local tl3 = {0, 0, 0}                          -- the traffic light's lamps, eased
  local creep, sb3 = 0, 0

  local function wiper_a()
    if wipe >= 1 then return A_REST end
    return A_REST - (PI - 0.7) * sin(PI * wipe)
  end

  local function draw3(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local ph = phrase()
    wipe = wipe + K.DTS / 0.6
    mv = mv - mirror * 60 * DT - mv * 5 * DT
    mirror = clamp(mirror + mv * DT, -4, 4)
    haz3 = haz3 * math.exp(-DT / 0.35)
    ind = ind * math.exp(-DT / 0.25)
    for i = 1, 8 do eq[i] = eq[i] * math.exp(-DT / 0.18) end
    sb3 = K.follow(sb3, sub, 0.2, DT)
    creep = creep + K.DTS * (0.6 + e * 1.2) * (1 - kl * 0.7)

    -- the city through the wet glass: lights blurred into rings
    for i, B in ipairs(BOK) do
      local x = (B.x - creep * (2 + B.l * 3)) % 150 - 11
      local r = B.r + lo * 1.2 + sb3 * 1.4
      local l = (1 + B.l * 1.3 + amp * 1.1) * (1 - kl * 0.3)
      if B.y + r < dash_y(x) then
        if B.l > 0.45 then K.disc(1, x, B.y, r - 0.5) end
        K.ring(l, x, B.y, r, 12)
        if c > 0.4 then K.ring(l * 0.4, x + c * 5, B.y + 1, r, 10) end
      end
    end
    -- the traffic light ahead: red through the phrase, amber at its end,
    -- green as the next begins
    local st = (ph > 0.97 or ph < 0.08) and 3 or (ph > 0.85 and 2 or 1)
    for k = 1, 3 do tl3[k] = K.follow(tl3[k], st == k and 1 or 0, 0.15, DT) end
    local tx, ty = 100, 7
    line(1.5, tx - 3, ty - 2, tx - 3, ty + 14)
    line(1.5, tx + 3, ty - 2, tx + 3, ty + 14)
    line(1.2, tx, ty + 15, tx, 30)
    for k = 1, 3 do
      local ly = ty + (k - 1) * 5
      local l = 1.2 + tl3[k] * (5 + amp * 2)
      K.disc(l, tx, ly + 1, 1.6)
      if tl3[k] > 0.1 then K.ring(tl3[k] * (2 + amp), tx, ly + 1, 4 + lo, 10) end
    end
    -- a fill: a passing car's lights flood across the glass
    if flood >= 0 then
      flood = flood + K.DTS / 1.3
      if flood > 1 then flood = -1
      else
        local fx = -20 + flood * 170
        local fl = sin(PI * flood)
        K.disc(2 + fl * 4, fx, 30, 5)
        K.disc(2 + fl * 4, fx + 18, 30, 5)
        K.ring(1 + fl * 3, fx + 9, 30, 16, 16)
      end
    end
    if kl > 0.1 then K.haze(14, 3, 114, 42, kl * 0.5, 1 + kl, T * 2) end

    -- the glass: beads of rain, and drops running down
    K.grain(function(u, v) return 14 + u * 100, 4 + v * 38 end, 1 + hi * 6, 3 + hi * 4)
    local rate = (1.5 + e * 3 + kl * 4 + ph * 3) * K.DTS
    if K.rnd() < rate then bead(nil, nil, 0.4 + K.rnd() * 0.6) end
    local wa = wiper_a()
    for i = #beads, 1, -1 do
      local B = beads[i]
      local wiped = false
      if wipe < 1 then
        for _, W in ipairs(WP) do
          local dx, dy = B.x - W.x, B.y - W.y
          local a = math.atan(dy, dx)
          if dx * dx + dy * dy < W.len * W.len and a >= wa - 0.05 and a <= A_REST + 0.05 then wiped = true end
        end
      end
      if wiped then table.remove(beads, i)
      else
        local x = B.x + (c > 0.4 and sin(T * 3 + i) * c * 1.5 or 0)
        local age = T - B.t0
        local l = 2 + B.lv * 2 + hi * 3 * (0.5 + 0.5 * sin(T * 2 + i * 1.7)) + max(0, 1 - age * 4) * 4
        put(l, x, B.y, 1, 1)
        if B.lv > 1 then put(l * 0.5, x, B.y + 1, 1, 1) end
      end
    end
    for i = #runsd, 1, -1 do
      local R = runsd[i]
      local age = T - R.t0
      local y = R.y0 + age * R.sp + age * age * 6
      if y > dash_y(R.x) - 1 then table.remove(runsd, i)
      else
        local l = 3 + 6 * R.v
        put(l, R.x, y, 1, 2)
        line(l * 0.35, R.x, max(R.y0, y - 8), R.x, y - 1)
      end
    end

    -- the windscreen's frame: the pillars, the roof, the mirror
    line(2, 0, 40, 15, 0)
    line(1.5, 3, 42, 18, 0)
    line(2, 127, 40, 112, 0)
    line(1.5, 124, 42, 109, 0)
    line(1.2, 15, 0, 112, 0)
    local mx = 64 + mirror
    line(1.5, 64, 0, mx, 3)
    put(1, mx - 12, 4, 24, 5)
    line(1.5 + amp * 0.7, mx - 12, 3, mx + 12, 3)
    line(1.5 + amp * 0.7, mx - 12, 9, mx + 12, 9)
    line(2 + amp, mx - 13, 4, mx - 13, 8)
    line(2 + amp, mx + 13, 4, mx + 13, 8)
    line(1.5 + amp * 2 + fs, mx - 8, 6, mx + 8, 6)              -- the rear window in it

    -- the wipers
    for _, W in ipairs(WP) do
      local ex, ey = W.x + cos(wa) * W.len, W.y + math.sin(wa) * W.len
      line(1.5 + amp, W.x, W.y, ex, ey)
      local px, py = -math.sin(wa), cos(wa)
      line(2.5 + amp + (wipe < 1 and 1.5 or 0), W.x + px + cos(wa) * 8, W.y + py + math.sin(wa) * 8, ex + px, ey + py)
    end

    -- the dash: its edge, the dials, the headunit and its bars
    local px, py
    for k = 0, 16 do
      local x = k * 8
      local y = dash_y(x)
      if px then line(1.5 + mid * 1.2, px, py, x, y) end
      px, py = x, y
    end
    K.ring(1.5 + mid * 1.5, 28, 60, 13, 14, PI, K.TAU)
    for d = 0, 1 do
      local dx = d == 0 and 22 or 35
      K.ring(1.5 + mid * 2.5, dx, 59, 4.5, 10)
      local a = PI * 0.8 + (PI * 1.4) * clamp(d == 0 and (0.2 + amp * 0.7) or (0.3 + lo * 0.4 + e * 0.2), 0, 1)
      line(3 + mid * 4, dx, 59, dx + cos(a) * 4, 59 + math.sin(a) * 4)
    end
    -- the indicator and the hazard triangle
    put(1.2 + ind * 9, 43, 52, 2, 1)
    line(1.2 + ind * 9, 41, 52, 43, 50)
    line(1.2 + ind * 9, 41, 52, 43, 54)
    local hl = 1.5 + haz3 * 9
    line(hl, 64, 48, 61, 53)
    line(hl, 64, 48, 67, 53)
    line(hl, 61, 53, 67, 53)
    -- the headunit: a screen, eight bars pumping with the hits and the bands
    put(1, 50, 55, 28, 8)
    line(1.5 + mid * 1.5, 50, 55, 77, 55)
    line(1.5 + mid * 1.5, 50, 55, 50, 63)
    line(1.5 + mid * 1.5, 77, 55, 77, 63)
    local band = {lo, lo, mid, mid, mid, hi, hi, amp}
    for i = 1, 8 do
      local h = clamp(1 + eq[i] * 5 + band[i] * 2.5, 1, 7)
      put(min(12, 3 + mid * 3 + eq[i] * 4), 51 + (i - 1) * 3, 63 - h, 2, h)
    end
    -- the steering wheel
    K.ring(2 + amp, 28, 82, 28, 16, PI * 1.18, PI * 1.82)
    K.ring(1.5, 28, 82, 24, 14, PI * 1.2, PI * 1.8)
  end

  function M.draw(S)
    local DT = K.DT
    if plane >= 0 then
      plane = plane + K.DTS / 7
      if plane > 1 then plane = -1 end
    end
    flare = flare * math.exp(-DT / 0.22)
    buzz = buzz * math.exp(-DT / 0.25)
    sub = sub * math.exp(-DT / 0.6)                -- the 808 rings long
    tail = tail * math.exp(-DT / 0.25)
    fs = K.follow(fs, flare, 0.05, DT)
    ss = K.follow(ss, sub, 0.04, DT)
    if K.view == 2 then draw2(S) elseif K.view == 3 then draw3(S) else draw1(S) end
  end

  M.init()
  return M
end
