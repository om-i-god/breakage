-- phonk. view 1: a night drive on tape, seen from the chase car: a low coupe
-- drifts down an empty wet road, its four round tail-lights smearing as it
-- swings, tyre smoke rolling off the rear wheels, sodium streetlights passing
-- either side and a dark city low on the horizon.
-- view 2: from the driver's seat: the windshield with the road tilting as the
-- car drifts and the streetlights streaking overhead, the mirror full of our
-- own red smoke, fuzzy dice swinging, and on the dash a cassette deck turning,
-- a speedo and a tach whose needle glides like the 808.
-- view 3: the M bridge over the river at three in the morning: the twin lit
-- arches, the dark pyramid on the near bank, the city on the far one, a car's
-- tail-lights crossing the deck and every light shaking in the water.
-- all three are played back off a worn tape: the tracking band rolls up the
-- picture shifting the rows it crosses, the head-switching noise frays the
-- bottom edge, grain crawls over everything and the PLAY mark sits top left.
--
-- the kick is the 808: a long low sweep that glides as it goes (across the
-- road toward the horizon, along the dash lip, across the river toward us),
-- the car squats on it and the tach jumps and glides back down. snare brakes
-- (the tail-lights flare, a gust of smoke, the bridge's deck lights run out
-- from the car); clap throws a flash of glare across the scene; rim and
-- closed hats catch the cat's-eyes in the road (glints on the river), open
-- hats send a long shimmer down the lane (a streetlight streak, a long glint
-- on the water). the phonk cowbell plays its melody as bright ringing pings,
-- pitch for height, each struck one ringing out: across the sky in view 1,
-- on the glass in view 2, on the bridge's arch lights in view 3; the vox
-- warbles as a slow ghost smear in the sky; the other perc ping smaller and
-- lower. the crush tick drops VHS block noise, the pop tick backfires the
-- exhaust, break slices jump the tracking, ratchets stutter the tail-lights
-- into a row of echoes (and fast-forward the reels), a fill throws the car
-- into a wide drift with a cloud of smoke and rolls the tracking.
-- each bar swings the drift the other way; the phrase bends the road, winds
-- the tape from one reel to the other and runs the chase lights on the arches.
-- energy is speed: faster road, more smoke, more of the city lit. chaos
-- shakes the tape loose (worse tracking, a ghost of the car, the horizon
-- lurching, the reflections torn). kickless stretches pause the tape: the
-- car coasts with its hazards pulsing, fog comes in, the band stops rolling
-- and jitters in place and PLAY becomes PAUSE.
--
-- the ears: the lows light the road under the car, the sweeps and the tach;
-- the mids light the smoke, the reflections on the wet road and the bridge's
-- hangers; the highs light the streetlights, the lane lines, the cat's-eyes
-- and the grain; the level lifts the sodium glow over the city.
return function(K)
  local M = {}
  local A, clamp, num = K.A, K.clamp, K.num
  local sin, cos, floor, max, min, abs, sqrt, exp = math.sin, math.cos, math.floor, math.max, math.min,
    math.abs, math.sqrt, math.exp
  local asin = math.asin
  local PI, TAU = math.pi, 2 * math.pi

  ---------------------------------------------------------------- state
  local pings, sweeps, smoke, vox, blocks, pops, glints, streaks
  local note_i                           -- where the cowbell is in its melody
  local drift, drift_to, dvel, yaw       -- the car's swing (-1..1), target, speed, angle
  local squat, sq_px, brake, clapv, rat, rat_n, rat_dir, fillv, track
  local road, speed                      -- distance travelled, eased speed
  local trk_y, trk_dx, trk_h, wamp       -- the tracking band and the row wobble
  local bar_n, rev, reel, dw, dw_x       -- bars seen, tach rev, reel angle, deck-light wave
  local swing_e, swing_t                 -- the dice's kick swing
  local smoke_acc, bx, trail, trail_acc  -- smoke spawn clock, bridge car x, its trail
  local SKY, CITY                        -- skyline profiles (views 1 and 3)

  -- the cowbell's melody: semitones over the root, walked one hit at a time
  local MEL = {0, 3, 7, 3, 10, 7, 3, 0, 0, 3, 7, 8, 7, 3, 5, 3}

  function M.init()
    pings, sweeps, smoke, vox, blocks, pops, glints, streaks = {}, {}, {}, {}, {}, {}, {}, {}
    note_i = 0
    drift, drift_to, dvel, yaw = 0, 0.4, 0, 0
    squat, sq_px, brake, clapv, rat, rat_n, rat_dir, fillv, track = 0, 0, 0, 0, 0, 0, 1, 0, 0
    road, speed = 0, 0.5
    trk_y, trk_dx, trk_h, wamp = 70, 2, 3, 0
    bar_n, rev, reel, dw, dw_x = 0, 0, 0, 0, 64
    swing_e, swing_t = 0, 0
    smoke_acc, bx, trail, trail_acc = 0, 90, {}, 0
  end
  M.clear = M.init

  -- the city on the horizon in view 1: blocks {x, w, h}, and their profile
  local BLD = {}
  do
    local x, i = 0, 0
    while x < 128 do
      local w = 5 + floor(K.hash(i, 74) * 10)
      local h = 3 + floor(K.hash(i, 71) * 8)
      if K.hash(i, 72) < 0.2 then h = h + 6 end           -- a few towers
      if K.hash(i, 73) < 0.15 then h = 1 end              -- gaps
      BLD[#BLD + 1] = {x = x, w = w, h = h}
      x, i = x + w, i + 1
    end
  end
  SKY = K.profile(function(x)
    for _, b in ipairs(BLD) do
      if x >= b.x and x < b.x + b.w then return 25 - b.h end
    end
    return 24
  end)
  CITY = K.profile(function(x)
    if x <= 30 then return 12 + abs(x - 15) * 24 / 15 end   -- the pyramid
    if x >= 106 then
      local c = x // 5
      return 36 - (6 + floor(K.hash(c, 81) * 11))
    end
    return 36 - 1 - floor(K.hash(x // 7, 82) * 3)            -- the far shore, low
  end)

  ---------------------------------------------------------------- the tape
  -- every row is shifted by the tracking band and a slow wobble
  local function wob(y)
    local o = 0
    local d = y - trk_y
    if d > -trk_h and d < trk_h then o = trk_dx end
    if wamp > 0.05 then o = o + floor(sin(y * 0.23 + K.T * 1.9) * wamp + 0.5) end
    return o
  end
  -- the views' gain: the dense views run a touch dimmer, keeping the top
  -- levels for the hits
  local gk = 1
  local function G(l) return l * gk + max(0, l - 7) * (1 - gk) end
  local function P(l, x, y, w, h) K.put(G(l), x + wob(y), y, w, h) end
  local function L(l, x0, y0, x1, y1) K.line(G(l), x0 + wob(y0), y0, x1 + wob(y1), y1) end
  local function RING(l, ...) K.ring(G(l), ...) end
  local function DISC(l, ...) K.disc(G(l), ...) end

  -- one row at a level rounded to whole steps: a glow builds in solid bands
  -- (no row dither, so the kick's jolt doesn't make the rows swim)
  local function drow(v, y, x0, x1)
    if not (v > 0.5) or x1 - x0 < 1 then return end
    P(floor(v + 0.5), x0, floor(y), x1 - x0, 1)
  end
  -- the same over a skyline: lit only above the profile
  local function srow(v, y, prof)
    if not (v > 0.5) then return end
    K.row_above(floor(G(v) + 0.5), y, prof)
  end

  local function fell(l, cx, cy, rx, ry)
    if not (rx > 0.3 and ry > 0.3) then return end
    for dy = -floor(ry), floor(ry) do
      local u = dy / ry
      local hw = rx * sqrt(max(0, 1 - u * u))
      if hw >= 0.5 then P(l, cx - hw, cy + dy, max(1, hw * 2), 1) end
    end
  end

  local function phrase(S)
    local len = clamp(num(S.phrase_len, 16), 1, 256)
    local pos = num(S.phrase_pos, 0) % len
    return clamp((pos + K.bar_ph) / len, 0, 1)
  end

  local function puff(n, v)
    for _ = 1, n do
      if #smoke >= 16 then table.remove(smoke, 1) end
      local side = K.rnd() < 0.5 and -1 or 1
      smoke[#smoke + 1] = {x = 64 + drift * 16 + side * 15, side = side, t0 = K.T, v = v,
        vx = -dvel * 30 + side * (2 + K.rnd() * 5), vy = -(3 + K.rnd() * 5), life = 1.6 + K.rnd() * 1.2,
        seed = floor(K.rnd() * 999)}
    end
  end

  ---------------------------------------------------------------- events
  function M.kick(v)
    v = num(v, 1)
    squat = max(squat, v)
    rev = max(rev, v)
    if #sweeps >= 4 then table.remove(sweeps, 1) end
    sweeps[#sweeps + 1] = {t0 = K.T, v = v, ph = K.rnd() * TAU}
    swing_e, swing_t = max(swing_e * 0.5, 0.5 * v), K.T
    puff(1, 0.5 * v)
  end
  function M.snare(v, n)
    v = num(v, 1)
    brake = max(brake, 0.5 + 0.5 * v)
    dw, dw_x = 1, bx
    puff(2, v)
  end
  function M.clap(v)
    v = num(v, 1)
    clapv = max(clapv, 0.5 + 0.5 * v)
    brake = max(brake, 0.4 * v)
  end
  local function glint(v, open)
    if #glints >= 10 then table.remove(glints, 1) end
    glints[#glints + 1] = {t0 = K.T, u = K.rnd(), w = K.rnd(), v = v, open = open}
  end
  function M.rim(v) glint(num(v, 1) * 0.8, false) end
  function M.hat(v, open)
    v = num(v, 1)
    if open then
      if #streaks >= 4 then table.remove(streaks, 1) end
      streaks[#streaks + 1] = {t0 = K.T, v = v, side = K.rnd() < 0.5 and -1 or 1}
    else
      glint(v, false)
    end
  end
  local function ping(v, note, small)
    if #pings >= 8 then table.remove(pings, 1) end
    pings[#pings + 1] = {t0 = K.T, v = v, note = note, slot = note_i % 16, small = small}
  end
  function M.perc(kind, v)
    v = num(v, 1)
    kind = floor(num(kind, 1))
    if kind == 21 or kind == 3 then
      note_i = note_i + 1
      ping(v, MEL[note_i % #MEL + 1], false)
    elseif kind == 16 then
      if #vox >= 3 then table.remove(vox, 1) end
      vox[#vox + 1] = {t0 = K.T, v = v, x = 20 + K.rnd() * 88, y = 4 + K.rnd() * 8}
    else
      note_i = note_i + 1
      ping(v * 0.6, floor(K.hash(kind, 5) * 5), true)
    end
  end
  function M.tick(kind)
    kind = floor(num(kind, 1))
    if kind == 8 then
      if #pops >= 4 then table.remove(pops, 1) end
      pops[#pops + 1] = {t0 = K.T, side = K.rnd() < 0.5 and -1 or 1}
    else
      if #blocks >= 6 then table.remove(blocks, 1) end
      blocks[#blocks + 1] = {t0 = K.T, x = floor(K.rnd() * 112), y = floor(K.rnd() * 56),
        w = 4 + floor(K.rnd() * 14), h = 2 + floor(K.rnd() * 4)}
    end
  end
  function M.brk(s, n, rv)
    track = max(track, 0.6)
    trk_dx = (K.rnd() < 0.5 and -1 or 1) * (2 + floor(K.rnd() * 3))
  end
  function M.ratchet(n, voice)
    rat_n = clamp(floor(num(n, 2)), 1, 8)
    rat = 1
    rat_dir = K.rnd() < 0.5 and -1 or 1
    track = max(track, 0.4)
    puff(2, 0.7)
  end
  function M.fill()
    fillv = 1
    drift_to = (drift_to >= 0 and -1 or 1) * 1.1
    track = 1
    puff(4, 1)
  end
  function M.bar(S)
    bar_n = bar_n + 1
    if fillv < 0.3 then drift_to = (bar_n % 2 == 0 and 1 or -1) * (0.3 + K.energy * 0.5) end
  end

  ---------------------------------------------------------------- shared bits
  -- the cowbell pings: a bright ringing point, a cross, a ring spreading out
  local function draw_ping(p, x, y, scale)
    local a = K.T - p.t0
    local life = p.small and 0.6 or 1.4
    if a > life or a < 0 then return end
    local u = a / life
    local lv = p.v * exp(-a / (p.small and 0.18 or 0.45))
    local ring_lv = 1 + lv * 7
    local core = min(14, 3 + lv * 11 + (1 - u) * 0.6 * sin(a * 9))
    P(core, x, y, 1, 1)
    if lv > 0.15 then
      local arm = (p.small and 1 or 2) * scale * (0.5 + lv)
      L(min(12, 2 + lv * 9), x - arm, y, x + arm, y)
      if not p.small then L(min(12, 2 + lv * 7), x, y - arm * 0.7, x, y + arm * 0.7) end
    end
    if u < 0.9 then RING(ring_lv * (1 - u), x + wob(y), y, (1.5 + a * (p.small and 6 or 11)) * scale, 10) end
  end

  local function draw_vox(T)
    for i = 1, #vox do
      local o = vox[i]
      local a = T - o.t0
      if a >= 0 and a < 1.6 then
        local lv = o.v * (1 - a / 1.6) * 3
        for k = 0, 2 do
          local px, py
          for s = 0, 6 do
            local x = o.x - 18 + s * 6 + a * 4
            local y = o.y + k * 2 + sin(s * 0.9 + a * 3 + k) * (1 + a)
            if px then L(lv - k * 0.6, px, py, x, y) end
            px, py = x, y
          end
        end
      end
    end
  end

  -- the tape: tracking band noise, head-switching at the bottom, PLAY, grain
  local function draw_tape(T, e, c, kl, hi)
    -- the band itself: frayed streaks along the rows it covers
    for r = -trk_h + 1, trk_h - 1, 2 do
      local y = floor(trk_y + r)
      if y >= 0 and y < 64 then
        for k = 0, 2 do
          local h = K.hash(floor(T * 12) * 7 + k + y * 13, 31)
          if h < 0.45 + track * 0.4 + c * 0.2 then
            local x = floor(K.hash(floor(T * 12) + k * 5 + y, 32) * 120)
            K.put(1.5 + h * 3 + track * 3, x, y, 3 + floor(h * 18), 1)
          end
        end
      end
    end
    -- head switching: the bottom rows fray and slide
    for y = 61, 63 do
      local o = floor((K.hash(floor(T * 8) + y, 33) - 0.5) * (4 + c * 8))
      K.put(1 + (y - 60) * 0.4 + c, o + 4, y, 30 + floor(K.hash(y, 34) * 40), 1)
    end
    -- PLAY, or PAUSE when the kick drops out
    local pl = 2.5 + e + K.bar_pulse * 1.5
    if kl > 0.5 then
      K.put(pl, 3, 3, 1, 5); K.put(pl, 6, 3, 1, 5)
    else
      K.line(pl, 3, 3, 3, 8); K.line(pl, 3, 3, 7, 5.5); K.line(pl, 3, 8, 7, 5.5)
    end
    -- block noise from the crush
    for i = #blocks, 1, -1 do
      local b = blocks[i]
      local a = T - b.t0
      if a > 0.25 then table.remove(blocks, i)
      else
        local lv = 2 + 5 * (1 - a / 0.25)
        for r = 0, b.h - 1 do
          K.put(lv * (0.6 + 0.4 * K.hash(r + b.x, 35)), b.x + floor(K.hash(r, b.y) * 4), b.y + r, b.w, 1)
        end
      end
    end
    K.grain(function(u, v) return u * 128, v * 62 end, 4 + hi * 26 + e * 8 + c * 10, 3 + hi * 4)
  end

  ---------------------------------------------------------------- view 1
  local HY = 25
  local function draw1(S)
    local T, e, c, kl = K.T, K.energy, K.chaos, K.kickless
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]
    local ph = phrase(S)
    local VX = 64 + sin(ph * TAU) * 12 - drift * 5
    local glow = 0.6 + amp * 0.7 + e * 0.3 + K.bar_pulse * 0.25
    local function sy(s) return HY + (64 - HY) * s end
    local function rc(s) return VX + (64 - VX) * s end

    -- the sodium haze over the city, the towers dark against it, their windows
    for y = HY - 8, HY - 1 do local u = (y - HY + 9) / 9; srow(glow * u * 1.5, y, SKY) end
    -- the blocks' roofs and edges, faint against the dark above the glow
    local rl = 1 + amp * 0.5 + e * 0.3
    for _, b in ipairs(BLD) do
      if b.h > 3 then
        local top = HY - b.h
        L(rl, b.x, top, b.x + b.w - 2, top)
        if b.h > 8 then L(rl, b.x, top, b.x, HY - 8); L(rl, b.x + b.w - 2, top, b.x + b.w - 2, HY - 8) end
      end
    end
    for i = 0, 5 do                                              -- a few dim stars
      local x, y = floor(K.hash(i, 61) * 128), 1 + floor(K.hash(i, 62) * 9)
      P(1 + 0.6 * (0.5 + 0.5 * sin(T * (0.5 + K.hash(i, 63)) + i)) + hi, x, y, 1, 1)
    end
    for i = 0, 21 do
      local x = floor(K.hash(i, 64) * 64) * 2
      local top = K.at(SKY, x)
      local h = HY - top
      if h >= 3 then
        local on = K.hash(i + floor(T * 0.15 + K.hash(i, 66) * 7) * 41, 65) < 0.25 + e * 0.5
        if on then P(1 + amp * 1.2 + mid * 0.8, x, top + 1 + floor(K.hash(i, 67) * (h - 2)), 1, 1) end
      end
    end
    -- the horizon fog
    K.haze(0, HY - 5, 128, HY + 5, 0.2 + kl * 0.45 + e * 0.1, 1 + kl, T * 3)

    -- the road: its edges, the wet surface lit by the car, the lane lines
    L(2 + amp + hi, VX - 2, HY, -16, 64)
    L(2 + amp + hi, VX + 2, HY, 144, 64)
    local pcx = 64 + drift * 16
    local pw = 22 + lo * 10 + brake * 8
    for y = HY + 1, 63 do
      local s = (y - HY) / (64 - HY)
      local hw = 2 + 78 * s
      local x0 = rc(s) - hw
      local fog = (0.2 + kl * 0.6) * (1 - s) * (1 - s) * (1 - s)
      if y >= 50 then
        local pool = (0.3 + lo * 0.6 + brake * 0.8) * (y - 47) / 16
        drow(pool * 1.5, y, max(x0, pcx - pw), min(x0 + hw * 2, pcx + pw))
      else
        drow(fog, y, max(0, x0), min(128, x0 + hw * 2))
      end
    end
    local function wy(w) return clamp(2 / w, 0, 1.4) end
    local dash = road % 4
    for i = 0, 9 do
      local w = i * 4 - dash + 1
      if w > 0.8 then
        local s0, s1 = wy(w + 1.6), wy(w)
        for _, side in ipairs({-0.3, 0.3}) do
          local x0 = rc(s0) + (2 + 78 * s0) * side
          local x1 = rc(s1) + (2 + 78 * s1) * side
          L(1.5 + s1 * 3 + hi * 3, x0, sy(s0), x1, sy(s1))
        end
      end
    end

    -- the streetlights, and their long reflections in the wet road
    local pole = road % 10
    for i = 5, 0, -1 do
      local w = i * 10 - pole + 1.5
      if w > 1 then
        local s = wy(w)
        local by = sy(s)
        for side = -1, 1, 2 do
          local px = rc(s) + side * (2 + 78 * s) * 1.18
          local top = by - 36 * s
          L(1 + s * 2.5, px, by, px, top)
          local lx = px - side * 7 * s
          L(1 + s * 2.5, px, top, lx, top + 1)
          local lv = min(13, 3 + s * 5 + hi * 4 + amp * 1.5)
          P(lv, lx - s, top + 1, max(1, 2 * s), 1)
          -- the pool on the road under it and its streak in the wet
          local rl = 1 + mid * 2.5 + s * 1.5
          for k = 0, 3 do
            local ry = by + 1 + k * 3 * s
            if ry < 64 then P(rl * (1 - k * 0.2), lx - s, ry, max(1, 2 * s), max(1, s * 1.5)) end
          end
        end
      end
    end

    -- cat's-eyes caught by the rim and the closed hats
    for i = #glints, 1, -1 do
      local g = glints[i]
      local a = T - g.t0
      if a > 0.5 then table.remove(glints, i)
      else
        local w = 1.5 + g.w * 10 + a * speed * 14
        local s = wy(w)
        local side = g.u < 0.5 and -0.3 or 0.3
        local x = rc(s) + (2 + 78 * s) * side
        local lv = min(13, g.v * (1 - a / 0.5) * (8 + hi * 5))
        P(lv, x, sy(s), max(1, 2 * s), 1)
      end
    end
    -- open hats: a shimmer runs up the lane toward the horizon
    for i = #streaks, 1, -1 do
      local st = streaks[i]
      local a = T - st.t0
      if a > 0.7 then table.remove(streaks, i)
      else
        local u = a / 0.7
        local s1, s0 = 1.2 * (1 - u) ^ 2, 1.2 * (1 - u) ^ 2 * 0.55
        local lv = st.v * (1 - u) * (6 + hi * 5)
        local x1 = rc(s1) + (2 + 78 * s1) * 0.3 * st.side
        local x0 = rc(s0) + (2 + 78 * s0) * 0.3 * st.side
        L(lv, x0, sy(s0), x1, sy(s1))
        L(lv * 0.5, x0 + 1, sy(s0), x1 + 1, sy(s1))
      end
    end

    -- the 808s: long low sweeps rolling up the road, gliding as they go
    for i = #sweeps, 1, -1 do
      local sw = sweeps[i]
      local life = max(1.2, K.beat_sec * 2.5)
      local a = T - sw.t0
      local u = a / life
      if u >= 1 then table.remove(sweeps, i)
      else
        local s = (1 - u) ^ 1.4 * 0.85
        local ys = sy(s)
        local ap = (1.2 + 3.5 * sw.v) * (0.3 + s)
        local k = 0.05 + 0.1 * (1 - u)
        local lv = sw.v * (1 - u) ^ 1.5 * (2 + lo * 3.5 + e * 1.5)
        local hw = (2 + 78 * s) * 1.05
        local x0, x1 = rc(s) - hw, rc(s) + hw
        local px, py
        for j = 0, 14 do
          local x = x0 + (x1 - x0) * j / 14
          local y = ys + sin(x * k + sw.ph - a * 5) * ap * sin(PI * j / 14)
          if px then L(lv, px, py, x, y) end
          px, py = x, y
        end
      end
    end

    -- the smoke, lit red from behind by the tail-lights
    for i = #smoke, 1, -1 do
      local p = smoke[i]
      local a = T - p.t0
      local u = a / p.life
      if u >= 1 or u < 0 then table.remove(smoke, i)
      else
        local x = p.x + p.vx * a
        local y = 58 + p.vy * a
        local r = 2 + a * 7 + p.v * 2
        local lv = (1.2 + mid * 1.8 + brake * 2.5 * (1 - u) + e * 0.5) * (1 - u) * (0.5 + p.v * 0.5)
        if c > 0.5 and K.hash(p.seed + floor(T * 6), 37) < c - 0.4 then
          for k = 0, 3 do P(lv + 1, x + (K.hash(p.seed + k, 38) - 0.5) * r * 2, y + (K.hash(p.seed + k, 39) - 0.5) * r, 1, 1) end
        else
          RING(lv, x + wob(y), y, r, 9, 0, TAU, 0.7, 1 + r * 0.15, p.seed)
          if u < 0.4 then RING(lv * 0.7, x + wob(y), y + 1, r * 0.55, 7, 0, TAU, 0.7, 1, p.seed + 3) end
        end
      end
    end

    -- the car, from behind: wing, quad round tail-lights, flank as it yaws
    local function car(cx, gy, l, ghost)
      local ox = -yaw * 3                              -- the cabin swings off the body
      if not ghost then
        P(1, cx - 21, gy + 1, 42, 2)                   -- its shadow
        P(2, cx - 18, gy - 3, 4, 4); P(2, cx + 14, gy - 3, 4, 4)     -- tyres
        -- the flank on the side it is turned
        local fw = abs(yaw) * 9
        if fw >= 1 then
          local fx = yaw > 0 and cx - 18 - fw or cx + 18
          for r = 0, 6 do P(1.2 + l * 0.15, fx + (yaw > 0 and r * 0.6 or 0), gy - 10 + r, max(1, fw - r * 0.6), 1) end
        end
        P(1.5 + l * 0.25, cx - 18, gy - 7, 36, 4)     -- bumper and rear panel
        P(1 + hi * 1.2, cx - 11 + ox * 0.5, gy - 16, 22, 5)   -- the rear window
        -- a streetlight sliding across the glass
        local gx = cx - 11 + ox * 0.5 + (1 - pole / 10) * 26
        if gx < cx + 11 + ox * 0.5 then L(min(12, 3 + hi * 5 + amp * 2), gx, gy - 16, gx - 3, gy - 12) end
      end
      L(l + 1, cx - 12 + ox, gy - 17, cx + 12 + ox, gy - 17)          -- the roof
      L(l, cx - 12 + ox, gy - 17, cx - 16, gy - 11)
      L(l, cx + 12 + ox, gy - 17, cx + 16, gy - 11)
      L(l + 0.5, cx - 18, gy - 11, cx + 18, gy - 11)                 -- the deck
      L(l + 1.5, cx - 19, gy - 13, cx + 19, gy - 13)                 -- the wing
      L(l, cx - 12, gy - 13, cx - 12, gy - 11); L(l, cx + 12, gy - 13, cx + 12, gy - 11)
      -- the four round lights
      local tl = min(13, (ghost and 2 or 5) + brake * (ghost and 2 or 8) + mid * 1.5 + lo * 0.8)
      for _, dx in ipairs({-14, -9, 9, 14}) do
        DISC(tl, cx + dx + wob(gy - 8), gy - 8, 1.7)
      end
      return tl
    end
    local cx = 64 + drift * 16
    local gy = 59 + sq_px
    if c > 0.3 then car(cx + sin(T * 2.3) * c * 12 + 4, gy - 1, 1 + c * 1.5, true) end
    local tl = car(cx, gy, 3 + e + amp, false)
    -- light trails off the lights as it swings
    if abs(dvel) > 0.05 then
      for _, dx in ipairs({-14, 14}) do
        L(tl * 0.45, cx + dx, gy - 8, cx + dx - dvel * 40, gy - 8 + abs(dvel) * 4)
      end
    end
    -- the ratchet: the lights stutter into a row of echoes
    if rat > 0.05 then
      for k = 1, rat_n do
        local ex = cx + rat_dir * k * 5
        local lv = rat * (7 - k * 0.7)
        P(lv, ex - 15, gy - 9 - k % 2, 3, 2); P(lv, ex + 12, gy - 9 - k % 2, 3, 2)
      end
    end
    -- hazards, pulsing slowly while the kick is out
    if kl > 0.1 then
      local hz = kl * (2 + 6 * (0.5 + 0.5 * sin(T * TAU * 0.8)))
      P(hz, cx - 20, gy - 10, 2, 2); P(hz, cx + 18, gy - 10, 2, 2)
    end
    -- exhaust, and the pops backfiring out of it
    P(2.5, cx + 8, gy - 3, 3, 1)
    for i = #pops, 1, -1 do
      local p = pops[i]
      local a = T - p.t0
      if a > 0.3 then table.remove(pops, i)
      else
        local lv = 13 * (1 - a / 0.3)
        P(lv, cx + 9, gy - 3, 2, 2)
        RING(lv * 0.6, cx + 10, gy - 2, 1.5 + a * 14, 8)
      end
    end

    -- the cowbell, ringing across the sky; the vox drifting through it
    for i = #pings, 1, -1 do
      local p = pings[i]
      if K.T - p.t0 > 1.4 then table.remove(pings, i)
      else draw_ping(p, 8 + p.slot * 7.4, (p.small and 21 or 19) - p.note * 1.4, 1) end
    end
    draw_vox(T)
    -- the clap: glare across the glass of the camera
    if clapv > 0.05 then
      for k = 0, 2 do L(clapv * (5 - k), 30 + k * 30 - clapv * 6, 0, 10 + k * 30 + clapv * 6, 63) end
    end
  end

  ---------------------------------------------------------------- view 2
  local HZ, DSH = 19, 37                 -- the horizon in the glass, the dash's lip
  local function draw2(S)
    local T, e, c, kl = K.T, K.energy, K.chaos, K.kickless
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]
    local ph = phrase(S)
    local tilt = clamp(drift * 0.12 + yaw * 0.1 + (c > 0.4 and sin(T * 1.7) * (c - 0.4) * 0.15 or 0), -0.3, 0.3)
    local VX = 64 + sin(ph * TAU) * 10 + drift * 6
    local function R(x, y) return x, y + (x - 64) * tilt end      -- the world tilts in the glass
    local function RL(l, x0, y0, x1, y1)
      local a, b = R(x0, y0); local cc, d = R(x1, y1)
      if b < DSH and d < DSH then L(l, a, b, cc, d) end
    end
    local function sy(s) return HZ + (DSH + 4 - HZ) * s end
    local function rc(s) return VX + (64 - VX) * s end
    local function wy(w) return clamp(2 / w, 0, 1.4) end
    local glow = 0.6 + amp * 0.7 + e * 0.3 + K.bar_pulse * 0.25

    -- outside: the glow over the city, the city's lights along the horizon
    for y = 3, DSH - 1 do
      local d = abs(y - HZ)
      drow(glow * max(0, 1 - d / 7) * 0.9 + (kl * 0.4) * max(0, 1 - d / 12), y, 4 + max(0, (34 - y) * 0.4), 124 - max(0, (34 - y) * 0.4))
    end
    for i = 0, 15 do
      local x = 10 + i * 7 + floor(K.hash(i, 51) * 5)
      local _, y = R(x, HZ - 1 - floor(K.hash(i, 52) * 3))
      P(1 + amp + 0.7 * (0.5 + 0.5 * sin(T * 0.7 + i * 1.3)), x, y, 1, 1)
    end
    -- the road and its lane lines
    RL(2 + hi, VX - 2, HZ, -30, DSH + 6)
    RL(2 + hi, VX + 2, HZ, 158, DSH + 6)
    local dash = road % 4
    for i = 0, 8 do
      local w = i * 4 - dash + 1
      if w > 0.8 then
        local s0, s1 = wy(w + 1.6), wy(w)
        RL(1.5 + s1 * 3 + hi * 3, rc(s0), sy(s0), rc(s1), sy(s1))
      end
    end
    -- cat's-eyes
    for i = #glints, 1, -1 do
      local g = glints[i]
      local a = T - g.t0
      if a > 0.5 then table.remove(glints, i)
      else
        local s = wy(1.5 + g.w * 10 + a * speed * 14)
        local x, y = R(rc(s) + (g.u - 0.5) * 60 * s, sy(s))
        if y < DSH then P(min(13, g.v * (1 - a / 0.5) * (8 + hi * 5)), x, y, max(1, 2 * s), 1) end
      end
    end
    -- the streetlights streaking past overhead, and the open hats' long ones
    local pole = road % 10
    for i = 3, 0, -1 do
      local w = i * 10 - pole + 1.5
      if w > 0.7 then
        local s = clamp(2 / w, 0, 3)
        local s0 = s * 0.7
        for side = -1, 1, 2 do
          local x0, y0 = VX + side * (6 + 26 * s0), HZ - 3 - 14 * s0
          local x1, y1 = VX + side * (6 + 26 * s), HZ - 3 - 14 * s
          local lv = min(13, 2 + s * 4 + hi * 4 + amp)
          if y1 > 2 and y0 > 2 then RL(lv, x0, y0, x1, y1) end
        end
      end
    end
    for i = #streaks, 1, -1 do
      local st = streaks[i]
      local a = T - st.t0
      if a > 0.7 then table.remove(streaks, i)
      else
        local u = a / 0.7
        local s = 0.3 + u * 1.6
        local x0, y0 = VX + st.side * (6 + 26 * s * 0.4), HZ - 3 - 14 * s * 0.4
        local x1, y1 = VX + st.side * (6 + 26 * s), max(3, HZ - 3 - 14 * s)
        RL(st.v * (1 - u) * (8 + hi * 5), x0, y0, x1, y1)
      end
    end
    K.haze(4, HZ - 6, 124, DSH, 0.15 + kl * 0.5, 1 + kl, T * 4 + road)
    -- the cowbell on the glass, the vox through it
    for i = #pings, 1, -1 do
      local p = pings[i]
      if T - p.t0 > 1.4 then table.remove(pings, i)
      else draw_ping(p, 16 + p.slot * 6, 16 - p.note * 1.2, 0.8) end
    end
    draw_vox(T)

    -- the cabin: pillars, header, the mirror and its dice
    local cab = 1.5 + amp * 0.8 + e * 0.5
    L(cab, 14, 2, 0, 36); L(cab, 114, 2, 127, 36); L(cab, 14, 2, 114, 2)
    L(1.5, 10, 2, 0, 26); L(1.5, 118, 2, 127, 24)          -- the pillars' trim
    -- the mirror: our own smoke behind us, lit red by the brakes
    local mg = 0.4 + brake * 2 + mid * 0.8 + lo * 0.4
    for y = 4, 9 do drow(mg * (1 - abs(y - 7) * 0.15), y, 47, 81) end
    for i = 1, #smoke do
      local p = smoke[i]
      local a = T - p.t0
      local u = a / p.life
      if u >= 0 and u < 1 then
        local mx = 64 - (p.x + p.vx * a - 64) * 0.35
        local my = 9 - a * 2.5
        if mx > 47 and mx < 80 and my > 3 then P((1.5 + mid * 2 + brake * 3) * (1 - u), mx, my, 2, 1) end
      end
    end
    L(1.5 + mg, 56, 9, 62, 6); L(1.5 + mg, 72, 9, 66, 6)       -- the road behind
    L(2 + amp, 46, 3, 82, 3); L(2 + amp, 46, 10, 82, 10)
    L(2.5 + amp, 46, 3, 46, 10); L(2.5 + amp, 82, 3, 82, 10)
    -- the dice: they swing as the car drifts and jump on the kick
    local sa = clamp(drift * 0.5 + yaw * 0.5 + swing_e * sin((T - swing_t) * 9) * exp(-(T - swing_t) * 2), -1.2, 1.2)
    local hx, hy = 64 + sin(sa) * 9, 11 + cos(sa) * 9
    L(2 + amp, 64, 10, hx, hy)
    local dl = 3 + e + lo * 1.5
    for d = -1, 1, 2 do
      local x, y = hx + d * 2.5 - 1.5, hy + (d > 0 and 1 or 0)
      P(dl, x, y, 3, 3)
      P(dl + 4, x + 1, y + 1, 1, 1)
    end

    -- the 808 along the dash's lip: a long low wave gliding as it fades
    for i = #sweeps, 1, -1 do
      local sw = sweeps[i]
      local life = max(1.2, K.beat_sec * 2.5)
      local a = T - sw.t0
      local u = a / life
      if u >= 1 then table.remove(sweeps, i)
      else
        local k = 0.05 + 0.12 * (1 - u)
        local lv = sw.v * (1 - u) ^ 1.5 * (1.2 + lo * 2.2 + e * 0.8)
        local px, py
        for x = 0, 128, 8 do
          local y = DSH - 1 + sin(x * k + sw.ph - a * 6) * (2.5 * sw.v * (1 - u * 0.6))
          if px then L(lv, px, py, x, y) end
          px, py = x, y
        end
      end
    end
    -- the dash: its lip and the dim slope under it
    local px, py
    for x = 0, 128, 8 do
      local y = DSH + ((x - 64) / 64) ^ 2 * 3
      if px then L(1.5 + lo * 0.8 + amp * 0.4, px, py, x, y) end
      px, py = x, y
    end


    -- the gauges: the speedo, and the tach that leaps on the 808 and glides
    local function gauge(gx, gy, frac, red)
      RING(1.5 + amp * 1.2 + e * 0.5, gx + wob(gy), gy, 9, 14, PI * 0.75, PI * 2.25)
      for k = 0, 8 do
        local a = PI * 0.75 + k / 8 * PI * 1.5
        local lv = (red and k >= 7) and (3 + rev * 6) or (2 + hi * 2)
        P(lv, gx + cos(a) * 7, gy + sin(a) * 7, 1, 1)
      end
      local a = PI * 0.75 + clamp(frac, 0, 1) * PI * 1.5
      L(min(13, 6 + e * 2 + (red and rev * 5 or 0)), gx, gy, gx + cos(a) * 8, gy + sin(a) * 8)
      P(4, gx - 1, gy - 1, 2, 2)
    end
    gauge(20, 51, 0.15 + speed * 0.6)
    gauge(108, 51, 0.1 + rev * 0.65 + lo * 0.2 + e * 0.1, true)
    -- hazards on the dash while the kick is out
    if kl > 0.1 then
      local hz = kl * (2 + 6 * (0.5 + 0.5 * sin(T * TAU * 0.8)))
      L(hz, 34, 46, 37, 41); L(hz, 37, 41, 40, 46); L(hz, 34, 46, 40, 46)
    end

    -- the deck: faceplate, the tape window, two reels winding over the phrase
    local fp = 1.5 + amp * 0.7 + e * 0.4
    L(fp, 42, 40, 86, 40); L(fp, 42, 62, 86, 62); L(fp, 42, 40, 42, 62); L(fp, 86, 40, 86, 62)
    L(1.5, 47, 43, 81, 43); L(1.5, 47, 57, 81, 57); L(2, 47, 43, 47, 57); L(2, 81, 43, 81, 57)
    P(2 + mid * 3, 49, 44, 30, 1)                                   -- the label's edge
    for r = 0, 1 do
      local rx = r == 0 and 56 or 72
      local pack = 2.2 + (r == 0 and (1 - ph) or ph) * 3
      fell(1.2 + lo * 1.5, rx, 51, pack, pack)
      RING(3 + mid * 2 + e, rx + wob(51), 51, 2, 6)
      for k = 0, 2 do
        local a = reel * (r == 0 and 1 or 1.15) + k * TAU / 3
        L(4 + hi * 2 + rat * 4, rx, 51, rx + cos(a) * 2.2, 51 + sin(a) * 2.2)
      end
    end
    L(2 + mid * 2, 56, 56, 72, 56)                                   -- the tape across
    -- the level bars under the window, left the lows, right the highs
    P(3 + lo * 5, 46, 59, 1 + lo * 18 + squat * 6, 1)
    P(3 + hi * 5, 82 - (1 + hi * 18), 59, 1 + hi * 18, 1)
    if kl > 0.5 then P(4 + kl * 3, 82, 41, 1, 3); P(4 + kl * 3, 84, 41, 1, 3)
    else L(4 + e * 2, 82, 41, 82, 44); L(4 + e * 2, 82, 41, 85, 42.5) end
    -- the ratchet stutters the tape: echo lines across the window
    if rat > 0.05 then
      for k = 1, rat_n do P(rat * (8 - k * 0.8), 48 + k * 4, 45 + (k % 3) * 4, 3, 1) end
    end
    -- the clap: glare sweeps the glass
    if clapv > 0.05 then
      for k = 0, 2 do L(clapv * (5 - k), 40 + k * 22 - clapv * 8, 3, 24 + k * 22 + clapv * 8, 34) end
    end
  end

  ---------------------------------------------------------------- view 3
  local DY = 33                           -- the deck
  local ARCH = {{34, 70}, {70, 106}}
  local AH = 20                           -- arch height
  local function ay(x)
    for i = 1, 2 do
      local a, b = ARCH[i][1], ARCH[i][2]
      if x >= a and x <= b then return DY - AH * sin(PI * (x - a) / (b - a)) end
    end
    return DY
  end
  local NN = 11                           -- lights per arch
  local function node(i)                  -- i = 0 .. 2 * NN - 1
    local ar = ARCH[i // NN + 1]
    local u = (i % NN + 0.5) / NN
    local x = ar[1] + (ar[2] - ar[1]) * u
    return x, DY - AH * sin(PI * u) - 1
  end

  local function draw3(S)
    local T, e, c, kl = K.T, K.energy, K.chaos, K.kickless
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]
    local ph = phrase(S)
    local glow = 0.6 + amp * 0.7 + e * 0.3 + K.bar_pulse * 0.25

    -- the sky glowing over the banks, the pyramid and the city dark in it
    for y = 14, 35 do local u = (y - 13) / 23; srow(glow * u * u * 1.4, y, CITY) end
    for i = 0, 6 do
      local x, y = floor(K.hash(i, 91) * 128), 1 + floor(K.hash(i, 92) * 8)
      P(1 + 0.6 * (0.5 + 0.5 * sin(T * (0.4 + K.hash(i, 93)) + i)) + hi * 0.8, x, y, 1, 1)
    end
    local pe = 2 + amp * 1.5 + e
    L(pe, 0, 36, 15, 12); L(pe, 15, 12, 30, 36)
    L(1 + mid, 15, 12, 12, 36); L(1, 4, 30, 26, 30)
    local beacon = 4 + 4 * (0.5 + 0.5 * sin(T * 1.6)) + K.bar_pulse * 3
    P(min(13, beacon), 15, 11, 1, 1)
    for i = 0, 17 do                                   -- the city's windows
      local x = 107 + floor(K.hash(i, 94) * 20)
      local top = K.at(CITY, x)
      if 36 - top > 3 then
        local on = K.hash(i + floor(T * 0.12 + K.hash(i, 96) * 9) * 37, 95) < 0.3 + e * 0.5
        if on then P(1 + amp * 1.5 + mid * 0.6, x, top + 1 + floor(K.hash(i, 97) * (36 - top - 2)), 1, 1) end
      end
    end

    -- the arches: two curved chords, their hangers, the deck beneath
    local al = 2 + amp * 0.8 + e * 0.4
    for i = 1, 2 do
      local a, b = ARCH[i][1], ARCH[i][2]
      local px, py, qy
      for k = 0, 12 do
        local x = a + (b - a) * k / 12
        local y = DY - AH * sin(PI * k / 12)
        local y2 = DY - (AH - 3) * sin(PI * k / 12)
        if px then L(al, px, py, x, y); L(al * 0.6, px, qy, x, y2) end
        px, py, qy = x, y, y2
      end
      for x = a + 3, b - 3, 3 do
        L(1 + mid * 1.5 + e * 0.3, x, ay(x) + 3, x, DY - 1)
      end
    end
    -- the far ends: approach spans and the piers
    L(1 + amp * 0.6, 0, DY + 2, 127, DY + 2)
    for _, x in ipairs({34, 70, 106}) do L(2.5, x, DY, x, DY + 6) end
    -- the arch lights: a chase over the phrase, the bar lifting them
    local chase = ph * 2 * NN
    local nl = {}
    for i = 0, 2 * NN - 1 do
      local d = abs(i - chase); d = min(d, 2 * NN - d)
      local lv = 1.5 + e * 1 + amp * 1.2 + 4 * exp(-d * d / 3) * (0.4 + e * 0.6) + K.bar_pulse * 1.5
      local x, y = node(i)
      P(min(12, lv), x, y, 1, 1)
      nl[i] = lv
    end

    -- the deck and its lights, running out from the car on the snare
    L(2 + lo * 0.8 + amp * 0.4, 0, DY, 127, DY)
    for x = 2, 126, 5 do
      local d = abs(x - dw_x) - (1 - dw) * 70
      local wave = dw * exp(-d * d / 60)
      P(min(13, 1.5 + hi * 2 + wave * 9), x, DY - 1, 1, 1)
    end

    -- other traffic with the energy, headlights going the other way
    for k = 1, floor(e * 3 + 0.3) do
      local x = (K.hash(k, 98) * 140 + T * (14 + k * 3)) % 140 - 6
      P(4 + amp * 2, x, DY - 2, 2, 1)
    end
    -- the car crossing: tail-lights, a long-exposure trail, its smoke
    local yv = floor(drift * 1.2 + 0.5)
    local cy = DY - 2 + yv
    local tl = min(13, 6 + brake * 7 + mid * 1.5)
    local tlen = 4 + speed * 22 + abs(dvel) * 20
    for k = 0, 2 do
      local x0 = bx + 2 + tlen * k / 3
      L(tl * (0.5 - k * 0.14), x0, cy + (k == 1 and yaw or 0), x0 + tlen / 3, cy)
    end
    P(tl, bx, cy, 2, 1)
    if rat > 0.05 then
      for k = 1, rat_n do P(rat * (7 - k * 0.6), bx + rat_dir * k * 4, cy - (k % 2), 2, 1) end
    end
    if kl > 0.1 then P(kl * (2 + 6 * (0.5 + 0.5 * sin(T * TAU * 0.8))), bx - 1, cy - 1, 4, 1) end
    for i = 1, #smoke do
      local p = smoke[i]
      local a = T - p.t0
      local u = a / p.life
      if u >= 0 and u < 1 then
        local x = bx + 3 + (p.x - 64) * 0.12 + a * 6
        local y = DY - 3 - a * 3
        RING((1 + mid * 1.5 + brake * 2) * (1 - u), x + wob(y), y, 0.8 + a * 2.5, 6, 0, TAU, 0.7)
      end
    end
    for i = #pops, 1, -1 do
      local p = pops[i]
      local a = T - p.t0
      if a > 0.3 then table.remove(pops, i) else P(13 * (1 - a / 0.3), bx + 2, cy, 2, 1) end
    end

    -- the cowbell rings on the arch lights, pitch for height
    for i = #pings, 1, -1 do
      local p = pings[i]
      if T - p.t0 > 1.4 then table.remove(pings, i)
      else
        local f = clamp(p.note / 10, 0, 1)
        local u = asin(f * 0.98) / PI
        if p.slot % 2 == 1 then u = 1 - u end
        local ar = ARCH[(p.slot // 2) % 2 + 1]
        local x = ar[1] + (ar[2] - ar[1]) * u
        draw_ping(p, x, DY - AH * sin(PI * u) - 1 - (p.small and 0 or 0), 0.8)
      end
    end
    draw_vox(T)

    -- the river: ripples, the lights shaking in it, the 808 rolling across
    for r = 0, 8 do
      local y = 38 + floor(r * 1.3 + r * r * 0.17)
      if y < 61 then
        for k = 0, 2 do
          local x = (K.hash(r * 3 + k, 99) * 160 + T * (3 + r * 0.8) * (k % 2 == 0 and 1 or -1)) % 160 - 16
          P(1 + hi * 0.8 + amp * 0.5, x, y, 4 + r * 2, 1)
        end
      end
    end
    local tear = c > 0.5 and (c - 0.5) * 2 or 0
    for i = 0, 2 * NN - 1, 2 do
      local x, y = node(i)
      local lv = nl[i] * 0.45 + mid * 1.2
      local len = 3 + (DY - y) * 0.6
      for k = 0, 3 do
        local ry = 37 + (DY - y) * 0.15 + k * len / 4
        if ry < 61 then
          local wx = sin(ry * 0.7 + T * 3 + i) * (0.8 + lo * 1.5)
          if tear > 0 and K.hash(i * 5 + k + floor(T * 5), 77) < tear * 0.5 then wx = wx + (K.hash(i + k, 78) - 0.5) * 12 end
          P(lv * (1 - k * 0.18), x + wx, ry, 1, max(1, len / 5))
        end
      end
    end
    -- the car's lights in the water
    for k = 0, 3 do
      local ry = 38 + k * 3
      P(tl * 0.35 * (1 - k * 0.2), bx + sin(ry + T * 3) * (1 + lo), ry, 2, 2)
    end
    -- the pyramid's beacon too
    P(beacon * 0.3, 15 + sin(T * 2.5) * 1.5, 52, 1, 6)
    -- glints on the water (closed hats, rim), long ones for the open hats
    for i = #glints, 1, -1 do
      local g = glints[i]
      local a = T - g.t0
      if a > 0.5 then table.remove(glints, i)
      else
        local y = 39 + floor(g.w * 22)
        P(min(13, g.v * (1 - a / 0.5) * (7 + hi * 6)), 4 + g.u * 120, y, 1 + floor(g.w * 3), 1)
      end
    end
    for i = #streaks, 1, -1 do
      local st = streaks[i]
      local a = T - st.t0
      if a > 0.7 then table.remove(streaks, i)
      else
        local u = a / 0.7
        local y = 42 + (st.side > 0 and 8 or 14)
        local x = 64 + st.side * u * 40
        L(st.v * (1 - u) * (7 + hi * 5), x - 14, y, x + 14, y)
      end
    end
    for i = #sweeps, 1, -1 do
      local sw = sweeps[i]
      local life = max(1.2, K.beat_sec * 2.5)
      local a = T - sw.t0
      local u = a / life
      if u >= 1 then table.remove(sweeps, i)
      else
        local ys = 38 + u ^ 0.8 * 24
        local ap = (0.8 + u * 3) * sw.v
        local k = 0.05 + 0.1 * (1 - u)
        local lv = sw.v * (1 - u) ^ 1.5 * (1.2 + lo * 2.2 + e * 0.8)
        local px, py
        for x = -4, 132, 8 do
          local y = ys + sin(x * k + sw.ph - a * 4) * ap
          if px then L(lv, px, py, x, y) end
          px, py = x, y
        end
      end
    end
    K.haze(0, 34, 128, 62, 0.12 + kl * 0.5 + e * 0.05, 1 + kl * 0.8, T * 2)
    if clapv > 0.05 then
      for k = 0, 2 do L(clapv * (5 - k), 20 + k * 40 - clapv * 6, 0, 4 + k * 40 + clapv * 6, 36) end
    end
  end

  ---------------------------------------------------------------- frame
  function M.draw(S)
    local T, DT, DTS = K.T, K.DT, K.DTS
    local e, c, kl = K.energy, K.chaos, K.kickless
    -- speed: energy drives, the kick dropping out lets it coast
    speed = K.follow(speed, (0.35 + e * 0.8 + fillv * 0.3) * (1 - 0.75 * kl) + 0.1, 1.2, DT)
    road = (road + DTS * speed * 14) % 40000
    -- the drift: swing toward the bar's side; yaw leads the swing
    local d0 = drift
    drift = K.follow(drift, clamp(drift_to, -1.2, 1.2) * (1 - 0.6 * kl), max(0.2, K.beat_sec * 1.2), DTS)
    drift = clamp(drift, -1.2, 1.2)
    dvel = DT > 0 and K.follow(dvel, clamp((drift - d0) / DT, -3, 3) * 0.2, 0.15, DT) or dvel
    yaw = K.follow(yaw, clamp((drift_to - drift) * 1.2 + dvel * 2, -1, 1), 0.25, DT)
    -- smoke rolls off the tyres in the drift
    smoke_acc = smoke_acc + DTS * (0.6 + abs(yaw) * 4 + e * 2.5 + fillv * 6) * (1 - 0.6 * kl)
    while smoke_acc >= 1 do smoke_acc = smoke_acc - 1; puff(1, 0.3 + abs(yaw) * 0.5 + e * 0.2) end
    -- the kick's squat: a pixel a frame
    local to = squat > 0.4 and 1 or 0
    if to > sq_px then sq_px = sq_px + 1 elseif to < sq_px then sq_px = sq_px - 1 end
    squat = squat * exp(-DT / 0.1)
    brake = brake * exp(-DT / 0.18)
    clapv = clapv * exp(-DT / 0.12)
    rat = rat * exp(-DT / 0.25)
    fillv = fillv * exp(-DT / 0.9)
    track = track * exp(-DT / 0.6)
    rev = rev * exp(-DT / (K.beat_sec * 0.9))
    dw = dw * exp(-DT / 0.35)
    swing_e = swing_e * exp(-DT / 1.5)
    reel = reel + DTS * (2 + speed * 3 + rat * 25) * (1 - 0.85 * kl)
    -- the tracking band rolls up the picture; paused, it shivers in place
    local roll = (5 + c * 18 + track * 30) * (1 - kl * 0.95)
    trk_y = trk_y - DTS * roll
    if trk_y < -12 then trk_y = trk_y + 88 end
    if kl > 0.5 then trk_y = clamp(trk_y, 8, 56) + (K.hash(floor(T * 7), 41) - 0.5) * 1.2 end
    trk_h = 2.5 + c * 3 + track * 4 + kl * 2
    if K.hash(floor(T * 3), 42) < 0.3 then trk_dx = (K.hash(floor(T * 3), 43) < 0.5 and -1 or 1) * (1 + floor(c * 3 + track * 2)) end
    wamp = 0.35 + c * 1.6 + track * 1.5 + kl * 0.4
    -- the bridge car crosses right to left, coasting while paused
    bx = bx - DTS * speed * 18
    if bx < -40 then bx = bx + 180 end
    gk = K.view == 2 and 0.62 or (K.view == 3 and 0.8 or 1)
    if K.view == 2 then draw2(S)
    elseif K.view == 3 then draw3(S)
    else draw1(S) end
    draw_tape(T, e, c, kl, A[K.HI])
  end

  M.init()
  return M
end
