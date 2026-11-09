-- trance. view 1: the main stage at the peak of the night, laser fans
-- sweeping out of the stage over a crowd in silhouette, a row of lamps on
-- the truss, light columns climbing behind as the riser builds; view 2: the
-- breakdown sunrise over the water, the sun climbing out of the haze, a
-- string of festoon lamps swagged across the sky and the crowd on the
-- shore; view 3: the riser itself: the LED wall behind the decks as seven
-- detuned saws, each column ramping up and falling, the DJ's arms up
-- against it and lasers breaking out of it on the drop.
--
-- the night has a shape: over the phrase the build rises (the columns
-- climb, the lasers speed up and multiply, the saws ramp higher), a fill
-- surges it, and when the kick comes back after a kickless stretch, or the
-- phrase turns over at the top of a build, the drop lands: every laser
-- opens, the glow floods and the hands go up, then it settles back over a
-- few bars. kickless stretches are the breakdown: the lasers lie down and
-- slow, the light goes soft and the sun comes up.
--
-- view 1: the kick flares the lasers and the stage glow, the snare and
-- clap throw hands up through the crowd and kick the fan wider, closed
-- hats spark the laser tips, an offbeat open hat lifts a lamp on the truss
-- and lets it fade (the lamps flicker in turn, never strobe), rides glint
-- the truss, percs blink the light columns' caps, a ratchet rakes a quick
-- chase of extra beams, a fill throws the fan into a spin. energy adds
-- beams and haze, chaos splits the fan into two emitters crossing.
-- view 2: the sun climbs out of the water through the breakdown and the
-- phrase, its path glittering on the waves; the kick pulses the glow on the
-- horizon, the snare and clap put hands up on the shore, open hats lift the
-- festoon lamps one by one, rides twinkle them all, closed hats glitter the
-- sun's path, percs ring a ripple on the water, a ratchet ripples a row of
-- them; on the drop lasers cross the sky over the crowd. energy brings the
-- crowd and the rays, chaos scatters the lasers and breaks the sun's path.
-- view 3: the columns of the wall ramp like saws, each at its own rate (the
-- detune spreads with energy and chaos), their ceiling rising through the
-- build; the kick pulses the whole wall, the snare and clap lift the DJ's
-- arms and flash the floor, open hats flicker the lamps along the wall's
-- top, closed hats spark the column tops, percs light a column, a ratchet
-- runs a chase across the wall, a fill floods it; on the drop lasers break
-- out of the DJ's hands. kickless the saws slow to a breathing swell.
--
-- the ears: view 1, the lows light the stage glow and swell the columns,
-- the mids widen and brighten the lasers, the highs fill the haze and
-- spark the beams, the level lifts the lamps; view 2, the lows light the
-- horizon's glow, the mids the sun and its rays, the highs the glitter on
-- the water and the stars, the level the festoon lamps; view 3, the lows
-- pump the wall's base, the mids the saw ramps' brightness, the highs the
-- column tops and the lamps, the level the floor's glow.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min = math.sin, math.cos, math.floor, math.max, math.min

  -- the night's shape (all views)
  local pp, riser, drop, sunr, kl_seen = 0, 0, 0, 0, 0
  local lamps, lampt                    -- the flickering lamps (8), round robin
  local hands                           -- crowd hands up, per dancer (16)
  local spin, fan, rake, rake_t          -- view 1: fill spin, fan kick, ratchet rake
  local ripples                          -- view 2: {x, t0, v}
  local saws, chase, chase_t, colf, flood -- view 3
  local NL, NH, NC = 8, 16, 14

  function M.init()
    pp, riser, drop, sunr, kl_seen = 0, 0, 0, 0, 0
    lamps, lampt = {}, 0
    for i = 1, NL do lamps[i] = 0 end
    hands = {}
    for i = 1, NH do hands[i] = 0 end
    spin, fan, rake, rake_t = 0, 0, 0, 0
    ripples = {}
    saws, colf = {}, {}
    for i = 1, NC do saws[i] = K.hash(i, 91); colf[i] = 0 end
    chase, chase_t, flood = 0, 0, 0
  end
  M.clear = M.init

  local function hand(n, lv)
    for _ = 1, n do
      local i = 1 + floor(K.rnd() * NH)
      hands[i] = max(hands[i], lv)
    end
  end
  local function lamp(v)
    lampt = lampt % NL + 1
    lamps[lampt] = max(lamps[lampt], 0.5 + 0.5 * v)
  end
  local function land()                  -- the drop
    drop = 1
    hand(NH, 1)
    flood = 1
  end

  function M.kick(v)
    v = K.num(v, 1)
    if kl_seen > 0.4 then land() end
    kl_seen = 0
  end
  function M.snare(v)
    v = K.num(v, 1)
    hand(2 + floor(K.energy * 3), 0.6 + 0.4 * v)
    fan = max(fan, 0.6 * v)
  end
  function M.clap(v)
    v = K.num(v, 1)
    hand(3 + floor(K.energy * 3), 0.7 + 0.3 * v)
    fan = max(fan, 0.8 * v)
  end
  function M.hat(v, open)
    v = K.num(v, 1)
    if open then lamp(v) end
  end
  function M.ride(v) v = K.num(v, 1); for i = 1, NL do lamps[i] = max(lamps[i], 0.25 * v) end end
  function M.perc(kind, v)
    v = K.num(v, 1)
    local k = 1 + (floor(K.num(kind, 1)) * 5) % NC
    colf[k] = max(colf[k], 0.5 + 0.5 * v)
    if #ripples >= 6 then table.remove(ripples, 1) end
    ripples[#ripples + 1] = {x = 20 + K.rnd() * 88, t0 = K.T, v = v}
  end
  function M.tom(v) M.perc(7, v) end
  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    rake, rake_t = n, K.T
    chase, chase_t = n, K.T
    for k = 1, min(n, 4) do
      if #ripples >= 6 then table.remove(ripples, 1) end
      ripples[#ripples + 1] = {x = 30 + k * 16, t0 = K.T + k * 0.05, v = 0.8}
    end
  end
  function M.fill() spin = 1; flood = max(flood, 0.6) end
  function M.bar(S)
    local pl = floor(K.num(S and S.phrase_len, 16))
    if not (pl >= 1 and pl <= 256) then pl = 16 end
    local pos = K.num(S and S.phrase_pos, 1) % pl
    if pos == 0 and pp > 0.7 and K.kickless < 0.5 then land() end
  end

  ------------------------------------------------------------------ helpers
  -- a crowd's top edge (heads, hands up) as a profile, 2 px columns
  local prof = {}
  local function crowd(y0, sc, e, kl, bob)
    -- (the back of the crowd: a ragged line of far heads)
    for c = 0, 64 do prof[c] = y0 + (4 + 1.5 * sin(c * 1.3) + K.hash(c, 7) * 1.5) * sc end
    for i = 1, NH do
      local on = K.hash(i, 3) < 0.5 + e * 0.5 or i % 3 == 0
      if on then
        -- (chaos: the crowd jostles)
        local cj = K.chaos * K.chaos
        local x = (i - 0.5) * 128 / NH + (K.hash(i, 1) - 0.5) * 5 + sin(K.T * (0.6 + kl * 0.5) + i) * (1 + kl * 1.5)
          + sin(K.T * 5.3 + i * 2.1) * cj * 4
        local r = (2.4 + K.hash(i, 2) * 1.2) * sc
        local hy = y0 + K.hash(i, 4) * 3 * sc + bob * (0.5 + 0.5 * K.hash(i, 5)) + sin(K.T * 4.1 + i * 1.3) * cj * 3
        for c = floor((x - r * 2.2) / 2), floor((x + r * 2.2) / 2) do
          if c >= 0 and c <= 64 then
            local dx = math.abs(c * 2 + 1 - x)
            local top = hy + r * 1.6 + max(0, dx - r) * 0.5
            if dx <= r then top = math.min(top, hy - math.sqrt(r * r - dx * dx) + r * 0.2) end
            if top < prof[c] then prof[c] = top end
          end
        end
        local h = hands[i]
        if h > 0.12 then
          local up = h ^ 0.5 * (7 + e * 3) * sc
          for _, sd in ipairs({-1, 1}) do
            local c = floor((x + sd * r * 1.4) / 2)
            if c >= 0 and c <= 64 then prof[c] = min(prof[c], hy - up) end
          end
        end
      end
    end
  end

  -- a glow band behind the crowd, solid rows, the crowd cut out of it
  local function glow(y0, y1, x0, x1, lv)
    for y = y0, y1 do
      local l = lv(y)
      if l >= 0.5 then K.row_above(l, y, prof, x0, x1) end
    end
  end

  ---------------------------------------------------------------- view 1
  local EX, EY = 64, 41                   -- the laser emitter
  local sweep = 0

  local function draw1(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl, mid, amp = A[K.LO], A[K.HI], K.kickless, A[K.MID], A[K.AMP]
    local playing = K.playing and 1 or 0
    -- the fan sweeps: slow at rest, faster as the build rises, a fill spins it
    sweep = sweep + K.DTS * (0.25 + playing * (0.35 + riser * 0.9 + drop * 0.5) * (1 - kl * 0.6) + spin * 3)

    -- the truss and its towers
    line(1.5, 14, 6, 114, 6)
    line(1.2, 14, 9, 114, 9)
    for x = 14, 106, 8 do line(1, x, 6, x + 4, 9); line(1, x + 4, 9, x + 8, 6) end
    line(1.5 + K.bar_pulse, 14, 6, 14, 44)
    line(1.5 + K.bar_pulse, 114, 6, 114, 44)
    line(1, 17, 9, 17, 44)
    line(1, 111, 9, 111, 44)
    -- the lamps: each lifts on an offbeat open hat and fades, in turn
    for i = 1, NL do
      local x = 20 + (i - 1) * 12.5
      local l = lamps[i]
      put(1.5 + l * 9 + amp * 1.5 + K.env.ride * 2, x, 10, 3, 2)
      if l > 0.1 then
        for k = 1, 3 do put(l * (4 - k) * 0.8, x - k, 11 + k * 2, 3 + k * 2, 1) end
      end
    end

    -- the light columns: seven of them climbing behind the stage with the build
    local ch = 4 + riser * 26 + drop * 6 + lo * 3 - kl * 2
    for k = 0, 6 do
      local x = 30 + k * 11
      local hh = ch * (0.75 + 0.25 * sin(T * (0.7 + k * 0.13) + k * 1.9)) + c * 5 * (0.5 + 0.5 * sin(T * 2.1 + k * 2.3))
      local top = EY - hh
      local cl = 1 + riser * 1.5 + drop * 1.5 + lo * 0.8 + colf[k + 1] * 3
      put(cl, x, top, 3, EY - top)
      put(min(12, cl + 2 + colf[k + 1] * 5 + K.env.perc * 2), x, top, 3, 1)
    end

    -- the lasers: a fan from the stage, more beams with energy, the build
    -- and the drop; chaos adds a second emitter, its fan crossing the first
    local nb = clamp(floor(3 + e * 4 + riser * 3 + drop * 4), 3, 14)
    local spread = (0.6 + mid * 0.5 + fan * 0.6 + drop * 0.5) * (1 - kl * 0.5)
    local base = -math.pi / 2 + sin(sweep) * 0.5
    local ll = (1.6 + mid * 2 + K.env.kick * 3 + drop * 2 + riser) * (1 - kl * 0.5)
    local emit = {{EX, EY, 1}}
    if c > 0.4 then emit[2] = {EX - 34, EY, -1}; emit[3] = {EX + 34, EY, -1} end
    for ei, E in ipairs(emit) do
      local b0 = ei == 1 and base or (-math.pi / 2 - sin(sweep * 0.8 + ei) * 0.5)
      local n = ei == 1 and nb or min(3, floor(nb * c * 0.4))
      local lv = ei == 1 and ll or ll * c * 0.5
      for k = 0, n - 1 do
        local u = n > 1 and (k / (n - 1) - 0.5) or 0
        local a = b0 + u * spread * 2
        -- kickless the beams lie down toward a flat sheet
        a = a + (u >= 0 and 1 or -1) * kl * 0.6
        local len = 70
        local x1, y1 = E[1] + cos(a) * len, E[2] + sin(a) * len
        local bl = lv * (0.7 + 0.3 * sin(T * 3 + k))
        if rake > 0 then
          local ru = (T - rake_t) / 0.45
          if ru < 1 and floor(ru * rake) % n == k then bl = bl + 5 end
        end
        line(min(11, bl), E[1], E[2], x1, y1)
        -- (the tip sparks with the closed hats and the highs)
        if ei == 1 then
          local tx, ty = E[1] + cos(a) * (30 + k % 3 * 6), E[2] + sin(a) * (30 + k % 3 * 6)
          put(min(12, (K.env.hat * 8 + hi * 3) * (0.5 + 0.5 * sin(T * 11 + k * 2))), tx, ty, 1, 1)
        end
      end
    end
    put(min(13, 6 + K.env.kick * 6), EX - 1, EY - 1, 3, 2)

    -- the haze in the beams
    K.haze(16, 12, 112, 38, 0.05 + e * 0.08 + hi * 0.22 + kl * 0.1, 1, T * 5)

    -- the stage glow behind the crowd, the crowd black against it
    crowd(51, 1.35, e, kl, K.duck * (1 - kl) * 1.2)
    local gl = 1.2 + lo * 1.2 + K.env.kick * 1.5 + drop * 2 + flood * 2
    -- (brightest at the stage's middle, falling off to the sides)
    for k, span in ipairs({{4, 124, 0.45}, {26, 102, 0.75}, {44, 84, 1}}) do
      glow(30, 58, span[1], span[2], function(y)
        local u = clamp((y - 28) / 24, 0, 1)
        return clamp(gl * u * u * 1.4 * span[3], 0, 7)
      end)
    end
    -- the rim light on the near shoulders
    for cc = 0, 63 do
      local top = prof[cc]
      if top < 63 and top > 40 then put(1 + gl * 0.35, cc * 2, top + 1, 2, 1) end
    end
    K.grain(function(u, v) return 16 + u * 96, 12 + v * 28 end, 2 + hi * 10 + e * 4, 2 + hi * 4)
  end

  ---------------------------------------------------------------- view 2
  local HZ = 38                              -- the horizon over the water

  local function draw2(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl, mid, amp = A[K.LO], A[K.HI], K.kickless, A[K.MID], A[K.AMP]
    -- the sun climbs through the breakdown and the phrase
    local up = clamp(sunr * 0.75 + pp * 0.35, 0, 1)
    local sr = 7 + mid * 1.5
    local sx, sy = 64 + sin(T * 0.04) * 4, HZ + 6 - up * 24

    -- the sky: solid bands warming toward the horizon as the sun comes up
    -- (round the sun, wider and warmer as it climbs and with energy)
    for b = 0, 3 do
      local y0 = HZ - 2 - b * 3
      local hw = (26 + up * 30 + e * 14) * (1 - b * 0.2)
      local l = (0.7 + up * 2 + lo * 0.6 + K.env.kick * 0.6 + e * 0.5) * (1 - b * 0.22)
      if l >= 0.5 then put(l, sx - hw, y0, hw * 2, 2) end
    end
    -- stars fading out as the light comes
    for k = 0, 23 do
      local x, y = floor(K.hash(k, 61) * 127), 1 + floor(K.hash(k, 62) * 20)
      local tw = 0.5 + 0.5 * sin(T * (0.7 + K.hash(k, 63) * 2) + k)
      put((1 + tw * (1 + hi * 5)) * (1 - up * 0.7), x, y, 1, 1)
    end
    -- the sun and its rays (cut at the horizon), the mids light them
    for dy = -floor(sr), floor(sr) do
      local y = sy + dy
      if y < HZ then
        local hw = math.sqrt(max(0, sr * sr - dy * dy))
        if hw >= 0.5 then put(3 + mid * 3 + up * 2, sx - hw, y, hw * 2, 1) end
      end
    end
    local nr = floor(8 + e * 8)
    for k = 0, nr - 1 do
      local a = -math.pi + (k + 0.5) / nr * math.pi + sin(T * 0.1) * 0.05
      local r0, r1 = sr + 3, sr + 8 + up * 10 + mid * 8 + (k % 2) * 4
      local x0, y0 = sx + cos(a) * r0, sy + sin(a) * r0
      local x1, y1 = sx + cos(a) * r1, sy + sin(a) * r1
      if y0 < HZ and y1 < HZ then line(1 + mid * 2 + up * 1.5, x0, y0, x1, y1) end
    end

    -- the water: the sun's path glittering, ripples where the percs land
    line(2 + lo * 2 + K.env.kick * 2, 0, HZ, 127, HZ)
    for y = HZ + 2, 58, 3 do
      local u = (y - HZ) / 20
      local w = 4 + u * 18 + up * 8
      local brk = c > 0.3 and sin(T * 4 + y) * c * 6 or 0
      for k = 0, 5 do
        local gx = sx - w + ((k * 7 + y * 5 + T * (6 + y % 4)) % (w * 2)) + brk
        local tw = 0.5 + 0.5 * sin(T * 7 + k * 2.3 + y)
        put((1 + up * 3 + K.env.hat * 4 + hi * 5) * tw * (1 - u * 0.4), gx, y, 2 + floor(u * 2), 1)
      end
    end
    for i = #ripples, 1, -1 do
      local R = ripples[i]
      local u = (T - R.t0) / 1.2
      if u >= 1 then table.remove(ripples, i)
      elseif u >= 0 then
        K.ring((2 + 5 * R.v) * (1 - u), R.x, 50, 2 + u * 14, 12, 0, K.TAU, 0.25)
      end
    end

    -- the festoon string swagged across the sky, its lamps flickering
    local px, py
    for k = 0, 16 do
      local x = k * 8
      -- (chaos: the wind gets up and swings it)
      local y = 6 + 6 * (1 - ((k - 8) / 8) ^ 2) + c * c * 3 * sin(T * 2.3 + k * 0.7) * (1 - ((k - 8) / 8) ^ 2)
      if px then line(1.2, px, py, x, y) end
      px, py = x, y
      if k % 2 == 1 then
        local i = (k // 2) % NL + 1
        put(1.5 + lamps[i] * 9 + amp * 1.5, x - 1, y + 1, 2, 2)
      end
    end

    -- on the drop, lasers cross the sky from the shore
    local dl = drop * (3 + mid * 3) + riser * 2 * (1 - kl)
    if dl >= 0.6 then
      for k = 0, 5 do
        local a = -math.pi / 2 + (k - 2.5) * 0.25 + sin(T * 1.3 + k) * (0.25 + c * 0.4)
        local ox = k < 3 and 20 or 108
        line(dl, ox, 56, ox + cos(a) * 80, 56 + sin(a) * 80)
      end
    end

    -- the crowd on the shore, black against the glow on the water
    crowd(51, 1.2, e, kl, K.duck * (1 - kl))
    local gw = 24 + up * 26 + e * 12 + flood * 10
    glow(HZ + 1, 60, floor(sx - gw), floor(sx + gw), function(y)
      local u = 1 - (y - HZ) / 24
      return (0.8 + up * 1.4 + lo * 0.6 + e * 0.4 + flood * 1.5) * u
    end)
    K.grain(function(u, v) return u * 128, HZ + 2 + v * 14 end, 2 + hi * 10, 2 + hi * 4)
  end

  ---------------------------------------------------------------- view 3
  local WX0, WX1, WY0, WY1 = 8, 120, 5, 46   -- the LED wall

  local function draw3(S)
    local T, DT, DTS, e, c = K.T, K.DT, K.DTS, K.energy, K.chaos
    local lo, hi, kl, mid, amp = A[K.LO], A[K.HI], K.kickless, A[K.MID], A[K.AMP]
    local playing = K.playing and 1 or 0
    -- seven detuned saws across the wall (each column a voice, twice over)
    local rate = (0.2 + playing * (0.3 + riser * 0.6)) / max(0.25, K.beat_sec) * (1 - kl * 0.6)
    local det = 0.04 + e * 0.08 + c * 0.25
    local ceil_ = 0.35 + riser * 0.55 + drop * 0.3 + flood * 0.2
    local cw = (WX1 - WX0) / NC

    -- the wall's frame
    line(1.5, WX0 - 2, WY0 - 1, WX0 - 2, WY1)
    line(1.5, WX1 + 1, WY0 - 1, WX1 + 1, WY1)
    -- the DJ stands in front of it: the columns behind are cut round them
    local dx, dy = 64 + sin(T * 1.1) * 0.6, 40 + K.duck * (1 - kl) * 0.8
    for i = 1, NC do
      local voice = (i - 1) % 7
      saws[i] = (saws[i] + DTS * rate * (1 + (voice - 3) * det)) % 1
      local ph = saws[i]
      -- kickless: a breathing swell instead of the ramp
      local v = ph + (0.5 + 0.5 * sin(T * 0.8 + i * 0.6) - ph) * kl
      local hgt = clamp(v * ceil_ + lo * 0.12 + colf[i] * 0.1, 0, 1) * (WY1 - WY0)
      local x = WX0 + (i - 1) * cw
      local top = WY1 - hgt
      if chase > 0 then
        local cu = (T - chase_t) / 0.5
        if cu < 1 and floor(cu * NC) == i - 1 then colf[i] = max(colf[i], 0.7) end
      end
      -- the ceiling mark, the lit ramp (brighter as it climbs), its top
      put(1.5 + riser * 2, x + 1, WY1 - ceil_ * (WY1 - WY0), cw - 3, 1)
      local bot = WY1
      if x + cw > dx - 7 and x < dx + 7 then bot = min(bot, dy - 4) end
      local cl = 1 + mid * 1.5 + v * 1.5 + drop * 1.5 + flood * 2 + colf[i] * 3
      if bot - top >= 1 then put(min(10, cl), x + 1, top, cw - 3, bot - top) end
      local tl = cl + 2 + K.env.hat * 4 + hi * 3
      if top < bot then put(min(12, tl), x + 1, top - 1, cw - 3, 1) end
    end
    -- across the top of the wall, the sum of the seven saws: the supersaw
    local px, py
    local amp_s = 5 + riser * 6 + mid * 3
    for k = 0, 28 do
      local u = k / 28
      local sum = 0
      for vv = 0, 6 do sum = sum + ((u * 2.5 * (1 + (vv - 3) * det) + saws[vv + 1]) % 1 - 0.5) end
      local x, y = WX0 + u * (WX1 - WX0), WY0 + 9 - sum / 7 * 2 * amp_s * (1 - kl * 0.5)
      if px then line(1.2 + mid * 2 + riser * 1.5, px, py, x, y) end
      px, py = x, y
    end
    -- the lamps along the wall's top flicker on the offbeat open hats
    for i = 1, NL do
      local x = WX0 + (i - 0.5) * (WX1 - WX0) / NL
      put(1.5 + lamps[i] * 9 + hi * 2, x - 2, 1, 4, 2)
    end

    -- the floor's glow and the booth
    put(1 + amp * 1.5 + K.env.kick * 1.5 + flood * 2, 0, WY1 + 1, 128, 2)
    line(2.5, 30, 54, 98, 54)
    put(1.5, 34, 55, 60, 2)
    put(3 + K.env.kick * 4, 44, 52, 4, 1)
    put(3 + K.env.hat * 5, 80, 52, 4, 1)
    -- the DJ: head and shoulders against the wall, arms up on the snare,
    -- the clap and the drop
    local arm = max(K.env.snare, K.env.clap, drop * 0.8, hands[8], flood * 0.7)
    -- (black against the wall, a rim of light round the head and shoulders)
    K.ring(2.5 + flood * 3 + K.env.kick * 2, dx, dy, 3.2, 10)
    line(2.5, dx - 6, dy + 4, dx - 3, dy + 3)
    line(2.5, dx + 3, dy + 3, dx + 6, dy + 4)
    local ah = 5 + arm * 13
    for _, sd in ipairs({-1, 1}) do
      line(3 + arm * 6, dx + sd * 5, dy + 4, dx + sd * (7 + arm * 4), dy + 4 - ah)
    end
    -- on the drop, lasers break out of the hands
    local lz = drop * (4 + mid * 3)
    if lz >= 0.6 then
      for _, sd in ipairs({-1, 1}) do
        local hx, hy = dx + sd * (7 + arm * 4), dy + 4 - ah
        for k = 0, 2 do
          local a = -math.pi / 2 + sd * (0.3 + k * 0.35) + sin(T * 2 + k) * 0.1
          line(lz * (1 - k * 0.2), hx, hy, hx + cos(a) * 60, hy + sin(a) * 60)
        end
      end
    end
    -- the crowd's hands at the foot of the screen
    crowd(60, 0.8, e, kl, K.duck * (1 - kl))
    for cc = 0, 63 do
      local top = prof[cc]
      if top < 62 then put(1.5 + flood * 3 + drop * 2, cc * 2, top, 2, 1) end
    end
    K.grain(function(u, v) return WX0 + u * (WX1 - WX0), WY0 + v * (WY1 - WY0) end, 1 + hi * 8, 2 + hi * 4)
  end

  function M.draw(S)
    local DT = K.DT
    local pl = floor(K.num(S and S.phrase_len, 16))
    if not (pl >= 1 and pl <= 256) then pl = 16 end
    local pto = clamp((K.num(S and S.phrase_pos, 0) % pl + K.bar_ph) / pl, 0, 1)
    pp = K.follow(pp, pto, 0.5, DT)
    -- the build: the phrase's second half, steeper toward the end; a fill surges it
    local kl = K.kickless
    riser = K.follow(riser, clamp(pp * pp * 1.1 + K.env.fill * 0.4, 0, 1) * (1 - kl * 0.7), 0.4, DT)
    sunr = K.follow(sunr, kl, 2.5, DT)
    kl_seen = math.max(kl_seen, kl)
    drop = drop * math.exp(-DT / 3)
    flood = flood * math.exp(-DT / 0.6)
    spin = spin * math.exp(-DT / 0.8)
    fan = fan * math.exp(-DT / 0.25)
    for i = 1, NL do lamps[i] = lamps[i] * math.exp(-DT / 0.35) end
    for i = 1, NH do hands[i] = hands[i] * math.exp(-DT / (0.5 + drop)) end
    for i = 1, NC do colf[i] = colf[i] * math.exp(-DT / 0.2) end
    if K.view == 2 then draw2(S) elseif K.view == 3 then draw3(S) else draw1(S) end
  end

  M.init()
  return M
end
