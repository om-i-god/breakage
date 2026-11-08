-- acid. view 1: a glowing phosphor scope in a dark bezel, the trace a
-- resonant filtered saw that squelches; view 2: the bass box seen from
-- above, knobs turning, the step lamps running and the played key lit,
-- slides drawn as glides between keys.
--
-- view 1: a graticule in a rounded bezel; the trace is a saw through a
-- two-pole resonant lowpass, drawn with a bloom round it, its body glowing
-- faintly down to the centre line, and the last few sweeps fading behind
-- as phosphor ghosts. the beam sweeps once a beat and is brightest just
-- behind its head. energy opens the cutoff, the acid perc kicks the
-- resonance up so the edges ring and the wave squelches, the kick throws
-- the trace down and lets it spring back, the snare jolts it with noise,
-- hats fizz the bloom, a break slice nudges the trigger and marks the
-- bezel. chaos loses the trigger: the sweeps roll and the ghosts spread
-- into copies. kickless the beam slows and the ghosts hang on. four knobs
-- under the screen turn with the filter.
--
-- view 2: close over the box, which runs off the top and bottom of the
-- screen. a sixteen-step pattern plays; each step lights its lamp and its
-- key; a slide draws a glide arc between the two keys and the light
-- travels along it. the acid perc slams the accent knob, swings the cutoff
-- and resonance knobs and flares the key; the kick brightens the box's
-- sides and the lamp row, the snare lights the keyboard's outline, hats
-- tick a lamp. energy turns the knobs up; chaos rewrites the pattern bar
-- by bar and scatters ghost keys; kickless every step glides and the keys
-- fade slowly.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  ------------------------------------------------------------------
  -- shared filter state
  ------------------------------------------------------------------
  local fc, q = 2, 1                 -- cutoff (in harmonics), resonance
  local kd, kdv = 0, 0               -- kick deflection spring (px, px/s)
  local snz = 0                      -- snare noise
  local acidv = 0                    -- the acid perc's squelch, eased

  ------------------------------------------------------------------
  -- view 1: the scope
  ------------------------------------------------------------------
  local X0, X1, Y0, Y1 = 6, 121, 4, 48       -- the screen
  local MY = 26
  local N = 44                               -- trace segments
  local NH = 14                              -- harmonics
  local ghosts, echoes
  local ghost_t = 0
  local ph, ph_to = 0, 0                      -- trigger phase (slips with chaos)
  local slice_x, slice_v = 0, 0              -- the last break slice's marker
  local sweep_t0 = 0
  local ys = {}
  local ca, cb = {}, {}                      -- per-harmonic filter coefficients

  ------------------------------------------------------------------
  -- view 2: the box
  ------------------------------------------------------------------
  local KN_Y = 14
  local KN_X = {13, 33, 53, 73, 93, 113}
  local LED_Y = 28
  local KY0, KY1, KYB = 35, 64, 47           -- keys: top, (off the bottom), black keys' bottom
  local WK = 14                              -- white key width
  local KX0 = 8
  -- semitone -> {white index or nil, black (true)}; 13 keys, C to C
  local KEYS = {}
  do
    local wmap = {0, 2, 4, 5, 7, 9, 11, 12}
    local w = 0
    for s = 0, 12 do
      local isw = false
      for i, v in ipairs(wmap) do if v == s then isw = true; w = i - 1 end end
      if isw then KEYS[s] = {x = KX0 + w * WK, w = WK, black = false}
      else KEYS[s] = {x = KX0 + (w + 1) * WK - 4, w = 8, black = true} end
    end
  end
  local SCALE = {0, 3, 5, 7, 10, 12, 3, 7, 0, 5, 10, 2, 8}
  local salt = 0
  local keylit, keytgt = {}, {}
  local ghostkey = {}
  local accent, thump, kbglow, lampv = 0, 0, 0, 0
  local last_step = -1
  local glide = nil                           -- {from, to, t0, dur}
  local hatled = 0

  function M.init()
    fc, q, kd, kdv, snz, acidv = 2, 1, 0, 0, 0, 0
    ghosts, echoes = {}, {}
    ghost_t, ph, ph_to, sweep_t0 = 0, 0, 0, 0
    slice_x, slice_v = 0, 0
    for i = 0, N do ys[i] = MY end
    salt = 0
    for s = 0, 12 do keylit[s], keytgt[s], ghostkey[s] = 0, 0, 0 end
    accent, thump, kbglow, lampv = 0, 0, 0, 0
    last_step, glide, hatled = -1, nil, 0
  end
  M.clear = M.init

  ------------------------------------------------------------------
  -- the hits
  ------------------------------------------------------------------
  function M.kick(v)
    v = K.num(v, 1)
    kdv = kdv + 70 * v
    sweep_t0 = K.T
    thump = 1
  end

  function M.snare(v)
    v = K.num(v, 1)
    snz = math.max(snz, 0.6 + 0.4 * v)
    kbglow = 1
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8) end
  function M.rim(v) snz = math.max(snz, 0.3 * K.num(v, 1)); hatled = 1 end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 5 then
      acidv = math.min(1.3, acidv + 0.8 * v)
      accent = 1
      local s = last_step >= 0 and last_step or 0
      keytgt[s] = 1
    else
      acidv = math.min(1.3, acidv + 0.15 * v)
    end
  end
  function M.tom(v) kdv = kdv + 30 * K.num(v, 1) end

  function M.hat(v, open) hatled = math.max(hatled, open and 1 or 0.6) end
  function M.tick() hatled = math.max(hatled, 0.5) end

  function M.brk(s, n, rev)
    s, n = K.num(s, 1), math.max(1, K.num(n, 8))
    ph_to = ph_to + (rev and -0.04 or 0.04)
    slice_x, slice_v = (s - 0.5) / n, 1
  end

  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 8)
    for k = 1, n do
      if #echoes >= 4 then table.remove(echoes, 1) end
      echoes[#echoes + 1] = {t0 = K.T + k * 0.04, dy = (k % 2 == 0 and 1 or -1) * (3 + k * 2.5), k = k}
    end
    accent = math.max(accent, 0.6)
  end

  function M.bar()
    if K.chaos > 0.35 and K.rnd() < K.chaos then salt = salt + 1 end
  end

  ------------------------------------------------------------------
  -- the filter: a saw's harmonics through a resonant two-pole lowpass
  ------------------------------------------------------------------
  local function coeffs()
    local g = 1 / (1 + 0.12 * q)
    for h = 1, NH do
      local w = h / fc
      local re, im = 1 - w * w, w / q
      local d = re * re + im * im
      -- H = 1 / (re + i im): real re / d, imaginary -im / d
      ca[h] = re / d * g / h
      cb[h] = -im / d * g / h
    end
  end

  local function wave(t)
    local y = 0
    local TAU = K.TAU
    for h = 1, NH do
      local a = h * TAU * t
      y = y + ca[h] * math.sin(a) + cb[h] * math.cos(a)
    end
    -- the overdriven squelch: a soft clip
    return y / (1 + math.abs(y) * 0.35)
  end

  local function trace(lv, pts, dy, dx, lvf, st)
    local px, py
    for i = 0, N, st or 1 do
      local x = X0 + (X1 - X0) * i / N + (dx or 0)
      local y = pts[i] + (dy or 0)
      if px then
        local l = lvf and lvf(i, lv) or lv
        line(l, px, py, x, y)
      end
      px, py = x, y
    end
  end

  local function scope(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi = A[K.LO], A[K.HI]
    local kl = K.kickless

    -- the trigger: locked on the beat, slipping with chaos, rolling kickless
    ph_to = ph_to + (c * c * 0.5 + kl * 0.12) * K.DTS
    ph = K.follow(ph, ph_to, 0.08, DT)
    slice_v = slice_v * math.exp(-DT / 0.15)
    local sweep = K.beat_sec * (1 + kl * 1.5)
    local su = ((T - sweep_t0) / math.max(0.15, sweep)) % 1

    coeffs()
    local amp = 7 + lo * 3 + e * 4 + acidv * 2
    local cyc = 2
    for i = 0, N do
      local u = i / N
      local y = wave(u * cyc + ph)
      if snz > 0.03 then y = y + (K.hash(i + math.floor(T * 10) * 53, 9) - 0.5) * snz * 0.6 end
      ys[i] = clamp(MY - y * amp + kd, Y0 + 1, Y1 - 1)
    end

    -- the graticule: dashed divisions, a brighter cross with ticks
    for gy = 1, 3 do
      local y = math.floor(Y0 + (Y1 - Y0) * gy / 4 + 0.5)
      if gy ~= 2 then K.dashes(1, y, 1, 4, 0, X0 + 1, X1) end
    end
    for gx = 1, 7 do
      local x = math.floor(X0 + (X1 - X0) * gx / 8 + 0.5)
      if gx ~= 4 then for y = Y0 + 3, Y1 - 2, 5 do put(1, x, y, 1, 1) end end
    end
    K.dashes(1.6, MY, 1, 4, 0, X0 + 1, X1)
    local cx = math.floor((X0 + X1) / 2)
    for y = Y0 + 1, Y1 - 1, 3 do put(1.6, cx, y, 1, 1) end

    -- the bezel: a rounded frame, the screen's lip
    local bz = 2.5 + K.bar_pulse * 0.8
    line(bz, X0 + 2, Y0 - 2, X1 - 2, Y0 - 2)
    line(bz, X0 + 2, Y1 + 2, X1 - 2, Y1 + 2)
    line(bz, X0 - 2, Y0 + 2, X0 - 2, Y1 - 2)
    line(bz, X1 + 2, Y0 + 2, X1 + 2, Y1 - 2)
    line(bz, X0 - 2, Y0 + 2, X0 + 2, Y0 - 2)
    line(bz, X1 - 2, Y0 - 2, X1 + 2, Y0 + 2)
    line(bz, X0 - 2, Y1 - 2, X0 + 2, Y1 + 2)
    line(bz, X1 - 2, Y1 + 2, X1 + 2, Y1 - 2)
    line(1.2, 1, 1, 126, 1)
    line(1.2, 1, 1, 1, 51)
    line(1.2, 126, 1, 126, 51)

    -- the phosphor's ghosts of the last sweeps (dimmer the older)
    local ng = #ghosts
    for gi = ng, 1, -1 do
      local g = ghosts[gi]
      trace((1 - (gi - 1) / (ng + 1)) * (2.2 + e), g, 0, g.dx, nil, 2)
    end
    -- chaos: copies of the trace, rolled off the trigger
    if c > 0.3 then
      local nc = c > 0.7 and 2 or 1
      for k = 1, nc do
        local dx = math.sin(T * (0.7 + k * 0.45) + k * 2.1) * c * 22
        trace(1.2 + c, ys, math.sin(T * (0.5 + k * 0.3) + k) * c * 5, dx, nil, 2)
      end
    end
    -- ratchet echoes stacked above and below
    for i = #echoes, 1, -1 do
      local E = echoes[i]
      local u = (T - E.t0) / 0.5
      if u >= 1 then table.remove(echoes, i)
      elseif u >= 0 then trace((3.5 - E.k * 0.3) * (1 - u), ys, E.dy * (1 + u * 0.3), 0, nil, 2) end
    end

    -- the bloom round the beam, then the beam: brightest behind its head
    local hx = su * N
    local core = 9.5 + e * 1.5 + K.env.kick * 2 + acidv * 1.5
    local bloom = 3 + e * 1.2 + hi * 1.5 + K.env.hat * 1.5 + K.env.ohat * 2 + acidv
    local function behind(i, lv)
      local age = (hx - i) % N / N
      return lv * (0.45 + 0.55 * math.exp(-age * 3))
    end
    -- the afterglow: the wave's body filled faintly down to the centre line
    local fl = 1 + e * 0.6 + K.env.kick * 1.2 + acidv * 0.8
    local sw = (X1 - X0) / N
    for i = 0, N - 1 do
      local y = (ys[i] + ys[i + 1]) / 2
      local a, b = math.min(y + 2, MY), math.max(y - 2, MY)
      if b - a >= 1 then put(behind(i, fl), X0 + i * sw, a, math.ceil(sw), b - a) end
    end
    trace(bloom * 0.4, ys, -2, 0, behind, 2)
    trace(bloom * 0.4, ys, 2, 0, behind, 2)
    trace(bloom, ys, -1, 0, behind)
    trace(bloom, ys, 1, 0, behind)
    trace(core, ys, 0, 0, behind)
    local hi_i = math.floor(hx + 0.5)
    put(13, X0 + (X1 - X0) * hi_i / N - 1, ys[hi_i] - 1, 2, 2)

    -- keep a ghost a few times a second (longer persistence kickless)
    if T - ghost_t > 0.12 then
      local g = {dx = 0}
      for i = 0, N do g[i] = ys[i] end
      table.insert(ghosts, 1, g)
      ghost_t = T
      local keepn = 3 + math.floor(kl * 1.5 + c)
      while #ghosts > keepn do table.remove(ghosts) end
    end

    -- the knob row: cutoff, resonance, env mod, decay; a trig lamp
    local kv = {clamp((fc - 1) / 9, 0, 1), clamp((q - 0.7) / 7, 0, 1), e, 0.3 + kl * 0.6}
    for k = 1, 4 do
      local x, y = 14 + (k - 1) * 22, 58
      K.disc(1, x, y, 3.6)
      K.ring(2.5 + (k == 2 and acidv * 3 or 0), x, y, 4.2, 10)
      local a = math.pi * 0.75 + kv[k] * math.pi * 1.5
      line(7 + (k <= 2 and acidv * 4 or 0), x, y, x + math.cos(a) * 4, y + math.sin(a) * 4)
    end
    if slice_v > 0.05 then put(2 + slice_v * 8, X0 + slice_x * (X1 - X0) - 1, Y1 + 2, 3, 1) end
    put(1 + hatled * 9, 102, 57, 2, 2)
    put(1 + K.env.kick * 9, 110, 57, 2, 2)
    put(1.5 + accent * 9, 118, 57, 2, 2)
    line(1, 98, 62, 124, 62)
  end

  ------------------------------------------------------------------
  -- view 2: the box from above
  ------------------------------------------------------------------
  local function note_at(s)
    local r = K.hash(s + salt * 16, 11)
    return SCALE[1 + math.floor(r * #SCALE)]
  end
  local function slide_at(s) return K.hash(s + salt * 16, 12) < 0.3 + K.kickless * 0.7 end
  local function accent_at(s) return K.hash(s + salt * 16, 13) < 0.25 end
  local function rest_at(s) return K.hash(s + salt * 16, 14) < 0.15 end

  local function key_center(s)
    local k = KEYS[s]
    return k.x + k.w / 2, k.black and KY0 + 7 or KY0 + 15
  end

  local function knob(x, y, val, lv, hot)
    if hot > 0.3 then K.disc(hot * 2, x, y, 3) end
    K.ring(1.8 + lv * 0.3 + hot * 3, x, y, 6, 12)
    K.ring(2.5 + lv * 0.3 + hot * 4, x, y, 6, 4, math.pi * 1.0, math.pi * 1.45)   -- the rim's lit side
    local a = math.pi * 0.75 + clamp(val, 0, 1) * math.pi * 1.5
    line(8 + hot * 4, x + math.cos(a) * 1.5, y + math.sin(a) * 1.5, x + math.cos(a) * 5, y + math.sin(a) * 5)
    -- the scale's end dots
    put(1.5, x + math.cos(math.pi * 0.75) * 8, y + math.sin(math.pi * 0.75) * 8, 1, 1)
    put(1.5, x + math.cos(math.pi * 0.25) * 8, y + math.sin(math.pi * 0.25) * 8, 1, 1)
  end

  local function box(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi = A[K.LO], A[K.HI]
    local kl = K.kickless

    -- the sequencer: which step plays, and where the light is
    local step = math.floor(K.stepf) % 16
    local sub = K.stepf - math.floor(K.stepf)
    if not K.playing then step = math.floor(T * 2) % 16; sub = (T * 2) % 1 end
    if step ~= last_step then
      local prev = last_step >= 0 and note_at(last_step) or note_at(step)
      if not rest_at(step) then
        local n = note_at(step)
        keytgt[n] = math.max(keytgt[n], accent_at(step) and 1 or 0.7)
        if slide_at(last_step >= 0 and last_step or 0) and prev ~= n then
          glide = {from = prev, to = n, t0 = T, dur = K.beat_sec / 4}
        end
        if c > 0.3 then
          local g = note_at((step + 5 + math.floor(K.rnd() * 7)) % 16)
          ghostkey[g] = math.max(ghostkey[g], c)
        end
      end
      last_step = step
    end
    local fade = 0.12 + kl * 0.5 + e * 0.1
    for s = 0, 12 do
      keytgt[s] = keytgt[s] * math.exp(-DT / fade)
      keylit[s] = K.follow(keylit[s], keytgt[s], keytgt[s] > keylit[s] and 0.04 or 0.02, DT)
      ghostkey[s] = ghostkey[s] * math.exp(-DT / 0.2)
    end

    -- the box: its panel edge, a seam, the front edge with the kick's thump
    local th = thump
    -- (close up: the box runs off the top and bottom of the screen)
    line(2 + th * 2, 3, 0, 3, 63)
    line(2 + th * 2, 124, 0, 124, 63)
    line(1, 1, 0, 1, 63)
    line(1, 126, 0, 126, 63)
    line(1, 4, 24, 123, 24)
    for _, p in ipairs({{6, 4}, {121, 4}, {6, 60}, {121, 60}}) do put(2, p[1], p[2], 1, 1) end

    -- the knobs: tune, cutoff, resonance, env mod, decay, accent
    local kv = {0.5 + (c > 0.2 and (K.hash(math.floor(T * 6), 3) - 0.5) * c * 0.4 or 0),
      clamp((fc - 1) / 9, 0, 1), clamp((q - 0.7) / 7, 0, 1), 0.2 + e * 0.75, 0.25 + kl * 0.65,
      0.3 + accent * 0.6}
    for k = 1, 6 do
      local hot = (k == 2 or k == 3 or k == 6) and acidv * 0.6 or 0
      knob(KN_X[k], KN_Y, kv[k], e * 0.8, clamp(hot, 0, 1))
    end

    -- the step lamps: the one playing bright, accents and slides marked
    for s = 0, 15 do
      local x = 8 + s * 7
      local on = s == step
      local l = 1
      if accent_at(s) then l = 2 end
      l = l + th * 1.5
      if on then l = 10 + accent * 2 end
      if rest_at(s) and not on then l = 1 end
      put(l, x, LED_Y, 4, 2)
      if slide_at(s) then put(1.5 + (on and 3 or 0), x + 3, LED_Y + 3, 5, 1) end
    end
    put(1 + hatled * 8, 120, LED_Y, 2, 2)

    -- the keyboard: white keys dim-filled round the black ones
    local kb = 1.6 + kbglow * 3 + hi * 1.2
    for s = 0, 12 do
      local k = KEYS[s]
      if not k.black then
        local lit = keylit[s] + ghostkey[s] * 0.5
        local l = 1 + lit * 4
        local lb = (s ~= 0 and s ~= 5 and s ~= 12)   -- a black key on the left
        local rb = (s ~= 4 and s ~= 11 and s ~= 12)  -- and on the right
        local xa = k.x + 1 + (lb and 4 or 0)
        local xb = k.x + k.w - 1 - (rb and 4 or 0)
        if lit > 0.05 then put(l, xa, KY0 + 1, xb - xa, KYB - KY0) end
        put(l, k.x + 1, KYB + 3, k.w - 2, KY1 - KYB - 3)
        line(kb, k.x, lb and KYB or KY0, k.x, KY1)
        if lit > 0.2 then put(lit * 12, k.x + 4, 55, k.w - 7, 2) end
      end
    end
    line(kb, KX0 + 8 * WK, KY0, KX0 + 8 * WK, KY1)
    line(kb * 0.7, KX0, KY0, KX0 + 8 * WK, KY0)
    for s = 0, 12 do
      local k = KEYS[s]
      if k.black then
        local lit = keylit[s] + ghostkey[s] * 0.5
        line(kb * 0.8, k.x, KY0, k.x, KYB)
        line(kb * 0.8, k.x + k.w, KY0, k.x + k.w, KYB)
        line(kb * 0.8, k.x, KYB, k.x + k.w, KYB)
        if lit > 0.05 then put(lit * 6, k.x + 2, KY0 + 2, k.w - 3, KYB - KY0 - 3) end
        if lit > 0.2 then put(lit * 12, k.x + 2, KYB - 4, k.w - 3, 2) end
      end
    end

    -- the glide: an arc over the keys from note to note, a light along it
    if glide then
      local u = (T - glide.t0) / math.max(0.05, glide.dur * (1 + kl * 2))
      if u >= 1.6 then glide = nil
      else
        local xa, ya = key_center(glide.from)
        local xb, yb = key_center(glide.to)
        local hgt = 8 + math.abs(xb - xa) * 0.15
        local px, py
        for k = 0, 10 do
          local t = k / 10
          local x = xa + (xb - xa) * t
          local y = ya + (yb - ya) * t - math.sin(t * math.pi) * hgt
          if px then line((3 + e * 2) * clamp(1.6 - u, 0, 1), px, py, x, y) end
          px, py = x, y
        end
        local t = clamp(u, 0, 1)
        local gx = xa + (xb - xa) * t
        local gy = ya + (yb - ya) * t - math.sin(t * math.pi) * hgt
        if u < 1 then put(12, gx - 1, gy - 1, 2, 2) end
      end
    end
  end

  ------------------------------------------------------------------
  function M.draw(S)
    local DT, e, c = K.DT, K.energy, K.chaos
    local hi = A[K.HI]
    -- the filter moves for both views
    acidv = acidv * math.exp(-DT / 0.35)
    local fc_to = 1.4 + e * 3.5 + hi * 1.5 + K.env.acid * 4 + acidv * 2 + K.env.fill * 2
    fc = K.follow(fc, fc_to, fc_to > fc and 0.05 or 0.4, DT)
    local q_to = 0.9 + acidv * 6 + c * 2 + K.env.perc * 0.5
    q = K.follow(q, q_to, q_to > q and 0.04 or 0.5, DT)
    -- the kick's deflection: a damped spring
    kdv = kdv + (-kd * 260 - kdv * 14) * DT
    kd = clamp(kd + kdv * DT, -12, 14)
    snz = snz * math.exp(-DT / 0.1)
    accent = accent * math.exp(-DT / 0.25)
    thump = thump * math.exp(-DT / 0.12)
    kbglow = kbglow * math.exp(-DT / 0.15)
    hatled = hatled * math.exp(-DT / 0.07)
    if K.view == 2 then box(S) else scope(S) end
  end

  M.init()
  return M
end
