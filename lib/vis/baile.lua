-- baile. view 1: a baile on a Rio hillside at night: a paredao (a wall of stacked speakers) pumping at the foot of the morro, houses climbing the hill with their windows lit, the crowd in front.
-- view 2: the paredao up close: horns along the top, two rows of big cones flexing out of their boxes, LED strips running between them.
-- view 3: the whole morro from across the bay: its thousand windows, the switchback road with motos climbing it, the party a glowing pocket at the bottom.
--
-- view 1: the kick pumps every cone in the wall and puffs air out of them,
-- lifts the crowd and glows the ground; the tamborzao (and congas, bongos,
-- the rest of the hand drums) flexes the cones one at a time, walking the
-- pattern across the wall; snares and claps throw the crowd's hands up and
-- light the LED bar along the top; closed hats twinkle windows up the hill,
-- open hats sweep a fan of lasers into the sky; ticks light phone screens
-- in the crowd; cowbells and metal send a rocket up the hill to burst; a
-- ratchet runs a chase along the LED bar; a fill sets off fireworks. the
-- phrase fills the hill with lit windows as the night goes on. energy packs
-- the crowd and lights the hill, chaos shakes the stack, scatters the
-- lasers and jitters the houses, and kickless stretches rest the cones,
-- set the crowd swaying and let mist down over the morro under the moon.
-- view 2: the kick pushes every woofer out (the bottom row a beat behind
-- the top, so the wall ripples) and rings air off the cones; each
-- tamborzao hit flexes the next cone in its 3-3-2 walk; snares flare the
-- horns, hats sparkle the tweeters' throats, open hats a long glint; the
-- LED strips chase on the ratchets and fill with the phrase.
-- view 3: the kick pulses the party's glow and the windows around it;
-- the snare sends a ring of light out over the hill; each tamborzao or
-- hand drum starts a moto's headlight up the switchback road; hats
-- twinkle windows, open hats throw a beam up from the party; fills and
-- cowbells set fireworks over the hill; the bay doubles it all.
--
-- the ears: the lows bulge the cones and glow the ground and the bay, the
-- mids light the LED bars, the house walls and the windows' warmth, the
-- highs the lasers, the stars and the twinkle, the level the whole hill.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, exp, sqrt =
    math.sin, math.cos, math.floor, math.max, math.min, math.abs, math.exp, math.sqrt
  local PI = math.pi

  ---------------------------------------------------------------- shared
  -- the tamborzao walks the cones in a 3-3-2: the order the hits land in
  local TZ1 = {7, 8, 9, 10, 11, 12, 1, 2, 3, 13, 14, 15, 16, 17, 18, 4, 5, 6}
  local TZ2 = {5, 6, 7, 1, 2, 3, 8, 4}

  -- where we are in the phrase, 0..1
  local function phrase_u(S)
    if type(S) ~= "table" then return 0 end
    local pl = max(1, floor(K.num(S.phrase_len, 16) or 16))
    local u = ((K.num(S.phrase_pos, 0) or 0) % pl) / pl
    if not (u >= 0 and u <= 1) then u = 0 end
    return u
  end

  ---------------------------------------------------------------- view 1
  local PX0, PX1, PY0, PY1 = 38, 90, 24, 50   -- the paredao: 6 x 3 boxes
  local CWD, CHT = (90 - 38) / 6, (50 - 24) / 3
  local GROUND = 51
  local HILL = K.profile(function(x)
    -- the morro: low at the left, a ridge to the right of centre, falling away
    local u = x / 128
    local y = 30 - 24 * sin(clamp(u * 1.15, 0, 1) * PI * 0.62) + max(0, u - 0.82) * 50
    return y + 1.5 * sin(x * 0.21) + (K.hash(x // 6, 5) - 0.5) * 2
  end)
  -- the houses: a cell on the slope every 7 px across, 5 down
  local HOUSES = {}
  for hx = 0, 126, 7 do
    local top = floor(K.at(HILL, hx + 3)) + 1
    for hy = top, GROUND - 6, 5 do
      local i = #HOUSES + 1
      local behind = hx + 6 > PX0 - 2 and hx < PX1 + 2 and hy + 5 > PY0 - 4
      if not behind and K.hash(hx * 7 + hy, 11) > 0.22 then
        HOUSES[i] = {x = hx + floor(K.hash(hx + hy, 12) * 2), y = hy, w = 5 + floor(K.hash(hx, hy) * 2),
          tank = K.hash(hx * 3 + hy, 13) > 0.6, seed = i}
      end
    end
  end
  local NH = #HOUSES
  local NCROWD = 22

  ---------------------------------------------------------------- view 2
  local W2 = {}                               -- the woofers: x, y, r
  for r = 0, 1 do
    for c = 0, 3 do W2[#W2 + 1] = {x = 17 + c * 31, y = 28 + r * 22, r = 9.5} end
  end

  ---------------------------------------------------------------- view 3
  local MORRO = K.profile(function(x)
    local u = (x - 8) / 92
    local y = 50 - 42 * max(0, sin(clamp(u, 0, 1) * PI)) ^ 0.8
    return min(54, y + (K.hash(x // 4, 31) - 0.5) * 2)
  end)
  local LOAF = K.profile(function(x)
    local d = (x - 116) / 11
    if abs(d) >= 1 then return 64 end
    return 52 - 30 * sqrt(1 - d * d) ^ 1.6
  end)
  local BAY = 54
  -- the window field: one per 3 x 3 cell under the ridge
  local WIN3 = {}
  for wy = 4, BAY - 2, 3 do
    for wx = 2, 102, 3 do
      local x, y = wx + floor(K.hash(wx * 3 + wy, 41) * 2), wy + floor(K.hash(wx + wy * 5, 42) * 2)
      if y > K.at(MORRO, x) + 1 and K.hash(wx * 11 + wy * 7, 43) < 0.62 then
        WIN3[#WIN3 + 1] = {x = x, y = y, h = K.hash(wx + wy * 13, 44), k = K.hash(wx * 5 + wy, 45)}
      end
    end
  end
  -- the switchback road up the hill
  local ROAD = {{44, 53}, {72, 47}, {40, 41}, {66, 34}, {44, 27}, {62, 20}, {52, 13}}
  local PARTY_X, PARTY_Y = 40, 51

  ---------------------------------------------------------------- state
  local pump, pumps, lift                    -- the kick: cones out, eased, crowd lift
  local flex1, flex2                         -- each cone's flex (views 1, 2)
  local tz                                   -- where the tamborzao is in its walk
  local hands, ledb, horn, tweet, glint      -- snare hands, LED bar, horns, tweeters
  local lasers, rockets, sparks, phones
  local chase, chasen                        -- the ratchet's chase along the LED bar
  local rsched                               -- the ratchet's stutter through the cones
  local puffs                                -- air rings off the cones (view 2)
  local motos, shocks, beams3                -- view 3
  local twink, bloom, bars

  function M.init()
    pump, pumps, lift = 0, 0, 0
    flex1, flex2 = {}, {}
    for i = 1, 18 do flex1[i] = 0 end
    for i = 1, 8 do flex2[i] = 0 end
    tz = 0
    hands, ledb, horn, tweet, glint = 0, 0, 0, 0, 0
    lasers, rockets, sparks, phones = {}, {}, {}, {}
    chase, chasen = -9, 0
    rsched = {}
    puffs = {}
    motos, shocks, beams3 = {}, {}, {}
    twink, bloom, bars = 0, 0, 0
  end
  M.clear = M.init

  ---------------------------------------------------------------- events
  local function rocket(v)
    if #rockets >= 4 then table.remove(rockets, 1) end
    local x = 8 + K.rnd() * 112
    rockets[#rockets + 1] = {x = x, y0 = K.at(HILL, x), x3 = 10 + K.rnd() * 90, t0 = K.T, v = v,
      top = 6 + K.rnd() * 10, seed = floor(K.rnd() * 999)}
  end

  -- the tamborzao's next hit: a cone flexes (both walls), a moto sets off
  local function drum(v)
    tz = tz + 1
    local i1 = TZ1[(tz - 1) % #TZ1 + 1]
    flex1[i1] = max(flex1[i1], v)
    local i2 = TZ2[(tz - 1) % #TZ2 + 1]
    flex2[i2] = max(flex2[i2], v)
    if #motos >= 6 then table.remove(motos, 1) end
    motos[#motos + 1] = {t0 = K.T, v = v, sp = 0.09 + K.rnd() * 0.05}
  end

  function M.kick(v)
    v = K.num(v, 1)
    pump = max(pump, v)
    lift = max(lift, v)
    bloom = max(bloom, v)
    if #puffs >= 6 then table.remove(puffs, 1) end
    puffs[#puffs + 1] = {t0 = K.T, v = v}
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    hands = max(hands, v)
    ledb = max(ledb, v)
    horn = max(horn, v)
    if #shocks >= 3 then table.remove(shocks, 1) end
    shocks[#shocks + 1] = {t0 = K.T, v = v}
  end
  function M.clap(v)
    v = K.num(v, 1)
    hands = max(hands, v)
    ledb = max(ledb, v * 0.8)
    horn = max(horn, v * 0.7)
  end
  function M.rim(v)
    v = K.num(v, 1)
    ledb = max(ledb, v * 0.5)
    tweet = max(tweet, v * 0.6)
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    twink = max(twink, v)
    tweet = max(tweet, v * (open and 1 or 0.6))
    if open then
      glint = max(glint, v)
      if #lasers >= 3 then table.remove(lasers, 1) end
      lasers[#lasers + 1] = {t0 = K.T, v = v, dir = K.rnd() < 0.5 and -1 or 1, a0 = -PI / 2 + (K.rnd() - 0.5) * 0.8}
      if #beams3 >= 3 then table.remove(beams3, 1) end
      beams3[#beams3 + 1] = {t0 = K.T, v = v, a = -PI / 2 + (K.rnd() - 0.5) * 1.1}
    end
  end
  function M.ride(v) M.hat(K.num(v, 1) * 0.8, true) end
  function M.shaker(v) twink = max(twink, K.num(v, 1) * 0.7) end

  function M.perc(kind, v)
    kind = floor(K.num(kind, 1))
    v = K.num(v, 1)
    if kind == 3 or kind == 6 or kind == 21 then
      rocket(v)
    elseif kind == 20 or kind <= 2 or kind == 13 or kind == 17 or kind == 18 then
      drum(v)
    else
      drum(v * 0.6)
      tweet = max(tweet, v * 0.5)
    end
  end
  function M.tom(v) drum(K.num(v, 1)) end

  function M.tick()
    if #phones >= 6 then table.remove(phones, 1) end
    phones[#phones + 1] = {i = 1 + floor(K.rnd() * NCROWD), t0 = K.T}
  end

  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 16)
    chase, chasen = K.T, n
    -- the wall stutters: that many cones pop one after another across it,
    -- and the windows round the party flicker with it
    local r0 = floor(K.rnd() * 3)
    for q = 0, n - 1 do
      if #rsched < 16 then rsched[#rsched + 1] = {at = K.T + q * 0.05, i = r0 * 6 + q % 6 + 1, j = q % 8 + 1} end
    end
  end

  function M.fill()
    rocket(1); rocket(0.8)
    ledb = 1
  end

  function M.bar() bars = bars + 1 end

  ---------------------------------------------------------------- shared update
  local function update()
    local DT = K.DT
    for k = #rsched, 1, -1 do
      local R = rsched[k]
      if K.T >= R.at then
        flex1[R.i] = 1; flex2[R.j] = 1
        ledb = max(ledb, 0.7); bloom = max(bloom, 0.5)
        table.remove(rsched, k)
      end
    end
    pump = pump * exp(-DT / 0.12)
    pumps = K.follow(pumps, pump, 0.03, DT)
    lift = lift * exp(-DT / 0.2)
    for i = 1, 18 do flex1[i] = flex1[i] * exp(-DT / 0.15) end
    for i = 1, 8 do flex2[i] = flex2[i] * exp(-DT / 0.15) end
    hands = hands * exp(-DT / 0.35)
    ledb = ledb * exp(-DT / 0.2)
    horn = horn * exp(-DT / 0.2)
    tweet = tweet * exp(-DT / 0.1)
    glint = glint * exp(-DT / 0.4)
    twink = twink * exp(-DT / 0.12)
    bloom = bloom * exp(-DT / 0.3)
  end

  -- fireworks: rockets up, bursting into a ring of falling sparks
  -- (xf, basef: where a rocket goes up from, if not its own spot)
  local function fireworks(xf, basef)
    local T = K.T
    for k = #rockets, 1, -1 do
      local R = rockets[k]
      local age = T - R.t0
      local x = xf and xf(R) or R.x
      local base = basef and basef(R) or R.y0
      if age > 2.2 then table.remove(rockets, k)
      elseif age < 0.6 then
        local u = age / 0.6
        local y = base - (base - R.top) * (1 - (1 - u) ^ 2)
        put(6 + 4 * R.v, x, y, 1, 2)
        put(2, x, y + 2, 1, 2)
      else
        local u = (age - 0.6) / 1.6
        local r = 2 + u * 9 * (0.7 + 0.3 * R.v)
        local l = (2 + 9 * R.v) * (1 - u) ^ 1.5
        for s = 0, 9 do
          local a = s / 10 * K.TAU + R.seed
          put(l, x + cos(a) * r, R.top + sin(a) * r * 0.8 + u * u * 6, 1, 1)
        end
      end
    end
  end

  ---------------------------------------------------------------- view 1 draw
  local function cone_i(c, r) return r * 6 + c + 1 end

  local function draw1(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, hi, mid, am = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local pu = phrase_u(S)
    local pk = pumps * (1 - kl * 0.8)

    -- the sky: stars, the moon, a glow over the ridge from the city
    for i = 0, 16 do
      local x, y = floor(K.hash(i, 51) * 127), floor(K.hash(i, 52) * 18)
      if y < K.at(HILL, x) - 2 then
        put((1 + (0.5 + 0.5 * sin(T * (0.4 + K.hash(i, 53)) + i)) * (0.6 + hi * 2.5)), x, y, 1, 1)
      end
    end
    local mx, my = 18 + pu * 20, 7
    K.disc(2 + kl * 3 + am, mx, my, 3.2)
    K.ring(1 + kl * 2, mx, my, 5.5, 14)
    K.gradient(2, 30, function(y)
      local u = (y - 2) / 28
      return u * u * u * (0.5 + am * 0.8 + e * 0.4 + mid * 0.5)
    end, HILL)

    -- the morro: its ridge, the houses climbing it, windows lit (more as
    -- the phrase goes on), the walls warm with the mids
    local ridge = 1.5 + am + e * 0.5
    for x = 0, 126, 2 do line(ridge, x, K.at(HILL, x), x + 2, K.at(HILL, x + 2)) end
    local frac = 0.2 + 0.3 * e + 0.25 * pu + 0.15 * am
    local jit = c > 0.4 and (c - 0.4) * 2.5 or 0
    for i = 1, NH do
      local H = HOUSES[i]
      if H then
        local dx = jit > 0 and floor(jit * sin(T * 4.1 + i * 1.7) + 0.5) or 0
        local x, y = H.x + dx, H.y
        line(1.2 + mid * 0.8 + e * 0.3, x, y, x + H.w - 1, y)            -- the roof slab
        line(1, x, y, x, y + 4)
        if H.tank then put(1.5 + am, x + 1, y - 2, 2, 2) end            -- the water tank
        local lit = K.hash(i, 61 + bars % 4) < frac
        if lit then
          local tw = K.hash(i + floor(T * 7), 62) < twink * 0.3 and 4 or 0
          put(2.5 + K.hash(i, 63) * 2.5 + mid * 1.5 + tw, x + 2, y + 2, 2, 1)
        end
        if K.hash(i, 64) < frac * 0.5 then put(2 + mid, x + H.w - 2, y + 2, 1, 1) end
      end
    end
    -- kickless: mist down over the morro
    if kl > 0.05 then K.haze(0, 14, 128, 44, 0.4 * kl, 1, T * 4) end

    -- the lasers (open hats), fanning up from the top of the stack
    for k = #lasers, 1, -1 do
      local L = lasers[k]
      local age = T - L.t0
      if age > 1.4 then table.remove(lasers, k)
      else
        local f = min(1, age / 0.1) * min(1, (1.4 - age) / 0.5)
        for b = -2, 2 do
          local a = L.a0 + L.dir * age * 0.6 + b * (0.18 + c * 0.15 * sin(T * 5 + b))
          local l = (1.5 + 3 * L.v + hi * 2) * f * (1 - abs(b) * 0.15)
          line(l, 64, PY0 - 2, 64 + cos(a) * 80, PY0 - 2 + sin(a) * 80)
        end
      end
    end
    fireworks()

    -- the paredao: the stage glow behind, the boxes, the cones
    local sh = c > 0.5 and floor((c - 0.5) * 3 * sin(T * 6.3) + 0.5) or 0
    -- (the stack's breath: mist puffing off the top with the lows)
    K.haze(PX0 - 6, PY0 - 9, PX1 + 6, PY0 - 3, 0.25 + pk * 0.4 + lo * 0.2, 1 + pk, K.T * 8)
    for col = 0, 6 do
      local x = PX0 + col * CWD + sh
      line(2 + am, x, PY0, x, PY1)
    end
    line(2.5 + am, PX0 + sh, PY0, PX1 + sh, PY0)
    line(2.5 + am, PX0 + sh, PY1, PX1 + sh, PY1)
    for r = 0, 2 do
      for col = 0, 5 do
        local i = cone_i(col, r)
        local x = PX0 + (col + 0.5) * CWD + sh
        local y = PY0 + (r + 0.5) * CHT
        local f = min(1.2, pk * (0.7 + 0.3 * (r == 2 and 1 or 0)) + flex1[i] + lo * 0.25)
        K.ring(2 + f * 4 + mid, x, y, 2.6 + f * 1.1, 8)
        put(min(12, 2 + f * 8), x - 0.5, y - 0.5, 2, 2)
      end
    end
    if c > 0.5 then K.ring(1.5 * c, 64 - sh * 2, (PY0 + PY1) / 2, 30, 24, PI, K.TAU, 0.5) end
    -- the LED bar along the top: snares light it, a ratchet chases it,
    -- the mids glow it
    for s = 0, 12 do
      local x = PX0 + s * 4 + sh
      local cl = 0
      if T - chase < chasen * 0.06 then
        local p = floor((T - chase) / 0.06)
        if p % 13 == s then cl = 8 end
      end
      local lv = 1.5 + ledb * 8 * (0.6 + 0.4 * K.hash(s + floor(T * 8), 71)) + mid * 2 + cl
        + ((s == floor(pu * 13)) and 2 or 0) + 1.5 * max(0, sin(s * 0.7 - T * 4))
      put(min(12, lv), x, PY0 - 3, 3, 2)
    end
    -- the stage and the ground glowing with the lows
    line(2 + lo * 2 + pk * 2, 0, GROUND, 127, GROUND)
    for y = GROUND + 2, 62, 3 do
      K.dashes((1 + lo + pk * 2) * (1 - (y - GROUND) / 14), y, 3, 9, y * 5 + floor(K.T * 3), 24, 104)
    end

    -- the crowd: heads and shoulders against the glow, bouncing on the kick
    -- (swaying kickless), hands up on the snares, phones on the ticks
    local n = floor(10 + e * 12)
    for k = 1, min(n, NCROWD) do
      local x = 2 + (k - 1) * 5.8 + floor(K.hash(k, 81) * 3)
      local ph = K.hash(k, 82)
      local bob = floor(lift * (0.5 + ph) * 1.5 + 0.5)
      if kl > 0.3 then bob = floor(sin(T * 2 + ph * 6) * kl + 0.5) end
      local y = 55 + floor(ph * 3) - bob
      local rim = 1.5 + pk * 1.5 + am
      put(rim, x, y, 3, 3)                            -- the head, lit from the stage
      put(1.2 + am * 0.5, x - 1, y + 4, 5, 3)          -- the shoulders
      if hands > 0.3 and K.hash(k, 83 + bars % 3) < 0.6 then
        local hu = hands * 6
        line(rim + hands * 2, x - 1, y + 3, x - 2, y + 3 - hu)
        line(rim + hands * 2, x + 3, y + 3, x + 4, y + 3 - hu)
      end
    end
    for k = #phones, 1, -1 do
      local P = phones[k]
      local age = T - P.t0
      if age > 1.2 then table.remove(phones, k)
      else
        local x = 2 + (P.i - 1) * 5.8 + 1
        put(4 + 4 * (1 - age / 1.2), x, 50, 2, 2)
      end
    end
    K.grain(function(u, v) return PX0 + u * (PX1 - PX0), PY0 - 10 + v * 10 end, 6 + hi * 12 + e * 4, 3 + hi * 4)
  end

  ---------------------------------------------------------------- view 2 draw
  local function draw2(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, hi, mid, am = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local pu = phrase_u(S)
    local pk = pumps * (1 - kl * 0.8)
    local sh = 0

    -- the boxes: their seams (the wall's grid), the cabinets' edges
    for col = 0, 4 do
      local x = 1 + col * 31 + sh
      line(2 + am, x, 15, x, 62)
    end
    -- the horns along the top: flared mouths, their throats glinting
    for h = 0, 4 do
      local x = 13 + h * 25 + sh
      local fl = horn * (0.6 + 0.4 * K.hash(h + floor(T * 10), 91))
      local l = 1.3 + fl * 4 + mid * 0.5
      line(l, x - 10, 2, x - 3, 9)
      line(l, x + 10, 2, x + 3, 9)
      put(l * 0.8, x - 10, 2, 2, 2); put(l * 0.8, x + 9, 2, 2, 2)
      local tl = 1.5 + tweet * 7 + hi * 1.5 + glint * 3 * (0.5 + 0.5 * sin(T * 9 + h))
      put(min(12, tl), x - 1, 6, 3, 4)
      if glint > 0.2 then line(glint * 5, x, 4, x, 12) end
    end
    -- the LED strips: they chase on a ratchet, fill with the phrase, the
    -- snare lights them, the mids glow them
    for st = 0, 1 do
      local y = 13 + st * 26
      if st == 1 then y = 39 end
      for s = 0, 30 do
        local x = 2 + s * 4 + sh
        local cl = 0
        if T - chase < chasen * 0.06 then
          local p = floor((T - chase) / 0.06 * 3)
          if abs(p % 31 - s) < 2 then cl = 7 end
        end
        local meter = (s / 30 < pu) and 1.5 or 0
        local lv = 1 + meter * 0.8 + ledb * 4 * K.hash(s + st * 40 + floor(T * 6), 92) + mid * 0.7 + cl
          + 1.2 * max(0, sin(s * 0.4 + st * 2 - T * 3))
        put(min(12, lv), x, y - 1, 2, 2)
      end
    end
    -- the woofers: surround, cone, dust cap; the kick pushes them out (the
    -- bottom row a beat behind), the tamborzao flexes them one by one,
    -- the lows bulge them; air rings off them on the kick
    for i, W in ipairs(W2) do
      local row = i > 4 and 1 or 0
      local lagk = row == 1 and pump * 0.6 + pk * 0.4 or pk
      local f = min(1, lagk * 0.8 + flex2[i] + lo * 0.2)
      local jx = c > 0.5 and floor((c - 0.5) * 2.5 * sin(T * 2.3 + i * 1.9) + 0.5) or 0
      local x, y = W.x + jx, W.y
      K.ring(1.2 + am * 0.3 + f * 0.5, x, y, W.r, 18)
      K.ring(1.1 + f * 2 + mid * 0.3, x, y, 6, 14)
      K.disc(min(12, 2 + f * 7), x, y, 2)
      -- the box's screws
    end
    for k = #puffs, 1, -1 do
      local P = puffs[k]
      local u = (T - P.t0) / 0.45
      if u >= 1 then table.remove(puffs, k)
      else
        for i = 1, 4 do
          local W = W2[i + (k % 2) * 4]
          K.ring((0.8 + P.v * 1.2) * (1 - u) * (1 - kl * 0.8), W.x + sh, W.y, W.r + 1 + u * 4, 16)
        end
      end
    end
    -- the floor in front: the stage lip, the lows shaking it
    K.dashes(1 + lo + pk * 2, 63, 4, 6, 0, 0, 128)
    -- chaos: the stack judders, a ghost of the wall beside it
    if c > 0.5 then
      for i = 1, 8 do
        local W = W2[i]
        K.ring(1.2 * c, W.x + 2 * sin(T * 0.9 + i), W.y + 1, W.r + 2, 12)
      end
    end
    K.grain(function(u, v) return u * 128, v * 64 end, 8 + hi * 8 + e * 3, 3 + hi * 3)
  end

  ---------------------------------------------------------------- view 3 draw
  -- a point along the road, 0..1 from the bottom
  local RLEN = {}
  do
    local tot = 0
    RLEN[1] = 0
    for i = 2, #ROAD do
      tot = tot + sqrt((ROAD[i][1] - ROAD[i - 1][1]) ^ 2 + (ROAD[i][2] - ROAD[i - 1][2]) ^ 2)
      RLEN[i] = tot
    end
    for i = 1, #ROAD do RLEN[i] = RLEN[i] / tot end
  end
  local function road_at(u)
    u = clamp(u, 0, 1)
    for i = 2, #ROAD do
      if u <= RLEN[i] then
        local f = (u - RLEN[i - 1]) / max(1e-6, RLEN[i] - RLEN[i - 1])
        return ROAD[i - 1][1] + (ROAD[i][1] - ROAD[i - 1][1]) * f, ROAD[i - 1][2] + (ROAD[i][2] - ROAD[i - 1][2]) * f
      end
    end
    return ROAD[#ROAD][1], ROAD[#ROAD][2]
  end

  local function draw3(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, hi, mid, am = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local pu = phrase_u(S)
    local bl = bloom * (1 - kl * 0.7)

    -- the sky: stars, the moon over the bay, the city's glow low down
    for i = 0, 18 do
      local x, y = floor(K.hash(i, 151) * 127), floor(K.hash(i, 152) * 26)
      if y < K.at(MORRO, x) - 2 and y < K.at(LOAF, x) - 2 then
        put(1 + (0.5 + 0.5 * sin(T * (0.3 + K.hash(i, 153)) + i)) * (0.5 + hi * 2.5), x, y, 1, 1)
      end
    end
    K.disc(2 + kl * 3 + am, 104, 8, 2.6)
    -- the sugarloaf out in the bay, its cable car's lamp crossing
    for x = 104, 127, 2 do line(1.5 + am * 0.5, x, K.at(LOAF, x), x + 2, K.at(LOAF, x + 2)) end
    local cu = (T * 0.04) % 1
    line(1, 98, 40, 116, 22)
    put(2.5 + mid * 2, 98 + cu * 18, 40 - cu * 18, 1, 1)

    -- the morro: its ridge, then the windows: each house a light, twinkling
    -- with the hats, fuller as the phrase goes on; the kick pulses the ones
    -- round the party, the snare's ring of light runs out over them
    for x = 0, 100, 2 do line(1.5 + am, x, K.at(MORRO, x), x + 2, K.at(MORRO, x + 2)) end
    local frac = 0.35 + 0.3 * e + 0.2 * pu + 0.15 * am
    local twk = floor(T * 7)
    for i = 1, #WIN3 do
      local W = WIN3[i]
      if W.h < frac then
        local dx, dy = W.x - PARTY_X, (W.y - PARTY_Y) * 1.6
        local d = sqrt(dx * dx + dy * dy)
        local l = 1.6 + W.k * 3 + mid * 0.8
        l = l + bl * 4 * max(0, 1 - d / 22)
        for _, sk in ipairs(shocks) do
          local front = (T - sk.t0) * 60
          local w = abs(d - front)
          if w < 4 then l = l + sk.v * 5 * (1 - w / 4) * max(0, 1 - front / 90) end
        end
        if K.hash(i + twk * 3, 154) < twink * 0.15 then l = l + 4 end
        if c > 0.5 and K.hash(i + floor(T * 3), 155) < (c - 0.5) * 0.3 then l = 0.5 end
        put(min(12, l), W.x, W.y, 1, 1)
      end
    end
    for k = #shocks, 1, -1 do if T - shocks[k].t0 > 1.5 then table.remove(shocks, k) end end
    -- the road up the hill, faint, and the motos climbing it
    for q = 0, 60 do
      local x, y = road_at(q / 60)
      if q % 2 == 0 then put(1 + mid * 0.8 + am * 0.4, x, y, 1, 1) end
    end
    for k = #motos, 1, -1 do
      local Mo = motos[k]
      local u = (T - Mo.t0) * Mo.sp * (1 + e * 0.5) * (1 - kl * 0.4)
      if u >= 1 then table.remove(motos, k)
      else
        local x, y = road_at(u)
        put(min(12, 5 + 5 * Mo.v), x, y - 1, 2, 1)
        local x2, y2 = road_at(max(0, u - 0.03))
        line(2 + 2 * Mo.v, x2, y2 - 1, x, y - 1)
      end
    end
    -- kickless: mist over the morro
    if kl > 0.05 then K.haze(0, 10, 100, 52, 0.35 * kl, 1, T * 3) end

    -- the party at the foot: a glowing pocket, beams up from it
    for k = #beams3, 1, -1 do
      local B = beams3[k]
      local age = T - B.t0
      if age > 1.5 then table.remove(beams3, k)
      else
        local f = min(1, age / 0.1) * min(1, (1.5 - age) / 0.6)
        local a = B.a + sin(age * 2) * 0.3 + (c > 0.4 and c * 0.3 * sin(T * 4 + k) or 0)
        line((2 + 3 * B.v + hi * 2) * f, PARTY_X, PARTY_Y - 2, PARTY_X + cos(a) * 60, PARTY_Y - 2 + sin(a) * 60)
      end
    end
    local pr = 3 + bl * 3 + lo * 2
    K.disc(min(10, 2 + bl * 6 + lo * 2 + am), PARTY_X, PARTY_Y, 1.8 + bl)
    K.ring(1.5 + bl * 3 + lo, PARTY_X, PARTY_Y, pr, 14, 0, K.TAU, 0.6)
    K.ring(1 + bl * 1.5, PARTY_X, PARTY_Y, pr + 4, 16, 0, K.TAU, 0.6)
    fireworks(function(R) return R.x3 end, function(R) return K.at(MORRO, R.x3) end)

    -- the bay: the shore lights and the hill's glow doubled, broken by water
    line(1.5 + lo + bl, 0, BAY, 127, BAY)
    for y = BAY + 2, 63, 2 do
      local d = y - BAY
      local ox = floor((0.6 + lo * 1.5 + c * 2) * sin(y * 0.9 + T * 2.1) + 0.5)
      for x = 4, 100, 8 do
        put((1 + am + bl * 2 * max(0, 1 - abs(x - PARTY_X) / 20)) * (1 - d / 11), x + ox, y, 2, 1)
      end
      put(max(0, (2 + bl * 6 + lo * 2) * (1 - d / 11)), PARTY_X - 1 + ox, y, 3, 1)
      if (y // 2) % 2 == 0 then K.dashes(1 + hi * 2, y, 2, 13, T * 5 + y * 3, 100, 128) end
    end
    K.grain(function(u, v) return u * 100, 10 + v * 44 end, 6 + hi * 12 + e * 4, 3 + hi * 4)
  end

  function M.draw(S)
    update()
    if K.view == 2 then draw2(S)
    elseif K.view == 3 then draw3(S)
    else draw1(S) end
  end

  M.init()
  return M
end
