-- rave. view 1: a warehouse rave from the back of the crowd, laser fans
-- sweeping out of the booth through the smoke over a crowd in silhouette;
-- view 2: flying down a tunnel of rotating wireframe polygons; view 3: a free
-- party in a field at night, the rig on the skyline, the crowd nothing but
-- glowsticks whirling in the dark.
--
-- view 1: the roof's trusses hang faint in the smoke; the booth's glow
-- lights the haze from behind so the crowd stands black against it, heads
-- bobbing on the beat. a fan of laser beams sweeps out of the emitter over
-- the booth: the kick flares the beams and snaps the fan open, the snare
-- and the breaks throw hands up through the crowd and kick the fan to a
-- new angle, congas and bongos throw hands up too; closed hats glint along
-- the beams, an open hat drops a flat sheet of light down over the room;
-- bells, metal and ticks blink the truss lamps, a ratchet fires a quick
-- rake of extra beams. the fan swings to the other side every bar and
-- gains beams through the phrase. energy adds beams and thickens the smoke;
-- chaos multiplies the emitters and scatters their beams. kickless the
-- lasers lie down into a slow flat sheet over the heads and the crowd sways
-- with its hands low.
-- view 2: polygons of light come at you down a curving tunnel, joined at
-- their corners into a wireframe. the kick surges you forward and spins
-- the rings, the snare sends a bright ring racing away down the tunnel and
-- flips the twist, closed hats spark the corners, an open hat throws a ring
-- of sparks out from the centre, breaks jolt the spin; each bar adds or
-- drops a side and the phrase tightens the twist. energy adds sides and
-- speed, chaos jitters the corners and doubles the rings at odd angles;
-- kickless the tunnel rounds out into slow smooth circles.
-- view 3: three rows of dancers, far to near, each a pair of glowsticks
-- turning circles with a trail behind them. the kick bounces every stick
-- and brightens it, the snare reverses the circles, a clap throws the near
-- row's hands up, closed hats glint the stick tips, an open hat swings a
-- whole row wide, perc cracks a fresh stick bright, a ratchet spins one
-- dancer in a fast full circle, a fill sends a wave of raised sticks across
-- the crowd. the rig glows on the skyline under the stars and its
-- searchlight sweeps the clouds once a bar; the crowd fills in through the
-- phrase. energy brings more dancers and bigger circles, chaos throws
-- sticks spinning into the air, kickless the sticks sway slow and low.
--
-- the ears: the lows light the booth, the rig and the tunnel's far glow;
-- the mids light the smoke and the clouds and flex the tunnel walls; the
-- highs glint the beams, the stars and the stick tips; the level widens the
-- light at the end of the tunnel and lights the rig.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, exp = math.sin, math.cos, math.floor, math.max, math.min,
    math.abs, math.exp

  local function phrase(S)
    local pl = K.num(S.phrase_len, 16)
    if not (pl >= 1 and pl < 1e4) then pl = 16 end
    local pp = K.num(S.phrase_pos, 0)
    if not (pp >= 0 and pp < 1e4) then pp = 0 end
    return clamp((pp + K.bar_ph) / pl, 0, 1)
  end
  local side_s = 0

  ------------------------------------------------------------------
  -- view 1 state
  ------------------------------------------------------------------
  local EX, EY = 64, 37                -- the emitter over the booth
  local NP = 15                        -- heads in the crowd
  local PEOPLE = {}
  for i = 1, NP do
    -- near people stand big and high, far ones small and low
    local near = K.hash(i, 5)
    PEOPLE[i] = {x = 1 + (i - 1) * 9 + (K.hash(i, 1) - 0.5) * 5,
      y = 51 - near * 5 + K.hash(i, 2) * 2, r = 2.4 + near * 2.6,
      ph = K.hash(i, 4) * 6.28}
  end
  local prof = {}
  local hands, hands_to
  local flare, fan_open, base_to, base, sweep_ph, spin
  local flare_to, open_to
  local rake                            -- ratchet: extra beams {t0, a}
  local glints
  local lamps                           -- the truss lamps

  ------------------------------------------------------------------
  -- view 2 state
  ------------------------------------------------------------------
  local NR = 9
  local DZ = 0.8
  local travel, speed_k, rot, rotv, twist_dir
  local surge_to, rotv_to
  local twist_c = 1
  local races                           -- snare rings racing away {t0, v}
  local spark
  local bursts                          -- open hats: rings of sparks out of the centre

  local scans                           -- view 1: open hats' sheets of light
  local side                            -- the fan's side, flipped every bar
  local side_ext                        -- view 2: sides added / dropped per bar

  ------------------------------------------------------------------
  -- view 3 state: the field
  ------------------------------------------------------------------
  local ROWS = {{y = 33, n = 14, r = 1.6, len = 1.5, sh = 1.2, l = 3},
    {y = 43, n = 10, r = 3, len = 2.5, sh = 2.2, l = 5},
    {y = 55, n = 6, r = 6, len = 5, sh = 4, l = 7}}
  local DANCERS = {}
  for ri, R in ipairs(ROWS) do
    for k = 1, R.n do
      local i = #DANCERS + 1
      DANCERS[i] = {row = ri, x = (k - 0.5) / R.n * 128 + (K.hash(i, 401) - 0.5) * 6,
        ph = K.hash(i, 402) * 6.28, sp = 0.8 + K.hash(i, 403) * 0.5, order = K.hash(i, 404)}
    end
  end
  local STARS = {}
  for i = 1, 26 do STARS[i] = {x = K.hash(i, 411) * 128, y = K.hash(i, 412) * 22, h = K.hash(i, 413)} end
  local fdir, fdir_s, bounce, raise, wide, spin_i, spin_t, cracks, wave_t, thrown, rotf

  function M.init()
    hands, hands_to = {}, {}
    for i = 1, NP do hands[i], hands_to[i] = 0, 0 end
    for x = 0, 127 do prof[x] = 64 end
    flare, fan_open, base_to, base, sweep_ph, spin = 0, 0, 0, 0, 0, 0
    flare_to, open_to = 0, 0
    rake, glints = {}, {}
    lamps = {0, 0, 0, 0, 0}
    travel, speed_k, rot, rotv, twist_dir = 0, 0, 0, 0, 1
    surge_to, rotv_to, twist_c = 0, 0, 1
    races = {}
    spark = 0
    bursts, scans, side, side_ext = {}, {}, 1, 0
    fdir, fdir_s, bounce, raise, wide = 1, 1, 0, 0, {0, 0, 0}
    spin_i, spin_t, cracks, wave_t, thrown, rotf = 1, -9, {}, -9, {}, {}
    for i = 1, #DANCERS do rotf[i] = DANCERS[i].ph end
  end
  M.clear = M.init

  ------------------------------------------------------------------
  -- the hits
  ------------------------------------------------------------------
  local function throw_hands(n, v)
    for _ = 1, n do
      local i = 1 + math.floor(K.rnd() * NP)
      hands_to[i] = math.max(hands_to[i], 0.6 + 0.4 * v)
    end
  end

  function M.kick(v)
    v = K.num(v, 1)
    flare_to = math.max(flare_to, v)
    open_to = math.min(1.2, open_to + 0.4 * v)
    surge_to = surge_to + 2 * v
    rotv_to = rotv_to + 1.2 * v * twist_dir
    bounce = math.max(bounce, v)
  end

  function M.snare(v)
    v = K.num(v, 1)
    throw_hands(3 + math.floor((K.energy + v) * 3), v)
    base_to = base_to + (K.rnd() < 0.5 and -1 or 1) * (0.1 + 0.12 * K.rnd())
    twist_dir = -twist_dir
    fdir = -fdir
    if #races >= 5 then table.remove(races, 1) end
    races[#races + 1] = {t0 = K.T, v = v}
  end
  function M.clap(v)
    v = K.num(v, 1)
    throw_hands(2, v * 0.8)
    raise = math.max(raise, v)
    if #races >= 5 then table.remove(races, 1) end
    races[#races + 1] = {t0 = K.T, v = v * 0.6}
  end
  function M.rim(v) lamps[1 + math.floor(K.rnd() * 5)] = K.num(v, 1) end

  function M.hat(v, open)
    v = K.num(v, 1)
    if #glints >= 8 then table.remove(glints, 1) end
    glints[#glints + 1] = {t0 = K.T, k = K.rnd(), u = 0.25 + K.rnd() * 0.6, v = v}
    if open then
      open_to = math.min(1.2, open_to + 0.2)
      if #scans >= 3 then table.remove(scans, 1) end
      scans[#scans + 1] = {t0 = K.T, v = v, dir = K.rnd() < 0.5 and -1 or 1}
      if #bursts >= 4 then table.remove(bursts, 1) end
      bursts[#bursts + 1] = {t0 = K.T, v = v, a = K.rnd() * 6.28}
      local r = 1 + math.floor(K.rnd() * 3)
      wide[r] = math.max(wide[r], v)
    end
    spark = math.max(spark, open and 1 or 0.6 * v)
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    kind = math.floor(K.num(kind, 1))
    if kind == 1 or kind == 2 or kind == 13 or kind == 17 then throw_hands(2, v * 0.7)
    else lamps[1 + math.floor(K.rnd() * 5)] = v end
    if #cracks >= 4 then table.remove(cracks, 1) end
    cracks[#cracks + 1] = {i = 1 + math.floor(K.rnd() * #DANCERS), t0 = K.T, v = v}
  end
  function M.tick() lamps[1 + math.floor(K.rnd() * 5)] = 0.6 end

  function M.brk(s, n, rev)
    s, n = K.num(s, 1), math.max(1, K.num(n, 8))
    if s % 4 == 1 then
      throw_hands(2, 0.7)
      base_to = base_to + (rev and -0.08 or 0.08)
    end
    rotv_to = rotv_to + (rev and -0.15 or 0.15)
  end

  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 10)
    local a0 = -math.pi / 2 + (K.rnd() - 0.5) * 1.6
    for k = 1, n do
      if #rake >= 10 then table.remove(rake, 1) end
      rake[#rake + 1] = {t0 = K.T + k * 0.03, a = a0 + (k - n / 2) * 0.09}
    end
    surge_to = surge_to + 0.3 * n
    spin_i, spin_t = #DANCERS - math.floor(K.rnd() * ROWS[3].n), K.T
  end

  function M.fill() spin = 1; wave_t = K.T end

  function M.bar()
    side = -side
    side_ext = (side_ext + 1) % 3
    if K.chaos > 0.4 then
      for _ = 1, math.floor(K.chaos * 3) do
        if #thrown >= 4 then table.remove(thrown, 1) end
        thrown[#thrown + 1] = {x = 10 + K.rnd() * 108, t0 = K.T, vx = (K.rnd() - 0.5) * 30, w = (K.rnd() - 0.5) * 20}
      end
    end
  end

  ------------------------------------------------------------------
  -- view 1: the warehouse
  ------------------------------------------------------------------
  -- a beam from (x, y) at angle a, fading as it runs out through the smoke
  local function beam(lv, x, y, a, len)
    local ca, sa = math.cos(a), math.sin(a)
    local x1, y1 = x + ca * len * 0.3, y + sa * len * 0.3
    line(lv, x, y, x1, y1)
    -- further out the beam breaks up in the smoke: dashes, drifting outward
    local off = 0
    for d = len * 0.3 + off, len - 4, 8 do
      line(lv * 0.45, x + ca * d, y + sa * d, x + ca * (d + 4), y + sa * (d + 4))
    end
  end

  local function fan(lv, x, y, nb, mid, span, len)
    for b = 0, nb - 1 do
      local a = mid + (nb > 1 and (b / (nb - 1) - 0.5) or 0) * span
      beam(lv, x, y, a, len)
    end
  end

  -- one row of the glow, lit only above the crowd (per pixel)
  local function glow_row(l, y, x0, x1)
    local run
    for x = x0, x1 - 1 do
      if y < prof[x] then run = run or x
      elseif run then put(l, run, y, x - run, 1); run = nil end
    end
    if run then put(l, run, y, x1 - run, 1) end
  end
  local TH8 = {0, 4, 2, 6, 1, 5, 3, 7}
  local function glow(y0, y1, lv, x0, x1)
    for y = y0, y1 do
      local v = lv(y)
      if v == v and v > 0.05 then
        local th = (TH8[y % 8 + 1] + 0.5) / 8
        local l
        if v < 1 then l = (v > th) and 1 or 0
        else
          l = math.floor(v)
          if v - l > th then l = l + 1 end
        end
        if l > 0 then glow_row(l, y, x0, x1) end
      end
    end
  end

  local function warehouse(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless

    -- the crowd's profile (a top y per pixel column): heads bob on the
    -- beat, arms go up in a V
    for x = 0, 127 do prof[x] = 56 + math.sin(x * 0.35) * 0.8 end
    local nod = (1 - K.beat_ph) ^ 3 * (1 - kl * 0.6) * (0.6 + e * 0.6)
    for i = 1, NP do
      local P = PEOPLE[i]
      local sway = kl * math.sin(T * 1.3 + P.ph) * 2.5
      local hx = P.x + sway
      local hy = P.y + nod * 1.6 * (0.6 + 0.4 * math.sin(P.ph)) + lo * 0.8
      local r = P.r
      local hu = hands[i] * (1 - kl * 0.5)
      local reach = r * 2.6
      if hu > 0.08 then reach = math.max(reach, r + 1.5 + 2.5 * hu) end
      for x = math.max(0, math.floor(hx - reach)), math.min(127, math.ceil(hx + reach)) do
        local dx = math.abs(x + 0.5 - hx)
        local top = 64
        if dx <= r then top = hy - math.sqrt(r * r - dx * dx)
        elseif dx <= r * 2.6 then top = hy + r + 0.8 + (dx - r) * 0.35 end
        -- arms: from the shoulder up and out to the hands
        if hu > 0.08 then
          local ax0, ax1 = r + 0.5, r + 1.5 + 2.5 * hu
          if dx >= ax0 and dx <= ax1 then
            local u = (dx - ax0) / math.max(0.5, ax1 - ax0)
            local ay = hy + r - u * (r + 1 + 7 * hu)
            if ay < top then top = ay end
          end
        end
        if top < prof[x] then prof[x] = top end
      end
    end

    -- the roof: trusses hanging in the dark, their lamps
    local tl = 1 + e * 0.5
    line(tl, 0, 3, 127, 3)
    line(tl, 0, 9, 127, 9)
    for k = 0, 8 do
      local x = k * 16
      line(tl * 0.8, x, 3, x + 8, 9)
      line(tl * 0.8, x + 8, 9, x + 16, 3)
    end
    for k = 1, 5 do
      put(1.5 + lamps[k] * 10, 8 + (k - 1) * 28, 10, 2, 2)
    end

    -- the smoke, lit faintly; the body of the mix (mid) lights it up and
    -- rolls it faster, a brighter bank in the middle of the room
    K.haze(0, 16, 128, 44, 0.12 + e * 0.12 + kl * 0.12 + hi * 0.08, 1 + md * 1.6 + hi * 1.2, T * (4 + md * 10))
    if md > 0.08 then K.haze(30, 22, 98, 38, 0.08 + md * 0.12, 1.5 + md * 2.5, -T * (6 + md * 8)) end

    -- the booth's glow, the crowd black against it
    local ph = phrase(S)
    local g = 0.8 + e * 0.6 + lo * 0.6 + flare * 0.4
    glow(44, 58, function(y) return g * (0.5 + (y - 44) / 18) end, 0, 128)
    glow(39, 58, function(y) return g * (1.2 + (y - 37) / 10) end, 28, 100)
    glow(37, 58, function(y) return g * (1.8 + (y - 37) / 7) end, 42, 86)
    -- the booth itself, over the heads in the middle
    line(3 + flare * 3 + md * 3, 50, 41, 78, 41)
    put(2 + hi * 3 + md * 2, 52, 42, 24, 1)

    -- the lasers
    local nb = clamp(math.floor(3 + e * 3 + ph * 2 + 0.5), 3, 8)
    side_s = K.follow(side_s, side, 1.2, DT)
    local len = 120
    -- the sweep: a slow swing, kicked to new angles by the snare
    base = K.follow(base, base_to, 0.4, DT)
    if base_to > 0.6 or base_to < -0.6 then base_to = base_to * 0.4 end
    sweep_ph = sweep_ph + (0.45 + e * 0.4 + spin) * K.DTS
    local mid = -math.pi / 2 + clamp(math.sin(sweep_ph) * 0.15 + base + side_s * 0.15, -0.75, 0.75)
    local span = 0.45 + 0.45 * e + fan_open * 0.4 + 0.12 * math.sin(T * 0.37)
    local lv = 2.5 + e + flare * 2 + hi * 1.2
    if kl > 0.05 then
      -- kickless: the fan lies down into a flat sheet over the heads
      mid = mid * (1 - kl) + (-math.pi / 2) * kl
      span = span * (1 - kl) + 3.0 * kl
      lv = lv * (1 - kl * 0.35)
    end
    if kl > 0.5 then
      -- the sheet: beams near horizontal, slowly rolling
      local nsh = nb + 4
      local tx0, ty0
      for b = 0, nsh - 1 do
        local u = b / (nsh - 1)
        local xx = -12 + u * 152
        local yy = 16 + math.sin(xx * 0.045 + T * 0.7) * 3 + math.abs(u - 0.5) * 8
        line(lv * 0.5, EX, EY, xx, yy)
        if tx0 then line(lv * 0.9, tx0, ty0, xx, yy) end
        tx0, ty0 = xx, yy
      end
    else
      fan(lv, EX, EY, nb, mid, span, len)
    end
    -- chaos: more emitters, beams scattered
    if c > 0.5 then
      local ne = c > 0.65 and 2 or 1
      for k = 1, ne do
        local ex = k == 1 and 20 or 108
        local m2 = -math.pi / 2 + math.sin(sweep_ph * (1.3 + k * 0.4) + k * 2) * 0.8
        local nb2 = 2 + math.floor(c * 1.5)
        for b = 0, nb2 - 1 do
          local a = m2 + (b / math.max(1, nb2 - 1) - 0.5) * (0.6 + c * 0.6)
            + math.sin(T * (0.3 + K.hash(b + k * 17, 9) * 0.8) + b * 2.3) * c * 0.45
          beam(lv * 0.45, ex, 30, a, len * 0.8)
        end
        put(4 + flare * 6, ex - 1, 29, 3, 2)
      end
    end
    -- open hats: a flat sheet of light sweeping down over the room
    for i = #scans, 1, -1 do
      local Sc = scans[i]
      local u = (T - Sc.t0) / 0.45
      if u >= 1 then table.remove(scans, i)
      else
        local a = -math.pi / 2 + Sc.dir * (1.25 - u * 0.25)
        local l = (3 + Sc.v * 5) * (1 - u)
        for k = -1, 1 do beam(l * (k == 0 and 1 or 0.6), EX, EY, a + k * 0.05 - Sc.dir * u * 0.4, len) end
      end
    end
    -- the ratchet's rake
    for i = #rake, 1, -1 do
      local R = rake[i]
      local u = (T - R.t0) / 0.35
      if u >= 1 then table.remove(rake, i)
      elseif u >= 0 then beam(7 * math.min(1, u * 4) * (1 - u), EX, EY, R.a, len) end
    end
    -- hat glints along the beams
    for i = #glints, 1, -1 do
      local G = glints[i]
      local u = (T - G.t0) / 0.25
      if u >= 1 then table.remove(glints, i)
      else
        local a = mid + (G.k - 0.5) * span
        local d = 20 + G.u * 50
        put((5 + 6 * G.v) * (1 - u), EX + math.cos(a) * d - 1, EY + math.sin(a) * d, 3, 1)
      end
    end
    -- the air (hi): sparks running out along the beams, glinting
    if hi > 0.05 and kl < 0.5 then
      local ns = math.floor(2 + hi * 8)
      for k = 1, ns do
        local u = (T * (0.4 + K.hash(k, 61) * 0.5) + K.hash(k, 62)) % 1
        local a = mid + (K.hash(k, 63) - 0.5) * span
        local d = 8 + u * 70
        put(hi * (4 + 5 * math.sin(math.pi * u)), EX + math.cos(a) * d - 1, EY + math.sin(a) * d, 3, 1)
      end
    end
    -- the emitter
    put(6 + flare * 7, EX - 1, EY - 1, 3, 2)
  end

  ------------------------------------------------------------------
  -- view 2: the tunnel
  ------------------------------------------------------------------
  local F = 26
  local px_, py_ = {}, {}
  local qx_, qy_ = {}, {}

  local function centre(z, T)
    return 64 + math.sin(T * 0.35 + z * 0.12) * z * 1.6, 32 + math.sin(T * 0.27 + z * 0.1 + 1) * z * 1.0
  end

  local function tunnel(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless

    local speed = (0.55 + e * 0.9 + lo * 0.4) * (1 - kl * 0.5) + speed_k
    travel = travel + speed * K.DTS
    rot = rot + ((0.25 + e * 0.35) * (1 - kl * 0.7) + rotv) * K.DTS
    local ph = phrase(S)
    local sides = clamp(math.floor(3 + e * 3 + c * 3 + 0.5) + side_ext - 1, 3, 9)
    if kl > 0.5 then sides = 12 end
    twist_c = K.follow(twist_c, twist_dir, 0.35, DT)
    local twist = (0.18 + c * 0.25 + ph * 0.12) * twist_c * (1 - kl)
    local fr = travel / DZ - math.floor(travel / DZ)
    local ring_i0 = math.floor(travel / DZ)

    -- the far glow at the vanishing point
    local fx, fy = centre(NR * DZ - 1.6, T)
    -- the light at the end: the level (amp) widens it, the air (hi) makes it shimmer
    K.disc(1 + hi * (1.5 + 0.5 * math.sin(T * 3)), fx, fy, 9 + e * 5 + lo * 2 + amp * 5)
    K.disc(1.6 + e * 0.8 + flare * 0.5, fx, fy, 4 + e * 2)
    put(3 + hi * 4, fx, fy, 1, 1)

    -- speed lines: streaks out from the centre
    -- the air (hi) brightens the streaks
    for i = 0, 13 do
      local a = K.hash(i, 41) * K.TAU + T * 0.05
      local u = (T * (0.5 + K.hash(i, 42)) * (0.6 + speed * 0.3) + K.hash(i, 43)) % 1
      local r0 = 6 + u * u * 70
      local r1 = r0 + 2 + u * 8 * (0.5 + speed * 0.3)
      line(1 + u * (2 + hi * 4), fx + math.cos(a) * r0, fy + math.sin(a) * r0 * 0.6,
        fx + math.cos(a) * r1, fy + math.sin(a) * r1 * 0.6)
    end

    -- open hats: a ring of sparks thrown out of the centre
    for i = #bursts, 1, -1 do
      local Bu = bursts[i]
      local u = (T - Bu.t0) / 0.6
      if u >= 1 then table.remove(bursts, i)
      else
        local r = 4 + u * u * 70
        for k = 0, 9 do
          local a = Bu.a + k * K.TAU / 10
          put((3 + Bu.v * 6) * (1 - u), fx + cos(a) * r, fy + sin(a) * r * 0.6, 1 + floor(u * 2), 1)
        end
      end
    end
    -- the rings, far to near; each joined to the one behind it
    local prevn = 0
    for k = NR, 1, -1 do
      local z = (k - fr) * DZ
      if z > 0.25 then
        local s = F / z
        local cx, cy = centre(z, T)
        local ang = rot + z * twist + (ring_i0 + k) * (c > 0.5 and 0.4 or 0)
        -- brightness: dim far, brightest mid, fading as it passes you
        local bell = math.exp(-((z - 2.2) / 1.6) ^ 2)
        local near = clamp((z - 0.25) / 0.9, 0, 1)
        local far = clamp((NR * DZ - z) / 1.5, 0, 1)
        local lv = (1 + bell * (4 + md * 3) + e * 1.5 + amp * 0.8) * near * (0.3 + 0.7 * far)
        -- the snare's rings racing away down the tunnel
        for _, R in ipairs(races) do
          local rz = 1.3 + (T - R.t0) * 7
          local d = math.abs(z - rz)
          if d < DZ then lv = lv + (1 - d / DZ) * 5 * R.v * clamp(1 - (T - R.t0) / 1.0, 0, 1) * clamp((T - R.t0) * 12, 0, 1) end
        end
        if flare > 0.05 and k <= 4 then lv = lv + flare * 3 * near end
        lv = math.min(lv, 11)
        local n = sides
        for j = 0, n - 1 do
          local a = ang + j / n * K.TAU
          local jr = 1
          if c > 0.2 then jr = 1 + (K.hash(j + (ring_i0 + k) * 13, 7) - 0.5) * c * 0.5 end
          -- the body of the mix (mid) flexes the walls in and out
          jr = jr * (1 + md * 0.12 * math.sin(j * 2.1 + k * 1.3 + T * 1.2))
          qx_[j] = cx + math.cos(a) * s * jr
          qy_[j] = cy + math.sin(a) * s * jr * 0.8
        end
        for j = 0, n - 1 do
          local j2 = (j + 1) % n
          line(lv, qx_[j], qy_[j], qx_[j2], qy_[j2])
          if prevn == n and kl < 0.5 then
            line(lv * 0.45, qx_[j], qy_[j], px_[j], py_[j])
          end
          if spark > 0.1 and lv > 3 then put(lv * 0.5 + spark * 6, qx_[j], qy_[j], 1, 1)
          end
        end
        -- chaos: a ghost of the ring at an odd angle
        if c > 0.45 and k % 2 == 0 then
          local ga = ang + 0.5 + c
          local gx0, gy0
          for j = 0, n do
            local a = ga + j / n * K.TAU
            local x, y = cx + math.cos(a) * s * 0.85, cy + math.sin(a) * s * 0.85 * 0.8
            if gx0 then line(lv * 0.5, gx0, gy0, x, y) end
            gx0, gy0 = x, y
          end
        end
        for j = 0, n - 1 do px_[j], py_[j] = qx_[j], qy_[j] end
        prevn = n
      end
    end
  end

  ------------------------------------------------------------------
  -- view 3: the field
  ------------------------------------------------------------------
  local HZ = 27                         -- the skyline
  local RIG = {{44, 6}, {50, 9}, {56, 9}, {72, 9}, {78, 9}, {84, 6}}   -- stacks: x, height

  local function field(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    local ph = phrase(S)
    bounce = bounce * exp(-DT / 0.15)
    raise = raise * exp(-DT / 0.4)
    for r = 1, 3 do wide[r] = wide[r] * exp(-DT / 0.5) end
    fdir_s = K.follow(fdir_s, fdir, 0.12, DT)

    -- stars, twinkling with the highs
    for i = 1, #STARS do
      local P = STARS[i]
      local tw = 0.5 + 0.5 * sin(T * (0.7 + P.h * 2) + i * 2.1)
      put(1 + P.h * 1.5 + tw * (0.6 + hi * 2.5), P.x, P.y, 1, 1)
    end
    -- the searchlight off the rig, sweeping the clouds once a bar
    local sa = -math.pi / 2 + sin(K.bar_ph * K.TAU) * 0.7
    local sl = 1.2 + md * 1.5 + e * 0.5
    for k = -1, 1 do
      local a = sa + k * 0.04
      line(sl * (k == 0 and 1 or 0.6), 64, HZ - 8, 64 + cos(a) * 60, HZ - 8 + sin(a) * 60)
    end
    local cx = 64 + cos(sa) * (HZ - 10) / max(0.3, -sin(sa))
    K.ring(1 + md * 1.5, clamp(cx, -10, 138), 3, 8 + md * 4, 14, 0, K.TAU, 0.3)
    K.ring(1 + md, clamp(cx, -10, 138), 3, 4 + md * 2, 10, 0, K.TAU, 0.3)
    K.haze(0, 0, 128, 10, 0.1 + md * 0.25, 1, T * 2)

    -- the skyline and the rig on it, glowing with the lows
    line(1.5, 0, HZ, 127, HZ)
    local rg = 1.2 + lo * 2.5 + amp * 1.2 + bounce * 1.5
    for y = HZ - 6, HZ - 1 do
      local w = 30 + (y - HZ + 6) * 6
      put(min(4, rg * (0.3 + (y - HZ + 6) / 10)), 64 - w / 2, y, w, 1)
    end
    for _, R in ipairs(RIG) do
      line(1, R[1], HZ - R[2], R[1], HZ - 1)
      line(1, R[1] + 4, HZ - R[2], R[1] + 4, HZ - 1)
      line(1, R[1], HZ - R[2], R[1] + 4, HZ - R[2])
    end
    for k = 0, 4 do put(min(10, 3 + amp * 4 + lo * 2 + 1.5 * sin(T * 1.7 + k)), 56 + k * 4, HZ - 11, 1, 1) end

    -- the crowd: glowsticks turning circles, fainter far off
    local spin_d = 1 + e * 0.5
    for i = 1, #DANCERS do
      local D = DANCERS[i]
      local R = ROWS[D.row]
      if D.order < 0.45 + e * 0.35 + ph * 0.25 or D.row == 3 then
        local sp = (2.2 + e * 2) * D.sp * (1 - kl * 0.6)
        rotf[i] = rotf[i] + sp * fdir_s * K.DTS
        local th = rotf[i]
        local spinning = i == spin_i and T - spin_t < 0.6
        if spinning then th = th + (T - spin_t) * 30 end
        -- a wave of raised sticks across the crowd on a fill
        local wv = 0
        local wa = T - wave_t
        if wa >= 0 and wa < 1.6 then wv = exp(-((D.x - wa * 110) / 14) ^ 2) end
        local up = R.sh * (1.2 + bounce * 0.8 + (D.row == 3 and raise * 2 or 0) + wv * 2.5)
        local rad = R.r * (1 + e * 0.4 + wide[D.row] * 1.2 + (spinning and 1 or 0)) * (1 - kl * 0.4)
        local cy = R.y - up - bounce * R.sh * 0.6
        local lv = R.l * (0.75 + lo * 0.3 + bounce * 0.5 + wv * 0.4)
        for _, Cr in ipairs(cracks) do
          if Cr.i == i then lv = lv + Cr.v * 6 * max(0, 1 - (T - Cr.t0) / 1.2) end
        end
        if kl > 0.5 then lv = lv * 0.8 end
        for hand = -1, 1, 2 do
          local sx = D.x + hand * R.sh * 0.8
          local a0 = th * hand + (hand > 0 and 3.14 or 0)
          if kl > 0.5 then a0 = math.pi / 2 + sin(T * 0.8 + D.ph) * 0.8 end
          -- the trail behind the stick, then the stick
          for k = 2, 0, -1 do
            local a = a0 - k * 0.45 * hand * fdir_s * (kl > 0.5 and 0.2 or 1)
            local px, py = sx + cos(a) * rad, cy + sin(a) * rad * 0.8
            local ex, ey = px + cos(a) * R.len, py + sin(a) * R.len * 0.8
            local l = lv * (k == 0 and 1 or (0.45 - k * 0.12))
            if l >= 0.6 then line(min(12, l), px, py, ex, ey) end
            if k == 0 and hi > 0.1 and K.hash(i * 2 + hand, floor(T * 6)) < hi * 0.5 then
              put(min(12, lv + 3), ex, ey, 1, 1)
            end
          end
        end
        if D.row == 3 then K.disc(1, D.x, R.y + 3, 2.5) end
      end
    end
    -- chaos: sticks thrown spinning into the air
    for i = #thrown, 1, -1 do
      local P = thrown[i]
      local a = T - P.t0
      if a > 1.4 then table.remove(thrown, i)
      else
        local x = P.x + P.vx * a
        local y = 50 - 45 * a + 32 * a * a
        local an = P.w * a
        line(6 * (1 - a / 1.4) + 1, x - cos(an) * 2, y - sin(an) * 2, x + cos(an) * 2, y + sin(an) * 2)
      end
    end
  end

  ------------------------------------------------------------------
  function M.draw(S)
    local DT = K.DT
    flare_to = flare_to * math.exp(-DT / 0.12)
    open_to = open_to * math.exp(-DT / 0.4)
    flare = K.follow(flare, flare_to, 0.035, DT)
    fan_open = K.follow(fan_open, open_to, 0.08, DT)
    spin = spin * math.exp(-DT / 0.6)
    spark = spark * math.exp(-DT / 0.08)
    surge_to = surge_to * math.exp(-DT / 0.2)
    rotv_to = rotv_to * math.exp(-DT / 0.3)
    speed_k = K.follow(speed_k, surge_to, 0.08, DT)
    rotv = K.follow(rotv, rotv_to, 0.08, DT)
    for i = 1, NP do
      hands_to[i] = hands_to[i] * math.exp(-DT / 0.45)
      hands[i] = K.follow(hands[i], hands_to[i], hands_to[i] > hands[i] and 0.07 or 0.15, DT)
    end
    for k = 1, 5 do lamps[k] = lamps[k] * math.exp(-DT / 0.1) end
    for i = #races, 1, -1 do if K.T - races[i].t0 > 1.0 then table.remove(races, i) end end
    for i = #cracks, 1, -1 do if K.T - cracks[i].t0 > 1.2 then table.remove(cracks, i) end end
    if K.view == 2 then tunnel(S)
    elseif K.view == 3 then field(S)
    else warehouse(S) end
  end

  M.init()
  return M
end
