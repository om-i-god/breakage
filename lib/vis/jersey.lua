-- jersey. view 1: a cutaway bed in a Newark bedroom at night, a row of coil springs under the mattress and kids bouncing on it, a vocal chop scrawled on the wall.
-- view 2: the producer's sampler: a vocal cut into slices across the top that the drums chop, swap, reverse and stutter, a ball bouncing the triplets, a grid of pads lighting per voice.
-- view 3: a dance battle at eye level: a ring of silhouettes round a lit floor, two battlers trading rounds in the middle, speaker stacks either side.
--
-- view 1: the kick launches the bouncers off the mattress (it sinks and the
-- springs ring when they land); the bed squeak (perc 19) boings one spring
-- hard with squeak marks; the snare runs a wave along the mattress and
-- knocks the headboard, the clap flares the lamp; closed hats pop specks of
-- dust off the sheet, open hats loose a feather that floats down; vox chops
-- (perc 16) scrawl cut-up waveforms over the wall; congas, bongos and toms
-- bounce the ends of the bed, bells and claves ting the lamp chain; ticks
-- squeak a spring, break slices slide the quilting, a ratchet runs a chain
-- of boings down the bed, a fill sends everyone sky high. out_amp lights the
-- city in the window and the lamp, out_lo sags the springs and glows under
-- the bed, out_mid lights the mattress and the scrawl, out_hi glints the
-- coils and the dust in the window light. the jumps grow through the
-- phrase and the lamp swings once a bar; energy brings more bouncers,
-- chaos shakes the coils loose and ghosts the jumpers, kickless lets them
-- stand swaying while dust hangs in the air.
-- view 2: vox chops light a slice and stutter it; snares cut a slice loose
-- and drop it; claps swap two slices; open hats reverse a slice, closed
-- hats tick the ruler under the playhead; break slices remap the slices;
-- ticks glitch a column; a ratchet stutters the slice under the playhead;
-- a fill shuffles them all; the kick bounces the ball over the playhead and
-- pumps the waveform. every voice has its own pad below. a new vocal on
-- each phrase. out_amp scales the waveform, out_lo thickens its spine and
-- warms the kick pads, out_mid lights it, out_hi the ruler and the fizz on
-- top. chaos drops and reverses slices, kickless time-stretches the vocal.
-- view 3: the kick bounces the battler whose round it is (a new round each
-- bar) and the crowd bobs; the bed squeak drops him into a quick bounce
-- squat; the snare sends a wave of arms up round the ring, claps bring the
-- front row's hands up; open hats raise phones, closed hats nod heads; vox
-- chops are shouts from the crowd; ticks are phone flashes; toms and break
-- slices are leg kicks; a ratchet ripples hops round the ring; a fill makes
-- the battlers trade places and the crowd jump. out_amp lights the floor
-- pool, out_lo pumps the speaker cones and the floor ring, out_mid rims the
-- crowd, out_hi the dust in the light. the ring closes in over the phrase;
-- energy livens the crowd, chaos ghosts the battlers and jostles the ring,
-- kickless sets everyone swaying slow in a haze.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, exp, sqrt = math.sin, math.cos, math.floor, math.max, math.min,
    math.abs, math.exp, math.sqrt
  local PI, TAU = math.pi, K.TAU

  -- shared: the phrase position (0..1), the bar count
  local phr, bars = 0, 0

  ---------------------------------------------------------------- a dancer
  -- a stick silhouette standing at (x, y) (feet), scale s. cr crouch 0..1,
  -- al / ar arm angles (0 hanging, pi straight up), sp leg spread, lean,
  -- kk a leg kick (-1..1). returns the two hands.
  local function fig(l, x, y, s, cr, al, ar, sp, lean, kk, thick)
    cr = clamp(K.num(cr, 0), 0, 1)
    kk = clamp(K.num(kk, 0), -1, 1)
    local hy = y - s * (7 - 2.6 * cr)
    local hx = x + lean * s
    local ny = hy - s * 5.2
    local nx = hx + lean * s * 1.5
    local kn = s * (1.0 + cr * 1.8)
    local ky = y - s * (3.4 - 1.4 * cr)
    local fl = sp * s
    line(l, hx, hy, x - kn, ky); line(l, x - kn, ky, x - fl, y)
    local fx, fy = x + fl + kk * s * 3, y - abs(kk) * s * 3
    line(l, hx, hy, x + kn + kk * s, ky - abs(kk) * s); line(l, x + kn + kk * s, ky - abs(kk) * s, fx, fy)
    line(l, hx, hy, nx, ny)
    if thick then line(l, hx + 1, hy, nx + 1, ny) end
    local hr = max(1, s * 1.25)
    local hcx, hcy = nx + lean * s * 0.4, ny - hr - 0.3
    if hr < 1.6 then put(l, hcx - 1, hcy - 1, 2, 2) else K.disc(l, hcx, hcy, hr) end
    local sy = ny + s * 0.7
    local L = s * 2.5
    local hands = {}
    for side = -1, 1, 2 do
      local a = side < 0 and al or ar
      local ex, ey = nx + side * sin(a) * L, sy + cos(a) * L
      local a2 = a + 0.45
      local qx, qy = ex + side * sin(a2) * L, ey + cos(a2) * L
      line(l, nx, sy, ex, ey); line(l, ex, ey, qx, qy)
      hands[#hands + 1] = qx; hands[#hands + 1] = qy
    end
    return hands[1], hands[2], hands[3], hands[4]
  end

  ---------------------------------------------------------------- view 1 state
  local NS = 12
  local SX = {}
  for i = 1, NS do SX[i] = 18 + (i - 1) * 8.4 end
  local BASE, REST = 58, 45             -- the spring rail, the springs' tops at rest
  local MX0, MX1 = 12, 116              -- the mattress ends
  local sp, sv, sl                      -- per spring: displacement (down +), velocity, light
  local jum                             -- the bouncers
  local specks, waves, chops, squeaks
  local hbf, clf, lamp_v, lamp_a, quilt, railf
  local rq                              -- ratchet chain: {i, n, next}
  local NJ = 3
  local HOME = {64, 38, 90}
  local WIN = K.profile(function(x)
    local b = x // 5
    return 15 + floor(K.hash(b, 301) * 9)
  end)

  ---------------------------------------------------------------- view 2 state
  local NSL = 8
  local slc                             -- per slice: src, dy, dyt, g, rev, rep, cut
  local WV, wseed, wfade, wold
  local pad
  local ball_h, ball_v
  local glt                             -- column glitches
  local kick_n = 0
  local fillq2

  ---------------------------------------------------------------- view 3 state
  local NC = 18
  local CROWD = {}
  do
    local k = 0
    for i = 0, NC + 1 do
      local a = (i + 0.5) / (NC + 2) * TAU + 0.15
      local fa = abs(((a - PI / 2) + PI) % TAU - PI)
      if fa > 0.32 and k < NC then
        k = k + 1
        CROWD[k] = {a = a + (K.hash(i, 311) - 0.5) * 0.12, s0 = K.hash(i, 312)}
      end
    end
    table.sort(CROWD, function(p, q) return sin(p.a) < sin(q.a) end)
  end
  local crowd                           -- per member: h, hv, up, up_at, ph, shout, nod
  local bat                             -- the two battlers
  local act = 1                         -- whose round it is
  local cone, swap
  local coned = 0

  local function mkwave(seed)
    local w = {}
    for j = 0, 127 do
      local u = j / 128
      local a = 0.04
      for k = 0, 4 do
        local c = (k + 0.15 + K.hash(seed * 7 + k, 321) * 0.6) / 5
        local wd = 0.025 + K.hash(seed * 7 + k, 322) * 0.05
        local d = (u - c) / wd
        if d > -1 and d < 6 then
          local v = (d < 0 and (1 + d) or exp(-d * 0.6)) * (0.6 + 0.4 * K.hash(seed * 7 + k, 323))
          a = max(a, v)
        end
      end
      w[j] = clamp(a * (0.75 + 0.25 * K.hash(j + seed * 131, 324)), 0, 1)
    end
    return w
  end

  function M.init()
    sp, sv, sl = {}, {}, {}
    for i = 1, NS do sp[i], sv[i], sl[i] = 0, 0, 0 end
    jum = {}
    for i = 1, NJ do jum[i] = {x = HOME[i], h = 0, vy = 0, a = i == 1 and 1 or 0, sq = 0, arm = 0} end
    specks, waves, chops, squeaks = {}, {}, {}, {}
    hbf, clf, lamp_v, lamp_a, quilt, railf = 0, 0, 0, 0, 0, 0
    rq = nil
    phr, bars = 0, 0
    slc = {}
    for k = 0, NSL - 1 do slc[k] = {src = k, dy = 0, dyt = 0, g = 0, rev = 0, rep = 0, cut = 0} end
    wseed, wfade = 1, 1
    WV = mkwave(1)
    wold = WV
    pad = {}
    for i = 1, 16 do pad[i] = 0 end
    ball_h, ball_v = 0, 0
    glt = {}
    kick_n = 0
    fillq2 = nil
    crowd = {}
    for i = 1, NC do crowd[i] = {h = 0, hv = 0, up = 0, up_at = -1, ph = 0, shout = 0, nod = 0} end
    bat = {}
    for i = 1, 2 do bat[i] = {x = i == 1 and 50 or 78, tx = i == 1 and 50 or 78, h = 0, vy = 0, sq = 0, kk = 0, pt = 0, sw = 0} end
    act, cone, swap, coned = 1, 0, 0, 0
  end
  M.clear = M.init

  ---------------------------------------------------------------- events
  local function near(x)
    local i = floor((x - SX[1]) / 8.4 + 1.5)
    return clamp(i, 1, NS)
  end
  local function push(x, dv, wide)
    wide = wide or 1.6
    for i = 1, NS do
      local d = (SX[i] - x) / (8.4 * wide)
      local g = exp(-d * d)
      if g > 0.05 then
        sv[i] = sv[i] + dv * g
        sl[i] = max(sl[i], min(1, abs(dv) / 60) * g)
      end
    end
  end
  local function boing(i, v)
    i = clamp(i, 1, NS)
    sv[i] = sv[i] + 70 * v
    sl[i] = max(sl[i], v)
    if #squeaks >= 6 then table.remove(squeaks, 1) end
    squeaks[#squeaks + 1] = {x = SX[i], t0 = K.T, v = v}
  end
  local function speck(open, v)
    if #specks >= 14 then table.remove(specks, 1) end
    local x = MX0 + 6 + K.rnd() * (MX1 - MX0 - 12)
    if open then
      specks[#specks + 1] = {x = x, y = 18 + K.rnd() * 8, vy = 6, open = true, t0 = K.T, v = v, life = 2.4, ph = K.rnd() * 6}
    else
      specks[#specks + 1] = {x = x, y = 37, vy = -(40 + 30 * v), open = false, t0 = K.T, v = v, life = 0.6, ph = 0}
    end
  end
  local function chop(v)
    if #chops >= 6 then table.remove(chops, 1) end
    local w = 14 + floor(K.rnd() * 18)
    chops[#chops + 1] = {x = 4 + K.rnd() * (74 - w), y = 6 + floor(K.rnd() * 3) * 5, w = w,
      seed = floor(K.rnd() * 9999), t0 = K.T, v = v, cut = 1 + floor(K.rnd() * 3)}
  end
  local function slice_at_head()
    return clamp(floor(K.bar_ph * NSL), 0, NSL - 1)
  end
  local function crowd_wave(v)
    local a0 = K.rnd() * TAU
    for i = 1, NC do
      local m = crowd[i]
      local d = abs(((CROWD[i].a - a0) + PI) % TAU - PI) / PI
      m.up_at = K.T + d * 0.35
      m.upv = v
    end
  end
  local function hop(m, v) if m.h <= 0.01 then m.hv = 22 + 22 * v end end

  function M.kick(v)
    v = K.num(v, 1)
    local boost = 1 + phr * 0.45 + K.energy * 0.25
    for i = 1, NJ do
      local J = jum[i]
      if J.a > 0.3 and J.h < 3 then
        J.vy = (58 + 26 * v) * boost * (0.85 + 0.3 * K.hash(i + kick_n, 331))
        J.h = max(J.h, 0.1)
        push(J.x, 55 * v, 1.2)
      end
    end
    railf = max(railf, 0.5 * v)
    -- view 2
    kick_n = kick_n + 1
    pad[1 + kick_n % 2] = max(pad[1 + kick_n % 2], v)
    ball_v = 60 + 30 * v
    for k = 0, NSL - 1 do slc[k].g = max(slc[k].g, 0.12 * v) end
    -- view 3
    local B = bat[act]
    if B.h < 3 then B.vy = (60 + 30 * v) * (1 + phr * 0.3) end
    B.sw = B.sw + 1
    bat[3 - act].sq = max(bat[3 - act].sq, 0.4)
    for i = 1, NC do
      local m = crowd[i]
      m.ph = m.ph + 1
      if K.hash(i + kick_n * 7, 332) < 0.15 + K.energy * 0.25 then hop(m, 0.5 * v) end
    end
    cone = max(cone, v)
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    if #waves >= 4 then table.remove(waves, 1) end
    local dir = K.rnd() < 0.5 and -1 or 1
    waves[#waves + 1] = {t0 = K.T, dir = dir, v = v}
    hbf = max(hbf, 0.6 + 0.4 * v)
    -- view 2: cut a slice loose
    local k = floor(K.rnd() * NSL)
    slc[k].cut, slc[k].dyt = 1, 4 + 4 * v
    pad[3] = max(pad[3], v)
    -- view 3
    crowd_wave(v)
    bat[act].pt = 1
  end

  function M.clap(v)
    v = K.num(v, 1)
    clf = max(clf, 0.6 + 0.4 * v)
    lamp_v = lamp_v + (K.rnd() - 0.5) * 2
    local a = floor(K.rnd() * (NSL - 1))
    slc[a].src, slc[a + 1].src = slc[a + 1].src, slc[a].src
    slc[a].g, slc[a + 1].g = max(slc[a].g, 0.8), max(slc[a + 1].g, 0.8)
    pad[4] = max(pad[4], v)
    for i = 1, NC do
      if sin(CROWD[i].a) > 0.2 then crowd[i].up = max(crowd[i].up, 0.7 * v); crowd[i].clap = 1 end
    end
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    speck(open, v)
    if open then
      pad[6] = max(pad[6], v)
      local k = floor(K.rnd() * NSL)
      slc[k].rev = 1
      local m = crowd[1 + floor(K.rnd() * NC)]
      m.phone = 1
    else
      pad[5] = max(pad[5], v)
      local m = crowd[1 + floor(K.rnd() * NC)]
      m.nod = 1
    end
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    kind = floor(K.num(kind, 1))
    if kind == 19 then
      local i = 1 + floor(K.rnd() * NS)
      boing(i, 0.7 + 0.3 * v)
      pad[9] = max(pad[9], v)
      bat[act].sq = 1
      for i2 = 1, NJ do jum[i2].sq = max(jum[i2].sq, 0.6) end
    elseif kind == 16 then
      chop(v)
      pad[8] = max(pad[8], v)
      local k = floor(K.rnd() * NSL)
      slc[k].g, slc[k].rep = 1, 0.5
      slc[k].dyt = slc[k].dyt - 3
      local m = crowd[1 + floor(K.rnd() * NC)]
      m.shout = 1
    elseif kind == 1 or kind == 2 or kind == 13 or kind == 17 then
      local end_x = (kind == 1 or kind == 13) and SX[1] or SX[NS]
      push(end_x, 45 * v, 1.5)
      pad[10] = max(pad[10], v)
      bat[act].kk = (K.rnd() < 0.5 and -1 or 1)
    elseif kind == 3 or kind == 4 or kind == 6 or kind == 21 or kind == 11 or kind == 8 then
      lamp_v = lamp_v + (K.rnd() < 0.5 and -1.5 or 1.5) * v
      pad[11] = max(pad[11], v)
      local k = floor(K.rnd() * NSL)
      slc[k].g = max(slc[k].g, 0.6 * v)
    else
      local i = 1 + floor(K.rnd() * NS)
      sv[i] = sv[i] + 30 * v
      sl[i] = max(sl[i], 0.6 * v)
      pad[12] = max(pad[12], v)
      local m = crowd[1 + floor(K.rnd() * NC)]
      hop(m, v)
    end
  end
  function M.tom(v) M.perc(13, v) end

  function M.tick(kind)
    boing(1 + floor(K.rnd() * NS), 0.3)
    pad[13] = max(pad[13], 0.8)
    if #glt >= 6 then table.remove(glt, 1) end
    glt[#glt + 1] = {x = floor(K.rnd() * 64) * 2, t0 = K.T}
    local m = crowd[1 + floor(K.rnd() * NC)]
    m.flash = 1
  end

  function M.brk(s, n, rev)
    s, n = floor(K.num(s, 1)), max(1, floor(K.num(n, 8)))
    quilt = quilt + (rev and -2 or 2)
    local k = (s - 1) % NSL
    slc[k].src = (s * 3) % NSL
    slc[k].rev = rev and 1 or slc[k].rev
    slc[k].g = max(slc[k].g, 0.5)
    pad[14] = max(pad[14], 0.8)
    bat[act].kk = rev and -1 or 1
  end

  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 16)
    rq = {i = 1, n = n, next = K.NOW, step = max(1, floor(NS / n))}
    local k = slice_at_head()
    slc[k].rep, slc[k].g = 0.3 + n * 0.06, 1
    pad[15] = 1
    local a0 = floor(K.rnd() * NC)
    for j = 0, min(n, NC) - 1 do
      local m = crowd[(a0 + j) % NC + 1]
      m.hop_at = K.T + j * 0.04
    end
  end

  function M.fill()
    for i = 1, NJ do
      local J = jum[i]
      if J.a > 0.3 then J.vy = 150; J.h = max(J.h, 0.1) end
    end
    railf = 1
    for i = 1, NS do sl[i] = max(sl[i], 0.7) end
    pad[16] = 1
    fillq2 = {k = 0, next = K.NOW}
    bat[1].tx, bat[2].tx = bat[2].tx, bat[1].tx
    swap = 1
    for i = 1, NC do hop(crowd[i], 1) end
  end

  function M.bar(S)
    bars = bars + 1
    local pl = max(1, floor(K.num(S and S.phrase_len, 16)))
    local pp = floor(K.num(S and S.phrase_pos, 0)) % pl
    phr = clamp(pp / pl, 0, 1)
    act = 1 + bars % 2
    if pp == 0 then
      wold, wfade = WV, 0
      wseed = wseed + 1
      WV = mkwave(wseed)
      for i = 1, NJ do HOME[i] = 20 + K.hash(wseed * 3 + i, 341) * 88 end
    end
    if K.chaos > 0.4 then
      local k = floor(K.rnd() * NSL)
      slc[k].src = floor(K.rnd() * NSL)
    end
  end

  ---------------------------------------------------------------- view 1 draw
  local function top_at(x)
    local u = (x - SX[1]) / 8.4
    local i = floor(u)
    local f = u - i
    local a = sp[clamp(i + 1, 1, NS)]
    local b = sp[clamp(i + 2, 1, NS)]
    local d = a + (b - a) * f
    if x < SX[1] then d = d * clamp((x - MX0) / (SX[1] - MX0), 0, 1) end
    if x > SX[NS] then d = d * clamp((MX1 - x) / (MX1 - SX[NS]), 0, 1) end
    return d
  end

  local function wave_bump(x)
    local b = 0
    for _, W in ipairs(waves) do
      local age = K.T - W.t0
      local cx = (W.dir > 0 and MX0 or MX1) + W.dir * age * 140
      local d = (x - cx) / 7
      b = b + exp(-d * d) * 2.5 * W.v * max(0, 1 - age / 0.8)
    end
    return b
  end

  local function draw1(S)
    local T, DT, e, c, kl = K.T, K.DTS, K.energy, K.chaos, K.kickless
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]

    -- the ratchet chain
    if rq then
      while rq and K.NOW >= rq.next do
        boing(rq.i, 0.6)
        rq.i = rq.i + rq.step
        rq.n = rq.n - 1
        rq.next = rq.next + 0.05
        if rq.n <= 0 or rq.i > NS then rq = nil end
      end
    end

    -- physics, in small steps
    local n = max(1, math.ceil(DT / 0.016))
    local dt = min(DT, 0.25) / n
    local want = 1 + floor(e * 2.2 + 0.2)
    for _ = 1, n do
      for i = 1, NS do
        sv[i] = sv[i] + (-420 * sp[i] - 7 * sv[i]) * dt
        sp[i] = clamp(sp[i] + sv[i] * dt, -6, 8)
      end
      for i = 1, NJ do
        local J = jum[i]
        if J.h > 0 or J.vy > 0 then
          J.vy = J.vy - 400 * dt
          J.h = J.h + J.vy * dt
          if J.h <= 0 then
            J.h = 0
            push(J.x, -J.vy * 0.45, 1.1)
            J.vy = 0
          end
        end
      end
    end
    for i = 1, NJ do
      local J = jum[i]
      J.a = K.follow(J.a, i <= want and 1 or 0, 0.6, K.DT)
      local hx = HOME[i] + sin(T * (0.35 + i * 0.07) + i * 2) * (8 + c * 10)
      J.x = K.follow(J.x, clamp(hx, 26, 102), 0.8, K.DT)
      J.sq = J.sq * exp(-K.DT / 0.2)
      J.h = clamp(J.h, 0, 60)
    end
    for i = 1, NS do sl[i] = sl[i] * exp(-K.DT / 0.25) end
    hbf = hbf * exp(-K.DT / 0.2)
    clf = clf * exp(-K.DT / 0.25)
    railf = railf * exp(-K.DT / 0.4)
    -- the lamp: a pendulum, pushed once a bar
    local swing = 0.18 * sin(K.bar_ph * TAU) * (1 - kl * 0.5) + 0.05 * sin(T * 0.7)
    lamp_v = lamp_v + (-30 * lamp_a - 1.5 * lamp_v) * K.DT
    lamp_a = clamp(lamp_a + lamp_v * K.DT, -0.6, 0.6)
    for i = #waves, 1, -1 do if K.T - waves[i].t0 > 0.8 then table.remove(waves, i) end end

    -- the window: the city at night, lit by the level
    local wx0, wx1, wy0, wy1 = 86, 120, 4, 27
    for x = wx0 + 1, wx1 - 2, 2 do
      local top = floor(K.at(WIN, x - wx0 + 40) + 0.5)
      put(1, x, top, 2, wy1 - top)
    end
    for k = 0, 13 do
      local x = wx0 + 2 + floor(K.hash(k, 351) * 30)
      local top = K.at(WIN, x - wx0 + 40)
      local y = floor(top + 2 + K.hash(k, 352) * (wy1 - top - 3))
      if K.hash(k, 353) < 0.35 + amp * 0.6 then
        put(2 + amp * 4 + 1.5 * sin(T * 0.4 + k * 1.7) ^ 2, x, y, 1, 1)
      end
    end
    put(2 + amp * 2, 112, 8, 2, 2)                -- the moon over Newark
    line(2.5, wx0, wy0, wx1, wy0); line(2.5, wx0, wy1, wx1, wy1)
    line(2, wx0, wy0, wx0, wy1); line(2, wx1, wy0, wx1, wy1)
    line(1.5, (wx0 + wx1) / 2, wy0, (wx0 + wx1) / 2, wy1)
    -- the light falling from it, the dust in it (HI)
    line(1, wx0, wy1, wx0 - 26, 38); line(1, wx1 - 6, wy1, wx1 - 30, 38)
    K.grain(function(u, v) return wx0 - 22 + u * 40 + v * 4, wy1 + v * 10 end, 2 + hi * 14 + kl * 4, 3 + hi * 5)

    -- the lamp
    local la = swing + lamp_a
    local lx, ly = 50 + sin(la) * 13, cos(la) * 13
    line(1.5, 50, 0, lx, ly)
    local lb = 3 + amp * 4 + clf * 6 + phr * 2
    K.disc(min(12, lb), lx, ly + 1.5, 1.8)
    line(min(6, 1 + lb * 0.3), lx - 3, ly - 1, lx + 3, ly - 1)
    if lb > 4.5 then
      line(min(4, lb * 0.25), lx - 2, ly + 3, lx - 9, ly + 15)
      line(min(4, lb * 0.25), lx + 2, ly + 3, lx + 9, ly + 15)
    end

    -- the wall scrawl: a faint running waveform and the vox chops over it
    local px, py
    for x = 4, 78, 3 do
      local y = 13 + sin(x * 0.31 + T * 2.2) * (1 + mid * 3) * (0.5 + 0.5 * sin(x * 0.07 - T * 0.6))
      if px then line(1 + mid * 1.5, px, py, x, y) end
      px, py = x, y
    end
    for i = #chops, 1, -1 do
      local C = chops[i]
      local u = (K.T - C.t0) / 1.1
      if u >= 1 then table.remove(chops, i)
      else
        local l = (4 + 7 * C.v) * (1 - u) * (u < 0.08 and u / 0.08 or 1) + mid * 2
        for x = 0, C.w - 1, 2 do
          local piece = floor(x / C.w * (C.cut + 1))
          local dy = (piece % 2 == 0) and 0 or (K.hash(C.seed + piece, 361) < 0.5 and -2 or 2)
          local dx = piece * 2 * u
          local a = K.hash(C.seed + x * 7, 362) * (0.4 + 0.6 * sin(x / C.w * PI)) * 4.5
          line(min(12, l), C.x + x + dx, C.y + dy - a, C.x + x + dx, C.y + dy + a)
        end
      end
    end

    -- the headboard
    local hb = 1.5 + hbf * 5 + mid
    for k = 0, 3 do
      local x = 3 + k * 2.5
      line(hb * (k == 0 and 1 or 0.7), x, 22 + k, x, BASE)
    end
    line(hb, 3, 22, 11, 25)
    -- the footboard
    line(1.5 + railf * 3, 118, 34, 118, BASE)
    line(1.5 + railf * 3, 116, 34, 120, 34)

    -- the floor, the glow under the bed (LO)
    line(1.5, 0, 60, 127, 60)
    local ug = lo * 1.6 + railf * 1.2 + K.duck * 0.8
    if ug > 0.6 then K.dashes(ug, 62, 4 + floor(lo * 4), 6, T * 3, 16, 112) end
    -- the rail the springs stand on
    line(1.5 + railf * 1.5 + lo * 0.8, MX0, BASE, MX1, BASE)

    -- the springs: zigzag coils from the rail up to the mattress
    local sag = lo * 1.5
    for i = 1, NS do
      local x = SX[i]
      local top = REST + sp[i] + sag
      local h = BASE - top
      local l = 1.5 + sl[i] * 6 + hi * 1.2 + max(0, sp[i]) * 0.3
      local wdt = 2.2 + max(0, sp[i]) * 0.2
      local jx = c > 0.3 and sin(T * 9 + i * 3) * (c - 0.3) * 2.5 or 0
      -- the coil's two sides, near vertical, and its turns between them (dim)
      line(min(11, l), x - wdt + jx, BASE, x - wdt * 0.8, top + 1)
      line(min(11, l * 0.8), x + wdt + jx, BASE, x + wdt * 0.8, top + 1)
      local nz = 4
      for z = 0, nz - 1 do
        local y0 = BASE - h * z / nz
        local y1 = BASE - h * (z + 0.5) / nz
        line(min(5, 1 + l * 0.25), x - wdt + jx, y0, x + wdt + jx, y1)
      end
      if hi > 0.3 then put(1 + hi * 4, x + wdt, BASE - h * 0.4, 1, 1) end
    end
    -- squeak marks off a spring
    for i = #squeaks, 1, -1 do
      local Q = squeaks[i]
      local u = (K.T - Q.t0) / 0.5
      if u >= 1 then table.remove(squeaks, i)
      else
        local l = (3 + 6 * Q.v) * (1 - u)
        local r = 3 + u * 6
        K.ring(l, Q.x, 50, r, 4, -0.5, 0.5)
        K.ring(l, Q.x, 50, r, 4, PI - 0.5, PI + 0.5)
      end
    end

    -- the mattress: its body, the ticking, the quilting
    local tilt = c * sin(T * 0.8) * 2
    local body = 1.1 + mid * 1.2 + e * 0.4
    local tl = 2 + mid * 1.5 + e * 0.5
    local ptx, pty
    for x = MX0, MX1 - 1, 2 do
      local d = top_at(x) + sag - wave_bump(x) + tilt * (x - 64) / 52
      local ty = floor(38 + d + 0.5)
      put(body, x, ty + 1, 2, 5)
      if ptx then line(min(12, tl + wave_bump(x) * 2), ptx, pty, x + 1, ty) end
      ptx, pty = x + 1, ty
      if (x + floor(quilt)) % 8 == 0 then put(tl + 1 + hi * 2, x, ty + 3, 1, 1) end
    end
    line(tl * 0.7, MX0, 39 + sag, MX0, 45 + sag)
    line(tl * 0.7, MX1 - 1, 39 + sag, MX1 - 1, 45 + sag)

    -- the bouncers (and their chaos ghosts)
    for i = 1, NJ do
      local J = jum[i]
      if J.a > 0.05 then
        local fy = 38 + top_at(J.x) + sag - wave_bump(J.x) - J.h
        local air = clamp(J.h / 12, 0, 1)
        local cr = clamp(max(0, top_at(J.x)) / 5 + J.sq * 0.6 + (kl * 0.2), 0, 1)
        local arm = 0.5 + air * 2.2 + (J.vy > 0 and 0.3 or 0)
        local sway = kl * sin(T * 1.3 + i) * 0.6
        local l = (4.5 + amp * 2 + air * 3 + phr * 1.5) * J.a
        if c > 0.3 then
          fig((1 + c * 2) * J.a, J.x + sin(T * 3 + i) * c * 6, fy + 2, 1.15, cr, arm + 0.4, arm - 0.2, 0.9, sway, 0)
        end
        fig(min(12, l), J.x, fy, 1.2, cr * (1 - air), arm + sway, arm - sway, 0.8 + air * 0.6, sway,
          air > 0.5 and sin(T * 5 + i) * 0.4 or 0, true)
      end
    end

    -- dust and feathers
    for i = #specks, 1, -1 do
      local P = specks[i]
      local age = K.T - P.t0
      if age > P.life then table.remove(specks, i)
      else
        if P.open then
          P.y = P.y + P.vy * K.DTS
          local x = P.x + sin(age * 2.5 + P.ph) * 4
          local a = sin(age * 2.5 + P.ph) * 0.8
          local l = (3 + 4 * P.v) * min(1, (P.life - age) / 0.6)
          line(l, x - cos(a) * 2, P.y - sin(a) * 1, x + cos(a) * 2, P.y + sin(a) * 1)
        else
          P.vy = P.vy + 120 * K.DTS
          P.y = P.y + P.vy * K.DTS
          put((4 + 5 * P.v) * (1 - age / P.life), P.x, P.y, 1, 1)
        end
      end
    end

    -- kickless: the dust hangs, a haze in the room
    if kl > 0.05 then K.haze(0, 16, 128, 40, kl * 0.35, 1, T * 3) end
  end

  ---------------------------------------------------------------- view 2 draw
  local PADS = {}
  for i = 1, 16 do
    local r, cc = (i - 1) // 8, (i - 1) % 8
    PADS[i] = {x = 1 + cc * 16, y = 44 + r * 10}
  end

  local function draw2(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]
    wfade = min(1, wfade + DT / 0.8)
    for k = 0, NSL - 1 do
      local s = slc[k]
      s.dyt = s.dyt * exp(-DT / 0.35)
      s.dy = K.follow(s.dy, s.dyt, 0.06, DT)
      s.g = s.g * exp(-DT / 0.3)
      s.gd = K.follow(s.gd or 0, s.g, 0.06, DT)
      s.rev = s.rev * exp(-DT / 0.6)
      s.rep = max(0, s.rep - DT)
      s.cut = s.cut * exp(-DT / 0.25)
    end
    for i = 1, 16 do pad[i] = pad[i] * exp(-DT / 0.28) end
    if fillq2 then
      while fillq2 and K.NOW >= fillq2.next do
        local k = fillq2.k
        slc[k].src, slc[k].g, slc[k].dyt = floor(K.rnd() * NSL), 1, (k % 2 == 0) and -4 or 4
        fillq2.k = k + 1
        fillq2.next = fillq2.next + 0.05
        if fillq2.k >= NSL then fillq2 = nil end
      end
    end
    -- the ball: bounced by the kick, falls back to the ruler
    local n = max(1, math.ceil(K.DTS / 0.016))
    for _ = 1, n do
      local dt = min(K.DTS, 0.25) / n
      if ball_h > 0 or ball_v > 0 then
        ball_v = ball_v - 420 * dt
        ball_h = ball_h + ball_v * dt
        if ball_h <= 0 then ball_h, ball_v = 0, (ball_v < -40) and -ball_v * 0.35 or 0 end
      end
    end
    ball_h = clamp(ball_h, 0, 40)

    local head = K.bar_ph * 128
    local cy0 = 18
    local H = 5 + amp * 7 + e * 3 + K.duck * 1
    local hk = slice_at_head()
    -- the slice frames
    for k = 0, NSL - 1 do
      local s = slc[k]
      local x0 = k * 16
      local drop = K.hash(k + floor(T * 0.6) * 8, 371) < c * 0.3
      local cy = cy0 + s.dy
      if s.cut > 0.1 then line(min(10, 2 + s.cut * 6), x0, 2, x0, 34) else
        K.dashes(1, 0, 1, 3, 0, x0, x0 + 1)
        line(1, x0, 3, x0, 5); line(1, x0, 31, x0, 33)
      end
      if drop then
        K.dashes(1.5, floor(cy), 2, 4, T * 4, x0 + 1, x0 + 16)
      else
        local base = 1.6 + mid * 3 + s.gd * 5 + (k == hk and 0.7 or 0) + e * 0.6
        for o = 0, 7 do
          local oo = o
          if kl > 0.5 then oo = floor(o / 2) + (k % 2) * 4 end
          if s.rep > 0 then oo = o % 3 end
          if s.rev > 0.3 then oo = 7 - oo end
          local j = clamp(s.src * 16 + oo * 2, 0, 127)
          local w = WV[j] * wfade + wold[j] * (1 - wfade)
          local car = 0.6 + 0.4 * sin(j * 0.9 + T * 4 + k)
          local h = w * car * H * (1 + s.gd * 0.4)
          local x = x0 + 1 + o * 2
          local l = base * (0.6 + 0.6 * w)
          if s.rev > 0.3 then l = l * (0.5 + 0.5 * o / 7) end
          if h >= 0.7 then
            line(min(12, l), x, cy - h, x, cy + h)
            if lo > 0.2 and h > 2 then put(min(12, l + lo * 3), x, cy - 1, 1, 2) end
          else
            put(1 + lo * 1.5, x, cy, 1, 1)
          end
          -- the fizz on top (HI)
          if hi > 0.15 and K.hash(j + floor(T * 9), 372) < hi * 0.35 then
            put(1 + hi * 5, x, cy - h - 2, 1, 1)
          end
        end
      end
    end
    -- column glitches (ticks)
    for i = #glt, 1, -1 do
      local G = glt[i]
      local u = (K.T - G.t0) / 0.3
      if u >= 1 then table.remove(glt, i)
      else put(6 * (1 - u), G.x, 4, 1, 28) end
    end
    -- the ruler: a tick per 16th, the closed hats light it under the playhead
    for k = 0, 15 do
      local x = k * 8
      local onb = k % 4 == 0
      local near = max(0, 1 - abs(x + 4 - head) / 12)
      put(min(12, (onb and 2.5 or 1.3) + hi * 2 + near * pad[5] * 9 + near * 1.5), x, 36, onb and 2 or 1, onb and 3 or 2)
    end
    -- the playhead
    line(1.5 + mid * 1.2, head, 2, head, 34)
    put(min(9, 3 + amp * 3), head - 1, 0, 3, 2)
    -- the ball bouncing the triplets over it
    local by = 39 - ball_h
    for j = 1, 3 do
      local tx = head - j * 3
      put((3 - j * 0.7) * min(1, ball_h / 4), tx, by + j * 1.5, 1, 1)
    end
    put(min(13, 6 + lo * 4 + min(ball_h, 10) * 0.3), head - 1, by - 2, 3, 3)
    -- the pads
    local idle = 0.5 + 0.5 * sin(T * 1.7)
    for i = 1, 16 do
      local P = PADS[i]
      local g = pad[i]
      if i <= 2 then g = max(g, lo * 0.35) end
      if i == 8 then g = max(g, mid * 0.25) end
      local edge = 1.3 + g * 2 + (i == 1 + floor(T * 2) % 16 and idle * 1.5 * (1 - e) or 0)
      put(min(2, edge * 0.6), P.x + 1, P.y, 12, 1); put(min(2, edge * 0.6), P.x + 1, P.y + 7, 12, 1)
      put(edge, P.x, P.y, 1, 8); put(edge, P.x + 13, P.y, 1, 8)
      if g > 0.06 then put(min(9, 1 + g * 6), P.x + 2, P.y + 2, 10, 4) end
    end
    if kl > 0.05 then K.haze(0, 2, 128, 34, kl * 0.3, 1, T * 2) end
  end

  ---------------------------------------------------------------- view 3 draw
  local CXC, CYC = 64, 50
  local function draw3(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]
    cone = cone * exp(-DT / 0.2)
    coned = K.follow(coned, cone, 0.05, DT)
    swap = swap * exp(-DT / 0.6)
    local rx = 56 - phr * 8 - e * 2
    local ry = 9 - phr * 1
    local n = max(1, math.ceil(K.DTS / 0.016))
    local dt = min(K.DTS, 0.25) / n
    for _ = 1, n do
      for i = 1, 2 do
        local B = bat[i]
        if B.h > 0 or B.vy > 0 then
          B.vy = B.vy - 380 * dt
          B.h = B.h + B.vy * dt
          if B.h <= 0 then B.h, B.vy = 0, 0; B.sq = max(B.sq, 0.5) end
        end
      end
      for i = 1, NC do
        local m = crowd[i]
        if m.h > 0 or m.hv > 0 then
          m.hv = m.hv - 300 * dt
          m.h = m.h + m.hv * dt
          if m.h <= 0 then m.h, m.hv = 0, 0 end
        end
      end
    end
    for i = 1, 2 do
      local B = bat[i]
      B.h = clamp(B.h, 0, 40)
      B.x = K.follow(B.x, B.tx, 0.25, DT)
      B.sq = B.sq * exp(-DT / 0.18)
      B.kk = B.kk * exp(-DT / 0.2)
      B.pt = B.pt * exp(-DT / 0.3)
    end

    -- the back wall: the speaker stacks, their cones (LO)
    for side = 0, 1 do
      local x0 = side == 0 and 2 or 112
      line(1.2, x0, 12, x0 + 13, 12); line(1.2, x0, 44, x0 + 13, 44)
      line(1.5, x0, 12, x0, 44); line(1.5, x0 + 13, 12, x0 + 13, 44)
      for k = 0, 2 do
        local cy = 18 + k * 9
        local r = 3.3 + lo * 1.2 + coned * 0.8
        K.ring(min(8, 1.5 + lo * 2 + coned * 2), x0 + 6.5, cy, r, 10)
        put(1.5 + lo * 3, x0 + 6, cy - 0.5, 2, 2)
      end
    end
    -- the lights overhead, their cones down to the floor, dust (HI)
    line(1, 18, 2, 110, 2)
    for k = 0, 3 do
      local x = 30 + k * 23
      local lv = 2 + amp * 3 + (k == (bars % 4) and 2 or 0)
      put(min(10, lv), x - 1, 3, 3, 2)
      local sw = sin(T * 0.5 + k * 1.7) * 6
      line(1, x - 1, 5, x - 10 + sw, 44); line(1, x + 1, 5, x + 10 + sw, 44)
    end
    K.grain(function(u, v) return 22 + u * 84, 6 + v * 34 end, 2 + hi * 14 + kl * 3, 3 + hi * 5)

    -- the floor: a lit pool, rings pumping out on the kick (LO)
    local pool = 1 + amp * 1.5 + coned * 0.8 + e * 0.4
    for y = floor(CYC - ry), floor(CYC + ry + 1) do
      local dy = (y - CYC) / (ry + 1)
      if abs(dy) < 1 then
        local hw = rx * sqrt(1 - dy * dy)
        local w = 1 - abs(dy)
        put(min(4, pool * (0.55 + 0.45 * w)), CXC - hw * 0.5, y, hw, 1)
        if y % 3 == 0 then K.dashes(1, y, 1, 4, y, CXC - hw, CXC - hw * 0.5); K.dashes(1, y, 1, 4, y, CXC + hw * 0.5, CXC + hw) end
      end
    end
    local rr = 0.4 + K.duck * 0.5 + lo * 0.3
    K.ring(min(5, 1 + lo * 1.5 + coned * 2), CXC, CYC + 1, rx * rr, 20, 0, TAU, ry / rx)
    K.ring(1 + mid * 0.8, CXC, CYC + 1, rx + 2, 24, 0, TAU, (ry + 1) / (rx + 2))

    -- the crowd: back half first, then the battlers, then the front half
    local function member(i)
      local Cm, m = CROWD[i], crowd[i]
      local jit = c > 0.4 and sin(T * 2.3 + i * 1.7) * (c - 0.4) * 4 or 0
      local x = CXC + cos(Cm.a) * (rx + 2) + jit
      local sa = sin(Cm.a)
      local y = CYC + sa * (ry + 1) + 1
      local s = 0.75 + 0.45 * (sa + 1) / 2
      if m.up_at >= 0 and K.T >= m.up_at then m.up = max(m.up, m.upv or 1); m.up_at = -1 end
      if m.hop_at and K.T >= m.hop_at then hop(m, 0.8); m.hop_at = nil end
      m.up = m.up * exp(-DT / 0.35)
      m.nod = m.nod * exp(-DT / 0.15)
      m.shout = m.shout * exp(-DT / 0.4)
      m.phone = (m.phone or 0) * exp(-DT / 1.0)
      m.flash = (m.flash or 0) * exp(-DT / 0.12)
      m.clap = (m.clap or 0) * exp(-DT / 0.25)
      local bob = (lo * 1.2 + K.duck * 0.8) * (1 - kl * 0.5) + m.nod
      local sway = sin(T * (0.9 + kl * 0.4) + Cm.s0 * 6) * (0.25 + kl * 0.4)
      local au = 0.5 + m.up * 2.4 + sway * 0.3
      local al, ar = au, au
      if m.clap > 0.1 then al, ar = 2.2, 2.2 end
      if m.phone > 0.1 then ar = max(ar, 2.6) end
      local lv = (sa > 0) and (1.5 + mid * 1.2) or (1.2 + mid * 1.2)
      lv = lv + m.up * 1.2 + e * 0.3
      local hx1, hy1, hx2, hy2 = fig(min(10, lv), x, y - m.h, s, bob * 0.35, al, ar, 0.7, sway, 0, false)
      if m.phone > 0.1 then put(min(12, 3 + m.phone * 7), hx2 - 0.5, hy2 - 1, 1, 2) end
      if m.flash > 0.1 then put(min(12, 4 + m.flash * 8), hx1 - 0.5, hy1 - 1, 2, 2) end
      if m.shout > 0.1 then
        local hy = y - m.h - s * 13
        local dir = x < CXC and 1 or -1
        local l = 2 + m.shout * 7
        for k = 1, 2 do
          local r = 2 + k * 2 + (1 - m.shout) * 4
          line(l * (1 - k * 0.25), x + dir * r, hy - 2, x + dir * (r + 1), hy + 2)
        end
      end
    end
    local function battler(i)
      local B = bat[i]
      B.on = K.follow(B.on or (i == act and 1 or 0), i == act and 1 or 0, 0.3, DT)
      B.swd = K.follow(B.swd or 0, B.sw, 0.07, DT)
      local on = B.on
      local x, y = B.x, CYC + 1 - B.h
      local air = clamp(B.h / 10, 0, 1)
      local cr = clamp(B.sq + (1 - on) * 0.15 + kl * 0.15, 0, 1) * (1 - air)
      local sw = B.swd * 1.7 + T * (0.8 + 1.7 * on)
      local al = 1.2 + sin(sw) * 0.9 + air * 1.2
      local ar = 1.2 - sin(sw) * 0.9 + air * 1.2
      if B.pt > 0.1 then ar = ar + (1.6 + B.pt * 0.4 - ar) * B.pt end
      al = al * on + (0.6 + sin(T * 0.8) * 0.15) * (1 - on)
      ar = ar * on + 0.6 * (1 - on)
      local lean = sin(sw * 0.5) * 0.4 * on + (B.x < CXC and -0.3 or 0.3) * (1 - on)
      if kl > 0.3 then lean = lean + sin(T * 1.1 + i) * kl * 0.4 end
      local l = 4.5 + 3 * on + amp * 2 + air * 2 + swap * 2
      if c > 0.3 then
        for g = 1, 2 do
          local gx = x + sin(T * 2 + g * 2) * c * 7 * (g == 1 and 1 or -1)
          fig((1 + c * 1.5) / g, gx, y + g * 0.5, 1.5, cr, al + 0.3 * g, ar - 0.3 * g, 0.9, lean, 0)
        end
      end
      fig(min(12, l), x, y, 1.55, cr, al, ar, 0.8 + air * 0.5, lean, B.kk, true)
      -- the shadow on the floor
      put(min(6, 1.5 + amp * 2 + (1 - air) * 1.5), x - 4 + air * 2, CYC + 2, 8 - air * 4, 1)
    end
    for i = 1, NC do if sin(CROWD[i].a) <= 0 then member(i) end end
    battler(3 - act)
    battler(act)
    for i = 1, NC do if sin(CROWD[i].a) > 0 then member(i) end end

    if kl > 0.05 then K.haze(0, 26, 128, 60, kl * 0.35, 1, T * 3) end
  end

  function M.draw(S)
    if K.view == 2 then draw2(S)
    elseif K.view == 3 then draw3(S)
    else draw1(S) end
  end

  M.init()
  return M
end
