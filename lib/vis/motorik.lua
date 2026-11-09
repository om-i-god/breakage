-- motorik. view 1: an autobahn at night from the driver's seat: a long straight road to a low striped sun, lane marks flowing in time, pylons and their cables passing.
-- view 2: a minimal machine: four mannequin players in a row at their consoles over a grid floor, each lighting with its voice.
--
-- view 1: one lane mark passes every beat, and the kick lights the one
-- going under us; straight-eighth hats glint the reflector posts at the
-- road's edges as they go by; the snare runs a pulse along the cables;
-- syntoms (perc 17) and toms light the pylon nearest us, its insulators
-- and lattice; a fill sweeps the sun's bands; ratchets run pulses down
-- the cables. out_amp is the headlights on the road and the dash glow,
-- out_lo the sun (it swells and brightens with the low end), out_mid the
-- cables and the pylons, out_hi the stars and the reflectors. energy
-- brightens the road and lights more of the far pylons, chaos forks the
-- road into ghosts and splits the sun, kickless stretches let the sun rise
-- and the lane marks go dark while the road keeps flowing.
-- view 2: the four players are bass drum, snare, hats and syntoms, left
-- to right; each lights its outline, its console keys and the light above
-- it with its voice, and their heads turn a step on each bar. out_lo glows
-- the grid floor, out_mid the console screens, out_hi the backdrop tubes,
-- out_amp the players themselves. chaos jolts the players out of line and
-- doubles them, kickless stretches dim the bass drum player and let the
-- floor drift.
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

  function M.kick(v)
    v = K.num(v, 1)
    dash = max(dash, 0.6 + 0.4 * v)
    press(1, 0.6 + 0.4 * v)
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    cable_pulse(0.6 + 0.4 * v)
    press(2, 0.6 + 0.4 * v)
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8) end
  function M.rim(v) press(2, 0.5 * K.num(v, 1)); cab = max(cab, 0.3) end

  function M.hat(v, open)
    v = K.num(v, 1)
    post = max(post, 0.5 + 0.5 * v)
    press(3, (open and 0.9 or 0.6) * (0.5 + 0.5 * v))
  end
  function M.ride(v) M.hat(K.num(v, 1) * 0.7, true) end
  function M.shaker(v) M.hat(K.num(v, 1) * 0.5, false) end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 17 or kind == 13 or kind == 1 or kind == 2 or kind == 7 then
      pyl = max(pyl, 0.6 + 0.4 * v)
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
  end

  function M.fill()
    sunb = 1
    for i = 1, 4 do lamp[i] = 1 end
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
    local sr = 12 + lo * 3 + kl * 3 + e * 3
    local sy = HY - kl * 4
    local sl = 1.5 + lo * 3.5 + e * 0.8 + kl
    local nsun = c > 0.5 and 2 or 1
    for g = 1, nsun do
      local sx = VX + (g - 1) * (c * 26) * (g == 2 and 1 or 0)
      local gl = g == 1 and sl or sl * 0.5
      for dy = -floor(sr), -1 do
        local yy = sy + dy
        -- Bauhaus bands: gaps widen toward the horizon, sweeping on a fill
        local band = (dy + T * 2 + sunb * 12) % 6
        local gap = -dy < sr * 0.55 and band < (2 - dy / sr * 2) or false
        if yy < HY and not gap then
          local hw = math.sqrt(max(0, sr * sr - dy * dy))
          put(gl, sx - hw, yy, hw * 2, 1)
        end
      end
    end
    K.ring(1 + lo * 2 + sunb * 3, VX, sy, sr + 3, 20, PI, K.TAU)
    line(1.5 + lo * 1.5, 0, HY, 127, HY)

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

    -- the backdrop: vertical tubes, shimmering with the highs
    for x = 3, 125, 6 do
      local l = 1 + amp * 0.8 + hi * 3 * (0.5 + 0.5 * sin(T * 1.5 + x * 0.31))
      line(l, x, 0, x, 9)
      local dy = (T * 12 + K.hash(x, 5) * 10) % 10
      put(1 + hi * 9, x, dy, 1, 1)
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
      line(1 + v * 2, x - 3, 0, x - 4, 9)
      line(1 + v * 2, x + 3, 0, x + 4, 9)
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

  function M.draw(S)
    local DT = K.DT
    dash = dash * math.exp(-DT / 0.25)
    post = post * math.exp(-DT / 0.1)
    pyl = pyl * math.exp(-DT / 0.3)
    cab = cab * math.exp(-DT / 0.25)
    sunb = sunb * math.exp(-DT / 1.2)
    rat = rat * math.exp(-DT / 0.3)
    if K.view == 2 then draw2(S)
    else
      draw1(S)
      for i = 1, 4 do lamp[i] = lamp[i] * math.exp(-DT / 0.25) end
    end
  end

  M.init()
  return M
end
