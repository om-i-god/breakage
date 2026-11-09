-- amapiano. view 1: a township street at night: tin roofs black against a
-- warm glow, street lamps pooling light on the road, people dancing under
-- them, smoke off a braai, and the log drum hanging over it all as a big
-- round pulse that glides from note to note.
-- view 2: the long groove: the road running away to the horizon between
-- lamps, the log drum rising at the end of it and every note rolling down
-- the road toward us as a rounded swell, the keys' chord hanging in the sky
-- as soft bands of light.
-- view 3: the keys: a piano across the foot of the picture, each chord
-- lifting soft columns of light off the keys it holds, the log drum a big
-- round glow gliding along the keyboard to its note, dancers' shadows on
-- the wall behind.
--
-- the log drum (perc 18) is the bassline: each note picks a degree off the
-- bar's chord root by where it falls in the bar, so the riff repeats bar
-- to bar, and the pulse glides there and sags a little as the note dies;
-- a tom sets the pitch from its own; the kick nudges it at the root. the
-- chord moves on with the bar (four chords, a jazzy minor turn) and is
-- struck on snares, claps and rims; shakers and closed hats are a fine
-- shimmer (dust in the lamp light, sparks on the road, motes over the
-- keys), open hats and rides a wider sparkle; the clave knocks a window
-- on (view 1), a cat's eye (view 2), a high key (view 3). a ratchet throbs
-- the pulse that many times; a fill sends a car's headlights down the
-- street, surges the road, rolls a run up the keys. the phrase warms the
-- sky toward its end. energy brings more dancers, lamps and notes, chaos
-- buzzes the lamps, splits the pulse and scatters the steps, and kickless
-- stretches slow the dancing and let the log drum and the smoke fill it.
--
-- the ears: the lows swell the pulse and its glow, the mids light the
-- windows, the chord bands and the key columns, the highs the stars, the
-- shimmer and the road, and the level lights the lamps.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, exp = math.sin, math.cos, math.floor, math.max, math.min, math.abs, math.exp
  local PI, TAU = math.pi, K.TAU

  ---------------------------------------------------------------- harmony
  -- four chords over two octaves of semitones (0 = C): Fm7, Ebmaj7, Dbmaj7, Cm7
  local CHORDS = {{5, 8, 12, 15, 19}, {3, 7, 10, 14, 17}, {1, 5, 8, 12, 15}, {0, 3, 7, 10, 14}}
  local ROOT = {5, 3, 1, 0}
  local DEG = {0, 7, 12, 10, 3, 5, 0, 7}
  local BLACK = {[1] = true, [3] = true, [6] = true, [8] = true, [10] = true}
  local WIDX = {[0] = 0, [2] = 1, [4] = 2, [5] = 3, [7] = 4, [9] = 5, [11] = 6}

  -- state
  local bar_n, chord, stab, stab_t, hold
  local lp, lp_to, lv, bend, throb, throb_n, throb_t
  local shim, spark, knock, knock_t, car_t, surge, run_t
  local humps, cols, motes, swing_v, arms, dip
  local lampbuzz
  local lvs, stabs = 0, 0              -- eased, for the big areas

  function M.init()
    bar_n, chord, stab, stab_t, hold = 0, 1, 0, -9, 0
    lp, lp_to, lv, bend, throb, throb_n, throb_t = 5, 5, 0, 0, 0, 0, -9
    shim, spark, knock, knock_t, car_t, surge, run_t = 0, 0, 0, -9, -99, 0, -99
    humps, cols, motes = {}, {}, {}
    swing_v, arms, dip = 0, 0, 0
    lampbuzz = 0
  end
  M.clear = M.init

  local function cur_chord()
    if not K.playing then return CHORDS[floor(K.T / 7) % 4 + 1] end
    return CHORDS[chord]
  end
  local function cur_root()
    if not K.playing then return ROOT[floor(K.T / 7) % 4 + 1] end
    return ROOT[chord]
  end

  -- a log drum note: v its velocity, n its pitch (semitones 0..23)
  local function note(v, n)
    lp_to = clamp(n, 0, 23)
    lv = max(lv, 0.35 + 0.65 * v)
    bend = 1.2
    if #humps >= 8 then table.remove(humps, 1) end
    humps[#humps + 1] = {t0 = K.T, n = lp_to, v = v}
  end

  local function strike(v)
    stab, stab_t = max(stab, 0.4 + 0.6 * v), K.T
    local ch = cur_chord()
    for _, k in ipairs(ch) do
      if #cols >= 14 then table.remove(cols, 1) end
      cols[#cols + 1] = {k = k, t0 = K.T, v = v * (0.7 + 0.3 * K.rnd())}
    end
  end

  ---------------------------------------------------------------- events
  function M.kick(v)
    v = K.num(v, 1)
    dip = max(dip, v)
    lv = max(lv, 0.25 + 0.3 * v)
    if lv < 0.5 then lp_to = cur_root() end
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    if K.num(n, 1) > 1 then
      throb = max(throb, 0.6); return
    end
    strike(v * 0.8)
    arms = max(arms, 0.5 * v)
  end
  function M.clap(v)
    v = K.num(v, 1)
    strike(v * 0.7)
    arms = max(arms, v)
  end
  function M.rim(v)
    v = K.num(v, 1)
    stab = max(stab, 0.3 * v)
    knock, knock_t = max(knock, 0.6 * v), K.T
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    if open then spark = max(spark, 0.5 + 0.5 * v) else shim = max(shim, 0.3 + 0.4 * v) end
  end
  function M.ride(v) spark = max(spark, 0.4 * K.num(v, 1)) end
  function M.shaker(v) shim = max(shim, 0.45 + 0.55 * K.num(v, 1)) end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 18 or kind == 7 then
      local deg = DEG[floor(K.hash(K.step % 16, 5) * #DEG) + 1]
      note(v, cur_root() + deg)
    elseif kind == 4 or kind == 3 or kind == 21 then
      knock, knock_t = max(knock, 0.5 + 0.5 * v), K.T
    elseif kind == 10 or kind == 9 then
      shim = max(shim, 0.5 + 0.5 * v)
    else
      spark = max(spark, 0.3 * v)
      stab = max(stab, 0.2 * v)
    end
  end
  function M.tom(v, hz)
    v, hz = K.num(v, 1), clamp(K.num(hz, 110), 20, 2000)
    local n = floor(12 * math.log(hz / 65.4, 2) + 0.5) % 24
    note(v * 0.8, n)
  end
  function M.tick() shim = max(shim, 0.3) end

  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    throb, throb_n, throb_t = 1, n, K.T
    lv = max(lv, 0.7)
    spark = max(spark, 0.6)
  end

  function M.fill()
    car_t, surge, run_t = K.T, 1, K.T
  end

  function M.bar(S)
    bar_n = bar_n + 1
    chord = bar_n % 4 + 1
    hold = 1
    if K.chaos > 0.5 and K.rnd() < K.chaos * 0.5 then chord = floor(K.rnd() * 4) + 1 end
  end

  ---------------------------------------------------------------- shared bits
  -- solid bands of light, a whole level each (no row dither, so a jolt of a
  -- pixel only moves their edges)
  local function bands(y0, y1, fn, prof, x0, x1)
    for y = y0, y1 do
      local l = floor(K.num(fn(y), 0) + 0.5)
      if l >= 1 then K.row_above(min(l, 13), y, prof, x0, x1) end
    end
  end
  local function phrase(S)
    local pl = max(1, floor(K.num(S.phrase_len, 16)))
    local pp = K.num(S.phrase_pos, 0) % pl
    return clamp((pp + K.bar_ph) / pl, 0, 1)
  end

  -- a soft round glow: dithered disc rows thinning outward, then rings
  local function glow(cx, cy, r, l, rings, seed, ls)
    r = clamp(r, 1, 11)
    local rl = l
    l = ls or l
    for dy = -floor(r), floor(r) do
      local w = math.sqrt(max(0, r * r - dy * dy))
      if w >= 1 then
        local u = abs(dy) / r
        put(max(1, l * (1 - u * 0.6)), cx - w, cy + dy, w * 2, 1)
        if u < 0.6 then put(l * 0.35, cx - w * 0.5, cy + dy, w, 1) end
      end
    end
    for k = 1, rings do
      K.ring(rl * (0.9 - k * 0.2), cx, cy, r + k * 3, 20, 0, TAU, 1, K.chaos * 1.5, seed + k)
    end
  end

  -- a dancer: feet at (x, y), h tall, sway s (-1..1), dip, arms (0..1)
  local function dancer(l, x, y, h, s, dp, ar, i)
    local knee = dp * 2
    local hip_x = x + s * 1.5
    local hip_y = y - h * 0.45 + knee
    local sh_x = x + s * 3
    local sh_y = y - h * 0.8 + knee
    local step = sin(K.T * 2.2 + i * 1.7) * (1 + K.chaos * 2)
    line(l, hip_x, hip_y, x - 2 + step * 0.5, y)
    line(l, hip_x, hip_y, x + 2 - step * 0.5, y)
    line(l, hip_x, hip_y, sh_x, sh_y)
    line(l * 0.8, hip_x + 1, hip_y, sh_x + 1, sh_y)
    put(l + 0.5, sh_x - 1, sh_y - 3, 2, 2)
    put(l, sh_x - 1.5, sh_y - 2, 3, 1)
    if ar > 0.35 then
      line(l, sh_x, sh_y + 1, sh_x - 3 - s, sh_y - 4 * ar)
      line(l, sh_x, sh_y + 1, sh_x + 3 - s, sh_y - 4 * ar)
    else
      line(l, sh_x, sh_y + 1, sh_x - 3 + s * 2, sh_y + 4)
      line(l, sh_x, sh_y + 1, sh_x + 3 + s * 2, sh_y + 3)
    end
  end

  ---------------------------------------------------------------- view 1
  local GY = 47                         -- the street's far edge
  local LAMPS = {16, 64, 112}
  -- the township: houses black against the glow
  local HOUSES = {}
  do
    local x = -4
    local i = 0
    while x < 132 do
      i = i + 1
      local w = 10 + floor(K.hash(i, 31) * 9)
      local h = 6 + floor(K.hash(i, 32) * 6)
      HOUSES[#HOUSES + 1] = {x = x, w = w, h = h, pitch = K.hash(i, 33) < 0.45,
        win = 2 + floor(K.hash(i, 34) * (w - 6)), id = i}
      x = x + w + floor(K.hash(i, 35) * 3)
    end
  end
  local ROOFS = K.profile(function(x)
    for _, H in ipairs(HOUSES) do
      if x >= H.x and x < H.x + H.w then
        local top = GY - H.h
        if H.pitch then top = top - 3 + abs(x - (H.x + H.w / 2)) / (H.w / 2) * 3 end
        return top
      end
    end
    return GY - 2
  end)
  local TOWER_X = 86

  local function draw1(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local ph = phrase(S)

    -- the sky: deep at the top, a warm glow low over the roofs (the phrase
    -- warms it toward its end)
    local gb = 1 + e * 0.5 + ph * 0.8 + lo * 1.2 + amp * 0.8 + stabs * 0.8
    bands(35 - floor(ph * 3 + e), GY - 1, function(y)
      local u = (y - 33) / (GY - 34)
      return 1 + u * u * gb
    end, ROOFS)
    -- stars
    for i = 0, 15 do
      local x, y = floor(K.hash(i, 1) * 127), 1 + floor(K.hash(i, 2) * 16)
      local tw = 0.5 + 0.5 * sin(T * (0.5 + K.hash(i, 3)) + i * 2.1)
      put(0.7 + tw * (0.6 + hi * 2.5) + spark * tw * 2, x, y, 1, 1)
    end

    -- the log drum: a big round pulse over the roofs, high for a high note
    local py = 30 - lp * 1.05 + bend * 1.5
    local px = 44 + sin(T * 0.11) * 8
    local th = throb > 0.05 and (0.5 + 0.5 * cos((T - throb_t) * TAU * 8)) * throb or 0
    local pr = 4 + lvs * 6 + lo * 3 + th * 1.5 + kl * 2
    glow(px, py, pr, 1.2 + lv * 4 + lo * 2 + th * 2, 2, 3, 1.2 + lvs * 3 + lo * 2 + th)
    if c > 0.45 then glow(px + 14 + c * 10, py + 3, pr * 0.5, 1 + c * 2, 0, 9) end

    -- the water tower and the wires, swaying with the lows
    line(2, TOWER_X - 4, GY - 8, TOWER_X - 2, 22)
    line(2, TOWER_X + 4, GY - 8, TOWER_X + 2, 22)
    put(2 + mid * 2, TOWER_X - 5, 16, 11, 1)
    put(1.5, TOWER_X - 5, 17, 1, 5)
    put(1.5, TOWER_X + 5, 17, 1, 5)
    put(1.5 + mid * 1.5, TOWER_X - 5, 21, 11, 1)
    put(4 + hi * 4 + spark * 3, TOWER_X, 14, 1, 1)
    local sag = 3 + lo * 2 + sin(T * 0.7) * 0.6 + dip * 1.2
    for j = 1, #LAMPS - 1 do
      local x0, x1 = LAMPS[j] + 2, LAMPS[j + 1] - 2
      for wire = 0, 1 do
        local y0 = 20 + wire * 2
        local px0, py0
        for q = 0, 6 do
          local u = q / 6
          local x = x0 + (x1 - x0) * u
          local y = y0 + sag * (1 - (2 * u - 1) ^ 2) + (c > 0.4 and sin(T * 13 + q + j) * (c - 0.4) or 0)
          if px0 then line(1.2 + amp * 0.8, px0, py0, x, y) end
          px0, py0 = x, y
        end
      end
    end

    -- the roofs: a lit edge along the corrugated tin; windows, the chord on
    for _, H in ipairs(HOUSES) do
      local cx = H.x + H.w / 2
      if H.pitch then
        line(1.5 + mid * 1.2, H.x, GY - H.h, cx, GY - H.h - 3)
        line(1.5 + mid * 1.2, cx, GY - H.h - 3, H.x + H.w, GY - H.h)
      else
        line(1.5 + mid * 1.2, H.x, GY - H.h, H.x + H.w - 1, GY - H.h)
      end
      -- windows: some always lit, the chord's few glowing with the keys
      local ch = cur_chord()
      local inch = false
      for _, k in ipairs(ch) do if (H.id * 5 + k) % 9 == 0 then inch = true end end
      local base = (K.hash(H.id, 36) < 0.25 + e * 0.4) and (1.5 + mid * 2) or 0
      local wl = base
      if inch then wl = max(wl, 1.5 + stab * 7 + mid * 3 + hold * 1.5) end
      if knock > 0.05 and H.id % 4 == floor(knock_t * 10) % 4 then wl = max(wl, knock * 9) end
      if wl > 0.5 then put(min(12, wl), H.x + H.win, GY - H.h + 3, 3, 2) end
    end

    -- the braai: the drum's coals glowing with the lows, smoke climbing
    local bx = 34
    put(2, bx - 4, GY + 2, 9, 1)
    put(2.5 + lo * 4 + dip * 2, bx - 3, GY + 1, 7, 1)
    line(1.5, bx - 3, GY + 3, bx - 4, GY + 6)
    line(1.5, bx + 3, GY + 3, bx + 4, GY + 6)
    local wind = sin(T * 0.13) * 6 + c * 6
    local np = 6 + floor(kl * 3)
    for k = 0, np - 1 do
      local u = (T * 0.12 + k / np) % 1
      local y = GY - u * 40
      local x = bx + sin(T * 0.4 + u * 5) * 2 * u + wind * u * u
      local r = 1.2 + u * 4.5
      local l = (1 - u) * (1.4 + kl * 1.2 + lo * 0.6)
      if l > 0.5 then K.ring(l, x, y, r, 8, 0, TAU, 0.8) end
    end

    -- the street lamps: poles, heads, the cones of light and their pools
    local nl = #LAMPS
    for j = 1, nl do
      local x = LAMPS[j]
      local buzz = 1
      if c > 0.35 and j == 2 then buzz = 0.55 + 0.45 * K.hash(floor(T * 9), 7 + j) end
      local ll = (1.5 + amp * 2.2 + e * 0.6) * buzz * (1 - kl * 0.25)
      line(2, x, 18, x, GY + 8)
      line(2, x, 18, x + 4, 18)
      put(min(13, 5 + ll * 2), x + 3, 19, 3, 1)
      -- the cone: every other row lit, wider as it falls
      for r = -2, 2 do
        -- (the highs shimmer the light, ray by ray)
        local cl = ll * (0.9 - abs(r) * 0.22) + hi * 2.2 * (0.6 + 0.4 * sin(T * 7 + r * 1.9 + j))
        line(cl, x + 4 + r * 0.6, 21, x + 4 + r * 5.5, GY + 9)
      end
      K.ring(ll * 1.2, x + 4, GY + 10, 13, 16, 0, TAU, 0.22)
    end
    -- the shimmer: dust in the lamp light (shakers, closed hats, the highs)
    K.grain(function(u, v)
      local j = LAMPS[floor(u * nl) % nl + 1]
      local y = 22 + v * 30
      return j + 4 + ((u * nl) % 1 - 0.5) * (4 + v * 20), y
    end, 2 + hi * 14 + shim * 40 + spark * 20, 4 + hi * 3 + shim * 4)

    -- the street: a faint dusty road, ruts running away
    bands(GY + 1, GY + 3, function(y) return 1 + lo * 1.2 + amp * 0.5 - (y - GY) * 0.2 end)
    for k = 0, 3 do
      local y = GY + 3 + k * k * 1.3
      K.dashes(1 + lo * 0.8, y, 6 + k * 3, 14 + k * 6, k * 5 + sin(T * 0.2 + k) * 2)
    end
    line(1.5 + amp, 0, GY, 127, GY)

    -- headlights on a fill
    local ca = T - car_t
    if ca >= 0 and ca < 2.5 then
      local x = -20 + ca * 70
      put(9, x, 56, 2, 1)
      put(9, x + 6, 57, 2, 1)
      line(3, x + 2, 56, x + 30, 53)
      line(3, x + 8, 57, x + 36, 60)
      line(1.5, x - 14, 55, x + 1, 55)
    end

    -- the dancers on the street, lit by the nearest lamp
    local nd = floor(3 + e * 5 + 0.5)
    local sway_f = (0.5 - kl * 0.25)
    for i = 1, nd do
      local x = 6 + (i - 0.5) / nd * 116 + sin(T * 0.23 + i * 2.1) * 4
      if c > 0.5 then x = x + (K.hash(i + floor(T * 2) * 9, 4) - 0.5) * c * 8 end
      local near = 0
      for _, lx in ipairs(LAMPS) do near = max(near, 1 - abs(x - lx - 4) / 22) end
      local s = sin(TAU * (K.beat_ph + (K.stepf // 4) % 2) * sway_f + i * 0.9)
      local l = 2 + near * (3 + amp * 3) + mid * 1.5
      dancer(l, x, 60 + (i % 2) * 2, 15 + K.hash(i, 9) * 4, s, dip * (0.6 + 0.4 * K.hash(i, 8)),
        max(arms, kl * 0.5 * (0.5 + 0.5 * sin(T * 0.8 + i))), i)
    end
  end

  ---------------------------------------------------------------- view 2
  local VX, VY = 64, 24                 -- the road's vanishing point
  local NLAMP = 5

  local function draw2(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local ph = phrase(S)
    local speed = (K.playing and (0.25 + e * 0.35) or 0.1) * (1 - kl * 0.5) + surge * 0.4

    -- the sky: stars, and the chord as soft bands of light
    for i = 0, 17 do
      local x, y = floor(K.hash(i, 11) * 127), 1 + floor(K.hash(i, 12) * 18)
      local tw = 0.5 + 0.5 * sin(T * (0.6 + K.hash(i, 13)) + i)
      put(0.6 + tw * (0.6 + hi * 2.2) + spark * tw * 2, x, y, 1, 1)
    end
    local ch = cur_chord()
    for j, k in ipairs(ch) do
      local y = VY - 3 - k * 0.85
      local l = min(4.5, 0.8 + mid * 1.2 + stabs * 2.2 * (1 - j * 0.1) + hold * 0.5 + ph * 0.5)
      local w = 34 + 20 * sin(T * 0.21 + j * 1.3) + mid * 14
      local x = VX - w / 2 + sin(T * 0.17 + j) * 10
      put(l, x, y, w, 1)
      put(l * 0.5, x + w * 0.2, y - 1, w * 0.6, 1)
      if j % 2 == 0 then put(l * 0.45, x + w * 0.15, y + 1, w * 0.7, 1) end
    end

    -- the far township: a low black line with little lights, the glow over it
    bands(VY - 6, VY, function(y) return 1 + (y - VY + 6) / 6 * (0.8 + lo * 1.5 + ph * 0.8 + amp * 0.8) end)
    for i = 0, 21 do
      local x = floor(K.hash(i, 21) * 124) + 2
      local on = K.hash(i, 22) < 0.5 + e * 0.4
      if on then put(1.2 + (0.5 + 0.5 * sin(T * 0.9 + i)) * (hi * 2 + 0.5), x, VY - 1 - floor(K.hash(i, 23) * 2), 1, 1) end
    end

    -- the log drum rising at the end of the road
    local th = throb > 0.05 and (0.5 + 0.5 * cos((T - throb_t) * TAU * 8)) * throb or 0
    local py = VY - 4 - lp * 0.5 + bend
    local pr = 3 + lvs * 5 + lo * 2.5 + th * 1.5 + kl * 1.5
    glow(VX, py, pr, 1.5 + lv * 4 + lo * 2 + th * 2, 2, 5, 1.5 + lvs * 3 + lo * 2 + th)

    -- the road: its edges, the centre line rushing toward us
    line(2 + amp + hi, VX - 2, VY, -30, 64)
    line(2 + amp + hi, VX + 2, VY, 158, 64)
    -- (the tar holds a little of the glow near the horizon)
    for y = VY + 1, VY + 5 do
      local half = 2 + (y - VY) * 1.18
      put(1 + lo * 1.2 * (1 - (y - VY) / 6), VX - half, y, half * 2, 1)
    end
    local z0 = (T * speed) % 1
    for k = 0, 7 do
      local z = (k + z0) / 8
      local zz = z * z
      local y = VY + 1 + zz * 39
      local hh = 0.5 + zz * 4
      put(1.5 + zz * 4 + dip * zz * 3, VX - 0.5 - zz, y, 1 + zz * 2, hh)
      -- cat's eyes, glinting with the shimmer
      local ce = (k % 2 == 0) and (1 + hi * 3 + shim * 5 + (knock > 0.05 and knock * 6 or 0)) or 0
      if ce > 0.6 then
        put(ce * zz + 0.6, VX - 3 - zz * 34, y, 1, 1)
        put(ce * zz + 0.6, VX + 3 + zz * 34, y, 1, 1)
      end
    end
    -- sparkle on the tar (shakers and the highs)
    K.grain(function(u, v)
      local y = VY + 4 + v * v * 38
      local half = 2 + (y - VY) * 1.1
      return VX + (u - 0.5) * 2 * half, y
    end, 2 + hi * 12 + shim * 30 + spark * 15, 3 + hi * 3 + shim * 3)

    -- the lamps: in pairs, coming toward us
    local nlamp = NLAMP - 1 + floor(e * 2)
    for k = 0, nlamp - 1 do
      local z = ((k + (T * speed * 0.6) % 1) / nlamp)
      local zz = z * z
      local by = VY + 1 + zz * 39
      local hgt = 2 + zz * 34
      local buzz = (c > 0.35 and k % 3 == 1) and (0.5 + 0.5 * K.hash(floor(T * 9) + k, 17)) or 1
      local ll = (1.5 + amp * 2.5 + e * 0.6) * buzz * (0.4 + zz * 0.8)
      for side = -1, 1, 2 do
        local x = VX + side * (5 + zz * 100)
        line(1.5 + zz * 1.5, x, by, x, by - hgt)
        local hx = x - side * (1 + zz * 5)
        line(1.5 + zz, x, by - hgt, hx, by - hgt)
        put(min(13, 3 + ll * 2.5), hx - zz, by - hgt, 1 + zz * 3, 1)
        if zz > 0.08 then
          K.ring(ll * 0.6 + hi * 1.2, hx - side * zz * 6, by, 3 + zz * 16, 12, 0, TAU, 0.25)
          line(hi * 1.6 * zz, hx, by - hgt + 1, hx - side * zz * 8, by)
          line(hi * 1.6 * zz, hx, by - hgt + 1, hx + side * zz * 6, by)
        end
      end
    end

    -- the notes: rounded swells rolling down the road, high for high
    for i = #humps, 1, -1 do
      local H = humps[i]
      local u = (T - H.t0) * (0.45 + speed * 0.8)
      if u >= 1 then table.remove(humps, i)
      else
        local zz = u * u
        local y = VY + 1 + zz * 39
        local w = 2 + zz * 40
        local h = (2 + H.n * 0.35) * (0.3 + zz * 1.6)
        local l = (2 + H.v * 5) * (1 - u) ^ 0.7 + lo * 1.5
        K.ring(l, VX, y, w, 14, PI, TAU, h / w)
        if zz > 0.2 then K.ring(l * 0.5, VX, y, w * 0.7, 10, PI, TAU, h * 0.6 / (w * 0.7)) end
      end
    end

    -- headlights on a fill: a car coming up the road
    local ca = T - car_t
    if ca >= 0 and ca < 2 then
      local u = ca / 2
      local zz = u * u
      local y = VY + 2 + zz * 38
      local sp = 1 + zz * 20
      put(min(12, 4 + zz * 8), VX - sp, y, 1 + zz * 2, 1)
      put(min(12, 4 + zz * 8), VX + sp, y, 1 + zz * 2, 1)
    end

    -- two dancers close by, against the road's glow
    for i = 1, 2 do
      local x = i == 1 and 14 or 113
      local s = sin(TAU * (K.beat_ph + (K.stepf // 4) % 2) * (0.5 - kl * 0.25) + i * 2)
      dancer(2.5 + mid * 2 + amp * 2, x + sin(T * 0.3 + i) * 2, 66, 30, s * 2, dip * 1.5,
        max(arms, kl * 0.5), i)
    end
  end

  ---------------------------------------------------------------- view 3
  local KY = 49                         -- the keys' top
  local WW = 9                          -- a white key's width
  local KX0 = 1
  local keyl = {}                       -- each key's light, eased
  local function keyx(n)                -- a key's left edge and width
    local o, s = n // 12, n % 12
    if BLACK[s] then
      return KX0 + (o * 7 + WIDX[s - 1]) * WW + WW - 3, 5, true
    end
    return KX0 + (o * 7 + WIDX[s]) * WW, WW, false
  end

  local function draw3(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local ph = phrase(S)

    -- the wall: a hanging bulb, its light falling off, the dancers' shadows
    local sw = sin(T * 0.6) * 3 + sin(TAU * K.beat_ph * 0.5) * dip
    local bxl, byl = 64 + sw, 9
    line(1.5, 64, 0, bxl, byl - 2)
    local bl = 2 + amp * 3 + e + ph
    K.disc(1 + bl * 0.4, bxl, byl, 4 + amp * 2)
    put(min(12, 4 + bl * 1.5), bxl - 1, byl - 1, 3, 2)
    K.ring(bl * 0.6, bxl, byl, 7 + amp * 3 + ph * 2, 16)
    for r = -3, 3 do
      line(bl * (0.45 - abs(r) * 0.08) + hi * 1.8 * (0.6 + 0.4 * sin(T * 6 + r * 2.3)), bxl + r * 1.2, byl + 3, bxl + r * 9, KY - 2)
    end
    -- the window: the street outside, a lamp and the township's glow
    local wx0, wy0, wx1, wy1 = 98, 4, 124, 24
    put(1, wx0 + 1, wy1 - 6, wx1 - wx0 - 1, 5)
    put(1.5 + lo * 2 + ph, wx0 + 1, wy1 - 3, wx1 - wx0 - 1, 2)
    for k = 0, 2 do
      local x = wx0 + 3 + k * 8 + floor(K.hash(k, 66) * 3)
      put(1.5 + mid * 2 + stabs * 3, x, wy1 - 5 - (k % 2), 3, 2 + (k % 2))
    end
    put(min(12, 3 + amp * 4), wx0 + 18, wy0 + 6, 2, 1)
    line(1.5, wx0 + 18, wy0 + 7, wx0 + 18, wy1 - 1)
    for k = 0, 3 do
      put((0.5 + 0.5 * sin(T * (0.7 + k * 0.3) + k)) * (1 + hi * 2.5), wx0 + 3 + k * 6, wy0 + 2 + (k * 3) % 5, 1, 1)
    end
    line(2 + amp, wx0, wy0, wx1, wy0)
    line(2 + amp, wx0, wy1, wx1, wy1)
    line(2 + amp, wx0, wy0, wx0, wy1)
    line(2 + amp, wx1, wy0, wx1, wy1)
    line(1.5, (wx0 + wx1) / 2, wy0, (wx0 + wx1) / 2, wy1)
    line(1.5, wx0, (wy0 + wy1) / 2, wx1, (wy0 + wy1) / 2)
    local nd = 2 + floor(e * 3 + 0.5)
    for i = 1, nd do
      local x = 10 + (i - 0.5) / nd * 108 + sin(T * 0.19 + i * 2.7) * 6
      local s = sin(TAU * (K.beat_ph + (K.stepf // 4) % 2) * (0.5 - kl * 0.25) + i * 1.3)
      dancer(1 + mid * 0.8, x, 46, 26 + K.hash(i, 61) * 6, s * 1.5, dip, max(arms, kl * 0.4), i + 10)
    end

    -- the motes over the keys: a fine shimmer (shakers, closed hats, highs)
    for i = 0, 29 do
      local x = (K.hash(i, 71) * 128 + T * (2 + K.hash(i, 72) * 4)) % 128
      local y = 4 + (K.hash(i, 73) * 40 - T * (1 + K.hash(i, 74) * 2)) % 40
      local tw = 0.5 + 0.5 * sin(T * (3 + K.hash(i, 75) * 5) + i * 1.7)
      local l = (hi * 2.5 + shim * 4 + spark * 3) * tw
      if l > 0.6 then put(l + 0.4, x, y, 1, 1) end
    end

    -- the chord: soft columns of light rising off the keys
    local rise = 14 + e * 10 - kl * 5
    for i = #cols, 1, -1 do
      local C = cols[i]
      local age = T - C.t0
      local life = 2.2 + kl * 2
      if age > life then table.remove(cols, i)
      else
        local x, w, blk = keyx(C.k)
        local u = age / life
        local top = KY - 2 - age * rise
        local bot = KY - 1 - max(0, age - 0.5) * rise * 0.6
        if c > 0.5 then x = x + (K.hash(i + floor(T * 6), 3) - 0.5) * c * 4 end
        local l = (2 + C.v * 6 + mid * 3) * (1 - u) ^ 1.2
        if bot > top then
          local cw = blk and 1 or 3
          local cx = x + floor((w - cw) / 2)
          put(l * 0.5, cx, top + 2, cw, max(1, bot - top - 2))
          put(l * 0.35, cx - 1, top + 3, 1, max(1, bot - top - 4))
          put(l * 0.35, cx + cw, top + 3, 1, max(1, bot - top - 4))
          put(l, cx, top, cw, 2)
        end
      end
    end
    -- a fill runs up the keys
    local ra = T - run_t
    if ra >= 0 and ra < 1.2 then
      local k = floor(ra * 20)
      if k < 24 then
        local x, w = keyx(k)
        put(8 * (1 - ra / 1.2) + 2, x + 1, KY - 3 - ra * 8, w - 2, 2)
      end
    end

    -- the log drum: a big round glow gliding along the keys to its note
    local th = throb > 0.05 and (0.5 + 0.5 * cos((T - throb_t) * TAU * 8)) * throb or 0
    local kx, kw = keyx(clamp(floor(lp + 0.5), 0, 23))
    local gx = KX0 + (lp * 7 / 12 + 0.5) * WW
    local gy = 30 + bend * 2 - lv * 3
    local pr = 4 + lvs * 6 + lo * 3 + th * 1.5 + kl * 2
    glow(gx, gy, pr, 1.2 + lv * 4 + lo * 2 + th * 2, 2, 7, 1.2 + lvs * 3 + lo * 2 + th)
    if c > 0.45 then glow(gx - 20 * c, gy + 4, pr * 0.45, 1 + c * 2, 0, 13) end
    -- its glide: a thread down to the key
    line(1 + lv * 3, gx, gy + pr, kx + kw / 2, KY - 1)

    -- the keyboard: white keys with their edges, black keys over them,
    -- the held keys lit (the chord, the log drum's note, a fill's run)
    local held = {}
    for _, k in ipairs(cur_chord()) do held[k] = 0.4 + stab * 0.6 + mid * 0.3 + hold * 0.2 end
    local ln = clamp(floor(lp + 0.5), 0, 23)
    held[ln] = max(held[ln] or 0, lv)
    if knock > 0.05 then held[19 + floor(knock_t * 7) % 4] = knock end
    if ra >= 0 and ra < 1.2 then local k = floor(ra * 20); if k < 24 then held[k] = 1 end end
    for n = 0, 23 do keyl[n] = K.follow(keyl[n] or 0, held[n] or 0, (held[n] or 0) > (keyl[n] or 0) and 0.06 or 0.2, DT) end
    held = keyl
    line(2 + amp * 0.8, 0, KY, 127, KY)
    for n = 0, 23 do
      local x, w, blk = keyx(n)
      local h = held[n] or 0
      if not blk then
        line(1.5 + lo * 0.8, x, KY + 1, x, 63)
        if h > 0.05 then
          put(1 + h * 6, x + 1, KY + 9, w - 1, 64 - KY - 9)
          put(1 + h * 3, x + 1, KY + 1, w - 1, 1)
        else
          put(1 + mid * 0.6, x + 1, 62, w - 1, 1)
        end
      end
    end
    for n = 0, 23 do
      local x, w, blk = keyx(n)
      if blk then
        local h = held[n] or 0
        put(1.5 + h * 6, x, KY + 1, w, 7)
        put(2.5 + h * 3 + hi, x + 1, KY + 7, w - 2, 1)
      end
    end
  end

  ---------------------------------------------------------------- draw
  function M.draw(S)
    local DT = K.DT
    lp = K.follow(lp, lp_to, 0.14, DT)
    lvs = K.follow(lvs, lv, 0.12, DT)
    stabs = K.follow(stabs, stab, 0.2, DT)
    lv = lv * exp(-DT / 0.55)
    bend = bend * exp(-DT / 0.4)
    throb = throb * exp(-DT / 0.4)
    stab = stab * exp(-DT / 0.6)
    hold = hold * exp(-DT / 1.2)
    shim = shim * exp(-DT / 0.12)
    spark = spark * exp(-DT / 0.25)
    knock = knock * exp(-DT / 0.3)
    surge = surge * exp(-DT / 1.2)
    arms = arms * exp(-DT / 0.4)
    dip = dip * exp(-DT / 0.18)
    -- at rest the log drum hums on, wandering the chord
    if not K.playing then
      lp_to = cur_root() + (floor(K.T / 3.5) % 2) * 7
      lv = max(lv, 0.25 + 0.1 * sin(K.T * 1.3))
    end
    if K.view == 2 then draw2(S) elseif K.view == 3 then draw3(S) else draw1(S) end
  end

  M.init()
  return M
end
