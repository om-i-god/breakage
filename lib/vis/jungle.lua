-- jungle. view 1: a tower block at night in the rain with a pirate-radio
-- antenna on the roof, windows lighting with the hits and the sub glowing at
-- its base; view 2: a dense jungle canopy at night, vines swaying, leaves
-- flicking on the hats, rain falling and break slices flashing as fireflies;
-- view 3: a river under the forest at night, the moon's path on the water
-- and every hit landing on it as rings.
--
-- view 1: the block stands between two lower ones against a sodium sky,
-- with the far towers of the estate dim behind, their aviation lamps
-- breathing. homes are lit here and there (more with energy, and more as
-- the phrase goes on) and a TV flickers (a vox turns it up); the rolling
-- break climbs the block window by window (a reversed slice runs back
-- down), percussion and closed hats flick windows, an open hat runs the
-- stairwell lights up the side, a clap lights the top floors, a ratchet
-- runs a burst along one floor. the snare fires a pulse off the antenna,
-- rings rising into the rain; the sub kick lights the lobby and pools a
-- glow round the base. a car's lights run along the wet street every bar
-- and closed hats splash the puddles. the rain follows the hats and the
-- energy, falling harder and denser; chaos shears the floors sideways and
-- doubles the pulses; kickless, the base goes dark, fog settles on the
-- street and the station keeps sending slow pulses of its own.
-- view 2: inside the forest, under the canopy. trunks rise into a ragged
-- roof of leaves, fainter ones behind; vines hang and sway, their leaves
-- flicking on the closed hats, and an open hat shakes the rain off the
-- clumps in a run of drips; two big fronds in front jolt on the snare; the
-- kick lifts a glow off the forest floor. fireflies drift, more of them as
-- the phrase goes on, and each break slice flashes one of them so a rolling
-- break runs across the swarm; percussion opens a pair of eyes in the
-- undergrowth. energy wakes more fireflies and the rain, chaos tangles the
-- vines and splits the fireflies, kickless the floor mist thickens.
-- view 3: the far bank's trees stand black against the moon; its path
-- lies on the water and breaks up as the rings cross it. the kick drops a
-- big ring near us and swells the water, the snare a ring and a splash,
-- claps a pair; closed hats are raindrops, open hats a fish jumping; congas
-- and bongos plop rings by the reeds, bells glint on the path; break slices
-- land in a line across the river so a rolling break walks over it, a
-- ratchet strings a run of drops, a fill brings a squall. fireflies hang
-- over the water with their reflections under them. energy brings the rain
-- and the fireflies, chaos fractures the moon's path and jitters the rings,
-- kickless a mist lies on the water and the reeds sway slow.
--
-- the ears: view 1, the lows light the lobby and the base, the mids wake
-- the homes and the side blocks, the highs drive the rain, the level burns
-- the sodium sky; view 2, the lows lift the floor glow, the mids heave the
-- clumps and light their undersides, the highs glint the wet leaves and the
-- fireflies, the level catches the roof in moonlight; view 3, the lows
-- swell the water and widen the moon's path, the mids light the far bank
-- and the mist, the highs glint the ripples, the level brightens the moon.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, exp = math.sin, math.cos, math.floor, math.max, math.min,
    math.abs, math.exp

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

  local function phrase(S)
    local pl = K.num(S.phrase_len, 16)
    if not (pl >= 1 and pl < 1e4) then pl = 16 end
    local pp = K.num(S.phrase_pos, 0)
    if not (pp >= 0 and pp < 1e4) then pp = 0 end
    return clamp((pp + K.bar_ph) / pl, 0, 1)
  end

  local GY = 57
  local TX0, TX1, TTOP = 46, 82, 14       -- the tower
  local NCOL, NFL = 7, 10
  local AX = 72                           -- the antenna mast

  -- the sky's lower edge: the blocks' tops by 2px column
  local PROF = {}
  for c = 0, 64 do
    local x = c * 2
    local top = 64
    if x >= 4 and x < 32 then top = 26 end
    if x >= 32 and x < 44 then top = 38 end
    if x >= TX0 and x < TX1 then top = TTOP end
    if x >= 86 and x < 98 then top = 40 end
    if x >= 98 and x < 124 then top = 31 end
    PROF[c] = math.min(top, GY)
  end
  -- the estate's far towers, dim behind: {x0, x1, top}
  local FAR = {{0, 10, 20}, {20, 30, 17}, {36, 44, 24}, {84, 94, 21}, {102, 110, 15}, {116, 128, 22}}
  local FARW = {}
  for b = 1, #FAR do
    local B = FAR[b]
    for y = B[3] + 3, 44, 3 do
      for x = B[1] + 2, B[2] - 2, 3 do
        local i = #FARW + 1
        if K.hash(i, 57) < 0.3 then FARW[#FARW + 1] = {x = x, y = y, h = K.hash(i, 58)} end
      end
    end
  end
  local function sky_at(x, y) return y < PROF[clamp(floor(x) // 2, 0, 64)] end
  -- the side blocks' windows: fixed, a few lit
  local SIDE = {}
  for _, b in ipairs({{6, 28, 26}, {100, 122, 31}, {34, 42, 38}, {88, 96, 40}}) do
    for x = b[1], b[2] - 2, 4 do
      for y = b[3] + 3, GY - 3, 4 do
        local i = #SIDE + 1
        SIDE[i] = {x = x, y = y, h = K.hash(i, 51)}
      end
    end
  end

  local win, pulses, pend, rainb, kglow, flick, shear, fl_off
  local rain_ph, tip_t, auto_t
  local flies, eyes, frond, canopy_fl, leaf_fl
  local car_t, stairs, splash, tv, drips      -- view 1 / 2
  local rings, fish, squall, swell            -- view 3
  local rain_acc, gust = 0, 0

  local NFLY = 12

  function M.init()
    win = {}
    for i = 1, NCOL * NFL do win[i] = 0 end
    pulses, pend = {}, {}
    rainb, kglow, flick = 0, 0, {}
    shear, fl_off = {}, {}
    for f = 1, NFL do shear[f], fl_off[f] = 0, 0 end
    rain_ph, tip_t, auto_t = 0, -9, 0
    flies = {}
    for i = 1, NFLY do
      flies[i] = {fl = 0, ph = K.hash(i, 81) * 6.28, x0 = 8 + K.hash(i, 82) * 112, y0 = 22 + K.hash(i, 83) * 28}
    end
    eyes = {}
    frond = {0, 0, 0, 0}                 -- left angle, vel, right angle, vel
    canopy_fl, leaf_fl = 0, {}
    for i = 1, 6 do leaf_fl[i] = 0 end
    car_t, stairs, splash, tv, drips = -9, {}, {}, 0, {}
    rings, fish, squall, swell = {}, {}, 0, 0
    rain_acc, gust = 0, 0
  end
  M.clear = M.init

  local function wi(col, f) return (f - 1) * NCOL + col end
  local function light(col, f, lv)
    col = clamp(col, 1, NCOL); f = clamp(f, 1, NFL)
    local i = wi(col, f)
    win[i] = math.max(win[i], lv)
  end
  local function pulse(lv, sp)
    if #pulses >= 8 then table.remove(pulses, 1) end
    pulses[#pulses + 1] = {t0 = K.T, lv = lv, sp = sp or 40, dx = 0}
    if K.chaos > 0.45 and #pulses < 8 then
      pulses[#pulses + 1] = {t0 = K.T - 0.05, lv = lv * 0.6, sp = (sp or 40) * 1.3, dx = (K.rnd() - 0.5) * 10 * K.chaos}
    end
    tip_t = K.T
  end

  -- a ring on the river: u across (0..1), d depth (0 far .. 1 near), size, level
  local function ring(u, d, sz, lv, delay)
    if #rings >= 18 then table.remove(rings, 1) end
    rings[#rings + 1] = {u = u, d = d, sz = sz, lv = lv, t0 = K.T + (delay or 0)}
  end

  function M.kick(v)
    v = K.num(v, 1)
    kglow = math.max(kglow, 0.4 + 0.6 * v)
    swell = math.max(swell, v)
    ring(0.35 + K.rnd() * 0.3, 0.75 + K.rnd() * 0.2, 1.6, 5 + 4 * v)
  end
  function M.snare(v)
    v = K.num(v, 1)
    ring(0.15 + K.rnd() * 0.7, 0.3 + K.rnd() * 0.5, 1, 4 + 4 * v)
    pulse(4 + 6 * v, 40)
    light(1 + math.floor(K.rnd() * NCOL), 1 + math.floor(K.rnd() * 3), 6 + 5 * v)
    canopy_fl = math.max(canopy_fl, v)
    frond[2] = frond[2] - 3 * v
    frond[4] = frond[4] + 3 * v
  end
  function M.clap(v)
    v = K.num(v, 1)
    pulse(3 + 4 * v, 50); canopy_fl = math.max(canopy_fl, 0.6)
    for c = 1, NCOL do light(c, 1, 4 + 3 * v); light(c, 2, 3 + 2 * v) end
    local u = 0.2 + K.rnd() * 0.6
    ring(u, 0.5, 0.7, 4 * v); ring(u + 0.08, 0.45, 0.6, 3 * v, 0.06)
  end
  function M.rim(v) pulse(2 + 3 * K.num(v, 1), 60) end
  function M.hat(v, open)
    v = K.num(v, 1)
    if open then
      if #stairs >= 3 then table.remove(stairs, 1) end
      stairs[#stairs + 1] = K.T
      for k = 1, 4 do
        if #drips >= 14 then table.remove(drips, 1) end
        drips[#drips + 1] = {c = 1 + floor(K.rnd() * 14), t0 = K.T + k * 0.05}
      end
      if #fish >= 2 then table.remove(fish, 1) end
      fish[#fish + 1] = {u = 0.15 + K.rnd() * 0.7, d = 0.3 + K.rnd() * 0.4, t0 = K.T, dir = K.rnd() < 0.5 and -1 or 1}
    else
      if #splash >= 6 then table.remove(splash, 1) end
      splash[#splash + 1] = {x = 4 + K.rnd() * 120, t0 = K.T}
      ring(K.rnd(), K.rnd() * 0.9, 0.35, 2 + 3 * v)
    end
    rainb = math.min(1, rainb + 0.12 * v + (open and 0.1 or 0))
    if K.rnd() < 0.5 then light(1 + math.floor(K.rnd() * NCOL), 1 + math.floor(K.rnd() * NFL), 3 + 2 * v) end
    local i = 1 + math.floor(K.rnd() * 6)
    leaf_fl[i] = 1
    if open then leaf_fl[i % 6 + 1] = 1 end
  end
  function M.ride(v)
    tip_t = K.T
    rainb = math.min(1, rainb + 0.06)
    leaf_fl[1 + math.floor(K.rnd() * 6)] = 0.6
  end
  function M.shaker(v) rainb = math.min(1, rainb + 0.08) end
  local function eye()
    if #eyes >= 3 then return end
    eyes[#eyes + 1] = {x = 10 + K.rnd() * 100, y = 44 + K.rnd() * 9, t0 = K.T}
  end
  function M.perc(kind, v)
    v = K.num(v, 1)
    kind = floor(K.num(kind, 1))
    if kind == 16 then tv = math.max(tv, v) end
    light(1 + math.floor(K.rnd() * NCOL), 1 + math.floor(K.rnd() * NFL), 4 + 5 * v)
    if K.rnd() < 0.5 then eye() end
    if kind == 3 or kind == 4 or kind == 6 or kind == 21 then
      flick[1 + math.floor(K.rnd() * #SIDE)] = K.T
      ring(0.5 + (K.rnd() - 0.5) * 0.2, 0.15 + K.rnd() * 0.3, 0.4, 6 * v)
    else
      ring(K.rnd() < 0.5 and 0.06 or 0.94, 0.6 + K.rnd() * 0.3, 0.6, 3 + 3 * v)
    end
  end
  function M.tom(v) light(1 + math.floor(K.rnd() * NCOL), NFL - math.floor(K.rnd() * 3), 6); eye() end
  function M.tick(k)
    local i = 1 + math.floor(K.rnd() * #SIDE)
    flick[i] = K.T
  end
  function M.brk(i, n, rev)
    i, n = K.num(i, 1), math.max(1, K.num(n, 8))
    local u = clamp((i - 1) / n, 0, 0.999)
    -- the roll climbs the block (down, reversed), zigzagging across it
    local f = rev and (1 + math.floor(u * NFL)) or (NFL - math.floor(u * NFL))
    local col = 1 + (math.floor(i) * 3) % NCOL
    light(col, f, 8)
    local fly = flies[1 + (math.floor(i) - 1) % NFLY]
    if fly then fly.fl = 1 end
    ring(rev and 1 - u or u, 0.55, 0.45, 4)
  end
  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 12)
    local f = 1 + math.floor(K.rnd() * NFL)
    for k = 0, n - 1 do
      if #pend < 16 then pend[#pend + 1] = {t = K.T + k * 0.04, col = 1 + k % NCOL, f = f, fly = 1 + (k * 5) % NFLY} end
    end
    pulse(3 + n * 0.5, 70)
    local u0, d0 = 0.1 + K.rnd() * 0.5, 0.3 + K.rnd() * 0.5
    for k = 0, n - 1 do ring(u0 + k * 0.05, d0, 0.35, 4, k * 0.05) end
  end
  function M.fill()
    local f = 1 + math.floor(K.rnd() * NFL)
    for c = 1, NCOL do light(c, f, 7) end
    pulse(8, 30)
    for i = 1, NFLY, 2 do flies[i].fl = math.max(flies[i].fl, 0.7) end
    squall = 1
  end
  function M.bar() car_t = K.T; gust = 1 end

  -- rain: drops at fixed hashes, falling by a shared phase
  local function rain(n, x0, x1, ytop, lvl, slant, len)
    local w = x1 - x0 + 20
    for i = 1, n do
      local sp = 0.75 + 0.5 * K.hash(i, 3)
      local y = (K.hash(i, 2) * 74 + rain_ph * sp) % 74 - 6
      if y > ytop then
        local x = x0 - 10 + (K.hash(i, 1) * w + y * slant) % w
        local fg = i % 5 == 0
        local l = fg and len + 2 or len
        line(fg and lvl + 1 or lvl, x, y, x + slant * l, y + l)
      end
    end
  end

  -- a stipple row: dashes across the open runs above prof
  local function stipple(y, d, lv)
    if d < 0.06 then return end
    local gap = math.max(2, math.floor(7 - d * 5))
    local off = (y // 2) % 2
    local run
    for c = 0, 64 do
      local open = c < 64 and y < PROF[c]
      if open then run = run or c * 2
      elseif run then K.dashes(lv, y, 1, gap, off, run, c * 2); run = nil end
    end
  end

  ----------------------------------------------------------------------
  -- view 1: the tower block
  ----------------------------------------------------------------------
  local function draw_block(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless

    -- the sodium sky, thickest at the horizon; the level of the mix (amp)
    -- burns it brighter and lower
    for y = 10, GY - 1, 2 do
      local u = (y - 10) / (GY - 10)
      stipple(y, u * (u + amp * 0.5) * (0.7 + e * 0.5 + lo * 0.2), 1 + u + amp * 1.5 * u)
    end
    local ph = phrase(S)
    -- the far towers: dim edges in the sky's glow, a few homes, two
    -- aviation lamps breathing
    for b = 1, #FAR do
      local B = FAR[b]
      for x = B[1], B[2] - 1, 2 do
        if sky_at(x, B[3]) then put(1, x, B[3], 2, 1) end
      end
      for _, x in ipairs({B[1], B[2] - 1}) do
        for y = B[3], 44, 4 do
          if sky_at(x, y) then line(1, x, y, x, math.min(y + 3, 44)) end
        end
      end
    end
    for i = 1, #FARW do
      local W = FARW[i]
      if sky_at(W.x, W.y) and W.h < 0.3 + e * 0.3 + md * 0.3 then
        put(1 + W.h * 2 + md + 0.5 * sin(T * (0.2 + W.h) + i), W.x, W.y, 1, 1)
      end
    end
    put(1 + 3 * (0.5 + 0.5 * sin(T * 1.3)), 24, 16, 2, 1)
    put(1 + 3 * (0.5 + 0.5 * sin(T * 1.3 + 2)), 105, 14, 2, 1)
    -- side blocks: roof edges and their windows
    put(1.5, 4, 26, 28, 1); put(1.5, 98, 31, 26, 1); put(1, 32, 38, 12, 1); put(1, 86, 40, 12, 1)
    seg(1.5, 4, 26, 4, GY - 1); seg(1, 31, 26, 31, 37); seg(1.5, 98, 31, 98, 39); seg(1, 123, 31, 123, GY - 1)
    seg(1, 32, 38, 32, GY - 1); seg(1, 97, 40, 97, GY - 1)
    for i = 1, #SIDE do
      local W = SIDE[i]
      local lv = 0
      if W.h < 0.15 + e * 0.25 + md * 0.2 then lv = 1.5 + W.h * 4 + md * 1.5 end
      if flick[i] then
        local u = (K.T - flick[i]) / 0.4
        if u >= 1 then flick[i] = nil else lv = math.max(lv, 6 * (1 - u)) end
      end
      if c > 0.5 and K.hash(i, math.floor(T * 2)) < (c - 0.5) * 0.25 then lv = 3 end
      if lv >= 0.5 then put(lv, W.x, W.y, 2, 1) end
    end

    -- the tower: edges, slabs and windows; chaos shears the floors
    put(2.5, TX0, TTOP, TX1 - TX0, 1)
    seg(2 + lo * 0.8, TX0, TTOP, TX0, GY - 1)
    seg(1.2, TX1 - 1, TTOP, TX1 - 1, GY - 1)
    -- the stairwell: an open hat runs its lights up the side of the block
    for i = #stairs, 1, -1 do
      local a = T - stairs[i]
      if a > 1 then table.remove(stairs, i)
      else
        for f = 1, NFL do
          local u = a * 22 - (NFL - f)
          if u > 0 and u < 6 then
            put(6 * (1 - u / 6) + 1, TX1 + 1, TTOP + 3 + (f - 1) * 4, 1, 2)
          end
        end
      end
    end
    -- the body of the mix (mid): more homes awake, their lamps warmer; more
    -- as the phrase goes on
    local share = 0.15 + e * 0.35 + md * 0.2 + ph * 0.15
    for f = 1, NFL do
      local y = TTOP + 3 + (f - 1) * 4
      local to = 0
      if c > 0.3 then to = math.floor((K.hash(f, math.floor(T * 2)) - 0.5) * (c - 0.3) * 14 + 0.5) end
      if to > fl_off[f] then fl_off[f] = fl_off[f] + 1 elseif to < fl_off[f] then fl_off[f] = fl_off[f] - 1 end
      local ox = fl_off[f]
      put(1, TX0 + 1 + math.max(0, ox), y + 3, TX1 - TX0 - 2 - math.abs(ox), 1)
      for col = 1, NCOL do
        local i = wi(col, f)
        local x = TX0 + 2 + (col - 1) * 5 + ox
        local h = K.hash(i, 61)
        local lv = win[i]
        if h < share then lv = math.max(lv, 1.5 + h * 6 + md * (2 + math.sin(T * 1.7 + i))) end
        if h > 0.97 or (h > 0.9 and tv > 0.1) then
          lv = math.max(lv, 1.5 + (1.2 + tv * 4) * (math.sin(T * 9 + i) * math.sin(T * 2.7 + i)) + 1 + tv * 3)
        end
        if lv >= 0.6 then put(lv, x, y, 3, 2) else put(1, x + 1, y + 1, 1, 1) end
      end
    end

    -- the antenna: mast, yagi bars, guy wires, the tip light
    line(2.5, AX, TTOP - 1, AX, 2)
    for q = 0, 2 do
      local y = 4 + q * 3
      line(2, AX - 3 + q, y, AX + 3 - q, y)
    end
    line(1, AX, 5, TX0 + 14, TTOP - 1); line(1, AX, 5, TX1 - 2, TTOP - 1)
    K.ring(2, AX - 7, TTOP - 4, 2.5, 6, -0.6, 2.2)
    put(1.5, AX - 7, TTOP - 2, 1, 2)
    local blink = (T * 0.7) % 1 < 0.12 and 3 or 0
    local tip = math.max(0, 1 - (K.T - tip_t) / 0.3)
    put(3 + blink + tip * 6, AX - 1, 0, 3, 2)
    -- kickless: the station keeps sending, slowly
    if kl > 0.5 then
      auto_t = auto_t + K.DTS
      if auto_t > 1.6 then auto_t = 0; pulse(3, 22) end
    end
    -- the pulses: rings rising off the tip
    for i = #pulses, 1, -1 do
      local P = pulses[i]
      local age = K.T - P.t0
      local r = 3 + age * P.sp
      local u = r / 70
      if u >= 1 then table.remove(pulses, i)
      elseif age >= 0 then
        -- a wide arc spreading out sideways and up from the tip
        K.ring(P.lv * (1 - u) * (1 - u) + 0.6, AX + P.dx, 2, r, math.floor(clamp(6 + r * 0.25, 6, 16)),
          math.pi * 0.85, math.pi * 2.15, 0.45, c * 1.5, i)
      end
    end

    -- the base: the lobby, the sub's glow pooled round the foot
    kglow = kglow * math.exp(-DT / 0.25)
    local g = math.max(kglow, lo * 0.9) * (1 - kl * 0.8)
    put(1.5 + g * 9, 60, GY - 5, 5, 4)
    put(1, 59, GY - 6, 7, 1)
    for y = GY - 7, 63, 2 do
      local d = (1 - math.abs(y - GY) / 10) * g
      if d > 0.08 then
        local hw = math.floor(18 + g * 26)
        local gap = math.max(2, math.floor(6 - d * 5))
        K.dashes(1 + d * 3, y, d > 0.5 and 2 or 1, gap, (y // 2) % 2, 64 - hw, 64 + hw)
      end
    end
    -- the street: kerb, puddle reflections of the windows, a car every bar,
    -- the closed hats splashing
    put(2, 0, GY, 128, 1)
    local ca = T - car_t
    if ca >= 0 and ca < 2.6 then
      local x = -10 + ca * 58
      put(min(10, 6 + e * 2), x, GY - 2, 2, 1)
      K.dashes(2 + lo, GY - 1, 3, 5, 0, x + 2, x + 22)
      for q = 0, 2 do put(3 - q, x - 1, GY + 2 + q * 2, 3, 1) end
      put(3, x - 9, GY - 2, 1, 1)
    end
    for i = #splash, 1, -1 do
      local P = splash[i]
      local u = (T - P.t0) / 0.3
      if u >= 1 then table.remove(splash, i)
      else
        local l = (3 + hi * 3) * (1 - u)
        line(l, P.x, GY - 1, P.x - 1 - u * 2, GY - 2 - u * 2)
        line(l, P.x, GY - 1, P.x + 1 + u * 2, GY - 2 - u * 2)
      end
    end
    for col = 1, NCOL do
      local m = 0
      for f = NFL - 3, NFL do m = math.max(m, win[wi(col, f)]) end
      if m > 1 then
        local x = TX0 + 2 + (col - 1) * 5
        for q = 0, 2 do put(m * (0.45 - q * 0.12), x, GY + 2 + q * 2, 3, 1) end
      end
    end
    if kl > 0.05 then K.haze(0, GY - 14, 128, 64, kl * 0.45, 1, T * 4) end

    -- the rain
    rainb = rainb * math.exp(-DT / 0.6)
    local rate = 0.25 + e * 0.45 + rainb * 0.6 + hi * 0.3
    rain_ph = rain_ph + K.DTS * (45 + 70 * rate)
    local slant = 0.25 + (c > 0.4 and math.sin(T * 0.9) * c * 0.4 or 0)
    rain(math.floor(18 + 50 * rate), 0, 128, -6, 1.5 + rate * 0.8, slant, 3 + math.floor(rate * 3))
  end

  ----------------------------------------------------------------------
  -- view 2: the canopy
  ----------------------------------------------------------------------
  local CAN = {}
  for c = 0, 64 do
    local x = c * 2
    CAN[c] = 6 + 4 * math.sin(x * 0.11) + 3 * math.sin(x * 0.29 + 1) + 2 * K.hash(c, 91)
  end
  local TRUNK = {{12, 6, 2, 3}, {44, 3, 1.2, -2}, {66, 8, 2.2, 2}, {97, 4, 1.4, -3}, {117, 5, 1.8, 1}}
  local VINE = {{24, 34}, {33, 44}, {54, 28}, {79, 40}, {88, 26}, {106, 38}}
  local BACK = {29, 58, 91, 124}
  local CLUMP = {}
  for i = 0, 13 do
    local x = 4 + i * 9.5 + (K.hash(i, 97) - 0.5) * 4
    CLUMP[#CLUMP + 1] = {x = x, r = 3 + K.hash(i, 98) * 2.5, y = CAN[math.floor(x) // 2] + 1}
  end

  local function frond_draw(bx, by, ang, dir, lv)
    local px, py = bx, by
    local a = ang
    for k = 1, 6 do
      a = a - 0.16
      local nx, ny = px + math.cos(a) * 6 * dir, py - math.sin(a) * 6
      line(lv, px, py, nx, ny)
      local ll = 11 - k * 1.2
      line(lv * 0.8, nx, ny, nx + ll * 0.45 * dir, ny + ll * 0.85)
      line(lv * 0.7, nx, ny, nx - ll * 0.25 * dir, ny + ll * 0.95)
      px, py = nx, ny
    end
  end

  local function draw_canopy(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless

    local ph = phrase(S)
    -- trunks further in, fainter
    for i = 1, #BACK do
      local x = BACK[i]
      local top = floor(CAN[x // 2]) + 2
      local lean = i % 2 == 0 and 1 or -1
      for y = top, GY - 4, 6 do
        local u0, u1 = (y - top) / (GY - top), (y + 3 - top) / (GY - top)
        line(1, x + lean * u0, y, x + lean * u1, y + 3)
      end
    end
    -- the trunks
    for i = 1, #TRUNK do
      local t = TRUNK[i]
      local x, w, lv, lean = t[1], t[2], t[3], t[4]
      local top = math.floor(CAN[x // 2])
      -- a dim body, a lit edge on the moon side, a darker far edge
      -- bark: a few dim strokes down the trunk
      for q = math.max(1, w // 2), w - 1, 4 do
        line(1, x + lean + q, top, x + q + 1, GY - 1)
      end
      seg(lv + hi * 0.5, x + lean, top, x, GY - 1)
      seg(lv * 0.6, x + lean + w, top, x + w + 2, GY - 1)
      line(lv * 0.8, x, GY - 1, x - 3, GY)
      line(lv * 0.8, x + w + 2, GY - 1, x + w + 5, GY)
    end
    -- the canopy: a dim ragged roof, its underside lit by the snare
    canopy_fl = canopy_fl * math.exp(-DT / 0.25)
    -- the roof catches the moon as the mix fills (amp), in slow patches
    for col = 0, 63 do
      local b = math.floor(CAN[col])
      put(1 + amp * (0.6 + 0.5 * math.sin(col * 1.1 + T * 0.6) + 0.4 * K.hash(col, 77)), col * 2, 0, 2, b)
    end
    -- leaf clumps hanging off the roof, nodding; the snare lights their undersides
    for i = 1, #CLUMP do
      local C = CLUMP[i]
      -- the body of the mix (mid) heaves the clumps and lights their undersides
      local nod = math.sin(T * (0.4 + md * 0.8) + i * 1.3) * (0.8 + e * 0.6 + md * 1.5)
      local dip = md * 1.2 * (0.5 + 0.5 * math.sin(T * 1.1 + i * 2.1))
      K.disc(1, C.x + nod, C.y + dip - 1, C.r * 0.7)
      local lv = 1.5 + canopy_fl * 5 + hi * 0.8 + md * 2
      K.ring(lv, C.x + nod, C.y + dip, C.r, 6, math.pi * 0.15, math.pi * 0.85)
    end
    -- moonlight through the gaps
    for i = 0, 4 do
      local x = 10 + i * 26 + math.floor(math.sin(T * 0.2 + i) * 2)
      local y = math.floor(CAN[x // 2]) + 1
      put(1.5 + 0.8 * math.sin(T * 0.6 + i * 2), x, y, 2, 1)
    end
    -- the vines, swaying; their leaves flick on the hats
    for i = 1, #VINE do
      local V = VINE[i]
      local x0 = V[1]
      local y0 = math.floor(CAN[x0 // 2])
      local amp = 2 + e * 2 + c * 4 + md * 3
      leaf_fl[i] = leaf_fl[i] * math.exp(-DT / 0.15)
      local px, py = x0, y0
      for k = 1, 6 do
        local u = k / 6
        local sw = math.sin(T * (0.6 + i * 0.07) + i * 1.7 + u * 1.5) * amp * u * u
        if c > 0.3 then sw = sw + math.sin(T * 2.3 + k * 2 + i) * c * 2 * u end
        local nx, ny = x0 + sw, y0 + V[2] * u
        line(2, px, py, nx, ny)
        if k >= 2 then
          local fl = leaf_fl[i]
          local side = (k % 2 == 0) and 1 or -1
          local lx = nx + side * (1 + math.floor(fl * 2))
          local ly = ny - math.floor(fl * 2)
          -- the air (hi) glints on the wet leaves
          local gl = hi * (K.hash(k + i * 7, math.floor(T * 5)) > 0.5 and 4 or 1.5)
          line(2 + fl * 6 + gl * 0.5, nx, ny, lx + side * 2, ly - 1)
          put(1.5 + fl * 4 + gl, lx + side * 2, ly, 1, 1)
        end
        px, py = nx, ny
      end
    end
    -- the forest floor and the kick's glow lifting off it
    kglow = kglow * math.exp(-DT / 0.3)
    local g = math.max(kglow, lo * 0.7) * (1 - kl * 0.8)
    put(1.5 + lo * 1.5, 0, GY, 128, 1)
    for y = GY - 8, 63, 2 do
      local d = (1 - math.abs(y - GY) / 10) * g
      if d > 0.08 then
        K.dashes(1 + d * 2, y, 1, math.max(2, math.floor(6 - d * 5)), (y // 2) % 2, 0, 128)
      end
    end
    for x = 3, 127, 7 do
      local h = 2 + math.floor(K.hash(x, 95) * 4)
      line(1.5, x, GY, x + math.sin(T * 0.8 + x) * 1.2, GY - h)
    end
    -- eyes in the undergrowth
    for i = #eyes, 1, -1 do
      local E = eyes[i]
      local u = (K.T - E.t0) / 0.9
      if u >= 1 then table.remove(eyes, i)
      else
        local open = (u > 0.45 and u < 0.55) and 0.2 or math.sin(math.pi * u)
        put(2 + 6 * open, E.x, E.y, 1, 1); put(2 + 6 * open, E.x + 3, E.y, 1, 1)
      end
    end
    -- the fireflies: each break slice flashes one
    local nf = math.floor(4 + e * 6 + ph * 4)
    local spd = 1 - kl * 0.6
    for i = 1, NFLY do
      local F = flies[i]
      F.fl = F.fl * math.exp(-DT / 0.18)
      if i <= nf or F.fl > 0.1 then
        local x = F.x0 + 9 * math.sin(T * 0.23 * spd * (1 + i * 0.05) + F.ph) + 3 * math.sin(T * 0.7 * spd + i)
        local y = F.y0 + 5 * math.sin(T * 0.31 * spd + F.ph * 2) + 2 * math.sin(T * 0.9 * spd + i * 3)
        local glow = 1.5 + 1.5 * (0.5 + 0.5 * math.sin(T * 1.3 + F.ph * 3)) + hi * 1.5
        put(glow + F.fl * 8, x, y, 1, 1)
        put(glow * 0.35, x - 1, y + 1, 3, 1)
        if F.fl > 0.25 then
          put(2 + F.fl * 4, x - 1, y, 3, 1); put(2 + F.fl * 4, x, y - 1, 1, 3)
        end
        if c > 0.35 then put((glow + F.fl * 4) * 0.5 * c, x + 5 * math.sin(i + T), y + 3 * math.cos(i * 2 + T), 1, 1) end
      end
    end
    -- the rain, through the canopy
    rainb = rainb * math.exp(-DT / 0.6)
    local rate = 0.15 + e * 0.35 + rainb * 0.4 + hi * 0.2
    rain_ph = rain_ph + K.DTS * (40 + 50 * rate)
    rain(math.floor(8 + 16 * rate), 0, 128, 10, 1.2 + rate * 0.6, 0.12, 2 + math.floor(rate * 2))
    -- an open hat shakes the clumps: drips run down out of them
    for i = #drips, 1, -1 do
      local D = drips[i]
      local a = T - D.t0
      if a > 0.9 then table.remove(drips, i)
      elseif a >= 0 then
        local C = CLUMP[clamp(D.c, 1, #CLUMP)]
        local y = C.y + C.r + 60 * a * a
        if y < GY then line(3 + hi * 3, C.x + (D.c % 3 - 1), y, C.x + (D.c % 3 - 1), y + 2) end
      end
    end
    -- the fronds in front: springs knocked by the snare
    for s = 0, 1 do
      local a, v = frond[1 + s * 2], frond[2 + s * 2]
      v = v + (-a * 60 - v * 7) * DT
      a = a + v * DT
      frond[1 + s * 2], frond[2 + s * 2] = clamp(a, -0.6, 0.6), v
    end
    local sw = math.sin(T * 0.5) * 0.06
    frond_draw(-2, 64, 1.25 + frond[1] + sw, 1, 2.2 + e * 0.6)
    frond_draw(130, 64, 1.25 - frond[3] - sw, -1, 2.2 + e * 0.6)
    if kl > 0.05 then K.haze(0, GY - 18, 128, 64, kl * 0.5, 1, T * 3) end
  end

  ----------------------------------------------------------------------
  -- view 3: the river
  ----------------------------------------------------------------------
  local HZ = 25                            -- the far bank's waterline
  local BANK = {}
  for c = 0, 64 do
    local x = c * 2
    BANK[c] = 9 + 4 * sin(x * 0.07 + 1) + 3 * sin(x * 0.19) + 2 * K.hash(c // 2, 171)
    if x > 70 and x < 98 then BANK[c] = BANK[c] + 5 + 3 * sin((x - 70) / 28 * math.pi) end
  end
  local REED = {}
  for i = 1, 16 do
    local left = i <= 8
    local k = left and i or i - 8
    REED[i] = {x = left and (k * 3 + K.hash(i, 181) * 2) or (127 - k * 3 - K.hash(i, 181) * 2),
      h = 12 + K.hash(i, 182) * 12, ph = K.hash(i, 183) * 6.28, head = K.hash(i, 184) < 0.4}
  end
  local RFLY = 8

  local function water_xy(u, d)
    local y = HZ + 3 + d * (60 - HZ)
    local x = 64 + (u - 0.5) * (70 + d * 70)
    return x, y
  end

  local function draw_river(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, md, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    local ph = phrase(S)
    swell = swell * exp(-DT / 0.35)
    squall = squall * exp(-DT / 1.5)
    gust = gust * exp(-DT / 0.8)

    -- the night sky over the far bank, the moon behind its trees, the glow
    -- cut by them
    local MX, MY = 84, 9 - ph * 3
    for y = 6, HZ - 1 do K.row_above(1, y, BANK, 0, 128) end
    local ml = 6 + amp * 4 + md
    for band = 3, 1, -1 do
      local r = 4 + band * 5
      local l = (0.6 + md * 0.8 + amp * 0.6) * (1.6 - band * 0.4)
      if l >= 0.6 then
        for dy = -r, r do
          local y = floor(MY + dy)
          local hw = math.sqrt(math.max(0, r * r - dy * dy))
          if y >= 0 and y < HZ then K.row_above(l, y, BANK, max(0, floor(MX - hw)), min(128, floor(MX + hw))) end
        end
      end
    end
    K.disc(min(11, ml), MX, MY, 3)
    -- the trees' edge, lit faintly by the moon
    for col = 1, 64 do
      local x = col * 2
      local near = math.exp(-abs(x - MX) / 30)
      local l = 1 + near * (1.5 + md * 1.5)
      line(l, x - 2, BANK[col - 1], x, BANK[col])
    end
    line(1 + md, 0, HZ, 127, HZ)

    -- the moon's path on the water: widened by the lows, broken by the rings
    -- and fractured by chaos
    local dist = swell
    for _, R in ipairs(rings) do
      local a = T - R.t0
      if a >= 0 and a < 1 then dist = dist + R.lv * 0.06 * (1 - a) end
    end
    for y = HZ + 1, 63 do
      local d = (y - HZ) / (63 - HZ)
      local w = 2 + d * (8 + lo * 10 + swell * 6)
      local wob = sin(T * 1.6 + y * 0.8) * (0.3 + d * 1.2) * (1 + dist * 0.5)
      local off = 0
      if c > 0.3 then off = floor((K.hash(y // 3, 191 + floor(T * 1.5)) - 0.5) * (c - 0.3) * 18 + 0.5) end
      local l = (ml * 0.45) * (1 - d * 0.45) * (0.75 + 0.25 * sin(T * 2.3 + y * 1.7))
      local cx = MX + (y - HZ) * 0.25 + wob + off
      if l >= 0.6 then put(l, cx - w / 2, y, w, 1) end
      -- the highs glint at its edges
      if hi > 0.1 then
        local g = hi * 4 * (0.5 + 0.5 * sin(T * 5 + y * 2.3))
        if g >= 0.6 then put(g, cx + w / 2 + 1 + d * 3 * sin(T + y), y, 1, 1) end
      end
    end

    -- the reeds in the corners, swaying; a gust each bar
    for i = 1, #REED do
      local R = REED[i]
      local sw = sin(T * (0.7 - kl * 0.3) + R.ph) * (1 + gust * 3 + e) + gust * 2
      local x0, y0 = R.x, 64
      local x1, y1 = R.x + sw, 64 - R.h
      seg(1.5 + md * 0.5, x0, y0, x1, y1)
      if R.head then put(2 + md, x1 - 0.5, y1 - 1, 2, 3) end
    end

    -- the rings: every hit lands on the river
    for i = #rings, 1, -1 do
      local R = rings[i]
      local a = T - R.t0
      local life = 0.6 + R.sz * 0.6
      if a > life then table.remove(rings, i)
      elseif a >= 0 then
        local u = a / life
        local x, y = water_xy(R.u, R.d)
        local sc = 0.4 + R.d * 1.2
        local r = (1 + a * 26 * R.sz) * sc
        local lv = R.lv * (1 - u) * (1 - u) + 0.4
        K.ring(min(12, lv), x, y, r, r > 6 and 16 or 10, 0, K.TAU, 0.28, c * 2, i)
        if R.sz > 0.9 and r > 3 then K.ring(min(8, lv * 0.5), x, y, r * 0.6, 12, 0, K.TAU, 0.28, c * 2, i + 5) end
        if R.sz >= 1 and a < 0.25 then
          for k = 1, 4 do
            local da = a * (16 + k * 6)
            put(lv, x + (k - 2.5) * 2 * (0.5 + a * 4), y - da + 60 * a * a, 1, 1)
          end
        end
      end
    end
    -- the rain: squalls and energy, a few drops ringing the water
    local rate = 0.15 + e * 0.6 + squall * 2 + hi * 0.5 + rainb
    rain_acc = rain_acc + rate * 4 * K.DTS
    while rain_acc >= 1 do
      rain_acc = rain_acc - 1
      ring(K.rnd(), K.rnd(), 0.25, 2 + hi * 2)
    end
    rainb = rainb * exp(-DT / 0.6)
    rain_ph = rain_ph + K.DTS * (60 + 40 * rate)
    if rate > 0.3 then rain(floor(rate * 14), 0, 128, -6, 1.2 + rate * 0.5, 0.06, 2) end

    -- a fish jumps
    for i = #fish, 1, -1 do
      local F = fish[i]
      local a = (T - F.t0) / 0.55
      if a >= 1.6 then table.remove(fish, i)
      else
        local x, y = water_xy(F.u, F.d)
        local sc = 0.5 + F.d
        if a < 1 then
          local fx = x + F.dir * a * 12 * sc
          local fy = y - sin(a * math.pi) * 9 * sc
          local vx, vy = F.dir, -math.cos(a * math.pi) * 2
          local m = math.sqrt(vx * vx + vy * vy)
          line(7 + md * 2, fx - vx / m * 2 * sc, fy - vy / m * 2 * sc, fx + vx / m * 1.5 * sc, fy + vy / m * 1.5 * sc)
          if a < 0.3 then put(4, x, y - 1, 1, 1) end
        else
          local u = a - 1
          K.ring(4 * (1 - u / 0.6), x + F.dir * 12 * sc, y, 1 + u * 12 * sc, 10, 0, K.TAU, 0.28)
        end
      end
    end

    -- fireflies over the water, their reflections under them
    local nf = floor(3 + e * 3 + ph * 2 + 0.5)
    for i = 1, min(RFLY, nf) do
      local F = flies[i]
      F.fl = F.fl * exp(-DT / 0.18)
      local x = 10 + K.hash(i, 195) * 108 + 8 * sin(T * 0.2 + F.ph)
      local y = HZ - 3 - K.hash(i, 196) * 8 + 2 * sin(T * 0.37 + F.ph * 2)
      local g = 1.5 + 1.5 * (0.5 + 0.5 * sin(T * 1.3 + F.ph * 3)) + hi + F.fl * 7
      put(g, x, y, 1, 1)
      put(g * 0.45, x + sin(T * 3 + i) * 0.8, 2 * HZ - y + 1, 1, 1)
    end

    -- mist on the water: kickless, the mids light it
    local mist = 0.08 + kl * 0.45 + md * 0.1
    K.haze(0, HZ + 1, 128, HZ + 15, mist, 1 + md * 0.8, T * 3)
  end

  function M.draw(S)
    local DT = K.DT
    for i = 1, #win do win[i] = win[i] * math.exp(-DT / 0.45) end
    for i = #pend, 1, -1 do
      local P = pend[i]
      if K.T >= P.t then
        table.remove(pend, i)
        light(P.col, P.f, 9)
        local fly = flies[P.fly]; if fly then fly.fl = 1 end
      end
    end
    tv = tv * math.exp(-DT / 0.5)
    if K.view == 2 then draw_canopy(S)
    elseif K.view == 3 then draw_river(S)
    else draw_block(S) end
  end

  M.init()
  return M
end
