-- acoustic. view 1: a robot drum rig, solenoid arms on a frame striking a kick, a snare, toms, wood blocks, a hi-hat, tines and a bell.
-- view 2: inside an open grand piano from the keyboard end: hammers strike strings that ring as standing waves, some strings bolted.
-- view 3: a drum head from straight above with sand on it: every strike throws the sand up and it settles on the head's nodal figure.
--
-- view 1: every voice has its own arm. it fires down onto its drum and
-- springs back (a pulse runs out along its cable from the controller first),
-- the head it hits rings out in a ripple; a ratchet makes the arm buzz
-- against the head that many times. kick, snare, toms (low or high by
-- pitch), log perc on the wood blocks, metal and cowbell on the bell,
-- plinks on the tines, hats on the hat; ticks blink the controller. energy
-- brightens the work lamp and the heads; chaos jolts the frame, misfires
-- spare arms and ghosts them; kickless, the kick arm parks up.
-- view 2: kicks hit the bass strings and thump the board; toms land on a
-- string by their pitch; plinks on the treble; snares on the middle with a
-- paper rattle; metal perc rings the bolted strings; log perc knocks the
-- case; hats shimmer the top. each string rings as a standing wave (a
-- bolted one with a node at its bolt) and dies away, its damper lifting.
-- a ratchet re-strikes the hammer. energy sustains longer; chaos sets the
-- whole frame ringing in sympathy and in higher modes. open hats shimmer the
-- top strings, closed hats tick one; a program counter on view 1's beam
-- counts the phrase, and its last two bars put the sustain pedal down
-- (every damper lifts, the strings ring on); a fill does too.
-- view 3: the head is tuned to a figure (nodal diameters and rings), new
-- every two bars: plain at the top of the phrase, more intricate toward its
-- end, while a lamp's light rakes across and the lugs count the phrase
-- round. the kick throws all the sand, snares (and the wires buzzing under
-- the head), claps, rims and toms throw it near where they land; the sand
-- creeps back to the still lines, so the figure draws itself again after
-- every hit. the hi-hat at the corner clamps shut or parts and wobbles
-- open; the floor tom, wood block and cowbell answer their perc; a ratchet
-- rolls a buzz of strikes. the mids keep the figure singing between hits,
-- the lows pour more sand on, the highs sparkle it, the level lights the
-- hoop. energy pours more sand and sustains it; chaos sets a second figure
-- fighting the first and jolts the hoop; a fill spins the figure; kickless
-- a brush sweeps round dragging the sand with it.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  ---------------------------------------------------------------- view 1
  local BEAM = 6                         -- the frame's top beam
  local FLOOR = 60
  -- the instruments: kind, centre, size; arm pivot on the beam and the
  -- angles of the arm at rest and at the strike
  local INST = {
    kick  = {x = 62, y = 44, r = 14, sq = 1, px = 62, py = BEAM + 2, len = 22, rest = -0.5, hit = 0},
    snare = {x = 32, y = 44, r = 10, sq = 0.35, px = 24, py = BEAM + 2, len = 34, rest = 0.85, hit = 1.25},
    tom1  = {x = 44, y = 25, r = 7, sq = 0.4, px = 40, py = BEAM + 2, len = 15, rest = 0.75, hit = 1.3},
    tom2  = {x = 80, y = 25, r = 7, sq = 0.4, px = 84, py = BEAM + 2, len = 15, rest = 2.4, hit = 1.85},
    wood  = {x = 101, y = 34, r = 5, sq = 0.5, px = 106, py = BEAM + 2, len = 25, rest = 2.0, hit = 1.75},
    bell  = {x = 115, y = 48, r = 5, sq = 1, px = 124, py = BEAM + 2, len = 39, rest = 2.0, hit = 1.8},
    hat   = {x = 12, y = 22, r = 7, sq = 0.3, px = 6, py = BEAM + 2, len = 15, rest = 0.85, hit = 1.2},
    tines = {x = 96, y = 54, r = 6, sq = 1, px = 88, py = BEAM + 2, len = 46, rest = 1.15, hit = 1.38},
  }
  local ORDER = {"kick", "snare", "tom1", "tom2", "wood", "bell", "hat", "tines"}
  local BOX_X, BOX_Y = 4, 50             -- the controller

  ---------------------------------------------------------------- view 2
  local NS = 16                          -- strings, bass (left) to treble
  local SX0, SDX = 9, 7                  -- string x = SX0 + i * SDX
  local SBOT = 52                        -- where the hammers strike (bottom)
  local BOLTS = {[2] = 0.45, [5] = 0.6, [9] = 0.35, [12] = 0.55}   -- prepared strings
  local function s_x(i) return SX0 + i * SDX end
  local function s_top(i) return 3 + i * 2.1 end

  -- where we are in the phrase, 0..1
  local function phrase_u(S)
    if type(S) ~= "table" then return 0 end
    local pl = math.max(1, math.floor(K.num(S.phrase_len, 16) or 16))
    local u = (K.num(S.phrase_pos, 0) or 0) % pl / pl
    if not (u >= 0 and u <= 1) then u = 0 end
    return u
  end

  ---------------------------------------------------------------- view 3
  local HX, HY, HR = 64, 32, 27          -- the big head, from straight above
  local NG = 260                         -- grains of sand on it
  -- the figures the head is tuned to (m nodal diameters, n rings), simple
  -- at the top of the phrase and more intricate toward its end
  local FIGS = {{{2, 1}, {1, 2}, {0, 3}}, {{2, 2}, {3, 1}, {0, 4}},
    {{3, 2}, {4, 1}, {1, 3}}, {{4, 2}, {5, 2}, {2, 3}, {6, 1}}}
  local LUGS = 10

  local arms, rip, leds, pulses, lamp
  local amp, mode, ph, ham, rattle, board, knock
  local hopen, hclose, sustain            -- open / closed hat, the sustain pedal
  local sand, fig, fig2, drive, hrip, sched, hhat, htom, hwood, hbell, brush, wires, spin

  function M.init()
    arms, rip, pulses = {}, {}, {}
    for _, k in ipairs(ORDER) do arms[k] = {t0 = -9, v = 0, n = 0, dur = 0} end
    leds, lamp = {}, 0
    for i = 1, 8 do leds[i] = 0 end
    amp, mode, ph, ham, rattle = {}, {}, {}, {}, {}
    for i = 0, NS - 1 do amp[i], mode[i], ph[i], ham[i], rattle[i] = 0, 1, 0, -9, 0 end
    board, knock = 0, 0
    hopen, hclose, sustain = 0, 0, 0
    sand = {}
    for i = 1, NG do
      local r = math.sqrt(K.hash(i, 91)) * 0.95
      sand[i] = {r = r, a = K.hash(i, 92) * K.TAU, h = 0, j = K.hash(i, 93)}
    end
    fig, fig2, drive = {m = 2, n = 1, rot = 0.4}, {m = 3, n = 2, rot = 0}, 0
    hrip, sched = {}, {}
    hhat, htom, hwood, hbell, brush, wires, spin = 0, 0, 0, 0, 0, 0, 0
  end
  M.clear = M.init

  ---------------------------------------------------------------- events
  local function fire(k, v, n, dur)
    local a = arms[k]
    a.t0, a.v, a.n, a.dur = K.T, v, n or 1, dur or 0
    local I = INST[k]
    if #rip >= 10 then table.remove(rip, 1) end
    rip[#rip + 1] = {k = k, t0 = K.T + 0.03, v = v}
    if #pulses >= 10 then table.remove(pulses, 1) end
    pulses[#pulses + 1] = {k = k, t0 = K.T}
    leds[1 + math.floor(K.rnd() * 8)] = 1
    -- chaos: a spare arm misfires with it
    if K.chaos > 0.5 and K.rnd() < (K.chaos - 0.5) then
      local o = ORDER[1 + math.floor(K.rnd() * #ORDER)]
      if o ~= k then arms[o].t0, arms[o].v, arms[o].n, arms[o].dur = K.T + 0.04, v * 0.5, 1, 0 end
    end
  end

  local function strike(i, v, m)
    i = clamp(math.floor(i), 0, NS - 1)
    amp[i] = math.min(1.2, math.max(amp[i], v))
    mode[i] = m or 1
    ph[i] = 0
    ham[i] = K.T
  end

  local function hz_string(hz)
    -- 50 Hz .. 800 Hz across the strings, bass at the left
    local u = (math.log(clamp(hz, 40, 900)) - math.log(50)) / (math.log(800) - math.log(50))
    return clamp(math.floor(u * (NS - 1) + 0.5), 0, NS - 1)
  end

  -- (view 3) a strike on the head: it drives the figure the head is tuned
  -- to (w: how hard this voice drives it) and throws up the sand within
  -- `spread` px of the struck point (an angle, a radius 0..1)
  local function head(w, v, ang, rad, spread)
    v = clamp(K.num(v, 1), 0, 1.2)
    drive = math.min(1.4, drive + v * w)
    if #hrip >= 6 then table.remove(hrip, 1) end
    local a, r = ang or K.rnd() * K.TAU, rad or 0.5
    hrip[#hrip + 1] = {x = HX + math.cos(a) * r * HR, y = HY + math.sin(a) * r * HR, t0 = K.T, v = v,
      sp = spread or 10, new = true}
  end

  function M.kick(v)
    v = K.num(v, 1)
    fire("kick", v)
    strike(0, v); strike(1, v * 0.8)
    board = math.max(board, v)
    head(1, v, nil, 0, 99)
  end

  function M.snare(v, n)
    v, n = K.num(v, 1), K.num(n, 1)
    if n > 1 then
      -- a ratchet burst: the arm is already buzzing; each hit re-strikes
      strike(7 + math.floor(K.rnd() * 2), v * 0.6, 2)
      head(0.3, v * 0.6, nil, 0.6, 10)
      wires = 1
      return
    end
    fire("snare", v)
    strike(7, v * 0.8, 1)
    rattle[7] = 1
    head(0.6, v, nil, 0.55, 14)
    wires = 1
  end
  function M.clap(v)
    v = K.num(v, 1)
    fire("snare", v * 0.8)
    strike(6, v * 0.7, 2)
    -- the clap: three hands, a three-fold figure
    head(0.5, v, nil, 0.75, 10)
  end
  function M.rim(v)
    v = K.num(v, 1)
    fire("snare", v * 0.6); strike(8, v * 0.5, 3)
    head(0.15, v, nil, 0.95, 6)
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    fire("hat", v * (open and 1 or 0.7))
    if open then
      -- open: the cymbals part and wash; the top strings shimmer on
      hopen = math.max(hopen, v)
      for i = NS - 2, NS - 1 do strike(i, v * 0.25, 3) end
      head(0.15, v, nil, 0.85, 9)
    else
      hclose = math.max(hclose, v)
      strike(NS - 1 - math.floor(K.rnd() * 2), v * 0.35, 2)
      head(0.05, v * 0.6, nil, 0.9, 4)
    end
    hhat = math.max(hhat, v)
  end

  function M.tom(v, hz)
    v = K.num(v, 1)
    hz = K.num(hz, 120)
    fire(hz < 130 and "tom1" or "tom2", v)
    strike(hz_string(hz), v, 1)
    -- the head answers in a mode by its pitch: low toms one ring, high more
    head(0.5, v, nil, 0.35 + clamp(hz / 400, 0, 0.5), 12)
    htom = math.max(htom, v)
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    kind = math.floor(K.num(kind, 1))
    if kind == 7 or kind == 4 then
      fire("wood", v)
      knock = math.max(knock, v)
      hwood = math.max(hwood, v)
      head(0.2, v, nil, 0.92, 6)
    elseif kind == 6 or kind == 3 then
      fire("bell", v)
      local bs = {2, 5, 9, 12}
      strike(bs[1 + math.floor(K.rnd() * 4)], v, 1)
      hbell = math.max(hbell, v)
      head(0.25, v, nil, 0.8, 8)
    elseif kind == 8 then
      fire("tines", v)
      strike(9 + math.floor(K.hash(math.floor(K.T * 7), 3) * 7), v * 0.9, 1)
      head(0.2, v, nil, 0.5, 6)
    else
      -- congas, bongos and the rest: hand drums, a mode by the kind
      fire(K.rnd() < 0.5 and "tom2" or "wood", v * 0.7)
      strike(4 + math.floor(K.rnd() * 8), v * 0.6, 1)
      head(0.4, v, nil, 0.6, 10)
      htom = math.max(htom, v * 0.6)
    end
  end

  function M.tick(kind)
    for i = 1, 3 do leds[1 + math.floor(K.rnd() * 8)] = 1 end
    local bs = {2, 5, 9, 12}
    rattle[bs[1 + math.floor(K.rnd() * 4)]] = 0.6
  end

  function M.ratchet(n, voice)
    n = clamp(math.floor(K.num(n, 2)), 1, 16)
    local k = voice == "kick" and "kick" or (voice == "hat" and "hat" or (voice == "brk" and "wood" or "snare"))
    fire(k, 0.8, n, 0.06 * n)
    local i = k == "kick" and 0 or (k == "hat" and NS - 1 or 7)
    strike(i, 0.8, 2)
    rattle[i] = 1
    -- the head: a buzz roll, that many quick strikes
    for q = 0, n - 1 do
      if #sched < 16 then sched[#sched + 1] = {at = K.T + q * 0.055, k = k} end
    end
  end

  -- (view 3) each bar (or two) tunes the head to a new figure, simpler at
  -- the top of the phrase and more intricate toward its end
  function M.bar(S)
    local bar = math.floor(K.num(type(S) == "table" and S.bar, 0) or 0)
    local every = K.chaos > 0.6 and 1 or 2
    if bar % every ~= 0 then return end
    local lvl = clamp(math.floor(phrase_u(S) * 4), 0, 3) + 1
    local set = FIGS[lvl]
    local f = set[1 + math.floor(K.hash(bar, 77) * #set) % #set]
    fig.m, fig.n = f[1], f[2]
    fig.rot = K.hash(bar, 78) * K.TAU
  end

  function M.fill()
    lamp = math.max(lamp, 0.7)
    spin = 1
    sustain = math.max(sustain, 0.8)
  end

  ---------------------------------------------------------------- view 1 draw
  -- an arm's angle: fires down in 30 ms, springs back over 180 ms; a
  -- ratchet buzzes it against the head n times
  local function arm_u(k)
    local a = arms[k]
    local age = K.T - a.t0
    if age < 0 then return 0 end
    if a.n > 1 and age < a.dur then
      local per = a.dur / a.n
      local w = (age % per) / per
      return 0.55 + 0.45 * math.abs(math.cos(w * math.pi))
    end
    local t = age - (a.n > 1 and a.dur or 0)
    if t < 0.03 then return t / 0.03 end
    return math.max(0, 1 - (t - 0.03) / 0.18) ^ 2
  end

  local function draw_rig(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md = A[K.LO], A[K.HI], A[K.MID]
    local kl = K.kickless
    lamp = lamp * math.exp(-DT / 1.5)
    board = board * math.exp(-DT / 0.2)
    knock = knock * math.exp(-DT / 0.2)
    for i = 1, 8 do leds[i] = leds[i] * math.exp(-DT / 0.15) end
    local jx = 0

    -- the work lamp, hung from the beam and swaying; its pool on the wall
    local ll = 0.4 + e * 1.2 + lamp * 0.5 + lo * 0.3
    local sway = math.sin(T * 0.9) * 0.18 + math.sin(T * 0.37) * 0.08 + board * 0.05
    local lx, ly = 64 + math.sin(sway) * 9, BEAM + 1 + math.cos(sway) * 9
    line(2, 64 + jx, BEAM + 1, lx + jx, ly)
    K.ring(3 + ll * 2, lx + jx, ly + 1, 2.5, 8, 0, math.pi)
    put(math.min(11, 5 + ll * 4), lx - 1 + jx, ly + 1, 3, 1)
    local pcx = 64 + (lx - 64) * 2.5
    for dy = -8, 8 do
      local hw = 24 * math.sqrt(1 - (dy / 9) ^ 2)
      put(math.min(2, 0.6 + ll * (1 - math.abs(dy) / 12)), pcx - hw, 30 + dy, hw * 2, 1)
    end
    -- pegboard dots out in the dark
    for y = 4, 58, 6 do
      for x = 3 + (y // 6) % 2 * 3, 125, 6 do
        local dx, dy = x - 64, y - 34
        if dx * dx + dy * dy > 26 * 26 then put(1, x, y, 1, 1) end
      end
    end

    -- the frame: a beam on two legs, solenoids along it
    local bl = 3.5 + lo
    line(bl, 2 + jx, BEAM - 2, 125 + jx, BEAM - 2)
    line(bl, 2 + jx, BEAM + 1, 125 + jx, BEAM + 1)
    -- the program counter on the beam: one lamp per bar of the phrase so far
    local pu = phrase_u(S)
    for q = 0, 15 do
      local on = q < pu * 16 + 1
      put(on and (2 + (q == math.floor(pu * 16) and 3 * (1 - K.beat_ph) or 0) + e) or 1, 30 + q * 4, BEAM - 1, 2, 1)
    end
    line(3, 3 + jx, BEAM, 3 + jx, FLOOR)
    line(3, 124 + jx, BEAM, 124 + jx, FLOOR)
    line(2.5, 0, FLOOR, 127, FLOOR)

    -- the controller, its LEDs, and the cable loom up to the beam
    put(2, BOX_X + 2, BOX_Y, 14, 9)
    line(3.5, BOX_X + 2, BOX_Y, BOX_X + 15, BOX_Y)
    local scan = math.floor(T * 3) % 8 + 1
    for i = 1, 8 do
      local lv = 1.5 + leds[i] * 9 + (i % 3 == 0 and hi * 2 or 0) + (i == scan and 2 or 0)
      put(math.min(12, lv), BOX_X + 3 + ((i - 1) % 4) * 3, BOX_Y + 2 + ((i - 1) // 4) * 3, 2, 2)
    end
    line(1.5, BOX_X + 9, BOX_Y, BOX_X + 9, BEAM + 1)

    -- the instruments
    for _, k in ipairs(ORDER) do
      local I = INST[k]
      local x, y = I.x + jx, I.y
      local a = arms[k]
      local age = K.T - a.t0
      local hot = (age >= 0 and age < 0.4) and (1 - age / 0.4) * a.v or 0
      if k == "kick" then
        -- the kick from the front: a shell, a hoop, a port in the head
        -- the sub (lo) glows in the kick's head
        K.disc(1.2 + hot * 1.5 + lo * 2.2, x, y, I.r)
        K.ring(3 + e * 1.5 + hot * 4 + lo * 1.5, x, y, I.r, 22)
        K.ring(2, x, y, I.r - 2, 20)
        K.ring(2 + hot * 2, x + 5, y + 5, 2.5, 8)
        line(3, x - I.r + 2, y + I.r - 2, x - I.r - 3, FLOOR)
        line(3, x + I.r - 2, y + I.r - 2, x + I.r + 3, FLOOR)
      elseif k == "wood" then
        for b = -1, 1, 2 do
          local bx = x + b * 4
          put(1.5 + hot * 4 + knock * 2 + md * 2.5, bx - 3, y - 2, 6, 4)
          line(3 + hot * 3, bx - 3, y - 2, bx + 3, y - 2)
        end
        line(2, x - 8, y + 3, x + 8, y + 3)
        line(2, x, y + 3, x, FLOOR)
      elseif k == "bell" then
        -- a bell hung from its bracket
        local sw = hot * 0.25 * math.sin(age * 30)
        local bx = x + sw * 6
        line(2.5, x, y - 9, bx, y - 6)
        line(3.5 + hot * 5, bx - 3, y - 6, bx + 3, y - 6)
        line(3.5 + hot * 5, bx - 3, y - 6, bx - 6, y + 4)
        line(3.5 + hot * 5, bx + 3, y - 6, bx + 6, y + 4)
        line(4 + hot * 6, bx - 6, y + 4, bx + 6, y + 4)
        put(1.5 + hot * 3 + md * 2.5, bx - 4, y - 3, 9, 6)
      elseif k == "tines" then
        -- a comb of tines on a block (the plinks)
        put(2, x - 8, y + 4, 17, 3)
        for t = 0, 4 do
          local tx = x - 6 + t * 3
          -- the air (hi) keeps the tines singing
          local vib = (hot * 1.5 + hi * 0.8) * math.sin(age * 70 + t + T * 9)
          line(2.5 + hot * 7 + hi * 4, tx, y + 4, tx + vib, y - 4 - t)
        end
      else
        -- a drum seen from a little above: a shell under an elliptic head
        local sq = I.sq
        local h = (k == "hat") and 1 or math.floor(I.r * 0.9)
        -- the body of the mix (mid) warms the heads
        local hb = hot * 2 + (k == "hat" and hi * 1.5 or md * 1.8)
        if hb > 0.25 then K.disc(1 + hb, x, y, I.r * 0.6) end
        K.ring(2.5 + e * 1.5 + hot * 6 + (k == "hat" and hi * 3 or md * 2.5), x, y, I.r, 16, 0, K.TAU, sq)
        line(2.5, x - I.r, y, x - I.r, y + h)
        line(2.5, x + I.r, y, x + I.r, y + h)
        K.ring(2.5, x, y + h, I.r, 10, 0, math.pi, sq)
        if k == "hat" then
          -- shut, the top cymbal clamps down on the bottom; open, it lifts and wobbles
          local lift = hopen * 3 - hclose * 1.5
          K.ring(2.5 + hot * 4 + hopen * 3, x, y - 2 + hot * 2 - lift, I.r, 16, 0, K.TAU, sq, hopen * 1.2, math.floor(K.T * 10))
          line(2, x, y, x, FLOOR)
        elseif k == "snare" then
          line(2, x - 6, y + h, x - 9, FLOOR)
          line(2, x + 6, y + h, x + 9, FLOOR)
        else
          line(2, x, y + h, x, BEAM + 1)
        end
      end
    end

    -- the ripples on the heads that were struck
    for i = #rip, 1, -1 do
      local R = rip[i]
      local u = (K.T - R.t0) / 0.45
      if u >= 1 then table.remove(rip, i)
      elseif u >= 0 then
        local I = INST[R.k]
        K.ring((2 + R.v * 6) * (1 - u), I.x + jx, I.y, I.r * (0.3 + u * 0.75), 14, 0, K.TAU, I.sq)
      end
    end

    -- the arms: a solenoid on the beam, a rod to a beater; each fires and returns
    for _, k in ipairs(ORDER) do
      local I = INST[k]
      local a = arms[k]
      local u = arm_u(k)
      if k == "kick" and kl > 0.5 then u = 0 end
      local ang = I.rest + (I.hit - I.rest) * u
      local px_, py_ = I.px + jx, I.py
      local tx, ty = px_ + math.cos(ang) * I.len, py_ + math.sin(ang) * I.len
      if k == "kick" then
        -- the kick's beater swings on a long arm down onto the head
        ang = (math.pi / 2) - 0.5 * (1 - u) - kl * 0.4
        tx, ty = px_ + math.cos(ang) * (I.len + 6), py_ + math.sin(ang) * (I.len + 6)
      end
      local fl = 3 + u * 6 + (a.n > 1 and K.T - a.t0 < a.dur and 2 or 0)
      put(2.5 + u * 4 + hi * 1.5, px_ - 2, py_ - 1, 5, 6)
      line(4 + u * 4, px_ - 1, py_ - 1, px_ + 3, py_ - 1)
      local nx, ny = -math.sin(ang) * 0.8, math.cos(ang) * 0.8
      line(fl, px_ + nx, py_ + 4 + ny, tx + nx, ty + ny)
      line(fl * 0.7, px_ - nx, py_ + 4 - ny, tx - nx, ty - ny)
      K.disc(math.min(12, 3 + u * 8), tx, ty, 2.2)
      -- chaos: the arm's ghost a beat behind
      if c > 0.5 and u > 0.1 then
        local ga = ang - 0.3 * (c - 0.5)
        line(1 + c, px_, py_ + 2, px_ + math.cos(ga) * I.len, py_ + math.sin(ga) * I.len)
      end
    end

    -- the data pulses running along the beam from the controller to each arm
    for i = #pulses, 1, -1 do
      local P = pulses[i]
      local u = (K.T - P.t0) / 0.12
      if u >= 1 then table.remove(pulses, i)
      else
        local I = INST[P.k]
        local x = BOX_X + 9 + (I.px - BOX_X - 9) * u
        put(8 * (1 - u * 0.5), x + jx, BEAM, 2, 1)
      end
    end

    -- dust in the lamp light
    K.grain(function(uu, vv) return 34 + uu * 60, 8 + vv * 44 end, 3 + e * 8 + hi * 8, 3 + hi * 3)
  end

  ---------------------------------------------------------------- view 2 draw
  local function draw_piano(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md, am = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    board = board * math.exp(-DT / 0.25)
    knock = knock * math.exp(-DT / 0.2)
    local decay = (0.6 + e * 0.9) * (1 + sustain * 0.6)
    -- sympathy: chaos (and the lows) keep every string trembling
    local sym = c * 0.25 + lo * 0.06

    -- the case: the bentside curving down the treble ends, the rim
    local px_, py_
    for i = 0, NS - 1 do
      local x, y = s_x(i) + 3, s_top(i) - 3
      if px_ then line(2.5 + knock * 4, px_, py_, x, y) end
      px_, py_ = x, y
    end
    line(2.5 + knock * 4, px_, py_, 127, py_ + 8)
    line(2.5 + knock * 4, 2, 0, 2, 63)
    -- the iron plate: struts and its holes out over the treble
    local pl = 1.5 + e * 0.5 + board * 0.8 + am * 1.2    -- the plate lit by the level
    for _, h in ipairs({{88, 9, 6}, {108, 12, 7}, {121, 30, 5}, {68, 5, 4}}) do
      K.ring(pl + 1, h[1], h[2], h[3], 14)
    end
    -- the pins along the bottom glint in the air (hi)
    K.dashes(1.5 + e * 0.5 + hi * (1 + 0.5 * math.sin(T * 5)), SBOT + 3, 5, 7, 2, 4, 125)
    -- the soundboard: grain running between the strings, thumping on the kick
    local bl = math.min(2, 0.6 + board * 1.2 + lo * 0.4)
    for i = 0, NS - 2, 2 do
      local x = s_x(i) + 3 + (i % 2)
      line(bl * (0.7 + 0.3 * (i % 3) / 2), x, s_top(i + 1) + 2, x, SBOT - 1)
    end

    -- the strings
    for i = 0, NS - 1 do
      local x0, ytop = s_x(i), s_top(i)
      local L = SBOT - ytop
      amp[i] = amp[i] * math.exp(-DT / decay)
      rattle[i] = rattle[i] * math.exp(-DT / 0.2)
      local w = 3.5 + i * 0.25                -- the treble wobbles faster
      ph[i] = ph[i] + w * K.DTS
      -- each register trembles with its own band: lo the bass, mid the middle
      local reg = i / (NS - 1)
      local band = lo * math.max(0, 1 - reg * 3) + md * math.max(0, 1 - math.abs(reg - 0.5) * 3.5)
      local a = math.min(2, amp[i] * 2.4 + sym * (0.5 + 0.5 * math.sin(T * 0.7 + i)) + band * 0.25)
      local m = mode[i] + (c > 0.6 and 1 or 0)
      local bolt = BOLTS[i]
      local lv = 1.3 + e * 0.3 + math.min(1.8, a * 0.9)
      if a < 0.9 then
        -- a string at rest glows with its band; the air (hi) shimmers the treble
        lv = 1 + e * 0.2 + band * 1.3 + hi * math.max(0, reg * 2.5 - 1.1) * (1.2 + 0.5 * math.sin(T * 7 + i * 2))
        line(lv, x0, ytop, x0, SBOT)
      else
        local px2, py2
        local cs = math.cos(ph[i])
        for q = 0, 10 do
          local f = q / 10
          local y = SBOT - f * L
          local d
          if bolt then
            -- a node at the bolt: each side rings on its own
            if f < bolt then d = math.sin(math.pi * f / bolt * m)
            else d = math.sin(math.pi * (f - bolt) / (1 - bolt) * m) * 0.6 end
          else
            d = math.sin(math.pi * f * m)
          end
          if rattle[i] > 0.05 then d = d + (K.hash(q + math.floor(T * 15) * 11 + i, 5) - 0.5) * rattle[i] * 0.5 end
          local x = x0 + d * a * cs
          if px2 then line(lv, px2, py2, x, y) end
          px2, py2 = x, y
        end
      end
      -- the bolt (prepared strings), glinting when the string rings
      if bolt then
        local by = SBOT - bolt * L
        put(math.min(12, 3.5 + a * 2 + hi * 2), x0 - 1, by - 1, 3, 2)
      end
      -- the damper: lifted while the string rings
      local dl = clamp(amp[i] * 3 + sustain, 0, 1)
      -- the felts catch the body of the mix (mid)
      put(1.5 + dl * 2 + md * (1.2 + 0.4 * math.sin(T * 2 + i * 0.7)), x0 - 2, SBOT - 7 - math.floor(dl * 2 + 0.5), 5, 1)
      -- the hammer under it: up on the strike, then back down
      local hu = math.max(0, 1 - (K.T - ham[i]) / 0.12)
      put(1.5 + hu * 5, x0 - 1, SBOT + 4 - math.floor(hu * 2 + 0.5), 3, 2)
      -- the key, dipping
      -- the keys light by register: lo the bass, mid the middle, hi the treble
      local kb = band * 0.9 + hi * math.max(0, reg * 2.5 - 1.1) * 0.9
      put(1 + hu * 3 + kb, x0 - 3, 61, 6, 2)
    end
    -- kickless: the bass strings rest under felt
    if kl > 0.3 then put(1.5 * kl, s_x(0) - 3, SBOT - 18, s_x(3) - s_x(0) + 6, 2) end

    -- the lamp's reflection creeping along the wire
    for k = 0, 3 do
      local i = math.floor(T * 0.15 + k * 4.3) % NS
      local L = SBOT - s_top(i)
      local y = SBOT - 2 - ((T * (14 + k * 3) + k * 23) % math.max(1, L - 4))
      put(2.5 + hi * 3 + am * 2, s_x(i), y, 1, 2)
    end
    K.grain(function(uu, vv) return 6 + uu * 116, 6 + vv * 46 end, 10 + e * 6 + hi * 8, 3 + hi * 4)
  end

  ---------------------------------------------------------------- view 3 draw
  -- the head's displacement and its gradient at (r, a) for a figure:
  -- cos(m (a - rot)) times a radial shape with n rings (m = 0: the centre
  -- swings, a cos; else the centre is still, a sin)
  local PI = math.pi
  local function mode(F, amp, r, a)
    local ca, sa = 1, 0
    if F.m > 0 then
      local q = F.m * (a - F.rot)
      ca, sa = math.cos(q), math.sin(q)
    end
    local np, sr, cr
    if F.m == 0 then
      np = (F.n - 0.5) * PI
      sr, cr = math.cos(np * r), -math.sin(np * r)
    else
      np = F.n * PI
      sr, cr = math.sin(np * r), math.cos(np * r)
    end
    return amp * ca * sr, amp * ca * np * cr, -amp * F.m * sa * sr / math.max(r, 0.12)
  end

  local function draw_head(S)
    local T, DT, DTS, e, c, kl = K.T, K.DT, K.DTS, K.energy, K.chaos, K.kickless
    local lo, hi, md, am = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local pu = phrase_u(S)
    hhat = hhat * math.exp(-DT / (0.08 + hopen * 0.3))
    htom = htom * math.exp(-DT / 0.25)
    hwood = hwood * math.exp(-DT / 0.12)
    hbell = hbell * math.exp(-DT / 0.4)
    wires = wires * math.exp(-DT / 0.12)
    spin = spin * math.exp(-DT / 1.2)
    -- the ratchet's roll comes due
    for i = #sched, 1, -1 do
      if K.T >= sched[i].at then
        local k = sched[i].k
        if k == "kick" then head(0.5, 0.6, nil, 0, 99)
        elseif k == "hat" then head(0.1, 0.5, nil, 0.9, 5)
        else head(0.4, 0.6, nil, 0.55, 10); wires = 1 end
        table.remove(sched, i)
      end
    end
    -- the drive dies away (longer with energy and the sustain); the mids
    -- keep the figure singing between the hits; a fill spins it
    drive = drive * math.exp(-DT / (0.35 * (1 + e * 0.8 + sustain * 1.5)))
    local hum = 0.12 + md * 0.4 + lo * 0.15
    local a1 = math.max(drive, hum)
    fig.rot = fig.rot + (spin * 2.5) * DTS / (1 + fig.m)
    -- chaos: a second figure fights the first, turning against it
    local a2 = c > 0.3 and (c - 0.3) * 0.9 * (0.6 + 0.4 * math.sin(T * 0.9)) or 0
    fig2.rot = fig2.rot - (0.3 + c) * DTS
    fig2.m = 2 + math.floor(T * 0.4) % 4

    -- the room: a lamp off to the upper left, its light raking the head
    local la = T * 0.11 + pu * 1.2
    local lx, ly = HX + math.cos(la + 3.6) * 70, HY + math.sin(la + 3.6) * 40
    local glow = 0.6 + e * 0.5 + am * 0.8 + lamp * 0.5
    -- the floor round the drum: the seams of the boards running away from
    -- us, dim, the lamp side warmer
    for x = 3, 127, 7 do
      local inside = x > HX - HR - 8 and x < HX + HR + 8
      local off = math.floor(K.hash(x, 71) * 30)
      for y0 = -off, 63, 30 do
        local w = 1 - math.min(1, math.abs(x - lx) / 120)
        local l = 0.6 + w * glow * 0.9
        local ya, yb = math.max(0, y0 + 1), math.min(63, y0 + 28)
        if inside then
          -- (the seams pass under the drum)
          local hw = math.sqrt(math.max(0, (HR + 7) ^ 2 - (x - HX) ^ 2))
          if ya < HY - hw then line(l, x, ya, x, math.min(yb, HY - hw)) end
          if yb > HY + hw then line(l, x, math.max(ya, HY + hw), x, yb) end
        elseif yb > ya then
          line(l, x, ya, x, yb)
        end
      end
    end

    -- the hoop, the counterhoop and the lugs; the phrase walks round the lugs
    local jol = c > 0.5 and math.floor((c - 0.5) * 3 * math.sin(T * 5.3) + 0.5) or 0
    K.ring(2.5 + am + board + lo * 0.8, HX + jol, HY, HR + 2, 40)
    K.ring(1.5 + e * 0.5, HX, HY, HR + 4, 40)
    if c > 0.5 then K.ring(1.5 * c, HX - jol, HY + jol, HR + 3, 32) end
    local lit = math.floor(pu * LUGS) + 1
    for k = 0, LUGS - 1 do
      local a = k / LUGS * K.TAU - PI / 2
      local x, y = HX + math.cos(a) * (HR + 6), HY + math.sin(a) * (HR + 6)
      local on = k < lit and 1 or 0
      local fresh = (k == lit - 1) and (0.5 + 0.5 * math.sin(T * 3)) or 0
      put(2 + on * 2 + fresh * 3 + lo * 1.5 + board, x - 1, y - 1, 3, 2)
      line(1.5 + on, HX + math.cos(a) * (HR + 4), HY + math.sin(a) * (HR + 4), x, y)
    end

    -- the snare wires, seen through the head, buzzing on the snare
    if wires > 0.2 then
      local wl = 1 + wires * 3 + md * 0.6
      for k = -2, 2 do
        local x = HX + k * 4
        local hw = math.sqrt(math.max(0, (HR - 3) ^ 2 - (k * 4) ^ 2))
        line(wl * (0.7 + 0.3 * K.hash(k + math.floor(T * 30), 13)), x, HY - hw * 0.85, x, HY + hw * 0.85)
      end
    end

    -- the strike ripples running out over the head
    for i = #hrip, 1, -1 do
      local R = hrip[i]
      local u = (T - R.t0) / 0.5
      if u >= 1 then table.remove(hrip, i)
      else
        K.ring((1.5 + R.v * 3) * (1 - u), R.x, R.y, 1 + u * math.min(16, R.sp + 4), 14)
        if u < 0.2 then K.disc((1 - u * 5) * 7 * R.v, R.x, R.y, 1.5) end
      end
    end

    -- the sand: thrown up where a strike lands, it creeps down to where the
    -- head is still, so the figure draws itself; energy pours more on
    local ns = math.floor(120 + e * 100)
    local bx, by = HX + math.cos(T * 1.7) * HR * 0.55, HY + math.sin(T * 1.7) * HR * 0.55
    local k = 0.5 * DTS
    for i = 1, ns do
      local g = sand[i]
      local u, gr, ga = mode(fig, a1, g.r, g.a)
      if a2 > 0 then
        local u2, gr2, ga2 = mode(fig2, a2, g.r, g.a)
        u, gr, ga = u + u2, gr + gr2, ga + ga2
      end
      local au = math.abs(u)
      local x, y = HX + math.cos(g.a) * g.r * HR, HY + math.sin(g.a) * g.r * HR
      -- a fresh strike throws it up, harder near the struck point and
      -- where the head swings
      for q = 1, #hrip do
        local R = hrip[q]
        if R.new then
          local d = math.sqrt((x - R.x) ^ 2 + (y - R.y) ^ 2)
          if d < R.sp then
            local j = R.v * (1 - d / R.sp) * (0.35 + au)
            if j > g.h then g.h = j end
          end
        end
      end
      -- creep down the slope of u^2, to the nodes; airborne sand scatters
      local dr = clamp(-u * gr * k, -0.05, 0.05)
      local dt_ = clamp(-u * ga * k, -0.05, 0.05)
      local jump = g.h * (0.025 + c * 0.05) + au * 0.01 + 0.014 * math.min(1, a1)
      dr = dr + (K.rnd() - 0.5) * jump
      dt_ = dt_ + (K.rnd() - 0.5) * jump
      -- kickless: a brush sweeps round, dragging the sand along
      if kl > 0.2 then
        local d2 = (x - bx) ^ 2 + (y - by) ^ 2
        if d2 < 49 then dt_ = dt_ + kl * 0.5 * DTS; g.h = math.max(g.h, 0.2 * kl) end
      end
      g.r = clamp(g.r + dr, 0.03, 0.95)
      -- sand run off to the rim is poured back on (more with energy, the lows)
      if g.r > 0.9 and K.rnd() < (0.1 + e * 0.5 + lo * 0.4) * DTS then
        g.r, g.a, g.h = math.sqrt(K.rnd()) * 0.7, K.rnd() * K.TAU, 0.4
      end
      g.a = (g.a + dt_ / math.max(g.r, 0.1)) % K.TAU
      g.h = g.h * math.exp(-DT / 0.15)
      x, y = HX + math.cos(g.a) * g.r * HR, HY + math.sin(g.a) * g.r * HR
      -- the air (hi) sets the odd grain sparkling
      local sp = (g.j > 0.88 and hi * 4 * (0.5 + 0.5 * math.sin(T * 9 + i))) or 0
      local lift = g.h
      local lv = 2.4 + g.j * 1.2 + math.min(3, lift * 4) + sp
      -- the lamp's side catches more
      lv = lv + glow * 0.8 * math.max(0, (lx < HX and -1 or 1) * (x - HX) / HR)
      put(math.min(10, lv), x, y, 1, 1)
    end
    for q = 1, #hrip do hrip[q].new = false end

    -- the hi-hat, top left, from above: shut it is one tight disc, open the
    -- two cymbals part and wobble
    local hx, hy = 16, 15
    local op = hopen
    K.ring(2 + hhat * 4 + hi * 1.5, hx, hy, 11, 20, 0, K.TAU, 1, op * 1.5, math.floor(T * 12))
    if op > 0.1 then K.ring(1.5 + op * 5, hx + op * 2, hy - op, 10, 18, 0, K.TAU, 1, op, math.floor(T * 9) + 3) end
    K.ring(1.5 + hclose * 5, hx, hy, 6, 12)
    K.disc(2 + hhat * 5 + hclose * 3, hx, hy, 2.2)
    -- the floor tom, bottom right
    local tx, ty = 113, 49
    K.ring(2 + htom * 4 + lo, tx, ty, 11, 20)
    K.ring(1.2 + htom * 3, tx, ty, 11 - htom * 3, 16)
    K.disc(1 + htom * 3 + md * 1.5, tx, ty, 3)
    -- the wood block and the cowbell, top right
    put(1.5 + hwood * 8 + md * 2, 104, 6, 14, 5)
    line(2.5 + hwood * 6, 104, 6, 117, 6)
    local bw = hbell > 0.1 and math.sin(T * 40) * hbell or 0
    line(2.5 + hbell * 7, 106 + bw, 16, 116 + bw, 16)
    line(2.5 + hbell * 7, 106 + bw, 16, 108, 22)
    line(2.5 + hbell * 7, 116 + bw, 16, 114, 22)
    -- the brush (kickless) going round
    if kl > 0.2 then
      local a = T * 1.7
      for f = -2, 2 do
        local fa = a + 1.9 + f * 0.12
        line(2 + kl * 5, bx, by, bx + math.cos(fa) * 6, by + math.sin(fa) * 6)
      end
      line(2 + kl * 3, bx, by, bx - math.cos(a + 1.9) * 30, by - math.sin(a + 1.9) * 30)
    end
    -- the kick beater, from below the frame: a felt that thuds up at the head
    local ka = K.T - arms.kick.t0
    local kb = (ka >= 0 and ka < 0.2) and (1 - ka / 0.2) or 0
    if kl < 0.5 then
      put(2 + kb * 5, HX - 3, 60, 7, 3)
      line(2 + kb * 3, HX, 63, HX, 60)
    end
    -- dust in the lamplight
    K.grain(function(uu, vv) return uu * 128, vv * 64 end, 8 + e * 8 + hi * 10, 3 + hi * 3)
  end

  function M.draw(S)
    local DT = K.DT
    sustain = sustain * math.exp(-DT / 1.5)
    hopen = hopen * math.exp(-DT / 0.35)
    hclose = hclose * math.exp(-DT / 0.06)
    -- the sustain pedal goes down for the phrase's last two bars
    local pu = phrase_u(S)
    local pl = math.max(1, math.floor(K.num(S and S.phrase_len, 16) or 16))
    if pu >= 1 - 2 / pl and K.playing then sustain = math.max(sustain, 0.7) end
    if K.view == 2 then draw_piano(S)
    elseif K.view == 3 then draw_head(S)
    else draw_rig(S) end
  end

  M.init()
  return M
end
