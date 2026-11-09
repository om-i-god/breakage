-- tribal. view 1: a bonfire at night in a forest clearing, dancers circling it,
-- two seated drummers in the foreground and a log drum at our feet.
-- view 2: a stone circle on a hill under a huge starfield and a low moon; each
-- stone holds a voice and lights from within.
--
-- view 1: the kick flares the fire, throws a burst of sparks and makes the
-- dancers hop; snares and claps spray sparks and the dancers clap overhead;
-- toms, congas and bongos make the left drummer strike, the talking drum the
-- right one (its waist squeezes with the bend); log hits light the slit drum
-- in front of us; tambourine and shaker glint in the dancers' hands; ticks pop
-- embers; break slices make one dancer stamp; ratchets throw spark chains and
-- a fill rolls both drummers and roars the fire. the tree line flickers in the
-- firelight. energy grows the fire, the glow and the ring of dancers; chaos
-- swirls the sparks and scatters the dancers into ghosts; kickless stretches
-- let the fire die to embers, the dancers slow, and the stars come out.
-- view 2: the kick sends a ring of light out across the grass from the circle
-- (stones flicker as it passes); each voice lights its own stone from within,
-- and the talking drum's bend makes its stone's glow rise and fall; hats
-- twinkle the stars, a fill raises a pillar of light from the altar, ratchets
-- chase round the stones. energy lights the milky way and warms the stones,
-- chaos jitters and doubles the rings and ghosts the stones, and kickless
-- stretches brighten the moon and let mist creep over the hill.
-- the live bands: view 1: amp feeds the firelight, lo the fire's size and the
-- glow pool, mid lights the dancers, drummers and trunks, hi shimmers the
-- flame tips, the grass and the stars. view 2: amp brightens the moon, lo
-- heaves a pool of light out from the altar, mid warms the stones, hi makes
-- the stars and the milky way sparkle.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, sqrt = math.sin, math.cos, math.floor, math.max, math.min, math.abs, math.sqrt
  local PI, TAU = math.pi, K.TAU

  ---------------------------------------------------------------- state
  local FX, FY = 64, 45               -- the fire's base
  local HZ = 31                       -- the clearing's far edge
  local MAXS = 30

  local sparks
  local flare, clapv, roll, tamb, tamb_i, shake, stamp, stamp_i
  local dh, dhand                     -- drummers: strike envelopes, alternating hand
  local bend, bend_t                  -- talking drum bend
  local logv
  local fs                            -- the fire size, eased
  local rat_q                         -- queued spark bursts: {t, v}

  -- view 2
  local NST = 9
  local lit, rise, rings, pillar, chase, twk
  local gl = {}                       -- the stones' glow, eased
  local shoot                         -- a shooting star {t0, x, y}
  local pv = 0                        -- the pillar, eased

  -- masks: rows of [x0, x1) a front dancer covers (fire and glow skip them)
  local mk, mn = {}, {}
  for y = 0, 63 do mk[y], mn[y] = {}, 0 end

  function M.init()
    sparks = {}
    flare, clapv, roll, tamb, tamb_i, shake, stamp, stamp_i = 0, 0, 0, 0, 1, 0, 0, 1
    dh, dhand = {0, 0}, {1, 1}
    bend, bend_t = 0, 99
    logv = 0
    fs = 0.4
    rat_q = {}
    lit, rise = {}, {}
    for i = 1, NST do lit[i], rise[i], gl[i] = 0, 0, 0 end
    rings, pillar, chase, twk = {}, 0, nil, 0
    pv = 0
    shoot = nil
  end
  M.clear = M.init

  local function mrect(x, y, w, h)
    x, y = floor(x), floor(y)
    for yy = y, y + h - 1 do
      if yy >= 0 and yy <= 63 and mn[yy] < 24 then
        local n = mn[yy]
        mk[yy][n + 1], mk[yy][n + 2] = x, x + w
        mn[yy] = n + 2
      end
    end
  end

  local function cut(l, a, b, y, k)
    if b - a < 1 then return end
    if k > mn[y] then put(l, a, y, b - a, 1); return end
    local m0, m1 = mk[y][k], mk[y][k + 1]
    if m1 <= a or m0 >= b then cut(l, a, b, y, k + 2)
    else
      if m0 > a then cut(l, a, m0, y, k + 2) end
      if m1 < b then cut(l, m1, b, y, k + 2) end
    end
  end
  -- a row span [x0, x1) that skips the masks
  local function span(l, x0, x1, y)
    y = floor(y)
    if y < 0 or y > 63 then return end
    x0, x1 = max(0, floor(x0 + 0.5)), min(128, floor(x1 + 0.5))
    if x1 <= x0 then return end
    cut(l, x0, x1, y, 1)
  end

  local function spark(x, y, v, spread, up)
    if #sparks >= MAXS then table.remove(sparks, 1) end
    sparks[#sparks + 1] = {x = x, y = y, vx = (K.rnd() - 0.5) * (spread or 12), vy = -(up or 14) * (0.6 + 0.6 * K.rnd()),
      t0 = K.T, life = 0.9 + K.rnd() * 1.1, lv = 5 + 6 * v, sd = K.rnd() * 6}
  end
  local function burst(n, v, spread, up)
    for k = 1, n do spark(FX + (K.rnd() - 0.5) * 8, FY - 4 - K.rnd() * 6, v, spread, up) end
  end

  ---------------------------------------------------------------- events
  function M.kick(v)
    v = K.num(v, 1)
    flare = math.max(flare, 0.6 + 0.4 * v)
    burst(3 + floor(v * 3), v, 14, 18)
    rings[#rings + 1] = {t0 = K.T, v = v}
    if #rings > 4 then table.remove(rings, 1) end
    lit[1] = max(lit[1], 0.5 + 0.5 * v)
  end
  function M.snare(v, n)
    v = K.num(v, 1)
    clapv = math.max(clapv, v)
    burst(3, v * 0.8, 30, 10)
    lit[2] = max(lit[2], 0.4 + 0.6 * v)
  end
  function M.clap(v)
    v = K.num(v, 1)
    clapv = math.max(clapv, v * 0.8)
    burst(2, v * 0.6, 26, 9)
    lit[2] = max(lit[2], 0.3 + 0.5 * v)
  end
  function M.rim(v)
    v = K.num(v, 1)
    dh[1] = max(dh[1], 0.5 * v); dhand[1] = 3 - dhand[1]
    lit[8] = max(lit[8], 0.3 + 0.5 * v)
  end
  function M.hat(v, open)
    v = K.num(v, 1)
    shake = max(shake, open and 0.8 or 0.4 * v + 0.2)
    if open or K.rnd() < 0.35 then spark(FX + (K.rnd() - 0.5) * 6, FY - 8, 0.3, 10, 12) end
    lit[3] = max(lit[3], (open and 0.6 or 0.3) * (0.5 + v))
    twk = max(twk, open and 1 or 0.5)
  end
  function M.ride(v) M.hat(v, true) end
  function M.shaker(v)
    v = K.num(v, 1)
    shake = max(shake, 0.4 + 0.5 * v)
    lit[8] = max(lit[8], 0.2 + 0.4 * v)
    twk = max(twk, 0.4)
  end
  function M.tom(v, hz)
    v, hz = K.num(v, 1), K.num(hz, 120)
    dh[1] = max(dh[1], 0.6 + 0.4 * v); dhand[1] = 3 - dhand[1]
    lit[4] = max(lit[4], 0.4 + 0.6 * v)
    if hz < 140 then flare = max(flare, 0.3 * v) end
  end
  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 13 then
      dh[2] = max(dh[2], 0.6 + 0.4 * v); dhand[2] = 3 - dhand[2]
      bend, bend_t = v, 0
      rise[5] = 0
      lit[5] = max(lit[5], 0.4 + 0.6 * v)
    elseif kind == 1 or kind == 2 then
      dh[1] = max(dh[1], 0.4 + 0.5 * v); dhand[1] = 3 - dhand[1]
      lit[6] = max(lit[6], 0.3 + 0.6 * v)
    elseif kind == 7 then
      logv = max(logv, 0.5 + 0.5 * v)
      spark(FX + (K.rnd() - 0.5) * 30, 58, v * 0.5, 8, 8)
      lit[7] = max(lit[7], 0.4 + 0.6 * v)
    elseif kind == 17 then
      M.tom(v, 90)
    elseif kind == 16 then
      -- a voice: the dancers call back, arms up
      clapv = max(clapv, 0.7 * v)
      lit[9] = max(lit[9], 0.4 + 0.5 * v)
    elseif kind == 10 then
      tamb, tamb_i = max(tamb, v), floor(K.rnd() * 8) + 1
      lit[8] = max(lit[8], 0.4 + 0.5 * v)
    else
      spark(FX + (K.rnd() - 0.5) * 10, FY - 6, v * 0.6, 16, 12)
      lit[9] = max(lit[9], 0.3 + 0.6 * v)
    end
  end
  function M.tick(kind)
    spark(FX + (K.rnd() - 0.5) * 12, FY - 2, 0.35, 20, 9)
    lit[9] = max(lit[9], 0.25)
  end
  function M.brk(s, n)
    s, n = K.num(s, 1), max(1, K.num(n, 8))
    stamp, stamp_i = 1, floor(s) % 8 + 1
    lit[(floor(s) % NST) + 1] = max(lit[(floor(s) % NST) + 1], 0.35)
  end
  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 10)
    roll = max(roll, 0.7)
    flare = max(flare, 0.5)
    for k = 0, n - 1 do
      if #rat_q < 16 then rat_q[#rat_q + 1] = {t = K.T + k * 0.06, v = 0.8 - k * 0.05} end
    end
    chase = {t0 = K.T, n = n}
    burst(2, 0.8, 30, 16)
  end
  function M.fill()
    roll = 1
    flare = 1
    pillar = 1
    burst(6, 1, 20, 22)
  end

  ---------------------------------------------------------------- view 1
  -- the tree line: rounded crowns and a few tall pines
  -- the forest round the clearing: pines and round crowns (x, height, kind)
  local TREES = {}
  for i = 0, 13 do
    local x = floor(-1 + i * 9.9 + K.hash(i, 3) * 5)
    local far = math.abs(x - 64) < 26
    TREES[#TREES + 1] = {x = x, h = floor(17 + K.hash(i, 4) * 9 - (far and 5 or 0)), pine = K.hash(i, 5) > 0.3,
      w = 5 + floor(K.hash(i, 6) * 3)}
  end
  -- (stars hide behind the crowns: a rough profile of them)
  local TREE = K.profile(function(x)
    local top = HZ
    for _, t in ipairs(TREES) do
      local d = math.abs(x - t.x)
      if d < t.w + 1 then top = math.min(top, HZ - t.h + d * (t.pine and 1.6 or 0.5)) end
    end
    return top
  end)

  -- a dancer: feet at (x, y), scale s, arm lift a (0..1), front = cutout
  local function dancer(x, y, s, a, step, l, front, hand)
    local hgt = 15 * s
    local hx = floor(x + 0.5)
    local legy = y - 6 * s
    local sh = y - 11 * s
    local hy = y - hgt
    local sp = 1 + floor(abs(step) * 2 * s + 0.5)
    local ay = sh - 1 - a * 4 * s
    if front then
      -- a dark halo round the figure, so it stands out against the fire
      mrect(hx - sp - 1, legy, sp * 2 + 3, y - legy + 2)
      mrect(hx - 2, hy - 1, 5, legy - hy + 1)
      mrect(hx - 4, ay - 1, 3, sh - ay + 2)
      mrect(hx + 2, ay - 1, 3, sh - ay + 2)
    end
    line(l, hx - sp, y, hx, legy)
    line(l, hx + sp, y, hx, legy)
    put(l, hx - 1, sh, 2, legy - sh + 1)
    put(l, hx - 1, hy, 2, 2)
    line(l, hx - 1, sh, hx - 3, ay)
    line(l, hx + 1, sh, hx + 3, ay)
    return hx + 3, ay
  end

  -- a seated drummer in the foreground, rim-lit from the fire
  local function drummer(side, l, strike, hand, kind)
    local dir = side == 1 and 1 or -1           -- toward the fire
    local bx = side == 1 and 10 or 117
    local hy = 40
    -- head and body, outlined on the fire side
    K.ring(l, bx, hy, 3, 8)
    put(l * 0.5, bx - 1, hy - 1, 3, 3)
    line(l, bx + dir * 3, hy + 4, bx + dir * 6, 63)
    line(l * 0.6, bx - dir * 4, hy + 4, bx - dir * 7, 63)
    line(l, bx + dir * 3, hy + 4, bx - dir * 4, hy + 4)
    -- the drum, between the knees
    local dx = bx + dir * 13
    local top = side == 1 and 50 or 49
    local hl = l + strike * 7
    if kind == 1 then
      -- a conga: a tall barrel, its head lighting on each strike
      K.ring(hl, dx, top, 5, 10, 0, TAU, 0.35)
      put(strike * 6 + l * 0.3, dx - 3, top, 7, 1)
      line(l, dx - 5, top, dx - 4, 63)
      line(l, dx + 5, top, dx + 4, 63)
      line(l * 0.6, dx - 5, top + 6, dx + 5, top + 6)
    else
      -- a talking drum under the arm: an hourglass whose waist squeezes
      local w = 4 - bend * 2 * math.exp(-bend_t / 0.35)
      line(hl, dx - 4, top - 2, dx + 4, top - 2)
      line(l, dx - 4, top - 2, dx - w * 0.5, top + 5)
      line(l, dx + 4, top - 2, dx + w * 0.5, top + 5)
      line(l, dx - w * 0.5, top + 5, dx - 4, top + 12)
      line(l, dx + w * 0.5, top + 5, dx + 4, top + 12)
      line(l * 0.8, dx - 4, top + 12, dx + 4, top + 12)
      for k = -1, 1 do line(l * 0.5, dx + k * 2, top - 1, dx + k * w * 0.3, top + 11) end
    end
    -- the arms: the striking one comes down on the head, the other rises
    local sx, sy = bx + dir * 2, hy + 6
    for a = 1, 2 do
      local down = (a == hand) and strike or strike * 0.25
      local tx = dx - dir * 2 + (a == 1 and -1 or 1) * 2
      local ty = top - 1 - (1 - down) * 9
      line(l + (a == hand and strike * 4 or 0), sx, sy, tx, ty)
      if a == hand and strike > 0.5 then put(strike * 7, tx - 1, top - 1, 3, 1) end
    end
  end

  local function draw1(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    for y = 0, 63 do mn[y] = 0 end

    -- the fire's size: energy and flare grow it, kickless lets it die
    local tgt = (0.3 + 0.45 * e + lo * 0.35 + flare * 0.7 + roll * 0.4) * (1 - 0.82 * kl)
    fs = K.follow(fs, tgt, tgt > fs and 0.05 or 0.3, DT)
    local fl = 0.75 + 0.25 * sin(T * 11.3) * sin(T * 7.1 + 1)       -- flicker
    local light = clamp(fs * fl * 1.3 + A[K.AMP] * 0.25, 0.05, 1.4)

    -- the sky: stars, more and brighter as the fire dies
    local nst = 22 + floor(kl * 20 + (1 - min(1, fs)) * 6)
    for i = 0, nst - 1 do
      local x, y = floor(K.hash(i, 11) * 128), floor(K.hash(i, 12) * 22)
      if y < K.at(TREE, x) - 1 then
        local tw = 0.5 + 0.5 * sin(T * (0.6 + K.hash(i, 13) * 1.5) + i * 2.1)
        put(0.8 + tw * (1 + kl * 2.5 + hi * 2 + twk * 2) * (y < 10 and 1 or 0.7), x, y, 1, 1)
      end
    end
    -- smoke: soft puffs rising and leaning out of the firelight
    local ftop = FY - 4 - fs * 18
    for k = 0, 3 do
      local p = (T * 0.11 + k / 4) % 1
      local y = ftop - 2 - p * 34
      local r = 2 + p * 8 + kl * 2
      local x = FX + p * 14 + sin(T * 0.7 + k * 2) * 2 + c * sin(T * 3 + k) * 6
      K.ring((1 + light * 0.8 + kl * 0.6) * (1 - p * 0.6) * min(1, p * 6), x, y, r, 10, 0, TAU, 0.6, 1.2, k + floor(T * 0.11 + k / 4) * 4)
    end

    -- the forest's edge: pines and crowns caught by the firelight from below
    for i, t in ipairs(TREES) do
      local near = 1 - min(1, abs(t.x - FX) / 70)
      local fl2 = 0.8 + 0.2 * sin(T * 7 + i * 1.9) * sin(T * 4.3 + i)
      local l = 0.9 + light * near * 2.4 * fl2 + mid * near
      local top = HZ - t.h
      if t.pine then
        -- three tiers, each a chevron; the underside of each catches the light
        for tier = 0, 2 do
          local ty = top + tier * floor(t.h * 0.24)
          local tw = t.w * (0.55 + tier * 0.25)
          local by = ty + floor(t.h * 0.34)
          line(l * 0.8, t.x, ty, t.x - tw, by)
          line(l, t.x, ty, t.x + tw, by)
          if tier == 2 then line(l * 1.2, t.x - tw, by, t.x + tw, by) end
        end
        line(l * 0.9, t.x, top + floor(t.h * 0.82), t.x, HZ)
      else
        local cy = top + floor(t.w * 0.9)
        K.ring(l * 0.8, t.x, cy, t.w, 6, PI, TAU, 0.9, 1, i)
        K.ring(l * 1.2, t.x, cy, t.w, 4, 0, PI, 0.6, 0.6, i + 3)
        line(l * 0.9, t.x, cy + floor(t.w * 0.6), t.x, HZ)
        line(l * 0.6, t.x, cy + floor(t.w * 0.6) + 1, t.x + 2, cy + 2)
      end
    end
    for x = 0, 127, 16 do
      local near = 1 - min(1, abs(x + 8 - FX) / 70)
      line(0.8 + light * near * 1.5, x, HZ, x + 12, HZ)
    end

    -- the dancers: in front (cutouts, masking fire and glow) and behind
    local n = 5 + floor(e * 3 + 0.5)
    local om = (0.22 + 0.25 * e) * (1 - 0.65 * kl)
    local hop = K.env.kick * 2.2 + stamp * 0
    local front = {}
    local back = {}
    for i = 1, n do
      local th = (i - 1) * TAU / n + T * om + c * 0.7 * sin(T * 1.9 + i * 2.3)
      local r = 1 + c * ((K.hash(i, 31) - 0.5) * 0.7 + 0.25 * sin(T * 1.3 + i))
      local x = FX + cos(th) * 44 * r
      local yb = FY + 2 + sin(th) * 8 * r
      local s = 0.78 + 0.22 * sin(th)
      local step = sin(T * 5 + i * 1.7) * (1 - 0.5 * kl)
      local a = clamp(0.35 + 0.35 * sin(K.beat_ph * TAU + i) + clapv * 0.8, 0, 1)
      local h = hop * s + ((i == stamp_i) and stamp * 3 or 0)
      local d = {x = x, y = yb - h, s = s, a = a, step = step, i = i}
      if sin(th) > 0.1 then front[#front + 1] = d else back[#back + 1] = d end
    end
    local handx, handy = {}, {}
    for _, d in ipairs(front) do
      handx[d.i], handy[d.i] = dancer(d.x, d.y, d.s, d.a, d.step, 2 + light * 2 + mid * 1.5, true)
    end

    -- the ground: grass strokes lit by the fire, falling away from it
    for y = HZ + 2, 63 do
      local dy = (y - FY) / 8
      local u = (y - HZ) / (63 - HZ)
      local off = y * 7 + floor(sin(T * 0.8 + y) * 1.5)
      local Rp = 0
      for ring = 0, 2 do
        local R = (12 + ring * 22 + light * (7 + ring * 9)) * sqrt(max(0, 1 - (dy / (1.5 + ring * 0.6)) ^ 2))
        if R > Rp + 1 and (ring == 0 or (ring == 1 and y % 2 == 1) or y % 4 == 1) then
          local l = (ring == 0 and 1.5 + light * 2.4 or ring == 1 and 1 + light * 0.6 or 1) * (0.85 + 0.15 * fl) + hi * (0.9 - ring * 0.3)
          if ring == 0 then
            span(l, FX - R, FX + R, y)
          else
            if ring == 1 then
              span(l, FX - R, FX - Rp, y)
              span(l, FX + Rp, FX + R, y)
            else
              local dw = 4 + floor(u * 4)
              K.dashes(l, y, dw, dw + 7, off, max(0, floor(FX - R)), max(0, floor(FX - Rp)))
              K.dashes(l, y, dw, dw + 7, off + 4, min(128, floor(FX + Rp)), min(128, floor(FX + R)))
            end
          end
        end
        Rp = max(Rp, R)
      end
    end
    -- the fire's own pool, close round the logs
    for y = FY - 1, FY + 4 do
      local w = (5 + light * 7) * sqrt(max(0, 1 - ((y - FY - 1.5) / 3.5) ^ 2))
      if w > 1 then span(1.5 + light * 2.5, FX - w, FX + w, y) end
    end

    -- the behind dancers: lit from the fire, dimmer to the sides
    for _, d in ipairs(back) do
      local near = 1 - min(1, abs(d.x - FX) / 60)
      local l = 1 + light * (1 + 3 * near) + mid * 1.5
      handx[d.i], handy[d.i] = dancer(d.x, d.y, d.s * 0.92, d.a, d.step, l, false)
      if c > 0.35 then
        dancer(d.x + sin(T * 3 + d.i) * c * 9, d.y, d.s * 0.92, 1 - d.a, -d.step, l * 0.5 * c, false)
      end
    end

    -- the logs and the embers
    line(2 + light, FX - 9, FY + 2, FX + 7, FY - 1)
    line(2 + light, FX + 9, FY + 2, FX - 7, FY - 1)
    for k = 0, 6 do
      local ex = FX - 7 + k * 2 + floor(sin(k * 2.7) * 1.5)
      local g = 0.5 + 0.5 * sin(T * (2 + k * 0.4) + k * 1.3)
      put(2 + g * (3 + kl * 3) + fs * 2, ex, FY - (k % 2), 1, 1)
    end

    -- the fire: nested tongues, wobbling, bright at the root
    local H = 3 + fs * 19
    local W0 = 3 + fs * 3.5 + e
    for t = 0, 2 do
      local tx = FX + (t - 1) * (2 + fs * 2)
      local th = H * (t == 1 and 1 or 0.65 + 0.2 * sin(T * 5.7 + t * 2))
      local tw = W0 * (t == 1 and 1 or 0.55)
      for r = 0, floor(th) do
        local u = r / max(1, th)
        local y = FY - r
        local w = tw * (1 - u) ^ 1.15
        local ox = sin(T * 9 + r * 0.6 + t * 2) * u * 2.2 + sin(T * 5.3 + r * 1.2) * u * 1.4
          + c * u * 3 * sin(T * 13 + r) + hi * u * 1.5 * sin(T * 23 + r * 2.1)
        if w >= 0.5 then
          local lv = (4 + 6 * (1 - u)) * (0.8 + 0.25 * fl) * min(1, 0.55 + fs)
          span(lv, tx + ox - w, tx + ox + w, y)
          if w > 1.5 and u < 0.55 and (t == 1 or r % 2 == 0) then
            span(min(13, lv + 3 + flare * 1.5), tx + ox - w * 0.45, tx + ox + w * 0.45, y)
          end
        end
      end
    end

    -- sparks: rising, drifting, swirling with chaos
    for i = #sparks, 1, -1 do
      local p = sparks[i]
      local u = (K.T - p.t0) / p.life
      if u >= 1 or u < 0 then table.remove(sparks, i)
      else
        local dts = K.DTS
        p.vy = p.vy - 4 * dts
        p.vx = p.vx * math.exp(-dts * 0.8) + sin(K.T * 3 + p.sd) * 6 * dts
        if c > 0.1 then
          local rx, ry = p.x - FX, p.y - (FY - 14)
          p.vx = p.vx - ry * c * 2.2 * dts
          p.vy = p.vy + rx * c * 1.2 * dts
        end
        local ox, oy = p.x, p.y
        p.x, p.y = p.x + p.vx * dts, p.y + p.vy * dts
        local lv = p.lv * (1 - u)
        put(lv, p.x, p.y, 1, 1)
        if abs(p.vy) + abs(p.vx) > 12 then line(lv * 0.4, ox, oy + 1, p.x, p.y + 1) end
      end
    end

    -- the front dancers' hands: tambourine jingles and shaker glints
    local ti = tamb_i
    if tamb > 0.05 and handx[ti] then
      put(3 + tamb * 8, handx[ti] - 1, handy[ti] - 1, 1, 1)
      put(2 + tamb * 6, handx[ti] + 1, handy[ti], 1, 1)
      K.ring(1 + tamb * 4, handx[ti], handy[ti], 2.5, 6)
    end
    if shake > 0.05 then
      for i = 1, n, 2 do
        if handx[i] then put(1 + shake * 5 + hi * 2, handx[i], handy[i] - 1, 1, 1) end
      end
    end

    -- the drummers, rim-lit, and the slit drum at our feet
    local dl = 1.2 + light * 1.4 + mid * 1.5
    local rl = roll > 0.05 and (0.5 + 0.5 * sin(K.T * 40)) * roll or 0
    drummer(1, dl, max(dh[1], rl), dhand[1], 1)
    drummer(2, dl, max(dh[2], roll > 0.05 and (0.5 - 0.5 * sin(K.T * 40)) * roll or 0), dhand[2], 2)
    local lx0, lx1, ly = 44, 84, 59
    line(1.5 + light * 1.5, lx0, ly, lx1, ly)
    line(1 + light, lx0 + 2, 63, lx1 - 2, 63)
    line(1 + light, lx0, ly, lx0 + 2, 63)
    line(1 + light, lx1, ly, lx1 - 2, 63)
    put(1 + logv * 10 + mid * 1.5, lx0 + 8, ly + 2, 10, 1)
    put(1 + logv * 7 + mid, lx1 - 18, ly + 2, 10, 1)
    if logv > 0.1 then put(logv * 5, lx0 + 6, ly - 1, lx1 - lx0 - 12, 1) end
  end

  ---------------------------------------------------------------- view 2
  local SCX, SCY, SRX, SRY = 62, 47, 50, 10
  local ST = {}
  for i = 1, NST do
    local th = -PI / 2 + (i - 1) * TAU / NST
    local s = 0.55 + 0.45 * (sin(th) + 1) / 2
    local h = floor((17 + K.hash(i, 41) * 7) * s * (i == 1 and 1.3 or 1))
    local w = max(3, floor((6 + K.hash(i, 42) * 3) * s + 0.5))
    ST[i] = {x = floor(SCX + cos(th) * SRX), y = floor(SCY + sin(th) * SRY), h = h, w = w, d = sin(th),
      lean = floor((K.hash(i, 43) - 0.5) * 3)}
  end
  local ORDER = {}
  for i = 1, NST do ORDER[i] = i end
  table.sort(ORDER, function(a, b) return ST[a].d < ST[b].d end)
  -- each stone's bottom clip: the top of any nearer stone overlapping it
  for _, i in ipairs(ORDER) do
    local s = ST[i]
    s.clip = s.y
    for j = 1, NST do
      local o = ST[j]
      if o.d > s.d and o.x - o.w / 2 < s.x + s.w / 2 + 1 and o.x + o.w / 2 + 1 > s.x - s.w / 2 then
        s.clip = min(s.clip, o.y - o.h - 1)
      end
    end
  end
  local FAR = K.profile(function(x)
    return 29 + 3 * sin(x * 0.04 + 1) + 2 * sin(x * 0.11) + K.hash(x // 6, 51) * 1.5
  end)
  local HILL = K.profile(function(x)
    local u = (x - 64) / 64
    return 36 + u * u * 7 + sin(x * 0.07) * 0.8
  end)
  local MX, MY = 101, 11
  -- the crest line hides behind the stones that stand across it
  local CREST = {}
  for cidx = 0, 63 do
    local x = cidx * 2 + 1
    local hidden = false
    for i = 1, NST do
      local st = ST[i]
      local cy = HILL[cidx]
      if x >= st.x - st.w // 2 - 1 and x <= st.x - st.w // 2 + st.w and st.y - st.h < cy and st.y > cy - 1 then hidden = true end
    end
    CREST[cidx] = not hidden
  end

  local function stone(i, s, g, ghost, c, e, kl, mlit)
    local x0 = s.x - s.w // 2
    local top = s.y - s.h
    local bot = min(s.y, s.clip)
    if bot <= top then return end
    local base = 1 + e * 0.6 + mlit + A[K.MID] * 0.8
    local ghx = ghost and floor(sin(K.T * 7 + i * 2) * 3 * c + 0.5) or 0
    -- the body: a dark slab, tapering and leaning at the head
    local th = max(1, floor(s.h * 0.3))
    if not ghost then
      for y = top, min(bot - 1, top + th - 1) do
        local t = (y - top) / th
        local inset = (y == top) and 1 or 0
        local sl = floor(s.lean * (1 - t) + 0.5)
        put(base * 0.7, x0 + inset + sl, y, s.w - inset * 2 - 1, 1)
      end
      if bot > top + th then put(base * 0.7, x0, top + th, s.w, bot - top - th) end
    end
    -- the moonlit edge and crown
    local ex = x0 + s.w - 1 + ghx
    line(base + 1.5 + mlit, ex - (s.lean > 0 and 0 or 1), top + 1, ex, bot - 1)
    line(base + 1 + mlit, x0 + 1 + s.lean + ghx, top, x0 + s.w - 2 + s.lean + ghx, top)
    -- the glow from within: fills up from the foot (the talking drum's
    -- stone rises and falls with its bend)
    if g > 0.04 then
      local fh = s.h * (rise[i] > 0 and rise[i] or 1)
      local gy0 = max(top + 1, floor(s.y - fh))
      -- in three bands, brightest at the foot
      local gh = bot - gy0
      for b = 0, 2 do
        local y0 = gy0 + floor(gh * b / 3)
        local y1 = gy0 + floor(gh * (b + 1) / 3)
        if y1 > y0 then put(min(13, base + g * (5 + b * 2)), x0 + 1 + ghx, y0, max(1, s.w - 2), y1 - y0) end
      end
      -- the carved rune, brightest
      local rx = x0 + s.w // 2 + ghx
      local ry = top + floor(s.h * 0.35)
      if ry < bot - 2 and ry >= gy0 then
        line(min(14, 3 + g * 11), rx, ry, rx, min(bot - 1, ry + floor(s.h * 0.4)))
        put(min(13, 2 + g * 10), rx - 1, ry + 1, 3, 1)
      end
      -- light spilling on the grass at its foot
      if s.clip >= s.y then put(1 + g * 4, x0 - 2, s.y + 1, s.w + 4, 1) end
    end
  end

  local function draw2(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]

    -- the moon, low and big, brighter in the quiet
    local amp = A[K.AMP]
    local mb = 3 + kl * 3 + e * 0.5 + amp * 2
    K.disc(mb, MX, MY, 6.5)
    K.disc(mb + 1.5, MX + 1, MY - 1, 4)
    put(mb - 1, MX - 3, MY + 1, 2, 2)
    put(mb - 1, MX + 2, MY + 3, 1, 1)
    K.ring(1 + kl * 1.5 + lo * 0.6, MX, MY, 9 + sin(T * 0.4) * 0.8 + lo * 1.5, 18)
    -- a wisp of cloud drifting past
    local cx = ((T * 2.2) % 190) - 30
    for k = 0, 2 do
      local w = 18 - k * 5
      put(1, cx + k * 4, MY + 3 + k * 2, w, 1)
    end

    -- the milky way: a dense diagonal band of stars over a faint haze
    for k = 0, 3 do
      local bx = k * 30
      local by = floor(20 - k * 6)
      K.haze(bx, by, bx + 34, by + 8, 0.22 + e * 0.25 + kl * 0.15 + twk * 0.1 + hi * 0.35, 1 + hi * 1.2, T * (1.5 + hi * 4) + k * 40)
    end
    for i = 0, 36 do
      local x, y = floor(K.hash(i, 64) * 128), floor(K.hash(i, 65) * 28)
      if y < K.at(FAR, x) - 1 and (x - MX) ^ 2 + (y - MY) ^ 2 > 120 then
        local tw = 0.5 + 0.5 * sin(T * (0.4 + K.hash(i, 66) * 1.6) + i * 2.7)
        local big = K.hash(i, 67) > 0.85
        put(1 + tw * (1.5 + hi * 5 + twk * 3 + kl) + (big and 1.5 or 0), x, y, 1, 1)
        if big and tw > 0.6 - hi * 0.4 then put(tw * 1.5 + hi * 3, x - 1, y, 3, 1); put(tw + hi * 2, x, y - 1, 1, 3) end
      end
    end
    -- a shooting star now and then (and on fills)
    if not shoot and (K.hash(floor(T * 0.5), 71) > 0.93) then
      shoot = {t0 = T, x = 20 + K.rnd() * 60, y = 3 + K.rnd() * 8}
    end
    if shoot then
      local u = (T - shoot.t0) / 0.6
      if u >= 1 or u < 0 then shoot = nil
      else
        local x, y = shoot.x + u * 40, shoot.y + u * 12
        line(6 * (1 - u), x - 6, y - 2, x, y)
        put(9 * (1 - u), x, y, 1, 1)
      end
    end

    -- the far hills, the hill we stand on, and the grass
    for cidx = 0, 62, 2 do line(1.5 + kl * 0.8, cidx * 2, FAR[cidx], cidx * 2 + 4, FAR[cidx + 2]) end
    for cidx = 0, 62, 2 do
      if CREST[cidx] and CREST[cidx + 1] then line(2 + kl * 0.8 + e * 0.6, cidx * 2, HILL[cidx], cidx * 2 + 4, HILL[cidx + 2])
      elseif CREST[cidx] then line(2 + kl * 0.8 + e * 0.6, cidx * 2, HILL[cidx], cidx * 2 + 1, HILL[cidx])
      elseif CREST[cidx + 1] then line(2 + kl * 0.8 + e * 0.6, cidx * 2 + 2, HILL[cidx + 1], cidx * 2 + 4, HILL[cidx + 2]) end
    end
    for y = 38, 63, 3 do
      local u = (y - 38) / 25
      K.dashes(1, y, 1 + floor(u * 3), 12 - floor(u * 3), y * 5 + sin(T * 0.7 + y) * 1.5, 0, 128)
    end
    -- mist creeping over the hill when it's quiet
    K.haze(0, 40, 128, 62, 0.08 + 0.3 * kl + 0.08 * e, 1, T * 4)

    -- the kick's rings of light, running out across the grass
    for i = #rings, 1, -1 do
      local R = rings[i]
      local age = T - R.t0
      local life = 1.6 + e * 0.6
      if age > life then table.remove(rings, i)
      elseif age >= 0 then
        local u = age / life
        local r = 6 + age * 44
        local lv = (1.5 + 5 * R.v) * (1 - u) ^ 1.4 * min(1, age / 0.08)
        local jit = c * 3 * (1 - u)
        K.ring(lv, SCX, SCY + 2, r, 20, 0, TAU, 0.24, jit, i)
        if c > 0.4 then K.ring(lv * 0.5, SCX + sin(R.t0 * 7) * c * 6, SCY + 2, r * 0.8, 14, 0, TAU, 0.24, jit * 2, i + 7) end
        -- the stones flicker as it passes
        for j = 1, NST do
          local s = ST[j]
          local dd = sqrt((s.x - SCX) ^ 2 + ((s.y - SCY - 2) / 0.24) ^ 2)
          if abs(dd - r) < 4 then lit[j] = max(lit[j], 0.25 * R.v * (1 - u)) end
        end
      end
    end

    -- the low end heaves a pool of light out from the altar across the grass
    local pr = 8 + lo * 26
    for y = SCY - 3, SCY + 6 do
      local dy = (y - SCY - 1.5) / 4.5
      local w = pr * math.sqrt(max(0, 1 - dy * dy))
      if w > 1 then put(lo * 2.6 * (1 - abs(dy) * 0.5), SCX - w, y, 2 * w, 1) end
    end
    -- the altar at the centre, and the pillar of light on a fill
    local al = 1.5 + e * 1.5 + lit[1] * 2 + pv * 4
    put(al, SCX - 6, SCY - 1, 13, 2)
    line(al + 1, SCX - 6, SCY - 2, SCX + 6, SCY - 2)
    if pv > 0.05 then
      for k = -1, 1 do
        line(pv * (k == 0 and 9 or 4), SCX + k, SCY - 3, SCX + k, 0)
      end
    end

    -- the stones, back to front, each glowing with its voice
    local ch = chase and floor((T - chase.t0) / 0.05) or -1
    for _, i in ipairs(ORDER) do
      local s = ST[i]
      local g = gl[i]
      if chase and ch >= 0 and ch < chase.n * 2 and (ch % NST) + 1 == i then g = max(g, 0.7) end
      local ml = (s.x > 64 and 0.6 or 0.2) + kl * 0.6
      if c > 0.3 then stone(i, s, g * 0.4, true, c, e, kl, ml * 0.4) end
      stone(i, s, g, false, c, e, kl, ml)
    end
    if chase and ch >= chase.n * 2 then chase = nil end
  end

  ---------------------------------------------------------------- draw
  function M.draw(S)
    local DT = K.DT
    flare = flare * math.exp(-DT / 0.25)
    clapv = clapv * math.exp(-DT / 0.18)
    roll = roll * math.exp(-DT / 0.6)
    tamb = tamb * math.exp(-DT / 0.25)
    shake = shake * math.exp(-DT / 0.12)
    stamp = stamp * math.exp(-DT / 0.15)
    logv = logv * math.exp(-DT / 0.3)
    pillar = pillar * math.exp(-DT / 0.7)
    pv = K.follow(pv, pillar, 0.08, DT)
    twk = twk * math.exp(-DT / 0.2)
    bend_t = bend_t + DT
    for d = 1, 2 do dh[d] = dh[d] * math.exp(-DT / 0.13) end
    -- the stones' glow: a long ritual reverb
    for i = 1, NST do
      lit[i] = lit[i] * math.exp(-DT / (i == 5 and 0.6 or 0.45))
      gl[i] = K.follow(gl[i], lit[i], lit[i] > gl[i] and 0.06 or 0.03, DT)
    end
    -- the talking drum's stone: the glow rises with the bend and falls
    local u = bend_t / 0.7
    rise[5] = u < 1 and (0.25 + 0.75 * sin(math.pi * u)) or 0
    for i = #rat_q, 1, -1 do
      if K.T >= rat_q[i].t then
        burst(2, rat_q[i].v, 24, 16)
        local j = (floor(K.T * 20) % NST) + 1
        lit[j] = max(lit[j], rat_q[i].v * 0.6)
        table.remove(rat_q, i)
      end
    end
    if K.view == 2 then draw2(S) else draw1(S) end
  end

  M.init()
  return M
end
