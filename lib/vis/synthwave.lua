-- synthwave. view 1: an 80s neon horizon: a striped sun setting behind wireframe mountains, a chrome horizon line and a perspective grid racing toward us.
-- view 2: the drive: a sports car from behind on a straight road into the sunset, palms streaming past, a city skyline on the horizon.
-- view 3: the tunnel: neon octagon frames rushing at us one after another, a small striped sun at the far end, warp dust streaking out.
--
-- view 1: the kick surges the grid toward us and rolls a bright row down
-- it; the gated snare is a big flash of the whole grid that holds, then
-- cuts; claps flash it a little less and nudge the sun's stripes; syntoms
-- (perc 17) and toms drop chevrons through the sky, stacked three deep;
-- closed hats light single stars, open hats throw a shooting star; the
-- ride and each bar run a glint along the chrome horizon; rims and claves
-- spark a node of the grid; ratchets send a train of rows rushing in, a
-- fill scrolls the sun's stripes and lights the mountains. over the phrase
-- the sun sinks a little into the horizon. out_lo swells and brightens the
-- sun, out_mid lights the mountains' ridges and facets, out_hi the stars and
-- the grid's long lines, out_amp the cross rows and the glow over the
-- horizon. energy speeds the grid and brightens it, chaos bends the rows
-- and tears the sun into offset slices, kickless stretches slow the grid to
-- a drift and lay fog on it.
-- view 2: the kick flares the car's tail lights and surges the lane marks;
-- the gated snare flashes the grid fields either side of the road; syntoms
-- light the chevron boards along the barrier, a chase running toward us;
-- closed hats wink the cat's eyes, open hats shoot a star; palms pass two to
-- a bar; a fill sweeps the skyline windows. out_lo bounces the car and its
-- glow on the road and swells the sun, out_mid rims the palms and lights the
-- windows, out_hi the stars and cat's eyes, out_amp the road's edges.
-- chaos swerves the car and ghosts it, kickless stretches let it coast in
-- a low mist.
-- view 3: a new frame launches each beat; the kick lights the nearest, the
-- gated snare flashes them all, syntoms send chevrons flying at us along
-- the floor, hats streak sparks outward (open hats longer), ratchets chase a
-- flash down the tunnel, a fill spins it. the tunnel twists further through
-- the phrase and steps round a notch each bar. out_lo swells the sun at the
-- end, out_mid lights the tunnel's long struts, out_hi thickens the warp
-- dust, out_amp the frames. chaos throws the tunnel's line about and doubles
-- the frames, kickless stretches slow it and fill it with smoke.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, sqrt = math.sin, math.cos, math.floor, math.max, math.min, math.abs, math.sqrt
  local PI = math.pi
  local TAU = 2 * PI

  ---------------------------------------------------------------- state
  local HY, VX, GH = 34, 64, 30                  -- view 1 horizon, vanishing x, eye height
  local travel                                   -- grid rows travelled
  local gate_t, gate_v, fs                       -- the gated snare: when, how hard, eased
  local front = 1                                -- the flash's front, rolling in (0..1)
  local sph = 0                                  -- the sun's stripes, scrolling
  local sunb, sweep, set, bars, rat, mrim, run
  local chevs, rushes, sparks, nodes, shoots, twink
  local play                                     -- eased: the drummer playing
  -- view 2
  local tail, cs, palm_t, boards, wins, steer
  -- view 3
  local tun, twist, notch, nk, fspin

  function M.init()
    travel = 0
    gate_t, gate_v, fs = -9, 0, 0
    sunb, sweep, set, bars, rat, mrim, run = 0, -1, 0, 0, 0, 0, 0
    chevs, rushes, sparks, nodes, shoots, twink = {}, {}, {}, {}, {}, {}
    play = 0
    tail, cs, palm_t, steer = 0, 0, 0, 0
    boards = {}
    for i = 1, 8 do boards[i] = 0 end
    wins = 0
    tun, twist, notch, nk, fspin = 0, 0, 0, 0, 0
  end
  M.clear = M.init

  local function push(list, item, cap)
    if #list >= cap then table.remove(list, 1) end
    list[#list + 1] = item
  end

  local function gate(v)
    gate_t, gate_v = K.NOW, max(K.num(v, 1), (K.NOW - gate_t < 0.12) and gate_v or 0)
  end

  local function chevron(v, x, d)
    push(chevs, {x = x or (14 + K.rnd() * 100), t0 = K.T + (d or 0), v = v}, 8)
  end

  local function rush(v, d)
    push(rushes, {t0 = K.T + (d or 0), v = v}, 5)
  end

  function M.kick(v)
    v = K.num(v, 1)
    rush(0.5 + 0.5 * v)
    tail = max(tail, 0.6 + 0.4 * v)
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    gate(0.6 + 0.4 * v)
  end

  function M.clap(v)
    v = K.num(v, 1)
    gate(0.45 + 0.3 * v)
    sunb = max(sunb, 0.3)
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    if open then
      push(shoots, {t0 = K.T, x = 10 + K.rnd() * 90, y = 2 + K.rnd() * 12, v = v}, 3)
    else
      push(twink, {i = floor(K.rnd() * 40), t0 = K.T, v = v}, 6)
    end
    push(sparks, {a = K.rnd() * TAU, t0 = K.T, len = open and 1 or 0.4, v = v}, 14)
  end
  function M.shaker(v) push(twink, {i = floor(K.rnd() * 40), t0 = K.T, v = 0.6 * K.num(v, 1)}, 6) end
  function M.ride(v) sweep = 0; M.hat(K.num(v, 1) * 0.6, false) end

  local function node(v)
    push(nodes, {k = floor(K.rnd() * 9) - 4, r = 2 + floor(K.rnd() * 5), t0 = K.T, v = v}, 6)
  end
  function M.rim(v) node(K.num(v, 1)) end

  function M.tom(v, hz)
    v = K.num(v, 1)
    hz = clamp(K.num(hz, 120), 20, 2000)
    local x = 14 + clamp((math.log(hz) - math.log(50)) / math.log(16), 0, 1) * 100
    chevron(0.6 + 0.4 * v, x)
    run = 1
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 17 or kind == 13 or kind == 7 then
      chevron(0.6 + 0.4 * v)
      run = 1
    elseif kind == 4 or kind == 6 or kind == 3 then
      node(v)
    else
      push(twink, {i = floor(K.rnd() * 40), t0 = K.T, v = v}, 6)
      mrim = max(mrim, 0.4 * v)
    end
  end

  function M.tick() push(twink, {i = floor(K.rnd() * 40), t0 = K.T, v = 0.5}, 6) end
  function M.brk(s, n)
    s = K.num(s, 1)
    if s % 2 == 1 then node(0.6) end
  end

  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 8)
    for k = 0, n - 1 do rush(0.9 - k * 0.06, k * 0.055) end
    rat = 1
    if n >= 4 then for k = 0, 1 do chevron(0.7, 40 + k * 48, k * 0.12) end end
  end

  function M.fill()
    sunb = 1
    sweep = 0
    mrim = 0.7
    fspin = fspin + 1
    wins = 1
    for k = 0, 1 do chevron(0.8, 49 + k * 30, k * 0.15) end
  end

  function M.bar()
    bars = bars + 1
    sweep = 0
    notch = notch + 1
  end

  -- the phrase: 0..1 through it
  local function phrase()
    local S = K.S or {}
    local len = max(1, K.num(S.phrase_len, 16))
    return clamp(K.num(S.phrase_pos, 0) / len + K.bar_ph / len, 0, 1)
  end

  ---------------------------------------------------------------- shared bits
  local STAR = {}
  for i = 0, 39 do STAR[i] = {x = floor(K.hash(i, 1) * 128), y = floor(K.hash(i, 2) * 26), s = K.hash(i, 3)} end

  local function stars(ymax, hi, lv)
    for i = 0, 39 do
      local s = STAR[i]
      if s.y < ymax then
        local tw = 0.5 + 0.5 * sin(K.T * (0.8 + s.s * 2) + i * 2.3)
        put((0.6 + tw * (0.5 + hi * 3)) * lv, s.x, s.y, 1, 1)
      end
    end
    for j = #twink, 1, -1 do
      local W = twink[j]
      local age = K.T - W.t0
      if age > 0.35 then table.remove(twink, j)
      else
        local s = STAR[W.i % 40]
        if s.y < ymax then
          local l = (4 + 7 * W.v) * (1 - age / 0.35)
          put(l, s.x, s.y, 1, 1)
          if l > 5 then put(l * 0.4, s.x - 1, s.y, 3, 1); put(l * 0.4, s.x, s.y - 1, 1, 3) end
        end
      end
    end
    for j = #shoots, 1, -1 do
      local P = shoots[j]
      local age = K.T - P.t0
      if age > 0.5 then table.remove(shoots, j)
      else
        local x, y = P.x + age * 90, P.y + age * 22
        local l = (5 + 6 * P.v) * sin(PI * age / 0.5)
        if y < ymax then
          line(l, x, y, x - 9, y - 2)
          line(l * 0.4, x - 9, y - 2, x - 16, y - 4)
        end
      end
    end
  end

  -- the sun: rows of a disc, striped in its lower part, clipped by `prof`
  local function sun(cx, cy, r, ybot, lv, stripe, prof, tear)
    local ri = floor(r)
    for dy = -ri, ri do
      local y = floor(cy + dy)
      if y >= ybot then break end
      if y >= 0 then
        local u = (dy + r) / (2 * r)
        local hw = sqrt(max(0, r * r - dy * dy))
        local gap = false
        if u > 0.36 then
          local P = 5
          local gw = (u - 0.36) / 0.64 * 3.8
          gap = ((y + stripe) % P) < gw
        end
        if not gap and hw >= 1 then
          local l = lv * (1.12 - u * 0.75)
          local ox = 0
          if tear > 0.25 and K.hash(y, floor(K.T * 4)) < tear * 0.3 then
            ox = (K.hash(y, floor(K.T * 4) + 7) - 0.5) * tear * 9
          end
          local x0, x1 = floor(cx - hw + ox), floor(cx + hw + ox)
          if prof then K.row_above(l, y, prof, max(0, x0), min(128, x1))
          else put(l, x0, y, x1 - x0, 1) end
        end
      end
    end
  end

  ---------------------------------------------------------------- view 1
  local RIDGE = {
    {0, 8}, {6, 12}, {11, 9}, {17, 15}, {23, 18}, {29, 12}, {33, 14}, {40, 8}, {46, 9},
    {52, 4}, {58, 2}, {70, 2}, {76, 5}, {82, 10}, {88, 8}, {95, 16}, {101, 19},
    {107, 13}, {112, 15}, {119, 9}, {124, 11}, {128, 7},
  }
  local function ridge_y(x)
    for i = 1, #RIDGE - 1 do
      local a, b = RIDGE[i], RIDGE[i + 1]
      if x <= b[1] then
        local u = (x - a[1]) / max(1, b[1] - a[1])
        return HY - (a[2] + (b[2] - a[2]) * u)
      end
    end
    return HY - 7
  end
  local MTN = K.profile(ridge_y)

  local function draw1(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local fl = fs
    local ph = phrase()

    -- the sky: a glow over the horizon, the stars above it
    K.gradient(HY - 7, HY - 1, function(y)
      local u = (y - (HY - 7)) / 7
      return u * u * (1.1 + amp * 1.2 + e * 0.4)
    end, MTN)
    stars(HY - 14, hi, 1)

    -- the sun, sinking through the phrase, behind the mountains
    local r = 15 + lo * 2 + kl * 2
    local sy = HY - 11 + set * 6 - kl * 3
    local slv = 3.5 + lo * 2.5 + e * 1 + sunb * 2
    local stripe = sph + bars * 0.5
    sun(VX, sy, r, HY, min(11, slv), stripe, MTN, c)
    if c > 0.5 then K.ring(1 + c * 1.5, VX + c * 12, sy - 2, r * 0.85, 20, PI, K.TAU) end
    K.ring(1 + lo * 2 + sunb * 2, VX, sy, r + 3, 22, PI * 1.08, PI * 1.92)

    -- the mountains: the ridge and its facets, lit from the sun
    local rl = 1.5 + mid * 4 + mrim * 4 + e * 0.5
    for i = 1, #RIDGE - 1 do
      local a, b = RIDGE[i], RIDGE[i + 1]
      local near = max(0, 1 - abs((a[1] + b[1]) / 2 - VX) / 70)
      line(rl * (0.6 + 0.6 * near), a[1], HY - a[2], b[1], HY - b[2])
      if a[2] > b[2] and a[2] > 7 then
        -- a facet down from the peak, and the valley's crease
        local fx = a[1] + (a[1] < VX and -1 or 1) * (a[2] * 0.6)
        line(rl * 0.45, a[1], HY - a[2], fx, HY - 1)
        line(rl * 0.3, a[1], HY - a[2], (a[1] + b[1]) / 2 + 2, HY - 1)
      end
    end

    -- the chrome horizon: a bright line, a dark band, a reflection; a glint
    -- runs along it on each bar and on the ride
    line(5 + amp * 2 + hi * 2 + fl * 2, 0, HY, 127, HY)
    if sweep >= 0 then
      local gx = -10 + sweep * 150
      for k = -2, 2 do put((11 - abs(k) * 2.5) * sin(PI * sweep), gx + k * 3, HY, 3, 1) end
      put(5 * sin(PI * sweep), gx - 4, HY + 3, 9, 1)
    end

    -- the grid: long lines to the vanishing point, cross rows coming at us
    -- the haze lying along the far edge of the grid, in solid rows
    for y = HY + 2, HY + 3 do
      put(1 + (y - HY - 2) * 0.4 + amp * 0.6, 0, y, 128, 1)
    end
    -- the flash rolls in from the horizon: rows and lines above its
    -- front are lit
    local yf = HY + GH / (6 * (1 - front) + 0.45)
    local vl = 1.2 + hi * 2.5 + amp * 0.5 + e * 0.4
    for k = -7, 7 do
      local xb = VX + k * 16
      local l = vl * (1 - abs(k) * 0.03)
      local gy0 = HY + (abs(k) <= 1 and 4 or 6)
      local function xa(y) return VX + k * 16 * (y - HY) / (64 - HY) end
      if fl > 0.04 and yf > gy0 then
        local ym = min(64, yf)
        line(l + fl * 2, xa(gy0), gy0, xa(ym), ym)
        if ym < 64 then line(l, xa(ym), ym, xb, 64) end
      else
        line(l, xa(gy0), gy0, xb, 64)
      end
    end
    local ph1 = travel % 1
    local bend = c > 0.3 and (c - 0.3) * 2.5 or 0
    for k = 0, 9 do
      local z = (k + 1 - ph1) * 0.5 + 0.5
      local y = HY + GH / z
      if y >= HY + 10 and y < 64 then
        local near = min(1, 1.3 / z)
        local l = (0.7 + amp * 0.9 + e * 0.3) * (0.5 + 0.5 * near) + (K.duck * 0.7 + (y <= yf and fl * 2.6 or 0) * near) * near
        if bend > 0 and z < 2.2 then
          for s = 0, 7 do
            local yo = sin(T * 3 + k * 0.9 + s * 1.3) * bend * near
            line(l, s * 16, y + yo, s * 16 + 16, y + sin(T * 3 + k * 0.9 + (s + 1) * 1.3) * bend * near)
          end
        else
          line(l, 0, y, 127, y)
        end
      end
    end
    -- the rows the kick and ratchets send rushing in
    for j = #rushes, 1, -1 do
      local R = rushes[j]
      local age = K.T - R.t0
      if age > 0.6 then table.remove(rushes, j)
      elseif age >= 0 then
        local z = 7 * (1 - age / 0.6) + 0.5
        local y = HY + GH / z
        if y < 64 and y > HY + 8 then line(min(12, (1.5 + 4 * R.v) * (0.4 + 0.6 * age / 0.6)), 0, y, 127, y) end
      end
    end
    -- grid nodes sparking on the rims
    for j = #nodes, 1, -1 do
      local N = nodes[j]
      local age = K.T - N.t0
      if age > 0.4 then table.remove(nodes, j)
      else
        local z = N.r * 0.5 + 0.5
        local y = HY + GH / z
        local x = VX + N.k * 16 * (y - HY) / (64 - HY)
        local l = (5 + 7 * N.v) * (1 - age / 0.4)
        put(l, x - 1, y, 3, 1)
        put(l * 0.6, x, y - 1, 1, 3)
      end
    end
    -- kickless: fog lies on the grid
    if kl > 0.1 then K.haze(0, HY + 2, 128, HY + 16, kl * 0.55, 1 + kl, T * 5) end

    -- the chevrons falling through the sky
    for j = #chevs, 1, -1 do
      local C = chevs[j]
      local age = K.T - C.t0
      if age > 1.3 then table.remove(chevs, j)
      elseif age >= 0 then
        local y = -4 + age * 26
        local f = 1 - age / 1.3
        for s = 0, 2 do
          local yy = y - s * 4
          if yy > 0 and yy < HY - 2 then
            local l = (2.5 + 5 * C.v) * f * (1 - s * 0.38)
            line(l, C.x - 5, yy - 4, C.x, yy)
            line(l, C.x, yy, C.x + 5, yy - 4)
          end
        end
      end
    end
    K.grain(function(u, v) return u * 128, 2 + v * (HY - 18) end, 1 + hi * 10, 3 + hi * 5)
  end

  ---------------------------------------------------------------- view 2
  local HY2 = 28
  local CITY = K.profile(function(x)
    local d = abs(x - VX)
    if d < 14 then return HY2 - 1 end
    local b = x // 7
    local h = 3 + floor(K.hash(b, 51) * 9) + (d > 40 and 2 or 0)
    if K.hash(b, 52) < 0.15 then h = h + 6 end
    return HY2 - h
  end)

  local function rd(u, z, cx)                    -- road coords: u = -1..1 edges, z depth
    return cx + u * 58 / z, HY2 + 34 / z
  end

  local function palm(x, by, sc, l)
    local h = 34 * sc
    local lean = (x < VX and -1 or 1) * 5 * sc
    local mx, my = x + lean * 0.4, by - h * 0.5
    local tx, ty = x + lean, by - h
    line(l * 0.8, x, by, mx, my)
    line(l * 0.8, mx, my, tx, ty)
    if sc > 0.5 then line(l * 0.5, x + 1, by, mx + 1, my) end
    for f = 0, 5 do
      local a = -PI + f * PI / 5 + sin(K.T * 1.3 + f + x * 0.1) * 0.08
      local fl = (10 + (f % 2) * 3) * sc
      local ex, ey = tx + cos(a) * fl, ty + sin(a) * fl * 0.5
      local dx, dy = tx + cos(a) * fl * 1.25, ty + sin(a) * fl * 0.2 + fl * 0.45
      line(l, tx, ty, ex, ey)
      line(l * 0.8, ex, ey, dx, dy)
    end
  end

  local function car(cx, by, lv, lo, mid, hi, ghost)
    local w = 25
    local x0, x1 = cx - w, cx + w
    local rt = by - 15
    line(lv * 0.8, x0 + 12, rt, x1 - 12, rt)                       -- the roof
    line(lv * 0.8, x0 + 12, rt, x0 + 5, rt + 6)
    line(lv * 0.8, x1 - 12, rt, x1 - 5, rt + 6)
    line(lv, x0, rt + 6, x1, rt + 6)                               -- the deck
    line(lv * 0.8, x0, rt + 6, x0 - 1, by - 2)
    line(lv * 0.8, x1, rt + 6, x1 + 1, by - 2)
    if ghost then return end
    for y = rt + 1, rt + 5 do                                      -- the rear glass
      local u = (y - rt) / 6
      put(1 + mid * 1.5, x0 + 12 - u * 7 + 1, y, (x1 - x0) - 24 + u * 14 - 2, 1)
    end
    -- the tail panel: slats over it, the lamps at its ends
    local tl = 2 + tail * 5 + lo * 1.5
    put(1.5 + tail * 1.5, x0 + 1, rt + 7, x1 - x0 - 1, 6)
    for s = 0, 1 do line(2 + lo, x0 + 8, rt + 9 + s * 2, x1 - 8, rt + 9 + s * 2) end
    put(min(13, tl), x0 + 1, rt + 8, 6, 4)
    put(min(13, tl), x1 - 6, rt + 8, 6, 4)
    put(1, x0, rt + 13, x1 - x0, by - rt - 14)
    put(3 + hi * 3, cx - 5, rt + 14, 10, 2)                       -- the plate
    put(1.5, x0 + 1, by - 2, 9, 4)                                -- tyres
    put(1.5, x1 - 9, by - 2, 9, 4)
  end

  local function draw2(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local fl = fs
    steer = K.follow(steer, sin(T * 0.21) * 6 + (c > 0.3 and sin(T * 2.3) * c * 10 or 0), 0.3, DT)
    local cx = VX - steer * 0.3

    stars(HY2 - 12, hi, 1)
    -- the glow over the horizon, in solid bands (it holds still under a jolt)
    for b = 0, 2 do
      local l = 1 + b * (0.4 + amp * 0.35) + fl * 0.4 * b
      for y = HY2 - 9 + b * 3, HY2 - 7 + b * 3 do K.row_above(l, y, CITY) end
    end
    -- the sun behind the city
    local r = 9.5 + lo * 2
    sun(VX, HY2 - 5 + set * 4, r, HY2, min(11, 3.5 + lo * 2.5 + sunb * 2 + e), sph, CITY, c * 0.6)
    -- the skyline: rims and windows
    for x = 0, 126, 2 do
      local t, t2 = CITY[x // 2], CITY[x // 2 + 1]
      if t < HY2 - 1 and abs(t - t2) < 1 then put(1.5 + mid * 2, x, t, 2, 1) end
    end
    for i = 0, 26 do
      local x = floor(K.hash(i, 61) * 128)
      local top = K.at(CITY, x)
      if top < HY2 - 3 then
        local y = floor(top + 2 + K.hash(i, 62) * (HY2 - top - 3))
        local on = 0.5 + 0.5 * sin(T * 0.7 + i * 1.7)
        put(1 + mid * 3 * on + wins * 6 * K.hash(i, floor(T * 4)), x, y, 1, 1)
      end
    end
    line(1.5 + amp * 0.5 + hi * 0.5 + fl * 0.7, 0, HY2, 127, HY2)
    if sweep >= 0 then
      local gx = -10 + sweep * 150
      put(9 * sin(PI * sweep), gx - 4, HY2, 9, 1)
    end

    -- the grid fields either side of the road
    local gl = 1 + amp * 0.3 + fl * 1.2 + e * 0.2
    for k = 2, 7, 2 do
      for side = -1, 1, 2 do
        local xa, ya = rd(side * k * 0.55, 30, cx)
        local xb, yb = rd(side * k * 0.55, 0.9, cx)
        line(gl * (0.85 - k * 0.07), xa, HY2 + 1, xb, yb)
      end
    end
    local ph = travel % 1
    for k = 0, 5 do
      local z = (k + 1 - ph) * 0.9 + 0.6
      local y = HY2 + 34 / z
      if y < 64 then
        local lx = rd(-1.08, z, cx)
        local rx = rd(1.08, z, cx)
        local l = gl * min(1, 1.4 / z) + K.duck * 0.6 / z
        if lx > 0 then line(l, 0, y, lx, y) end
        if rx < 127 then line(l, rx, y, 127, y) end
      end
    end

    -- the road: its edges, the barrier on the left with chevron boards
    local el = 2 + amp * 1.2 + e * 0.3
    local lx0, ly0 = rd(-1, 40, cx)
    local lx1, ly1 = rd(-1, 0.9, cx)
    local rx1, ry1 = rd(1, 0.9, cx)
    line(el, lx0, ly0, lx1, ly1)
    line(el, cx + (cx - lx0), ly0, rx1, ry1)
    -- the lane marks, surging on the kick
    for k = 0, 7 do
      local d = (k + 1 - ph) * 0.9 + 0.4
      local xa, ya = rd(0, d + 0.35, cx)
      local xb, yb = rd(0, d, cx)
      if yb > HY2 + 1 and ya < 43 then
        yb = min(yb, 43)
        local l = (2.5 + amp * 2 + e) * (1 - k * 0.08) + (k == 0 and K.duck * 1.5 or 0)
        line(l, xa, ya, xb, min(63, yb))
        if yb - ya > 5 then line(l * 0.7, xa + 1, ya, xb + 1, min(63, yb)) end
        -- cat's eyes on both edges
        for side = -1, 1, 2 do
          local ex, ey = rd(side * 0.96, d, cx)
          put(1.5 + hi * 7 + K.env.hat * 6 * (1 - k * 0.1), ex, ey, 1, 1)
        end
      end
    end
    -- the chevron boards along the left barrier, a chase toward us on syntoms
    for b = 1, 6 do
      local z = ((b - ph * 0.5) % 6) * 0.9 + 0.8
      local x, y = rd(-1.25, z, cx)
      local sc = 1 / z
      local idx = (b + floor(travel * 0.5)) % 8 + 1
      local l = 1.5 + amp + boards[idx] * 10
      local h = max(2, 7 * sc)
      line(l * 0.5, x, y, x, y - h * 1.2)
      for s = 0, 1 do
        local xx = x + s * 3.5 * sc - 2 * sc
        line(l, xx + 2 * sc, y - h * 1.2, xx, y - h * 1.2 - h * 0.4)
        line(l, xx, y - h * 1.2 - h * 0.4, xx + 2 * sc, y - h * 1.2 - h * 0.8)
      end
    end

    -- the palms either side, two to a bar
    local pt = travel / 2
    for k = 0, 3 do
      local z = (k + 1 - pt % 1) * 1.3 + 0.35
      local sc = 1 / z
      for side = -1, 1, 2 do
        local x, y = rd(side * 1.7, z, cx)
        if x > -30 and x < 158 and z < 4.2 then palm(x, min(80, y), sc * 0.9, (1.2 + mid * 2.5 + sunb * 2) * min(1, 0.3 + sc * 0.8)) end
      end
    end

    -- kickless: a low mist on the road
    if kl > 0.1 then K.haze(0, HY2 + 2, 128, HY2 + 18, kl * 0.5, 1 + kl, T * 6) end

    -- the car, bouncing on the low end, its glow under it
    local bob = floor(lo * 1.6 + 0.5)
    local ccx = VX + steer
    if c > 0.4 then car(ccx - 10 - c * 10, 60 + bob, 1.5 + c, lo, mid, hi, true) end
    put(1 + lo * 3 + tail * 2, ccx - 20, 61, 40, 1)
    put(1 + lo * 1.5, ccx - 14, 62, 28, 1)
    car(ccx, 60 + bob, 2.2 + amp * 1.1 + e * 0.5, lo, mid, hi, false)
    K.grain(function(u, v) return u * 128, v * (HY2 - 12) end, 1 + hi * 10, 3 + hi * 5)
  end

  ---------------------------------------------------------------- view 3
  local NF = 9
  local function frame_at(z, ox, oy)
    local s = 1 / z
    return 64 + ox * s, 30 + oy * s, 44 * s, 26 * s
  end

  local function draw3(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local fl = fs
    local ph = phrase()
    nk = K.follow(nk, notch, 0.6, DT)
    twist = K.follow(twist, ph * 1.2 + fspin * PI / 4 + nk * PI / 8, 0.3, DT)
    local zt = tun % 1
    -- the tunnel's line: drifts slowly, thrown about by chaos
    local function off(z)
      local w = 5 + c * 14
      return sin(T * 0.4 + z * 0.5) * w + sin(T * 0.9 + z * 1.3) * c * 6,
        cos(T * 0.31 + z * 0.4) * (2 + c * 6)
    end

    -- the far end: a small striped sun and its glow
    local fx, fy = off(10)
    local sx, sy = 64 + fx * 0.1, 30 + fy * 0.1
    local sr = 5 + lo * 3 + K.duck * 0.8
    K.ring(1 + lo * 2 + amp, sx, sy, sr + 3 + lo * 2, 14)
    sun(sx, sy, sr, sy + sr + 1, min(11, 4 + lo * 5 + sunb * 2), sph * 1.5, nil, c)
    if kl > 0.1 then K.haze(24, 10, 104, 52, kl * 0.5, 1 + kl, T * 5) end

    -- the frames, far to near, and the struts that join their corners
    local prev
    local nearest
    for k = NF - 1, 0, -1 do
      local z = (k + 1 - zt) * 0.75 + 0.18
      local ox, oy = off(z)
      local cx, cy, rx, ry = frame_at(z, ox, oy)
      local near = clamp(1.2 / z, 0, 1.6)
      local idx = floor(tun) + k                 -- this frame's number
      local lit = 0
      if k == 0 then lit = K.duck * 3 end
      local rch = rat > 0.05 and max(0, 1 - abs(k - (1 - rat) * NF) * 0.7) * 5 or 0
      local l = (1 + amp * 1.0 + e * 0.4 + fl * 2) * min(1, 0.15 + near * 0.6) + lit + rch
      if idx % 4 == 0 then l = l + 1 end
      local tw = twist + z * ph * 0.25
      local pts = {}
      for v = 0, 8 do
        local a = (v + 0.5) * TAU / 8 + tw
        pts[v] = {cx + cos(a) * rx, cy + sin(a) * ry}
      end
      for v = 0, 7 do
        if rx < 8 then break end
        line(min(13, l), pts[v][1], pts[v][2], pts[v + 1][1], pts[v + 1][2])
        if c > 0.45 and v % 2 == 0 then
          line(l * 0.3, pts[v][1] + c * 4, pts[v][2] + 1, pts[v + 1][1] + c * 4, pts[v + 1][2] + 1)
        end
      end
      if prev and rx >= 8 then
        local sl = (0.8 + mid * 2 + e * 0.3) * min(1, 0.4 + near * 0.4)
        for v = 0, 7, 2 do
          line(sl, prev[v][1], prev[v][2], pts[v][1], pts[v][2])
        end
      end
      prev = pts
      nearest = pts
    end
    -- the struts run on off the screen from the nearest frame
    if nearest then
      for v = 0, 7, 2 do
        local x, y = nearest[v][1], nearest[v][2]
        line(0.8 + mid * 1.6, x, y, x + (x - 64) * 0.8, y + (y - 30) * 0.8)
      end
    end

    -- the warp dust: specks streaking out from the far end
    local nd = floor(4 + hi * 10 + e * 4)
    for i = 0, nd - 1 do
      local sp = 0.6 + K.hash(i, 71) * 0.8
      local u = (T * sp * (0.4 + play * 0.6) + K.hash(i, 72)) % 1
      local a = K.hash(i, 73) * TAU + twist * 0.3
      local rr = 4 + u * u * 70
      local x, y = sx + cos(a) * rr, sy + sin(a) * rr * 0.55
      local l = (1 + hi * 3.5) * u
      line(l, x, y, x - cos(a) * u * 3, y - sin(a) * u * 1.5)
    end
    -- the hats' sparks
    for j = #sparks, 1, -1 do
      local P = sparks[j]
      local age = K.T - P.t0
      local life = 0.25 + P.len * 0.25
      if age > life then table.remove(sparks, j)
      else
        local u = age / life
        local r0, r1 = 8 + u * 50, 8 + u * 50 + 6 + P.len * 12
        local l = (5 + 7 * P.v) * (1 - u)
        line(l, sx + cos(P.a) * r0, sy + sin(P.a) * r0 * 0.55, sx + cos(P.a) * r1, sy + sin(P.a) * r1 * 0.55)
      end
    end
    -- the chevrons flying at us along the floor
    for j = #chevs, 1, -1 do
      local C = chevs[j]
      local age = K.T - C.t0
      if age > 1.0 then table.remove(chevs, j)
      elseif age >= 0 then
        local z = 7 * (1 - age) + 0.35
        local ox, oy = off(z)
        local cx, cy, rx, ry = frame_at(z, ox, oy)
        local s = 1 / z
        local y = cy + ry * 0.62
        local x = cx + (C.x - 64) * 0.25 * s
        local l = min(12, (3 + 8 * C.v) * min(1, age * 3))
        for k = 0, 1 do
          local yy = y - k * 5 * s
          line(l * (1 - k * 0.4), x - 7 * s, yy - 4 * s, x, yy)
          line(l * (1 - k * 0.4), x, yy, x + 7 * s, yy - 4 * s)
        end
      end
    end
  end

  function M.draw(S)
    local DT = K.DT
    -- the gate: holds while the snare rings, then cuts
    local gt = (K.NOW - gate_t < 0.1 + K.energy * 0.05) and gate_v or 0
    if gt > fs then fs = gt else fs = K.follow(fs, gt, 0.12, DT) end
    front = clamp((K.NOW - gate_t) / 0.14, 0, 1)
    sunb = sunb * math.exp(-DT / 0.8)
    sph = sph + K.DTS * (1.2 + sunb * 4)
    mrim = mrim * math.exp(-DT / 0.5)
    rat = rat * math.exp(-DT / 0.35)
    tail = tail * math.exp(-DT / 0.2)
    run = run * math.exp(-DT / 0.4)
    wins = wins * math.exp(-DT / 0.6)
    for i = 1, 8 do boards[i] = boards[i] * math.exp(-DT / 0.3) end
    if run > 0.05 then
      local i = floor((1 - run) * 8) % 8 + 1
      boards[i] = max(boards[i], run)
    end
    if sweep >= 0 then
      sweep = sweep + K.DTS / 0.9
      if sweep > 1 then sweep = -1 end
    end
    play = K.follow(play, K.playing and 1 or 0, 0.8, DT)
    set = K.follow(set, phrase(), 1.5, DT)
    -- the ground runs on: slower in silence and the kickless stretches,
    -- surging on each kick
    local sp = (0.35 + 0.35 * play + K.energy * 0.3) * (1 - K.kickless * 0.5) + K.duck * (K.view == 1 and 0.9 or 0.2)
    travel = travel + K.DTS / K.beat_sec * sp
    tun = tun + K.DTS / K.beat_sec * (0.16 + 0.14 * play + K.duck * 0.08) * (1 - K.kickless * 0.45)
    if K.view == 2 then draw2(S) elseif K.view == 3 then draw3(S) else draw1(S) end
  end

  M.init()
  return M
end
