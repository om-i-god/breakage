-- footwork. view 1: a battle circle seen from above at an angle, a ring of onlookers round a lit pool and a dancer's sneakers blurring through the steps.
-- view 2: a pair of sneakers in close-up on a floor lit by the speaker stacks behind them; every hit is a step that leaves a light trail.
--
-- view 1: kicks are foot strikes that leave glowing footprints on the floor;
-- hats flick the free foot (blur trails); toms throw the dancer into a spin
-- (a motion ring round him); snares and claps clap the crowd's hands up and
-- flash the pool; vox chops (perc 16) send a hype shout rippling round the
-- ring of onlookers, arms going up as it passes; ticks are phone flashes in
-- the crowd; ratchets run a burst of prints, fills raise the whole crowd.
-- out_amp lights the overhead lamp and its pool, out_lo bounces the crowd
-- and pumps the pool's core, out_mid lights the chalk circle and the faces,
-- out_hi glints the sneakers and the dust in the lamp. energy fills the
-- ring and speeds the steps, chaos brings ghost dancers and scatters the
-- prints, kickless stretches slow him into a glide and set the crowd swaying.
-- view 2: kicks stomp the near shoe (a pool of light where it lands),
-- snares tap the far toe with sparks, hats lift the heels, toms twist a
-- shoe across the floor in an arc, vox chops flare the speaker cones and the
-- LED strip. out_lo pumps the cones and the floor glow in front of them,
-- out_mid lights the floor's seams and the shoes' rims, out_hi glints the
-- laces and the floor sparkle, out_amp lights the LED strip between stacks.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, sqrt = math.sin, math.cos, math.floor, math.max, math.min, math.abs, math.sqrt
  local PI = math.pi

  -- a stippled row: one pixel in `gap`, staggered row to row (dim atmosphere
  -- that reads as a grey without lighting the whole area)
  local function stip(l, y, x0, x1)
    put(l, floor(x0), y, floor(x1) - floor(x0), 1)
  end

  ---------------------------------------------------------------- view 1 state
  local CX, CY, RX, RY = 64, 40, 44, 13          -- the floor ellipse
  local NCR = 24                                  -- onlookers
  local prints, waves, phones
  local feet                                      -- two feet: {u, v, tu, tv, tr = trail}
  local fi                                        -- the foot that strikes next
  local spin, spinv, sring
  local clapt, pool, fillt, rat
  local crowd_arm                                  -- per onlooker: arms up 0..1
  local MAXP = 18

  ---------------------------------------------------------------- view 2 state
  local shoes                                     -- {x, y, x0, x1, t0, dur, h, lift, tw, trail}
  local glows, sparks
  local cone2, flare, strip
  local cs2, fs2

  function M.init()
    prints, waves, phones = {}, {}, {}
    feet = {{u = -3, v = 0, tu = -3, tv = 0, tr = {}}, {u = 3, v = 0, tu = 3, tv = 0, tr = {}}}
    fi = 1
    spin, spinv, sring = 0, 0, 0
    clapt, pool, fillt, rat = 0, 0, 0, 0
    crowd_arm = {}
    for i = 1, NCR do crowd_arm[i] = 0 end
    shoes = {
      {x = 20, y = 49, x0 = 20, x1 = 20, t0 = -9, dur = 0.2, h = 0, lift = 0, tw = 0, trail = {}, L = 27, far = true},
      {x = 62, y = 61, x0 = 62, x1 = 62, t0 = -9, dur = 0.2, h = 0, lift = 0, tw = 0, trail = {}, L = 36, far = false},
    }
    glows, sparks = {}, {}
    cone2, flare, strip = 0, 0, 0
    cs2, fs2 = 0, 0
  end
  M.clear = M.init

  -- floor plane (u, v) round the dancer to the screen
  local function proj(u, v, cx, cy) return cx + u * 1.4, cy + v * 0.55 end

  local function dancer_c()
    local e, kl = K.energy, K.kickless
    local x = CX + sin(K.T * (0.35 + kl * 0.25)) * (6 + e * 6 + kl * 10)
    local y = CY + 1 + sin(K.T * 0.23) * 2
    return x, y
  end

  local function stamp(x, y, lv)
    if #prints >= MAXP then table.remove(prints, 1) end
    prints[#prints + 1] = {x = x, y = y, t0 = K.T, lv = lv}
  end

  -- a foot strike: the foot jumps to a new spot and leaves a print
  local function strike(v, wide)
    local f = feet[fi]
    fi = 3 - fi
    local c = K.chaos
    local r = 4 + K.rnd() * (5 + (wide or 0) + c * 8)
    local a = K.rnd() * K.TAU
    f.tu, f.tv = cos(a) * r, sin(a) * r * 0.9
    local cx, cy = dancer_c()
    local ca, sa = cos(spin), sin(spin)
    local x, y = proj(f.tu * ca - f.tv * sa, f.tu * sa + f.tv * ca, cx, cy)
    stamp(x, y, 4 + 7 * v)
  end

  local function shout(v, a0)
    if #waves >= 4 then table.remove(waves, 1) end
    waves[#waves + 1] = {t0 = K.T, a0 = a0 or (K.rnd() * K.TAU), v = v}
  end

  -- view 2: a shoe steps from where it is to x1
  local function step(i, dx, h, dur, tw)
    local s = shoes[i]
    s.x0 = s.x
    local lo, hi = s.far and 4 or 30, s.far and 62 or 86
    dx = dx * 0.7
    local nx = s.x + dx
    if nx < lo or nx > hi then nx = s.x - dx end
    s.x1 = clamp(nx, lo, hi)
    s.t0, s.dur, s.hop, s.tw = K.T, dur * 1.6, h, tw or 0
  end

  local function glow2(x, y, lv, w)
    if #glows >= 5 then table.remove(glows, 1) end
    glows[#glows + 1] = {x = x, y = y, t0 = K.T, lv = lv * 0.6, w = w}
  end

  function M.kick(v)
    v = K.num(v, 1)
    strike(v)
    pool = max(pool, 0.6 + 0.4 * v)
    -- view 2: the near shoe stomps
    step(2, (K.rnd() - 0.5) * 22, 2 + v, 0.22)
    cone2 = 1
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    clapt = max(clapt, 0.7 + 0.3 * v)
    pool = max(pool, 0.4 * v)
    for i = 1, NCR do if K.hash(i, floor(K.T * 3)) < 0.45 then crowd_arm[i] = max(crowd_arm[i], 0.8 * v) end end
    step(1, (K.rnd() - 0.5) * 14, 3, 0.18, 1)
    local s = shoes[1]
    for k = 1, 4 do
      if #sparks >= 14 then table.remove(sparks, 1) end
      local a = -PI * (0.15 + 0.7 * K.rnd())
      sparks[#sparks + 1] = {x = s.x1 + s.L - 3, y = s.y, vx = cos(a) * 30, vy = sin(a) * 24, t0 = K.T}
    end
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.85) end
  function M.rim(v) M.hat(K.num(v, 1) * 0.8, false) end

  function M.hat(v, open)
    v = K.num(v, 1)
    local f = feet[fi]
    f.tu = f.tu + (K.rnd() - 0.5) * 5
    f.tv = f.tv + (K.rnd() - 0.5) * 4
    local i = (K.step % 2) + 1
    if open then step(i, (K.rnd() - 0.5) * 10, 3, 0.22) else
      local s = shoes[i]
      s.lift = max(s.lift, 0.6 * v)
    end
  end

  function M.tom(v, hz)
    v = K.num(v, 1)
    spinv = clamp(spinv + 9 * v, -24, 24)
    sring = max(sring, v)
    strike(v * 0.6, 3)
    local i = K.rnd() < 0.5 and 1 or 2
    step(i, (K.rnd() < 0.5 and -1 or 1) * (10 + 6 * v), 4, 0.3, (K.rnd() < 0.5 and -1 or 1))
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 16 then
      shout(v)
      flare = 1
    elseif kind == 17 or kind == 7 or kind == 13 then
      M.tom(v * 0.8)
    elseif kind == 1 or kind == 2 then
      strike(v * 0.6)
      step(K.rnd() < 0.5 and 1 or 2, (K.rnd() - 0.5) * 12, 2, 0.18)
    else
      local i = 1 + floor(K.rnd() * NCR)
      if #phones < 6 then phones[#phones + 1] = {i = i, t0 = K.T} end
      shoes[1].lift = max(shoes[1].lift, 0.4 * v)
      strip = max(strip, 0.4 * v)
    end
  end

  function M.tick(kind)
    local i = 1 + floor(K.rnd() * NCR)
    if #phones < 6 then phones[#phones + 1] = {i = i, t0 = K.T} end
    strip = max(strip, 0.25)
  end

  function M.brk(s, n, rev)
    s, n = K.num(s, 1), max(1, K.num(n, 8))
    local cx, cy = dancer_c()
    local a = (s - 0.5) / n * K.TAU
    stamp(cx + cos(a) * 12, cy + sin(a) * 5, 4)
    if s % 2 == 1 then
      local i = s % 2 + 1
      shoes[i].lift = max(shoes[i].lift, 0.5)
    end
  end

  function M.ratchet(n, voice)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    local cx, cy = dancer_c()
    local a = K.rnd() * K.TAU
    for k = 0, n - 1 do
      stamp(cx + cos(a) * (3 + k * 2.2), cy + sin(a) * (1.5 + k * 0.9) + (k % 2) * 2 - 1, 9 - k * 0.5)
    end
    rat = 1
    for k = 1, min(n, 6) do
      glow2(20 + k * 14, 52 + (k % 2) * 6, 6, 8)
    end
    shoes[1].lift, shoes[2].lift = 0.8, 0.8
  end

  function M.fill()
    fillt = 1
    shout(1, PI * 0.5)
    shout(0.8, -PI * 0.5)
    spinv = spinv + 12
    flare = 1
  end

  ---------------------------------------------------------------- view 1
  -- an onlooker at angle a round the ellipse
  local function onlooker(i, a, lo, mid, hi, e, kl, hype)
    local s = sin(a)
    local depth = (s + 1) * 0.5                   -- 0 back .. 1 front
    local sc = 0.75 + depth * depth * 1.7
    local fx = CX + cos(a) * (RX + 5 + depth * 3)
    local fy = CY + s * (RY + 6 + depth * 9)
    local ph = K.hash(i, 5) * K.TAU
    local bob = lo * 1.8 * max(0, sin(K.TAU * K.beat_ph + ph * 0.3)) + 0.6 * sin(K.T * 1.3 + ph)
    local sway = kl * 2 * sin(K.T * 1.6 + ph * 0.2)
    fx = fx + sway
    fy = fy - bob
    local arm = max(crowd_arm[i], hype, fillt * 0.9)
    -- the body: back row faces us lit by the pool, front row a dark back
    local face = 1 - depth
    local bl = 1 + face * (1 + mid * 2.5 + pool * 1.2) + e * 0.4
    local bw = floor(3 + sc * 2.5)
    local bh = floor(4 + sc * 3)
    put(bl * 0.8, fx - bw / 2, fy - bh, bw, depth > 0.6 and 3 or 2)
    if depth < 0.6 then put(bl * 0.6, fx - bw / 2 + 1, fy - bh + 2, bw - 2, bh - 2) end
    local hr = 1.2 + sc * 1.0
    local hy = fy - bh - hr
    K.disc(bl + face * 0.8 + hype * 3, fx, hy, hr)
    -- the front row's heads catch the pool on their crowns
    if depth > 0.6 then put(2 + mid * 3 + pool * 2, fx - hr + 1, hy - hr, hr * 2 - 1, 1) end
    if arm > 0.05 then
      local al = 2 + arm * 6 + hype * 3
      local up = (3 + sc * 3) * arm
      line(al, fx - bw / 2, fy - bh + 1, fx - bw / 2 - 2, fy - bh - up)
      line(al, fx + bw / 2, fy - bh + 1, fx + bw / 2 + 2, fy - bh - up)
      if clapt > 0.3 then put(3 + clapt * 6, fx - 1, fy - bh - up - 1, 2, 1) end
    end
    return fx, hy
  end

  local function draw_dancer(cx, cy, lv, hi, ghost)
    local ca, sa = cos(spin), sin(spin)
    local hx, hy = cx, cy - 10                    -- hips
    -- the legs and feet
    for k = 1, 2 do
      local f = feet[k]
      local u, v = f.u * ca - f.v * sa, f.u * sa + f.v * ca
      local x, y = proj(u, v, cx, cy)
      local kx = hx + (k == 1 and -1 or 1)
      local mx, my = (kx + x) / 2 + (k == 1 and -2 or 2), (hy + y) / 2 - 1
      line(lv * 0.8, kx, hy, mx, my)
      line(lv * 0.8, mx, my, x, y - 1)
      if not ghost then
        -- the blur trail
        local tr = f.tr
        for j = 2, #tr do
          local q, p = tr[j], tr[j - 1]
          line((lv * 0.6 + hi * 3) * (1 - j / (#tr + 1)), p[1], p[2], q[1], q[2])
        end
      end
      put(min(13, lv + 2 + hi * 4), x - 2, y - 1, 4, 2)
    end
    -- the torso, the head, the arms (out wide when he spins)
    local sx, sy = hx + sin(spin) * 1.5, hy - 11
    line(lv, hx - 1, hy, sx - 1, sy)
    line(lv, hx + 1, hy, sx + 1, sy)
    line(lv * 0.8, sx - 2, sy + 1, sx + 2, sy + 1)
    K.disc(lv + 1, sx, sy - 3, 2.6)
    local reach = 6 + min(5, abs(spinv) * 0.3)
    local sw = sin(K.T * 7 + K.beat_ph * K.TAU)
    line(lv * 0.8, sx, sy + 1, sx + ca * reach, sy + 1 + sa * reach * 0.4 + sw)
    line(lv * 0.8, sx, sy + 1, sx - ca * reach, sy + 1 - sa * reach * 0.4 - sw)
  end

  local function draw1(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local cx, cy = dancer_c()

    -- feet: ease toward their targets, idle shuffle, and record the trails
    local rate = 0.5 + e * 0.7 - kl * 0.25
    for k = 1, 2 do
      local f = feet[k]
      local base = k == 1 and -3 or 3
      f.tu = K.follow(f.tu, base, 0.6, DT)
      f.tv = K.follow(f.tv, 0, 0.6, DT)
      local sh = sin(T * K.TAU * rate * 2 + k * PI) * (1.5 + e * 1.5)
      f.u = K.follow(f.u, f.tu + sh, 0.035, DT)
      f.v = K.follow(f.v, f.tv + cos(T * K.TAU * rate + k) * 1.2, 0.035, DT)
      local ca, sa = cos(spin), sin(spin)
      local x, y = proj(f.u * ca - f.v * sa, f.u * sa + f.v * ca, cx, cy)
      table.insert(f.tr, 1, {x, y})
      if #f.tr > 5 then f.tr[#f.tr] = nil end
    end
    spinv = spinv * math.exp(-DT / 0.45)
    spin = spin + (spinv + kl * 1.5 + 0.4) * K.DTS

    -- the back wall: a dim hall, the lamp's cone and two stacks
    for y = 11, 20, 3 do stip(0.8 + (y - 10) / 10 * (0.5 + amp * 1.5 + e * 0.5), y, 0, 128) end
    for k = 0, 2 do K.dashes(1 + amp, 3 + k * 3, 8, 12, k * 4) end
    line(1 + amp * 2 + hi * 2, 0, 21, 127, 21)
    for side = 0, 1 do
      local x0 = side == 0 and 4 or 106
      line(1.5, x0, 6, x0 + 17, 6); line(1.5, x0, 6, x0, 20); line(1.5, x0 + 17, 6, x0 + 17, 20)
      local pr = 3.5 + lo * 1.5 + K.env.kick * 1.2
      K.ring(2 + lo * 4 + K.env.kick * 3, x0 + 9, 14, pr, 10)
      put(2 + hi * 5, x0 + 8, 8, 2, 1)
    end
    -- the overhead lamp and its cone of dust
    local lamp = 0.4 + amp * 0.6 + pool * 0.3 + e * 0.2
    put(4 + lamp * 6, CX - 4, 0, 9, 2)
    for y = 3, 25, 3 do
      local u = y / 26
      local hw = 5 + u * 30
      K.dashes(lamp * (0.4 + hi * 2.2), y, 1, 6, T * (6 + hi * 20) + y * 7, floor(CX - hw), floor(CX + hw))
    end

    -- the floor: the ellipse, the pool under the lamp, the chalk circle
    for y = CY - RY, CY + RY do
      local dy = (y - CY) / RY
      local hw = RX * sqrt(max(0, 1 - dy * dy))
      local pr = (0.3 + lo * 0.15 + pool * 0.1)
      local phw = hw * pr
      if y % 4 == 0 then stip(1 + amp * 1.5 + e * 0.5, y, CX - hw, CX + hw) end
      if y % 4 == 1 then K.dashes(1 + hi * 4, y, 1, 9, T * 3 + y * 5, floor(CX - hw), floor(CX + hw)) end
      if phw > 1 then
        local core = 0.6 + lamp * 0.8 + lo * 1.4 + pool * 2 - kl * 0.5
        K.gradient(y, y, function() return core * (1 - abs(dy) * 0.5) end, nil, floor(CX - phw), floor(CX + phw))
      end
    end
    K.ring(2 + mid * 4 + clapt * 2, CX, CY, RX - 3, 30, 0, K.TAU, RY / RX * 1.05)
    if kl > 0.2 then K.ring(kl * (2 + mid * 2), CX, CY, RX * 0.45, 20, 0, K.TAU, 0.3) end

    -- the prints, glowing and fading on the floor
    for i = #prints, 1, -1 do
      local P = prints[i]
      local age = T - P.t0
      local life = 1.4 + e * 0.8 + kl
      if age > life then table.remove(prints, i)
      else
        local u = age / life
        local l = P.lv * (1 - u) ^ 1.3 + hi * (1 - u)
        local x, y = P.x, P.y
        if c > 0.3 then x = x + sin(i * 2.1 + T) * c * 4 end
        put(l, x - 1, y, 3, 1)
        put(l * 0.7, x, y - 1, 2, 1)
        if age < 0.35 then K.ring(l * 0.7 * (1 - age / 0.35), x, y, 2 + age * 18, 10, 0, K.TAU, 0.42) end
      end
    end
    if sring > 0.05 then
      K.ring(2 + sring * 7, cx, cy - 3, 10 + (1 - sring) * 5, 16, spin, spin + K.TAU * 0.8, 0.42)
    end

    -- the dancer (and his ghosts under chaos)
    if c > 0.35 then
      local n = c > 0.7 and 2 or 1
      for g = 1, n do
        local gx = cx + (g == 1 and -1 or 1) * (14 + c * 10) + sin(T * 1.7 + g) * 3
        draw_dancer(gx, cy + (g - 1.5), 2 + c * 2, hi, true)
      end
    end
    draw_dancer(cx, cy, 6 + pool * 3 + e * 1.5, hi, false)

    -- the ring of onlookers: back half first, then the front row
    local hype = {}
    for i = 1, NCR do hype[i] = 0 end
    for j = #waves, 1, -1 do
      local W = waves[j]
      local age = T - W.t0
      if age > 1.6 then table.remove(waves, j)
      else
        local front = W.a0 + age * 4.5
        local back = W.a0 - age * 4.5
        for i = 1, NCR do
          local a = (i - 0.5) / NCR * K.TAU
          for _, f in ipairs({front, back}) do
            local d = (a - f + PI) % K.TAU - PI
            local b = math.exp(-d * d * 3) * W.v * (1 - age / 1.6)
            if b > hype[i] then hype[i] = b end
          end
        end
      end
    end
    local shown = 0.55 + e * 0.45
    local ord = {}
    for i = 1, NCR do ord[i] = i end
    table.sort(ord, function(p, q)
      return sin((p - 0.5) / NCR * K.TAU) < sin((q - 0.5) / NCR * K.TAU)
    end)
    local heads = {}
    for _, i in ipairs(ord) do
      local a = (i - 0.5) / NCR * K.TAU + sin(K.hash(i, 9) * 6) * 0.06
      if K.hash(i, 3) < shown or sin(a) > 0.5 then
        local x, y = onlooker(i, a, lo, mid, hi, e, kl, hype[i])
        heads[i] = {x, y}
        if hype[i] > 0.3 then K.ring(hype[i] * 5, x, y, 3 + hype[i] * 2, 8) end
      end
    end
    -- phones held up: a short bright glint
    for j = #phones, 1, -1 do
      local P = phones[j]
      local age = T - P.t0
      if age > 0.5 then table.remove(phones, j)
      else
        local h = heads[P.i]
        if h then put(9 * (1 - age / 0.5) + 2, h[1] + 1, h[2] - 4, 1, 2) end
      end
    end
    K.grain(function(u, v) return CX - 24 + u * 48, 4 + v * 22 end, 2 + hi * 16 + e * 4, 3 + hi * 4)
    if rat > 0.05 then K.ring(rat * 6, cx, cy - 2, 6 + (1 - rat) * 14, 14, 0, K.TAU, 0.42) end
  end

  ---------------------------------------------------------------- view 2
  local VPX, VPY, FY = 64, 14, 30                 -- vanishing point, floor's back edge

  local function shoe(s, mid, hi, e, lv)
    local x, y, L = s.x, s.y - s.h, s.L
    local tilt = s.lift                            -- heel up (0..1)
    local hh = s.far and 8 or 11
    local ol = 1.5 + mid * 1.5 + lv * 0.2          -- outline
    local hy = y - tilt * 2                        -- heel's sole y
    -- the pant leg rising out of frame: two seams and a cuff
    local ax0, ax1 = x + 4, x + floor(L * 0.42)
    local top = hy - hh - 2
    line(1.5 + mid, ax0, 0, ax0 - 1, top)
    line(1.5 + mid, ax1, 0, ax1 + 1, top)
    line(1, (ax0 + ax1) / 2, 0, (ax0 + ax1) / 2, top - 2)
    put(1, ax0, top - 3, ax1 - ax0 + 1, 3)
    line(1.5 + mid, ax0 - 1, top, ax1 + 1, top)
    -- the upper, row by row (every other row filled, so it reads as a
    -- shaded body), tapering to the toe; the heel lifts with tilt
    local px0, px1
    for r = 0, hh - 1 do
      local u = r / hh
      local x0 = x + u * 2
      local x1 = x + L - 1 - u * u * L * 0.5
      local yy = floor(y - 3 - r - tilt * 2 * (1 - u * 0.5) + 0.5)
      put(1 + mid * 0.6, x0 + 1, yy, x1 - x0 - 2, 1)
      put(ol, x1, yy, 1, 1)
      if r == hh - 1 then line(ol, x0, yy, x1, yy) end
      px0, px1 = x0, x1
    end
    line(ol, x, hy - 3, x + 2, hy - 2 - hh)        -- the heel counter
    -- the sole: the brightest line, and the midsole under it
    local sl = lv + mid * 2
    line(sl, x, hy - 2, x + L, y - 2)
    -- a side stripe and the laces, glinting with the highs
    line(1.5 + mid * 2, x + 6, hy - 6, x + L * 0.62, y - 4 - tilt)
    for k = 0, 3 do
      put(2 + hi * 5 + e, x + L * 0.45 + k * 3, y - hh - 1 + k * 1.5 - tilt * 1.5, 2, 1)
    end
    -- the toe cap
    line(ol, x + L - 7, y - 3, x + L - 1, y - 4)
  end

  local function draw2(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    cone2 = cone2 * math.exp(-DT / 0.14)
    flare = flare * math.exp(-DT / 0.35)
    strip = strip * math.exp(-DT / 0.25)
    cs2 = K.follow(cs2, cone2, 0.05, DT)
    fs2 = K.follow(fs2, flare, 0.06, DT)

    -- the LED strip between the stacks and the wall behind
    local sl = 1 + amp * 1.2 + strip * 3 + fs2 * 3 + e * 0.5
    for x = 37, 91, 6 do line(0.8 + amp * 1.6 + fs2 * 2.5 + (x % 12 == 1 and hi * 2 or 0), x, 3, x, FY - 1) end
    for k = 0, 11 do
      local w = 0.5 + 0.5 * sin(T * 2 + k * 0.9 + fs2 * 6)
      put(sl * (0.6 + 0.4 * w), 36 + k * 5, 18, 3, 1)
    end
    -- the speaker stacks: boxes, two cones each, pumping with the sub
    for side = 0, 1 do
      local x0 = side == 0 and 2 or 96
      for gx = x0 + 3, x0 + 27, 6 do line(1 + amp * 0.8, gx, 3, gx, FY - 2) end
      line(1.2 + amp, x0, 1, x0 + 29, 1)
      line(1.5, side == 0 and x0 + 29 or x0, 1, side == 0 and x0 + 29 or x0, FY - 1)
      for b = 0, 1 do
        local by = 8 + b * 13
        local r = 4.5 + cs2 * 1.2 + lo * 1.4
        K.ring(1.5 + lo * 1.2 + cs2 * 1.5 + fs2 * 2, x0 + 15, by, r, 12)
        K.ring(1 + lo * 1, x0 + 15, by, r - 2.5, 8)
        K.disc(2 + lo * 3 + cs2 * 5 + fs2 * 4, x0 + 15, by, 1.2)
      end
    end

    -- the floor: seams converging on the vanishing point, lit in front of
    -- the stacks by the sub
    for y = FY, 63 do
      local u = (y - FY) / (63 - FY)
      if y % 6 == 0 then K.dashes(1 + mid * 0.5 + hi, y, 1, 9, T * 2 + y, 0, 128) end
    end
    -- light from the stacks fanning across the floor
    for side = 0, 1 do
      local x = side == 0 and 17 or 111
      for r = -2, 2 do
        local spread = 6 + lo * 3
        local l = (0.8 + lo * 0.8 + cs2 * 1.2 + amp * 0.2) * (1 - abs(r) * 0.25)
        line(l, x + r * 2, FY + 1, x + r * spread, 63)
      end
    end
    for k = -2, 2 do
      local xb = VPX + k * 40
      local x0 = VPX + (xb - VPX) * (FY - VPY) / (63 - VPY)
      line(1 + mid * 0.8 + K.env.snare * 1.5, x0, FY, xb, 63)
    end
    K.dashes(1 + amp * 0.8 + mid * 0.6, FY, 3, 6, T * 1.5)

    -- the shoes: step, lift and leave trails
    for i = 1, 2 do
      local s = shoes[i]
      local u = clamp((T - s.t0) / s.dur, 0, 1)
      s.x = s.x0 + (s.x1 - s.x0) * K.ease(u)
      local hh = (u < 1) and sin(PI * u) * (s.hop or 0) or 0
      local idle = (0.5 + 0.5 * sin(T * K.TAU / K.beat_sec * 0.5 + i * PI)) * (0.6 + e)
      s.lift = s.lift * math.exp(-DT / 0.12)
      local shh = hh + idle * 0.8
      local yb = s.y - shh
      if u >= 1 and T - s.t0 < s.dur + DT * 1.5 then
        glow2(s.x + s.L / 2, s.y, 6 + (i == 2 and 3 or 0), s.L * 0.6)
      end
      table.insert(s.trail, 1, {s.x + s.L - 2, yb - 2, s.x + 2, yb - 2})
      if #s.trail > 6 then s.trail[#s.trail] = nil end
      s.drawh = shh
    end
    -- the glows where the shoes landed
    for j = #glows, 1, -1 do
      local G = glows[j]
      local age = T - G.t0
      local life = 0.9 + e * 0.5
      if age > life then table.remove(glows, j)
      else
        local u = age / life
        local w = G.w * (0.5 + u * 0.5)
        local l = G.lv * (1 - u) ^ 1.4
        for dy = 0, 1 do
          K.gradient(G.y + dy, G.y + dy, function() return l * (1 - abs(dy) * 0.4) end, nil,
            floor(G.x - w * (1 - abs(dy) * 0.3)), floor(G.x + w * (1 - abs(dy) * 0.3)))
        end
        K.ring(l * 0.6, G.x, G.y, w * 0.6 + u * 10, 14, 0, K.TAU, 0.25)
      end
    end
    -- the trails: the toe and the heel's recent paths, fading
    for i = 1, 2 do
      local tr = shoes[i].trail
      for j = 2, #tr do
        local p, q = tr[j - 1], tr[j]
        local f = 1 - j / (#tr + 1)
        if abs(p[1] - q[1]) + abs(p[2] - q[2]) > 0.3 then
          line((2 + hi * 4 + e) * f, p[1], p[2], q[1], q[2])
          line((1.5 + hi * 2) * f, p[3], p[4], q[3], q[4])
        end
      end
    end
    -- chaos: ghost shoes, out of step
    if c > 0.5 then
      for i = 1, 2 do
        local s = shoes[i]
        local gx = s.x + sin(T * 3.1 + i) * (6 + c * 14)
        local saved = s.x
        s.x = gx; s.h = (s.drawh or 0) + c * 3
        shoe(s, 0, 0, 0, 1.5 + c)
        s.x = saved
      end
    end
    for i = 1, 2 do
      local s = shoes[i]
      s.h = s.drawh or 0
      shoe(s, mid, hi, e, 7 + e)
    end
    -- sparks off the toe
    for j = #sparks, 1, -1 do
      local P = sparks[j]
      local age = T - P.t0
      if age > 0.45 then table.remove(sparks, j)
      else
        local x = P.x + P.vx * age
        local y = P.y + P.vy * age + 60 * age * age
        line(9 * (1 - age / 0.45), x, y, x - P.vx * 0.03, y - P.vy * 0.03)
      end
    end
    K.grain(function(u, v) return u * 128, FY + 2 + v * 30 end, 2 + hi * 18 + e * 4, 3 + hi * 5)
  end

  function M.draw(S)
    local DT = K.DT
    clapt = clapt * math.exp(-DT / 0.18)
    pool = pool * math.exp(-DT / 0.2)
    fillt = fillt * math.exp(-DT / 0.7)
    rat = rat * math.exp(-DT / 0.3)
    sring = sring * math.exp(-DT / 0.35)
    for i = 1, NCR do crowd_arm[i] = crowd_arm[i] * math.exp(-DT / 0.2) end
    if K.view == 2 then draw2(S) else draw1(S) end
  end

  M.init()
  return M
end
