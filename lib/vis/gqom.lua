-- gqom. view 1: a taxi rank under a flyover in Durban at night, a minibus
-- idling with its sliding door open and the sound coming out of it as
-- pressure waves through the concrete; view 2: a concrete underpass with
-- one bulb on a cable, the waves rolling down it toward you out of the dark;
-- view 3: the rank from above, slabs of concrete whose joints bend as each
-- wave passes through them. three lights at most, black everywhere else.
--
-- view 1: the flyover deck runs across the top on three pillars; two sodium
-- lamps hang under it and a strip light buzzes over the queue. the kick is
-- a pressure wave out of the taxi's door: an arc that swells through the
-- rank, flares each pillar as it passes, sags the lamps and shakes dust off
-- the deck. toms and hand drums (congas, bongos, talking drum, log drums)
-- crack the concrete, pillars and floor, and the cracks stay, building up
-- over the phrase until it turns over and they go dim; bells and metal
-- glint off the kerb. the snare flares the brake lights and lights the
-- deck's underside, claps a smaller echo of it; closed hats tick the strip
-- light, open hats make it buzz and spill; rims and ticks glint in the
-- puddle; a vox lights the taxi inside; a ratchet stutters a run of small
-- waves; a fill throws the high beams. a car passes on the far road every
-- bar. energy brings more of the queue and pushes the waves harder, chaos
-- breaks the deck into slabs and splinters the cracks and the waves,
-- kickless the waves stop, exhaust and fog settle in and the lamps hum.
-- view 2: the underpass is a concrete arch running away to a dim orange
-- mouth. each kick is a ring of pressure out of the far end that rolls
-- toward you, shaking dust from the crown and swinging the bulb, whose pool
-- of light sways over the wet floor. hand drums crack the walls, bells and
-- metal clank the pipe along the right wall, the snare lights the mouth
-- (headlights passing outside), closed hats drip from the crown, open hats
-- buzz the filament, rims ping rings on the puddle. chaos knocks the arch's
-- sections off true; kickless, a figure stands in the mouth and the fog
-- comes down the tunnel.
-- view 3: from above: the taxi's roof, a lamp's pool, the queue's heads,
-- puddles and litter on a grid of slabs. each kick ring spreads from the
-- open door and the joints bend as it passes, the litter skitters; hand
-- drums crack the slabs; the snare lights the brake lights, hats drip on
-- the puddles, open hats bring moths round the lamp; bells kick a can. chaos
-- shears the slabs apart, kickless the grid lies still under drifting fog.
--
-- the ears: the lows drive the waves and the pools of light, the mids light
-- the taxi's windows and the walls, the highs buzz the strip light and the
-- bulb and glint the water, the level lights the lamps' cones.
return function(K)
  local M = {}
  local put, line, A, clamp, num = K.put, K.line, K.A, K.clamp, K.num
  local sin, cos, floor, max, min, abs, exp, sqrt = math.sin, math.cos, math.floor, math.max, math.min,
    math.abs, math.exp, math.sqrt
  local PI, TAU = math.pi, K.TAU
  local TH8 = {0, 4, 2, 6, 1, 5, 3, 7}

  -- a level, ordered-dithered by row (for the views that hold still)
  local function dith(v, y)
    if not (v > 0.05) then return 0 end
    local th = (TH8[y % 8 + 1] + 0.5) / 8
    if v < 1 then return (v > th) and 1 or 0 end
    local l = floor(v)
    if v - l > th then l = l + 1 end
    return l
  end

  -- a long line in short pieces, so a glitch tears only the rows it holds
  local function seg(l, x0, y0, x1, y1)
    local n = max(1, floor(max(abs(x1 - x0), abs(y1 - y0)) / 8))
    local px, py = x0, y0
    for k = 1, n do
      local nx, ny = x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n
      line(l, px, py, nx, ny)
      px, py = nx, ny
    end
  end

  ---------------------------------------------------------------- state
  local waves, cracks, motes, glints, drips, puffs
  local boom, sag, snap, clapv, tube, otube, beam, vox, bell, ping
  local car_t, crack_acc, puff_acc, drip_acc
  local sw_a, sw_v                      -- the bulb's swing (view 2)
  local bulb_s = 3
  local slab, slab_to                   -- chaos: the deck / the slabs out of true
  local litter
  local phase_seen

  local NLIT = 10

  function M.init()
    waves, cracks, motes, glints, drips, puffs = {}, {}, {}, {}, {}, {}
    boom, sag, snap, clapv, tube, otube, beam, vox, bell, ping = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    car_t, crack_acc, puff_acc, drip_acc = -9, 0, 0, 0
    sw_a, sw_v = 0.2, 0
    slab, slab_to = {0, 0, 0, 0}, {0, 0, 0, 0}
    litter = {}
    for i = 1, NLIT do
      litter[i] = {x = 6 + K.hash(i, 301) * 116, y = 6 + K.hash(i, 302) * 52, vx = 0, vy = 0}
    end
    phase_seen = -1
  end
  M.clear = M.init

  ---------------------------------------------------------------- the hits
  local function wave(v, small, delay)
    if #waves >= 8 then table.remove(waves, 1) end
    waves[#waves + 1] = {t0 = K.T + (delay or 0), v = v, small = small,
      dur = small and 0.45 or 1.1, jit = K.rnd() * 100}
  end

  local function crack(v)
    if #cracks >= 14 then table.remove(cracks, 1) end
    cracks[#cracks + 1] = {t0 = K.T, v = v, u = K.rnd(), w = K.rnd(), a = K.rnd() * TAU,
      seed = floor(K.rnd() * 9973), life = 5 + K.rnd() * 5}
  end

  local function dust(n, v)
    for _ = 1, n do
      if #motes >= 36 then table.remove(motes, 1) end
      motes[#motes + 1] = {t0 = K.T, u = K.rnd(), v = v, dx = (K.rnd() - 0.5) * 6, g = 30 + K.rnd() * 30}
    end
  end

  local function glint(kind, v)
    if #glints >= 8 then table.remove(glints, 1) end
    glints[#glints + 1] = {t0 = K.T, u = K.rnd(), kind = kind, v = v}
  end

  function M.kick(v)
    v = num(v, 1)
    wave(v)
    boom = max(boom, v)
    sag = max(sag, v)
    sw_v = sw_v + (sw_a > 0 and -1 or 1) * (0.6 + 0.6 * v)
    dust(3 + floor(K.energy * 4 + v * 2), v)
    -- the litter jumps away from the door
    for i = 1, NLIT do
      local L = litter[i]
      local dx, dy = L.x - 41, L.y - 41
      local d = sqrt(dx * dx + dy * dy) + 1
      local f = v * 30 * exp(-d / 50)
      L.vx, L.vy = L.vx + dx / d * f, L.vy + dy / d * f
    end
  end

  function M.snare(v, n)
    v = num(v, 1)
    snap = max(snap, v)
    if (n or 1) > 1 then wave(0.4, true) end
  end
  function M.clap(v) clapv = max(clapv, num(v, 1)); wave(0.35 * num(v, 1), true, 0.03) end
  function M.rim(v) glint(1, num(v, 1)); ping = max(ping, num(v, 1)) end

  function M.hat(v, open)
    v = num(v, 1)
    if open then otube = max(otube, v) else tube = max(tube, v) end
    if #drips >= 6 then table.remove(drips, 1) end
    drips[#drips + 1] = {t0 = K.T, u = K.rnd(), v = v, open = open}
  end
  function M.ride(v) otube = max(otube, 0.5 * num(v, 1)); glint(2, num(v, 1)) end
  function M.shaker(v) tube = max(tube, 0.5 * num(v, 1)) end

  -- the hand drums crack the concrete; bells and metal glint; a vox lights the taxi
  local HAND = {[1] = true, [2] = true, [7] = true, [13] = true, [17] = true, [18] = true, [20] = true}
  local BELL = {[3] = true, [4] = true, [6] = true, [10] = true, [21] = true}
  function M.perc(kind, v)
    kind, v = floor(num(kind, 1)), num(v, 1)
    if HAND[kind] then crack(v)
    elseif BELL[kind] then bell = max(bell, v); glint(3, v)
    elseif kind == 16 then vox = max(vox, v)
    else glint(1, v * 0.7); tube = max(tube, 0.4 * v) end
  end
  function M.tom(v) crack(num(v, 1)); dust(2, 0.5) end
  function M.tick() glint(1, 0.6) end
  function M.brk(s, n, rev)
    s = floor(num(s, 1))
    if s % 4 == 1 then crack(0.5) else glint(1, 0.5) end
  end

  function M.ratchet(n)
    n = clamp(floor(num(n, 2)), 1, 12)
    for k = 0, n - 1 do wave(0.5, true, k * 0.06) end
    sw_v = sw_v + 0.3 * n * (K.rnd() < 0.5 and -1 or 1)
  end

  function M.fill() beam = 1; sw_v = sw_v + 2 end

  function M.bar(S)
    car_t = K.T
    for i = 1, 4 do slab_to[i] = (K.hash(i + floor(K.T * 3), 311) - 0.5) end
    -- the phrase turns over: the cracks go dim
    local pp = num(type(S) == "table" and S.phrase_pos, 0)
    if pp == 0 then
      for _, C in ipairs(cracks) do C.life = math.min(C.life, K.T - C.t0 + 1.2) end
    end
  end

  ---------------------------------------------------------------- shared
  -- a crack: a jagged polyline grown from (x, y) along a, with branches
  local function crack_path(lv, x, y, a, seed, n, sc, grow, wob, x0, x1, y0, y1)
    local nseg = min(n, floor(grow * n) + 1)
    local px, py = x, y
    local ch = K.chaos
    for k = 1, nseg do
      a = a + (K.hash(seed + k, 31) - 0.5) * wob
      local l = sc * (0.6 + K.hash(seed + k, 32))
      local nx, ny = clamp(px + cos(a) * l, x0, x1), clamp(py + sin(a) * l, y0, y1)
      line(lv, px, py, nx, ny)
      if k < nseg and K.hash(seed + k, 33) < 0.2 + ch * 0.45 then
        local ba = a + (K.hash(seed + k, 34) < 0.5 and -1 or 1) * (0.7 + 0.6 * K.hash(seed + k, 35))
        local bl = l * (0.8 + K.hash(seed + k, 36) * (1 + ch))
        line(lv * 0.6, nx, ny, clamp(nx + cos(ba) * bl, x0, x1), clamp(ny + sin(ba) * bl, y0, y1))
      end
      px, py = nx, ny
    end
  end

  -- a crack's level and growth now (level 0: gone)
  local function crack_lv(C)
    local age = K.T - C.t0
    if age < 0 then return 0, 0 end
    local fade = clamp((C.life - age) / 1.2, 0, 1)
    return (1.6 + C.v * 8 * exp(-age / 0.3)) * fade, clamp(age / 0.22, 0, 1)
  end

  local function phrase(S)
    local pl = num(S.phrase_len, 16)
    if not (pl >= 1 and pl < 1e4) then pl = 16 end
    local pp = num(S.phrase_pos, 0)
    if not (pp >= 0 and pp < 1e4) then pp = 0 end
    return clamp((pp + K.bar_ph) / pl, 0, 1)
  end

  local function age_out(DT)
    boom = boom * exp(-DT / 0.14)
    sag = sag * exp(-DT / 0.3)
    snap = snap * exp(-DT / 0.22)
    clapv = clapv * exp(-DT / 0.16)
    tube = tube * exp(-DT / 0.07)
    otube = otube * exp(-DT / 0.3)
    beam = beam * exp(-DT / 1.0)
    vox = vox * exp(-DT / 0.4)
    bell = bell * exp(-DT / 0.2)
    ping = ping * exp(-DT / 0.3)
    local T = K.T
    for i = #waves, 1, -1 do if T - waves[i].t0 > waves[i].dur then table.remove(waves, i) end end
    for i = #cracks, 1, -1 do if T - cracks[i].t0 > cracks[i].life then table.remove(cracks, i) end end
    for i = #glints, 1, -1 do if T - glints[i].t0 > 0.5 then table.remove(glints, i) end end
    for i = #drips, 1, -1 do if T - drips[i].t0 > 1.0 then table.remove(drips, i) end end
    for i = #motes, 1, -1 do if T - motes[i].t0 > 1.6 then table.remove(motes, i) end end
    -- chaos cracks the concrete on its own
    crack_acc = crack_acc + max(0, K.chaos - 0.3) * 1.2 * K.DTS
    if crack_acc >= 1 then crack_acc = 0; crack(0.4 + K.chaos * 0.4) end
    for i = 1, 4 do slab[i] = K.follow(slab[i], slab_to[i] * max(0, K.chaos - 0.35) * 2, 0.25, DT) end
  end

  ---------------------------------------------------------------- view 1
  local GY = 53                         -- the ground line
  local DECK = 9                        -- the deck's underside
  local PIL = {{6, 8}, {72, 8}, {121, 7}}
  local L1X, L2X, LY = 34, 110, 13      -- the sodium lamps
  local TX0, TX1 = 86, 100              -- the strip light
  local VAN0, VAN1, VTOP = 22, 60, 37   -- the taxi
  local DX, DY = 41, 45                 -- its open door: where the sound comes out
  local RIDGE = {}
  for c = 0, 64 do
    local x = c * 2
    RIDGE[c] = 33 - 4 * sin(x * 0.03 + 0.5) - 2 * sin(x * 0.11) - floor(K.hash(c // 3, 321) * 3)
  end
  local CITY = {}
  for i = 1, 14 do
    local x = floor(K.hash(i, 331) * 124) + 2
    CITY[i] = {x = x, y = RIDGE[x // 2] + 2 + floor(K.hash(i, 332) * 8), h = K.hash(i, 333)}
  end
  local QUEUE = {85, 90, 95, 100, 104, 108}
  local FIG, nfig = {}, 0
  for i = 1, 16 do FIG[i] = {0, 0, 0, 0} end

  local function fig_add(x0, x1, y0, y1)
    nfig = nfig + 1
    local f = FIG[nfig]
    f[1], f[2], f[3], f[4] = x0, x1, y0, y1
  end

  -- a row of light with the queue cut out of it, so they stand black
  local function row_cut(l, y, x0, x1)
    if l < 1 then return end
    local a = x0
    for i = 1, nfig do
      local f = FIG[i]
      if y >= f[3] and y < f[4] and f[2] > a and f[1] < x1 then
        if f[1] > a then put(l, a, y, f[1] - a, 1) end
        a = max(a, f[2])
      end
    end
    if x1 > a then put(l, a, y, x1 - a, 1) end
  end

  -- a lamp's cone down to the ground and its pool
  local function cone(bx, by, I, spread)
    for y = by + 2, GY - 1, 1 do
      local d = y - by
      local hw = 1.5 + d * spread
      local v = I * (0.45 + 0.55 * exp(-d / 14)) * 0.9
      if y % 3 == 0 then
        local l = dith(v * 0.55, y)
        if l > 0 then row_cut(l, y, bx - hw, bx + hw) end
      elseif d < 22 or y % 3 == 1 then
        local lc = dith(v, y)
        if lc > 0 then row_cut(lc, y, bx - hw * 0.35, bx + hw * 0.35) end
      end
    end
    for r = 0, 3 do
      local y = GY + 2 + r * 2
      local hw = (GY - by) * spread * (1.1 - r * 0.15) + r * 2
      local l = dith(I * (1 - r * 0.18), y)
      if l > 0 then put(l, bx - hw, y, hw * 2, 1) end
    end
  end

  local function rank(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    local ph = phrase(S)

    -- the queue under the strip light: black against the light
    nfig = 0
    fig_add(VAN0, VAN1, VTOP, GY - 1)
    local nq = clamp(floor(2 + e * 4 + 0.5), 2, #QUEUE)
    for i = 1, nq do
      local x = QUEUE[i] + sin(T * 0.4 + i * 1.7) * 0.6
      local h = 10 + floor(K.hash(i, 341) * 3)
      fig_add(x - 1, x + 2, GY - h + 3, GY + 1)
      fig_add(x - 0.5, x + 1.5, GY - h, GY - h + 3)
    end

    -- the city on the ridge beyond, a few lights, an aviation lamp
    local rl = 1 + amp * 0.8 + md * 0.6
    for col = 1, 63 do line(rl, (col - 1) * 2, RIDGE[col - 1], col * 2, RIDGE[col]) end
    for i = 1, #CITY do
      local P = CITY[i]
      if P.h < 0.35 + e * 0.35 + md * 0.3 then
        put(1.5 + P.h * 2 + md * 1.5 + 0.6 * sin(T * (0.3 + P.h) + i), P.x, P.y, 1, 1)
      end
    end
    put(1 + 4 * (0.5 + 0.5 * sin(T * 1.6)), 58, RIDGE[29] - 4, 1, 1)
    line(1, 58, RIDGE[29] - 3, 58, RIDGE[29])

    -- a car on the far road, once a bar
    local ca = T - car_t
    if ca >= 0 and ca < 3 then
      local x = -6 + ca * 50
      local inx = x < VAN0 or x > VAN1
      if inx then
        put(3 + lo, x, 41, 2, 1)
        line(1.2, x + 2, 41, x + 9, 41)
      end
    end

    -- the deck: a dark slab; chaos breaks it into slabs out of true
    for k = 0, 3 do
      local dy = floor(slab[k + 1] * 3 + 0.5)
      local x0 = k * 32
      line(1, x0, 2 + dy, x0 + 31, 2 + dy)
      -- the underside, lit by the lamps and the snare, the mids warm it
      local und = 1.5 + snap * 5 + clapv * 2.5 + md * 1.5 + amp * 0.8
      line(und, x0, DECK + dy, x0 + 31, DECK + dy)
      if k > 0 and c > 0.4 then line(2 + c * 3, x0, 0, x0, DECK + dy) end
    end
    for x = 4, 124, 12 do put(1.5 + snap * 2, x, DECK + 1, 3, 1) end
    for x = 18, 124, 24 do line(1, x, 3, x, DECK - 1) end

    -- the lamps: sag on the kick, hum when the kick stops; the level
    -- lights their cones
    local hum = kl * 0.8 * (0.5 + 0.5 * sin(T * 2.1))
    local fail = c > 0.5 and (0.5 + 0.5 * sin(T * 3.3) * sin(T * 1.1)) * (c - 0.5) * 1.6 or 0
    local I1 = (2.2 + amp * 1.6 + lo * 0.6 + hum + beam * 0.5) * (1 - sag * 0.35) * (1 - fail)
    local I2 = (2.0 + amp * 1.4 + lo * 0.5 + hum) * (1 - sag * 0.3)
    local sx1 = sin(T * 0.9 + sw_a) * 0.6
    cone(L1X + sx1, LY, I1, 0.34)
    cone(L2X, LY, I2, 0.3)
    -- the strip light over the queue: the highs buzz it, hats tick it
    local buzz = tube * (0.6 + 0.4 * sin(T * 70)) + otube * (0.7 + 0.3 * sin(T * 47))
    local sl = 1.2 + hi * 2.4 + buzz * 2.2 + e * 0.4
    for y = DECK + 4, GY - 1, 2 do
      local d = (y - DECK - 4) / (GY - DECK)
      if d > 0.3 and y % 6 ~= 1 then goto skip end
      local l = dith(sl * (1 - d * 0.9) * 0.8, y)
      if l > 0 then row_cut(l, y, TX0 - 1 - d * 7, TX1 + 1 + d * 7) end
      ::skip::
    end
    line(4 + hi * 5 + buzz * 5, TX0, DECK + 3, TX1, DECK + 3)
    line(1.5, TX0 + 2, DECK + 1, TX0 + 2, DECK + 3)
    line(1.5, TX1 - 2, DECK + 1, TX1 - 2, DECK + 3)
    -- lamp heads and cables
    line(1.5, L1X, DECK + 1, L1X + sx1, LY - 1)
    line(1.5, L2X, DECK + 1, L2X, LY - 1)
    put(min(11, 6 + amp * 3 - sag * 2 + hum * 2 - fail * 4), L1X + sx1 - 1, LY - 1, 3, 2)
    put(min(11, 6 + amp * 3 - sag * 2 + hum * 2), L2X - 1, LY - 1, 3, 2)

    -- the pillars: their faces flare as each wave goes through them
    for p = 1, #PIL do
      local px, pw = PIL[p][1], PIL[p][2]
      local d = abs(px + pw / 2 - DX)
      local hitl = 0
      for _, W in ipairs(waves) do
        local age = T - W.t0
        if age >= 0 then
          local r = age * (W.small and 90 or 70)
          hitl = hitl + W.v * exp(-((r - d) / 6) ^ 2) * (W.small and 3 or 6) * (1 - age / W.dur)
        end
      end
      local off = (c > 0.45 and p ~= 3) and floor(slab[p] * 4 + 0.5) or 0
      local fy = 30 + p * 4
      local pl = 1 + hitl * 0.6 + lo * 0.5
      seg(pl, px, DECK, px, fy); seg(pl, px + off, fy, px + off, GY - 1)
      seg(pl, px + pw - 1, DECK, px + pw - 1, fy); seg(pl, px + pw - 1 + off, fy, px + pw - 1 + off, GY - 1)
      for y = DECK + 6, GY - 4, 9 do put(1, px + 1 + (y > fy and off or 0), y, pw - 2, 1) end
      local near = (p == 2) and 1 or 0
      seg(2 + hitl + beam * 4 * near + lo * near, px + (near == 1 and 0 or pw - 1), DECK, px + (near == 1 and 0 or pw - 1) + off, GY - 1)
      if hitl > 0.6 then
        for x = px + 1, px + pw - 2, 2 do seg(hitl * 0.7, x + (off > 0 and 1 or 0), DECK + 2, x, GY - 2) end
      end
      put(2 + hitl * 0.6, px - 1, DECK, pw + 2, 2)
      if off ~= 0 then line(3 + c * 3, px, fy, px + pw, fy) end
    end

    -- the ground: the kerb, the headlights on it, the puddle
    put(2 + lo * 1.2, 0, GY, 128, 1)
    local hb = 1.6 + beam * 5 + e * 0.5
    for r = 0, 4 do
      local y = GY - 3 + r * 2
      local x0 = VAN1 + 2 + r * 2
      local l = dith(hb * (1 - r * 0.15), y)
      if l > 0 then row_cut(l, y, x0, x0 + 18 + r * 8 + beam * 14) end
    end
    -- the puddle by the far lamp: the lamp's streak, broken by the waves and drips
    local pr = 0
    for _, W in ipairs(waves) do
      local age = T - W.t0
      if age >= 0 then pr = pr + W.v * exp(-age / 0.3) end
    end
    for k = 0, 3 do
      local y = 57 + k
      local wob = sin(T * 5 + k * 2) * (0.5 + pr * 2 + ping * 2)
      put(I2 * (0.9 - k * 0.15) + hi * 1.2, L2X - 1 + wob, y, 3, 1)
    end
    line(1.5 + hi, 98, 61, 124, 61)
    for _, G in ipairs(glints) do
      local u = (T - G.t0) / 0.5
      local x = G.kind == 3 and (VAN1 + 4 + G.u * 40) or (100 + G.u * 22)
      local y = G.kind == 3 and GY or 57 + floor(G.u * 4)
      put((3 + G.v * 7) * (1 - u), x, y, G.kind == 3 and 2 or 1, 1)
    end

    -- the taxi: a minibus side on, nose to the right, door open
    local shud = boom * 0.6 + lo * 0.4
    local vy = VTOP + (shud > 0.6 and 1 or 0)
    -- a black body: only its edges catch the lamps
    local body = 1.5 + md * 0.8 + amp * 0.5
    line(body, VAN0, vy, VAN0, GY - 3)
    line(body, VAN1, vy + 4, VAN1, GY - 4)
    line(body, VAN0, GY - 3, VAN1, GY - 3)
    line(body * 0.7, VAN0 + 1, vy + 7, VAN1 - 1, vy + 7)
    line(body, DX - 4, vy + 1, DX - 4, GY - 4)
    line(body, DX + 4, vy + 1, DX + 4, GY - 4)
    put(1, DX - 3, vy + 1, 7, GY - 4 - vy)
    line(2.5 + amp, VAN0, vy, VAN1 - 5, vy)
    line(2.5 + amp, VAN1 - 5, vy, VAN1, vy + 4)
    -- the windows: the inside lit by the mids and a vox
    local win = 1 + md * 3 + vox * 6 + e * 0.5
    for x = VAN0 + 2, VAN1 - 8, 6 do
      if x + 4 < DX - 4 or x > DX + 4 then put(win, x, vy + 2, 4, 3) end
    end
    -- the door: the speaker in the dark, its cone pumping
    K.ring(2 + boom * 7 + lo * 3, DX, DY - 1, 2 + boom * 1.5 + lo * 0.8, 10)
    put(3 + boom * 8, DX, DY - 1, 1, 1)
    -- wheels, lights
    K.ring(2, VAN0 + 7, GY - 2, 3, 8)
    K.ring(2, VAN1 - 9, GY - 2, 3, 8)
    put(min(12, 7 + beam * 4 + e), VAN1 - 2, vy + 6, 2, 2)
    put(2 + snap * 8 + clapv * 4, VAN0, vy + 6, 2, 3)
    -- kickless: it idles, the exhaust drifting
    if kl > 0.1 then
      puff_acc = puff_acc + kl * 2 * K.DTS
      if puff_acc >= 1 then
        puff_acc = 0
        if #puffs >= 6 then table.remove(puffs, 1) end
        puffs[#puffs + 1] = {t0 = T}
      end
    end
    for i = #puffs, 1, -1 do
      local u = (T - puffs[i].t0) / 2.5
      if u >= 1 then table.remove(puffs, i)
      else K.ring(1.5 * (1 - u) + 0.6, VAN0 - 2 - u * 10, GY - 3 - u * 8, 1 + u * 4, 6, 0, TAU, 0.6) end
    end

    -- the waves out of the door, through the rank
    for _, W in ipairs(waves) do
      local age = T - W.t0
      if age >= 0 then
        local u = age / W.dur
        local r = age * (W.small and 90 or 70) + 3
        local lv = (W.small and 3 or 2.5 + W.v * 6 + lo * 2) * (1 - u) * (1 - u)
        K.ring(lv, DX, DY, r, W.small and 16 or 24, PI * 0.98, PI * 2.02, 0.62, c * 4, floor(W.jit))
        if not W.small and u < 0.5 then
          K.ring(lv * 0.4, DX, DY, r * 0.8, 18, PI, PI * 2, 0.62, c * 3, floor(W.jit) + 3)
        end
      end
    end

    -- the cracks: pillars and floor
    for _, C in ipairs(cracks) do
      local lv, grow = crack_lv(C)
      if lv > 0.5 then
        if C.u < 0.55 then
          local P = PIL[1 + floor(C.w * 2.99)]
          local x = P[1] + 1 + (C.w * 3 % 1) * (P[2] - 2)
          local y = DECK + 3 + C.u / 0.55 * 36
          crack_path(lv, x, y, (C.a < PI) and PI / 2 or -PI / 2, C.seed, 7, 2.5, grow, 1.2,
            P[1], P[1] + P[2] - 1, DECK + 2, GY - 1)
        else
          local x = 4 + C.w * 120
          crack_path(lv, x, GY + 1 + (C.u - 0.55) * 10, (C.a < PI) and 0 or PI, C.seed, 7, 3, grow, 1.1,
            0, 127, GY + 1, 63)
        end
      end
    end

    -- dust off the deck as the wave reaches it
    for _, P in ipairs(motes) do
      local x = 4 + P.u * 120
      local age = T - P.t0 - abs(x - DX) / 70 * 0.6
      if age >= 0 then
        local y = DECK + 2 + 0.5 * P.g * age * age
        if y < GY then put((2 + P.v * 3 + hi * 2) * clamp(1 - age / 1.4, 0, 1), x + P.dx * age, y, 1, 1) end
      end
    end
    -- the air between hits: a little drifting grit in the light
    for k = 1, 8 do
      local u = (T * (0.08 + K.hash(k, 351) * 0.08) + K.hash(k, 352)) % 1
      put(1 + hi + 0.8 * sin(T * 2 + k), L2X - 10 + K.hash(k, 353) * 20 + sin(T * 0.5 + k) * 3, LY + 4 + u * 36, 1, 1)
    end
    -- the phrase: fog creeps in under the deck as it goes on; kickless, it settles
    local fog = kl * 0.45 + ph * 0.12 + e * 0.05 + 0.08
    K.haze(0, GY - 14, 128, 64, fog, 1, T * 3)
  end

  ---------------------------------------------------------------- view 2
  local VX, VY, F = 64, 28, 34
  local HW, SPR, AR = 1.3, -0.1, 1.3   -- half width, spring line, arch radius
  local ZB = 3.4                        -- the bulb hangs here
  local ZM = 11                         -- the mouth
  local JOINT = {1.05, 1.4, 1.85, 2.45, 3.2, 4.2, 5.5, 7.2, 9.3}
  local ASEG = 8
  local SX, SY = {}, {}                 -- a section's outline, scratch

  -- the section outline at depth z (walls, arch), shifted by (ox, oy) px
  local function section(lv, z, ox, oy, s)
    s = s or 1
    local n = 0
    local function add(X, Y)
      n = n + 1
      SX[n], SY[n] = VX + X * s * F / z + ox, VY + Y * s * F / z + oy
    end
    add(-HW, 1)
    add(-HW, SPR)
    for k = 1, ASEG - 1 do
      local a = PI + k / ASEG * PI
      add(cos(a) * AR, SPR + sin(a) * AR)
    end
    add(HW, SPR)
    add(HW, 1)
    for k = 2, n do line(lv, SX[k - 1], SY[k - 1], SX[k], SY[k]) end
  end

  local function pj(X, Y, z) return VX + X * F / z, VY + Y * F / z end

  local function underpass(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    local ph = phrase(S)

    -- the bulb swings on its cable
    sw_v = sw_v + (-sw_a * 9 - sw_v * 0.6) * DT + sin(T * 0.7) * 0.15 * DT
    sw_a = clamp(sw_a + sw_v * DT, -1, 1)
    local bX = sin(sw_a) * 0.55
    local bY = -AR + SPR + 0.25 + cos(sw_a) * 0.55
    bulb_s = K.follow(bulb_s, (3.2 + amp * 1.5 + e * 0.8 + otube * 0.8 + hi * 1.2) * (1 - sag * 0.15), 0.1, DT)
    local bulb = bulb_s
    local function lit(X, Y, z)
      local dx, dy, dz = X - bX, Y - bY, (z - ZB) * 0.8
      return bulb / (1 + (dx * dx + dy * dy + dz * dz) * 1.4)
    end

    -- the mouth: the night outside, orange-dim; the snare is headlights passing
    local mo = 1.3 + amp * 1.2 + snap * 4 + clapv * 2 + ph * 0.8
    local mx0, mx1 = pj(-HW, 0, ZM)
    local my0 = VY + (SPR - AR) * F / ZM
    local my1 = VY + F / ZM
    local _, mys = pj(0, SPR, ZM)
    local fx = VX + sin(T * 0.13) * 0.6
    for y = floor(my0) + 1, floor(my1) do
      local hw = HW * F / ZM
      if y < mys then
        local dy = (mys - y) / (AR * F / ZM)
        hw = hw * sqrt(max(0, 1 - dy * dy))
      end
      local l = min(8, mo * (0.7 + 0.3 * (y - my0) / (my1 - my0)))
      -- kickless: someone stands in the mouth
      if kl > 0.5 and y > my0 + 2 then
        put(l, VX - hw, y, fx - 0.5 - (VX - hw), 1)
        put(l, fx + 1.5, y, VX + hw - fx - 1.5, 1)
      else
        put(l, VX - hw, y, hw * 2, 1)
      end
    end

    -- the walls, strip by strip: concrete lit by the bulb; the mids lift it
    for x = 1, 126, 4 do
      local side = x < VX and -1 or 1
      local dxs = abs(x - VX)
      if dxs > HW * F / ZM + 1 then
        local z = HW * F / dxs
        if z > 0.9 then
          local yt = VY + SPR * F / z
          local yb = VY + F / z
          local l = lit(side * HW, 0.4, z) * (1 + md * 0.8) + md * 0.3
          if l > 1 then seg(min(4, l), x, yt + 1, x, yb - 1) end
        end
      end
    end
    -- the floor: wet concrete, a pool under the bulb, the lows warm it
    for y = floor(VY + F / ZM) + 1, 63 do
      local z = F / (y - VY)
      local hw = HW * F / z
      local dz, dx = (z - ZB) * 0.9, bX * 0.5
      local l = bulb * (1.1 + lo * 0.7) / (1 + (dz * dz + dx * dx) * 3.5) - 0.5
      if l >= 0.6 then put(min(6, l), VX - hw, y, hw * 2, 1) end
    end
    -- the bulb's reflection in the water, rippled by the waves and the rims
    local pr = ping * 2
    for _, W in ipairs(waves) do
      local age = T - W.t0
      if age >= 0 then pr = pr + W.v * exp(-age / 0.4) end
    end
    local _, rfy = pj(0, 1, ZB)
    for k = 0, 7 do
      local z = ZB - 0.25 - k * 0.12
      local x, y = pj(bX, 1, z)
      local wob = sin(T * 6 + k * 1.9) * (0.4 + pr * 1.5)
      put(min(10, bulb * (1 - k * 0.1) + hi * 1.5), x + wob - 1, rfy + k * 1.6 + 2, 2 + (k > 4 and 1 or 0), 1)
    end

    -- the sections: joints in the concrete, knocked off true by chaos
    for j = #JOINT, 1, -1 do
      local z = JOINT[j]
      local l = lit(0, -0.2, z) * 0.7 + 0.9 + md * 0.5
      local ox, oy = 0, 0
      if c > 0.35 then
        ox = floor((K.hash(j, 361 + floor(T * 0.5)) - 0.5) * (c - 0.35) * 8 / z * 3 + 0.5)
        oy = floor((K.hash(j, 362 + floor(T * 0.5)) - 0.5) * (c - 0.35) * 4 / z * 3 + 0.5)
      end
      section(min(5, l), z, ox, oy)
    end
    -- the long edges, from us to the mouth
    for _, P in ipairs({{-HW, 1}, {HW, 1}, {-HW, SPR}, {HW, SPR}, {0, SPR - AR}}) do
      local x0, y0 = pj(P[1], P[2], 0.9)
      local x1, y1 = pj(P[1], P[2], ZM)
      seg(1.5 + lo * 0.6, x0, y0, x1, y1)
    end
    -- the pipe along the right wall: bells clank it
    do
      local x0, y0 = pj(HW - 0.08, -0.05, 1)
      local x1, y1 = pj(HW - 0.08, -0.05, ZM)
      seg(2 + bell * 7 + md, x0, y0, x1, y1)
      for j = 2, #JOINT, 2 do
        local x, y = pj(HW - 0.08, -0.05, JOINT[j])
        put(2 + bell * 5, x - 1, y, 1, 2)
      end
    end

    -- the bulb on its cable
    local cx0, cy0 = pj(0, SPR - AR, ZB)
    local bx, by = pj(bX, bY, ZB)
    line(1.5, cx0, cy0, bx, by)
    put(min(12, 4 + bulb * 1.6 + otube * 3 + tube * 2), bx - 1, by, 2, 2)
    put(min(6, bulb * 0.9), bx - 2, by - 1, 4, 1)

    -- the waves: rings of pressure rolling toward us out of the dark
    for _, W in ipairs(waves) do
      local age = T - W.t0
      if age >= 0 then
        local u = age / W.dur
        local z = (ZM - 0.5) / (1 + age * (W.small and 18 or 9))
        if z > 0.95 then
          local lv = (W.small and 2.5 or 2 + W.v * 6 + lo * 2.5) * clamp((z - 0.95) / 1.6, 0, 1)
          local ox = c > 0.3 and sin(W.jit + T * 7) * c * 2 or 0
          section(min(12, lv), z, ox, 0)
          if not W.small and z < 6 then section(lv * 0.3, z * 1.25, 0, 0) end
        end
      end
    end

    -- the cracks in the walls
    for _, C in ipairs(cracks) do
      local lv, grow = crack_lv(C)
      if lv > 0.5 then
        local side = C.w < 0.5 and -1 or 1
        local z = 1.3 + C.u * 4.5
        local x, y = pj(side * HW, -0.05 + (C.w * 2 % 1) * 0.9, z)
        local yt, yb = VY + SPR * F / z, VY + F / z
        local xa = side < 0 and 0 or x - 12 / z * 3
        local xb = side < 0 and x + 12 / z * 3 or 127
        crack_path(lv, x, y, C.a, C.seed, 6, 7 / z, grow, 1.3, xa, xb, yt, yb)
      end
    end

    -- dust shaken from the crown as the wave passes overhead; drips
    for _, P in ipairs(motes) do
      local z = 1.2 + P.u * 6
      local age = T - P.t0 - (ZM - z) / 9 * 0.35
      if age >= 0 and age < 1.4 then
        local Y = SPR - AR + 0.1 + 0.5 * P.g * 0.04 * age * age
        if Y < 1 then
          local x, y = pj(P.dx * 0.12, Y, z)
          put((2 + P.v * 3) * (1 - age / 1.4) + lit(0, Y, z) * 0.4, x, y, 1, 1)
        end
      end
    end
    for _, D in ipairs(drips) do
      local age = T - D.t0
      local z = 1.5 + D.u * 3.5
      local X = (D.u * 7 % 1 - 0.5) * 1.6
      local Y = SPR - AR * 0.9 + 4 * age * age
      if Y < 1 then
        local x, y = pj(X, Y, z)
        line(min(9, 2 + D.v * 4 + hi * 3 + (D.open and 2 or 0)), x, y, x, y + 1)
      else
        local u = clamp((age - 0.5) / 0.5, 0, 1)
        local x, y = pj(X, 1, z)
        K.ring((2 + D.v * 3) * (1 - u), x, y, 1 + u * 6 / z, 8, 0, TAU, 0.35)
      end
    end

    -- fog down the tunnel: the phrase and kickless thicken it
    local fog = kl * 0.4 + ph * 0.1 + 0.06
    K.haze(20, 14, 108, 44, fog, 1, T * 2)
  end

  ---------------------------------------------------------------- view 3
  local GX = {0, 22, 44, 66, 88, 110, 128}
  local GYS = {21, 43}
  local SRC_X, SRC_Y = 41, 40           -- the door, seen from above
  local LPX, LPY = 98, 18               -- the lamp post
  local HEADS = {{60, 46}, {66, 50}, {72, 47}, {78, 51}, {84, 48}, {70, 55}, {90, 52}, {56, 53}}
  local PUD = {{20, 54, 9, 3}, {104, 40, 7, 3}}

  -- the wave's push at (x, y): outward displacement, px
  local function push(x, y)
    local dx, dy = x - SRC_X, y - SRC_Y
    local d = sqrt(dx * dx + dy * dy) + 0.001
    local m = 0
    local T = K.T
    for _, W in ipairs(waves) do
      local age = T - W.t0
      if age >= 0 then
        local r = age * (W.small and 90 or 70)
        local u = age / W.dur
        local q = (d - r) / (W.small and 3 or 5)
        m = m + W.v * (W.small and 1 or 2.6 + A[K.LO] * 1.4) * (1 - u) * exp(-q * q) * clamp(d / 8, 0, 1)
      end
    end
    return dx / d * m, dy / d * m
  end

  local function yard(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    local ph = phrase(S)

    -- the lamp's pool: rings of level, the level of the mix widens it
    local pr = 13 + amp * 6 + e * 2
    local pl = (2.2 + amp * 1.2) * (1 - sag * 0.3)
    for x = floor(LPX - pr), floor(LPX + pr) do
      local dx = abs(x - LPX)
      for band = 1, 3 do
        local r = pr * (1.25 - band * 0.25)
        if dx < r and (band > 1 or x % 2 == 0) then
          local h = sqrt(r * r - dx * dx) * 0.85
          seg(pl * (0.3 + band * 0.28), x, LPY - h, x, LPY + h)
        end
      end
    end
    -- the taxi's door spills light on the ground: the mids
    local sp = 1 + md * 2.4 + vox * 4
    for k = 0, 4 do
      put(sp * (1 - k * 0.16), SRC_X - 5 - k * 2, SRC_Y + 2 + k * 2, 10 + k * 4, 2)
    end
    -- the headlights: two beams forward, the fill throws them long
    local hl = 1.6 + beam * 4 + e * 0.6
    for x = 59, 99, 2 do
      local u = (x - 59) / (44 + beam * 30)
      local h = 0.5 + (x - 59) * 0.11
      local l = hl * (1 - u)
      if l >= 0.6 then
        line(l, x, 30 - h, x, 30 + h)
        line(l, x, 37 - h, x, 37 + h)
      end
    end

    -- the slabs: joints that bend as the wave goes through them; chaos
    -- shears the slabs apart
    local jl = 1.2 + lo * 0.6
    local sh = c > 0.4 and (c - 0.4) * 5 or 0
    for i = 2, #GX - 1 do
      local x = GX[i]
      local ox = sh > 0 and floor(slab[i % 4 + 1] * sh + 0.5) or 0
      local pxp, pyp
      for y = 0, 64, 8 do
        local dx, dy = push(x, y)
        local nx, ny = x + dx + ox, y + dy
        if pxp then line(jl + abs(dx) * 0.8, pxp, pyp, nx, ny) end
        pxp, pyp = nx, ny
      end
    end
    for j = 1, #GYS do
      local y = GYS[j]
      local oy = sh > 0 and floor(slab[(j + 1) % 4 + 1] * sh * 0.6 + 0.5) or 0
      local pxp, pyp
      for x = 0, 128, 8 do
        local dx, dy = push(x, y)
        local nx, ny = x + dx, y + dy + oy
        if pxp then line(jl + abs(dy) * 0.8, pxp, pyp, nx, ny) end
        pxp, pyp = nx, ny
      end
    end

    -- the puddles: hats drip on them, the highs glint
    for p = 1, #PUD do
      local P = PUD[p]
      local dx, dy = push(P[1], P[2])
      K.ring(1.5 + hi * 2 + lo * 0.5, P[1] + dx * 0.5, P[2] + dy * 0.5, P[3], 12, 0, TAU, P[4] / P[3])
      put(1.5 + hi * 4 + 0.8 * sin(T * 1.3 + p), P[1] - 2, P[2] - 1, 3, 1)
    end
    for _, D in ipairs(drips) do
      local u = (T - D.t0) / 1.0
      local P = PUD[1 + floor(D.u * 1.99)]
      local x = P[1] + (D.u * 5 % 1 - 0.5) * P[3]
      K.ring((2 + D.v * 4 + (D.open and 2 or 0)) * (1 - u), x, P[2], 0.8 + u * 4, 8, 0, TAU, 0.5)
    end

    -- the cracks in the slabs
    for _, C in ipairs(cracks) do
      local lv, grow = crack_lv(C)
      if lv > 0.5 then
        crack_path(lv, 6 + C.w * 116, 6 + C.u * 52, C.a, C.seed, 7, 3.5, grow, 1.2, 0, 127, 0, 63)
      end
    end

    -- litter: skittering away from each wave, settling
    for i = 1, NLIT do
      local L = litter[i]
      L.x = L.x + L.vx * DT
      L.y = L.y + L.vy * DT
      L.vx, L.vy = L.vx * exp(-DT / 0.25), L.vy * exp(-DT / 0.25)
      if L.x < 2 or L.x > 126 then L.vx = -L.vx; L.x = clamp(L.x, 2, 126) end
      if L.y < 2 or L.y > 62 then L.vy = -L.vy; L.y = clamp(L.y, 2, 62) end
      -- a slow drift back toward where it lay, so the yard keeps its shape
      L.x = L.x + (6 + K.hash(i, 301) * 116 - L.x) * 0.05 * DT
      L.y = L.y + (6 + K.hash(i, 302) * 52 - L.y) * 0.05 * DT
      local m = abs(L.vx) + abs(L.vy)
      put(1.5 + min(4, m * 0.15) + (i == 1 and bell * 6 or 0), L.x, L.y, i % 3 == 0 and 2 or 1, 1)
    end

    -- the waves, spreading from the door
    for _, W in ipairs(waves) do
      local age = T - W.t0
      if age >= 0 then
        local u = age / W.dur
        local r = age * (W.small and 90 or 70) + 2
        local lv = (W.small and 2.5 or 2 + W.v * 5 + lo * 2) * (1 - u) * (1 - u)
        K.ring(lv, SRC_X, SRC_Y, r, W.small and 16 or 28, 0, TAU, 1, c * 3, floor(W.jit))
      end
    end

    -- the taxi from above: roof, rack, windscreen; brake lights on the snare
    local shud = boom > 0.5 and 1 or 0
    put(1.5 + md * 0.6, 24, 28 + shud, 34, 12)
    line(2.5 + amp, 24, 28 + shud, 57, 28 + shud)
    line(2.5 + amp, 24, 39 + shud, 57, 39 + shud)
    line(2, 24, 28 + shud, 24, 39 + shud)
    line(2.5, 57, 28 + shud, 57, 39 + shud)
    for x = 28, 50, 5 do line(1, x, 30 + shud, x, 37 + shud) end
    put(1 + md * 2.5 + vox * 5, 52, 29 + shud, 4, 10)
    put(2 + snap * 8 + clapv * 4, 23, 29 + shud, 1, 2)
    put(2 + snap * 8 + clapv * 4, 23, 37 + shud, 1, 2)
    put(3 + boom * 8 + lo * 2, SRC_X - 3, SRC_Y, 7, 1)

    -- the queue, heads from above, shuffling; more with energy
    local nq = clamp(floor(3 + e * 5 + 0.5), 3, #HEADS)
    for i = 1, nq do
      local H = HEADS[i]
      local x = H[1] + sin(T * 0.3 + i * 2.3) * 1.2
      local y = H[2] + sin(T * 0.23 + i) * 0.8
      local dx, dy = push(x, y)
      K.disc(1, x + dx * 0.3, y + dy * 0.3, 2.2)
      put(2 + md * 1.2, x + dx * 0.3 - 1, y + dy * 0.3 - 1, 2, 2)
    end

    -- the lamp head, and moths round it: the highs and open hats
    put(min(12, 6 + amp * 3 - sag * 2), LPX - 1, LPY - 1, 3, 3)
    local nm = floor(1 + hi * 4 + otube * 4 + e)
    for k = 1, nm do
      local a = T * (1.5 + K.hash(k, 371) * 2) + k * 2.1
      local r = 4 + K.hash(k, 372) * 6 + sin(T * 3 + k) * 1.5
      put(2 + hi * 4 + otube * 3, LPX + cos(a) * r, LPY + sin(a) * r * 0.8, 1, 1)
    end

    -- fog drifting across: kickless, and as the phrase goes on
    local fog = kl * 0.4 + ph * 0.1 + 0.04
    K.haze(0, 0, 128, 64, fog, 1, T * 4)
  end

  ---------------------------------------------------------------- draw
  function M.draw(S)
    age_out(K.DT)
    if K.view == 2 then underpass(S)
    elseif K.view == 3 then yard(S)
    else rank(S) end
  end

  M.init()
  return M
end
