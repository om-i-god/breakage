-- dubstep. view 1: a dripping concrete storm drain in one-point perspective, black water on its floor and a glow at the far end.
-- view 2: a storm over a city at night: lightning forks out of the cloud, rain sheets sweep the skyline, thunder rolls through.
-- view 3: the sound system under a railway arch: two stacks of bass bins and horns, an amp rack of meters between them, smoke, a crowd.
--
-- view 1: the sub kick heaves the black water (ripples run out across it)
-- and breathes the near rings of the pipe outward; the big snare lights the
-- whole tunnel (eased in, never a flash) and its light runs off down the
-- drain, coming back fainter at the echo time; the clap lights the walls;
-- the wobble stab makes the far glow pulse at the wobble rate; closed hats,
-- ticks and break slices drip from the ceiling (each drop rings the water),
-- an open hat starts a trickle running from a crack in the roof; metal
-- clanks a ring of the pipe; a ratchet is a run of drips; a fill throws a
-- train of light down the tunnel. each bar sends a surge of water rolling
-- out of the dark toward us, and over the phrase the far glow builds until
-- the phrase turns and a big surge comes through. AMP lights the concrete,
-- LO lifts the water, MID brightens the middle of the tunnel, HI glints on
-- the wet ceiling and the water. energy brightens and quickens it; chaos
-- bends the drain and ghosts a second branch beside it; kickless, the water
-- stills and mist fills it.
-- view 2: the snare forks lightning from the cloud to the rooftops (an eased
-- glow, it lights the cloud base and the roofs near it); the kick rolls
-- thunder through the clouds; open hats send sheets of rain across, closed
-- hats splash rings in the puddles on the street; the wobble pulses the
-- radio mast; perc lights windows; ticks flicker one. each bar lights the
-- cloud deck from inside with a slow, dim sheet glow; over the phrase the
-- ragged scud sinks lower over the towers and the turn of the phrase brings a
-- strike down on the mast. AMP lights the windows, LO the cloud base, MID
-- the roof edges and the mast, HI the rain. chaos splits the strikes into
-- many and crosses the rain; energy thickens the rain and the lights;
-- kickless, mist rolls between the towers.
-- view 3: the kick pushes every bass cone out and a pressure ring off the
-- stacks; the wobble flutters the cones at the wobble rate; the snare
-- swings a beam from behind the stacks through the smoke, the clap lights
-- the horns; closed hats shake dust off the cones, open hats hiss light
-- along the horn mouths; perc lights the rack, metal rattles it, toms and
-- congas thump single cones; ticks blink the rack's clip lamps; a ratchet
-- flutters the cones in a burst; a fill rolls pressure rings off the bins
-- one by one. the rack's four meters read AMP, LO, MID and HI; LO also sets
-- how far the cones swing, MID warms the smoke, HI the dust and the horn
-- mouths, AMP the arch. each bar the rack's bar lamps step on, the phrase
-- fills the smoke and lifts the crowd's hands toward its turn. energy packs
-- the crowd and brightens the smoke, chaos distorts the cones and jostles
-- the crowd, kickless stills the cones while the smoke rolls in and the
-- crowd's phone lights come up.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local floor, sin, cos, exp, max, min, abs = math.floor, math.sin, math.cos, math.exp, math.max,
    math.min, math.abs
  local TAU = K.TAU

  -- the phrase: 0..1 through it, smooth between bars (set in draw)
  local phr = 0

  ---------------------------------------------------------------- view 1
  local VX, VY = 64, 24               -- the vanishing point
  local F = 34                        -- focal scale
  local WY = 0.5                      -- the water surface (world y, down +)
  local WA = math.asin(WY)            -- where the water meets the wall
  local NR = 11
  local RZ = {}
  for k = 0, NR - 1 do RZ[k] = 0.62 * 1.33 ^ k end
  local WALLS = {3.6, 4.1, 4.7, 5.3, 5.9}   -- angles of the long joints

  local ripples, drips, pulses, emits, clank, surges, trickles
  local snt, snl, clf, wob, wph, shk, fillf, flare
  local MAXRIP, MAXDRIP = 12, 16
  local idle_t = 0

  ---------------------------------------------------------------- view 2
  local GY = 63
  local FAR = K.profile(function(x)
    local h = 12 + floor(K.hash(x // 8, 11) * 10)
    return 40 - h * 0.5
  end)
  local NEAR = K.profile(function(x)
    local b = x // 14
    local h = 10 + floor(K.hash(b, 21) * 16)
    if b == 5 then h = 30 end                       -- the tower with the mast
    if K.hash(b, 22) > 0.7 and x % 14 > 9 then h = h - 6 end
    return GY - 8 - h
  end)
  local MASTX = 5 * 14 + 7
  local forks, rolls, sheets, wins, puddles
  local flk, mast, sheet_t, sheet_l

  ---------------------------------------------------------------- view 3
  -- the bins: two stacks of 2 x 2, each a box with a cone
  local BINS = {}
  for s = 0, 1 do
    local x0 = s == 0 and 4 or 82
    for r = 0, 1 do
      for cc = 0, 1 do
        BINS[#BINS + 1] = {x = x0 + cc * 21, y = 20 + r * 15, w = 21, h = 15, st = s}
      end
    end
  end
  local NB = #BINS
  local HORNS = {{x = 6, y = 10, w = 38}, {x = 84, y = 10, w = 38}}
  local RX, RY, RW, RH3 = 50, 21, 28, 29      -- the amp rack
  local smoke, beam_s, hornf_s = 0, 0, 0
  local cone, prings, dust, beam, beam_a, hornf, rackf, clip, lamps
  local crowd                                -- fixed heads
  local CROWD_N = 16
  do
    crowd = {}
    for i = 1, CROWD_N do
      crowd[i] = {x = (i - 0.5) * 128 / CROWD_N + (K.hash(i, 301) - 0.5) * 5,
        h = 2.2 + K.hash(i, 302) * 1.4, ph = K.hash(i, 303), rank = K.hash(i, 304)}
    end
  end

  function M.init()
    ripples, drips, pulses, emits, clank, surges, trickles = {}, {}, {}, {}, {}, {}, {}
    for k = 0, NR - 1 do clank[k] = 0 end
    snt, snl, clf, wob, wph, shk, fillf, flare = 0, 0, 0, 0, 0, 0, 0, 0
    idle_t = 0
    forks, rolls, sheets, wins, puddles = {}, {}, {}, {}, {}
    flk, mast, sheet_t, sheet_l = 0, 0, 0, 0
    cone, prings, dust = {}, {}, {}
    for i = 1, NB do cone[i] = {ex = 0, kick = 0, thump = 0} end
    beam, beam_a, hornf, rackf, clip, lamps = 0, 0, 0, 0, {0, 0, 0, 0}, 0
    smoke, beam_s, hornf_s = 0, 0, 0
    phr = 0
  end
  M.clear = M.init

  -- world (x across, y down, z ahead) to screen, with the chaos bend
  local bend = 0
  local function proj(x, y, z)
    local s = F / z
    return VX + x * s + bend * z * z * 0.25, VY + y * s, s
  end

  ---------------------------------------------------------------- events
  local function ripple(x, z, v, rmax)
    if #ripples >= MAXRIP then table.remove(ripples, 1) end
    ripples[#ripples + 1] = {x = x, z = z, v = v, t0 = K.T, rmax = rmax or 1.2}
  end

  local function drip(v, k, a)
    if #drips >= MAXDRIP then table.remove(drips, 1) end
    k = k or (2 + floor(K.rnd() * 6))
    a = a or (1.5 * math.pi + (K.rnd() - 0.5) * 1.6)
    local z = RZ[clamp(k, 0, NR - 1)] * (0.9 + K.rnd() * 0.2)
    drips[#drips + 1] = {x = cos(a) * 0.97, y0 = sin(a) * 0.97, z = z, t0 = K.T, v = v}
  end

  local function pulse(lv, delay)
    if #pulses >= 8 then table.remove(pulses, 1) end
    pulses[#pulses + 1] = {t0 = K.T + (delay or 0), lv = lv}
  end

  local function surge(v)
    if #surges >= 3 then table.remove(surges, 1) end
    surges[#surges + 1] = {t0 = K.T, v = v}
  end

  -- (view 2) a lightning fork from the cloud down toward the rooftops
  local function fork(v, x)
    if #forks >= 5 then table.remove(forks, 1) end
    x = x or (10 + K.rnd() * 108)
    local pts = {x, 10 + K.rnd() * 4}
    local px, py = pts[1], pts[2]
    local ground = K.at(NEAR, x) + 1
    local br = {}
    while py < ground and #pts < 24 do
      px = px + (K.rnd() - 0.5) * 9
      py = py + 3 + K.rnd() * 4
      if py > ground then py = ground end
      pts[#pts + 1] = px; pts[#pts + 1] = py
      if #br < 2 and K.rnd() < 0.25 + K.chaos * 0.3 then
        local bx, by = px, py
        local b = {bx, by}
        for _ = 1, 3 do
          bx = bx + (K.rnd() < 0.5 and -1 or 1) * (2 + K.rnd() * 4)
          by = by + 2 + K.rnd() * 3
          b[#b + 1] = bx; b[#b + 1] = by
        end
        br[#br + 1] = b
      end
    end
    forks[#forks + 1] = {pts = pts, br = br, x = x, t0 = K.T, v = v, b = 0}
  end

  -- (view 3) a pressure ring off a bin
  local function pring(i, v, delay)
    if #prings >= 10 then table.remove(prings, 1) end
    prings[#prings + 1] = {i = i, v = v, t0 = K.T + (delay or 0)}
  end
  local function dusty(i, v, n)
    local B3 = BINS[i]
    for _ = 1, n do
      if #dust >= 24 then table.remove(dust, 1) end
      local a = K.rnd() * TAU
      local r = 3 + K.rnd() * 5
      dust[#dust + 1] = {x = B3.x + B3.w / 2 + cos(a) * r, y = B3.y + B3.h / 2 + sin(a) * r,
        vx = cos(a) * (6 + K.rnd() * 10), vy = sin(a) * 6 - 8 - K.rnd() * 8, t0 = K.T, v = v}
    end
  end

  function M.kick(v)
    v = K.num(v, 1)
    ripple(K.chaos * (K.rnd() - 0.5), 1.6 + K.rnd() * 0.8, v, 1.4)
    shk = max(shk, 0.5 + 0.5 * v)
    if #rolls >= 4 then table.remove(rolls, 1) end
    rolls[#rolls + 1] = {t0 = K.T, x = K.rnd() * 128, dir = K.rnd() < 0.5 and -1 or 1, v = v}
    for i = 1, NB do cone[i].kick = max(cone[i].kick, v) end
    pring(K.rnd() < 0.5 and 1 or 5, v)
  end

  function M.snare(v)
    v = K.num(v, 1)
    snt = max(snt, 0.6 + 0.4 * v)
    pulse(0.7 + 0.3 * v)
    if #emits >= 4 then table.remove(emits, 1) end
    emits[#emits + 1] = {lv = 0.7 * v, next = K.NOW + K.echo_t, n = 0}
    local n = 1 + floor(K.chaos * 2.5 + 0.2)
    for i = 1, n do fork(v * (i == 1 and 1 or 0.6)) end
    beam = max(beam, 0.6 + 0.4 * v)
    beam_a = (K.rnd() - 0.5) * 1.2
  end

  function M.clap(v)
    v = K.num(v, 1)
    clf = max(clf, 0.5 + 0.5 * v)
    flk = max(flk, 0.6 * v)
    hornf = max(hornf, 0.5 + 0.5 * v)
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    if open then
      -- a trickle runs from a crack in the roof for a moment
      if #trickles >= 3 then table.remove(trickles, 1) end
      trickles[#trickles + 1] = {a = 1.5 * math.pi + (K.rnd() - 0.5) * 1.4, k = 1 + floor(K.rnd() * 5),
        t0 = K.T, dur = 0.35 + 0.3 * v, acc = 0}
      if #sheets >= 5 then table.remove(sheets, 1) end
      sheets[#sheets + 1] = {t0 = K.T, x = K.rnd() * 128, v = v, w = 40}
      sheet_t = max(sheet_t, 0.6 * v)
      hornf = max(hornf, 0.35 * v)
    else
      drip(0.5 + 0.5 * v)
      if #puddles >= 8 then table.remove(puddles, 1) end
      puddles[#puddles + 1] = {x = 4 + K.rnd() * 120, y = GY - 4 + K.rnd() * 3, t0 = K.T, v = v}
      dusty(1 + floor(K.rnd() * NB), v, 2)
    end
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 14 then
      wob = max(wob, 0.6 + 0.4 * v)
      mast = max(mast, 0.5 + 0.5 * v)
    elseif kind == 6 or kind == 3 then
      local k = 1 + floor(K.rnd() * 6)
      clank[k] = max(clank[k], 0.6 + 0.4 * v)
      rackf = max(rackf, 0.8 * v)
    elseif kind == 13 or kind == 17 or kind == 1 then
      ripple((K.rnd() - 0.5) * 0.8, 2.5 + K.rnd() * 3, 0.6 * v, 0.9)
      local i = 1 + floor(K.rnd() * NB)
      cone[i].thump = max(cone[i].thump, v)
    else
      drip(0.6 * v)
      rackf = max(rackf, 0.5 * v)
    end
    if #wins >= 8 then table.remove(wins, 1) end
    wins[#wins + 1] = {x = floor(K.rnd() * 60) * 2 + 4, t0 = K.T, v = v, r = K.rnd()}
  end
  function M.tom(v) M.perc(13, v) end

  function M.tick(kind)
    drip(0.4); flk = max(flk, 0.3)
    local k = 1 + floor(K.rnd() * 4)
    clip[k] = 1
  end
  function M.brk(s, n)
    s, n = K.num(s, 1), max(1, K.num(n, 8))
    drip(0.5, 1 + floor((s - 1) / n * 8))
    local i = 1 + floor((s - 1) / n * NB) % NB
    cone[i].thump = max(cone[i].thump, 0.5)
  end
  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    for i = 1, min(n, 6) do drip(0.8, 1 + i) end
    for i = 0, min(n, 4) - 1 do pulse(0.6 - i * 0.1, i * 0.07) end
    snt = max(snt, 0.5)
    for i = 1, NB do cone[i].thump = max(cone[i].thump, 0.4 + n * 0.06) end
    for i = 0, min(n, 6) - 1 do pring(1 + (i * 3) % NB, 0.6, i * 0.06) end
  end
  function M.fill()
    fillf = 1
    for i = 0, 3 do pulse(0.8 - i * 0.15, i * 0.12) end
    fork(1, 64)
    surge(0.8)
    for i = 1, NB do pring(i, 0.8, (i - 1) * 0.08) end
  end

  function M.bar(S)
    local pl = max(1, floor(K.num(S and S.phrase_len, 16)))
    local pp = floor(K.num(S and S.phrase_pos, 1)) % pl
    local turn = pp == 0
    surge(turn and 1 or 0.45)
    sheet_l = max(sheet_l, turn and 0.9 or 0.45)
    if turn then
      flare = 1
      fork(0.9, MASTX)
    end
    lamps = (lamps + 1) % 9
  end

  ---------------------------------------------------------------- view 1 drawing
  local function fog(z) return exp(-z / (6 + 4 * K.energy - 2.5 * K.kickless)) end

  local function draw1(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]
    bend = c * 0.9 * sin(T * 0.25)
    -- the drain drips on its own, a slow irregular drip
    if T >= idle_t then
      drip(0.35 + 0.2 * K.rnd())
      idle_t = T + 0.6 + K.rnd() * 1.4
    end
    -- the trickles: drips from one crack, on time
    for i = #trickles, 1, -1 do
      local Tr = trickles[i]
      local age = T - Tr.t0
      if age > Tr.dur then table.remove(trickles, i)
      else
        Tr.acc = Tr.acc + K.DTS
        while Tr.acc >= 0.06 do
          Tr.acc = Tr.acc - 0.06
          drip(0.55, Tr.k, Tr.a)
        end
      end
    end
    -- the echoes of the snare light, at the echo time
    for i = #emits, 1, -1 do
      local em = emits[i]
      if K.NOW >= em.next then
        em.lv = em.lv * K.echo_fb
        em.n = em.n + 1
        if em.lv > 0.12 then pulse(em.lv) end
        em.next = em.next + K.echo_t
      end
      if em.lv <= 0.12 or em.n > 6 then table.remove(emits, i) end
    end
    local glow = 0.35 + 0.25 * amp + 0.15 * e + kl * 0.25 + phr * 0.35 + flare * 0.6
      + wob * (0.5 + 0.5 * sin(wph)) * 1.1
    local heave = lo * 1.2 + shk * 0.5
    local sy = floor(shk * 1.3 + 0.3)                       -- the lip's shudder, px

    -- the far end: an outfall glow beyond the last ring
    local fx, fy = proj(0, 0, RZ[NR - 1] * 1.2)
    K.disc(min(12, 2 + glow * 7), fx, fy, 1.5 + glow * 1.5)
    K.ring(min(8, 1 + glow * 4), fx, fy, 4 + glow * 3, 12)
    if glow > 0.6 then K.ring(min(5, glow * 2), fx, fy, 8 + glow * 4, 14) end
    -- its light on the far air: slow rays turning (MID)
    for k = 0, 5 do
      local a = k * TAU / 6 + T * 0.12
      local r0 = 6 + glow * 4
      local r1 = r0 + 4 + glow * 6 + mid * 6
      line(min(4, (0.6 + mid * 1.6 + glow * 0.6) * (0.6 + 0.4 * sin(T * 0.7 + k * 1.7))),
        fx + cos(a) * r0, fy + sin(a) * r0 * 0.7, fx + cos(a) * r1, fy + sin(a) * r1 * 0.7)
    end

    -- the rings of the pipe, nearest first; lit by the snare, its echoes,
    -- the wobble glow (far ones), the mids (middle ones) and the clanks;
    -- the near ones breathe out with the sub
    for k = 0, NR - 1 do
      local z = RZ[k]
      local cx, cy, s = proj(0, 0, z)
      local f = fog(z)
      local lv = (0.8 + 1.2 * f) * (0.7 + 0.6 * amp + 0.3 * e)
      lv = lv + snl * 3 * (0.3 + 0.7 * f)
      for p = 1, #pulses do
        local P = pulses[p]
        local age = K.T - P.t0
        if age >= 0 then
          local zp = 0.5 + age * 7
          local d = abs(z - zp) / (0.4 + zp * 0.25)
          if d < 1 then lv = lv + P.lv * 3 * (1 - d) * (0.4 + 0.6 * f) end
        end
      end
      if k >= 3 and k <= 7 then lv = lv + mid * 2.5 * f end
      lv = lv + glow * 3 * (1 - f) * (k / NR)
      lv = lv + clank[k] * 5
      lv = min(12, lv)
      local yy = cy + (k == 0 and sy or 0)
      K.ring(lv, cx, yy, s, k < 3 and 22 or 14, math.pi - WA, TAU + WA)
      if k == 0 then K.ring(lv * 0.7, cx, yy, s - 3, 22, math.pi - WA + 0.05, TAU + WA - 0.05) end
      -- its reflection in the black water: the wall feet, wobbling
      local wl = cy + WY * s
      local wo = sin(T * 2.1 + k * 1.3) * (0.4 + heave * 1.5) * min(1, s / 12)
      for side = -1, 1, 2 do
        local x0 = cx + side * cos(WA) * s
        local x1 = cx + side * cos(WA + 0.45) * s
        local y1 = wl + s * 0.22
        line(lv * 0.35, x0 + wo, wl + 1, x1 + wo, y1)
      end
    end

    -- the long joints down the pipe walls, and the stains running down them
    local nearz, farz = RZ[1], RZ[NR - 1]
    for i = 1, #WALLS do
      local a = WALLS[i]
      local xa, ya = proj(cos(a), sin(a), nearz)
      local xb, yb = proj(cos(a), sin(a), farz)
      line(1 + clf * 4 + amp * 0.8, xa, ya, xb, yb)
    end
    for i = 1, #trickles do
      local Tr = trickles[i]
      local u = (T - Tr.t0) / Tr.dur
      local z = RZ[clamp(Tr.k, 0, NR - 1)]
      local xa, ya = proj(cos(Tr.a) * 0.97, sin(Tr.a) * 0.97, z)
      put(min(10, 3 + 6 * (1 - u) + hi * 2), xa - 1, ya, 3, 1)
    end

    -- the water: its edges along the walls, heaving with the sub
    local hv = floor(heave * 1.5 * sin(T * 3.1) + 0.5)
    for side = -1, 1, 2 do
      local xa, ya = proj(side * cos(WA), WY, RZ[0])
      local xb, yb = proj(side * cos(WA), WY, farz)
      line(1.5 + lo * 2 + e, xa, ya + hv, xb, yb)
    end
    -- the surges: a swell rolling out of the dark toward us
    for i = #surges, 1, -1 do
      local Sg = surges[i]
      local age = T - Sg.t0
      local z = farz - age * 9
      if z < RZ[0] then table.remove(surges, i)
      elseif age >= 0 then
        local f = fog(z)
        local w = cos(WA) - 0.03
        local xa, ya = proj(-w, WY, z)
        local xb, yb = proj(w, WY, z)
        local lv = (2 + 6 * Sg.v) * (0.3 + 0.7 * f) * (1 - kl * 0.5) * min(1, age * 4)
        line(lv, xa, ya + hv, xb, yb + hv)
        local xc, yc = proj(-w, WY, z + 0.5)
        local xd, yd = proj(w, WY, z + 0.5)
        line(lv * 0.4, xc, yc + hv, xd, yd + hv)
      end
    end
    -- the far glow's reflection: a broken column of light on the water
    local _, wy0 = proj(0, WY, farz)
    for y = floor(wy0) + 1, 63, 2 do
      local u = (y - wy0) / (63 - wy0)
      local w = 1 + u * (3 + glow * 6)
      local dx = sin(y * 0.6 + T * 2.3) * (0.5 + heave * 2 + u * 2)
      local lv = (glow * 4 + hi * 2.5) * (1 - u * 0.6) * (0.6 + 0.4 * sin(y * 1.3 - T * 4))
      if lv > 0.6 then put(min(9, lv), VX + bend * 0.5 + dx - w / 2, y + hv, w, 1) end
    end
    -- glints on the water (HI)
    for i = 0, 9 do
      local z = 1 + K.hash(i, 5) * 6
      local x = (K.hash(i, 6) - 0.5) * 1.4
      local px, py = proj(x, WY, z)
      local tw = 0.5 + 0.5 * sin(T * (2 + K.hash(i, 7) * 3) + i * 2)
      put(tw * (1 + hi * 6), px, py + hv, 2, 1)
    end

    -- ripples spreading over the water
    for i = #ripples, 1, -1 do
      local R = ripples[i]
      local age = K.T - R.t0
      local life = 1.6 * (1 - kl * 0.4)
      if age > life then table.remove(ripples, i)
      elseif age >= 0 then
        local u = age / life
        local rr = 0.05 + R.rmax * (1 - (1 - u) ^ 2)
        local lv = (2 + 6 * R.v) * (1 - u) * (1 - kl * 0.5) * fog(R.z * 0.6)
        local px, py, pok
        for j = 0, 16 do
          local a = TAU * j / 16
          local x, z = R.x + cos(a) * rr, R.z + sin(a) * rr
          local ok = abs(x) < cos(WA) - 0.02 and z > 0.7
          local sx, syy = proj(x, WY, max(0.7, z))
          if px and ok and pok then line(lv, px, py + hv, sx, syy + hv) end
          px, py, pok = sx, syy, ok
        end
      end
    end

    -- drips: fall from the ceiling, ring the water where they land
    for i = #drips, 1, -1 do
      local D = drips[i]
      local age = K.T - D.t0
      local y = D.y0 + 0.5 * 9 * age * age
      if y >= WY then
        ripple(D.x * 0.85, D.z, D.v * 0.6, 0.35)
        table.remove(drips, i)
      else
        local x, sy2, s = proj(D.x, y, D.z)
        local f = fog(D.z)
        put(min(11, (3 + 6 * D.v + hi * 2) * (0.5 + 0.5 * f)), x, sy2, 1, s > 20 and 3 or 2)
      end
    end

    -- the branch: chaos ghosts a second drain off to one side
    if c > 0.35 then
      local cl = (c - 0.35) / 0.65
      local off = 34 * (sin(T * 0.13) > 0 and 1 or -1)
      for k = 3, NR - 1, 2 do
        local cx, cy, s = proj(0, 0, RZ[k])
        K.ring((1 + 2 * fog(RZ[k])) * cl, cx + off * fog(RZ[k] * 0.5), cy, s * 0.6, 10, math.pi - WA, TAU + WA)
      end
    end

    -- the hanging weed at the pipe's lip, swinging with the sub
    for i = 0, 6 do
      local x = 6 + i * 19 + floor(K.hash(i, 9) * 8)
      local len = 3 + floor(K.hash(i, 10) * 6)
      local sw = sin(T * 0.9 + i) * (0.5 + lo * 1.5)
      line(1.5 + amp, x, 0, x + sw, len)
      if K.hash(i, 11) > 0.5 then put(2 + hi * 4 + K.env.hat * 4, x + sw, len + 1, 1, 1) end
    end

    -- mist, and the drain's wet air glinting (HI)
    K.haze(16, 6, 112, 40, 0.1 + 0.45 * kl + 0.1 * e + 0.1 * phr, 1, T * 4)
    K.grain(function(u, v) return 24 + u * 80, 2 + v * 20 end, 2 + hi * 14 + e * 3, 2 + hi * 5)
  end

  ---------------------------------------------------------------- view 2 drawing
  local function draw2(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]

    -- lightning strength (eased in and out)
    local bolt, bx = 0, 64
    for i = #forks, 1, -1 do
      local Fk = forks[i]
      local age = K.T - Fk.t0
      local to = age < 0.08 and Fk.v or Fk.v * exp(-(age - 0.08) / 0.3)
      Fk.b = K.follow(Fk.b, to, 0.07, DT)
      if age > 1.6 then table.remove(forks, i)
      elseif Fk.b > bolt then bolt, bx = Fk.b, Fk.x end
    end

    -- thunder rolling along the clouds on the kick
    for i = #rolls, 1, -1 do
      local R = rolls[i]
      local age = K.T - R.t0
      if age > 1.4 then table.remove(rolls, i)
      else
        R.cx = R.x + R.dir * age * 55
        R.b = sin(math.pi * min(1, age / 1.4)) * R.v * (1 - kl * 0.6)
        R.w = 14 + age * 14
      end
    end
    -- the cloud deck: solid banks hanging over the city, drifting; their
    -- underside lit by the city (LO), by the strikes and the thunder; it
    -- sinks over the phrase, and the bar's sheet glow lights it inside
    local sink = phr * 2.5
    local inner = sheet_l * 1.6 + sheet_t
    for col = 0, 63 do
      local x = col * 2
      local cb = 8 + 4 * sin(x * 0.045 + T * 0.12) + 2.5 * sin(x * 0.11 - T * 0.2)
      if c > 0.3 and sin(x * 0.21 + T * 0.15) > 1.3 - c then cb = cb - 5 * c end   -- torn
      cb = floor(cb + 0.5)
      local lit = bolt * max(0, 1 - abs(x - bx) / (24 + bolt * 20))
      for r = 1, #rolls do
        local R = rolls[r]
        if R.b and R.b > 0 then lit = lit + R.b * 0.6 * max(0, 1 - abs(x - R.cx) / R.w) end
      end
      local body = 1 + lit * 2.5 + inner * (0.6 + 0.4 * sin(x * 0.09 + T * 0.4))
      if cb > 1 then
        put(body, x + col % 2 * 0, 0, 1, max(1, cb - 3))
        put(body + 0.4 + lo * 0.6, x, max(0, cb - 3), 2, min(cb, 3))
      end
      put(min(10, 1 + lo * 1.5 + e * 0.5 + lit * 5 + inner * 0.4), x, cb, 2, 1)
      -- a ragged lower scud layer, faster
      local sb = 15 + sink + 3 * sin(x * 0.07 + T * 0.35) + 2 * sin(x * 0.19 - T * 0.5)
      if sb > 15.5 + sink then put(1 + lo * 0.8 + lit * 2, x, floor(sb), 2, 1) end
    end

    -- the far skyline: outlines in the rain
    for col = 0, 63 do
      local top = FAR[col]
      if top < NEAR[col] - 1 then put(1 + mid * 1.2, col * 2, top, 2, 1) end
    end
    -- the near skyline: black towers, their roof edges caught by the
    -- lightning and the mids, windows lit by the level (AMP)
    for col = 0, 63 do
      local x = col * 2
      local top = NEAR[col]
      local near = bolt * max(0, 1 - abs(x - bx) / 40)
      put(min(11, 1.2 + mid * 1.8 + near * 8), x, top, 2, 1)
      local nx = NEAR[min(63, col + 1)]
      if nx ~= top then line(1.2 + mid * 1.8 + near * 5, x + 1.5, top, x + 1.5, nx) end
    end
    for b = 0, 9 do
      if K.hash(b, 23) < 0.3 then
        local x0 = b * 14
        for col = x0 // 2, min(63, (x0 + 13) // 2) do
          local top = NEAR[col]
          put(1, col * 2, top + 1, 2, GY - 8 - top)
        end
      end
    end
    -- the windows: how many are lit follows the level (AMP)
    local wl = 0.25 + 0.4 * amp + 0.25 * e
    for b = 0, 9 do
      local x0 = b * 14
      local top = NEAR[min(63, (x0 + 4) // 2)]
      for r = 0, 4 do
        local y = top + 4 + r * 5
        if y < GY - 9 then
          for cc = 0, 2 do
            local h = K.hash(b * 31 + r * 5 + cc, 41)
            if h < wl then
              local lv = 1 + 1.3 * K.hash(b + r * 7 + cc, 42) + amp * 1.5
              put(lv, x0 + 3 + cc * 4, y, 1, 1)
            end
          end
        end
      end
    end
    -- windows the perc switch on, and one that flickers on the ticks
    for i = #wins, 1, -1 do
      local W = wins[i]
      local age = K.T - W.t0
      if age > 0.9 then table.remove(wins, i)
      else
        local top = K.at(NEAR, W.x)
        local y = floor(top + 4 + W.r * (GY - 14 - top))
        put(min(11, 2 + 8 * W.v * sin(math.pi * min(1, age / 0.9))), W.x, y, 2, 1)
      end
    end
    put(min(10, 1 + flk * 8), 33, 46, 2, 1)

    -- the radio mast on the tall tower: its lamps pulse with the wobble
    local mtop = NEAR[MASTX // 2]
    line(1.5 + mid, MASTX, mtop, MASTX, mtop - 10)
    line(1, MASTX - 3, mtop, MASTX, mtop - 7); line(1, MASTX + 3, mtop, MASTX, mtop - 7)
    local mp = 0.3 + 0.2 * sin(T * 1.2) + mast * (0.5 + 0.5 * sin(wph)) + mid * 0.4
    put(min(12, 2 + mp * 9), MASTX - 1, mtop - 11, 3, 1)
    put(min(9, 1 + mp * 6), MASTX, mtop - 5, 1, 1)

    -- the lightning itself
    for i = 1, #forks do
      local Fk = forks[i]
      if Fk.b > 0.05 then
        local P = Fk.pts
        local lv = min(12, 2 + Fk.b * 10)
        for j = 1, #P - 3, 2 do
          line(lv, P[j], P[j + 1] + sink * 0.5, P[j + 2], P[j + 3])
          line(lv * 0.5, P[j] + 1, P[j + 1] + sink * 0.5, P[j + 2] + 1, P[j + 3])
        end
        for _, b in ipairs(Fk.br) do
          for j = 1, #b - 3, 2 do line(lv * 0.55, b[j], b[j + 1], b[j + 2], b[j + 3]) end
        end
        -- the strike's reflection in the wet street
        local gx = P[#P - 1]
        line(lv * 0.4, gx, GY - 6, gx + 1, GY)
      end
    end

    -- rain: a steady fall, sheets sweeping across on the open hats (HI)
    local slant = 0.35 + 0.3 * sin(T * 0.1)
    local n = 22 + floor(e * 14 + kl * 10)
    for i = 0, n - 1 do
      local sp = 70 + K.hash(i, 51) * 30
      local x0 = K.hash(i, 52) * 150 - 10
      local y = (K.hash(i, 53) * 80 + T * sp) % 80 - 10
      local x = x0 + y * slant
      local sl = 0.8 + hi * 1.4
      for s = 1, #sheets do
        local Sh = sheets[s]
        local age = K.T - Sh.t0
        local cxs = Sh.x + age * 60 - 20
        local d = abs(x - cxs)
        if d < Sh.w and age < 1 then sl = sl + 3 * Sh.v * (1 - d / Sh.w) * (1 - age) end
      end
      line(min(8, sl * (1 - kl * 0.3)), x, y, x + 3 * slant, y + 3)
      if c > 0.5 and i % 3 == 0 then line(sl * 0.6, x + 20, y, x + 20 - 3 * slant, y + 3) end
    end
    for s = #sheets, 1, -1 do if K.T - sheets[s].t0 > 1 then table.remove(sheets, s) end end

    -- the wet street: reflections of the windows, rain rings
    for i = 0, 11 do
      local x = floor(K.hash(i, 61) * 124)
      local y = GY - 5 + floor(K.hash(i, 62) * 5)
      local tw = 0.5 + 0.5 * sin(T * (1.5 + K.hash(i, 63) * 3) + i)
      put((0.8 + tw) * (0.7 + amp * 1.2 + hi * 0.8), x, y, 2 + floor(K.hash(i, 64) * 3), 1)
    end
    -- the closed hats splash rings in the puddles
    for i = #puddles, 1, -1 do
      local P = puddles[i]
      local u = (T - P.t0) / 0.6
      if u >= 1 then table.remove(puddles, i)
      else
        local r = 1 + u * 5
        local l = (2 + 6 * P.v) * (1 - u)
        put(l, P.x - r, P.y, 2, 1)
        put(l, P.x + r - 1, P.y, 2, 1)
        if u < 0.4 then put(l * 1.2, P.x, P.y - 1 - floor(u * 6), 1, 1) end
      end
    end

    if kl > 0.05 then K.haze(0, 24, 128, 56, 0.32 * kl, 1, T * 3) end
    K.grain(function(u, v) return u * 128, GY - 6 + v * 6 end, 2 + hi * 12 + e * 3, 2 + hi * 4)
  end

  ---------------------------------------------------------------- view 3 drawing
  local function draw3(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]
    local still = 1 - kl * 0.75
    -- the structure is line art, kept dim (the kick shake moves all of it):
    -- the hits and the lamps carry the bright levels
    local G = 0.55

    -- the arch: brick courses of a railway arch overhead, lit by the level,
    -- the beam and the smoke
    local archl = (1 + amp * 0.6 + beam_s * 1.2 + e * 0.3) * G
    K.ring(archl, 64, 70, 70, 28, math.pi * 1.03, math.pi * 1.97, 0.95)
    K.ring(archl * 0.6, 64, 70, 64, 26, math.pi * 1.05, math.pi * 1.95, 0.95)
    for k = 0, 13 do
      local a = math.pi * (1.06 + k * 0.064)
      local ca, sa = cos(a), sin(a) * 0.95
      line(archl * 0.5, 64 + ca * 64, 70 + sa * 64, 64 + ca * 70, 70 + sa * 70)
    end

    -- the smoke: banks rolling through, thicker with the phrase and kickless,
    -- warmed by the mids
    smoke = K.follow(smoke, 0.25 * kl + 0.05 * phr + 0.04 * mid + 0.04 * beam_s, 0.6, DT)
    K.haze(0, 2, 128, 36, smoke, 1, T * (5 + e * 4))

    -- the beam: swung from behind the rack through the smoke on the snare
    if beam_s > 0.04 then
      local a0 = -math.pi / 2 + beam_a * (0.4 + 0.6 * beam_s) + sin(T * 0.6) * 0.15
      for j = -2, 2 do
        local a = a0 + j * 0.06
        local l = min(9, beam_s * (5 - abs(j) * 1.6) + mid)
        if l > 0.5 then line(l, 64, 24, 64 + cos(a) * 70, 24 + sin(a) * 70) end
      end
    end

    -- the horns on the stacks: their mouths hiss with HI and the open hats
    for h = 1, 2 do
      local H = HORNS[h]
      local x, y, w = H.x, H.y, H.w
      local hl = (1.2 + hornf_s * 4 + hi * 1.6 + amp * 0.6) * G
      -- (the long edges stay dim: the kick shake moves them)
      line(1.2, x, y, x + w - 1, y)
      line(1, x, y + 8, x + w - 1, y + 8)
      line(hl * 0.8, x, y, x, y + 8)
      line(hl * 0.8, x + w - 1, y, x + w - 1, y + 8)
      for m = 0, 1 do
        local mx = x + 3 + m * 18
        -- the flare: two lines to a throat, the mouth lit from inside
        line(hl * 0.7, mx, y + 2, mx + 6, y + 4)
        line(hl * 0.7, mx, y + 6, mx + 6, y + 4)
        line(hl * 0.7, mx + 15, y + 2, mx + 9, y + 4)
        line(hl * 0.7, mx + 15, y + 6, mx + 9, y + 4)
        local ml = (1 + hi * 3 + hornf_s * 5) * (0.7 + 0.3 * sin(T * 9 + m * 2 + h))
        put(min(11, ml), mx + 6, y + 4, 4, 1)
      end
    end

    -- the bins: each a box, a surround, a cone, a dust cap; the cone swings
    -- with the sub, the wobble and the kick
    local wobv = wob * sin(wph)
    for i = 1, NB do
      local B3, C3 = BINS[i], cone[i]
      C3.kick = C3.kick * exp(-DT / 0.12)
      C3.thump = C3.thump * exp(-DT / 0.1)
      local to = (C3.kick * 1.4 + C3.thump * 1.1 + lo * 0.9 * (0.6 + 0.4 * sin(T * 11 + i))
        + wobv * 1.2) * still
      C3.ex = K.follow(C3.ex, to * 0.8, 0.09, DT)
      local x, y, w, h = B3.x, B3.y, B3.w, B3.h
      local cx, cy = x + w / 2, y + h / 2
      local bl = (1.2 + amp * 0.8 + max(0, C3.ex) * 0.6) * G
      line(1.2, x, y, x + w - 1, y)
      line(bl, x, y, x, y + h - 1)
      line(bl * 0.8, x + w - 1, y, x + w - 1, y + h - 1)
      -- the corner bolts
      put(1.5 + hi * 2, x + 2, y + 2, 1, 1); put(1.5 + hi * 2, x + w - 3, y + h - 3, 1, 1)
      local ex = C3.ex
      local jit = c * 1.2
      local sl = min(8, 1.6 + abs(ex) * 1.6 + lo * 1.2) * G
      K.ring(sl * 0.5, cx, cy, 6.6, 16, 0, TAU, 1, jit * 0.5, i)
      K.ring(min(8, sl + ex * 0.6), cx, cy, 4.7 + ex * 0.8, 14, 0, TAU, 1, jit, i + 9)
      K.ring(sl * 0.5, cx, cy, 2.6 + ex * 0.3, 10)
      K.disc(min(9, 1.2 + max(0, ex) * 2 + C3.thump * 3), cx, cy, 1.6 + max(0, ex) * 0.4)
    end

    -- pressure rings off the bins (kick, ratchet, fill)
    for i = #prings, 1, -1 do
      local P = prings[i]
      local age = T - P.t0
      if age > 0.7 then table.remove(prings, i)
      elseif age >= 0 then
        local u = age / 0.7
        local B3 = BINS[P.i]
        local cx = B3.st == 0 and 46 or 82
        local r = 10 + u * 50
        local l = (1 + 3 * P.v) * (1 - u) * still * min(1, age / 0.1)
        local a0 = B3.st == 0 and -0.9 or math.pi - 0.9
        K.ring(l, cx, B3.y + B3.h, r, 10, a0, a0 + 1.8, 0.6)
      end
    end

    -- the amp rack: four meters (AMP, LO, MID, HI), clip lamps, bar lamps
    local rx, ry = RX, RY
    local rl = (1.2 + rackf * 3) * G
    line(rl, rx, ry, rx + RW - 1, ry)
    line(rl, rx, ry, rx, ry + RH3 - 1)
    line(rl, rx + RW - 1, ry, rx + RW - 1, ry + RH3 - 1)
    local bands = {amp, lo, mid, hi}
    for b = 1, 4 do
      local my = ry + 3 + (b - 1) * 6
      line(1, rx + 2, my + 3, rx + RW - 3, my + 3)
      local n = floor(clamp(bands[b], 0, 1) * 9 + 0.5)
      for s = 0, 8 do
        local on = s < n
        local l = on and (1.6 + s * 0.45 + rackf * 1.5) or 1
        if on or s % 2 == 0 then put(min(11, l), rx + 3 + s * 2, my + 1, 1, 2) end
      end
      clip[b] = clip[b] * exp(-DT / 0.15)
      put(min(11, 1 + clip[b] * 9 + (n >= 9 and 3 or 0)), rx + RW - 5, my + 1, 2, 2)
    end
    -- the bar lamps: one more lights each bar, over two bars of the phrase
    for k = 0, 7 do
      local on = k < lamps
      put(on and (2 + phr * 3) or 1, rx + 3 + k * 3, ry + RH3 - 6, 2, 1)
    end
    put(1.5 + rackf * 4, rx + 3, ry + RH3 - 3, RW - 6, 1)

    -- dust shaken off the cones (closed hats)
    for i = #dust, 1, -1 do
      local D = dust[i]
      local age = T - D.t0
      if age > 0.8 then table.remove(dust, i)
      else
        D.x, D.y = D.x + D.vx * DT, D.y + D.vy * DT
        D.vy = D.vy + 30 * DT
        put((3 + 5 * D.v + hi * 2) * (1 - age / 0.8), D.x, D.y, 1, 1)
      end
    end

    -- the floor and the crowd: heads and shoulders rimmed by the stacks'
    -- light, bobbing on the beat; hands go up toward the turn of the phrase
    for k = 0, 1 do
      K.dashes(1, 60 + k * 3, 2 + k, 6 - k, T * (1 + k) * (1 + lo) + k * 3)
    end
    local nshow = 8 + floor(e * 8)
    for i = 1, CROWD_N do
      local P = crowd[i]
      if P.rank * 16 < nshow then
        local ph = (K.beat_ph + P.ph * 0.15) % 1
        local by = (ph < 0.5 and sin(ph * TAU) or 0) * (1 + lo * 0.8) * still
        local jx = c > 0.4 and sin(T * (5 + P.ph * 4) + i) * c * 1.5 or 0
        local x = P.x + jx
        local hy = 55 - P.h + by
        local rim = (1 + amp * 0.8 + beam_s * 1.5 + e * 0.4) * G
        K.ring(rim, x, hy, P.h, 8, math.pi, TAU)
        line(rim * 0.6, x - P.h * 2.2, hy + P.h + 3, x - P.h * 0.8, hy + P.h + 1)
        line(rim * 0.6, x + P.h * 0.8, hy + P.h + 1, x + P.h * 2.2, hy + P.h + 3)
        local up = phr * 1.2 + e * 0.4 - P.rank
        if up > 0.2 then
          local ah = 4 + up * 4
          local s = (i % 2 == 0) and 1 or -1
          line(rim * 0.8, x + s * P.h * 1.6, hy + P.h + 2, x + s * (P.h * 2 + 1), hy - ah + by)
        end
        -- a phone held up in the dark
        if kl > 0.3 and K.hash(i, 305) < 0.55 then
          put(1 + kl * 4 * (0.6 + 0.4 * sin(T * 0.8 + i)), x + 3, hy - 6 - P.h, 1, 2)
        end
      end
    end
    K.grain(function(u, v) return 4 + u * 120, 4 + v * 48 end, 2 + hi * 10 + e * 3, 2 + hi * 4)
  end

  function M.draw(S)
    local DT = K.DT
    snt = snt * exp(-DT / 0.3)
    snl = K.follow(snl, snt, 0.1, DT)
    clf = clf * exp(-DT / 0.2)
    wob = wob * exp(-DT / 0.7)
    wph = (wph + DT * TAU * 2 / max(0.1, K.beat_sec)) % TAU
    shk = shk * exp(-DT / 0.25)
    fillf = fillf * exp(-DT / 0.8)
    flare = flare * exp(-DT / 1.2)
    flk = flk * exp(-DT / 0.12)
    mast = mast * exp(-DT / 0.7)
    sheet_t = sheet_t * exp(-DT / 0.4)
    sheet_l = K.follow(sheet_l, 0, 0.9, DT)
    beam = beam * exp(-DT / 0.35)
    hornf = hornf * exp(-DT / 0.2)
    rackf = rackf * exp(-DT / 0.2)
    beam_s = K.follow(beam_s, beam, 0.07, DT)
    hornf_s = K.follow(hornf_s, hornf, 0.06, DT)
    for k = 0, NR - 1 do clank[k] = clank[k] * exp(-DT / 0.2) end
    for i = #pulses, 1, -1 do if K.T - pulses[i].t0 > 2.5 then table.remove(pulses, i) end end
    -- the phrase, smooth between bars
    local pl = max(1, floor(K.num(S and S.phrase_len, 16)))
    local pp = K.num(S and S.phrase_pos, 0) % pl
    phr = K.follow(phr, clamp((pp + K.bar_ph) / pl, 0, 1), 0.3, DT)
    if K.view == 2 then draw2(S)
    elseif K.view == 3 then draw3(S)
    else draw1(S) end
  end

  M.init()
  return M
end
