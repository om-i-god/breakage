-- acid. view 1: a glowing phosphor scope in a dark bezel, the trace a
-- resonant filtered saw that squelches; view 2: the bass box seen from
-- above, knobs turning, the step lamps running and the played key lit,
-- slides drawn as glides between keys; view 3: the squelch country: every
-- eighth the filtered wave is laid down as a ridge in front of you and the
-- ridges roll away into the dark, a smiling sun coming up behind them.
--
-- all three: the cutoff opens slowly over the phrase (the long sweep) and
-- snaps back at its turn; energy opens it further, the acid perc kicks the
-- resonance up so the wave rings and squelches, a fill throws it wide.
--
-- view 1: a graticule in a rounded bezel; the trace is a saw through a
-- two-pole resonant lowpass, drawn with a bloom round it, its body glowing
-- faintly down to the centre line, and the last few sweeps fading behind
-- as phosphor ghosts. the beam sweeps once a beat and is brightest just
-- behind its head. the kick throws the trace down and lets it spring back,
-- the snare jolts it with noise, a clap jolts it twice, closed hats fizz
-- the bloom, open hats run a hiss along the top of the glass, rides tick
-- the graticule, other percs blip a marker on the trace, a break slice
-- nudges the trigger and marks the bezel, a ratchet stacks echoes of the
-- trace. chaos loses the trigger: the sweeps roll and the ghosts spread
-- into copies. kickless the beam slows and the ghosts hang on. four knobs
-- under the screen turn with the filter, the bar lamp blinks on the bar.
--
-- view 2: close over the box, which runs off the top and bottom of the
-- screen. a sixteen-step pattern plays; each step lights its lamp and its
-- key; a slide draws a glide arc between the two keys and the light
-- travels along it. the acid perc slams the accent knob, swings the cutoff
-- and resonance knobs and flares the key; the kick brightens the box's
-- sides and the lamp row, the snare lights the keyboard's outline, closed
-- hats tick a lamp, open hats light the slide marks; the pattern-bank lamps
-- along the top count the phrase. energy turns the knobs up; chaos
-- rewrites the pattern bar by bar and scatters ghost keys; kickless every
-- step glides and the keys fade slowly.
--
-- view 3: the newest ridge rises in front, brightest, and every older one
-- recedes and dims into the haze; the resonance peaks glint along the
-- near ridges. an accent lays down a tall bright ridge, the kick bows the
-- near ridges down and lets them spring back, the snare roughs the next
-- ridge with noise (a clap twice), other percs blip on the front ridge,
-- closed hats glint on the peaks, open hats flare the sun's rays, rides
-- twinkle the sky, a ratchet stacks echoes over the front ridge, the bar
-- lays down a brighter ridge. the sun climbs over the phrase and blinks
-- on the snare; its grin widens with the squelch. energy raises and
-- brightens the hills, chaos shakes them sideways and doubles them,
-- kickless the ridges come slower and smoother under a fog.
--
-- the ears: the mids push the resonance up (all views); view 1, the lows
-- swing the trace, the mids fill its body and its bloom, the highs open the
-- cutoff and fizz the glass; view 2, the lows lean on the case sides and the
-- lamp row, the mids light the keys from inside, the highs glint the knobs;
-- view 3, the lows swell the hills and the sun, the mids light the peaks,
-- the highs fill the sky with stars, the level lights the sun's rays.
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
  local pp = 0                       -- the phrase, eased (0 .. 1)
  local hiss, ridel, barl = 0, 0, 0  -- open-hat hiss, ride tick, bar lamp
  local clap2 = nil                  -- a clap's second jolt (time)
  local blips = {}                   -- other percs: {u, t0, v}

  ------------------------------------------------------------------
  -- view 3: the squelch country
  ------------------------------------------------------------------
  local NRID, NS3 = 8, 32           -- ridges, samples per ridge
  local HZ = 21                      -- the horizon
  local ridges, rn3, scroll = {}, 0, 0
  local lastbp, idle3, bcount = 0, 0, 0
  local hz = {}                      -- the nearer ridges' tops, per column
  local rpend = {acc = false, bar = false}
  local sunblink, flare = 0, 0
  local rat3 = 0                     -- a ratchet: the sun stutters

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
    pp, hiss, ridel, barl, clap2 = 0, 0, 0, 0, nil
    blips = {}
    ridges, rn3, scroll = {}, 0, 0
    for i = 1, NRID do
      local r = {acc = false, bar = false, nz = 0}
      for k = 0, NS3 do r[k] = 0 end
      ridges[i] = r
    end
    rpend.acc, rpend.bar = false, false
    sunblink, flare = 0, 0
  end
  M.clear = M.init

  ------------------------------------------------------------------
  -- the hits
  ------------------------------------------------------------------
  function M.kick(v)
    v = K.num(v, 1)
    kdv = kdv + 40 * v
    sweep_t0 = K.T
    thump = 1
  end

  function M.snare(v)
    v = K.num(v, 1)
    snz = math.max(snz, 0.6 + 0.4 * v)
    kbglow = 1
    sunblink = 1
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8); clap2 = K.T + 0.07 end
  function M.rim(v) snz = math.max(snz, 0.3 * K.num(v, 1)); hatled = 1 end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 5 then
      acidv = math.min(1.3, acidv + 0.8 * v)
      accent = 1
      local s = last_step >= 0 and last_step or 0
      keytgt[s] = 1
      rpend.acc = true
    else
      acidv = math.min(1.3, acidv + 0.15 * v)
      if #blips >= 6 then table.remove(blips, 1) end
      blips[#blips + 1] = {u = 0.1 + K.rnd() * 0.8, t0 = K.T, v = v, kind = kind}
    end
  end
  function M.tom(v) kdv = kdv + 30 * K.num(v, 1) end

  function M.hat(v, open)
    hatled = math.max(hatled, open and 1 or 0.6)
    if open then hiss = math.max(hiss, 0.5 + 0.5 * K.num(v, 1)); flare = 1 end
  end
  function M.ride(v) ridel = math.max(ridel, K.num(v, 1)); hatled = math.max(hatled, 0.4) end
  function M.tick() hatled = math.max(hatled, 0.5) end

  function M.brk(s, n, rev)
    s, n = K.num(s, 1), math.max(1, K.num(n, 8))
    ph_to = ph_to + ((s % 2 == 0) ~= (rev == true) and 0.012 or -0.012)
    slice_x, slice_v = (s - 0.5) / n, 1
  end

  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 8)
    for k = 1, n do
      if #echoes >= 4 then table.remove(echoes, 1) end
      echoes[#echoes + 1] = {t0 = K.T + k * 0.04, dy = (k % 2 == 0 and 1 or -1) * (3 + k * 2.5), k = k}
    end
    accent = math.max(accent, 0.6)
    flare = math.max(flare, 0.8)
    rat3 = 1
  end

  function M.bar()
    if K.chaos > 0.35 and K.rnd() < K.chaos then salt = salt + 1 end
    barl = 1
    rpend.bar = true
  end
  function M.fill() flare = 1; acidv = math.min(1.3, acidv + 0.4) end

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
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    local kl = K.kickless

    -- the trigger: locked on the beat, slipping with chaos, rolling kickless
    ph_to = ph_to + (c * c * 0.18 + kl * 0.1) * K.DTS
    ph = K.follow(ph, ph_to, 0.08, DT)
    slice_v = slice_v * math.exp(-DT / 0.15)
    local sweep = K.beat_sec * (1 + kl * 1.5)
    local su = ((T - sweep_t0) / math.max(0.15, sweep)) % 1

    coeffs()
    local amp = 6 + lo * 2 + e * 2.5 + acidv * 1.5
    local cyc = 2
    for i = 0, N do
      local u = i / N
      local y = wave(u * cyc + ph)
      if snz > 0.03 then y = y + (K.hash(i + math.floor(T * 4) * 53, 9) - 0.5) * snz * 0.6 end
      ys[i] = clamp(MY - y * amp + kd, Y0 + 1, Y1 - 1)
    end

    -- the graticule: dashed divisions, a brighter cross with ticks
    for gy = 1, 3 do
      local y = math.floor(Y0 + (Y1 - Y0) * gy / 4 + 0.5)
      if gy ~= 2 then K.dashes(1, y, 1, 4, 0, X0 + 1, X1) end
    end
    for gx = 1, 7 do
      local x = math.floor(X0 + (X1 - X0) * gx / 8 + 0.5)
      if gx ~= 4 then for y = Y0 + 3, Y1 - 2, 5 do put(1 + ridel * 3 * K.hash(gx * 13 + y, 5), x, y, 1, 1) end end
    end
    K.dashes(1.6, MY, 1, 4, 0, X0 + 1, X1)
    -- the highs: the phosphor fizzes on the glass
    K.haze(X0 + 1, Y0 + 1, X1, Y1, hi * 0.18, 1, T * 30)
    -- open hats: a hiss runs along the top of the glass
    if hiss > 0.05 then
      K.dashes(hiss * 5, Y0 + 2, 2, 5, T * 90, X0 + 2, X1 - 1)
    end
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
      local nc = 1
      for k = 1, nc do
        local dx = math.sin(T * (0.3 + k * 0.2) + k * 2.1) * c * 18
        trace(1.2 + c, ys, math.sin(T * (0.5 + k * 0.3) + k) * c * 5, dx, nil, 2)
      end
    end
    -- ratchet echoes stacked above and below
    for i = #echoes, 1, -1 do
      local E = echoes[i]
      local u = (T - E.t0) / 0.5
      if u >= 1 then table.remove(echoes, i)
      elseif u >= 0 then trace((3 - E.k * 0.3) * (1 - u), ys, E.dy, 0, nil, 2) end
    end

    -- the bloom round the beam, then the beam: brightest behind its head
    local hx = su * N
    local core = 8 + e * 1 + K.env.kick * 2.5 + acidv * 1.5
    local bloom = 1.8 + e * 0.8 + hi * 1.2 + mid * 1 + K.env.hat * 1.5 + K.env.ohat * 2 + acidv * 0.7
    local function behind(i, lv)
      local age = (hx - i) % N / N
      return lv * (0.72 + 0.28 * math.exp(-age * 3))
    end
    -- the afterglow: the wave's body filled faintly down to the centre line
    -- (the mids fill it out: the wave's body)
    local fl = 0.5 + mid * 2 + e * 0.6 + K.env.kick * 1.2 + acidv * 0.8
    local sw = (X1 - X0) / N
    for i = 0, N - 1 do
      local y = (ys[i] + ys[i + 1]) / 2
      local a, b = math.min(y + 1.5 + mid * 1.5, MY), math.max(y - 1.5 - mid * 1.5, MY)
      -- (a band hugging the trace on the centre's side, not the whole body)
      local depth = 5 + mid * 3
      if y < MY then b = math.min(b, a + depth) else a = math.max(a, b - depth) end
      if b - a >= 1 then put(fl, X0 + i * sw, a, math.ceil(sw), b - a) end
    end
    trace(bloom, ys, -1, 0, behind)
    trace(bloom, ys, 1, 0, behind)
    trace(core, ys, 0, 0, behind)
    local hi_i = math.floor(hx + 0.5)
    put(13, X0 + (X1 - X0) * hi_i / N - 1, ys[hi_i] - 1, 2, 2)
    -- other percs blip a marker on the trace
    for i = #blips, 1, -1 do
      local b = blips[i]
      local u = (T - b.t0) / 0.45
      if u >= 0 and u < 1 then
        local bi = clamp(math.floor(b.u * N + 0.5), 0, N)
        local bx, by = X0 + (X1 - X0) * bi / N, ys[bi] - 4 - u * 3
        local l = (4 + 6 * b.v) * (1 - u)
        line(l, bx - 2, by - 2, bx, by)
        line(l, bx + 2, by - 2, bx, by)
      end
    end

    -- keep a ghost a few times a second (longer persistence kickless)
    if T - ghost_t > 0.12 then
      local g = {dx = 0}
      for i = 0, N do g[i] = ys[i] end
      table.insert(ghosts, 1, g)
      ghost_t = T
      local keepn = 2 + math.floor(kl * 1.5 + c)
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
    put(1 + barl * 9, 94, 57, 2, 2)
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
    K.ring(2.5 + lv * 0.3 + hot * 4 + A[K.HI] * 4, x, y, 6, 4, math.pi * 1.0, math.pi * 1.45)   -- the rim's lit side
    local a = math.pi * 0.75 + clamp(val, 0, 1) * math.pi * 1.5
    line(8 + hot * 4, x + math.cos(a) * 1.5, y + math.sin(a) * 1.5, x + math.cos(a) * 5, y + math.sin(a) * 5)
    -- the scale's end dots
    put(1.5, x + math.cos(math.pi * 0.75) * 8, y + math.sin(math.pi * 0.75) * 8, 1, 1)
    put(1.5, x + math.cos(math.pi * 0.25) * 8, y + math.sin(math.pi * 0.25) * 8, 1, 1)
  end

  local function box(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
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
    -- (the lows lean on it: the case's sides and the lamp row)
    local th = thump + lo * 0.6
    -- (close up: the box runs off the top and bottom of the screen)
    line(1.5 + th * 2, 3, 0, 3, 63)
    line(1.5 + th * 2, 124, 0, 124, 63)
    line(1, 1, 0, 1, 63)
    line(1, 126, 0, 126, 63)
    line(1, 4, 24, 123, 24)
    -- a glint of light runs along the seam (the room's lamps on the panel)
    local sg = 4 + (T * 23) % 119
    put(2.5 + hi * 3, sg, 23, 2, 1)
    put(1.5, sg - 3, 23, 3, 1)
    for _, p in ipairs({{6, 4}, {121, 4}, {6, 60}, {121, 60}}) do put(2, p[1], p[2], 1, 1) end
    -- the pattern-bank lamps count the phrase along the top
    local pf = pp * 8
    for k = 0, 7 do
      local on = clamp(pf - k, 0, 1)
      local cur = k == math.floor(pf)
      put(1 + on * 1.5 + (cur and (2 + barl * 6) or 0), 36 + k * 7, 1, 4, 1)
    end

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
      local l = 0.7
      if accent_at(s) then l = 1.7 end
      l = l + th * 2
      if on then l = 10 + accent * 2 end
      if rest_at(s) and not on then l = 1 end
      put(l, x, LED_Y, 4, 2)
      if slide_at(s) then put(1.5 + (on and 3 or 0) + hiss * 4, x + 3, LED_Y + 3, 5, 1) end
    end
    put(1 + hatled * 8, 120, LED_Y, 2, 2)

    -- the keyboard: white keys dim-filled round the black ones
    local kb = 1.6 + kbglow * 3 + hi * 1.2
    for s = 0, 12 do
      local k = KEYS[s]
      if not k.black then
        local lit = keylit[s] + ghostkey[s] * 0.5
        local l = 1 + mid * 1.6 + lit * 4
        local lb = (s ~= 0 and s ~= 5 and s ~= 12)   -- a black key on the left
        local rb = (s ~= 4 and s ~= 11 and s ~= 12)  -- and on the right
        local xa = k.x + 1 + (lb and 4 or 0)
        local xb = k.x + k.w - 1 - (rb and 4 or 0)
        if lit > 0.05 then put(l, xa, KY0 + 1, xb - xa, KYB - KY0) end
        put(l, k.x + 1, KYB + 5, k.w - 2, KY1 - KYB - 5)
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
        line(kb * 0.8 + mid * 1.5, k.x, KY0, k.x, KYB)
        line(kb * 0.8 + mid * 1.5, k.x + k.w, KY0, k.x + k.w, KYB)
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
  -- view 3: the squelch country
  ------------------------------------------------------------------
  -- lay the wave down as a new ridge (the oldest ridge's table is reused)
  local function push_ridge()
    local r = table.remove(ridges)
    table.insert(ridges, 1, r)
    rn3 = rn3 + 1
    local note = note_at(last_step >= 0 and last_step or (rn3 % 16))
    local cyc = 1.1 + (note % 12) / 12 * 1.4
    local ph = K.hash(rn3, 21)
    for k = 0, NS3 do
      local y = wave(k / NS3 * cyc + ph)
      if snz > 0.05 then y = y + (K.hash(k + rn3 * 41, 9) - 0.5) * snz * 0.5 end
      r[k] = clamp(y, -1.5, 1.5)
    end
    -- (a little smoothing: hills, not needles)
    local p0 = r[0]
    for k = 1, NS3 - 1 do
      local cur = r[k]
      r[k] = (p0 + 2 * cur + r[k + 1]) / 4
      p0 = cur
    end
    r.acc, r.bar = rpend.acc, rpend.bar
    rpend.acc, rpend.bar = false, false
  end

  -- is (x, y) above the nearer ridges?
  local function clear(x, y)
    local col = math.floor(x)
    if col < 0 or col > 127 then return y < 64 end
    return y < hz[col] - 0.5
  end
  local function cline(l, x0, y0, x1, y1)
    local a, b = clear(x0, y0), clear(x1, y1)
    if a and b then line(l, x0, y0, x1, y1)
    elseif a then line(l, x0, y0, (x0 + x1) / 2, (y0 + y1) / 2)
    elseif b then line(l, (x0 + x1) / 2, (y0 + y1) / 2, x1, y1) end
  end

  local px3, py3 = {}, {}
  local function country(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    coeffs()
    if rn3 == 0 then for _ = 1, NRID do push_ridge() end end
    -- a ridge every three beats: the land lurches forward on each beat and
    -- settles; kickless it floats on evenly; at rest it drifts on slowly
    local bp = K.beat_ph
    if K.playing then
      if bp < lastbp - 0.5 then
        bcount = (bcount + 1) % 3
        if bcount == 0 then push_ridge() end
      end
      local lurch = bp * 0.4 + (1 - (1 - bp) ^ 2) * 0.6
      scroll = (bcount + lurch + (bp - lurch) * kl) / 3
    else
      idle3 = idle3 + K.DTS / 2.5
      if idle3 >= 1 then idle3 = idle3 % 1; push_ridge() end
      scroll = idle3
    end
    lastbp = bp

    for x = 0, 127 do hz[x] = 64 end
    local A0 = (9 + e * 4 + lo * 3.5) * (1 - kl * 0.4)
    local fogp = 1.5 + kl * 1.4
    for i = 1, NRID do
      local r = ridges[i]
      local d = (i - 1 + scroll) / NRID
      local z = 1 + d * 5
      local yb = HZ + (67 - HZ) / z
      local half = 66 * (0.72 + 0.28 / z)
      local am = A0 / z * (r.acc and 1.35 or 1)
      local fade = clamp((i - 1 + scroll) * 1.5, 0, 1)
      local lv = (2.8 + e * 0.4 - c * 0.6 + (r.acc and 1.2 or 0) + (r.bar and 0.8 or 0) + (i <= 2 and K.env.kick * 1.2 or 0))
        * (1 - d) ^ fogp * fade
      local jx = c > 0.45 and math.sin(T * 2.2 + (rn3 - i) * 1.9) * (c - 0.45) * 12 / z or 0
      for k = 0, NS3 do
        px3[k] = 64 + jx + (k / NS3 - 0.5) * 2 * half
        py3[k] = yb - r[k] * am
      end
      -- (the near ridges are drawn in full, the far ones in every other step)
      local st = i <= 5 and 1 or 2
      if lv >= 0.5 then
        -- (the far ones broken, as if through haze)
        local sk = i > 6 and 2 * st or st
        for k = st, NS3, sk do cline(lv, px3[k - st], py3[k - st], px3[k], py3[k]) end
        if c > 0.5 and i % 3 == 1 then
          for k = 2, NS3, 2 do cline(lv * 0.25 * c, px3[k - 2] + 3, py3[k - 2] - 2, px3[k] + 3, py3[k] - 2) end
        end
      end
      -- the resonance peaks glint on the near ridges, the closed hats too
      if i <= 5 then
        local gl = (1.5 + mid * 5 + acidv * 2.5 + K.env.hat * 4 + (r.acc and 2 or 0)) * (1 - d) * fade
        if gl >= 1 then
          for k = 1, NS3 - 1 do
            if r[k] > r[k - 1] and r[k] >= r[k + 1] and r[k] > 0.25 and clear(px3[k], py3[k] - 1) then
              put(gl, px3[k], py3[k] - 1, 1, 1)
            end
          end
        end
      end
      -- (the front ridge carries the blips and the ratchet's echoes)
      if i == 1 or (i == 2 and scroll < 0.5) then
        for bi = #blips, 1, -1 do
          local b = blips[bi]
          local u = (T - b.t0) / 0.45
          if u >= 0 and u < 1 then
            local k = clamp(math.floor(b.u * NS3 + 0.5), 0, NS3)
            local bx, by = px3[k], py3[k] - 4 - u * 4
            local l = (4 + 6 * b.v) * (1 - u)
            line(l, bx - 2, by - 2, bx, by)
            line(l, bx + 2, by - 2, bx, by)
          end
        end
        for ei = #echoes, 1, -1 do
          local E = echoes[ei]
          local u = (T - E.t0) / 0.5
          if u >= 0 and u < 1 and E.k <= 3 then
            local dy = -math.abs(E.dy) - 2
            for k = 2, NS3, 2 do
              line((2.6 - E.k * 0.4) * (1 - u), px3[k - 2], py3[k - 2] + dy, px3[k], py3[k] + dy)
            end
          end
        end
      end
      -- what this ridge hides from the ones behind it
      for k = 1, NS3 do
        local x0, x1 = px3[k - 1], px3[k]
        local c0, c1 = math.max(0, math.ceil(x0)), math.min(127, math.floor(x1))
        for col = c0, c1 do
          local u = (col - x0) / math.max(0.01, x1 - x0)
          local y = py3[k - 1] + (py3[k] - py3[k - 1]) * u
          if y < hz[col] then hz[col] = y end
        end
      end
    end
    for i = #echoes, 1, -1 do if T - echoes[i].t0 > 0.5 then table.remove(echoes, i) end end

    -- the sky: stars where the hills leave it, twinkling with the highs
    for k = 0, 27 do
      local x, y = math.floor(K.hash(k, 71) * 127), 1 + math.floor(K.hash(k, 72) * (HZ + 4))
      if K.hash(k, 73) < 0.35 + hi * 0.65 and clear(x, y) then
        local tw = 0.5 + 0.5 * math.sin(T * (1 + K.hash(k, 74) * 3) + k * 1.3)
        put(0.8 + tw * (0.6 + hi * 4 + ridel * 4), x, y, 1, 1)
      end
    end
    -- kickless: a fog lies along the horizon
    if kl > 0.05 then K.haze(0, HZ, 128, HZ + 7, kl * 0.3, 1, T * 4) end

    -- the sun: it climbs over the phrase, swells with the lows, smiles
    local sr = 8 + lo * 1.2
    local sx, sy = 64 + math.sin(T * 0.05) * 3, HZ + 9 - pp * 16 - lo
    local sl = 2.2 + amp * 1.2 + e * 0.6 + flare * 1.5
    -- a glow in the sky round it, behind the hills (the level widens it)
    local gx, gy = 17 + amp * 7 + e * 4 + flare * 5, 11 + amp * 2
    for dy = -math.floor(gy), math.floor(gy) do
      local y = math.floor(sy + dy)
      local hw = gx * math.sqrt(math.max(0, 1 - (dy / gy) ^ 2))
      if hw >= 2 and y >= 0 then
        local run
        local x0, x1 = math.floor(sx - hw), math.floor(sx + hw)
        for x = x0, x1 + 2, 2 do
          local ok = x <= x1 and clear(x, y) and clear(x + 1, y)
          if ok then run = run or x
          elseif run then put(0.6 + amp * 0.3, run, y, x - run, 1); run = nil end
        end
      end
    end
    for dy = -math.floor(sr), math.floor(sr) do
      local y = sy + dy
      local hw = math.sqrt(math.max(0, sr * sr - dy * dy))
      if hw >= 1 then
        -- (cut where the hills come in front)
        local run
        for x = math.floor(sx - hw), math.floor(sx + hw) + 1 do
          local ok = x <= sx + hw and clear(x, y)
          if ok then run = run or x
          elseif run then put(sl, run, y, x - run, 1); run = nil end
        end
      end
    end
    local rl = 2.5 + amp * 1 + flare * 3 + K.env.ohat * 2
    local segs = 20
    for k = 1, segs do
      local a0, a1 = (k - 1) / segs * K.TAU, k / segs * K.TAU
      cline(rl, sx + math.cos(a0) * sr, sy + math.sin(a0) * sr, sx + math.cos(a1) * sr, sy + math.sin(a1) * sr)
    end
    -- a ratchet: the sun's ring stutters out sideways
    if rat3 > 0.1 then
      for k = 1, 2 do
        local ox = k * 5
        for side = -1, 1, 2 do
          for j = 1, 10 do
            local a0, a1 = (j - 1) / 10 * K.TAU, j / 10 * K.TAU
            cline(rat3 * (5 - k * 1.2), sx + side * ox + math.cos(a0) * sr, sy + math.sin(a0) * sr,
              sx + side * ox + math.cos(a1) * sr, sy + math.sin(a1) * sr)
          end
        end
      end
    end
    -- its rays turn slowly; open hats and fills flare them
    local ra = T * 0.12
    for k = 0, 11 do
      local a = ra + k / 12 * K.TAU
      local r0, r1 = sr + 2.5, sr + 4 + amp * 5 + flare * 6 + (k % 2) * 2
      cline(1 + amp * 2 + flare * 4, sx + math.cos(a) * r0, sy + math.sin(a) * r0, sx + math.cos(a) * r1, sy + math.sin(a) * r1)
    end
    -- the face: the eyes blink on the snare, the grin widens with the squelch
    local fl = 5 + mid * 3 + acidv * 3
    for _, ex in ipairs({sx - 3.5, sx + 2.5}) do
      if clear(ex, sy - 2) then
        if sunblink > 0.4 then put(fl, ex - 0.5, sy - 2, 2, 1) else put(fl, ex, sy - 3, 1, 2) end
      end
    end
    local gr = clamp(acidv * 0.35 + mid * 0.15, 0, 0.5)
    local m0, m1 = 0.45 - gr, math.pi - 0.45 + gr
    for k = 1, 6 do
      local a0, a1 = m0 + (m1 - m0) * (k - 1) / 6, m0 + (m1 - m0) * k / 6
      cline(fl, sx + math.cos(a0) * 4.5, sy - 0.5 + math.sin(a0) * 4.5, sx + math.cos(a1) * 4.5, sy - 0.5 + math.sin(a1) * 4.5)
    end
  end

  ------------------------------------------------------------------
  function M.draw(S)
    local DT, e, c = K.DT, K.energy, K.chaos
    local hi = A[K.HI]
    -- the filter moves for both views
    acidv = acidv * math.exp(-DT / 0.35)
    local pl = math.floor(K.num(S and S.phrase_len, 16))
    if not (pl >= 1 and pl <= 256) then pl = 16 end
    local pto = clamp((K.num(S and S.phrase_pos, 0) % pl + K.bar_ph) / pl, 0, 1)
    pp = K.follow(pp, pto, 0.4, DT)
    hiss = hiss * math.exp(-DT / 0.15)
    ridel = ridel * math.exp(-DT / 0.2)
    barl = barl * math.exp(-DT / 0.2)
    sunblink = sunblink * math.exp(-DT / 0.12)
    rat3 = rat3 * math.exp(-DT / 0.25)
    flare = flare * math.exp(-DT / 0.35)
    if clap2 and K.T >= clap2 then snz = math.max(snz, 0.55); clap2 = nil end
    for i = #blips, 1, -1 do if K.T - blips[i].t0 > 0.5 then table.remove(blips, i) end end
    -- (the long sweep: the cutoff opens over the phrase)
    local fc_to = 1.4 + e * 3.5 + hi * 1.5 + K.env.acid * 4 + acidv * 2 + K.env.fill * 2 + pp * pp * 2.5
    fc_to = math.min(fc_to, 6)
    fc = K.follow(fc, fc_to, fc_to > fc and 0.15 or 0.5, DT)
    local q_to = 0.9 + acidv * 6 + c * 2 + K.env.perc * 0.5 + A[K.MID] * 2.5
    q_to = math.min(q_to, 5.5)
    q = K.follow(q, q_to, q_to > q and 0.12 or 0.6, DT)
    -- the kick's deflection: a damped spring
    kdv = kdv + (-kd * 200 - kdv * 22) * DT
    kd = clamp(kd + kdv * DT, -12, 14)
    snz = snz * math.exp(-DT / 0.1)
    accent = accent * math.exp(-DT / 0.25)
    thump = thump * math.exp(-DT / 0.12)
    kbglow = kbglow * math.exp(-DT / 0.15)
    hatled = hatled * math.exp(-DT / 0.07)
    if K.view == 2 then box(S) elseif K.view == 3 then country(S) else scope(S) end
  end

  M.init()
  return M
end
