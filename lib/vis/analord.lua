-- analord. view 1: a rack of analog gear at night, a meter bridge of three
-- warm VU meters over a lamp strip and a patch bay whose cables hang and
-- swing in front; view 2: close up on a modular synth wall, oscillators
-- drawing their waves on small scopes, patch points pulsing, a sequencer
-- lamp running and cables swinging between the modules; view 3: the
-- studio's reel-to-reel tape machine, its reels turning, the tape running
-- over the heads and the capstan, the transport buttons lit below.
--
-- view 1: the rack stands between its rails, each unit's faceplate lit
-- along its top edge and shadowed under it. the meters (kick, snare, hats)
-- glow from behind, their needles thrown by the hits with real VU
-- ballistics, a little overshoot and a ghost on the face. the lamp strip
-- runs the sixteen steps, with a lamp for each voice (closed and open hat
-- apart), a clip lamp on the peaks, and a phrase rule under it that fills
-- bar by bar; a fill chases the strip. the cables hang from the bay in
-- loops, each a pendulum: the kick swings them all, the snare and perc
-- swing a few, a perc kind lights its own jack. energy patches in more
-- cables and lifts the meters' glow, chaos makes the needles chatter, the
-- lamps flicker and re-patches the bay, a ratchet rattles a needle once
-- for every repeat; kickless the kick meter dims to standby, its lamp
-- breathing, and the cables settle.
--
-- view 2: four modules fill the wall: the kick's oscillator (a sine that
-- drops in pitch and dies away on its scope, idling as a slow LFO between
-- kicks), the snare's noise and tone, a sequencer with eight lamps in two
-- columns and four bar lamps under them, and the hats' envelope scope (a
-- closed hat a needle, an open hat a wide hump). each scope's beam sweeps
-- it, leaving a short phosphor tail. jacks pulse with the voice they
-- carry, a perc kind lights its own jack on the sequencer; cables arc
-- between them and swing. energy turns the knobs up and brightens the
-- scopes, chaos folds the waves, skips the sequencer and patches more
-- cables, a fill runs every lamp; kickless the kick's scope idles.
--
-- view 3: two reels turn on the deck, their packs wound as rings: over a
-- phrase the tape winds from the left reel onto the right, and at the
-- phrase edge it rewinds, both reels spinning back. the tape runs down
-- past a guide, over the erase, record and play heads, through the
-- capstan and pinch roller and up to the take-up reel, its oxide marks
-- crawling with the speed. the kick lurches the reels, bows the tape and
-- lights the play head; the snare flashes the record head and its lamp
-- and sets the tape fluttering; a closed hat sparks the erase head, an
-- open hat runs a glint the length of the tape; a perc kind lights its
-- transport button, a fill runs them all; a ratchet stutters the reels
-- once per repeat. energy speeds the transport and lifts the light,
-- chaos sets wow (the reels wobble on their spindles) and flutter on the
-- tape and flashes splices; kickless the pinch roller lifts, the reels
-- coast and a haze settles on the deck.
--
-- the ears: view 1, the lows, mids and highs backlight the three meter
-- faces, the mids glow the lamp strip and the lower jacks, the highs
-- glint on the rail holes and the dust, the level lights the faceplate
-- edges. view 2, each scope's phosphor is lit by its band (lo kick, mid
-- snare, hi hats), the level lights the panel edges and the sequencer.
-- view 3, the lows glow the reel hubs and swell the bass meter, the mids
-- light the tape and the heads, the highs glint on the flanges and swell
-- the treble meter, the level lights the pilot lamps and the deck frame.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  ------------------------------------------------------------------
  -- shared state
  ------------------------------------------------------------------
  local ndl, vel, buzz, buzz_t, lamp, ghost_a
  local clip = 0
  local cables                         -- view 1's cables
  local wires                          -- view 2's cables
  local hatv, percv = 0, 0
  local ohat = 0                       -- open-hat lamp
  local jflash = {}                    -- view 1: perc kind -> top-row jack flash
  local fill_t = 99                    -- time since a fill
  local bar_n = 0                      -- bars seen

  -- view 1 layout
  local MW, MH, MY = 32, 21, 3          -- a meter's box, its top
  local MX = {11, 48, 85}               -- each meter's left
  local LY = 30                         -- the lamp strip unit's top
  local JY = {43, 51}                   -- the bay's jack rows
  local NJ = 9
  local JX = {}
  for j = 1, NJ do JX[j] = 14 + (j - 1) * 12.5 end

  -- view 1's cables: (row, jack) -> (row, jack), slack below the lower end
  local BASE = {{1, 1, 2, 3, 10}, {1, 4, 2, 2, 7}, {1, 6, 2, 8, 12}, {2, 5, 1, 9, 9},
    {1, 2, 1, 5, 14}, {2, 1, 2, 6, 11}, {1, 3, 2, 7, 13}, {1, 7, 2, 9, 8}}

  -- view 2 layout: four modules, their jacks
  local MODX = {1, 33, 65, 97}
  local MODW = 30
  local SCY0, SCY1 = 5, 23              -- the scopes' screens
  local JACK2 = {}                      -- [module] = {{x, y}, ...}
  for m = 1, 4 do
    local x = MODX[m]
    JACK2[m] = {{x + 7, 50}, {x + 15, 50}, {x + 23, 50}, {x + 7, 58}, {x + 23, 58}}
  end
  local WBASE = {{1, 3, 2, 1, 9}, {2, 3, 4, 1, 12}, {3, 2, 1, 4, 8}, {4, 2, 2, 5, 10},
    {3, 5, 4, 4, 7}, {1, 5, 3, 1, 11}}

  local kick_t, snare_t, kick_v, snare_v = 99, 99, 0, 0
  local snare_n = 0
  local hat_spikes = {}
  local seq_i, seq_seen = 0, -1
  local pulse = {0, 0, 0, 0}            -- each module's jacks
  local jpulse = {0, 0, 0, 0, 0}        -- view 2: the sequencer's jacks, by perc kind

  -- view 3 state
  local angL, angR = 0, 0               -- reel angles
  local tape_u = 0                      -- eased wind position 0..1
  local lurch = 0                       -- kick jolt on the transport
  local flutter = 0                     -- snare flutter on the tape
  local oxide = 0                       -- distance the tape has run (px)
  local rec = 0                         -- record head flash
  local erase = 0                       -- erase head spark
  local tglints = {}                    -- open-hat glints along the tape
  local btn = {0, 0, 0, 0, 0, 0}        -- transport buttons
  local stut, stut_t = 0, 0             -- ratchet stutter
  local spin = 0                        -- signed reel speed, eased

  function M.init()
    ndl, vel, buzz, buzz_t, lamp, ghost_a = {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}
    clip, hatv, percv, ohat = 0, 0, 0, 0
    jflash = {}
    for j = 1, NJ do jflash[j] = 0 end
    fill_t, bar_n = 99, 0
    cables = {}
    for i, c in ipairs(BASE) do
      cables[i] = {a = c[1], i = c[2], b = c[3], j = c[4], sag = c[5], ph = i * 1.7, sw = 0, swv = 0}
    end
    wires = {}
    for i, c in ipairs(WBASE) do
      wires[i] = {m1 = c[1], j1 = c[2], m2 = c[3], j2 = c[4], sag = c[5], sw = 0, swv = 0}
    end
    kick_t, snare_t, kick_v, snare_v = 99, 99, 0, 0
    snare_n = 0
    hat_spikes = {}
    seq_i, seq_seen = 0, -1
    pulse = {0, 0, 0, 0}
    jpulse = {0, 0, 0, 0, 0}
    angL, angR, tape_u, lurch, flutter, oxide = 0, 1.1, 0, 0, 0, 0
    rec, erase, stut, stut_t, spin = 0, 0, 0, 0, 0
    tglints = {}
    btn = {0, 0, 0, 0, 0, 0}
  end
  M.clear = M.init

  local function swing(list, amt, every)
    for i, C in ipairs(list) do
      if not every or i % every == 0 then
        C.swv = C.swv + amt * (0.6 + 0.8 * K.hash(i, 21)) * ((i % 2 == 0) and 1 or -1)
      end
    end
  end

  local function throw(m, v)
    vel[m] = vel[m] + (2.5 + 5 * v)
    lamp[m] = 1
    if v > 0.85 then clip = 1 end
  end

  function M.kick(v)
    v = clamp(K.num(v, 1), 0, 1)
    throw(1, v)
    swing(cables, 22 * v)
    swing(wires, 9 * v)
    kick_t, kick_v = 0, v
    pulse[1] = 1
    lurch = math.max(lurch, 0.4 + 0.6 * v)
  end
  function M.snare(v, n)
    v = clamp(K.num(v, 1), 0, 1)
    throw(2, v)
    swing(cables, 14 * v, 2)
    swing(wires, 10 * v, 2)
    snare_t, snare_v = 0, v
    snare_n = snare_n + 1
    pulse[2] = 1
    rec = math.max(rec, 0.5 + 0.5 * v)
    flutter = math.max(flutter, 0.5 + 0.5 * v)
  end
  function M.clap(v)
    v = clamp(K.num(v, 1), 0, 1)
    throw(2, v * 0.7)
    swing(cables, 9 * v, 3)
    swing(wires, 7 * v, 3)
    pulse[2] = math.max(pulse[2], 0.8)
    rec = math.max(rec, 0.8)
    flutter = math.max(flutter, 0.4)
    btn[2] = 1
  end
  function M.rim(v)
    v = clamp(K.num(v, 1), 0, 1)
    throw(2, v * 0.4); pulse[2] = math.max(pulse[2], 0.5)
    jflash[5] = 1
    btn[5] = math.max(btn[5], 0.7)
  end
  function M.hat(v, open)
    v = clamp(K.num(v, 1), 0, 1)
    throw(3, v * (open and 0.9 or 0.5))
    hatv = 1
    if open then ohat = 1 end
    pulse[4] = math.max(pulse[4], open and 1 or 0.6)
    if #hat_spikes >= 10 then table.remove(hat_spikes, 1) end
    hat_spikes[#hat_spikes + 1] = {t0 = K.T, v = v, open = open}
    erase = math.max(erase, 0.5 + 0.5 * v)
    if open and #tglints < 4 then tglints[#tglints + 1] = {t0 = K.T, v = v} end
  end
  function M.perc(kind, v)
    v = clamp(K.num(v, 1), 0, 1)
    local k = clamp(math.floor(K.num(kind, 1)), 1, 21)
    throw(3, v * 0.3)
    lamp[2] = math.max(lamp[2], 0.5)
    percv = 1
    swing(cables, 6 * v, 3)
    pulse[3] = math.max(pulse[3], 0.7)
    jflash[(k - 1) % NJ + 1] = 1
    jpulse[(k - 1) % 5 + 1] = 1
    btn[(k - 1) % 6 + 1] = 1
  end
  function M.tom(v)
    v = clamp(K.num(v, 1), 0, 1)
    throw(1, v * 0.5); swing(cables, 8 * v, 3)
    jflash[9] = 1; jpulse[5] = 1; btn[6] = 1
    lurch = math.max(lurch, 0.3 * v)
  end
  function M.tick() pulse[3] = math.max(pulse[3], 0.5); jpulse[2] = math.max(jpulse[2], 0.6); btn[4] = math.max(btn[4], 0.6) end
  function M.fill() fill_t = 0 end

  function M.ratchet(n, voice)
    local m = voice == "kick" and 1 or ((voice == "hat" or voice == "tick") and 3 or 2)
    n = clamp(math.floor(K.num(n, 2)), 1, 16)
    buzz[m], buzz_t[m] = n, 0
    ghost_a[m] = 1
    lamp[m] = 1
    stut, stut_t = n, 0
  end

  -- chaos re-patches on the bar
  function M.bar()
    bar_n = bar_n + 1
    if K.chaos > 0.35 then
      local c = cables[1 + math.floor(K.rnd() * #cables)]
      c.i = 1 + math.floor(K.rnd() * NJ)
      c.j = 1 + math.floor(K.rnd() * NJ)
      c.b = K.rnd() < 0.5 and 1 or 2
      if c.a == c.b and c.i == c.j then c.j = c.j % NJ + 1 end
      local w = wires[1 + math.floor(K.rnd() * #wires)]
      w.m2 = 1 + math.floor(K.rnd() * 4)
      w.j2 = 1 + math.floor(K.rnd() * 5)
      if w.m1 == w.m2 and w.j1 == w.j2 then w.j2 = w.j2 % 5 + 1 end
    end
  end

  -- where we are in the phrase, 0..1 (smooth through the bar)
  local function phrase_u(S)
    local pl = math.max(1, math.floor(K.num(S and S.phrase_len, 16)))
    local pp = math.floor(K.num(S and S.phrase_pos, 0)) % pl
    if not K.playing then return (K.T * 0.012) % 1 end
    return clamp((pp + K.bar_ph) / pl, 0, 1)
  end

  ------------------------------------------------------------------
  -- physics shared by the views
  ------------------------------------------------------------------
  local function needles(DT, T, e, c)
    local lo, hi = A[K.LO], A[K.HI]
    local target = {lo * 0.6 * (1 - K.kickless * 0.7) + K.env.kick * 0.3,
      A[K.MID] * 0.5 + K.env.snare * 0.3, hi * 0.6 + K.env.hat * 0.3 + K.env.ohat * 0.2}
    for m = 1, 3 do
      local to = target[m] * (0.6 + 0.5 * e) + 0.03
      if buzz[m] > 0 then
        buzz_t[m] = buzz_t[m] - DT
        if buzz_t[m] <= 0 then vel[m] = vel[m] + 4; buzz[m] = buzz[m] - 1; buzz_t[m] = 0.05; lamp[m] = 1 end
      end
      ghost_a[m] = ghost_a[m] * math.exp(-DT / 0.35)
      to = to + 0.015 * math.sin(T * 5.1 + m * 2) + 0.01 * math.sin(T * 0.7 + m)
      if c > 0.2 then to = to + math.sin(T * (17 + m * 3) + m) * c * 0.12 end
      -- VU ballistics: a stiff, slightly underdamped spring
      local acc = (to - ndl[m]) * 260 - vel[m] * 15
      vel[m] = clamp(vel[m] + acc * DT, -60, 60)
      ndl[m] = clamp(ndl[m] + vel[m] * DT, -0.05, 1.1)
      lamp[m] = lamp[m] * math.exp(-DT / 0.08)
    end
  end

  local function pendulums(list, DT)
    local damp = 2.2 + K.kickless * 2
    for _, C in ipairs(list) do
      C.swv = C.swv + (-C.sw * 30 - C.swv * damp) * DT
      C.sw = clamp(C.sw + C.swv * DT, -14, 14)
    end
  end

  -- a cable: a quadratic from (x0, y0) to (x1, y1) through (mx, my); its
  -- shadow a step down and right, faint
  local function cable(lv, x0, y0, x1, y1, mx, my, segs, shadow)
    local px, py = x0, y0
    for k = 1, segs do
      local t = k / segs
      local x = (1 - t) ^ 2 * x0 + 2 * (1 - t) * t * mx + t * t * x1
      local y = (1 - t) ^ 2 * y0 + 2 * (1 - t) * t * my + t * t * y1
      if shadow then line(1, px + 2, py + 2, x + 2, y + 2) end
      line(lv, px, py, x, y)
      px, py = x, y
    end
  end

  ------------------------------------------------------------------
  -- view 1: the rack
  ------------------------------------------------------------------
  local SPAN = 0.8
  local function meter(m, x0, val, e)
    local cx, cy = x0 + MW / 2, MY + MH + 8
    local R = 24
    local yb = MY + MH
    local kl = (m == 1) and K.kickless or 0
    -- each face is backlit by its own band: lo / mid / hi; dithered so the
    -- dark glass stays dark until the band comes up
    local band = A[m == 1 and K.LO or (m == 2 and K.MID or K.HI)]
    local glow = (0.45 + e * 0.35 + lamp[m] * 0.6 + val * 0.35 + band * 1.3 + K.bar_pulse * 0.25
      + 0.12 * math.sin(K.T * 0.9 + m * 2.1)) * (1 - kl * 0.6)
    -- (a lit top row, then a dither that thins down the face)
    put(clamp(glow * 1.6, 0, 6), x0 + 1, MY + 1, MW - 1, 1)
    K.gradient(MY + 2, MY + 8, function(y)
      return clamp(glow * 0.55, 0, 1.6) * (1 - 0.5 * (y - MY) / 8)
    end, nil, x0 + 1, x0 + MW)
    -- the bezel
    line(3, x0 - 1, MY - 1, x0 + MW + 1, MY - 1)
    line(1.5, x0 - 1, yb + 1, x0 + MW + 1, yb + 1)
    line(2, x0 - 1, MY - 1, x0 - 1, yb + 1)
    line(2, x0 + MW + 1, MY - 1, x0 + MW + 1, yb + 1)
    -- the scale: an arc of ticks, the last third hot
    K.ring(3.5 - kl, cx, cy, R - 4, 8, -math.pi / 2 - SPAN, -math.pi / 2 + SPAN * 0.4)
    K.ring(5 - kl * 2, cx, cy, R - 4, 4, -math.pi / 2 + SPAN * 0.4, -math.pi / 2 + SPAN)
    for k = 0, 8, 2 do
      local a = -math.pi / 2 - SPAN + 2 * SPAN * k / 8
      local r1 = R - 4
      local r0 = r1 + (k % 4 == 0 and 3 or 1.5)
      line(k >= 6 and 6 or 4, cx + math.cos(a) * r1, cy + math.sin(a) * r1, cx + math.cos(a) * r0, cy + math.sin(a) * r0)
    end
    -- the needle's ghost and shadow, then the needle, from its pivot below the face
    local a = -math.pi / 2 - SPAN - 0.05 + (2 * SPAN + 0.1) * clamp(val, 0, 1.08)
    local ca, sa = math.cos(a), math.sin(a)
    local r0 = math.max(11, (cy - yb + 2) / math.max(0.2, -sa))
    if ghost_a[m] > 0.05 then
      local ga = a - 0.12 * ghost_a[m]
      line(3 * ghost_a[m], cx + math.cos(ga) * r0, cy + math.sin(ga) * r0, cx + math.cos(ga) * (R - 2), cy + math.sin(ga) * (R - 2))
    end
    line(0.6, cx + ca * r0 + 2, cy + sa * r0 + 1, cx + ca * (R - 1) + 2, cy + sa * (R - 1) + 1)
    line((11 + lamp[m] * 1.5) * (1 - kl * 0.4), cx + ca * r0, cy + sa * r0, cx + ca * (R - 1), cy + sa * (R - 1))
    -- the pivot's cover and the lamp (kickless: a breathing standby lamp)
    put(3, cx - 4, yb - 2, 9, 2)
    local ll = 1.5 + lamp[m] * 9
    if kl > 0.3 then ll = 1.5 + 2 * (0.5 + 0.5 * math.sin(K.T * 1.6)) end
    put(ll, x0 + MW - 3, MY + 1, 2, 2)
  end

  local function rack(S)
    local T, e, c = K.T, K.energy, K.chaos
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]

    -- the rails, their holes catching glints of the air (hi)
    for ri, x in ipairs({2, 122}) do
      line(1.5, x, 0, x, 63)
      for y = 3, 63, 7 do
        local g = K.hash(y + ri * 13 + math.floor(T * 9) * 7, 41)
        put(1 + hi * (g > 0.5 and 4 or 1.5), x + 1, y, 3, 2)
      end
    end
    -- a slow sheen of room light sliding down the rails
    local sy = (T * 6) % 80 - 8
    put(2.5 + amp * 2, 3, sy, 1, 6); put(2.5 + amp * 2, 123, 72 - sy, 1, 6)

    -- the units: lit top edge, screws glowing with the level (amp)
    for _, u in ipairs({{0, 27}, {LY - 1, 9}, {39, 25}}) do
      local y0 = u[1]
      line(1.5 + amp * 3 + K.bar_pulse * 0.8, 8, y0, 120, y0)
      put(1 + amp * 4, 10, y0 + 2, 1, 1); put(1 + amp * 4, 117, y0 + 2, 1, 1)
    end

    -- the meter bridge
    for m = 1, 3 do meter(m, MX[m], ndl[m], e) end

    -- the lamp strip: sixteen steps, voice lamps, a clip lamp
    local step = math.floor(K.stepf) % 16
    if not K.playing then step = math.floor(T * 2) % 16 end
    local chase = fill_t < 1.2 and math.floor(fill_t * 26) % 16 or -1
    for s = 0, 15 do
      local on = s == step
      -- the unlit lamps glow with the body of the mix (mid), a wave along the strip
      local l = 1.2 + (s % 4 == 0 and 0.8 or 0) + mid * (2.5 + 1.5 * math.sin(T * 4 - s * 0.6))
      if c > 0.3 and K.hash(s * 7 + math.floor(T * 8), 77) < (c - 0.3) * 0.35 then l = l + 4 end
      if s == chase or s == (chase + 8) % 16 and chase >= 0 then l = math.max(l, 8) end
      if on then l = 9 + K.env.kick * 2 end
      put(l, 14 + s * 5, LY + 2, 3, 2)
    end
    for m = 1, 3 do put(1.5 + lamp[m] * 9, 96 + (m - 1) * 4, LY + 2, 2, 2) end
    put(1.5 + ohat * 9, 108, LY + 2, 2, 2)
    put(1 + clip * 10, 113, LY + 2, 3, 2)
    -- the phrase rule: one cell per bar, filling through the phrase
    local pl = clamp(math.floor(K.num(S and S.phrase_len, 16)), 1, 32)
    local pp = math.floor(K.num(S and S.phrase_pos, 0)) % pl
    local cw = 80 / pl
    for b = 0, pl - 1 do
      local lv = b < pp and (2 + e) or (b == pp and (3 + K.bar_pulse * 5) or 1)
      put(lv, 14 + b * cw, LY + 6, math.max(1, cw - 1), 1)
    end

    -- the bay: jacks
    for r = 1, 2 do
      for j = 1, NJ do
        local lv = 2 + (r == 1 and (lamp[1 + (j - 1) % 3] * 3 + jflash[j] * 6) or mid * 2.5)
        K.ring(lv, JX[j], JY[r], 2, 6)
        if r == 2 then put(mid * 4 * (0.6 + 0.4 * math.sin(T * 3 + j)), JX[j] - 1, JY[r] - 1, 2, 2) end
        if r == 1 and jflash[j] > 0.1 then put(jflash[j] * 11, JX[j], JY[r], 1, 1) end
      end
    end
    -- a power lamp, breathing
    put(1.5 + 2 * (0.5 + 0.5 * math.sin(T * 0.9)), 9, 45, 2, 1)
    -- dust drifting in the meters' light
    K.grain(function(u, v) return 9 + u * 110, 2 + v * 34 end, 8 + e * 10 + hi * 12, 3 + hi * 3)

    -- the cables: loops that hang and swing in front
    local n = clamp(math.floor(3 + e * 5 + c * 2 + 0.5), 3, #cables)
    local sw = 1.5 + K.swing * 4
    for k = 1, n do
      local C = cables[k]
      local x0, y0 = JX[C.i], JY[C.a] + 2
      local x1, y1 = JX[C.j], JY[C.b] + 2
      local sway = C.sw + math.sin(T * (1.1 + K.swing) + C.ph) * sw
      local my = math.max(y0, y1) + C.sag * (1 + lo * 0.3) + math.abs(C.sw) * 0.3
      local lv = 3 + (k % 3) * 0.8 + percv * 2 + hi * 1.5 + K.env.kick * 1.5
      cable(lv, x0, y0, x1, y1, (x0 + x1) / 2 + sway, my + 8, 7, k <= 1)
      put(lv + 3, x0 - 1, y0 - 2, 2, 2); put(lv + 3, x1 - 1, y1 - 2, 2, 2)
    end
  end

  ------------------------------------------------------------------
  -- view 2: the modular wall
  ------------------------------------------------------------------
  local function knob2(x, y, val, lv)
    K.ring(1.2 + lv * 0.3, x, y, 3.5, 8)
    local a = math.pi * 0.75 + clamp(val, 0, 1) * math.pi * 1.5
    line(4 + lv * 1.5, x, y, x + math.cos(a) * 3.5, y + math.sin(a) * 3.5)
  end

  local function scope2(m, fn, lv, n, glow)
    local x0, x1 = MODX[m] + 3, MODX[m] + MODW - 3
    local cy = (SCY0 + SCY1) / 2
    -- the phosphor's backlight, lit by the band this module hears: a bloom
    -- about the centre line that opens as the band comes up
    if glow and glow > 0.05 then
      local h = math.floor(clamp(1 + glow * 13 + 1.5 * math.sin(K.T * 2.3 + m), 1, SCY1 - SCY0 + 1) + 0.5)
      put(1 + glow * 0.8, x0, math.floor(cy - h / 2 + 0.5), x1 - x0 + 1, h)
    end
    line(1.2, x0 - 1, SCY0 - 1, x1 + 1, SCY0 - 1)
    line(1.2, x0 - 1, SCY1 + 1, x1 + 1, SCY1 + 1)
    line(2.5, x0 - 1, SCY0 - 1, x0 - 1, SCY1 + 1)
    line(2.5, x1 + 1, SCY0 - 1, x1 + 1, SCY1 + 1)
    K.dashes(1, math.floor(cy), 1, 3, 0, x0, x1)
    -- the beam sweeping the screen, a short phosphor tail behind it
    local bu = (K.T * (0.9 + m * 0.13) + m * 0.31) % 1
    local px, py
    for k = 0, n do
      local u = k / n
      local x = x0 + (x1 - x0) * u
      local y = clamp(cy - fn(u) * (SCY1 - SCY0) * 0.45, SCY0, SCY1)
      local behind = bu - u
      local tl = (behind >= 0 and behind < 0.25) and (1 - behind / 0.25) * 2 or 0
      if px then line(lv + tl, px, py, x, y) end
      px, py = x, y
    end
    local bx = x0 + (x1 - x0) * bu
    put(lv + 4, bx, clamp(cy - fn(bu) * (SCY1 - SCY0) * 0.45, SCY0, SCY1), 1, 1)
  end

  local function wall(S)
    local T, e, c = K.T, K.energy, K.chaos
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless

    -- the modules: panel edges, screws; the panels' edges light with the level
    for m = 1, 4 do
      local x = MODX[m]
      line(1.5 + amp * 3, x, 0, x, 63)
      line(0.8 + amp * 1.5, x + MODW, 0, x + MODW, 63)
      put(1.5 + amp * 4, x + 3, 1, 2, 1); put(1.5 + amp * 4, x + MODW - 4, 62, 2, 1)
    end

    -- module 1: the kick's oscillator. a sine dropping in pitch, dying away;
    -- between kicks (and kickless) a slow LFO idles on the screen
    local kt = kick_t
    local fold = 1 + c * 2.5
    local idle = kt > 0.9 or kl > 0.5 and kt > 0.5
    local sweep = clamp(kt / 0.12, 0, 1)
    local kfade = math.exp(-kt / 0.7)
    scope2(1, function(u)
      if idle then return math.sin(u * K.TAU * 1.5 + T * 2) * (0.3 + lo * 0.4 + e * 0.1) end
      local cyc = 2 * u + 1.3 * (1 - math.exp(-u * 8))
      local y = math.sin(cyc * K.TAU) * math.exp(-u * (2.6 - e * 1.4)) * (0.5 + kick_v * 0.5)
      if u > sweep then y = y * 0.4 end
      if fold > 1.05 then y = math.sin(y * fold) / math.sin(math.min(1.5, fold)) end
      return y * (0.35 + 0.65 * kfade) + (lo - 0.3) * 0.1
    end, idle and 3.5 or (3.5 + kfade * sweep * 3.5 + e * 0.5), 22, lo)
    knob2(MODX[1] + 8, 32, 0.3 + e * 0.5 + 0.05 * math.sin(T * 0.5), e)
    knob2(MODX[1] + 22, 32, 0.6 - kl * 0.4, e)
    knob2(MODX[1] + 15, 41, 0.2 + lo * 0.6, e)

    -- module 2: the snare. a tone and noise burst
    local st = snare_t
    local sfade = math.exp(-st / 0.5)
    local ssweep = clamp(st / 0.1, 0, 1)
    scope2(2, function(u)
      local env = math.exp(-u * 4.5) * (0.4 + snare_v * 0.6)
      local nz = K.hash(math.floor(u * 44) + snare_n * 97, 5) - 0.5
      local y = (math.sin(u * K.TAU * 5) * 0.45 + nz * 1.5) * env
      if u > ssweep then y = y * 0.4 end
      y = y * (0.25 + 0.75 * sfade) + (K.hash(math.floor(u * 22) + math.floor(T * 6) * 7, 6) - 0.5) * (mid * 0.15 + 0.04)
      if c > 0.3 then y = y + math.sin(u * 30 + T * 6) * c * 0.2 end
      return y
    end, 3 + sfade * ssweep * 3.5 + e * 0.5, 22, mid)
    knob2(MODX[2] + 8, 32, 0.4 + mid * 0.4, e)
    knob2(MODX[2] + 22, 32, 0.5 + K.env.snare * 0.3, e)
    line(1.5, MODX[2] + 15, 37, MODX[2] + 15, 45)
    put(5 + e * 3, MODX[2] + 13, 44 - e * 7, 5, 2)

    -- module 3: the sequencer. eight lamps in two columns, one running;
    -- four bar lamps count the bars; a fill runs them all
    local step = math.floor(K.stepf)
    if not K.playing then step = math.floor(T * 2) end
    if step ~= seq_seen then
      seq_seen = step
      if c > 0.3 and K.rnd() < c * 0.5 then seq_i = (seq_i + 1 + math.floor(K.rnd() * 3)) % 8
      else seq_i = (seq_i + 1) % 8 end
    end
    local chase = fill_t < 1.2 and math.floor(fill_t * 20) % 8 or -1
    for s = 0, 7 do
      local col, row = s // 4, s % 4
      local x, y = MODX[3] + 8 + col * 14, 6 + row * 8
      local on = s == seq_i or s == chase
      K.ring(1 + amp * 0.8 + (on and 3 or 0), x + 1, y + 1, 2.6, 6)
      put(on and (10 + K.env.kick * 2) or (1 + amp * 1.5), x, y, 3, 3)
      local kv = K.hash(s, 31)
      local a = math.pi * 0.75 + kv * math.pi * 1.5 + (c > 0.4 and math.sin(T * 3 + s) * c or 0)
      line(2 + e, x + 7, y + 1, x + 7 + math.cos(a) * 2.5, y + 1 + math.sin(a) * 2.5)
    end
    for b = 0, 3 do
      local on = (bar_n % 4) == b
      put(on and (3 + K.bar_pulse * 7) or 1.2, MODX[3] + 7 + b * 5, 40, 3, 2)
    end

    -- module 4: the hats' envelope scope: spikes that slide off
    scope2(4, function(u)
      local y = -0.85 + hi * 0.15 + 0.04 * math.sin(u * 40 + T * 9)
      for _, H in ipairs(hat_spikes) do
        local age = K.T - H.t0
        local hx = 1 - age / 1.2
        if hx > 0 and u <= hx then
          local d = (hx - u) * (H.open and 6 or 18)
          y = y + H.v * 1.7 * math.exp(-d * 2.5)
        end
      end
      return math.min(y, 1)
    end, 3.5 + hatv * 2.5 + e * 0.5, 20, hi)
    for i = #hat_spikes, 1, -1 do if K.T - hat_spikes[i].t0 > 1.2 then table.remove(hat_spikes, i) end end
    knob2(MODX[4] + 8, 32, 0.25 + hi * 0.6, e)
    knob2(MODX[4] + 22, 32, 0.5 + math.sin(T * 0.4) * 0.1, e)

    -- the patch points, pulsing with their voice
    for m = 1, 4 do
      for j, P in ipairs(JACK2[m]) do
        local pl = pulse[m] * (j <= 3 and 1 or 0.6)
        if m == 3 then pl = math.max(pl, jpulse[j]) end
        K.ring(1.2 + amp * 0.5 + pl * 2, P[1], P[2], 2.5, 6)
        put(1 + pl * 10, P[1], P[2], 1, 1)
      end
    end

    -- the cables, arcing between modules, swinging
    local n = clamp(math.floor(2 + e * 3 + c * 2 + 0.5), 2, #wires)
    for k = 1, n do
      local W = wires[k]
      local P, Q = JACK2[W.m1][W.j1], JACK2[W.m2][W.j2]
      local x0, y0, x1, y1 = P[1], P[2], Q[1], Q[2]
      local my = math.max(y0, y1) + W.sag + 4
      local mx = (x0 + x1) / 2 + W.sw + math.sin(T * 0.9 + k) * 2.5
      local lv = 2 + (k % 2) * 0.8 + pulse[W.m1] * 1.5
      cable(lv, x0, y0, x1, y1, mx, my, 7, false)
    end
  end

  ------------------------------------------------------------------
  -- view 3: the tape machine
  ------------------------------------------------------------------
  local RLX, RRX, RY = 28, 100, 23      -- reel centres
  local FL = 20                         -- flange radius
  local HUB, PMAX = 4, 17               -- hub, full pack radius
  local GX, GY = 44, 49                 -- the guide roller
  local CPX, CPY = 86, 49               -- the capstan
  local HEADX = {54, 63, 72}            -- erase, record, play
  local TY = 51                         -- the tape over the heads

  -- the tape path as points (for the oxide marks and the glints)
  local function path(PL, PR, bow, wob)
    local lx, ly = RLX + PL * 0.72, RY + PL * 0.69
    local rx, ry = RRX - PR * 0.72, RY + PR * 0.69
    return {{lx, ly}, {GX, GY + 2}, {(GX + CPX) / 2, TY + bow + wob}, {CPX, CPY + 2}, {rx, ry}}
  end

  local function reel(cx, cy, P, ang, lit, e, c, hi, lo, idx)
    -- wow: the reel wobbles on its spindle
    local wx = c > 0.2 and math.sin(K.T * 2.1 + idx) * (c - 0.2) * 1.8 or 0
    local wy = c > 0.2 and math.cos(K.T * 1.7 + idx * 2) * (c - 0.2) * 1.2 or 0
    cx, cy = cx + wx, cy + wy
    -- the pack: a dark mass of wound tape, its layers as rings
    K.disc(1, cx, cy, P)
    local nl = 0
    for r = HUB + 2.5, P - 1, 2.8 do
      nl = nl + 1
      local lv = 1.5 + (nl % 2) * 0.5 + lo * 0.4 + e * 0.2
      K.ring(lv, cx, cy, r, math.floor(10 + r * 0.6))
    end
    if P > HUB + 2 then K.ring(2 + lit * 2 + e * 0.5, cx, cy, P, math.floor(12 + P * 0.6), ang, ang + K.TAU, 1, 0.4, idx) end
    -- the flange: a rim with three windows (spokes) turning
    K.ring(2.2, cx, cy, FL, 26)
    for s = 0, 2 do
      local a = ang + s * K.TAU / 3
      local ca, sa = math.cos(a), math.sin(a)
      line(2 + lit * 0.5, cx + ca * (HUB + 1), cy + sa * (HUB + 1), cx + ca * (FL - 1), cy + sa * (FL - 1))
      local a2 = a + 0.5
      put(1.5 + e, cx + math.cos(a2) * (FL - 2.5), cy + math.sin(a2) * (FL - 2.5), 1, 1)
    end
    -- the highs: a glint of the room light on the flange (fixed in the room)
    K.ring(1.5 + hi * 4, cx, cy, FL, 4, -2.4, -1.7)
    -- the hub, glowing with the lows
    K.disc(2 + lo * 4 + lit * 4, cx, cy, 2.2)
    put(1, cx + math.cos(ang) * 1.5, cy + math.sin(ang) * 1.5, 1, 1)
  end

  local function tapemachine(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless

    -- the transport: the wind follows the phrase; at the phrase edge it
    -- runs back (a rewind) at a limited speed
    local u_to = phrase_u(S)
    local du = u_to - tape_u
    local lim = DT * 1.6
    tape_u = clamp(tape_u + clamp(du * (1 - math.exp(-DT / 0.25)), -lim, lim), 0, 1)
    local rewinding = du < -0.05
    -- the reel speed: playing, coasting, lurching on the kick, stuttering
    if stut > 0 then
      stut_t = stut_t - DT
      if stut_t <= 0 then stut = stut - 1; stut_t = 0.05; lurch = math.max(lurch, 0.7) end
    end
    local base = (K.playing and 1 or 0.35) * (0.7 + e * 0.7) * (1 - kl * 0.55) + mid * 0.3
    local to = rewinding and -9 or base + lurch * 2.5
    spin = K.follow(spin, to, rewinding and 0.25 or 0.12, DT)
    local pk = HUB + 2
    local PL = math.sqrt(pk * pk + (PMAX * PMAX - pk * pk) * (1 - tape_u))
    local PR = math.sqrt(pk * pk + (PMAX * PMAX - pk * pk) * tape_u)
    local step = clamp(spin * DT * 1.8, -0.45, 0.45)
    -- (never more than a few px a frame at the rim, so the spokes glide)
    angL = (angL + clamp(step * 9 / math.max(PL, 5), -0.14, 0.14)) % K.TAU
    angR = (angR + clamp(step * 9 / math.max(PR, 5), -0.14, 0.14)) % K.TAU
    oxide = (oxide + spin * DT * 14) % 1000
    lurch = lurch * math.exp(-DT / 0.12)
    flutter = flutter * math.exp(-DT / 0.25)
    rec = rec * math.exp(-DT / 0.15)
    erase = erase * math.exp(-DT / 0.08)
    for i = 1, 6 do btn[i] = btn[i] * math.exp(-DT / 0.2) end

    -- the deck: a dim plate, its frame lit with the level, haze kickless
    local fl = 1 + amp * 1.5
    -- (the sides only, and corner brackets: long horizontals would jolt
    -- the whole width on a shake)
    line(fl, 0, 0, 0, 63); line(fl, 127, 0, 127, 63)
    put(fl, 1, 0, 6, 1); put(fl, 121, 0, 6, 1); put(fl, 1, 63, 6, 1); put(fl, 121, 63, 6, 1)
    for _, p in ipairs({{3, 3}, {124, 3}, {3, 60}, {124, 60}}) do put(1.5 + amp * 3, p[1], p[2], 1, 1) end
    K.haze(2, 44, 126, 62, 0.05 + kl * 0.3 + e * 0.05, 1, T * 4)

    -- the reels
    local lit = K.env.kick * (1 - kl)
    reel(RLX, RY, PL, angL, lit, e, c, hi, lo, 1)
    reel(RRX, RY, PR, angR, lit, e, c, hi, lo, 2)

    -- the tape: bowed by the kick, fluttering on the snare and with chaos
    local bow = lurch * 2.5 + (kl > 0.3 and 1.5 * kl or 0)
    local wob = math.sin(T * 23) * (flutter * 1.5 + c * 1.2)
    local P = path(PL, PR, bow, wob)
    local tl = 2.5 + mid * 2 + e
    for i = 1, #P - 1 do
      local a, b = P[i], P[i + 1]
      if i == 2 or i == 3 then
        -- the run over the heads, flutter as a ripple
        local segs = 6
        local px, py = a[1], a[2]
        for k = 1, segs do
          local t = k / segs
          local x = a[1] + (b[1] - a[1]) * t
          local y = a[2] + (b[2] - a[2]) * t + math.sin(t * math.pi * 3 + T * 30) * (flutter + c * 0.6) * 0.8 * math.sin(t * math.pi)
          line(tl, px, py, x, y)
          px, py = x, y
        end
      else
        line(tl, a[1], a[2], b[1], b[2])
      end
    end
    -- the oxide marks crawling along the tape; splices flash with chaos
    local seglen, total = {}, 0
    for i = 1, #P - 1 do
      local dx, dy = P[i + 1][1] - P[i][1], P[i + 1][2] - P[i][2]
      seglen[i] = math.sqrt(dx * dx + dy * dy)
      total = total + seglen[i]
    end
    local function at(d)
      d = d % math.max(1, total)
      for i = 1, #P - 1 do
        if d <= seglen[i] then
          local t = d / math.max(0.01, seglen[i])
          return P[i][1] + (P[i + 1][1] - P[i][1]) * t, P[i][2] + (P[i + 1][2] - P[i][2]) * t
        end
        d = d - seglen[i]
      end
      return P[#P][1], P[#P][2]
    end
    for k = 0, math.floor(total / 7) do
      local x, y = at(k * 7 + oxide % 7)
      local sp = c > 0.3 and K.hash(k + math.floor(oxide / 7), 17) < (c - 0.3) * 0.25
      put(sp and 9 or (tl + 2), x, y - 1, 1, 1)
    end
    -- open hats: glints running the length of the tape
    for i = #tglints, 1, -1 do
      local G = tglints[i]
      local v = (K.T - G.t0) / 0.6
      if v >= 1 or v < 0 then table.remove(tglints, i)
      else
        local x, y = at(v * total)
        put((6 + 6 * G.v) * math.sin(math.pi * v), x - 1, y - 1, 3, 1)
      end
    end

    -- the guide roller and the capstan with its pinch roller
    K.ring(3 + mid * 2, GX, GY, 2.5, 8)
    K.disc(3 + amp * 3, CPX, CPY, 1.6)
    local lift = kl * 3
    local pa = angR * 2
    K.ring(3 + lurch * 3, CPX, CPY - 4.5 - lift, 2.8, 8)
    put(5, CPX + math.cos(pa) * 1.8, CPY - 4.5 - lift + math.sin(pa) * 1.8, 1, 1)

    -- the head block: erase (hats), record (snare), play (kick)
    line(1.5, HEADX[1] - 4, TY + 7, HEADX[3] + 6, TY + 7)
    local hl = {1.5 + erase * 9 + hi * 3, 1.5 + rec * 9 + mid * 3, 1.5 + lit * 9 + lo * 3}
    for i = 1, 3 do
      local x = HEADX[i]
      put(1 + hl[i] * 0.2, x, TY + 2, 5, 4)
      line(hl[i], x, TY + 1, x + 4, TY + 1)
    end
    if erase > 0.2 then put(erase * 11, HEADX[1] + 2, TY - 1, 1, 1) end
    -- the record lamp
    put(1.5 + rec * 10, 64, 4, 2, 2)
    K.ring(1.5, 65, 5, 2.5, 6)

    -- the transport buttons: perc kinds, a fill runs them
    local chase = fill_t < 1.2 and math.floor(fill_t * 15) % 6 + 1 or 0
    for i = 1, 6 do
      local x = 37 + (i - 1) * 9
      local lv = 1.5 + btn[i] * 9 + (i == chase and 7 or 0)
      if i == 3 and K.playing then lv = math.max(lv, 3 + K.env.kick * 2) end
      put(lv, x, 60, 7, 2)
    end

    -- the meters: bass on the left, treble on the right, peak lights on the bar
    local ml = clamp(lo * 0.8 + K.env.kick * 0.3, 0, 1)
    local mr = clamp(hi * 0.8 + K.env.hat * 0.3 + K.env.ohat * 0.2, 0, 1)
    for s, v in ipairs({ml, mr}) do
      local x0 = s == 1 and 4 or 99
      for q = 0, 11 do
        local on = q / 12 < v
        put(on and (2 + q * 0.3) or 1, x0 + q * 2, 58, 1, 3)
      end
      put(1.5 + K.bar_pulse * 8, x0 + 25, 58, 1, 3)
    end
    -- pilot lamps with the level
    put(1.5 + amp * 6, 60, 13, 1, 1); put(1.5 + amp * 6, 67, 13, 1, 1)
    -- the tape counter: four wheels rolling with the run
    for d = 0, 3 do
      local x = 55 + d * 4
      local r = (oxide / (10 ^ (3 - d) * 0.5)) % 10
      local f = r % 1
      put(1.2, x, 20, 3, 6)
      put(3 + K.bar_pulse * 3, x + 1, 21 + f * 3, 1, 2)
    end
    -- dust in the light over the deck
    K.grain(function(a, b) return 8 + a * 112, 2 + b * 44 end, 5 + e * 8 + hi * 10, 3 + hi * 3)
  end

  ------------------------------------------------------------------
  function M.draw(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    needles(DT, T, e, c)
    pendulums(cables, DT)
    pendulums(wires, DT)
    clip = clip * math.exp(-DT / 0.2)
    hatv = hatv * math.exp(-DT / 0.1)
    percv = percv * math.exp(-DT / 0.15)
    ohat = ohat * math.exp(-DT / 0.25)
    kick_t, snare_t = kick_t + DT, snare_t + DT
    fill_t = fill_t + DT
    for m = 1, 4 do pulse[m] = pulse[m] * math.exp(-DT / 0.12) end
    for j = 1, 5 do jpulse[j] = jpulse[j] * math.exp(-DT / 0.15) end
    for j = 1, NJ do jflash[j] = jflash[j] * math.exp(-DT / 0.15) end
    if K.view == 2 then wall(S) elseif K.view == 3 then tapemachine(S) else rack(S) end
  end

  M.init()
  return M
end
