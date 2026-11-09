-- jungle: view 1, a tower block at night in the rain with a pirate-radio antenna on the roof, windows lighting with the hits and the sub glowing at its base; view 2, a dense jungle canopy at night: vines sway, leaves flick on the hats, rain falls and break slices flash as fireflies.
--
-- view 1: the block stands between two lower ones against a sodium sky.
-- homes are lit here and there (more with energy) and a TV flickers; the
-- rolling break climbs the block window by window (a reversed slice runs
-- back down), percussion and hats flick windows, a ratchet runs a burst
-- along one floor. the snare fires a pulse off the antenna, rings rising
-- into the rain; the sub kick lights the lobby and pools a glow round the
-- base. the rain follows the hats and the energy, falling harder and
-- denser; chaos shears the floors sideways and doubles the pulses; kickless,
-- the base goes dark, fog settles on the street and the station keeps
-- sending slow pulses of its own.
-- view 2: inside the forest, under the canopy. trunks rise into a ragged
-- roof of leaves; vines hang and sway, their leaves flicking on the hats;
-- two big fronds in front jolt on the snare; the kick lifts a glow off the
-- forest floor. fireflies drift, and each break slice flashes one of them so
-- a rolling break runs across the swarm; percussion opens a pair of eyes in
-- the undergrowth. energy wakes more fireflies and the rain, chaos tangles
-- the vines and splits the fireflies, kickless the floor mist thickens.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

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

  function M.kick(v) kglow = math.max(kglow, 0.4 + 0.6 * K.num(v, 1)) end
  function M.snare(v)
    v = K.num(v, 1)
    pulse(4 + 6 * v, 40)
    light(1 + math.floor(K.rnd() * NCOL), 1 + math.floor(K.rnd() * 3), 6 + 5 * v)
    canopy_fl = math.max(canopy_fl, v)
    frond[2] = frond[2] - 3 * v
    frond[4] = frond[4] + 3 * v
  end
  function M.clap(v) pulse(3 + 4 * K.num(v, 1), 50); canopy_fl = math.max(canopy_fl, 0.6) end
  function M.rim(v) pulse(2 + 3 * K.num(v, 1), 60) end
  function M.hat(v, open)
    v = K.num(v, 1)
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
  function M.perc(_, v)
    light(1 + math.floor(K.rnd() * NCOL), 1 + math.floor(K.rnd() * NFL), 4 + 5 * K.num(v, 1))
    if K.rnd() < 0.5 then eye() end
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
  end
  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 12)
    local f = 1 + math.floor(K.rnd() * NFL)
    for k = 0, n - 1 do
      if #pend < 16 then pend[#pend + 1] = {t = K.T + k * 0.04, col = 1 + k % NCOL, f = f, fly = 1 + (k * 5) % NFLY} end
    end
    pulse(3 + n * 0.5, 70)
  end
  function M.fill()
    local f = 1 + math.floor(K.rnd() * NFL)
    for c = 1, NCOL do light(c, f, 7) end
    pulse(8, 30)
    for i = 1, NFLY, 2 do flies[i].fl = math.max(flies[i].fl, 0.7) end
  end

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
    -- side blocks: roof edges and their windows
    put(1.5, 4, 26, 28, 1); put(1.5, 98, 31, 26, 1); put(1, 32, 38, 12, 1); put(1, 86, 40, 12, 1)
    line(1.5, 4, 26, 4, GY - 1); line(1, 31, 26, 31, 37); line(1.5, 98, 31, 98, 39); line(1, 123, 31, 123, GY - 1)
    line(1, 32, 38, 32, GY - 1); line(1, 97, 40, 97, GY - 1)
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
    line(2 + lo * 0.8, TX0, TTOP, TX0, GY - 1)
    line(1.2, TX1 - 1, TTOP, TX1 - 1, GY - 1)
    -- the body of the mix (mid): more homes awake, their lamps warmer
    local share = 0.15 + e * 0.35 + md * 0.2
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
        if h > 0.97 then lv = math.max(lv, 1.5 + 1.2 * (math.sin(T * 9 + i) * math.sin(T * 2.7 + i)) + 1) end
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
    -- the street: kerb, puddle reflections of the windows
    put(2, 0, GY, 128, 1)
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
      line(lv + hi * 0.5, x + lean, top, x, GY - 1)
      line(lv * 0.6, x + lean + w, top, x + w + 2, GY - 1)
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
      K.disc(1, C.x + nod, C.y + dip, C.r)
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
        K.dashes(1 + d * 2.5, y, 1, math.max(2, math.floor(6 - d * 5)), (y // 2) % 2 + math.floor(T * 3), 0, 128)
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
    local nf = math.floor(4 + e * 8)
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
    rain(math.floor(10 + 26 * rate), 0, 128, 10, 1.2 + rate * 0.6, 0.12, 2 + math.floor(rate * 2))
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
    if K.view == 2 then draw_canopy(S) else draw_block(S) end
  end

  M.init()
  return M
end
