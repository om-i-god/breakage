-- motorik. view 1: an autobahn at night from the driver's seat: a long straight road to a low striped sun, lane marks flowing in time, pylons and their cables passing.
-- view 2: a minimal machine: four mannequin players in a row at their consoles over a grid floor, each lighting with its voice.
-- view 3: Trans-Europe: riding alongside a train at dusk, its lit windows steady while the masts, the sleepers and the far hills stream past.
--
-- view 1: one lane mark passes every beat, and the kick lights the one
-- going under us; closed hats glint the reflector posts nearest us as they
-- go by, open hats flare the far ones down the road; the snare runs a pulse
-- along the cables; syntoms (perc 17) and toms light the pylon nearest us,
-- its insulators and lattice; a gantry sign comes up the road each bar and
-- passes over us on the downbeat; a fill sweeps the sun's bands; ratchets
-- run pulses down the cables. the sun climbs a little through the phrase.
-- out_amp is the headlights on the road and the dash glow, out_lo the sun
-- (it swells and brightens with the low end), out_mid the cables, the pylons
-- and the gantries, out_hi the stars, the reflectors and the far town's
-- lights. energy brightens the road and lights more of the far pylons,
-- chaos forks the road into ghosts and splits the sun, kickless stretches
-- let the sun rise and the lane marks go dark while the road keeps flowing.
-- view 2: the four players are bass drum, snare, hats and syntoms, left
-- to right; each lights its outline, its console keys and the light above
-- it with its voice (open hats throw the hat player's light wider), and
-- their heads turn a step on each bar; the backdrop's tubes fill up from
-- the floor through the phrase. out_lo glows the grid floor, out_mid the
-- console screens, out_hi the backdrop tubes, out_amp the players
-- themselves. chaos jolts the players out of line and doubles them,
-- kickless stretches dim the bass drum player and let the floor drift.
-- view 3: the kick is a rail joint clacking under the bogies (the wheels
-- flash, a spark at the rail); the snare sparks the pantograph on the wire
-- and runs a flash along it; closed hats glint the sleepers, open hats pass
-- a lit signal; syntoms light a far village on the hills; ratchets throw a
-- shower of sparks off the pantograph, a fill takes the train over a truss
-- bridge. one mast passes a beat; another window lights each bar and the sun
-- sinks into the hills through the phrase. out_lo sways the train and warms
-- its wheels, out_mid lights the windows, out_hi the stars, sparks and
-- sleepers, out_amp the sky and the carriage's stripe. chaos flickers the
-- windows and ghosts the masts, kickless stretches let the train coast
-- through a low mist.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs = math.sin, math.cos, math.floor, math.max, math.min, math.abs
  local PI = math.pi

  ---------------------------------------------------------------- state
  local HY, VX = 27, 64                          -- horizon, vanishing point
  local H = 36                                   -- camera height (y = HY + H / z)
  local travel                                   -- distance travelled (dash units)
  local dash, post, pyl, cab, sunb
  local pulses                                   -- runs along the cables
  local rat                                      -- a ratchet's run of reflectors
  -- view 2
  local lamp, keys, turn, bars, drift
  local ls = {0, 0, 0, 0}                        -- the lamps, eased for drawing
  local sbph, opost, wide3                       -- the sun's bands, open hats, the hat lamp's spread
  -- view 3
  local ride, clack, panto, wire, sparks3, sig, vill, bridge, wph

  function M.init()
    travel = 0
    dash, post, pyl, cab, sunb = 0, 0, 0, 0, 0
    pulses = {}
    rat = 0
    lamp = {0, 0, 0, 0}
    ls = {0, 0, 0, 0}
    keys = {}
    for i = 1, 4 do keys[i] = {0, 0, 0, 0, 0} end
    turn = {0, 0, 0, 0}
    bars, drift = 0, 0
    sbph, opost, wide3 = 0, 0, 0
    ride, clack, panto, wire, sig, vill, bridge, wph = 0, 0, 0, {}, -1, 0, -1, 0
    sparks3 = {}
  end
  M.clear = M.init

  local function cable_pulse(v, sp)
    if #pulses >= 8 then table.remove(pulses, 1) end
    pulses[#pulses + 1] = {t0 = K.T, v = v, sp = sp or 1}
  end

  local function press(i, v)
    lamp[i] = max(lamp[i], v)
    local k = 1 + floor(K.rnd() * 5)
    keys[i][k] = max(keys[i][k], v)
  end

  local function spark(x, y, n, sp)
    for k = 1, n do
      if #sparks3 >= 16 then table.remove(sparks3, 1) end
      local a = -PI * (0.1 + 0.8 * K.rnd())
      sparks3[#sparks3 + 1] = {x = x, y = y, vx = cos(a) * sp * (0.5 + K.rnd()), vy = sin(a) * sp * 0.7, t0 = K.T}
    end
  end

  function M.kick(v)
    v = K.num(v, 1)
    clack = max(clack, 0.6 + 0.4 * v)
    spark(26 + (K.step % 2) * 76, 54, 2, 18)
    dash = max(dash, 0.6 + 0.4 * v)
    press(1, 0.6 + 0.4 * v)
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    cable_pulse(0.6 + 0.4 * v)
    press(2, 0.6 + 0.4 * v)
    panto = max(panto, 0.6 + 0.4 * v)
    if #wire >= 4 then table.remove(wire, 1) end
    wire[#wire + 1] = {t0 = K.T, v = v}
    spark(60, 13, 2, 14)
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8) end
  function M.rim(v) press(2, 0.5 * K.num(v, 1)); cab = max(cab, 0.3) end

  function M.hat(v, open)
    v = K.num(v, 1)
    if open then
      opost = max(opost, 0.6 + 0.4 * v)
      wide3 = 1
      if sig < 0 then sig = 0 end
    else
      post = max(post, 0.5 + 0.5 * v)
    end
    press(3, (open and 0.9 or 0.6) * (0.5 + 0.5 * v))
  end
  function M.ride(v) M.hat(K.num(v, 1) * 0.7, true) end
  function M.shaker(v) M.hat(K.num(v, 1) * 0.5, false) end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 17 or kind == 13 or kind == 1 or kind == 2 or kind == 7 then
      pyl = max(pyl, 0.6 + 0.4 * v)
      vill = max(vill, 0.6 + 0.4 * v)
      press(4, 0.6 + 0.4 * v)
    else
      press(4, 0.5 * v)
      cab = max(cab, 0.4 * v)
    end
  end
  function M.tom(v) M.perc(17, K.num(v, 1)) end

  function M.tick() post = max(post, 0.3); press(3, 0.3) end
  function M.brk(s, n)
    s = K.num(s, 1)
    press(1 + floor(s) % 4, 0.5)
    if s % 2 == 1 then post = max(post, 0.4) end
  end

  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    for k = 0, min(n, 6) - 1 do
      if #pulses >= 8 then table.remove(pulses, 1) end
      pulses[#pulses + 1] = {t0 = K.T + k * 0.05, v = 0.9 - k * 0.08, sp = 1.4}
    end
    for i = 1, 4 do press(i, 0.6) end
    pyl = max(pyl, 0.7)
    rat, dash, sunb = 1, 1, max(sunb, 0.6)
    spark(60, 13, min(n, 8), 26)
    panto = 1
  end

  function M.fill()
    sunb = 1
    for i = 1, 4 do lamp[i] = 1 end
    if bridge < 0 then bridge = 0 end
  end

  local function phrase()
    local S = K.S or {}
    local len = max(1, K.num(S.phrase_len, 16))
    return clamp(K.num(S.phrase_pos, 0) / len + K.bar_ph / len, 0, 1)
  end

  function M.bar()
    bars = bars + 1
    for i = 1, 4 do
      if K.hash(bars * 4 + i, 3) < 0.5 then turn[i] = (turn[i] == 0) and ((K.hash(bars + i, 4) < 0.5) and -1 or 1) or 0 end
    end
  end

  ---------------------------------------------------------------- view 1
  -- a point on the ground at lateral offset u (road half-width = 1) and
  -- depth z (1 = the bottom of the screen)
  local RW = 90                                  -- road half-width at z = 1, px
  local function gp(u, z, cx)
    return (cx or VX) + u * RW / z, HY + H / z
  end

  local function pylon(x, by, sc, lv, ins)
    -- an A-frame lattice with two crossarms: Bauhaus-plain
    local h = 70 * sc
    local w = 9 * sc
    local tx, ty = x, by - h
    line(lv, x - w, by, tx - 1, ty + 2)
    line(lv, x + w, by, tx + 1, ty + 2)
    if sc > 0.3 then
      line(lv * 0.7, x - w + 1, by, tx, ty + 2)
      line(lv * 0.7, x + w - 1, by, tx, ty + 2)
    end
    local a1, a2 = ty + h * 0.12, ty + h * 0.32
    line(lv, tx - 16 * sc, a1, tx + 16 * sc, a1)
    line(lv * 0.9, tx - 12 * sc, a2, tx + 12 * sc, a2)
    -- the lattice: two cross braces
    line(lv * 0.6, x - w * 0.55, by - h * 0.45, x + w * 0.35, by - h * 0.7)
    line(lv * 0.6, x + w * 0.55, by - h * 0.45, x - w * 0.35, by - h * 0.7)
    -- insulators
    for _, ix in ipairs({-15, 15}) do put(min(13, 2 + ins), tx + ix * sc - 1, a1 + 1, 2, max(1, 3 * sc)) end
    for _, ix in ipairs({-11, 11}) do put(min(13, 1.5 + ins * 0.8), tx + ix * sc - 1, a2 + 1, 2, max(1, 3 * sc)) end
    return tx, a1, sc
  end

  local function draw1(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    -- one lane mark a beat, in time with the tempo
    travel = travel + K.DTS / K.beat_sec

    -- the sky: stars and the low sun, banded
    for i = 0, 18 do
      local x, y = floor(K.hash(i, 1) * 128), floor(K.hash(i, 2) * (HY - 6))
      local tw = 0.5 + 0.5 * sin(T * (0.7 + K.hash(i, 3)) + i * 2)
      put(1 + tw * (0.4 + hi * 3.5), x, y, 1, 1)
    end
    local ph = phrase()
    local sr = 12 + lo * 3 + kl * 3 + e * 3
    local sy = HY - kl * 4 - ph * 3
    local sl = 1.5 + lo * 3.5 + e * 0.8 + kl
    local nsun = c > 0.5 and 2 or 1
    for g = 1, nsun do
      local sx = VX + (g - 1) * (c * 26) * (g == 2 and 1 or 0)
      local gl = g == 1 and sl or sl * 0.5
      for dy = -floor(sr), -1 do
        local yy = sy + dy
        -- Bauhaus bands: light and dark, the dark ones thicker toward the
        -- horizon, drifting down (sweeping on a fill)
        local band = (yy + sbph) % 5
        local dark = band < 1 + 2.5 * (1 + dy / sr)
        if yy < HY then
          local hw = math.sqrt(max(0, sr * sr - dy * dy))
          put(dark and gl * 0.45 or gl, sx - hw, yy, hw * 2, 1)
        end
      end
    end
    K.ring(1 + lo * 2 + sunb * 3, VX, sy, sr + 3, 20, PI, K.TAU)
    line(1.5 + lo * 1.5, 0, HY, 127, HY)
    -- the far town on the left, its lights twinkling
    for i = 0, 13 do
      local x = 4 + K.hash(i, 21) * 40
      local tw = 0.5 + 0.5 * sin(T * (1 + K.hash(i, 22) * 2) + i)
      put(1 + hi * 3 * tw + K.hash(i, 23) * 1.5, x, HY - 1 - floor(K.hash(i, 24) * 3), 1, 1)
    end
    -- a gantry sign comes up the road each bar
    do
      local z = 7 * (1 - K.bar_ph) + 0.45
      local lx, ly = gp(-1.15, z)
      local rx = gp(1.15, z)
      local h = 34 / z
      local gl = (1.2 + mid * 2.5 + amp) * min(1, 1.6 / z)
      if ly - h > -20 then
        line(gl, lx, ly, lx, ly - h)
        line(gl, rx, ly, rx, ly - h)
        line(gl, lx, ly - h, rx, ly - h)
        local sx0, sx1 = VX + 0.15 * RW / z, VX + 0.9 * RW / z
        local sh = 10 / z
        put(1 + mid * 1.5, sx0, ly - h + 1, sx1 - sx0, sh)
        line(gl + 1, sx0, ly - h + 1, sx1, ly - h + 1)
        line(gl + 1, sx0, ly - h + sh, sx1, ly - h + sh)
      end
    end

    -- the road: edges to the vanishing point, the headlights' pool as
    -- vertical hatching, chaos forking it into ghosts
    local ghosts = c > 0.35 and (c > 0.75 and 2 or 1) or 0
    for g = 0, ghosts do
      local cx = VX + (g == 0 and 0 or (g == 1 and -1 or 1) * (18 + c * 16) * sin(T * 0.7 + g))
      local el = g == 0 and (2 + amp * 1.5 + e + hi * 2) or (1 + c)
      local lx, ly = gp(-1, 1.1, cx)
      local rx, ry = gp(1, 1.1, cx)
      line(el, cx, HY, lx, ly)
      line(el, cx, HY, rx, ry)
      if g == 0 then
        line(el * 0.6, cx - 1, HY + 1, lx - 8, ly + 3)
        line(el * 0.6, cx + 1, HY + 1, rx + 8, ry + 3)
      end
    end
    -- the tarmac in the headlights: vertical hatching from the road's
    -- edge down, brighter toward us
    for x = 26, 102, 4 do
      local f = 1 - abs(x - VX) / 40
      local y0 = floor(56 - f * 8)
      line((1 + amp * 2.5 + e * 0.6) * (0.5 + 0.5 * f), x, y0, x, 60)
    end

    -- the lane marks: one per beat, flowing toward us
    local ph = travel % 1
    for k = 0, 9 do
      local d = k + 1 - ph                       -- distance in dash units
      local z0, z1 = d * 0.9, d * 0.9 + 0.35
      local x0, y0 = gp(-0.3, z1)
      local x1, y1 = gp(-0.3, max(0.25, z0))
      if y1 > HY + 1 then
        local near = (k == 0) and 1 or 0
        local l = (3 + amp * 2 + e) * (1 - k * 0.07) + near * dash * 7 * (1 - kl)
        l = min(12, l * (1 - kl * 0.5))
        for side = -1, 1, 2 do
          local xa, ya = gp(0.34 * side, z1)
          local xb, yb = gp(0.34 * side, max(0.25, z0))
          line(l, xa, ya, xb, min(63, yb))
          if yb - ya > 3 then line(l * 0.8, xa + side, ya, xb + side, min(63, yb)) end
        end
      end
    end

    -- reflector posts at both edges, two per lane mark (the eighths)
    local pph = (travel * 2) % 1
    for k = 0, 9 do
      local d = (k + 1 - pph) * 0.45
      for side = -1, 1, 2 do
        local x, y = gp(side * 1.08, d)
        local h = max(1, 5 / d)
        if y > HY + 1 and y < 64 then
          local l = 1.2 + hi * 6 + (k <= 1 and post * 9 or 0) + rat * (k % 2) * 6
            + ((k >= 2 and k <= 5) and opost * 7 or 0)
          line(min(12, l * (1 - k * 0.05)), x, y - h, x, y)
          put(min(13, l + 1), x - (h > 3 and 1 or 0), y - h, h > 3 and 2 or 1, 1)
        end
      end
    end

    -- the pylons on the right, one every two bars, the cables between them
    local pt = travel / 8
    local pph2 = pt % 1
    local tops = {}
    for k = 0, 3 do
      local d = 1.2 + (k + 1 - pph2) * 2.0
      local x, y = gp(1.25, d)
      if y > HY then
        local sc = 1 / d
        local near = k == 0
        local lv = 1.2 + mid * 4 + (near and pyl * 7 or 0) + (K.hash(floor(pt) + k, 9) < e * 0.5 and 1 or 0)
        local tx, ty = pylon(x, y, sc, lv, (near and pyl * 10 or 0) + mid * 3)
        tops[#tops + 1] = {tx, ty, sc}
        if c > 0.5 then pylon(x + 20 * sc * c, y, sc * 0.9, 1 + c, 0) end
      end
    end
    -- off the far end: the cables run into the horizon
    tops[#tops + 1] = {VX + 6, HY - 2, 0}
    for j = 1, #tops - 1 do
      local a, b = tops[j], tops[j + 1]
      for w = -1, 1, 2 do
        local ax, bx = a[1] + w * 15 * a[3], b[1] + w * 15 * b[3]
        local mx, my = (ax + bx) / 2, (a[2] + b[2]) / 2 + 3 * a[3]
        local cl = 1.2 + mid * 4 + cab * 5
        line(cl, ax, a[2], mx, my)
        line(cl, mx, my, bx, b[2])
        -- pulses running along toward the horizon
        for _, P in ipairs(pulses) do
          local u = (T - P.t0) * 2.2 * P.sp - (j - 1)
          if u >= 0 and u <= 1 then
            local q = u < 0.5 and u * 2 or (u - 0.5) * 2
            local x = u < 0.5 and ax + (mx - ax) * q or mx + (bx - mx) * q
            local y = u < 0.5 and a[2] + (my - a[2]) * q or my + (b[2] - my) * q
            put(min(13, 3 + P.v * 9), x - 1, y, 3, 1)
          end
        end
      end
    end
    for i = #pulses, 1, -1 do if T - pulses[i].t0 > 3 then table.remove(pulses, i) end end

    -- the dash: a low shelf with two gauges, the needle on the level
    put(1, 0, 61, 128, 3)
    for gx = 0, 1 do
      local cx = gx == 0 and 22 or 106
      K.ring(1.5 + amp * 2, cx, 63, 6, 10, PI, K.TAU)
      local a = PI + 0.3 + (PI - 0.6) * clamp(gx == 0 and amp or lo, 0, 1)
      line(3 + amp * 4, cx, 63, cx + cos(a) * 5, 63 + sin(a) * 5)
    end
    if kl > 0.2 then K.haze(0, HY - 2, 128, HY + 8, kl * 0.5, 1, T * 3) end
  end

  ---------------------------------------------------------------- view 2
  local PX = {18, 48, 80, 110}
  local FY = 46                                  -- the floor's back edge

  local function player(i, x, lv, kl1, mid, ghost)
    local A_MID = mid
    local t = turn[i]
    local l = lv
    -- the head, flat-topped, turned a step on the bar
    local hx = x + t
    put(ghost and 1 or 1.2, hx - 3, 13, 6, 7)
    line(l, hx - 3, 13, hx + 2, 13)                        -- the parting
    line(l, hx - 3, 13, hx - 3, 19)
    line(l, hx + 3, 13, hx + 3, 19)
    put(l, hx - 2 + max(0, t), 16, 1, 1)                   -- eyes
    put(l, hx + 1 + min(0, t), 16, 1, 1)
    -- neck, shoulders, the shirt and the tie
    line(l * 0.8, x, 20, x, 21)
    line(l * 0.5, x - 8, 23, x + 8, 23)
    line(l, x - 8, 23, x - 8, 33)
    line(l, x + 8, 23, x + 8, 33)
    if not ghost then
      put(1 + A_MID * 1.6, x - 7, 24, 15, 10)
      line(l + 1.5, x, 23, x, 30)                          -- the tie
    end
  end

  local function draw2(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    for i = 1, 4 do
      for k = 1, 5 do keys[i][k] = keys[i][k] * math.exp(-DT / 0.15) end
    end
    drift = drift + K.DTS * (0.4 + kl * 0.8)

    -- the backdrop: vertical tubes, shimmering with the highs, filling up
    -- from the floor through the phrase
    local fillh = floor(phrase() * (FY - 13))
    for x = 3, 125, 6 do
      if fillh > 0 and x % 12 ~= 3 then line(1 + hi * 1.5, x, FY - 13 - fillh, x, FY - 13) end
      local l = 1 + amp * 0.8 + hi * 3 * (0.5 + 0.5 * sin(T * 1.5 + x * 0.31))
      line(l, x, 0, x, 9)
      local dy = (T * 26 + K.hash(x, 5) * 10) % 10
      put(1.5 + hi * 8, x, dy, 1, 2)
      if x % 12 == 3 then line(l * 0.6, x, 10, x, FY - 13) end
    end

    -- the grid floor: lines to the vanishing point, cross lines drifting
    local fl = 1 + lo * 2.5 + K.env.kick * 1
    for k = -4, 4 do
      local xb = 64 + k * 17
      line(fl * (1 - abs(k) * 0.08), 64 + (xb - 64) * 0.5, FY, xb, 63)
    end
    for k = 0, 2 do
      local u = ((k + drift) % 3) / 3
      local y = FY + floor(16 * u * u + 0.5)
      K.dashes(1, y, 2, 5, 0)
    end
    -- a pool of light under each player, glowing with the low end
    for i = 1, 4 do
      for k = -2, 2 do line(1 + lo * 2 + ls[i] * 2 - abs(k) * 0.3, PX[i] + k * 2, FY + 2, PX[i] + k * 2, FY + 6) end
    end

    -- the players: lamp above each, the player, the console in front
    for i = 1, 4 do
      ls[i] = K.follow(ls[i], lamp[i], 0.06, DT)
      local v = ls[i]
      local x = PX[i]
      if c > 0.3 then x = x + sin(T * 2 + i * 2) * c * 3 end
      local lv = 1.5 + amp * 1.2 + v * 5 - (i == 1 and kl * 1 or 0)
      -- the light from above
      line(1 + v * 5, x, 0, x, 11)
      local wd = i == 3 and wide3 * 4 or 0
      line(1 + v * 2, x - 3, 0, x - 4 - wd, 9)
      line(1 + v * 2, x + 3, 0, x + 4 + wd, 9)
      if c > 0.55 then player(i, x + 7 * c, 1 + c, kl, mid, true) end
      player(i, x, min(12, lv), kl, mid, false)
      -- the console: a slanted desk, keys and pads, its screen glowing
      local cx0, cx1 = x - 12, x + 12
      line(1.2 + amp * 0.4 + v * 1.5, cx0, 34, cx1, 34)
      line(1.5 + amp * 0.5, cx0, 34, cx0 - 2, 41)
      line(1.5 + amp * 0.5, cx1, 34, cx1 + 2, 41)
      line(1 + amp * 0.5, cx0 - 2, 41, cx1 + 2, 41)
      put(1.5 + mid * 3 + v * 1.5, x - 4, 36, 8, 2)          -- the screen
      for k = 1, 5 do
        put(min(13, 1.2 + keys[i][k] * 8 + mid), cx0 + (k - 1) * 5, 39, 3, 1)
      end
      -- legs down to the floor behind the desk
      line(lv * 0.6, x - 3, 41, x - 3, FY + 2)
      line(lv * 0.6, x + 3, 41, x + 3, FY + 2)
      lamp[i] = lamp[i] * math.exp(-DT / 0.25)
    end
  end


  ---------------------------------------------------------------- view 3
  local TY = 27                                  -- the carriage's roof
  local wl3, sun3 = {}, 15                       -- the windows' light, the sun's height, eased
  local TB = 49                                  -- its underframe
  local RY3 = 56                                 -- the rail
  local function hill_y(x)
    return 24 - 4 * sin(x * 0.031) - 3 * sin(x * 0.083 + 1.3) - 2 * K.hash(floor(x / 9), 31)
  end

  local function draw3(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local ph = phrase()
    clack = clack * math.exp(-DT / 0.15)
    panto = panto * math.exp(-DT / 0.2)
    vill = vill * math.exp(-DT / 0.6)
    ride = K.follow(ride, lo * 1.2, 0.3, DT)
    local dy = floor(ride + 0.5)
    wph = wph + K.DTS * (3 + e * 2)

    -- the sky: stars, a glow over the hills in solid bands, the sun sinking
    -- into them through the phrase
    for i = 0, 20 do
      local x, y = floor(K.hash(i, 41) * 128), floor(K.hash(i, 42) * 13)
      local tw = 0.5 + 0.5 * sin(T * (0.7 + K.hash(i, 43)) + i * 2)
      put(1 + tw * (0.3 + hi * 3), x, y, 1, 1)
    end
    K.row_above(1 + amp * 0.6 + kl * 0.3, 22, nil, 0, 128)
    -- the far hills, drifting by slowly, the village lights on them; the
    -- sun goes down behind them
    local hx = travel * 3
    local HP = K.profile(function(x) return hill_y(x + hx) end)
    sun3 = K.follow(sun3, 15 + ph * 9, 1.2, DT)
    local sx, sy, sr = 96, sun3, 6 + lo * 1.5
    for ddy = -floor(sr), floor(sr) do
      local hw = math.sqrt(max(0, sr * sr - ddy * ddy))
      if hw >= 1 then K.row_above(2 + lo * 2.5 + sunb * 2, floor(sy + ddy), HP, floor(sx - hw), floor(sx + hw)) end
    end
    local prx, pry
    for k = 0, 16 do
      local x = k * 8
      local y = hill_y(x + hx)
      if prx then line(1.2 + amp * 0.7, prx, pry, x, y) end
      prx, pry = x, y
    end
    for i = 0, 7 do
      local x = (K.hash(i, 51) * 200 - hx) % 200 - 30
      if x > 0 and x < 127 then
        local y = hill_y(x + hx) + 1
        put(1.5 + vill * 8 * K.hash(i, 52) + hi * 1.5, x, y, 1, 1)
      end
    end
    if kl > 0.1 then
      for y = 23, 25 do put(1 + kl * 1.5, 0, y, 128, 1) end
    end

    -- the catenary: masts passing one a beat, the wire sagging between them
    local mph = travel % 1
    local mx = {}
    for k = -1, 2 do
      local x = (k + 1 - mph) * 64 - 4
      mx[#mx + 1] = x
      local ml = 1.2 + mid + e * 0.3
      line(ml, x, 6, x, TY - 2)
      line(ml, x - 1, 6, x - 1, TY - 2)
      line(ml * 0.8, x, 8, x + 22, 8)
      line(ml * 0.6, x, 12, x + 18, 8)
      if c > 0.5 then line(1 + c, x + c * 6, 6, x + c * 6, TY - 2) end
    end
    for j = 1, #mx - 1 do
      local a, b = mx[j] + 18, mx[j + 1] + 18
      local m = (a + b) / 2
      local wl = 1.2 + mid
      line(wl, a, 9, m, 11)
      line(wl, m, 11, b, 9)
    end
    -- the flash running along the wire from the pantograph
    for i = #wire, 1, -1 do
      local W = wire[i]
      local age = T - W.t0
      if age > 0.4 then table.remove(wire, i)
      else
        local d = age * 160
        local l = (5 + 6 * W.v) * (1 - age / 0.4)
        put(l, 60 - d, 10, 4, 1)
        put(l, 60 + d, 10, 4, 1)
      end
    end

    -- the carriage: a long dark body, its stripe, the windows lit inside
    local y0, y1 = TY + dy, TB + dy
    line(1.2 + amp * 0.8, 0, y0, 127, y0)
    put(1 + amp * 0.6, 0, y1 - 5, 128, 1)
    local lit_n = 3 + floor(ph * 5) + (bars % 2)
    for w = 0, 8 do
      local wx = 3 + w * 14
      local on = K.hash(w, 61) * 8 < lit_n
      wl3[w] = K.follow(wl3[w] or 0, on and 1 or 0, 0.4, DT)
      local l = 1 + mid * 0.4 + wl3[w] * (1 + mid * 1.5 + e * 0.3)
      if c > 0.4 and K.hash(w, floor(T * 4)) < c * 0.25 then l = l * 0.5 end
      if on then
        -- a passenger's head and shoulders, dark against the light
        local px = floor(wx + 2 + K.hash(w, 62) * 5)
        put(min(11, l), wx, y0 + 4, px - wx, 8)
        put(min(11, l), px + 3, y0 + 4, wx + 10 - px - 3, 8)
        put(min(11, l), px, y0 + 4, 3, 2)
      else
        put(min(11, l), wx, y0 + 4, 10, 8)
      end
    end
    -- the pantograph on the roof, sparking on the wire
    line(2 + mid, 52, y0, 60, 10)
    line(2 + mid, 68, y0, 60, 10)
    line(2 + panto * 9, 55, 10, 65, 10)
    if panto > 0.1 then K.ring(panto * 4, 60, 10, 2 + panto * 3, 8) end

    -- the bogies, wheels turning, the rail and the sleepers streaming past
    for b = 0, 1 do
      local bx = 26 + b * 76
      for wv = -1, 1, 2 do
        local wx = bx + wv * 8
        local wl = 1.5 + lo * 1.5 + clack * 4
        K.ring(min(12, wl), wx, RY3 - 4, 4, 10)
        local a = -wph * 2
        line(wl * 0.6, wx, RY3 - 4, wx + cos(a) * 3.5, RY3 - 4 + sin(a) * 3.5)
      end
    end
    line(1.2 + hi * 0.6 + clack * 1.5, 0, RY3, 127, RY3)
    local sph = (travel * 8) % 1
    for k = 0, 17 do
      local x = (k + 1 - sph) * 8 - 8
      local sl = 1 + hi * 1.5 + post * 6 * max(0, 1 - abs(x - 64) / 40)
      line(sl, x, RY3 + 2, x - 2, RY3 + 5)
    end
    -- a signal passing on the open hats
    if sig >= 0 then
      sig = sig + K.DTS / 0.9
      if sig > 1 then sig = -1
      else
        local x = 140 - sig * 170
        line(2, x, RY3 + 6, x, 34)
        K.disc(3 + 7 * sin(PI * sig), x, 33, 1.8)
      end
    end
    -- a fill: the truss of a bridge sweeping past in front
    if bridge >= 0 then
      bridge = bridge + K.DTS / 2.4
      if bridge > 1 then bridge = -1
      else
        -- the girders overhead, braced, sliding over the roofline
        local bl = (2 + amp) * sin(PI * bridge)
        local x0 = 130 - bridge * 280
        for k = 0, 7 do
          local x = x0 + k * 18
          line(bl, x, 1, x + 9, 6)
          line(bl, x + 9, 6, x + 18, 1)
        end
        line(bl, x0, 1, x0 + 144, 1)
        line(bl * 0.7, x0, 6, x0 + 144, 6)
      end
    end
    -- sparks off the wheels and the pantograph
    for j = #sparks3, 1, -1 do
      local P = sparks3[j]
      local age = T - P.t0
      if age > 0.4 then table.remove(sparks3, j)
      else
        local x = P.x + P.vx * age
        local y = P.y + P.vy * age + 50 * age * age
        put((6 + hi * 4) * (1 - age / 0.4), x, y, 1, 1)
      end
    end
  end

  function M.draw(S)
    local DT = K.DT
    sbph = sbph + K.DTS * (0.8 + sunb * 5)
    opost = opost * math.exp(-DT / 0.25)
    wide3 = wide3 * math.exp(-DT / 0.3)
    dash = dash * math.exp(-DT / 0.25)
    post = post * math.exp(-DT / 0.1)
    pyl = pyl * math.exp(-DT / 0.3)
    cab = cab * math.exp(-DT / 0.25)
    sunb = sunb * math.exp(-DT / 1.2)
    rat = rat * math.exp(-DT / 0.3)
    if K.view == 2 then draw2(S)
    elseif K.view == 3 then
      travel = travel + K.DTS / K.beat_sec * (1 - K.kickless * 0.4) * (K.playing and 1 or 0.5)
      draw3(S)
      for i = 1, 4 do lamp[i] = lamp[i] * math.exp(-DT / 0.25) end
    else
      draw1(S)
      for i = 1, 4 do lamp[i] = lamp[i] * math.exp(-DT / 0.25) end
    end
  end

  M.init()
  return M
end
