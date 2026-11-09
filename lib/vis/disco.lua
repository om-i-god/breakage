-- disco. view 1: a light-up dance floor of square tiles in perspective, a mirror ball throwing moving spots, dancers silhouetted against the wall.
-- view 2: a 70s light show: colour-wheel spotlights as grey beams, a glitter curtain shimmering with the hats, a string section swelling below.
--
-- view 1: each voice lights the tiles its own way: the kick a diamond that
-- spreads out from the middle, the snare a row sweeping toward us, claps a
-- diagonal, hats a single tile here and there (open hats two), tambourine
-- a column twinkling, congas and bongos the side tiles, a ratchet a chase
-- along a row, a fill a wave over the whole floor. the mirror ball turns
-- and throws spots over the wall and the floor; the dancers bob on the beat
-- and throw their arms up on the claps. out_amp lights the wall, out_lo
-- glows the middle tiles, out_mid rims the dancers and warms the wall,
-- out_hi sparkles the ball and its spots. energy brings more dancers and
-- quickens the ball, chaos scatters tiles and doubles the spots, kickless
-- stretches leave a slow chase going round the floor's edge.
-- view 2: the kick pulses the beams, the snare clicks the colour wheels on
-- (each gel a grey), claps swing the beams, congas cross them; hats and the
-- tambourine run glitter down the curtain; out_mid swells the strings (the
-- bows saw wider and the stage wash behind them lifts); out_lo lights the
-- stage floor, out_amp the beams, out_hi the glitter. chaos sends the beams
-- wild, kickless stretches let the strings carry it alone.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs = math.sin, math.cos, math.floor, math.max, math.min, math.abs
  local PI = math.pi

  ---------------------------------------------------------------- the floor
  local VPX, VPY = 64, 8
  local NC, NR = 8, 5
  local YS = {35, 39, 44, 50, 57, 64}          -- row edges, back to front
  local function xat(k, y)                     -- column edge k (0..NC) at y
    local xb = -40 + k * 26
    return VPX + (xb - VPX) * (y - VPY) / (64 - VPY)
  end
  local WY0, WY1 = 12, 34                      -- the wall band

  local tile, waves
  local spots, rot
  local dancers, arms
  -- view 2
  local beams, wheel, glit, pulse, swing2
  local ps

  function M.init()
    tile = {}
    for i = 1, NC * NR do tile[i] = 0 end
    waves = {}
    rot = 0
    arms = 0
    beams = {
      {x = 18, a = 0.35, va = 0, g = 0},
      {x = 64, a = -0.1, va = 0, g = 2},
      {x = 110, a = -0.4, va = 0, g = 4},
    }
    wheel, glit, pulse, swing2 = 0, {}, 0, 0
    ps = 0
  end
  M.clear = M.init

  local function lightt(c, r, v)
    if c >= 0 and c < NC and r >= 0 and r < NR then
      local i = r * NC + c + 1
      if v > tile[i] then tile[i] = v end
    end
  end

  local function wave(kind, v, c0, r0)
    if #waves >= 8 then table.remove(waves, 1) end
    waves[#waves + 1] = {kind = kind, t0 = K.T, v = v, c0 = c0 or 0, r0 = r0 or 0}
  end

  local function sparkle(n, v)
    for k = 1, n do
      if #glit >= 24 then table.remove(glit, 1) end
      glit[#glit + 1] = {x = 2 + floor(K.rnd() * 25) * 5, y0 = K.rnd() * 20, t0 = K.T, v = v}
    end
  end

  function M.kick(v)
    v = K.num(v, 1)
    wave("diamond", v, 3.5, 2)
    pulse = 1
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    wave("row", v)
    wheel = wheel + 1
    swing2 = swing2 + 0.5
  end

  function M.clap(v)
    v = K.num(v, 1)
    wave("diag", v * 0.9)
    arms = 1
    for _, b in ipairs(beams) do b.va = b.va + (K.rnd() - 0.5) * 3 end
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    local n = open and 2 or 1
    for k = 1, n do lightt(floor(K.rnd() * NC), floor(K.rnd() * NR), 0.25 + 0.2 * v) end
    sparkle(open and 4 or 2, 0.6 + 0.4 * v)
  end
  function M.ride(v) M.hat(K.num(v, 1) * 0.7, true) end
  function M.rim(v) lightt(floor(K.rnd() * NC), NR - 1, 0.6 * K.num(v, 1)) end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 10 or kind == 9 then
      wave("col", v * 0.8, floor(K.rnd() * NC))
      sparkle(5, v)
    elseif kind == 1 or kind == 2 or kind == 13 then
      local side = K.rnd() < 0.5 and 0 or NC - 1
      for r = 0, NR - 1 do lightt(side, r, (0.5 + 0.4 * v) * (1 - r * 0.1)) end
      beams[1].va = beams[1].va + 1.5 * v
      beams[3].va = beams[3].va - 1.5 * v
    else
      lightt(floor(K.rnd() * NC), floor(K.rnd() * NR), 0.6 * v)
      sparkle(2, v * 0.7)
    end
  end
  function M.tom(v) M.perc(1, K.num(v, 1)) end
  function M.shaker(v) sparkle(2, 0.5 * K.num(v, 1)) end
  function M.tick() sparkle(1, 0.5) end

  function M.brk(s, n)
    s, n = K.num(s, 1), max(1, K.num(n, 8))
    local i = floor((s - 1) / n * NC * NR)
    lightt(i % NC, (i // NC) % NR, 0.7)
  end

  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    wave("chase", 1, 0, floor(K.rnd() * NR))
    waves[#waves].n = n
    sparkle(n, 1)
    swing2 = swing2 + 1
  end

  function M.fill()
    wave("fill", 1)
    arms = 1
    wheel = wheel + 2
  end

  -- the waves light the tiles they pass
  local function run_waves(T)
    for j = #waves, 1, -1 do
      local W = waves[j]
      local age = T - W.t0
      local done = true
      if W.kind == "diamond" then
        local d = age * 9
        for r = 0, NR - 1 do for c = 0, NC - 1 do
          local m = abs(c - W.c0) + abs(r - W.r0) * 1.3
          local u = abs(m - d)
          if u < 0.6 then lightt(c, r, W.v * (1 - u / 0.6) * max(0, 1 - d / 5)) end
        end end
        done = d > 5
      elseif W.kind == "row" then
        local r = floor(age * 14)
        if r < NR then for c = 0, NC - 1 do lightt(c, r, W.v * 0.8) end end
        done = r >= NR
      elseif W.kind == "diag" then
        local d = floor(age * 18)
        for r = 0, NR - 1 do lightt(d - r, r, W.v * 0.75) end
        done = d - NR >= NC
      elseif W.kind == "col" then
        local r = NR - 1 - floor(age * 16)
        if r >= 0 then lightt(W.c0, r, W.v * 0.7) end
        done = r < 0
      elseif W.kind == "chase" then
        local c = floor(age * 30)
        for k = 0, (W.n or 3) - 1 do lightt(c - k, W.r0, 1 - k * 0.1) end
        done = c - (W.n or 3) >= NC
      elseif W.kind == "fill" then
        local d = age * 6
        for r = 0, NR - 1 do for c = 0, NC - 1 do
          if abs(r + c * 0.5 - d) < 0.7 then lightt(c, r, 0.9) end
        end end
        done = d > NR + NC * 0.5 + 1
      end
      if done then table.remove(waves, j) end
    end
  end

  ---------------------------------------------------------------- view 1
  local ND = 7
  local function dancer_at(i, T, e, nd)
    local x = 6 + (i - 0.5) / nd * 116 + sin(T * 0.4 + i * 1.9) * 5
    local bob = abs(sin(K.TAU * K.beat_ph * 0.5 + i * 0.7)) * (1 + A[K.LO] * 1.5)
    local h = 15 + K.hash(i, 3) * 5
    return x, WY1 - h + bob, h
  end

  local function draw1(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    for i = 1, NC * NR do tile[i] = tile[i] * math.exp(-DT / 0.13) end
    run_waves(T)
    -- kickless: a slow chase round the floor's edge
    if kl > 0.2 then
      local per = 2 * (NC + NR) - 4
      local p = floor(T * 6) % per
      local cc, rr
      if p < NC then cc, rr = p, 0
      elseif p < NC + NR - 1 then cc, rr = NC - 1, p - NC + 1
      elseif p < 2 * NC + NR - 2 then cc, rr = NC - 1 - (p - NC - NR + 2), NR - 1
      else cc, rr = 0, NR - 1 - (p - 2 * NC - NR + 3) end
      lightt(cc, rr, 0.5 * kl)
    end
    -- chaos: stray tiles
    if c > 0.3 and K.rnd() < c * 1.0 * K.SP then lightt(floor(K.rnd() * NC), floor(K.rnd() * NR), c * 0.6) end

    -- the wall: slats, glowing toward the floor
    local wl = 1 + amp * 1.8 + mid * 1.2 + e * 0.6 + K.env.kick * 1.5
    for x = 1, 127, 4 do
      if x % 8 == 1 then line(1, x, WY0, x, 23) end
      line(wl, x, 24, x, WY1 - 1)
    end
    -- the dancers on the back of the floor, lit from below: heads, bodies,
    -- legs; the clap (and a fill) throws an arm up
    local nd = floor(3 + e * 4 + 0.5)
    local up = max(arms, K.env.clap)
    for i = 1, nd do
      local x, top, h = dancer_at(i, T, e, nd)
      local dl = 2 + mid * 3 + K.env.snare * 1.5
      local hop = (c > 0.4) and sin(T * 9 + i) * c * 3 or 0
      x = x + hop
      local sw = sin(K.TAU * K.beat_ph + i)
      K.disc(dl + 0.5, x, top + 2, 1.8)
      put(dl, x - 2, top + 4, 5, floor(h * 0.4))
      local hip = top + 4 + floor(h * 0.4)
      line(dl * 0.9, x - 1, hip, x - 2 - sw, WY1 + 2)
      line(dl * 0.9, x + 1, hip, x + 2 + sw, WY1 + 2)
      if up > 0.3 and i % 2 == 1 then
        line(dl + up * 4, x + 2, top + 5, x + 6, top - 3)               -- the point
        line(dl, x - 2, top + 5, x - 4, top + 10)
      else
        line(dl, x + 2, top + 5, x + 4 + sw, top + 10)
        line(dl, x - 2, top + 5, x - 4 - sw, top + 10)
      end
      put(2 + mid * 5 + hi * 2, x - 1, top + 0.5, 3, 1)                 -- the rim on the hair
    end
    line(1.5 + amp, 0, WY0 - 1, 127, WY0 - 1)

    -- the mirror ball and its spots
    rot = rot + K.DTS * (0.6 + e * 0.8)
    local bx, by, br = 64, 6, 5
    line(1.5, bx, 0, bx, by - br)
    K.disc(2 + amp + K.env.kick * 3, bx, by, br)
    for k = 0, 9 do
      local a = rot * 2 + k * 0.63
      local fx = bx + cos(a) * (br - 1.2)
      local fy = by - 3 + (k % 4) * 2
      if sin(a) > 0 then put(3 + hi * 8 * (0.5 + 0.5 * sin(T * 6 + k)), fx, fy, 1, 1) end
    end
    local nsp = c > 0.4 and 18 or 12
    for k = 0, nsp - 1 do
      local a = rot + k * K.TAU / 12 + (k >= 12 and 0.26 or 0)
      local s = sin(a)
      if s > -0.2 then
        local x = 64 + cos(a) * 80
        local y = (k % 3 == 0) and (WY0 + 3 + (k % 5) * 3) or (YS[1] + 3 + (k % 4) * 6)
        if x > 0 and x < 127 then put(2 + hi * 8 + s * 2 + K.env.kick * 4, x, y, 3, 1) end
      end
    end

    -- the floor: lit tiles, then the grid over them
    for r = 0, NR - 1 do
      local y0, y1 = YS[r + 1], YS[r + 2]
      for cc = 0, NC - 1 do
        local v = tile[r * NC + cc + 1]
        -- the low end glows the middle tiles
        local mdist = abs(cc - 3.5) + abs(r - 2) * 1.2
        v = max(v, lo * (0.12 + 0.3 * max(0, 1 - mdist / 2)))
        if v > 0.06 then
          local l = 1 + v * (9 + e * 2)
          local ya, yb = y0 + 1, y1 - 1
          if yb - ya >= 3 then ya, yb = ya + 1, yb - 1 end
          for y = ya, yb do
            local xa, xb = xat(cc, y), xat(cc + 1, y)
            local ins = (xb - xa) * 0.18 + 1
            xa, xb = xa + ins, xb - ins
            if xb > xa then put(l, xa, y, xb - xa, 1) end
          end
        end
      end
    end
    local gl = 1.2 + amp * 0.8
    for r = 1, NR + 1 do line(1 + amp * 0.4 + hi * 1.2, 0, YS[r], 127, YS[r]) end
    for k = 0, NC do line(gl + lo * 2.2 + K.env.kick * 1.5, xat(k, YS[1]), YS[1], xat(k, 64), 64) end
    K.grain(function(u, v) return 30 + u * 68, 1 + v * 12 end, 2 + hi * 20, 4 + hi * 6)
  end

  ---------------------------------------------------------------- view 2
  local GEL = {2, 5, 3, 6, 2.5, 4}
  local SY = 46                                 -- the stage line
  local NP = 6                                  -- players

  local function draw2(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    pulse = pulse * math.exp(-DT / 0.18)
    swing2 = swing2 * math.exp(-DT / 0.5)
    ps = K.follow(ps, pulse, 0.1, DT)
    local sw = mid * (0.6 + kl * 0.4)

    -- the glitter curtain: strands, their sequins catching the light
    for x = 2, 125, 5 do
      local l = 1 + amp * 0.8 + hi * 1.5 * (0.5 + 0.5 * sin(T * 2 + x * 0.7))
      line(l, x, 0, x, SY - 9)
    end
    for i = #glit, 1, -1 do
      local G = glit[i]
      local age = T - G.t0
      local y = G.y0 + age * 40
      if age > 0.7 or y > SY - 8 then table.remove(glit, i)
      else put(min(12, 3 + G.v * 7 * (1 - age / 0.7) + hi * 2), G.x, y, 1, 2) end
    end
    -- standing shimmer: the highs keep a few sequins lit
    for k = 0, 11 do
      local x = 2 + floor(K.hash(k + floor(T * 3) * 13, 5) * 25) * 5
      local y = floor(K.hash(k + floor(T * 3) * 13, 6) * (SY - 10))
      put(2 + hi * 7, x, y, 1, 1)
    end

    -- the beams: from lamps along the top, each wheel's gel a grey
    for i, b in ipairs(beams) do
      b.va = b.va + (-(b.a - (i - 2) * -0.3) * 1.5 - b.va * 1.2) * DT + (K.rnd() - 0.5) * c * 6 * DT
      b.a = clamp(b.a + (b.va + sin(T * 0.4 + i * 2.1) * (0.25 + swing2 * 0.6)) * K.DTS, -0.9, 0.9)
      local g = GEL[(floor(wheel) + b.g) % #GEL + 1]
      local l = (g * 0.5 + amp * 1.0 + ps * 3 + e * 0.4)
      local len = 48 + lo * 6
      local ex, ey = b.x + sin(b.a) * len, 1 + cos(b.a) * len
      for k = -1, 1 do
        local spread = k * (4 + ps * 2)
        line(l * (1 - abs(k) * 0.55), b.x + k * 0.5, 1, ex + spread, ey)
      end
      -- the pool where it lands
      K.ring(l, ex, ey, 6 + ps * 2, 12, 0, K.TAU, 0.35)
      put(min(13, 4 + l), b.x - 2, 0, 5, 2)
    end

    -- the stage: the wash behind the players lifts with the strings
    for x = 1, 127, 3 do
      line(1 + mid * 2.5 + lo * 0.6, x, SY - 6, x, SY - 1)
    end
    line(1.2 + lo * 1.5 + ps, 0, SY, 127, SY)
    for x = 4, 127, 16 do                       -- footlights
      put(1.5 + lo * 4 + ps * 2, x, 62, 3, 2)
      line(1 + lo * 3, x + 1, 61, x + 1, SY + 2)
    end

    -- the string section: seated players, cellos and violins, sawing
    for i = 1, NP do
      local px = 10 + (i - 1) * 21.5
      local cello = i % 3 == 0
      local sway = sin(T * 1.2 + i) * (1 + sw * 1.5)
      local rim = 1.5 + mid * 2.5 + kl * 1.5
      put(1, px - 4 + sway * 0.4, SY + 3, 9, 63 - SY - 3)
      -- the head and the shoulders, outlined by the wash behind them
      K.ring(rim, px + sway * 0.5, SY - 2, 2.6, 8)
      line(rim, px - 5 + sway * 0.3, SY + 4, px - 2 + sway * 0.5, SY + 1)
      line(rim, px + 5 + sway * 0.3, SY + 4, px + 2 + sway * 0.5, SY + 1)
      line(rim * 0.7, px - 5, SY + 4, px - 6, 63)
      line(rim * 0.7, px + 5, SY + 4, px + 6, 63)
      local bow = sin(T * (3 + sw * 3) + i * 1.3) * (3 + sw * 6)
      if cello then
        K.ring(rim, px + 7, SY + 12, 4, 10, 0, K.TAU, 1.4)
        line(rim, px + 7, SY + 6, px + 7, SY - 2)
        line(2 + mid * 5, px + 1 + bow, SY + 9, px + 13 + bow, SY + 13)
      else
        line(rim, px - 3, SY + 3, px - 9, SY + 6)
        line(2 + mid * 5, px - 8 + bow * 0.4, SY - 1 + bow * 0.3, px + 4 + bow * 0.4, SY + 9 + bow * 0.3)
      end
    end
  end

  function M.draw(S)
    arms = arms * math.exp(-K.DT / 0.35)
    if K.view == 2 then draw2(S) else draw1(S) end
  end

  M.init()
  return M
end
