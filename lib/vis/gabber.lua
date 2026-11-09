-- gabber. view 1: a press shop on the night shift, two massive presses slamming on the kick beside a redlining gauge.
-- view 2: an extreme close-up of a speaker cone pumping, its waveform clipping square on the kick inside a distortion halo.
-- view 3: the hakken floor: a wall of bass bins behind a crowd stomping the
-- 16ths, lamps on the truss above, smoke, lasers when a ratchet fires.
--
-- view 1: the rams drop onto their dies on the kick (in turn; both at once
-- when the energy is up) and climb back over the beat; each blow throws a
-- spray of sparks both ways along the bed, jolts the floor, glows the
-- plate on the die and vents steam out of the crown. noise snares spit
-- sparks off a die and kick dust off the floor; ring-mod ticks arc between
-- a press's columns; hats hiss steam. a ratchet hammers one press that many
-- times. the gauge reads the energy, shivers with the lows and pins in the
-- red at the top, lighting the warning lamp; the crane hook behind sways.
-- chaos knocks the presses out of step, ghosts the rams, cracks the floor
-- and shakes the needle. kickless: the rams park up, steam hisses steadily
-- and the gauge sags. a stamped plate goes on the stack by the line each
-- bar, the stack cleared at the end of the phrase.
-- view 2: the kick throws the cone out at us (the inner rings swell more
-- than the outer), squares off the trace and flares the halo; snares fuzz
-- the trace and the cone's ribs; ring-mod ticks tremble it; a ratchet
-- winds the trace's pitch up and buzzes the cone. energy drives it harder
-- (more excursion, more clip, a thicker halo); chaos splits the trace,
-- tears the ribs and multiplies the halo; kickless, it just breathes. a
-- bead goes round the surround over the phrase and flashes on each bar.
-- view 3: the kick throws every cone and pumps the crowd's arms; noise
-- snares fizz across the wall; ring-mod ticks arc between two bins; a
-- closed hat blips one lamp, an open hat flares a pair; a ratchet fans
-- lasers from the truss, a fill throws the whole crowd in the air. the
-- truss LEDs fill over the phrase. energy packs the floor and quickens the
-- lamps, chaos jolts the bins and the crowd, kickless leaves them swaying
-- arms up in thick smoke.
--
-- the ears: view 1, the lows rumble the checker plate and glow the die pits,
-- the mids ring the rams, the plates and the column rivets, the highs light
-- the windows and the roof haze; view 2, the lows hold the cone out, the
-- mids light its middle zone and ribs, the highs glitter the grille; view
-- 3, the lows glow the cones, the mids the beams, the smoke and the crowd,
-- the highs the bolts and lamp lenses, the level the bins and the truss.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  ---------------------------------------------------------------- view 1
  local PX = {26, 72}                   -- the presses' centres
  local HW = 21                         -- half the press width (columns' outer edge)
  local RHW = 15                        -- half the ram width
  local CROWN0, CROWN1 = 4, 13          -- the crown (top block)
  local UP, DOWN = 14, 31               -- the ram's top edge, up / down
  local RH = 14                         -- ram height
  local BED = 47                        -- the bolster's top
  local FLOOR = 53
  local GX, GY, GR = 113, 27, 12        -- the gauge

  ---------------------------------------------------------------- view 2
  local CX, CY = 64, 32
  local SR = 28                         -- the surround's outer radius

  local hit_t, ham, turn, sparks, puffs, arcs, dust, cracks
  local gauge, gvel, jolt, plate, lamp, hook, hookv, fired, fly
  local cone, cone_v, drive, fuzz, trem, pitch, phase, buzz, halo
  -- view 3
  local bars, blk, jump, pump, lamps3, lasers, noise3, zaps3, sweep, stomp

  function M.init()
    hit_t, ham, turn = {-9, -9}, {}, 0
    sparks, puffs, arcs, dust, cracks = {}, {}, {}, {}, {}
    gauge, gvel, jolt, plate, lamp, hook, hookv = 0.1, 0, 0, {0, 0}, 0, 0.3, 0
    fired, fly = {}, {0, 1, 0, 0}
    cone, cone_v, drive, fuzz, trem, pitch, phase, buzz, halo = 0, 0, 0, 0, 0, 1, 0, 0, 0
  end
  local init1 = M.init
  function M.init()
    init1()
    bars, blk, jump, pump, stomp = 0, 0, 0, 0, 0
    lamps3, lasers, noise3, zaps3, sweep = {}, {t0 = -9, n = 0}, {t0 = -9, v = 0}, {}, 0
    for i = 1, 8 do lamps3[i] = 0 end
  end
  M.clear = M.init

  ---------------------------------------------------------------- events
  local function spark(x, y, n, v, spread)
    for _ = 1, n do
      if #sparks >= 36 then table.remove(sparks, 1) end
      local c = K.chaos
      local dir = K.rnd() < 0.5 and -1 or 1
      sparks[#sparks + 1] = {x = x + dir * K.rnd() * 6, y = y, vx = dir * (40 + K.rnd() * (spread or 60) + c * 50),
        vy = -(10 + K.rnd() * 40 + c * 25), t0 = K.T, v = v}
    end
  end

  local function puff(x, y, s, v)
    if #puffs >= 12 then table.remove(puffs, 1) end
    puffs[#puffs + 1] = {x = x, y = y, s = s, t0 = K.T, v = v, dx = (K.rnd() - 0.5) * 8}
  end

  local function slam(p, v, delay)
    hit_t[p] = K.T + (delay or 0)
    plate[p] = math.max(plate[p], v)
  end

  function M.kick(v)
    v = K.num(v, 1)
    local e, c = K.energy, K.chaos
    turn = turn % 2 + 1
    if c > 0.5 and K.rnd() < c * 0.5 then turn = 1 + math.floor(K.rnd() * 2) end
    slam(turn, v)
    if e > 0.7 then slam(3 - turn, v * 0.8, 0.07 + c * K.rnd() * 0.08) end
    jolt = math.max(jolt, v)
    cone_v = math.min(20, cone_v + 9 * v)
    drive = math.max(drive, v)
    halo = math.max(halo, v)
    pump = math.max(pump, v)
    stomp = math.max(stomp, v)
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    local p = 1 + math.floor(K.rnd() * 2)
    spark(PX[p] + (K.rnd() - 0.5) * 20, BED - 1, (n or 1) > 1 and 2 or 3 + math.floor(v * 4), v)
    if #dust >= 6 then table.remove(dust, 1) end
    dust[#dust + 1] = {x = 10 + K.rnd() * 90, t0 = K.T, v = v}
    fuzz = math.max(fuzz, v)
    noise3.t0, noise3.v = K.T, v
    if K.chaos > 0.45 and (n or 1) == 1 then
      if #cracks >= 6 then table.remove(cracks, 1) end
      cracks[#cracks + 1] = {x = 8 + K.rnd() * 90, seed = math.floor(K.rnd() * 999), t0 = K.T}
    end
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8, 1) end

  function M.hat(v, open)
    v = K.num(v, 1)
    local p = 1 + math.floor(K.rnd() * 2)
    if open then puff(PX[p] + (K.rnd() < 0.5 and -HW or HW), BED - 6, 3, v * 0.8)
    elseif K.rnd() < 0.4 then puff(PX[p] + (K.rnd() - 0.5) * 30, CROWN0, 2, v * 0.5) end
    -- (view 3: a closed hat blips one lamp, an open hat flares a pair)
    local li = 1 + math.floor(K.rnd() * 8)
    lamps3[li] = math.max(lamps3[li], open and 1 or 0.5 * v + 0.2)
    if open then lamps3[9 - li] = math.max(lamps3[9 - li], 0.9) end
  end

  function M.tick(kind)
    if #arcs >= 4 then table.remove(arcs, 1) end
    arcs[#arcs + 1] = {p = 1 + math.floor(K.rnd() * 2), y = CROWN1 + 4 + K.rnd() * 26, t0 = K.T,
      seed = math.floor(K.rnd() * 999)}
    trem = 1
    if #zaps3 >= 4 then table.remove(zaps3, 1) end
    zaps3[#zaps3 + 1] = {t0 = K.T, c = math.floor(K.rnd() * 5), r = math.floor(K.rnd() * 2), seed = math.floor(K.rnd() * 999)}
  end

  function M.perc(kind, v) if kind == 6 or kind == 3 then M.tick(4) else M.hat(v, false) end end

  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 16)
    local p = 1 + math.floor(K.rnd() * 2)
    for k = 0, n - 1 do
      if #ham >= 16 then table.remove(ham, 1) end
      ham[#ham + 1] = {p = p, t = K.T + k * 0.055}
    end
    pitch = math.min(4, 1 + n * 0.2)
    buzz = math.max(buzz, math.min(1, n / 8))
    lasers.t0, lasers.n = K.T, n
  end

  function M.fill()
    lamp = math.max(lamp, 0.6)
    jump = 1
    for i = 1, 8 do lamps3[i] = math.max(lamps3[i], 0.7) end
  end

  function M.bar(S)
    bars = bars + 1
    blk = 1
  end

  ---------------------------------------------------------------- view 1 draw
  -- a ram's top edge: slams down in 40 ms, climbs back over most of a beat
  local function ram_y(p)
    local age = K.T - hit_t[p]
    if age < 0 then return UP end
    local down = 0.04
    if age < down then return UP + (DOWN - UP) * (age / down) ^ 2 end
    local up = math.max(0.25, K.beat_sec * 0.85)
    local u = clamp((age - down) / up, 0, 1)
    return DOWN - (DOWN - UP) * K.ease(u)
  end

  local function draw_shop(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    local kl = K.kickless

    -- hammer blows due from a ratchet
    for i = #ham, 1, -1 do
      if K.T >= ham[i].t then
        local H = ham[i]
        hit_t[H.p] = K.T - 0.04 * 0.4 -- most of the way down already
        jolt = math.max(jolt, 0.5)
        plate[H.p] = math.max(plate[H.p], 0.6)
        spark(PX[H.p], BED - 1, 2, 0.6, 40)
        table.remove(ham, i)
      end
    end
    jolt = jolt * math.exp(-DT / 0.08)
    lamp = lamp * math.exp(-DT / 1.5)
    for p = 1, 2 do plate[p] = plate[p] * math.exp(-DT / 0.5) end
    local jy = jolt > 0.5 and 1 or 0

    -- the back wall: tall windows lit from the yard, girders each side
    local wl = 0.8 + e * 0.8 + hi * 2
    for k = 0, 5 do
      local x0 = 8 + k * 19
      line(wl, x0, 2, x0 + 11, 2)
      line(wl, x0, 2, x0, 16)
      line(wl, x0 + 11, 2, x0 + 11, 16)
      line(wl * 0.8, x0 + 1, 9, x0 + 10, 9)
      put(0.6 + hi * 3 * (0.5 + 0.5 * math.sin(T * 5 + k * 1.9)), x0 + 2 + (k % 2) * 4, 5, 4, 1)
    end
    line(2.5, 1, 0, 1, FLOOR)
    line(2.5, 126, 0, 126, FLOOR)

    -- the crane rail and its hook, swaying behind the presses
    K.dashes(2, 18, 6, 8, 0)
    K.dashes(1.5, 19, 2, 8, 3)
    local pull = (K.rnd() - 0.5) * jolt * 4
    hookv = hookv + (-hook * 6 + pull) * DT - hookv * 0.4 * DT
    hook = clamp(hook + hookv * DT * (1 + e), -0.6, 0.6)
    local hx, hy = 49 + math.sin(hook + 0.2 * math.sin(T * 0.7)) * 20, 18 + math.cos(hook) * 20
    put(2.5, 45, 17, 9, 3)
    line(1.5 + lo, 49, 20, hx, hy)
    K.ring(3 + hi * 2, hx, hy + 2, 2.5, 6, -0.5, math.pi + 0.5)

    -- the floor: a lit edge and a band of checker plate, jolting with the blows
    line(3 + jolt * 2, 0, FLOOR + jy, 127, FLOOR + jy)
    -- (the lows rumble through the checker plate)
    K.dashes(0.9 + lo * 2.6, FLOOR + 3, 2, 5, 0)
    K.dashes(0.9 + lo * 2, FLOOR + 6, 2, 5, 2)
    K.dashes(lo * 1.4, FLOOR + 4, 1, 5, 3)
    K.dashes(1, FLOOR + 9, 2, 7, 1)
    for i = #cracks, 1, -1 do
      local C = cracks[i]
      local age = K.T - C.t0
      if age > 5 then table.remove(cracks, i)
      else
        local lv = 1 + 6 * math.exp(-age / 0.3) + 2 * (1 - age / 5)
        local px, py = C.x, FLOOR + 1 + jy
        for j = 1, 4 do
          local x = C.x + (K.hash(C.seed + j, 3) - 0.5) * 14 + j * 3
          local y = FLOOR + 1 + j * 2.5 + jy
          line(lv, px, py, x, y)
          px, py = x, y
        end
      end
    end

    -- the presses
    for p = 1, 2 do
      local cx = PX[p]
      local y = ram_y(p)
      y = y + (UP - 3 - y) * clamp(kl * 1.5, 0, 1)        -- kickless: parked up
      local age = K.T - hit_t[p]
      local hot = (age >= 0 and age < 0.35) and (1 - age / 0.35) or 0
      if age >= 0 and fired[p] ~= hit_t[p] then
        fired[p] = hit_t[p]
        spark(cx, BED - 2, 4 + math.floor(e * 4), 1)
        puff(cx + (K.rnd() < 0.5 and -10 or 10), CROWN0 - 1, 4 + e * 3, 0.9)
        fly[p + 2] = 6 + e * 6
      end
      local x0, x1 = cx - HW, cx + HW
      -- the crown: a heavy beam with rivets, ribbed
      line(4, x0, CROWN0, x1, CROWN0)
      line(3, x0, CROWN1, x1, CROWN1)
      line(3, x0, CROWN0, x0, CROWN1)
      line(3, x1, CROWN0, x1, CROWN1)
      K.dashes(1.5 + lo * 0.8, CROWN0 + 6, 3, 5, p, x0 + 1, x1)
      for k = 0, 4 do put(4 + hi * 3, x0 + 3 + k * 9, CROWN0 + 3, 2, 2) end
      -- the flywheel on the crown: spinning on, kicked round by each blow
      fly[p + 2] = (fly[p + 2] or 0) * math.exp(-DT / 0.4)
      fly[p] = (fly[p] or 0) + ((K.playing and (1.2 + e * 3) or 0.4) * (1 - kl * 0.7) + fly[p + 2]) * K.DTS
      local fx, fy, fr = cx + (p == 1 and -9 or 9), CROWN0 + 1, 7
      K.ring(3 + lo * 2, fx, fy, fr, 14, math.pi, K.TAU)
      for k = 0, 2 do
        local a = fly[p] + k * K.TAU / 3
        if math.sin(a) < 0.2 then
          line(2.5 + hot * 3, fx, fy, fx + math.cos(a) * fr, fy + math.sin(a) * fr)
        end
      end
      -- the columns (shaking a pixel on the blow)
      local sx = 0
      line(3.5, x0 + 2 + sx, CROWN1, x0 + 2 + sx, BED)
      line(3.5, x1 - 2 + sx, CROWN1, x1 - 2 + sx, BED)
      for yy = CROWN1 + 3, BED - 3, 5 do
        put(1.2 + mid * 2.5, x0 + sx, yy, 2, 2)
        put(1.2 + mid * 2.5, x1 - 1 + sx, yy, 2, 2)
      end
      -- the slide rod
      line(3 + hot * 2, cx - 2, CROWN1, cx - 2, y)
      line(3 + hot * 2, cx + 2, CROWN1, cx + 2, y)
      -- the ram: ribbed, a hot edge where it strikes
      local r0, r1 = cx - RHW, cx + RHW
      line(2.5 + hot, r0, y, r1, y)
      line(2.5, r0, y, r0, y + RH)
      line(2.5, r1, y, r1, y + RH)
      -- (the mids: the ram's body rings)
      for q = 4, RH - 2, 5 do put(1 + lo * 0.3 + mid * 1.2, r0 + 1, y + q, 2 * RHW - 1, 1) end
      line(2.5 + hot * 3, r0, y + RH, r1, y + RH)
      -- chaos: a ghost of the ram knocked out of step
      if c > 0.4 then
        local gy = UP + 4 + 8 * (0.5 + 0.5 * math.sin(T * 2 + p * 2))
        line(1 + c, r0 - 3, gy, r1 + 3, gy)
        line(1 + c, r0 - 3, gy + RH, r1 + 3, gy + RH)
      end
      -- the plate on the die, flattened and glowing after the blow
      local pv = plate[p]
      local ph = math.max(1, math.floor(3 - pv * 2 + 0.5))
      put(2 + mid * 3 + pv * 6, cx - 10 - pv * 3, BED - ph + jy, 21 + pv * 6, ph)
      -- the bolster, jolting with the floor
      put(2 + hot * 2, x0 - 2, BED + 2 + jy, 2 * HW + 5, 1)
      line(3.5 + hot * 3, x0 - 2, BED + jy, x1 + 2, BED + jy)
      line(2, x0 + 2, BED + 3 + jy, x0 + 2, FLOOR)
      line(2, x1 - 2, BED + 3 + jy, x1 - 2, FLOOR)
      -- the lows: the pit under the bolster glows and throbs
      if lo > 0.05 then
        K.gradient(BED + 4 + jy, FLOOR - 1 + jy, function(yy) return lo * (1 + (yy - BED - 4) * 0.45) end,
          nil, x0 + 4, x1 - 3)
      end
      -- the shock running out along the bed
      if hot > 0 then
        local w = (1 - hot) * 22 + 3
        line(hot * 6, x0 - 2 - w, BED - 1 + jy, x0 - 2, BED - 1 + jy)
        line(hot * 6, x1 + 2, BED - 1 + jy, x1 + 2 + w, BED - 1 + jy)
      end
      -- kickless: steam hisses steadily from the crown
      if kl > 0.3 and K.rnd() < kl * 0.15 then puff(cx + (K.rnd() - 0.5) * 30, CROWN0 - 1, 3, 0.6) end
    end

    -- ring-mod ticks: an arc jumping between a press's columns
    for i = #arcs, 1, -1 do
      local R = arcs[i]
      local u = (K.T - R.t0) / 0.18
      if u >= 1 then table.remove(arcs, i)
      else
        local x0, x1 = PX[R.p] - HW + 4, PX[R.p] + HW - 4
        local px, py = x0, R.y
        local fr = math.floor(K.T * 12)
        for j = 1, 6 do
          local x = x0 + (x1 - x0) * j / 6
          local y = R.y + (j < 6 and (K.hash(R.seed + j + fr * 7, 9) - 0.5) * 8 or 0)
          line(6 * (1 - u) + 1, px, py, x, y)
          px, py = x, y
        end
      end
    end

    -- steam: puffs swelling and rising, dim
    for i = #puffs, 1, -1 do
      local P = puffs[i]
      local age = K.T - P.t0
      local u = age / 1.4
      if u >= 1 then table.remove(puffs, i)
      else
        local r = P.s * (0.6 + u * 1.6)
        K.disc((1 + P.v * 2.5) * (1 - u) + 0.3, P.x + P.dx * u, P.y - u * 14, r)
      end
    end

    -- dust off the floor from the snares
    for i = #dust, 1, -1 do
      local D = dust[i]
      local u = (K.T - D.t0) / 0.6
      if u >= 1 then table.remove(dust, i)
      else
        K.ring((2 + D.v * 4) * (1 - u), D.x, FLOOR + 2 + jy, 3 + u * 14, 10, math.pi, K.TAU, 0.3)
      end
    end

    -- sparks: thrown along the bed, falling to the floor
    for i = #sparks, 1, -1 do
      local P = sparks[i]
      local age = K.T - P.t0
      local u = age / 0.7
      local x = P.x + P.vx * age
      local y = P.y + P.vy * age + 70 * age * age
      if u >= 1 or y > FLOOR + 2 then table.remove(sparks, i)
      else
        local vx, vy = P.vx, P.vy + 140 * age
        local m = math.sqrt(vx * vx + vy * vy) + 0.01
        line((4 + 6 * P.v) * (1 - u) + hi * 1.5, x - vx / m * 3, y - vy / m * 3, x, y)
      end
    end

    -- the gauge: energy and the lows; pinned and shivering in the red at the top
    local tgt = 0.06 + e * 0.9 + lo * 0.15 + K.env.kick * 0.08 - kl * 0.2
    if c > 0.3 then tgt = tgt + (K.hash(math.floor(T * 14), 4) - 0.5) * c * 0.3 end
    gvel = gvel + ((tgt - gauge) * 140 - gvel * 11) * DT
    gauge = gauge + gvel * DT
    if gauge > 1.04 then gauge, gvel = 1.04, -math.abs(gvel) * 0.4 end
    if gauge < 0 then gauge, gvel = 0, 0 end
    local red = clamp((gauge - 0.8) / 0.2, 0, 1)
    lamp = math.max(lamp, red)
    K.ring(1, GX, GY, GR - 5, 12)
    K.ring(4, GX, GY, GR + 1, 20)
    K.ring(2, GX, GY, GR + 3, 20)
    for k = 0, 10 do
      local a = math.pi * 0.75 + k / 10 * math.pi * 1.5
      local hotk = k >= 8
      line(hotk and 5 or 3, GX + math.cos(a) * (GR - (hotk and 4 or 3)), GY + math.sin(a) * (GR - (hotk and 4 or 3)),
        GX + math.cos(a) * (GR - 1), GY + math.sin(a) * (GR - 1))
    end
    K.ring(3 + red * 4, GX, GY, GR - 2, 4, math.pi * 0.75 + 0.8 * math.pi * 1.5, math.pi * 2.25)
    local ga = math.pi * 0.75 + math.min(1, gauge) * math.pi * 1.5
      + math.sin(T * 37) * (lo * 0.04 + red * 0.06 + 0.01)
    line(math.min(13, 8 + K.env.kick * 3 + red * 2), GX, GY, GX + math.cos(ga) * (GR - 2), GY + math.sin(ga) * (GR - 2))
    put(5, GX - 1, GY - 1, 3, 3)
    -- the pipe down to the line, the warning lamp above
    line(2.5, GX, GY + GR + 3, GX, FLOOR - 1)
    line(2.5, PX[2] + HW + 2, FLOOR - 5, GX, FLOOR - 5)
    local lv = 1.5 + lamp * (6 + 2 * math.sin(T * 5))
    put(lv, GX - 3, 3, 7, 4)
    if lamp > 0.3 then K.ring(lamp * 3, GX, 5, 6 + math.sin(T * 5) * 1.5, 12) end

    -- the stack of stamped plates by the line: one more each bar, cleared
    -- at the end of the phrase; the newest glows
    local pl = math.max(1, math.floor(K.num(S.phrase_len, 16)))
    local phr = clamp((K.num(S.phrase_pos, 0) % pl + K.bar_ph) / pl, 0, 0.999)
    local np = math.floor(phr * 8) + 1
    for k = 1, np do
      local top = k == np
      put(top and (2 + blk * 7 + mid * 2) or (1.5 + mid * 1.5), 99 + (k % 2), FLOOR - 1 - k * 2 + jy, 9, 1)
    end

    -- haze in the roof, thicker with energy and the steam
    K.haze(0, 0, 128, 22, 0.05 + e * 0.08 + kl * 0.15 + hi * 0.15, 1, T * 6)
  end

  ---------------------------------------------------------------- view 2 draw
  -- the trace: a sine driven into the rails; square when driven hard
  local function wave(x, drv, amp, ph, f, nz)
    local s = math.sin((x / 128) * K.TAU * f - ph)
    if trem > 0.05 then s = s * (1 - trem * 0.6 * (0.5 + 0.5 * math.sin(x * 0.9 + K.T * 40))) end
    s = clamp(s * drv, -1, 1)
    if nz > 0.05 then s = s + (K.hash(math.floor(x) + math.floor(K.T * 10) * 131, 77) - 0.5) * nz end
    return s * amp
  end

  local function draw_cone(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    local kl = K.kickless
    -- the cone: a stiff spring the kick throws out, the lows hold out
    local rest = lo * 0.35 * (1 - kl * 0.5) + kl * 0.15 * math.sin(T * 1.3)
    cone_v = cone_v + ((rest - cone) * 160 - cone_v * 14) * DT
    cone = clamp(cone + cone_v * DT, -0.4, 1.1)
    drive = drive * math.exp(-DT / (0.15 + e * 0.1))
    fuzz = fuzz * math.exp(-DT / 0.12)
    trem = trem * math.exp(-DT / 0.15)
    buzz = buzz * math.exp(-DT / 0.35)
    halo = halo * math.exp(-DT / 0.25)
    pitch = 1 + (pitch - 1) * math.exp(-DT / 0.4)
    phase = (phase + (2.5 + e * 3) * pitch * K.DTS) % (K.TAU * 100)
    local bz = buzz > 0.05 and math.sin(T * 90) * buzz * 0.08 or 0
    local ex = cone + bz

    -- the baffle: a perforated grille round the speaker, bolts at the corners
    for y = 2, 62, 5 do
      local off = (y // 5) % 2 * 3
      for x = 2 + off, 126, 6 do
        local dx, dy = x - CX, y - CY
        -- (the grille's holes glitter with the highs)
        if dx * dx + dy * dy > 35 * 35 then
          put(0.7 + hi * (1 - K.env.kick) ^ 3 * 2.5 * (0.5 + 0.5 * math.sin(T * 6 + x * 0.7 + y * 1.3)), x, y, 1, 1)
        end
      end
    end
    for _, b in ipairs({{8, 7}, {120, 7}, {8, 57}, {120, 57}}) do
      K.ring(3, b[1], b[2], 3, 8)
      line(4, b[1] - 2, b[2], b[1] + 2, b[2])
    end

    -- the distortion halo round the surround: it flares rather than moves
    local hv = halo * (0.6 + e * 0.6) + drive * 0.3 + e * 0.15
    local nh = 1 + math.floor(c * 1.6)
    for k = 1, nh do
      local r = SR + 3 + k * 2.5
      K.ring((0.8 + hv * 2.5) / k, CX, CY, r, 24, 0, K.TAU, 1, 0.4 + c * 2, k + math.floor(T * 3) * 3)
    end

    -- the surround: a fat roll (an annulus, lit along its top)
    for dy = -SR, SR do
      local ho = math.sqrt(math.max(0, SR * SR - dy * dy))
      local ri = SR - 3
      local hi_ = math.abs(dy) < ri and math.sqrt(ri * ri - dy * dy) or 0
      local lv = 2 + lo * 0.8 + (dy < -SR * 0.5 and 1 or 0)
      if hi_ > 0 then
        put(lv, CX - ho, CY + dy, math.max(1, ho - hi_), 1)
        put(lv, CX + hi_, CY + dy, math.max(1, ho - hi_), 1)
      elseif ho >= 0.5 then
        put(lv, CX - ho, CY + dy, ho * 2, 1)
      end
    end
    K.ring(4 + hi * 3 + halo * 2, CX, CY, SR - 1, 10, math.pi * 1.15, math.pi * 1.6)

    -- the cone: shaded zones, the middle thrown out further than the edge
    local z1 = SR - 3.5
    K.disc(1, CX, CY, z1)
    K.disc(1.1 + mid * 2, CX, CY, 17 * (1 + ex * 0.25))
    K.disc(2.4 + lo * 0.8 + K.env.kick, CX, CY, 11 * (1 + ex * 0.45))
    -- the ribs: radial creases; snares fuzz them, chaos tears them
    for k = 0, 11 do
      local a = k / 12 * K.TAU + 0.13
      local r0 = 7.5 * (1 + ex * 0.5)
      local r1 = z1 - 1
      local tear = (c > 0.5 and K.hash(k + math.floor(T * 4) * 13, 81) < (c - 0.5)) and 0.5 or 1
      local wob = fuzz * (K.hash(k + math.floor(T * 10) * 17, 82) - 0.5) * 0.2
      line(1 + e * 0.5 + fuzz + mid * 2.5, CX + math.cos(a) * r0, CY + math.sin(a) * r0,
        CX + math.cos(a + wob) * (r0 + (r1 - r0) * tear), CY + math.sin(a + wob) * (r0 + (r1 - r0) * tear))
    end
    -- the dust cap, swelling, with a highlight
    local dr = 6.5 + ex * 3.5
    K.disc(3.5 + lo + K.env.kick * 3, CX, CY, dr)
    put(math.min(12, 5 + K.env.kick * 6 + hi * 3), CX - dr * 0.45, CY - dr * 0.5, 2, 2)

    -- the phrase: a bead round the surround, each bar flashes it
    local pl = math.max(1, math.floor(K.num(S.phrase_len, 16)))
    local phr = clamp((K.num(S.phrase_pos, 0) % pl + K.bar_ph) / pl, 0, 1)
    local ba = phr * K.TAU - math.pi / 2
    K.disc(3 + blk * 7 + A[K.AMP] * 2, CX + math.cos(ba) * (SR + 6), CY + math.sin(ba) * (SR + 6), 1.5 + blk)

    -- the trace across the whole picture, clipping square on the kick
    local drv = 1 + drive * (4 + e * 6) + e * 1.5
    local amp = (7 + e * 5 + drive * 4) * (1 - kl * 0.4)
    local f = 2 + e
    local nz = fuzz * 0.8 + c * 0.1
    local traces = 1 + (c > 0.55 and 1 or 0)
    for tr = 1, traces do
      local oy = (tr - 1) * (tr % 2 == 0 and 9 or -9) * c
      local oph = (tr - 1) * 0.9
      local lv = (tr == 1 and (2.6 + drive * 2 + hi * 1.5) or (1 + drive * 0.5))
      local px, py
      for x = 0, 128, 4 do
        local y = CY + oy - wave(x, drv, amp, phase + oph, f, nz)
        if px then line(lv, px, py, x, y) end
        px, py = x, y
      end
    end
  end

  ---------------------------------------------------------------- view 3 draw
  -- the hakken floor: a wall of bass bins behind a crowd stomping on the 16ths,
  -- lamps on the truss over them, smoke, lasers when a ratchet fires
  local WY0, WY1 = 11, 39               -- the wall of bins
  local NCB, NRB = 6, 2                 -- cabinets across, up
  local CW = 21

  local function draw_floor(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    pump = pump * math.exp(-DT / 0.12)
    for i = 1, 8 do lamps3[i] = lamps3[i] * math.exp(-DT / 0.18) end
    sweep = sweep + (0.3 + e * 0.5 + c * 0.8) * (1 - kl * 0.6) * K.DTS
    local pl = math.max(1, math.floor(K.num(S.phrase_len, 16)))
    local phr = clamp((K.num(S.phrase_pos, 0) % pl + K.bar_ph) / pl, 0, 1)

    -- the wall of bins: each cone thrown on the kick, glowing with the lows
    local nage = K.T - noise3.t0
    for r = 0, NRB - 1 do
      for q = 0, NCB - 1 do
        local x0, y0 = 1 + q * CW, WY0 + r * 14
        local jx = (c > 0.5 and K.hash(q + r * 7 + math.floor(T * 6) * 13, 41) < (c - 0.5) * 0.6) and 1 or 0
        local bl = 1 + amp * 0.4 + blk * 1.5
        line(bl, x0 + jx, y0 + 1, x0 + jx, y0 + 12)
        line(bl, x0 + CW - 2 + jx, y0 + 1, x0 + CW - 2 + jx, y0 + 12)
        put(bl, x0 + jx, y0, 4, 1)
        put(bl, x0 + CW - 5 + jx, y0, 4, 1)
        put(bl, x0 + jx, y0 + 13, 4, 1)
        put(bl, x0 + CW - 5 + jx, y0 + 13, 4, 1)
        local cx, cy = x0 + CW / 2 - 1 + jx, y0 + 6.5
        K.ring(1 + lo * 0.4, cx, cy, 4.5, 12)
        K.disc(1 + lo * 1.5 + pump * 2.5, cx, cy, 1.6)
        -- (the highs glitter the bolts)
        put(1 + hi * 3 * (0.5 + 0.5 * math.sin(T * 9 + q * 1.7 + r)), x0 + 2 + jx, y0 + 2, 1, 1)
        put(1 + hi * 3 * (0.5 + 0.5 * math.sin(T * 8 + q * 2.3 + r * 2)), x0 + CW - 4 + jx, y0 + 11, 1, 1)
      end
    end
    -- noise snares: the wall fizzes
    if nage < 0.3 then
      local u = nage / 0.3
      local fr = math.floor(T * 30)
      for k = 0, 15 do
        local x = K.hash(k + fr * 31, 43) * 126
        local y = WY0 + K.hash(k + fr * 31, 44) * (WY1 - WY0)
        put((2 + noise3.v * 5) * (1 - u), x, y, 2, 1)
      end
    end
    -- ring-mod ticks: an arc between two bins
    for i = #zaps3, 1, -1 do
      local Z = zaps3[i]
      local u = (K.T - Z.t0) / 0.18
      if u >= 1 then table.remove(zaps3, i)
      else
        local y = WY0 + 6 + Z.r * 14
        local xa, xb = 1 + Z.c * CW + CW / 2 + 4, 1 + (Z.c + 1) * CW + CW / 2 - 6
        local px, py = xa, y
        local fr = math.floor(K.T * 12)
        for j = 1, 5 do
          local x = xa + (xb - xa) * j / 5
          local yy = y + (j < 5 and (K.hash(Z.seed + j + fr * 7, 9) - 0.5) * 7 or 0)
          line(7 * (1 - u) + 1, px, py, x, yy)
          px, py = x, yy
        end
      end
    end

    -- the truss: two chords and a zigzag, the phrase filling its LEDs
    line(1 + amp * 0.4, 0, 6, 127, 6)
    for x = 0, 124, 8 do line(1, x, 1, x + 4, 6); line(1, x + 4, 6, x + 8, 1) end
    for k = 0, 15 do
      if k < phr * 16 then put(2 + blk * 6 + mid, 3 + k * 8, 3, 2, 1) end
    end

    -- smoke over the floor
    K.haze(0, 26, 128, 50, 0.1 + kl * 0.35 + mid * 0.06, 1 + kl * 0.6, T * 4)

    -- the lamps and their beams, sweeping; hats fire them
    for i = 1, 8 do
      local lx = 8 + (i - 1) * 16
      local a = math.sin(sweep + i * 0.9) * (0.35 + c * 0.4) + (i % 2 == 0 and 0.15 or -0.15)
      local lv = lamps3[i]
      local bl = 0.4 + mid * 0.3 + lv * 1.6 + e * 0.1
      local ex = lx + math.sin(a) * 44
      line(bl, lx, 8, ex, 46)
      put(math.min(12, 2 + lv * 8 + hi * 2), lx - 1, 7, 3, 1)
    end
    -- a ratchet: lasers fanning from the middle of the truss, spinning
    local la = K.T - lasers.t0
    if la < 0.7 then
      local n = clamp(lasers.n, 2, 7)
      local u = la / 0.7
      for k = 0, n - 1 do
        local a = (k / (n - 1) - 0.5) * (1.2 + c * 0.5) + math.floor(la * 4) * 0.08
        line((1.5 + n * 0.25) * (1 - u * u), 64, 7, 64 + math.sin(a) * 70, 7 + math.cos(a) * 70)
      end
    end

    -- the crowd: hakkers stomping the 16ths, arms pumping on the kick;
    -- kickless they sway with their arms up; a fill throws them all up
    local step = math.floor(K.stepf) % 2
    local ju = 1 - jump
    local jy = ju < 0.4 and -5 * math.sin(math.pi * ju / 0.4) or 0
    local nb = 8 + math.floor(e * 5)
    for i = 1, nb do
      local x = (i - 0.5) / nb * 128 + math.sin(T * 0.5 + i * 2.3) * 3
      if c > 0.5 then x = x + (K.hash(i + math.floor(T * 3) * 11, 47) - 0.5) * (c - 0.5) * 12 end
      local y = 45 + math.floor(jy * 0.6 + 0.5)
      K.disc(1 + amp * 0.5 + mid * 0.4, x, y - 3, 1.8)
      line(1 + amp * 0.3, x - 3, y + 1, x + 3, y + 1)
      local up = math.max(kl * 0.8, jump, stomp * 0.6)
      if up > 0.4 or i % 3 == 0 then line(1.2 + amp * 0.5 + pump * 2, x + 3, y + 1, x + 5, y - 5 - up * 2) end
    end
    local nf = 5 + math.floor(e * 2)
    for i = 1, nf do
      local x = (i - 0.5) / nf * 128 + math.sin(T * 0.37 + i * 1.7) * 4
      if c > 0.5 then x = x + (K.hash(i + math.floor(T * 3) * 17, 48) - 0.5) * (c - 0.5) * 16 end
      local leg = (K.playing and (step + i) % 2 == 0) and 1 or -1
      local hop = (1 - kl) * (K.playing and 1 or 0)
      local y = 52 + math.floor(jy + 0.5)
      local l = 1.1 + amp * 0.5 + mid * 0.4
      local sw = kl * math.sin(T * 1.4 + i) * 3
      K.disc(l + 0.5, x + sw * 0.3, y - 4, 2.6)
      line(l, x - 4, y, x + 4, y)
      line(l, x, y, x, y + 6)
      line(l, x, y + 6, x - 2 - leg * hop * 2, 64)
      line(l, x, y + 6, x + 2 - leg * hop * 2, 64)
      local up = math.max(kl * 0.8, jump, (i % 3 == 1) and stomp * 0.7 or 0)
      if up > 0.3 then
        line(l + pump * 3, x - 4, y, x - 6 + sw, y - 6 - up * 4)
        line(l + pump * 3, x + 4, y, x + 6 + sw, y - 6 - up * 4)
      else
        line(l, x - 4, y, x - 6, y + 5)
        line(l, x + 4, y, x + 7, y - 3 - pump * 3)
      end
    end
  end

  function M.draw(S)
    blk = blk * math.exp(-K.DT / 0.35)
    jump = jump * math.exp(-K.DT / 0.5)
    stomp = stomp * math.exp(-K.DT / 0.12)
    if K.view == 2 then draw_cone(S) elseif K.view == 3 then draw_floor(S) else draw_shop(S) end
  end

  M.init()
  return M
end
