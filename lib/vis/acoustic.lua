-- acoustic. view 1: a robot drum rig, solenoid arms on a frame striking a kick, a snare, toms, wood blocks, a hi-hat, tines and a bell.
-- view 2: inside an open grand piano from the keyboard end: hammers strike strings that ring as standing waves, some strings bolted.
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
-- whole frame ringing in sympathy and in higher modes.
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

  local arms, rip, leds, pulses, lamp
  local amp, mode, ph, ham, rattle, board, knock

  function M.init()
    arms, rip, pulses = {}, {}, {}
    for _, k in ipairs(ORDER) do arms[k] = {t0 = -9, v = 0, n = 0, dur = 0} end
    leds, lamp = {}, 0
    for i = 1, 8 do leds[i] = 0 end
    amp, mode, ph, ham, rattle = {}, {}, {}, {}, {}
    for i = 0, NS - 1 do amp[i], mode[i], ph[i], ham[i], rattle[i] = 0, 1, 0, -9, 0 end
    board, knock = 0, 0
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

  function M.kick(v)
    v = K.num(v, 1)
    fire("kick", v)
    strike(0, v); strike(1, v * 0.8)
    board = math.max(board, v)
  end

  function M.snare(v, n)
    v, n = K.num(v, 1), K.num(n, 1)
    if n > 1 then
      -- a ratchet burst: the arm is already buzzing; each hit re-strikes
      strike(7 + math.floor(K.rnd() * 2), v * 0.6, 2)
      return
    end
    fire("snare", v)
    strike(7, v, 1)
    rattle[7] = 1
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8, 1) end
  function M.rim(v) fire("snare", K.num(v, 1) * 0.6); strike(8, K.num(v, 1) * 0.5, 3) end

  function M.hat(v, open)
    v = K.num(v, 1)
    fire("hat", v * (open and 1 or 0.7))
    strike(NS - 1 - math.floor(K.rnd() * 2), v * 0.35, 2)
  end

  function M.tom(v, hz)
    v = K.num(v, 1)
    hz = K.num(hz, 120)
    fire(hz < 130 and "tom1" or "tom2", v)
    strike(hz_string(hz), v, 1)
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 7 then
      fire("wood", v)
      knock = math.max(knock, v)
    elseif kind == 6 or kind == 3 then
      fire("bell", v)
      local bs = {2, 5, 9, 12}
      strike(bs[1 + math.floor(K.rnd() * 4)], v, 1)
    elseif kind == 8 then
      fire("tines", v)
      strike(9 + math.floor(K.hash(math.floor(K.T * 7), 3) * 7), v * 0.9, 1)
    else
      fire(K.rnd() < 0.5 and "tom2" or "wood", v * 0.7)
      strike(4 + math.floor(K.rnd() * 8), v * 0.6, 1)
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
  end

  function M.fill() lamp = math.max(lamp, 0.7) end

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
          K.ring(2.5 + hot * 4, x, y - 2 + hot * 2, I.r, 16, 0, K.TAU, sq)
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
    local decay = 0.6 + e * 0.9
    -- sympathy: chaos (and the lows) keep every string trembling
    local sym = c * 0.25 + lo * 0.06

    -- the case: the bentside curving down the treble ends, the rim
    local px_, py_
    for i = 0, NS - 1 do
      local x, y = s_x(i) + 3, s_top(i) - 3
      if px_ then line(3 + knock * 7, px_, py_, x, y) end
      px_, py_ = x, y
    end
    line(3 + knock * 7, px_, py_, 127, py_ + 8)
    line(3 + knock * 7, 2, 0, 2, 63)
    -- the iron plate: struts and its holes out over the treble
    local pl = 1.5 + e * 0.5 + board * 2 + am * 1.2    -- the plate lit by the level
    for _, h in ipairs({{88, 9, 6}, {108, 12, 7}, {121, 30, 5}, {68, 5, 4}}) do
      K.disc(1, h[1], h[2], h[3])
      K.ring(pl + 1, h[1], h[2], h[3], 14)
    end
    -- the pins along the bottom glint in the air (hi)
    K.dashes(1.5 + e * 0.5 + hi * (1 + 0.5 * math.sin(T * 5)), SBOT + 3, 5, 7, 2, 4, 125)
    -- the soundboard: grain running between the strings, thumping on the kick
    local bl = math.min(3, 0.7 + board * 1.8 + lo * 0.6)
    for i = 0, NS - 2 do
      local x = s_x(i) + 3 + (i % 2)
      line(bl * (0.7 + 0.3 * (i % 3) / 2), x, SBOT - 1, x, s_top(i + 1) + 2)
    end

    -- the strings
    for i = 0, NS - 1 do
      local x0, ytop = s_x(i), s_top(i)
      local L = SBOT - ytop
      amp[i] = amp[i] * math.exp(-DT / decay)
      rattle[i] = rattle[i] * math.exp(-DT / 0.2)
      local w = 9 + i * 0.6                   -- the treble wobbles faster
      ph[i] = ph[i] + w * K.DTS
      -- each register trembles with its own band: lo the bass, mid the middle
      local reg = i / (NS - 1)
      local band = lo * math.max(0, 1 - reg * 3) + md * math.max(0, 1 - math.abs(reg - 0.5) * 3.5)
      local a = math.min(3.5, amp[i] * 3.5 + sym * (0.5 + 0.5 * math.sin(T * 0.7 + i)) + band * 0.25)
      local m = mode[i] + (c > 0.6 and 1 or 0)
      local bolt = BOLTS[i]
      local lv = 1.2 + e * 0.4 + math.min(3.8, a * 1.4)
      if a < 0.4 then
        -- a string at rest glows with its band; the air (hi) shimmers the treble
        lv = lv + band * 2.4 + hi * math.max(0, reg * 2.5 - 1.1) * (2 + 0.6 * math.sin(T * 7 + i * 2))
        line(lv, x0, SBOT, x0, ytop)
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
          if rattle[i] > 0.05 then d = d + (K.hash(q + math.floor(T * 15) * 11 + i, 5) - 0.5) * rattle[i] * 0.8 end
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
      local dl = clamp(amp[i] * 3, 0, 1)
      -- the felts catch the body of the mix (mid)
      put(1.5 + dl * 2 + md * (1.2 + 0.4 * math.sin(T * 2 + i * 0.7)), x0 - 2, SBOT - 7 - dl * 3, 5, 2)
      -- the hammer under it: up on the strike, then back down
      local hu = math.max(0, 1 - (K.T - ham[i]) / 0.12)
      put(1.5 + hu * 7, x0 - 1, SBOT + 4 - hu * 3, 3, 3)
      -- the key, dipping
      -- the keys light by register: lo the bass, mid the middle, hi the treble
      local kb = band * 0.9 + hi * math.max(0, reg * 2.5 - 1.1) * 0.9
      put(1 + hu * 3 + kb, x0 - 3, 61 + (hu > 0.3 and 1 or 0), 6, 2)
    end
    -- kickless: the bass strings rest under felt
    if kl > 0.3 then put(1.5 * kl, s_x(0) - 3, SBOT - 18, s_x(3) - s_x(0) + 6, 2) end

    -- the lamp's reflection creeping along the wire
    for k = 0, 1 do
      local i = math.floor(T * 0.15 + k * 7) % NS
      local L = SBOT - s_top(i)
      local y = SBOT - 2 - ((T * 5 + k * 23) % math.max(1, L - 4))
      put(2.5 + hi * 3, s_x(i), y, 1, 2)
    end
    K.grain(function(uu, vv) return 6 + uu * 116, 6 + vv * 46 end, 2 + e * 6 + hi * 8, 3 + hi * 4)
  end

  function M.draw(S)
    if K.view == 2 then draw_piano(S) else draw_rig(S) end
  end

  M.init()
  return M
end
