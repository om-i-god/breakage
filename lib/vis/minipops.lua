-- minipops. view 1: a 70s preset rhythm box on its wood-veneer cabinet, lit by a
-- table lamp: rhythm buttons, voice lamps, a big tempo knob and a breathing grille.
-- view 2: a 70s living room at night: a home organ with the rhythm box on top, a
-- lava lamp whose blobs rise and split on the hits, and a TV test card glowing.
--
-- view 1: one of six rhythm buttons (bossa nova, rhumba, cha-cha, samba,
-- beguine, slow rock) is lit and moves on every eight bars; each voice has a
-- lamp (bass drum, snare, cymbal, clave, guiro, bongo, conga, maracas) that
-- glows and fades with its hits; the kick pushes the speaker behind the
-- grille so its slats bow out; guiro scrapes run a quick ripple along the
-- lamps and the slats; tambourine shakes jingles round the maracas lamp; the
-- tempo pilot blinks the beat and the knob turns slowly with the tempo; a
-- fill chases the buttons and the lamps; a ratchet runs the lamps. energy
-- warms the lamp behind and the halos, chaos multiplies the lamps into
-- flickering ghost rows, flickers the other buttons on and jars the slats,
-- and kickless stretches dim the lamp, let the moon in through the window
-- and leave long trails on the lamps.
-- view 2: the kick heats the lava and lights the organ's pedals and swell
-- grille; snares split a blob; guiro and fills run along the keys, congas
-- and bongos press the lower manual, ratchets run the upper; hats glint the
-- drawbar tabs, tambourine and open hats put snow on the TV. chaos makes
-- the TV roll and ghost, doubles the lamp and the keys and multiplies the
-- blobs; energy heats the lamp; kickless slows the lava and lets the TV and
-- the moon through the blinds light the room.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, sqrt = math.sin, math.cos, math.floor, math.max, math.min, math.abs, math.sqrt
  local PI = math.pi

  ---------------------------------------------------------------- shared
  -- voice lamps: 1 bass drum 2 snare 3 cymbal 4 clave 5 guiro 6 bongo 7 conga 8 maracas
  local NL = 8
  local PERC_LAMP = {7, 6, 4, 4, 3, 3, 6, 4, 5, 8}
  local lamp, ltau                         -- lamp level 0..1, its decay (s)
  local btn, bl, bars                      -- the lit rhythm button, button glow, bar count
  local fillt, rips, sched                 -- fill clock, guiro ripples, scheduled flashes
  local cone, cs                           -- speaker push and its eased form
  local jingle, pilot, ratt                -- tambourine jingle, tick blip, ratchet glow
  -- view 2
  local NK = 17
  local keyU, keyL, tab                    -- key presses, drawbar tab glints
  local blobs, heat, lg                    -- lava blobs, base heat, lamp glow kick
  local pedal, pedal_i, swell              -- bass pedals, swell grille
  local roll, rollv, rburst, snow, tvf     -- TV vertical roll, snow, flicker
  local lgs, sws                           -- lava kick glow and swell, eased

  function M.init()
    lamp, ltau = {}, {}
    for i = 1, NL do lamp[i], ltau[i] = 0, 0.14 end
    ltau[1] = 0.2
    btn, bl, bars = 1, {1, 0, 0, 0, 0, 0}, 0
    fillt, rips, sched = 0, {}, {}
    cone, cs = 0, 0
    jingle, pilot, ratt = 0, 0, 0
    keyU, keyL, tab = {}, {}, {}
    for k = 1, NK do keyU[k], keyL[k] = 0, 0 end
    for k = 1, 12 do tab[k] = 0 end
    blobs = {}
    for k = 1, 4 do
      blobs[k] = {x = 112, y = 22 + k * 5, r = 2.2 + K.hash(k, 3) * 1.5, vy = 0, vx = 0,
        heat = K.hash(k, 4), seed = k * 1.7}
    end
    heat, lg = 0, 0
    pedal, pedal_i, swell = 0, 1, 0
    roll, rollv, rburst, snow, tvf = 0, 0, 0, 0, 0
    lgs, sws = 0, 0
  end
  M.clear = M.init

  local function flash(i, v)
    if i >= 1 and i <= NL then lamp[i] = max(lamp[i], clamp(v, 0, 1)) end
  end

  local function press(keys, k, v)
    k = (floor(k) - 1) % NK + 1
    keys[k] = max(keys[k], v)
  end

  -- split the biggest blob in two
  local function split(v)
    local bi, br = nil, 0
    for i, b in ipairs(blobs) do if b.r > br then bi, br = i, b.r end end
    if not bi or br < 1.8 or #blobs >= 11 then
      if bi then blobs[bi].vy = blobs[bi].vy - 6 * v end
      return
    end
    local b = blobs[bi]
    local r = b.r * 0.72
    b.r, b.vx = r, -6 * v
    blobs[#blobs + 1] = {x = b.x + 1, y = b.y - 1, r = r, vy = b.vy - 4 * v, vx = 6 * v,
      heat = b.heat, seed = K.rnd() * 9}
  end

  local function ripple(v, dir)
    if #rips >= 4 then table.remove(rips, 1) end
    rips[#rips + 1] = {t0 = K.T, v = v, dir = dir or 1}
  end

  function M.kick(v)
    v = K.num(v, 1)
    flash(1, 0.4 + 0.6 * v)
    cone = 1
    heat = min(1.5, heat + 0.5 * v)
    lg = max(lg, v)
    pedal = 1
    pedal_i = pedal_i % 9 + 1
    swell = 1
    for _, b in ipairs(blobs) do
      if b.y > 34 then b.vy = b.vy - 5 * v * b.heat end
    end
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    flash(2, 0.4 + 0.6 * v)
    split(v)
    tvf = max(tvf, 0.5 * v)
    local k0 = 3 + floor(K.hash(bars, 9) * 10)
    press(keyU, k0, 0.8 * v); press(keyU, k0 + 2, 0.7 * v); press(keyU, k0 + 4, 0.7 * v)
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.85) end
  function M.rim(v) v = K.num(v, 1); flash(4, 0.6 * v + 0.3); press(keyU, 12 + floor(K.rnd() * 5), 0.6 * v) end

  function M.hat(v, open)
    v = K.num(v, 1)
    flash(3, (open and 0.5 or 0.3) + 0.6 * v)
    if open then ltau[3] = 0.32; snow = max(snow, 0.6 * v) else ltau[3] = 0.1 end
    local k = 1 + floor(K.rnd() * 12)
    tab[k] = max(tab[k], 0.5 + 0.5 * v)
  end
  function M.ride(v) M.hat(K.num(v, 1) * 0.8, true) end
  function M.shaker(v) v = K.num(v, 1); flash(8, 0.3 + 0.6 * v); tab[12] = max(tab[12], v) end

  function M.perc(kind, v)
    kind = clamp(floor(K.num(kind, 1)), 1, 10)
    v = K.num(v, 1)
    flash(PERC_LAMP[kind], 0.35 + 0.65 * v)
    if kind == 9 then
      ripple(v, 1)
      for k = 1, NK, 3 do press(keyU, k, 0.25 * v) end
    elseif kind == 10 then
      jingle = max(jingle, v)
      flash(3, 0.3 * v)
      snow = max(snow, 0.8 * v)
    elseif kind == 1 or kind == 2 or kind == 7 then
      local k = kind == 1 and 4 or (kind == 2 and 9 or 6)
      press(keyL, k + floor(K.rnd() * 3), 0.6 + 0.4 * v)
    else
      press(keyU, 10 + kind, 0.5 * v)
      tab[kind] = max(tab[kind], 0.7 * v)
    end
  end
  function M.tom(v) M.perc(1, v) end

  function M.tick(kind)
    pilot = max(pilot, 0.6)
    flash((floor(K.num(kind, 1)) * 3) % NL + 1, 0.25)
    tvf = max(tvf, 0.25)
  end

  function M.brk(s, n, rev)
    s, n = K.num(s, 1), max(1, K.num(n, 8))
    local i = floor((s - 1) / n * NL) + 1
    if rev then i = NL + 1 - i end
    flash(i, 0.55)
    press(keyU, floor((s - 0.5) / n * NK) + 1, 0.6)
  end

  local VOICE = {snare = 2, hat = 3, kick = 1, tick = 4, brk = 6, ride = 3, clap = 2, perc = 7}
  function M.ratchet(n, voice)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    local i0 = VOICE[voice or ""] or 2
    for k = 0, n - 1 do
      if #sched < 24 then sched[#sched + 1] = {at = K.NOW + k * 0.045, i = (i0 + k - 1) % NL + 1, k = i0 + k * 2} end
    end
    ratt = 1
    ripple(0.8, -1)
  end

  function M.fill()
    fillt = 1
    rburst = 1
    for _, b in ipairs(blobs) do b.vy = b.vy - 3 end
  end

  function M.bar(S)
    bars = bars + 1
    local p = type(S) == "table" and (K.num(S.preset, nil) or K.num(S.rhythm, nil) or K.num(S.pattern, nil))
    -- the preset groove that's playing lights its own button
    if not p and type(S) == "table" and type(S.pat) == "table" then
      p = ({bossa = 1, rhumba = 2, chacha = 3, samba = 4, beguine = 5, rock = 6})[S.pat.family]
    end
    if p then
      btn = (floor(p) - 1) % 6 + 1
    else
      local every = K.chaos > 0.5 and 2 or 8
      if bars % every == 1 then btn = 1 + floor(K.hash(bars // every, 17) * 6) end
    end
  end

  -- once per frame, whatever the view
  local function tick_state()
    local DT, NOW, c, kl = K.DT, K.NOW, K.chaos, K.kickless
    for i = #sched, 1, -1 do
      local s = sched[i]
      if NOW >= s.at then
        flash(s.i, 0.85)
        press(keyU, s.k, 0.9)
        table.remove(sched, i)
      end
    end
    for i = 1, NL do lamp[i] = lamp[i] * math.exp(-DT / (ltau[i] * (1 + kl * 1.6))) end
    for i = 1, 6 do
      local to = (i == btn) and 1 or 0
      if i ~= btn and c > 0.15 then
        local f = sin(K.T * (1.3 + K.hash(i, 5) * 2.5) + i * 1.7)
        to = c * 0.8 * max(0, f) ^ 2
      end
      if fillt > 0.02 then
        local ph = (1 - fillt) * 14
        if floor(ph) % 6 + 1 == i then to = max(to, 0.9) end
      end
      bl[i] = K.follow(bl[i], to, 0.07, DT)
    end
    if fillt > 0.02 then
      local ph = (1 - fillt) * 18
      local i = floor(ph) % NL + 1
      flash(i, 0.6 * fillt + 0.2)
      press(keyU, floor((1 - fillt) * 40) % NK + 1, 0.8)
    end
    fillt = max(0, fillt - DT / 0.8)
    for i = #rips, 1, -1 do if K.T - rips[i].t0 > 0.35 then table.remove(rips, i) end end
    cs = K.follow(cs, cone, 0.035, DT)
    cone = cone * math.exp(-DT / 0.1)
    jingle = jingle * math.exp(-DT / 0.25)
    pilot = pilot * math.exp(-DT / 0.08)
    ratt = ratt * math.exp(-DT / 0.25)
    for k = 1, NK do
      keyU[k] = keyU[k] * math.exp(-DT / 0.16)
      keyL[k] = keyL[k] * math.exp(-DT / 0.2)
    end
    for k = 1, 12 do tab[k] = tab[k] * math.exp(-DT / 0.15) end
    heat = heat * math.exp(-DT / 0.8)
    lg = lg * math.exp(-DT / 0.3)
    lgs = K.follow(lgs, lg, 0.08, DT)
    sws = K.follow(sws, swell, 0.05, DT)
    pedal = pedal * math.exp(-DT / 0.18)
    swell = swell * math.exp(-DT / 0.15)
    snow = snow * math.exp(-DT / 0.2)
    tvf = tvf * math.exp(-DT / 0.15)
    rburst = rburst * math.exp(-DT / 0.5)
  end

  -- the front of every running guiro ripple near x (span x0..x1)
  local function rip_at(x, x0, x1)
    local s = 0
    for _, r in ipairs(rips) do
      local u = (K.T - r.t0) / 0.3
      local rx = r.dir > 0 and (x0 + u * (x1 - x0)) or (x1 - u * (x1 - x0))
      local d = abs(x - rx)
      if d < 6 then s = max(s, r.v * (1 - d / 6)) end
    end
    return s
  end

  ---------------------------------------------------------------- view 1
  local LCX = 30                           -- the table lamp behind, x
  local BX0, BX1, BY0, BY1 = 6, 121, 14, 56  -- the cabinet
  local PX0, PX1, PY0, PY1 = 15, 112, 17, 51 -- its panel
  local KX, KY = 103, 29                   -- tempo knob
  local GX, GY = 56, 43                    -- the speaker behind the grille
  local LY = 31                            -- lamp row
  local function lamp_x(i) return 19 + (i - 1) * 10 end
  local function btn_x(i) return 18 + (i - 1) * 13 end

  local function wood_rows(y0, y1, x0, x1, l)
    for y = y0, y1 do
      local w = 4 + floor(K.hash(y, 41) * 6)
      local gap = w + 5 + floor(K.hash(y, 42) * 6)
      K.dashes(l + (K.hash(y, 43) > 0.6 and 1 or 0), y, w, gap, floor(K.hash(y, 44) * 20), x0, x1)
    end
  end

  local function cheek(x0, l)
    line(l + 1, x0, BY0, x0, BY1)
    line(l + 0.5, x0 + 7, BY0, x0 + 7, BY1)
    for j = 0, 1 do
      local x = x0 + 2 + j * 3
      local px, py = x, BY0
      for s = 1, 4 do
        local ny = BY0 + s * (BY1 - BY0) / 4
        local nx = x + floor((K.hash(j * 7 + s + x0, 45) - 0.5) * 2.2 + 0.5)
        line(l * (0.7 + 0.5 * K.hash(j + x0, 46)), px, py, nx, ny)
        px, py = nx, ny
      end
    end
  end

  local function draw1(S)
    local T, e, c, kl = K.T, K.energy, K.chaos, K.kickless
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    local playing = K.playing
    local lampg = (0.55 + 0.4 * e + 0.2 * lo + 0.03 * sin(T * 7.3) + 0.02 * sin(T * 11.9)) * (1 - 0.7 * kl)

    -- the wall: dim 70s stripes, the lamp's glow pooling round its shade,
    -- a night window that the moon finds when the kick goes away
    for x = 2, 127, 8 do
      if abs(x - LCX) > 16 and (x < 60 or x > 94) then
        for y = 1 + (x // 8) % 2 * 3, 12, 6 do put(1, x, y, 1, 2) end
      end
    end
    local hw = 14 + e * 3 + lo * 2
    for y = 0, 13 do
      local u = (y - 6) / 9
      local w = hw * sqrt(max(0, 1 - u * u))
      local v = lampg * (0.95 - abs(y - 6) / 10)
      K.gradient(y, y, function() return v end, nil, floor(LCX - w), floor(LCX + w))
    end
    -- window
    local wv = 0.2 + kl * 1.0 + hi * 0.2
    line(2, 62, 0, 62, 12); line(2, 92, 0, 92, 12); line(2, 77, 0, 77, 12); line(1.5, 62, 6, 92, 6)
    K.gradient(0, 12, function(y) return wv * (0.8 + 0.3 * sin(y * 0.7 + T * 0.4)) end, nil, 63, 77)
    K.gradient(0, 12, function(y) return wv * (0.7 + 0.3 * sin(y * 0.5 - T * 0.3)) end, nil, 78, 92)
    if kl > 0.2 then K.disc(1 + kl * 4, 86, 3.5, 2.5) end
    -- the lamp shade (its foot hidden behind the cabinet)
    for y = 1, 12 do
      local w = 7 + (y - 1) * 0.35
      local l = 2.5 + lampg * 5.5 * (0.6 + y / 24)
      put(l, LCX - w, y, w * 2, 1)
    end
    line(3 + lampg * 7, LCX - 11, 12, LCX + 11, 12)
    put(2 + lampg * 3, LCX - 1, 0, 2, 1)

    -- the cabinet: top edge lit by the lamp, veneer rails and cheeks
    line(2.5 + lampg * 4, BX0, BY0 - 1, 60, BY0 - 1)
    line(2 + lampg * 2, 61, BY0 - 1, BX1, BY0 - 1)
    wood_rows(BY0, BY0 + 1, BX0 + 8, BX1 - 7, 1.4 + lampg * 0.6)
    wood_rows(PY1 + 3, BY1, BX0 + 8, BX1 - 7, 1.2 + lampg * 0.4)
    cheek(BX0, 1.5 + lampg * 0.8)
    cheek(BX1 - 7, 1.3 + lampg * 0.5)

    -- the panel frame
    line(3 + lampg, PX0, PY0, PX1, PY0)
    line(1.5, PX0, PY0, PX0, PY1); line(1.5, PX1, PY0, PX1, PY1)
    line(1.5, PX0, PY1, PX1, PY1)

    -- rhythm buttons
    for i = 1, 6 do
      local x, b = btn_x(i), bl[i]
      local dy = b > 0.5 and 1 or 0
      put(1.2 + b * 6 + (i == btn and e * 1.5 or 0), x, 20 + dy, 10, 5)
      line(3 + b * 7 + hi * 1.5, x, 19 + dy, x + 9, 19 + dy)
      if b > 0.3 then put(b * 2.5, x - 1, 26, 12, 1) end
      put(1.5, x + 3, 28, 4, 1)                   -- its label
    end

    -- voice lamps (with chaos they multiply into flickering ghost rows)
    local ng = floor(c * 3.2)
    for i = 1, NL do
      local x, v = lamp_x(i), lamp[i]
      local rp = rip_at(x + 2, 18, 93)
      local vv = min(1, v + rp * 0.8 + (i == 3 and hi * 0.15 or 0) + (i == 1 and lo * 0.12 or 0))
      local split = c > 0.25 and floor(c * 2.5 * sin(T * 3.1 + i * 2.3) + 0.5) or 0
      local y = LY - floor(rp * 1.5 + 0.5)
      if vv > 0.2 then
        put(vv * (3.5 + e * 1.5), x - 1, y - 1, 6, 5)
        put(vv * 2.5, x, LY + 4, 4, 1)
      end
      local l = 1.5 + vv * 11.5
      if split ~= 0 then
        put(l, x + split, y, 2, 3); put(l, x + 2 - split, y, 2, 3)
      else
        put(l, x, y, 4, 3)
      end
      for g = 1, ng do
        local fl = 0.5 + 0.5 * sin(T * (4 + 3 * K.hash(i * 5 + g, 6)) + i * 1.3 + g)
        local gx = x + (K.hash(i * 3 + g, 7) - 0.5) * c * 22 + sin(T * (1.1 + g * 0.4) + i) * c * 3
        local gy = LY + ((g % 2 == 1) and -1 or 1) * (2 + g * 3) * c + 1
        put((1 + vv * 6) * fl * c, gx, gy, 4, 2)
      end
    end
    -- tambourine jingles round the maracas lamp
    if jingle > 0.05 then
      local x = lamp_x(8)
      for k = 0, 5 do
        local a = k * PI / 3 + T * 6
        put(jingle * (4 + 4 * (0.5 + 0.5 * sin(T * 13 + k))), x + 1.5 + cos(a) * 5, LY + 1 + sin(a) * 3, 1, 1)
      end
    end

    -- the tempo knob: a slow hand on it, the tempo pilot blinking the beat
    local bpm = K.num(S.bpm, 120) or 120
    local u = clamp((bpm - 50) / 150, 0, 1) + 0.07 * sin(T * 0.13) + 0.03 * sin(T * 0.37)
      + c * 0.12 * sin(T * 2.9)
    local ang = PI * 0.75 + u * PI * 1.5
    for k = 0, 10 do
      local a = PI * 0.75 + k / 10 * PI * 1.5
      put(1.5 + (abs(a - ang) < 0.3 and 3 or 0), KX + cos(a) * 10, KY + sin(a) * 10, 1, 1)
    end
    K.disc(2 + lampg * 0.8, KX, KY, 7)
    K.ring(3 + lampg * 3, KX, KY, 7, 12, PI * 1.05, PI * 1.7)
    K.ring(1.5, KX, KY, 7, 10, PI * 0.1, PI * 0.9)
    line(9 + e * 2, KX + cos(ang) * 1.5, KY + sin(ang) * 1.5, KX + cos(ang) * 6, KY + sin(ang) * 6)
    local bp = playing and (1 - K.beat_ph) ^ 6 or 0
    local pl = 2 + bp * 9 + pilot * 4
    put(pl, KX - 6, 42, 3, 2)
    if pl > 6 then put((pl - 6) * 0.5, KX - 7, 41, 5, 4) end
    K.ring(2, KX + 5, 46, 3, 8)
    line(4, KX + 5, 46, KX + 5 + cos(T * 0.2) * 2, 44)

    -- the grille: slats bowing out with the speaker behind
    line(2, 17, 37, 17, 49); line(2, 95, 37, 95, 49)
    local kb = cs * (1 - kl * 0.8)
    for sy = 38, 48, 2 do
      local jx = c > 0.2 and floor(c * 3 * sin(T * 4.3 + sy * 1.9) + 0.5) or 0
      local side = sy < GY and -1 or 1
      for sx = 18, 90, 6 do
        local cx = sx + 3
        local dx, dy = cx - GX, (sy - GY) * 2.2
        local d = sqrt(dx * dx + dy * dy)
        local rim = math.exp(-((d - 17) / 4) ^ 2)
        local core = max(0, 1 - d / 11)
        local fall = max(0, 1 - d / 30)
        local rp = rip_at(cx, 18, 93)
        local l = 1 + 0.5 * e + lo * 1.4 * fall + rim * (0.8 + kb * 3) + core * (kb * 5 + lo * 1.2 + mid * 0.6)
          + rp * 4 + ratt * fall * 2
        local off = floor(side * kb * 1.8 * fall + 0.5) - floor(rp * 1.2 + 0.5)
          + floor(0.4 * sin(T * 1.3 + sx * 0.05) * fall + 0.5)
        put(l, sx + jx, sy + off, 6, 1)
      end
    end

    -- the table, the lamps reflected in its varnish, a cable curling off
    line(2 + lampg * 2, 0, 57, 127, 57)
    for i = 1, NL do
      if lamp[i] > 0.15 then put(lamp[i] * 3.5, lamp_x(i), 59, 4, 1) end
    end
    K.dashes(1, 61, 4, 15, 9, 0, 128)
    K.gradient(58, 61, function(y) return lampg * (1.2 - (y - 58) / 4) end, nil, LCX - 12, LCX + 12)
    local px, py
    for k = 0, 8 do
      local x = 96 + k * 4
      local y = 60 + 2 * sin(k * 0.9 + 0.5) + (k > 5 and (k - 5) or 0)
      if px then line(2 + lampg, px, py, x, y) end
      px, py = x, y
    end

    -- dust in the lamplight, hiss off the grille
    K.grain(function(uu, vv)
      if uu < 0.45 then return LCX - 16 + uu / 0.45 * 32, vv * 13 end
      return 18 + (uu - 0.45) / 0.55 * 76, 38 + floor(vv * 6) * 2
    end, 16 + hi * 14 + K.env.ohat * 20 + e * 4, 3 + hi * 4)
  end

  ---------------------------------------------------------------- view 2
  local LX = 112                           -- the lava lamp
  local GT, GB = 16, 43                    -- its glass, top / bottom
  local SX, SY, SW, SH = 8, 21, 22, 17     -- the TV screen
  local WALLP = {}
  for j = 0, 4 do
    for i = 0, 10 do
      local x, y = 6 + i * 12 + (j % 2) * 6, 5 + j * 10
      local inwin = x > 40 and x < 100 and y < 24
      local intv = x < 42 and y > 14
      local inlava = x > 98 and y > 6
      local inorg = x > 38 and x < 102 and y > 20
      if not (inwin or intv or inlava or inorg) then WALLP[#WALLP + 1] = {x, y} end
    end
  end
  local function ghw(y)
    local u = (y - GT) / (GB - GT)
    return 2.5 + 5 * sin(PI * clamp(u, 0, 1) * 0.85)
  end
  -- the armchair's outline, back to us: arm, back, arm
  local CHAIR = {{0, 52}, {2, 50}, {6, 50}, {7, 52}, {7, 46}, {9, 44}, {23, 44}, {25, 46},
    {25, 52}, {26, 50}, {30, 50}, {32, 52}, {32, 63}}

  -- a rect on the TV screen, rolled (wrapping)
  local function tvrect(l, x, y, w, h)
    local yy = (y - SY + roll) % SH
    local h1 = min(h, SH - yy)
    put(l, x, SY + yy, w, h1)
    if h > h1 then put(l, x, SY, w, h - h1) end
  end

  local function lava(dt, e, c, kl)
    local spd = (5 + e * 7 + heat * 6) * (1 - kl * 0.55)
    local target = 3 + floor(e * 2.5 + c * 4)
    for _, b in ipairs(blobs) do
      local warm = b.y > GB - 6 and (0.35 + heat * 0.6) or (b.y < GT + 6 and -0.25 or -0.04)
      b.heat = clamp(b.heat + warm * dt, 0, 1)
      b.vy = K.follow(b.vy, -(b.heat - 0.45) * spd, 0.6, dt)
      b.y = b.y + b.vy * dt
      local lo_y, hi_y = GT + b.r + 1, GB - b.r * 0.6
      if b.y < lo_y then b.y, b.vy = lo_y, abs(b.vy) * 0.3 end
      if b.y > hi_y then b.y, b.vy = hi_y, -abs(b.vy) * 0.3 end
      b.vx = b.vx * math.exp(-dt / 0.5)
      local room = max(0, ghw(b.y) - b.r - 0.8)
      b.x = clamp(b.x + b.vx * dt + (LX + sin(K.T * 0.31 + b.seed) * room * 0.7 - b.x) * min(1, dt * 1.5),
        LX - room, LX + room)
    end
    -- merge the closest overlapping pair when there are too many
    if #blobs > target then
      local bi, bj, bd
      for i = 1, #blobs do
        for j = i + 1, #blobs do
          local a, b = blobs[i], blobs[j]
          local d = sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) - a.r - b.r
          if not bd or d < bd then bi, bj, bd = i, j, d end
        end
      end
      if bd and (bd < 0.5 or #blobs > target + 3) then
        local a, b = blobs[bi], blobs[bj]
        a.r = min(4.6, sqrt(a.r * a.r + b.r * b.r))
        a.y = (a.y + b.y) / 2
        table.remove(blobs, bj)
      end
    elseif #blobs < target and K.rnd() < dt * 0.8 then
      blobs[#blobs + 1] = {x = LX, y = GB - 2, r = 1.6, vy = -2, vx = 0, heat = 0.8, seed = K.rnd() * 9}
    end
  end

  local function blob_disc(l, bx, by, r)
    for dy = -floor(r), floor(r) do
      local y = by + dy
      if y >= GT and y <= GB then
        local h = sqrt(max(0, r * r - dy * dy))
        local g = ghw(y) - 0.6
        local x0, x1 = max(bx - h, LX - g), min(bx + h, LX + g)
        if x1 - x0 >= 0.6 then put(l, x0, y, max(1, x1 - x0), 1) end
      end
    end
  end

  local function draw2(S)
    local T, DT, DTS, e, c, kl = K.T, K.DT, K.DTS, K.energy, K.chaos, K.kickless
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    lava(DTS, e, c, kl)
    local glow = (0.5 + 0.35 * e + lgs * 0.4 + heat * 0.2 + lo * 0.25) * (1 - 0.45 * kl)
    local tvg = 0.55 + 0.25 * e + kl * 0.45 + tvf * 0.4
    local moon = 0.6 + kl * 0.9

    -- the wallpaper: dim 70s circles
    for i, p in ipairs(WALLP) do
      local near = max(0, 1 - abs(p[1] - LX) / 30) * glow + max(0, 1 - abs(p[1] - 20) / 26) * tvg * 0.5
      K.ring(1 + near * 1.2, p[1], p[2], 3.5, 8)
    end
    -- the window behind the organ, the moon through vertical blinds
    -- (swaying a little in a draught)
    line(2, 44, 1, 96, 1); line(1.5, 44, 1, 44, 21); line(1.5, 96, 1, 96, 21)
    for k = 0, 16 do
      local x = 46 + k * 3
      local d = abs(x - 80) / 22
      local sway = floor(0.6 * sin(T * 0.5 + k * 0.4) + 0.5)
      local l = 1 + moon * 2.4 * max(0, 1 - d) + hi * 0.5 * max(0, 1 - d)
      put(l, x + sway, 3, 1, 18)
    end

    -- the lava lamp's glow on the wall
    K.ring(1 + glow * 1.6, LX, 30, 11 + glow * 2, 18, 0, K.TAU, 1.9)
    K.ring(0.7 + glow * 0.9, LX, 30, 15 + glow * 2, 20, 0, K.TAU, 1.6)

    -- the TV: wood cabinet, the test card, rolling under chaos
    line(2.5, 4, 18, 38, 18); line(2, 4, 18, 4, 47); line(2, 38, 18, 38, 47); line(2, 4, 47, 38, 47)
    line(1.5, 7, 47, 5, 52); line(1.5, 35, 47, 37, 52)
    put(2.5 + tvg, 34, 23, 2, 2); put(2 + tvg, 34, 28, 2, 2)
    for y = 33, 44, 2 do line(1.5, 32, y, 36, y) end
    rollv = c * 14 + rburst * 40
    if rollv > 0.5 then
      roll = (roll + rollv * DTS) % SH
    else
      local to = roll > SH / 2 and SH or 0
      roll = K.follow(roll, to, 0.25, DTS)
      if abs(roll - to) < 0.05 then roll = 0 end
    end
    local BAR = {6, 5, 5, 4, 3, 3, 2}
    for b = 1, 7 do
      local l = BAR[b] * tvg * 0.62
      tvrect(l, SX + (b - 1) * 3 + 1, SY, 3, 11)
      if c > 0.3 then tvrect(l * 0.4 * c, SX + (b - 1) * 3 + 3, SY + 1, 3, 9) end
      tvrect((8 - BAR[b]) * tvg * 0.4, SX + (b - 1) * 3 + 1, SY + 12, 3, 4)
    end
    -- the circle and the cross
    local ccx, ccy = SX + 11, SY + 8
    local pxx, pyy
    for k = 0, 12 do
      local a = k / 12 * K.TAU
      local x, y = ccx + cos(a) * 6.5, SY + ((ccy + sin(a) * 6 - SY + roll) % SH)
      if pxx and abs(y - pyy) < 5 then line(6 * tvg, pxx, pyy, x, y) end
      pxx, pyy = x, y
    end
    tvrect(7 * tvg, ccx - 1, ccy - 1, 3, 3)
    -- snow and glints
    local nsn = floor(snow * 10 + hi * 4)
    local fr = floor(T * 20)
    for k = 1, nsn do
      put(4 + snow * 6, SX + floor(K.hash(fr * 13 + k, 51) * SW), SY + floor(K.hash(fr * 17 + k, 52) * SH), 1, 1)
    end
    -- the screen's glow on the wall above and the floor in front
    line(1 + tvg * 2, 6, 17, 36, 17)

    -- the organ
    local OX0, OX1 = 42, 98
    line(3 + glow * 0.5, OX0, 30, OX1, 30)
    line(2, OX0, 30, OX0, 58); line(2, OX1, 30, OX1, 58)
    -- the rhythm box on the lid
    line(2.5, 60, 24, 84, 24); line(2, 60, 24, 60, 29); line(2, 84, 24, 84, 29)
    put(1.2, 61, 25, 23, 5)
    for i = 1, 6 do put(2 + bl[i] * 8, 62 + (i - 1) * 3, 25, 2, 1) end
    for i = 1, NL do
      local v = lamp[i]
      local gx = c > 0.3 and floor(sin(T * 3 + i * 2) * c * 2 + 0.5) or 0
      if v > 0.25 then put(v * 4, 61 + (i - 1) * 2 + gx, 26, 3, 3) end
      put(1.5 + v * 11, 62 + (i - 1) * 2 + gx, 27, 1, 1)
    end
    local pb = K.playing and (1 - K.beat_ph) ^ 6 or 0
    put(2 + pb * 8, 80, 27, 2, 1)
    -- drawbar tabs
    for k = 1, 12 do
      put(1.2 + K.hash(k, 61) * 1.5 + tab[k] * 8 + hi * 1.5, 45 + (k - 1) * 4.4, 32, 2, 2)
    end
    -- the manuals: upper then lower, keys pressed down and lit
    local function manual(keys, y, ox, base)
      for k = 1, NK do
        local x = 45 + (k - 1) * 3 + ox
        local rp = rip_at(x, 45, 96)
        local p = min(1, keys[k] + rp)
        put(base + p * 6.5, x, y + (p > 0.4 and 1 or 0), 2, p > 0.4 and 2 or 3)
        if c > 0.35 then
          local gy = y - 2 - floor(c * 3 * (0.5 + 0.5 * sin(T * 2.3 + k)))
          if p > 0.2 or k % 3 == 0 then put((1 + p * 3) * c, x + floor(sin(T * 1.7 + k * 0.7) * c * 2), gy, 2, 1) end
        end
      end
      line(1.2, OX0 + 1, y + 3, OX1 - 1, y + 3)
    end
    manual(keyU, 35, 0, 1.8 + glow * 0.3)
    manual(keyL, 39, 1, 1.6 + glow * 0.3)
    -- the body: grain, the swell grille breathing with the kick
    line(1.5, 50, 47, 50, 56); line(1.5, 91, 47, 91, 56)
    local sw = sws * (1 - kl * 0.7)
    put(1 + sw * 2.5 + lo * 1.2 + mid * 0.4, 58, 47, 26, 9)
    for x = 60, 82, 4 do line(0.8 + sw * 2 + lo, x, 48, x, 54) end
    -- bass pedals
    for i = 1, 9 do
      local l = 1.5 + lo * 1.2 + (i == pedal_i and pedal * 8 or 0)
      put(l, 47 + (i - 1) * 5.5, 59 + ((i == pedal_i and pedal > 0.4) and 1 or 0), 4, 2)
    end

    -- the lava lamp on its side table
    line(2.5, 100, 54, 124, 54); line(1.5, 102, 54, 102, 63); line(1.5, 122, 54, 122, 63)
    for y = 44, 53 do
      local w = 3.5 + (y - 44) * 0.38
      put(1.5 + glow * 1.2 + (y < 46 and heat * 2 or 0), LX - w, y, w * 2, 1)
    end
    put(2.5, LX - 2, 12, 4, 4)
    local cj = c > 0.3 and floor(c * 3 * sin(T * 1.7) + 0.5) or 0
    for y = GT, GB - 1, 4 do
      local y1 = min(GB, y + 4)
      local a, b = ghw(y), ghw(y1)
      line(2 + glow * 0.8, LX - a - 1, y, LX - b - 1, y1)
      line(2 + glow * 0.8, LX + a, y, LX + b, y1)
      if cj ~= 0 then
        line(1.2 * c, LX - a - 1 + cj, y, LX - b - 1 + cj, y1)
        line(1.2 * c, LX + a + cj, y, LX + b + cj, y1)
      end
    end
    for y = GT + 1, GB do
      local g = ghw(y) - 0.5
      put(1 + (y > GB - 10 and glow * 1.2 or 0), LX - g, y, g * 2, 1)
    end
    -- the pool at the bottom and the blobs
    blob_disc(3.5 + heat * 3 + glow * 1.5, LX, GB + 1, 4.5)
    for i, b in ipairs(blobs) do
      local l = min(9, 3 + b.heat * 3.5 + glow * 1.5 + e * 0.8)
      blob_disc(l, b.x, b.y, b.r)
      if c > 0.3 then blob_disc(l * 0.4 * c, b.x + sin(T * 2.1 + i) * c * 4, b.y + cos(T * 1.6 + i) * c * 3, b.r * 0.8) end
    end

    -- the floor: shag rug, the TV's and the lamp's light on it,
    -- an armchair in the foreground against the TV glow
    K.dashes(1, 62, 3, 7, 5, 34, 100)
    line(tvg * 1.8, 34, 53, 48, 53); line(tvg * 1.2, 34, 56, 44, 56)
    line(1 + glow * 3, LX - 9, 55, LX + 9, 55)
    local ppx, ppy
    for _, p in ipairs(CHAIR) do
      if ppx then line(2 + tvg * 2.2, ppx, ppy, p[1], p[2]) end
      ppx, ppy = p[1], p[2]
    end
    K.grain(function(uu, vv)
      if uu < 0.5 then return LX - 4 + uu * 16, GT + vv * (GB - GT) end
      return SX + (uu - 0.5) * 2 * SW, SY + vv * SH
    end, 4 + hi * 10 + snow * 20, 3 + hi * 3)
  end

  function M.draw(S)
    tick_state()
    if K.view == 2 then draw2(S) else draw1(S) end
  end

  M.init()
  return M
end
