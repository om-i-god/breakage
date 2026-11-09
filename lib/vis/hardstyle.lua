-- hardstyle. view 1: a Dutch hard-dance main stage at night: angular metal
-- wings round a pointed screen, pyro jets on the deck, lasers, and a crowd of
-- fists in front.
-- view 2: the kick's own landscape: every beat a ridge of its waveform (the
-- distorted, pitched kick and the reverse-bass tail ringing after it),
-- stacked back into the dark, pyro columns either side.
-- view 3: the arena from the lighting rig: the arrow-shaped stage at the top,
-- a fan of heads below, the kick's shockwave rolling out through them.
--
-- view 1: the kick slams a shockwave out across the floor from the stage
-- lip, flashes the screen and throws every fist up (the nearest first, the
-- back rows a moment later); the pyro jets fire on the downbeat, on the
-- third beat as the energy rises and on every kick at the top, a smoke puff
-- left hanging over each. the screen draws the reverse bass as it rings
-- toward the next kick and cuts dead on it. snares chase the chevrons out
-- along the wings, claps put both hands up, hats flick the lasers (open
-- hats swing them), percussion throws follow-spots into the crowd, a
-- ratchet walks a run of pyro bursts along the deck and a fill fires the
-- CO2 cannons. every bar changes what is behind the screen's wave; each
-- phrase edge fires the whole deck. energy brings more jets, more fists
-- and thicker haze; chaos scatters the lasers, doubles the shockwave and
-- tears the screen; kickless, the jets rest, lighters come up and the crowd
-- sways while the screen sings the breakdown's lead.
-- view 2: the front ridge is the beat being played, written left to right
-- by a bright head: the kick's pitch drop squared off by the distortion,
-- then the reverse bass swelling to the cut. snares leave a burst of noise
-- in the ridge, claps three spikes, hats a fine hiss (open hats a longer
-- one), percussion a ringing bump, a ratchet a comb of spikes, so the
-- landscape is a record of the groove. each kick pushes the beat back into
-- the landscape and sends a slam over it. energy drives the kick harder
-- into the clip and the pyros higher; chaos roughens every ridge; kickless
-- ridges are the lead's slow melody.
-- view 3: heads in rows round the stage; the kick's wave lifts the fists as
-- it passes, and the reverse bass is a ring drawn back in toward the stage
-- over the beat, brighter as it nears. snares light a wedge of clapping
-- hands, hats glint phones, percussion drops a follow-spot, a ratchet rings
-- out from the deck that many times, the pyros flare from above. chaos
-- opens circle pits that wheel; kickless, the crowd sways and holds up
-- lighters.
--
-- the ears: view 1, the lows light the stage lip and the shockwave, the
-- mids the metal wings and the screen, the highs the lasers and the truss
-- lamps, the level the haze over the crowd. view 2, the lows raise the
-- front ridges, the mids the reverse bass and the frame, the highs spark on
-- the crests, the level the far glow. view 3, the lows the shockwave, the
-- mids the stage's lines, the highs the lasers and the phones, the level
-- the whole crowd.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, exp = math.sin, math.cos, math.floor, math.max, math.min, math.abs, math.exp
  local PI, TAU = math.pi, 2 * math.pi
  local TOP = 13.4                     -- the brightest any hit gets (level 15 is rationed)
  local function P(l, x, y, w, h) if l > TOP then l = TOP end put(l, x, y, w, h) end
  local function L(l, x0, y0, x1, y1) if l > TOP then l = TOP end line(l, x0, y0, x1, y1) end

  ------------------------------------------------------------------
  -- state shared by the views
  ------------------------------------------------------------------
  local kick_T, kick_v, kick_n = -99, 0, 0
  local slam = 0
  local shocks = {}                    -- {t0, v, dx}
  local NJ = 6
  local fire_T, fire_v = {}, {}         -- each pyro jet: when it fired, how hard
  local queue = {}                     -- pending pyro bursts {t, i, v}
  local snare_T, snare_v, clap_T = -99, 0, -99
  local las_flash, las_swing, las_sv = 0, 0, 0
  local spots = {}                     -- follow-spots {x, t0, v, big}
  local sparks = {}                    -- view 3 phone glints {i, t0, v, life}
  local scr_pat, phrase_T, fill_T = 1, -99, -99
  local rat_T, rat_n = -99, 0
  local wedge_a, wedge_T, wedge_v = 0, -99, 0
  local pits = {}

  -- view 2: the ridges (newest first), the beat being written, its clock
  local NRG = 7
  local ridges, cur = {}, nil
  local rc = 0                         -- 0..1 through the beat being written
  local push_T = -99
  local rid = 0
  local H = {}                         -- the nearest line drawn so far, per 2px column
  local RX, RY = {}, {}                -- the front ridges' points, for sparks

  local function new_ridge(kv, kl)
    rid = rid + 1
    return {kv = kv, kl = kl, e = K.energy, c = K.chaos, seed = rid, ev = {}}
  end
  local function push_ridge(kv, kl)
    if cur then table.insert(ridges, 1, cur) end
    while #ridges > NRG do ridges[#ridges] = nil end
    cur = new_ridge(kv, kl)
    rc, push_T = 0, K.T
  end
  -- an event written into the beat at the head
  local function mark(k, v, w, n)
    if not cur or #cur.ev >= 12 then return end
    cur.ev[#cur.ev + 1] = {u = clamp(rc, 0, 0.98), k = k, v = clamp(v, 0, 1), w = w, n = n or 1}
  end

  local function fire_jet(i, v)
    if i < 1 or i > NJ then return end
    fire_T[i], fire_v[i] = K.T, clamp(v, 0.3, 1)
  end

  function M.init()
    kick_T, kick_v, kick_n, slam = -99, 0, 0, 0
    shocks, queue, spots, sparks, pits = {}, {}, {}, {}, {}
    for i = 1, NJ do fire_T[i], fire_v[i] = -99, 0 end
    snare_T, snare_v, clap_T = -99, 0, -99
    las_flash, las_swing, las_sv = 0, 0, 0
    scr_pat, phrase_T, fill_T = 1, -99, -99
    rat_T, rat_n = -99, 0
    wedge_a, wedge_T, wedge_v = 0, -99, 0
    ridges, cur, rid = {}, nil, 0
    -- a landscape already there: the last few beats, made up
    for k = 1, NRG do
      push_ridge(0.6 + 0.3 * K.hash(k, 91), false)
      cur.e = 0.3
    end
    rc, push_T = 0, -99
  end
  M.clear = M.init

  ------------------------------------------------------------------
  -- the events
  ------------------------------------------------------------------
  function M.kick(v)
    v = clamp(K.num(v, 1), 0, 1)
    kick_T, kick_v, kick_n = K.T, v, kick_n + 1
    slam = 1
    if #shocks >= 4 then table.remove(shocks, 1) end
    shocks[#shocks + 1] = {t0 = K.T, v = v, dx = 0}
    local e, c = K.energy, K.chaos
    if c > 0.45 and #shocks < 4 then
      shocks[#shocks + 1] = {t0 = K.T - 0.06, v = v * 0.6, dx = (K.rnd() - 0.5) * 50 * c}
    end
    -- the pyros: the downbeat, the third beat with energy, every kick at the top
    local beat = (kick_n - 1) % 4
    if beat == 0 then fire_jet(1, v); fire_jet(4, v) end
    if beat == 2 and e > 0.35 then fire_jet(2, v); fire_jet(3, v) end
    if e > 0.75 then fire_jet(5 + kick_n % 2, v) end
    if e > 0.9 and beat % 2 == 1 then fire_jet(1 + 3 * (kick_n % 2), v * 0.8) end
    if c > 0.4 and K.rnd() < c * 0.7 then fire_jet(1 + floor(K.rnd() * NJ), v * 0.7) end
    push_ridge(v, false)
  end

  function M.snare(v, n)
    v = clamp(K.num(v, 1), 0, 1)
    snare_T, snare_v = K.T, v
    wedge_a, wedge_T, wedge_v = 0.35 + K.rnd() * (PI - 0.7), K.T, v
    if K.num(n, 1) <= 1 then mark(1, v, 0.09) end
  end
  function M.clap(v)
    v = clamp(K.num(v, 1), 0, 1)
    clap_T = K.T
    wedge_a, wedge_T, wedge_v = 0.35 + K.rnd() * (PI - 0.7), K.T, v * 0.8
    mark(2, v, 0.06)
  end
  function M.rim(v) las_flash = math.max(las_flash, 0.5); mark(3, K.num(v, 1) * 0.6, 0.03) end
  function M.hat(v, open)
    v = clamp(K.num(v, 1), 0, 1)
    las_flash = math.max(las_flash, 0.6 + 0.4 * v)
    if open then las_sv = las_sv + (K.rnd() < 0.5 and -1 or 1) * (1.5 + v) end
    mark(3, v, open and 0.16 or 0.04)
    if #sparks < 10 then sparks[#sparks + 1] = {i = 1 + floor(K.rnd() * 9999), t0 = K.T, v = v, life = open and 0.4 or 0.18} end
  end
  function M.ride(v) M.hat(K.num(v, 1) * 0.7, true) end
  function M.shaker(v) M.hat(K.num(v, 1) * 0.5, false) end
  function M.perc(kind, v)
    v = clamp(K.num(v, 1), 0, 1)
    if #spots >= 4 then table.remove(spots, 1) end
    spots[#spots + 1] = {x = 8 + K.rnd() * 112, t0 = K.T, v = v, big = false, k = K.num(kind, 1)}
    mark(4, v * 0.8, 0.07)
  end
  function M.tom(v)
    v = clamp(K.num(v, 1), 0, 1)
    if #spots >= 4 then table.remove(spots, 1) end
    spots[#spots + 1] = {x = 20 + K.rnd() * 88, t0 = K.T, v = v, big = true, k = 0}
    mark(4, v, 0.12)
  end
  function M.tick() las_flash = math.max(las_flash, 0.4) end
  function M.ratchet(n, voice)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    rat_T, rat_n = K.T, n
    -- a run of pyro bursts walking along the deck
    local order = {1, 5, 2, 3, 6, 4}
    for k = 0, math.min(n, 8) - 1 do
      if #queue < 12 then queue[#queue + 1] = {t = K.T + k * 0.06, i = order[k % NJ + 1], v = 0.7} end
    end
    mark(5, 0.9, 0.2, n)
    las_flash = 1
  end
  function M.fill()
    fill_T = K.T
    for i = 1, NJ do fire_jet(i, 0.8) end
  end
  function M.bar(S)
    kick_n = 0
    scr_pat = scr_pat % 3 + 1
    local pl = math.max(1, floor(K.num(S and S.phrase_len, 16)))
    local pp = floor(K.num(S and S.phrase_pos, 1))
    if pp % pl == 0 then
      phrase_T = K.T
      for i = 1, NJ do fire_jet(i, 1) end
    end
    -- the circle pits move on with the bar
    pits = {}
    local np = floor(K.chaos * 3 + 0.3)
    local b = floor(K.num(S and S.bar, 0)) % 997
    for k = 1, np do
      pits[k] = {x = 28 + K.hash(b * 3 + k, 71) * 72, y = 32 + K.hash(b * 3 + k, 72) * 20,
        r = 7 + K.chaos * 5 + K.hash(k + b, 73) * 3, dir = (k % 2 == 0) and 1 or -1}
    end
  end

  ------------------------------------------------------------------
  -- shared drawing
  ------------------------------------------------------------------
  -- a jet's flame now: 0..1 height and strength
  local function flame_now(i)
    local age = K.T - fire_T[i]
    if age < 0 or age > 1.2 then return 0, age end
    local rise = K.ease(clamp(age / 0.12, 0, 1))
    local f = age < 0.22 and 1 or exp(-(age - 0.22) / 0.14)
    return rise * f * fire_v[i], age
  end

  -- a flame column standing on (x, yb), h px tall, w wide
  local function flame(x, yb, h, f, w, seed)
    if f < 0.03 or h < 1 then return end
    local T = K.T
    local n = math.max(2, floor(h / 3))
    for k = 0, n - 1 do
      local u = k / n
      local y = yb - (k + 1) * h / n
      local fl = (K.hash(k + seed * 31, floor(T * 10)) - 0.5) * 1.4
      local ww = math.max(1, w * (1 - u * 0.6) + fl)
      local lv = (1.5 + 4 * f) * (1 - u * 0.7)
      P(lv, x - ww / 2 + fl * 0.5, y, ww, h / n + 1)
      if u < 0.5 then P(lv + 2.5, x - 0.5, y, 1, h / n + 1) end
    end
    -- the tongue at the top flickers loose
    local ty = yb - h - 2 - K.hash(seed, floor(T * 18)) * 3
    P(2 + 3 * f, x + (K.hash(seed + 5, floor(T * 18)) - 0.5) * 3, ty, 1, 2)
  end

  local function smoke(x, yb, age, i)
    if age < 0.15 or age > 2.4 then return end
    local u = (age - 0.15) / 2.25
    local y = yb - 4 - u * 16
    local s = 2 + u * 7
    local lv = 1.6 * (1 - u)
    for k = 0, 3 do
      local ox = (K.hash(i * 7 + k, 81) - 0.5) * s * 2 + sin(K.T * 0.8 + k + i) * 1.5
      local oy = (K.hash(i * 7 + k, 82) - 0.5) * s * 0.7
      P(lv + 0.4, x + ox, y + oy, 2 + floor(u * 2), 1)
    end
  end

  -- the waveform of one beat at u (0..1): about -1.3..1.3
  local function wave(R, u)
    local y
    if R.kl then
      local f = 2 + R.seed % 3
      y = sin(u * TAU * f + R.seed * 1.7) * 0.5 * (0.5 + 0.5 * sin(u * PI))
    elseif u < 0.3 then
      local w = u / 0.3
      local cyc = 5.5 * w - 2.6 * w * w                         -- the pitch drops
      local s = clamp(sin(cyc * TAU) * (1.6 + R.e * 3.5 + R.kv), -1, 1)  -- driven into the clip
      y = s * (1 - 0.45 * w) * (0.55 + 0.45 * R.kv)
      if u < 0.025 then y = y + 0.5 end
    else
      local w = (u - 0.3) / 0.7
      local env = w ^ 1.5
      if u > 0.95 then env = env * (1 - u) / 0.05 end
      local ph = w * 7.5
      local s = sin(ph * TAU) * 0.7 + ((ph % 1) * 2 - 1) * 0.3
      y = s * env * 0.8 * (0.7 + 0.3 * R.e)
    end
    if R.c > 0.05 then y = y + (K.hash(floor(u * 48) + R.seed * 53, 7) - 0.5) * R.c * 0.8 end
    local ev = R.ev
    for i = 1, #ev do
      local E = ev[i]
      local d = u - E.u
      if d >= 0 and d < E.w then
        local a = E.v * (1 - d / E.w)
        if E.k == 1 then
          y = y + (K.hash(floor(u * 90) + i * 17 + R.seed, 9) - 0.5) * 2.2 * a
        elseif E.k == 2 then
          local q = d / E.w * 3
          y = y + (((q % 1) < 0.35) and 1.1 or 0) * a * ((floor(q) % 2 == 0) and 1 or -1)
        elseif E.k == 3 then
          y = y + (K.hash(floor(u * 160) + i * 5 + R.seed, 4) - 0.5) * 0.8 * a
        elseif E.k == 4 then
          y = y + sin(d / E.w * PI * 3) * 0.7 * a
        else
          local q = d / E.w * E.n
          y = y + (((q % 1) < 0.35) and 1 or -0.3) * 0.9 * a
        end
      end
    end
    return y
  end

  ------------------------------------------------------------------
  -- view 1: the main stage
  ------------------------------------------------------------------
  local JX1 = {10, 27, 101, 118, 45, 83}
  local DECK = 38
  local SCX, SCY = 64, 21
  local function scr_hw(y) return 13 + 6 * (1 - abs(y - SCY) / 9) end
  local EMIT = {16, 40, 88, 112}
  local BACK, FRONT = {}, {}
  for i = 0, 31 do
    BACK[i + 1] = {x = floor(i * 4.1 + K.hash(i, 3) * 2), y = 46 + floor(K.hash(i, 4) * 3), ph = K.hash(i, 5), pump = K.hash(i, 6)}
  end
  for i = 0, 20 do
    FRONT[i + 1] = {x = floor(1 + i * 6.1 + K.hash(i, 7) * 2), y = 52 + floor(K.hash(i, 8) * 3), ph = K.hash(i, 9),
      pump = K.hash(i, 10), side = K.hash(i, 11) < 0.5 and -2 or 5}
  end

  -- the nearest heads, right under the camera: big dark shapes, big fists
  local NEAR = {}
  for i = 0, 7 do
    NEAR[i + 1] = {x = 4 + i * 16 + floor(K.hash(i, 12) * 6), ph = K.hash(i, 13), pump = K.hash(i, 14) * 0.6,
      side = K.hash(i, 15) < 0.5 and -3 or 8}
  end
  local function lift(Pp, front)
    -- how far this person's fist is up (0..1)
    local e, kl = K.energy, K.kickless
    local up = 0
    if Pp.pump < 0.3 + e * 0.7 then
      local delay = abs(Pp.x - 64) / 64 * 0.07 + (front and 0 or 0.05)
      local age = K.T - kick_T - delay
      if age >= 0 then up = K.ease(math.min(1, age / 0.1)) * exp(-math.max(0, age - 0.1) / (0.16 + 0.1 * (1 - e))) end
      up = up * (1 - kl)
    end
    local ca = K.T - clap_T
    if ca >= 0 and ca < 0.4 then up = math.max(up, 0.8 * (1 - ca / 0.4)) end
    -- the sway, kickless or between
    up = math.max(up, (0.25 + 0.2 * sin(K.T * 1.1 + Pp.ph * 9)) * kl * (Pp.pump < 0.5 and 1 or 0))
    if not K.playing then up = math.max(up, 0.15 + 0.15 * sin(K.T * 0.9 + Pp.ph * 9)) * (Pp.pump < 0.3 and 1 or 0) end
    return clamp(up, 0, 1)
  end

  local function draw_stage(S)
    local T, e, c, kl = K.T, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local kage = T - kick_T
    local kp = (kage >= 0 and kage < 1) and exp(-kage / 0.12) * kick_v or 0
    local ph = clamp((T - phrase_T) / 0.8, 0, 1)
    local phf = ph < 1 and (1 - ph) or 0

    -- the truss: two chords and their lattice, the lamps hanging under
    local tl = 1.3 + mid * 1.1 + phf * 3
    L(tl, 0, 1, 127, 1); K.dashes(tl * 0.8, 5, 3, 4, 0)
    for x = 0, 120, 8 do L(tl * 0.7, x, 1, x + 4, 5); L(tl * 0.7, x + 4, 5, x + 8, 1) end
    for k, x in ipairs(EMIT) do
      P(2 + hi * 4 + las_flash * 4 * ((k % 2 == 0) and 1 or 0.6), x - 1, 6, 3, 2)
    end

    -- the screen: a pointed panel, behind its wave the bar's pattern
    local flash = kp * (1.2 + 1 * lo) * (1 - kl) + phf * 1.5
    for y = SCY - 8, SCY + 8 do
      local hw = scr_hw(y)
      local tear = 0
      if c > 0.35 and K.hash(y, floor(T * 6)) < (c - 0.35) * 0.6 then tear = (K.hash(y + 9, floor(T * 6)) - 0.5) * 10 * c end
      local bg = 0
      if scr_pat == 1 then bg = (floor(y / 3) % 2 == floor(T * 4) % 2) and 1 + mid * 1.5 or 0
      elseif scr_pat == 2 then bg = ((floor(abs(y - SCY) + T * 10)) % 6 < 2) and 0.9 + mid * 1.5 or 0
      else bg = (abs(y - SCY) % 4 == floor(T * 8) % 4) and 0.8 + mid * 1.5 or 0 end
      local lv = (y % 3 == 0) and flash or ((y % 3 == 1) and bg or 0)
      if lv >= 0.5 then P(lv, SCX - hw + tear, y, hw * 2, 1) end
    end
    -- its edge: angled metal
    local el = 2.5 + mid * 3 + kp * 3
    L(el, SCX - 13, SCY - 9, SCX + 13, SCY - 9); L(el, SCX - 13, SCY + 9, SCX + 13, SCY + 9)
    L(el, SCX - 13, SCY - 9, SCX - 20, SCY); L(el, SCX - 20, SCY, SCX - 13, SCY + 9)
    L(el, SCX + 13, SCY - 9, SCX + 20, SCY); L(el, SCX + 20, SCY, SCX + 13, SCY + 9)
    -- the wave across it: the beat being played
    if cur then
      local px, py
      local N = 28
      local amp_px = 6 + lo * 1.5
      for k = 0, N do
        local u = k / N
        local x = SCX - 18 + 36 * u
        local y
        if u <= rc or not K.playing then
          local uu = K.playing and u or (u + T * 0.15) % 1
          y = SCY - wave(cur, uu) * amp_px
        else y = SCY end
        y = clamp(y, SCY - 8, SCY + 8)
        if px then L((u <= rc and 7 or 2) + mid * 3 + kp * 2, px, py, x, y) end
        px, py = x, y
      end
      if K.playing then P(11, SCX - 18 + 36 * clamp(rc, 0, 1), py - 1, 1, 3) end
    end

    -- the wings: nested chevrons pointing out from the screen, chased by the snare
    local sage = T - snare_T
    for k = 1, 4 do
      local ax = SCX - 20 - k * 9
      -- the chase: a soft swell running out through the chevrons
      local d = (sage - (k - 1) * 0.05) / 0.07
      local ch = (sage >= 0 and sage < 0.6) and exp(-d * d) * snare_v * 2.2 or 0
      local cl = (k == 1) and clamp((0.4 - (T - clap_T)) / 0.4, 0, 1) * 1.2 or 0
      local lv = 1 + mid * 1 + kp * 0.5 * (5 - k) / 4 + ch + cl + phf * 2
      local jy = c > 0.4 and sin(T * (2.3 + k) + k * 2) * 3 * (c - 0.4) or 0
      for s = -1, 1, 2 do
        local x0 = SCX + s * (SCX - ax)
        local x1 = SCX + s * (SCX - ax - 11)
        L(lv, x1, SCY - 15 + k + jy, x0, SCY + jy)
        L(lv, x1, SCY + 15 - k + jy, x0, SCY + jy)
      end
    end

    -- the deck: its lip lit by the lows, an LED strip running
    L(3 + lo * 3 + kp * 2, 0, DECK, 127, DECK)
    local off = floor(T * (8 + e * 30)) % 6
    for x = off, 127, 6 do P(1.2 + lo * 2.5 + e, x, DECK + 2, 3, 1) end

    -- the pyro jets, and their smoke
    local nj = e > 0.75 and 6 or 4
    for i = 1, NJ do
      local f, age = flame_now(i)
      if i <= nj or f > 0 then
        P(2 + lo, JX1[i] - 2, DECK - 1, 5, 1)
        if f > 0 then flame(JX1[i], DECK - 1, f * (20 + e * 12 + lo * 4), f, 2.5 + f * 2, i) end
        smoke(JX1[i], DECK - 1 - (14 + e * 10), age, i)
      end
    end
    for k = #queue, 1, -1 do
      if T >= queue[k].t then fire_jet(queue[k].i, queue[k].v); table.remove(queue, k) end
    end
    -- CO2 cannons on a fill: white plumes that spread and fade
    local fa = T - fill_T
    if fa >= 0 and fa < 1.2 then
      local u = fa / 1.2
      for _, x in ipairs({36, 92}) do
        for k = 0, 5 do
          local w = 2 + k * 1.5 * (0.5 + u)
          P((4 - k * 0.5) * (1 - u), x - w / 2 + sin(T * 3 + k) * u * 2, DECK - 4 - k * 4 - u * 6, w, 3)
        end
      end
    end

    -- the lasers: a fan from the truss into the haze over the crowd
    las_sv = las_sv - (las_swing * 9 + las_sv * 2.2) * K.DTS
    las_swing = clamp(las_swing + las_sv * K.DTS, -1.2, 1.2)
    local nl = 1 + floor(e * 1.2 + c * 0.6)
    local base = sin(T * (0.3 + e * 0.3)) * 0.45 + las_swing * 0.3
    local ll = (0.7 + hi * 1.6 + las_flash * 1.6) * (1 - kl * 0.4)
    for k, x in ipairs(EMIT) do
      for j = 1, nl do
        local a = PI / 2 + (k <= 2 and 0.85 or -0.85) + base * ((k <= 2) and 1 or -1) + (j - (nl + 1) / 2) * (0.22 + kl * 0.15)
        if c > 0.3 then a = a + (K.hash(k * 5 + j, floor(T * 3)) - 0.5) * c * 1.4 end
        a = clamp(a, 0.3, PI - 0.3)
        local ex, ey = x + cos(a) * 64, DECK + sin(a) * 64
        L(ll * (j == 1 and 1 or 0.7), x, DECK + 1, ex, ey)
        P(ll + 3, x, DECK, 1, 1)
      end
    end

    -- follow-spots from the truss onto the crowd
    for k = #spots, 1, -1 do
      local Sp = spots[k]
      local u = (T - Sp.t0) / (Sp.big and 0.6 or 0.4)
      if u >= 1 or u < 0 then table.remove(spots, k)
      else
        local lv = (2.5 + 4 * Sp.v) * (1 - u)
        local ex = EMIT[1 + floor(Sp.x) % 4]
        local hw = Sp.big and 6 or 3
        L(lv * 0.6, ex, 7, Sp.x - hw, 56); L(lv * 0.6, ex, 7, Sp.x + hw, 56)
        P(lv, Sp.x - hw, 56, hw * 2, 1)
      end
    end

    -- the air between the stage and the crowd, lit by the stage (the level)
    local hz = (0.45 + amp * 0.9 + e * 0.4 + kp * lo * 0.8 + kl * 0.4 * (0.5 + 0.5 * sin(T * 0.7))) * (K.playing and 1 or 0.8)
    K.gradient(DECK + 3, 44, function(y) return clamp(hz * 0.22 * (1.1 - (y - DECK - 3) / 4), 0, 0.4) end)
    -- the crowd, caught in the stage light: heads and shoulders, fists up
    -- on the kick (the front first, the back a moment later)
    local rim = 1.6 + amp * 1.1 + kp * 0.4 + mid * 0.6
    for _, Pp in ipairs(BACK) do
      local up = lift(Pp, false)
      local x = Pp.x + sin(T * 1.1 + Pp.ph * 9) * kl * 1.2
      P(rim * 0.8, x, Pp.y, 3, 1)
      if up > 0.05 then
        local fy = Pp.y + 1 - up * 6
        P(rim * 0.5, x + 3, fy + 1, 1, Pp.y + 1 - fy)
        P(rim + up * 3, x + 3, fy, 2, 1)
      end
    end
    for i, Pp in ipairs(FRONT) do
      local up = lift(Pp, true)
      local x = Pp.x + sin(T * 1.1 + Pp.ph * 9) * kl * 1.6
      P(rim * 1.3, x + 1, Pp.y, 3, 1)
      P(rim, x, Pp.y + 1, 5, 2)
      if up > 0.05 then
        local ax = x + Pp.side
        local fy = Pp.y + 2 - up * 10
        P(rim * 0.6, ax + 1, fy + 2, 1, Pp.y + 3 - fy - 2)
        P(rim + 1 + up * 3, ax, fy, 3, 1)
        P(rim * 0.8, ax + 1, fy + 1, 1, 1)
      end
      -- kickless: lighters held up
      if kl > 0.2 and Pp.pump < 0.5 then
        local fy = Pp.y + 2 - up * 10
        P((2 + 2.5 * (0.5 + 0.5 * sin(T * 5 + i * 1.7))) * kl, x + Pp.side + 1, fy - 2, 1, 1)
      end
    end

    for _, Pp in ipairs(NEAR) do
      local up = lift(Pp, true)
      local x = Pp.x + sin(T * 0.9 + Pp.ph * 9) * (0.6 + kl * 1.5)
      P(rim * 0.75, x + 1, 58, 6, 1)
      P(rim * 0.4, x, 59, 8, 2)
      P(rim * 0.3, x - 3, 62, 14, 1)
      if up > 0.05 then
        local ax = x + Pp.side
        local fy = 60 - up * 15
        P(rim * 0.35, ax + 1, fy + 3, 2, 62 - fy - 3)
        P(rim * 0.9 + up * 2.5, ax, fy, 4, 1)
        P(rim * 0.5, ax, fy + 1, 4, 2)
      end
    end

    -- the shockwave: a ring slammed out across the floor from the lip
    for k = #shocks, 1, -1 do
      local Sh = shocks[k]
      local age = T - Sh.t0
      if age > 0.7 then table.remove(shocks, k)
      elseif age > 0 then
        local r = 6 + age * (150 + lo * 40)
        local lv = (2 + 4 * Sh.v + lo * 1.5) * (1 - age / 0.7) ^ 1.5
        K.ring(lv, 64 + Sh.dx, DECK + 1, r, 20, 0.05, PI - 0.05, 0.28)
        if age < 0.25 then K.ring(lv * 0.5, 64 + Sh.dx, DECK + 1, r * 0.75, 14, 0.1, PI - 0.1, 0.28) end
      end
    end
    -- a ratchet's bursts ring along the lip
    local ra = T - rat_T
    if ra >= 0 and ra < 0.5 then
      for q = 0, math.min(rat_n, 8) - 1 do
        local x = 8 + q * (112 / math.max(1, math.min(rat_n, 8) - 1 + 0.001))
        P((9 - q * 0.4) * (1 - ra / 0.5), x, DECK - 2, 2, 2)
      end
    end
    -- sparks over the crowd with the highs
    K.grain(function(u, v) return 4 + u * 120, 10 + v * 30 end, 3 + hi * 22 + e * 6, 3 + hi * 5)
  end

  ------------------------------------------------------------------
  -- view 2: the landscape of the kick
  ------------------------------------------------------------------
  local function proj(z)
    local y = 14 + 41 / (1 + z * 0.16)
    local hw = 60 / (1 + z * 0.12)
    local ap = 10 / (1 + z * 0.35)
    return y, hw, ap
  end

  local function draw_land(S)
    local T, e, c, kl = K.T, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local kage = T - kick_T
    local kp = (kage >= 0 and kage < 1) and exp(-kage / 0.12) * kick_v or 0
    local phf = math.max(0, 1 - (T - phrase_T) / 0.8)

    -- the frame: an angular metal V behind the landscape, chased by the snare
    local sage = T - snare_T
    for k = 0, 1 do
      local d = sage * 8 - k * 0.5
      local ch = (d > 0 and d < 1) and (1 - d) * snare_v * 3 or 0
      local lv = 0.7 + mid * 0.6 + ch + phf * 2 + kp * (1 - k)
      local y0, y1 = 1 + k * 8, 20 + k * 6
      L(lv, 0, y0, 64, y1); L(lv, 127, y0, 64, y1)
    end
    -- the far glow over the horizon (the level)
    -- (a dome of light rising behind the horizon, in scanlines)
    local fy = floor(proj(NRG))
    local dr = 13 + amp * 3
    local dl = 0.6 + amp * 0.5 + e * 0.2 + phf
    for y = fy - floor(dr), fy do
      local d = fy - y
      local hw = math.sqrt(math.max(0, dr * dr - d * d)) * 2.2
      P(dl * ((d > dr * 0.45) and 0.6 or 1), 64 - hw, y, hw * 2, 1)
    end

    for col = 0, 64 do H[col] = 99 end
    -- each kick steps the landscape back a beat: the ridges keep their
    -- places, each takes the beat in front of it
    local N = 36
    local drive = 0.85 + lo * 0.45 + kp * 0.35
    local ripple = kage * 16                   -- the slam travelling back
    for k = 0, NRG do
      local R = (k == 0) and cur or ridges[k]
      if R then
        local z = k
        local yb, hw, ap = proj(z)
        if k <= 1 then ap = ap * drive end
        if k == 0 then yb = yb + kp * 2 end
        local hl = (kage >= 0 and kage < 0.8) and 2.5 * exp(-(z - ripple) ^ 2 * 0.6) * (1 - kage / 0.8) or 0
        local lv = (0.5 + 3.5 / (1 + z * 0.8)) * (0.75 + 0.25 * amp) + hl + (k == 0 and 1 or 0)
        if R.kl then lv = lv * 0.75 end
        local lim = (k == 0 and K.playing) and clamp(rc, 0, 1) or 1
        local xs, ys = RX[k] or {}, RY[k] or {}
        RX[k], RY[k] = xs, ys
        for i = 0, N do
          local u = i / N
          local x = 64 + (u * 2 - 1) * hw
          local y
          if k == 0 and not K.playing then
            y = yb - sin(u * TAU * 2 + T * 1.3) * ap * 0.25 * (0.5 + 0.5 * sin(u * PI))
          elseif u <= lim then
            local w = wave(R, u)
            -- the reverse bass on the front ridges swells with the mids
            if k <= 1 and u > 0.3 then w = w * (0.75 + mid * 0.5) end
            y = yb - w * ap
          else y = yb end
          xs[i], ys[i] = x, clamp(y, -4, 70)
        end
        -- draw what the nearer ridges have not hidden, then hide behind it
        for i = 1, N do
          local x0, y0, x1, y1 = xs[i - 1], ys[i - 1], xs[i], ys[i]
          local c0 = clamp(floor(x0 / 2), 0, 64)
          local c1 = clamp(floor(x1 / 2), 0, 64)
          if y0 < H[c0] and y1 < H[c1] then
            local u = i / N
            local seg = lv
            if k == 0 and u > lim + 0.001 then seg = 1.5 + amp end
            if u < 0.3 and not R.kl then seg = seg * (1 + 0.25 * e) end
            L(seg, x0, y0, x1, y1)
          end
        end
        for i = 1, N do
          local x0, y0, x1, y1 = xs[i - 1], ys[i - 1], xs[i], ys[i]
          local ca, cb = floor(x0 / 2), floor(x1 / 2)
          for cc = math.max(0, ca), math.min(64, cb) do
            local f = (cb > ca) and (cc - ca) / (cb - ca) or 0
            local yy = y0 + (y1 - y0) * f
            if yy < H[cc] then H[cc] = yy end
          end
        end
        -- the head writing the beat
        if k == 0 and K.playing and lim < 1 then
          local i = clamp(floor(lim * N + 0.5), 0, N)
          P(11 + kp * 2, xs[i], ys[i] - 1, 1, 2)
          L(1.5 + lo * 2, xs[i], ys[i] + 2, xs[i], 63)
        end
      end
    end

    -- the slam: rings rising over the landscape from the front
    for k = #shocks, 1, -1 do
      local Sh = shocks[k]
      local age = T - Sh.t0
      if age > 0.7 then table.remove(shocks, k)
      elseif age > 0 then
        local r = 8 + age * (110 + lo * 30)
        K.ring((1.5 + 3.5 * Sh.v + lo) * (1 - age / 0.7) ^ 1.5, 64 + Sh.dx, 66, r, 18, PI + 0.15, TAU - 0.15, 0.5)
      end
    end

    -- the pyros either side: tall columns
    local XS = {4, 12, 115, 123}
    local JI = {1, 2, 3, 4}
    for q = 1, 4 do
      local i = JI[q]
      local f, age = flame_now(i)
      local f2 = math.max(f, flame_now(q <= 2 and 5 or 6) * 0.8)
      P(2 + lo * 2, XS[q] - 2, 62, 5, 2)
      if f2 > 0 then flame(XS[q], 62, f2 * (24 + e * 14 + lo * 6), f2 * 0.8, 2 + f2, q) end
      smoke(XS[q], 62 - (30 + e * 14), age, q)
    end
    for k = #queue, 1, -1 do
      if T >= queue[k].t then fire_jet(queue[k].i, queue[k].v); table.remove(queue, k) end
    end

    -- the highs: sparks on the crests
    K.grain(function(u, v)
      local k = floor(v * 4)
      local xs, ys = RX[k], RY[k]
      local i = floor(u * 36)
      if xs and xs[i] and ys[i] then return xs[i], ys[i] - 1 end
    end, 4 + hi * 26 + e * 6, 4 + hi * 6)
  end

  ------------------------------------------------------------------
  -- view 3: the arena from above
  ------------------------------------------------------------------
  local OX, OY = 64, 4                  -- the stage's point, the rows' centre
  local HEADS = {}
  for j = 0, 13 do
    local r = 17 + j * 3.7
    local n = floor(PI * r / 3.9)
    for q = 0, n do
      local i = #HEADS + 1
      local a = (q + (K.hash(i, 61) - 0.5) * 0.5) / n * PI
      local rr = r + (K.hash(i, 62) - 0.5) * 1.4
      local x, y = OX + cos(a) * rr, OY + sin(a) * rr * 0.95
      if x >= 1 and x <= 126 and y >= 16 and y <= 62 then
        HEADS[#HEADS + 1] = {x = x, y = y, r = rr, a = a, h = K.hash(i, 63)}
      end
    end
  end
  local NH = #HEADS
  local JX3 = {{22, 6}, {29, 9}, {99, 9}, {106, 6}, {44, 13}, {84, 13}}
  local LAS3 = {{34, 3}, {94, 3}}

  local function draw_arena(S)
    local T, e, c, kl = K.T, K.energy, K.chaos, K.kickless
    local lo, mid, hi, amp = A[K.LO], A[K.MID], A[K.HI], A[K.AMP]
    local kage = T - kick_T
    local kp = (kage >= 0 and kage < 1) and exp(-kage / 0.12) * kick_v or 0
    local phf = math.max(0, 1 - (T - phrase_T) / 0.8)

    -- the stage: an arrow pointing into the crowd, its LED lines chased
    local sl = 1.2 + mid * 0.8 + kp * 1.2 + phf * 3
    L(sl, 16, 0, 16, 5); L(sl, 112, 0, 112, 5)
    L(sl, 16, 5, 64, 15); L(sl, 112, 5, 64, 15)
    local sage = T - snare_T
    for k = 1, 2 do
      local d = sage * 10 - k * 0.4
      local ch = (d > 0 and d < 1) and (1 - d) * snare_v * 5 or 0
      local lv = 0.8 + mid * 0.8 + ch + phf * 2 + kp * 0.6
      local y = 5 + k * 3
      L(lv, 16 + k * 10, 1 + k, 64, y + 3); L(lv, 112 - k * 10, 1 + k, 64, y + 3)
    end
    -- the booth, and the screen's back edge lit by the bar's pattern
    P(2 + kp * 3, 59, 3, 10, 3)
    for x = 18, 108, 6 do
      local on = ((floor(x / 6) + scr_pat + floor(T * 3)) % 3 == 0)
      P((on and 2.2 or 0.9) + mid * 0.8, x, 0, 4, 1)
    end

    -- the reverse bass: a ring drawn in toward the stage over the beat
    local bp = K.playing and K.beat_ph or (T * 0.3) % 1
    if kl < 0.7 then
      local rr = 17 + (1 - bp) * 46
      local lv = (0.7 + bp ^ 1.5 * (1.6 + mid * 1.6)) * (1 - kl)
      K.ring(lv, OX, OY, rr, 26, 0.15, PI - 0.15, 0.95)
    end

    -- the heads: the shockwave lifts them, the wedge claps, pits wheel
    local wr = 14 + kage * (95 + lo * 30)
    local wf = (kage >= 0 and kage < 0.9) and (1 - kage / 0.9) * (0.4 + 0.6 * kick_v) or 0
    local wage = T - wedge_T
    local wl = (wage >= 0 and wage < 0.35) and (1 - wage / 0.35) * wedge_v or 0
    local base = 0.7 + amp * 0.9 + e * 0.3
    local np = #pits
    for i = 1, NH do
      local Hd = HEADS[i]
      local x, y = Hd.x, Hd.y
      local lv = base * (1 - kl * 0.45)
      local up = 0
      -- the circle pits: heads wheel round an open centre
      local skip = false
      for p = 1, np do
        local Pt = pits[p]
        local dx, dy = x - Pt.x, y - Pt.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d < Pt.r then
          if d < 2.6 then skip = true end
          local a = T * 1.8 * Pt.dir * (1 - d / Pt.r * 0.5)
          x, y = Pt.x + dx * cos(a) - dy * sin(a), Pt.y + dx * sin(a) + dy * cos(a)
          if d > Pt.r - 2.5 then lv = lv + 1.5 * c end
        end
      end
      if kl > 0.05 then x = x + sin(T * 0.8 + Hd.y * 0.09) * 1.3 * kl end
      if not K.playing then lv = lv + 0.4 * sin(T * 0.7 + Hd.r * 0.15) end
      if wf > 0 then
        local d = abs(Hd.r - wr)
        if d < 4 then up = (1 - d / 4) * wf end
      end
      if wl > 0 and abs(Hd.a - wedge_a) < 0.3 then up = math.max(up, wl * 0.8) end
      lv = lv + up * (3.5 + 2.5 * lo)
      -- kickless: lighters held up
      if kl > 0.2 and Hd.h < 0.22 then lv = lv + (2 + 2 * sin(T * 1.3 + Hd.h * 60)) * kl end
      if not skip and lv >= 0.5 then
        if up > 0.35 then P(lv, x, y - 1, 1, 2) else P(lv, x, y, 1, 1) end
      end
    end
    -- phones glinting with the hats
    for k = #sparks, 1, -1 do
      local Sp = sparks[k]
      local u = (T - Sp.t0) / Sp.life
      if u >= 1 or u < 0 then table.remove(sparks, k)
      else
        local Hd = HEADS[Sp.i % NH + 1]
        P((5 + 6 * Sp.v) * math.sin(PI * math.max(u, 0.15)), Hd.x, Hd.y - 1, 1, 1)
      end
    end
    K.grain(function(u)
      local Hd = HEADS[floor(u * NH) % NH + 1]
      return Hd.x, Hd.y
    end, 2 + hi * 24, 3 + hi * 6)

    -- follow-spots on the crowd
    for k = #spots, 1, -1 do
      local Sp = spots[k]
      local u = (T - Sp.t0) / (Sp.big and 0.6 or 0.4)
      if u >= 1 or u < 0 then table.remove(spots, k)
      else
        local Hd = HEADS[floor(Sp.x * 7) % NH + 1]
        K.ring((2.5 + 4 * Sp.v) * (1 - u), Hd.x, Hd.y, Sp.big and 6 or 4, 10)
      end
    end

    -- the lasers raking the crowd, a hot spot where each lands
    las_sv = las_sv - (las_swing * 9 + las_sv * 2.2) * K.DTS
    las_swing = clamp(las_swing + las_sv * K.DTS, -1.2, 1.2)
    local nl = 1 + floor(e * 1.2 + c * 0.6)
    local ll = (0.8 + hi * 1.6 + las_flash * 1.6) * (1 - kl * 0.5)
    for k, Em in ipairs(LAS3) do
      local base_a = PI / 2 + sin(T * (0.25 + e * 0.2) + k * 2) * 0.8 + las_swing * 0.4 * (k == 1 and 1 or -1)
      for j = 1, nl do
        local a = base_a + (j - (nl + 1) / 2) * 0.28
        if c > 0.3 then a = a + (K.hash(k * 9 + j, floor(T * 3)) - 0.5) * c * 1.2 end
        local len = 40 + 20 * K.hash(j + k * 4, 5)
        local ex, ey = Em[1] + cos(a) * len, Em[2] + sin(a) * len
        L(ll * 0.7, Em[1], Em[2], ex, ey)
        P(ll + 2, ex, ey, 2, 1)
      end
    end

    -- the pyros from above: a core, tongues thrown out, a smoke ring after
    for i = 1, NJ do
      local f, age = flame_now(i)
      local J = JX3[i]
      P(1.5 + lo * 1.5, J[1], J[2], 2, 1)
      if f > 0.03 then
        K.disc(5 + 7 * f, J[1] + 1, J[2], 0.8 + f * 2.2)
        for t = 0, 5 do
          local a = K.hash(t + i * 9, floor(T * 15)) * TAU
          local len = f * (3 + e * 3 + K.hash(t, i) * 3)
          L(3 + 5 * f, J[1] + 1, J[2], J[1] + 1 + cos(a) * len, J[2] + sin(a) * len * 0.8)
        end
      end
      if age > 0.2 and age < 1.6 then
        local u = (age - 0.2) / 1.4
        K.ring(1.8 * (1 - u) + 0.5, J[1] + 1, J[2], 3 + u * 10, 10, 0, TAU, 0.8, 1, i)
      end
    end
    for k = #queue, 1, -1 do
      if T >= queue[k].t then fire_jet(queue[k].i, queue[k].v); table.remove(queue, k) end
    end
    -- CO2 on a fill: plumes spreading from the stage corners
    local fa = T - fill_T
    if fa >= 0 and fa < 1.2 then
      local u = fa / 1.2
      for _, x in ipairs({30, 98}) do K.ring(4 * (1 - u), x, 10, 3 + u * 16, 14, 0, TAU, 0.7, 1.5, x) end
    end
    -- a ratchet rings out from the deck that many times
    local ra = T - rat_T
    if ra >= 0 and ra < 0.6 then
      for q = 0, math.min(rat_n, 8) - 1 do
        local a2 = ra - q * 0.05
        if a2 > 0 then K.ring((7 - q * 0.5) * (1 - ra / 0.6), OX, 15, 3 + a2 * 90, 14, 0.2, PI - 0.2, 0.8) end
      end
    end
  end

  ------------------------------------------------------------------
  function M.draw(S)
    local DT = K.DT
    slam = slam * exp(-DT / 0.15)
    las_flash = las_flash * exp(-DT / 0.12)
    -- the beat being written: on the clock while playing, slowly at rest
    if K.playing then rc = rc + DT / math.max(0.05, K.beat_sec)
    else rc = rc + K.DTS / 1.6 end
    if rc > 1.04 or not cur then
      push_ridge(0, K.kickless > 0.5 or not K.playing)
      if not K.playing then cur.kv = 0.5 end
    end
    if K.view == 2 then draw_land(S)
    elseif K.view == 3 then draw_arena(S)
    else draw_stage(S) end
  end

  M.init()
  return M
end
