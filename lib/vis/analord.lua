-- analord. view 1: a rack of analog gear at night, a meter bridge of three
-- warm VU meters over a lamp strip and a patch bay whose cables hang and
-- swing in front; view 2: close up on a modular synth wall, oscillators
-- drawing their waves on small scopes, patch points pulsing, a sequencer
-- lamp running and cables swinging between the modules.
--
-- view 1: the rack stands between its rails, each unit's faceplate lit
-- along its top edge and shadowed under it. the meters (kick, snare, hats)
-- glow from behind, their needles thrown by the hits with real VU
-- ballistics, a little overshoot and a shadow on the face. the lamp strip
-- runs the sixteen steps, with a lamp for each voice and a clip lamp on
-- the peaks. the cables hang from the bay in loops that run off the
-- bottom, each a pendulum: the kick swings them all, the snare and perc
-- swing a few, and they cast a faint shadow on the panel behind. energy
-- patches in more cables and lifts the meters' glow, chaos makes the
-- needles chatter and re-patches the bay, a ratchet rattles a needle once
-- for every repeat; kickless the kick meter sleeps and the cables settle.
--
-- view 2: four modules fill the wall: the kick's oscillator (a sine that
-- drops in pitch and dies away on its scope), the snare's noise and tone,
-- a sequencer with eight lamps in two columns, and the hats' envelope
-- scope with its spikes. jacks pulse with the voice they carry; cables
-- arc between them and swing. energy turns the knobs up and brightens the
-- scopes, chaos folds the waves, skips the sequencer and patches more
-- cables; kickless the kick's scope idles as a slow LFO.
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
  -- which voice each module carries: kick, snare, seq, hats
  local WBASE = {{1, 3, 2, 1, 9}, {2, 3, 4, 1, 12}, {3, 2, 1, 4, 8}, {4, 2, 2, 5, 10},
    {3, 5, 4, 4, 7}, {1, 5, 3, 1, 11}}

  local kick_t, snare_t, kick_v, snare_v = 99, 99, 0, 0
  local snare_n = 0
  local hat_spikes = {}
  local seq_i, seq_seen = 0, -1
  local pulse = {0, 0, 0, 0}            -- each module's jacks

  function M.init()
    ndl, vel, buzz, buzz_t, lamp, ghost_a = {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}
    clip, hatv, percv = 0, 0, 0
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
    v = K.num(v, 1)
    throw(1, v)
    swing(cables, 22 * v)
    swing(wires, 16 * v)
    kick_t, kick_v = 0, v
    pulse[1] = 1
  end
  function M.snare(v)
    v = K.num(v, 1)
    throw(2, v)
    swing(cables, 14 * v, 2)
    swing(wires, 10 * v, 2)
    snare_t, snare_v = 0, v
    snare_n = snare_n + 1
    pulse[2] = 1
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8) end
  function M.rim(v) throw(2, K.num(v, 1) * 0.4); pulse[2] = math.max(pulse[2], 0.5) end
  function M.hat(v, open)
    v = K.num(v, 1)
    throw(3, v * (open and 0.9 or 0.5))
    hatv = 1
    pulse[4] = math.max(pulse[4], open and 1 or 0.6)
    if #hat_spikes >= 10 then table.remove(hat_spikes, 1) end
    hat_spikes[#hat_spikes + 1] = {t0 = K.T, v = v, open = open}
  end
  function M.perc(_, v)
    v = K.num(v, 1)
    throw(3, v * 0.3)
    lamp[2] = math.max(lamp[2], 0.5)
    percv = 1
    swing(cables, 6 * v, 3)
    pulse[3] = math.max(pulse[3], 0.7)
  end
  function M.tom(v) throw(1, K.num(v, 1) * 0.5); swing(cables, 8 * K.num(v, 1), 3) end
  function M.tick() pulse[3] = math.max(pulse[3], 0.5) end

  function M.ratchet(n, voice)
    local m = voice == "kick" and 1 or ((voice == "hat" or voice == "tick") and 3 or 2)
    n = clamp(math.floor(K.num(n, 2)), 1, 16)
    buzz[m], buzz_t[m] = n, 0
    ghost_a[m] = 1
    lamp[m] = 1
  end

  -- chaos re-patches on the bar
  function M.bar()
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

  ------------------------------------------------------------------
  -- physics shared by both views
  ------------------------------------------------------------------
  local function needles(DT, T, e, c)
    local lo, hi = A[K.LO], A[K.HI]
    local target = {lo * 0.6 * (1 - K.kickless * 0.7) + K.env.kick * 0.3,
      A[K.MID] * 0.5 + K.env.snare * 0.3, hi * 0.6 + K.env.hat * 0.3}
    for m = 1, 3 do
      local to = target[m] * (0.6 + 0.5 * e) + 0.03
      if buzz[m] > 0 then
        buzz_t[m] = buzz_t[m] - DT
        if buzz_t[m] <= 0 then vel[m] = vel[m] + 4; buzz[m] = buzz[m] - 1; buzz_t[m] = 0.05; lamp[m] = 1 end
      end
      ghost_a[m] = ghost_a[m] * math.exp(-DT / 0.35)
      to = to + 0.012 * math.sin(T * 5.1 + m * 2)
      if c > 0.2 then to = to + math.sin(T * (17 + m * 3) + m) * c * 0.12 end
      -- VU ballistics: a stiff, slightly underdamped spring
      local acc = (to - ndl[m]) * 260 - vel[m] * 15
      vel[m] = vel[m] + acc * DT
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
    -- the face: a warm glow from behind, brighter in the middle
    local glow = 1.1 + e * 0.5 + lamp[m] * 0.6 + val * 0.4 + 0.05 * math.sin(K.T * 7.3 + m)
    K.gradient(MY + 1, MY + 11, function(y)
      return glow * (1 - 0.25 * (y - MY) / 11)
    end, nil, x0 + 1, x0 + MW)
    -- the bezel
    line(3, x0 - 1, MY - 1, x0 + MW + 1, MY - 1)
    line(1.5, x0 - 1, yb + 1, x0 + MW + 1, yb + 1)
    line(2, x0 - 1, MY - 1, x0 - 1, yb + 1)
    line(2, x0 + MW + 1, MY - 1, x0 + MW + 1, yb + 1)
    -- the scale: an arc of ticks, the last third hot
    K.ring(3.5, cx, cy, R - 4, 10, -math.pi / 2 - SPAN, -math.pi / 2 + SPAN * 0.4)
    K.ring(5, cx, cy, R - 4, 5, -math.pi / 2 + SPAN * 0.4, -math.pi / 2 + SPAN)
    for k = 0, 8 do
      local a = -math.pi / 2 - SPAN + 2 * SPAN * k / 8
      local r1 = R - 4
      local r0 = r1 + (k % 4 == 0 and 3 or 1.5)
      line(k >= 6 and 6 or 4, cx + math.cos(a) * r1, cy + math.sin(a) * r1, cx + math.cos(a) * r0, cy + math.sin(a) * r0)
    end
    -- the needle's shadow, then the needle, from its pivot below the face
    local a = -math.pi / 2 - SPAN - 0.05 + (2 * SPAN + 0.1) * clamp(val, 0, 1.08)
    local ca, sa = math.cos(a), math.sin(a)
    local r0 = math.max(11, (cy - yb + 2) / math.max(0.2, -sa))
    if ghost_a[m] > 0.05 then
      local ga = a - 0.12 * ghost_a[m]
      line(3 * ghost_a[m], cx + math.cos(ga) * r0, cy + math.sin(ga) * r0, cx + math.cos(ga) * (R - 2), cy + math.sin(ga) * (R - 2))
    end
    line(0.6, cx + ca * r0 + 2, cy + sa * r0 + 1, cx + ca * (R - 1) + 2, cy + sa * (R - 1) + 1)
    line(11 + lamp[m] * 1.5, cx + ca * r0, cy + sa * r0, cx + ca * (R - 1), cy + sa * (R - 1))
    -- the pivot's cover and the lamp
    put(3, cx - 4, yb - 2, 9, 2)
    put(1.5 + lamp[m] * 9, x0 + MW - 3, MY + 1, 2, 2)
  end

  local function rack(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi = A[K.LO], A[K.HI]

    -- the rails, their holes
    for _, x in ipairs({2, 122}) do
      line(2, x, 0, x, 63)
      line(2, x + 4, 0, x + 4, 63)
      for y = 3, 63, 7 do put(1, x + 1, y, 3, 2) end
    end
    -- the units: lit top edge, shadow gap under
    for _, u in ipairs({{0, 27}, {LY - 1, 9}, {39, 25}}) do
      local y0, h = u[1], u[2]
      line(2.5 + K.bar_pulse * 0.5, 8, y0, 120, y0)
      put(2, 10, y0 + 2, 1, 1); put(2, 117, y0 + 2, 1, 1)
    end

    -- the meter bridge
    for m = 1, 3 do meter(m, MX[m], ndl[m], e) end

    -- the lamp strip: sixteen steps, three voice lamps, a clip lamp
    local step = math.floor(K.stepf) % 16
    if not K.playing then step = math.floor(T * 2) % 16 end
    for s = 0, 15 do
      local on = s == step
      local l = 1.2 + (s % 4 == 0 and 0.8 or 0)
      if on then l = 9 + K.env.kick * 2 end
      put(l, 14 + s * 5, LY + 3, 3, 2)
    end
    for m = 1, 3 do put(1.5 + lamp[m] * 9, 98 + (m - 1) * 5, LY + 3, 3, 2) end
    put(1 + clip * 10, 113, LY + 3, 3, 2)

    -- the bay: jacks
    for r = 1, 2 do
      for j = 1, NJ do
        local lv = 2.5 + (r == 1 and lamp[1 + (j - 1) % 3] * 3 or 0)
        K.ring(lv, JX[j], JY[r], 2, 6)
      end
    end
    -- a power lamp, breathing
    put(1.5 + 2 * (0.5 + 0.5 * math.sin(T * 0.9)), 9, 45, 2, 1)
    -- dust drifting in the meters' light
    K.grain(function(u, v) return 9 + u * 110, 2 + v * 34 end, 10 + e * 10 + hi * 10, 3 + hi * 3)

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
      cable(lv, x0, y0, x1, y1, (x0 + x1) / 2 + sway, my + 8, 8, true)
      put(lv + 3, x0 - 1, y0 - 2, 2, 2); put(lv + 3, x1 - 1, y1 - 2, 2, 2)
    end
  end

  ------------------------------------------------------------------
  -- view 2: the modular wall
  ------------------------------------------------------------------
  local function knob2(x, y, val, lv)
    K.ring(1.2 + lv * 0.3, x, y, 3.5, 8)
    local a = math.pi * 0.75 + clamp(val, 0, 1) * math.pi * 1.5
    line(5 + lv * 2, x, y, x + math.cos(a) * 3.5, y + math.sin(a) * 3.5)
  end

  local function scope2(m, fn, lv, n)
    local x0, x1 = MODX[m] + 3, MODX[m] + MODW - 3
    local cy = (SCY0 + SCY1) / 2
    -- the screen: its bezel and a centre line
    line(1.2, x0 - 1, SCY0 - 1, x1 + 1, SCY0 - 1)
    line(1.2, x0 - 1, SCY1 + 1, x1 + 1, SCY1 + 1)
    line(2.5, x0 - 1, SCY0 - 1, x0 - 1, SCY1 + 1)
    line(2.5, x1 + 1, SCY0 - 1, x1 + 1, SCY1 + 1)
    K.dashes(1, math.floor(cy), 1, 3, 0, x0, x1)
    local px, py
    for k = 0, n do
      local u = k / n
      local x = x0 + (x1 - x0) * u
      local y = clamp(cy - fn(u) * (SCY1 - SCY0) * 0.45, SCY0, SCY1)
      if px then line(lv, px, py, x, y) end
      px, py = x, y
    end
  end

  local function wall(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    local kl = K.kickless

    -- the modules: panel edges (vertical, they run off the top and bottom),
    -- the screws, a rail across the top
    for m = 1, 4 do
      local x = MODX[m]
      line(2, x, 0, x, 63)
      line(1, x + MODW, 0, x + MODW, 63)
      put(2, x + 3, 1, 2, 1); put(2, x + MODW - 4, 62, 2, 1)
    end

    -- module 1: the kick's oscillator. a sine dropping in pitch, dying away
    local kt = kick_t
    local fold = 1 + c * 2.5
    local idle = kl > 0.5 and kt > 1
    local sweep = clamp(kt / 0.12, 0, 1)
    local kfade = math.exp(-kt / 0.7)
    scope2(1, function(u)
      if idle then return math.sin(u * K.TAU * 1.5 + T * 2) * (0.35 + lo * 0.4) end
      -- the 808's body: a sine whose pitch drops fast, dying away
      local cyc = 2 * u + 1.3 * (1 - math.exp(-u * 8))
      local y = math.sin(cyc * K.TAU) * math.exp(-u * (2.6 - e * 1.4)) * (0.5 + kick_v * 0.5)
      if u > sweep then y = y * 0.4 end
      if fold > 1.05 then y = math.sin(y * fold) / math.sin(math.min(1.5, fold)) end
      return y * (0.35 + 0.65 * kfade) + (lo - 0.3) * 0.1
    end, idle and 5 or (4 + kfade * sweep * 4.5 + e), 22)
    knob2(MODX[1] + 8, 32, 0.3 + e * 0.5, e)
    knob2(MODX[1] + 22, 32, 0.6 - kl * 0.4, e)
    knob2(MODX[1] + 15, 41, 0.2 + lo * 0.6, e)

    -- module 2: the snare. a tone and noise burst
    local st = snare_t
    local sfade = math.exp(-st / 0.5)
    local ssweep = clamp(st / 0.1, 0, 1)
    scope2(2, function(u)
      -- the snare: a tone under a burst of noise, fixed for each hit
      local env = math.exp(-u * 4.5) * (0.4 + snare_v * 0.6)
      local nz = K.hash(math.floor(u * 44) + snare_n * 97, 5) - 0.5
      local y = (math.sin(u * K.TAU * 5) * 0.45 + nz * 1.5) * env
      if u > ssweep then y = y * 0.4 end
      y = y * (0.25 + 0.75 * sfade) + (K.hash(math.floor(u * 22) + math.floor(T * 6) * 7, 6) - 0.5) * mid * 0.15
      if c > 0.3 then y = y + math.sin(u * 30 + T * 6) * c * 0.2 end
      return y
    end, 3.5 + sfade * ssweep * 4.5 + e, 22)
    knob2(MODX[2] + 8, 32, 0.4 + mid * 0.4, e)
    knob2(MODX[2] + 22, 32, 0.5 + K.env.snare * 0.3, e)
    -- a slider: the snare's decay, its cap riding with energy
    line(1.5, MODX[2] + 15, 37, MODX[2] + 15, 45)
    put(5 + e * 3, MODX[2] + 13, 44 - e * 7, 5, 2)

    -- module 3: the sequencer. eight lamps in two columns, one running
    local step = math.floor(K.stepf)
    if not K.playing then step = math.floor(T * 2) end
    if step ~= seq_seen then
      seq_seen = step
      if c > 0.3 and K.rnd() < c * 0.5 then seq_i = (seq_i + 1 + math.floor(K.rnd() * 3)) % 8
      else seq_i = (seq_i + 1) % 8 end
    end
    for s = 0, 7 do
      local col, row = s // 4, s % 4
      local x, y = MODX[3] + 8 + col * 14, 6 + row * 9
      local on = s == seq_i
      K.ring(1.2 + (on and 3 or 0), x + 1, y + 1, 2.6, 6)
      put(on and (10 + K.env.kick * 3) or 1.2, x, y, 3, 3)
      -- each step's pitch knob, a tick beside its lamp
      local kv = K.hash(s, 31)
      local a = math.pi * 0.75 + kv * math.pi * 1.5
      line(2 + e, x + 7, y + 1, x + 7 + math.cos(a) * 2.5, y + 1 + math.sin(a) * 2.5)
    end
    put(1.5 + K.bar_pulse * 8, MODX[3] + 14, 42, 3, 2)

    -- module 4: the hats' envelope scope: spikes that slide off
    scope2(4, function(u)
      local y = -0.85 + hi * 0.15
      for _, H in ipairs(hat_spikes) do
        local age = K.T - H.t0
        local hx = 1 - age / 1.2
        if hx > 0 and u <= hx then
          local d = (hx - u) * (H.open and 6 or 18)
          y = y + H.v * 1.7 * math.exp(-d * 2.5)
        end
      end
      return math.min(y, 1)
    end, 4 + hatv * 3 + e, 20)
    for i = #hat_spikes, 1, -1 do if K.T - hat_spikes[i].t0 > 1.2 then table.remove(hat_spikes, i) end end
    knob2(MODX[4] + 8, 32, 0.25 + hi * 0.6, e)
    knob2(MODX[4] + 22, 32, 0.5 + math.sin(T * 0.4) * 0.1, e)

    -- the patch points, pulsing with their voice
    for m = 1, 4 do
      for j, P in ipairs(JACK2[m]) do
        local pl = pulse[m] * (j <= 3 and 1 or 0.6)
        K.ring(1.2 + pl * 3, P[1], P[2], 2.5, 6)
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
      local mx = (x0 + x1) / 2 + W.sw + math.sin(T * 0.9 + k) * 1.5
      local lv = 2.5 + (k % 2) + pulse[W.m1] * 2
      cable(lv, x0, y0, x1, y1, mx, my, 7, false)
    end
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
    kick_t, snare_t = kick_t + DT, snare_t + DT
    for m = 1, 4 do pulse[m] = pulse[m] * math.exp(-DT / 0.12) end
    if K.view == 2 then wall(S) else rack(S) end
  end

  M.init()
  return M
end
