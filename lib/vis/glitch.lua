-- glitch. view 1: a circuit board close up: a clock chip feeding six voice chips down a bus of copper traces, vias, parts and a sheen moving over the solder mask.
-- view 2: a datamoshed picture: a sun on a gridded horizon drawn in halftone blocks that the drums shift, smear, repeat and corrupt, healing slowly.
--
-- view 1: every hit sends a pulse racing from the clock chip down its trace
-- to that voice's chip (kick, snare, hats top; perc, ticks, breaks below),
-- which lights when it lands; reversed break slices run back to the clock;
-- a ratchet sends a train of pulses; error and crush ticks corrupt a trace
-- with a stutter of lit segments; a fill fires every trace at once. energy
-- fills the bus with faint idle data and brightens the board, chaos reroutes
-- traces through detours and shorts the bus with sparks (and misroutes some
-- pulses), kickless stretches dim the board and the kick chip and leave the
-- clock breathing with slow idle data on every trace.
-- view 2: the kick pumps the sun and melts the blocks around it downward,
-- snares shove a band of blocks sideways, hats nudge single blocks, ticks
-- corrupt blocks into bit-noise stripes, perc freezes a block in time,
-- break slices slide a column of blocks, ratchets repeat one row down the
-- picture, a fill smears the whole image; everything heals back slowly.
-- energy grows the sun and lights the grid, chaos keeps blocks wobbling
-- loose, kickless sinks the sun to a ring and slows the ground.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local floor = math.floor

  ---------------------------------------------------------------- view 1
  -- the clock chip and the six voice chips
  local CLK = {x = 3, y = 21, w = 14, h = 22}
  local CHIPS = {
    {x = 26, y = 3, w = 18, h = 10, bus = 24, up = true},   -- 1 kick
    {x = 58, y = 3, w = 18, h = 10, bus = 27, up = true},   -- 2 snare
    {x = 92, y = 3, w = 16, h = 10, bus = 30, up = true},   -- 3 hats
    {x = 26, y = 51, w = 18, h = 10, bus = 40, up = false}, -- 4 perc
    {x = 58, y = 51, w = 18, h = 10, bus = 37, up = false}, -- 5 ticks
    {x = 92, y = 51, w = 16, h = 10, bus = 34, up = false}, -- 6 breaks
  }
  local NV = #CHIPS

  -- a route: the bus from the clock, a 45 degree turn, up / down to the chip
  local function route(v, alt)
    local C = CHIPS[v]
    local px = C.x + floor(C.w / 2)
    local by = C.bus
    local ey = C.up and (C.y + C.h) or C.y - 1
    local dir = C.up and -1 or 1
    local pts = {{CLK.x + CLK.w, by}}
    if alt then
      -- a detour: a jog off the bus and back
      local jx = 20 + floor(K.hash(v, 21) * (px - 30))
      local jd = C.up and 2 or -2
      pts[#pts + 1] = {jx, by}
      pts[#pts + 1] = {jx + 2, by + jd}
      pts[#pts + 1] = {jx + 8, by + jd}
      pts[#pts + 1] = {jx + 10, by}
    end
    pts[#pts + 1] = {px - 3, by}
    pts[#pts + 1] = {px, by + dir * 3}
    pts[#pts + 1] = {px, ey}
    local len, acc = {}, 0
    for k = 2, #pts do
      local a, b = pts[k - 1], pts[k]
      acc = acc + math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
      len[k] = acc
    end
    len[1] = 0
    return {pts = pts, len = len, total = acc}
  end

  local ROUTE, ALT = {}, {}
  for v = 1, NV do ROUTE[v], ALT[v] = route(v, false), route(v, true) end

  -- decor: vias, a few dim traces, parts
  local VIAS = {}
  for k = 0, 21 do
    VIAS[#VIAS + 1] = {x = 20 + floor(K.hash(k, 31) * 104), y = 15 + floor(K.hash(k, 32) * 34)}
  end
  local VOICE = {kick = 1, snare = 2, clap = 2, hat = 3, perc = 4, tom = 4, tick = 5, brk = 6}

  local pulses, corrupt, lit, sparks
  local clkf, idle_k, sheen_k
  local MAXP = 28

  ---------------------------------------------------------------- view 2
  local HY = 36                         -- the horizon
  local BC, BR = 16, 8                  -- blocks: 16 x 8 of 8 px
  local blk                             -- per block: ox, oy, frz, ft, cor
  local rep                             -- repeated rows: {row, src, t}
  local pump, pump_t, smear

  function M.init()
    pulses, corrupt, sparks = {}, {}, {}
    lit = {}
    for v = 1, NV do lit[v] = 0 end
    clkf, idle_k, sheen_k = 0, -1, 0
    blk = {}
    for i = 0, BC * BR - 1 do blk[i] = {ox = 0, oy = 0, px = 0, py = 0, frz = 0, ft = 0, cor = 0} end
    rep = {}
    pump, pump_t, smear = 0, 0, 0
  end
  M.clear = M.init

  local function path(v)
    if K.hash(v, 77) < K.chaos * 0.8 - 0.1 then return ALT[v] end
    return ROUTE[v]
  end

  local function send(v, lv, back, delay)
    if #pulses >= MAXP then table.remove(pulses, 1) end
    local to = v
    -- chaos misroutes some
    if K.chaos > 0.5 and K.rnd() < (K.chaos - 0.5) * 0.6 then
      to = 1 + floor(K.rnd() * NV)
      if #sparks < 10 then sparks[#sparks + 1] = {x = 24 + K.rnd() * 60, y = 24 + floor(K.rnd() * 5) * 3, t0 = K.T} end
    end
    pulses[#pulses + 1] = {v = to, s = -(delay or 0), lv = lv, back = back == true, idle = false}
    if v == 1 or lv > 8 then clkf = math.max(clkf, lv / 10) end
  end

  -- view 2 helpers
  local function bi(c, r) return (r % BR) * BC + (c % BC) end
  local function shove_row(r, dx)
    for c = 0, BC - 1 do
      local b = blk[bi(c, r)]
      b.ox = b.ox + dx * (0.6 + 0.4 * K.hash(c + r * 16, 5))
    end
  end

  ---------------------------------------------------------------- events
  function M.kick(v)
    v = K.num(v, 1)
    send(1, 6 + 5 * v)
    pump_t = 1
    -- melt the blocks around the sun downward
    for c = 6, 9 do
      for r = 2, 4 do
        local b = blk[bi(c, r)]
        b.oy = b.oy - (2 + 3 * v) * K.hash(c * 9 + r + floor(K.T * 7), 6)
      end
    end
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    send(2, 6 + 5 * v)
    local r = floor(K.rnd() * BR)
    shove_row(r, (K.rnd() < 0.5 and -1 or 1) * (4 + 5 * v))
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8) end

  function M.hat(v, open)
    v = K.num(v, 1)
    send(3, (open and 5 or 3) + 2 * v)
    local b = blk[floor(K.rnd() * BC * BR)]
    b.ox = b.ox + (K.rnd() - 0.5) * 6
    if open then b.oy = b.oy + (K.rnd() - 0.5) * 6 end
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    send(4, 5 + 4 * v)
    local b = blk[floor(K.rnd() * BC * BR)]
    b.frz, b.ft = 0.8 + v * 0.6, K.T - 0.5
    if kind == 11 or kind == 8 then lit[4] = math.max(lit[4], 0.5) end
  end
  function M.tom(v) M.perc(1, v) end

  function M.tick(kind)
    if kind == 7 or kind == 3 then
      local v = 1 + floor(K.rnd() * NV)
      local P = ROUTE[v]
      local s0 = K.rnd() * P.total * 0.7
      if #corrupt < 6 then corrupt[#corrupt + 1] = {v = v, s0 = s0, s1 = s0 + 8 + K.rnd() * 14, t0 = K.T} end
      local b = blk[floor(K.rnd() * BC * BR)]
      b.cor = 1
    else
      send(5, 5)
      local b = blk[floor(K.rnd() * BC * BR)]
      b.ox = b.ox + (K.rnd() - 0.5) * 4
    end
  end

  function M.brk(s, n, rev)
    s, n = floor(K.num(s, 1)), math.max(1, floor(K.num(n, 8)))
    send(6, 6, rev == true)
    local c = (s - 1) % BC
    for r = 0, BR - 1 do
      local b = blk[bi(c, r)]
      b.oy = b.oy + (rev and -4 or 4)
    end
  end

  function M.ratchet(n, voice)
    n = clamp(floor(K.num(n, 2)), 1, 16)
    local v = VOICE[voice or ""] or 2
    for k = 1, math.min(n, 8) do send(v, 8 - k * 0.4, false, k * 5) end
    -- repeat a row down the picture
    local r = floor(K.rnd() * (BR - 2))
    for k = 1, math.min(n, 3, BR - 1 - r) do
      if #rep < 24 then rep[#rep + 1] = {row = r + k, src = r, t0 = K.T + k * 0.06, t = K.T + 0.35 + n * 0.05 + k * 0.06} end
    end
  end

  function M.fill()
    for v = 1, NV do send(v, 9) end
    smear = 1
  end

  ---------------------------------------------------------------- view 1 draw
  -- the point at distance s along a route
  local function at(P, s)
    if s <= 0 then return P.pts[1][1], P.pts[1][2] end
    for k = 2, #P.pts do
      if s <= P.len[k] then
        local a, b = P.pts[k - 1], P.pts[k]
        local u = (s - P.len[k - 1]) / math.max(0.001, P.len[k] - P.len[k - 1])
        return a[1] + (b[1] - a[1]) * u, a[2] + (b[2] - a[2]) * u
      end
    end
    local q = P.pts[#P.pts]
    return q[1], q[2]
  end

  local function sheen(x, y)
    local d = (x + y * 0.8 - sheen_k) % 220
    if d < 26 then return math.sin(d / 26 * math.pi) end
    return 0
  end

  local function trace(P, base, hi)
    local pts = P.pts
    for k = 2, #pts do
      local a, b = pts[k - 1], pts[k]
      local n = math.max(1, floor(math.max(math.abs(b[1] - a[1]), math.abs(b[2] - a[2])) / 10))
      for j = 0, n - 1 do
        local x0, y0 = a[1] + (b[1] - a[1]) * j / n, a[2] + (b[2] - a[2]) * j / n
        local x1, y1 = a[1] + (b[1] - a[1]) * (j + 1) / n, a[2] + (b[2] - a[2]) * (j + 1) / n
        line(math.min(11, base + sheen((x0 + x1) / 2, (y0 + y1) / 2) * hi), x0, y0, x1, y1)
      end
    end
  end

  local function chip(C, l, die, dim)
    local x, y, w, h = C.x, C.y, C.w, C.h
    -- its shadow, the body, the pins
    line(1, x + 1, y + h, x + w, y + h)
    put((1 + die * 4) * dim + l * 0.1, x + 1, y + 1, w - 2, h - 2)
    line((2 + l * 0.3) * dim, x, y, x + w - 1, y)
    line((1.5 + l * 0.2) * dim, x, y + h - 1, x + w - 1, y + h - 1)
    line((1.5 + l * 0.2) * dim, x, y + 1, x, y + h - 2)
    line((1.5 + l * 0.2) * dim, x + w - 1, y + 1, x + w - 1, y + h - 2)
    for px = x + 2, x + w - 3, 3 do
      put((1.5 + l * 0.4) * dim, px, y - 1, 1, 1)
      put((1.5 + l * 0.4) * dim, px, y + h, 1, 1)
    end
    -- the pin-1 dot and the die window
    put(2.5 * dim, x + 2, y + 2, 1, 1)
    if die > 0.05 then put(math.min(13, 2 + die * 10), x + w / 2 - 3, y + h / 2 - 1, 6, 2) end
    put(math.min(9, 1.5 + die * 5 + l * 0.3) * dim, x + 3, y + h / 2 - 2, w - 6, 1)
  end

  local function draw1(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl, mid, amp = A[K.LO], A[K.HI], K.kickless, A[K.MID], A[K.AMP]
    local dim = 1 - kl * 0.35
    sheen_k = (T * 22) % 220
    clkf = clkf * math.exp(-DT / 0.12)
    for v = 1, NV do lit[v] = lit[v] * math.exp(-DT / 0.22) end

    -- idle data: faint pulses down random traces (more with energy, every
    -- trace in a kickless stretch)
    local rate = 0.8 + e * 9 + kl * 3
    local ik = floor(T * rate)
    if ik ~= idle_k then
      if idle_k >= 0 and #pulses < MAXP then
        local v = 1 + floor(K.hash(ik, 41) * NV)
        pulses[#pulses + 1] = {v = v, s = 0, lv = 2 + e * 1.5 + kl, back = false, idle = true}
      end
      idle_k = ik
    end

    -- the board: a mounting hole, the ground pour hatch, the edge fingers
    K.ring(2, 121, 5, 3, 8)
    K.ring(2, 121, 58, 3, 8)
    for k = 0, 5 do
      local x = 112 + k * 3
      line(1 * dim, x, 14 + k * 2, x + 8, 22 + k * 2)
    end
    for k = 0, 6 do
      put(1.5 + amp * 2 + (k % 2) * mid, 50 + k * 4, 63, 2, 1)
    end
    -- dim side traces between the vias
    for k = 1, #VIAS - 1, 2 do
      local a, b = VIAS[k], VIAS[k + 1]
      if math.abs(a.y - b.y) < 12 and (a.y < 22 or a.y > 42) then
        line(1, a.x, a.y, b.x, a.y)
        line(1, b.x, a.y, b.x, b.y)
      end
    end
    for _, V in ipairs(VIAS) do
      local l = math.min(11, 1.5 + sheen(V.x, V.y) * (2 + hi * 3) + hi * 3 + e * 1.5)
      put(l * dim, V.x - 1, V.y, 3, 1)
      put(l * dim, V.x, V.y - 1, 1, 3)
    end
    -- a big electrolytic cap and a crystal can
    K.ring(1.5 + lo * 1.5, 118, 33, 7, 14)
    K.ring(1, 118, 33, 4, 10)
    line(2 + lo, 113, 28, 113, 38)
    K.ring(1.5 + mid, 9, 51, 4, 10, 0, K.TAU, 0.6)

    -- the traces: the bus and the drops, lit by the sheen and the mids
    local tb = (1.3 + mid * 1.2 + e * 1.2) * dim
    for v = 1, NV do
      local P = path(v)
      local d = (v == 1) and (1 - kl * 0.5) or 1
      trace(P, tb * d + lit[v] * 3, 1.5 + hi * 6 + e * 1.5)
    end
    -- the bus's pads at the clock
    for v = 1, NV do put(2.5 + lit[v] * 3, CLK.x + CLK.w, CHIPS[v].bus - 1, 2, 3) end

    -- shorts (chaos): sparks across the bus, flickering smoothly
    if c > 0.4 then
      for k = 0, 3 do
        local x = 26 + floor(K.hash(k, 51) * 60)
        local y = 24 + floor(K.hash(k, 52) * 5) * 3
        local f = (0.5 + 0.5 * math.sin(T * (9 + k * 3) + k * 2)) * (c - 0.4) * 1.6
        if f > 0.15 then line(2 + f * 7, x, y, x + 1, y + 3) end
      end
    end
    for k = #sparks, 1, -1 do
      local sp = sparks[k]
      local u = (T - sp.t0) / 0.3
      if u >= 1 then table.remove(sparks, k)
      else
        put(9 * (1 - u), sp.x, sp.y, 2, 2)
        line(5 * (1 - u), sp.x - 2, sp.y - 2, sp.x + 3, sp.y + 3)
      end
    end

    -- corrupted stretches: a stutter of lit segments
    for k = #corrupt, 1, -1 do
      local C = corrupt[k]
      local u = (T - C.t0) / 0.6
      if u >= 1 then table.remove(corrupt, k)
      else
        local P = ROUTE[C.v]
        local st = floor((T - C.t0) * 18)
        for s = C.s0, C.s1, 3 do
          if K.hash(floor(s) + st * 7, 53) < 0.6 then
            local x, y = at(P, s)
            put(math.min(11, (4 + 6 * (1 - u))), x - 1, y - 1, 2, 2)
          end
        end
      end
    end

    -- the pulses, racing to their chips
    local spd = 400
    for k = #pulses, 1, -1 do
      local p = pulses[k]
      local P = path(p.v)
      p.s = p.s + spd * DT * (p.idle and 0.45 or 1)
      if p.s >= P.total then
        if not p.idle then lit[p.v] = math.max(lit[p.v], p.lv / 10) end
        table.remove(pulses, k)
      elseif p.s >= 0 then
        local s = p.back and (P.total - p.s) or p.s
        local dir = p.back and 1 or -1
        local tail = p.idle and 3 or 4
        for j = tail, 0, -1 do
          local x, y = at(P, s + dir * j * 2)
          local l = p.lv * (1 - j / (tail + 1))
          if j == 0 and not p.idle then
            put(l * 0.45, x - 2, y - 2, 5, 5)
            put(math.min(12, l), x - 1, y - 1, 3, 3)
          else put(l * 0.8, x, y, 1, 1) end
        end
      end
    end

    -- the chips
    for v = 1, NV do
      local d = (v == 1) and (1 - kl * 0.6) or dim
      local l = lit[v] * 10 + (v == 1 and lo * 2 or 0) + (v == 3 and hi * 2 or 0)
      chip(CHIPS[v], l, lit[v], d)
    end
    -- the clock chip: its can, its LED keeping time
    local C = CLK
    put((1 + clkf * 5 + lo * 2.5) * dim, C.x + 1, C.y + 1, C.w - 2, C.h - 2)
    line(2.5 + clkf * 4 + lo * 1.5, C.x, C.y, C.x + C.w - 1, C.y)
    line(2, C.x, C.y + 1, C.x, C.y + C.h - 1)
    line(2 + clkf * 3, C.x + C.w - 1, C.y + 1, C.x + C.w - 1, C.y + C.h - 1)
    line(1.5, C.x, C.y + C.h - 1, C.x + C.w - 1, C.y + C.h - 1)
    K.ring(2 + clkf * 5 + lo * 2, C.x + C.w / 2, C.y + 8, 4, 10)
    local led
    if kl > 0.5 then led = 2 + 3 * (0.5 + 0.5 * math.sin(T * 1.5))
    else led = K.beat_ph < 0.2 and (4 + 6 * (1 - K.beat_ph * 5)) or 2 end
    put(led, C.x + C.w / 2 - 1, C.y + C.h - 5, 3, 2)
    put(2 + amp * 4, C.x + 2, C.y + C.h - 3, 2, 1)
    K.grain(function(u, w) return 20 + u * 100, 16 + w * 32 end, 2 + hi * 6 + c * 6, 3 + hi * 2)
  end

  ---------------------------------------------------------------- view 2 draw
  -- the picture: brightness 0..1 at (x, y) at time t
  local sun_y, sun_r, gs, kls, lvk, heave, sp_hi, mid_v

  -- the far hills along the horizon, px above it, per 4 px column
  local HILL = {}
  for k = 0, 40 do
    local x = k * 4
    HILL[k] = floor(3 + 4 * math.max(0, math.sin(x * 0.045 + 1.2)) + 3 * math.max(0, math.sin(x * 0.11 + 4))
      + K.hash(k, 81) * 2)
  end

  -- the picture at (x, y), time t: a level and a dot size (4 = solid cell)
  local function scene(x, y, t)
    local hx = clamp(floor(x / 4), 0, 40)
    if y < HY then
      if y >= HY - HILL[hx] then return 1.3 + lvk * 0.6 + heave * 0.8, 4 end
      -- two clouds drifting
      for k = 0, 1 do
        local cx = (x - t * (2 + k * 1.5) + k * 70) % 160 - 16
        local cy = y - (8 + k * 9)
        if (cx - 14) * (cx - 14) / 196 + cy * cy / 6 < 1 then return 1.2 + lvk * 0.6, 4 end
      end
      local dx, dy = x - 64, y - sun_y
      local d2 = dx * dx + dy * dy
      if d2 < sun_r * sun_r then
        if kls > 0.5 and d2 < (sun_r - 4) * (sun_r - 4) then return 0, 0 end
        if dy > 1 and floor(dy / 4) % 2 == 1 then return 2 + gs * 2, 2 end
        return 5 + gs * 1.5 + pump * 1.2, 4
      end
      if d2 < (sun_r + 4) * (sun_r + 4) then return 2 + pump * 2 + sp_hi * 3, 1 end
      local cx, cy = x // 4, y // 4
      if K.hash(cx * 31 + cy, 61) > 0.93 then return 1.5 + sp_hi * 4 + 1.5 * math.sin(t * 1.3 + cx), 1 end
      if y >= HY - 12 then return 1.2 + (y - HY + 12) / 12 * (1 + gs + pump), 1 end
      return 0, 0
    end
    local gy = y - HY
    local dz = gy + 1.5 + heave * math.max(0, 1 - math.abs(x - 64) / 50) * 3
    local z = 30 / dz
    local hl = (z + t * (1.6 - kls * 1.1)) % 1
    -- the road running to the horizon, its centre line flowing at us
    local rw = 2 + gy * 0.85
    local ax = math.abs(x - 64)
    if ax < rw then
      if ax < 2.5 and hl < 0.45 then return 4 + gs * 3, 2 end
      if ax > rw - 3 then return 2 + gs + mid_v * 1.2, 4 end
      local refl = (kls < 0.5 and gy < 10) and (1 - gy / 10) * 2 or 0
      return 1 + mid_v * 1.5 + refl, 4
    end
    local vx = ((x - 64) / dz * 0.9) % 1
    if hl < 0.25 or vx < 0.16 then return 1.5 + gs * 1.5, (hl < 0.25 and vx < 0.16) and 2 or 1 end
    return 0, 0
  end

  local function dot(l, s, x, y)
    if s == 0 or l < 0.5 then return end
    l = math.min(11, l * lvk)
    if s == 4 then put(l, x, y, 4, 4); return end
    local o = (4 - s) // 2
    put(l, x + o, y + o, s, s)
  end

  local function draw2(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl, mid, amp = A[K.LO], A[K.HI], K.kickless, A[K.MID], A[K.AMP]
    pump_t = pump_t * math.exp(-DT / 0.16)
    pump = K.follow(pump, pump_t, 0.06, DT)
    smear = smear * math.exp(-DT / 0.6)
    kls = kl
    gs = clamp(e * 0.6 + mid * 0.4, 0, 1)
    sun_y = 26 + kl * 9 - pump * 1.5
    sun_r = 8 + e * 2 + pump * 2 + lo * 2
    lvk = 0.6 + amp * 0.5
    sp_hi, mid_v = hi, mid
    heave = lo + pump * 0.5
    -- heal
    local heal = math.exp(-DT / 1.4)
    for i = 0, BC * BR - 1 do
      local b = blk[i]
      b.ox, b.oy = clamp(b.ox * heal, -10, 10), clamp(b.oy * heal, -8, 8)
      -- the shown offset slides toward the target (a smear, not a jump)
      local mx = 24 * DT
      b.px = b.px + clamp(b.ox - b.px, -mx, mx)
      b.py = b.py + clamp(b.oy - b.py, -mx, mx)
      b.frz = b.frz - DT
      b.cor = b.cor * math.exp(-DT / 0.5)
    end
    for k = #rep, 1, -1 do if T > rep[k].t + 0.3 then table.remove(rep, k) end end
    local rsrc, rt0, rt1 = {}, {}, {}
    for _, R in ipairs(rep) do if T >= R.t0 then rsrc[R.row], rt0[R.row], rt1[R.row] = R.src, R.t0, R.t end end

    for r = 0, BR - 1 do
      local rs = rsrc[r] or r
      for cc = 0, BC - 1 do
        -- a repeated row: most of its blocks become a fainter copy
        local sr = (rs ~= r and K.hash(cc + r * 16, 91) < 0.65 and T >= rt0[r] + K.hash(cc, 92) * 0.25 and T < rt1[r] + K.hash(cc, 93) * 0.3) and rs or r
        lvk = (0.6 + amp * 0.5) * (sr ~= r and 0.55 or 1)
        local b = blk[bi(cc, sr)]
        local ox, oy = b.px, b.py + (sr - r) * 8
        -- chaos: loose blocks wobble
        local hb = K.hash(cc + r * 16, 71)
        if hb < c * 0.55 then
          ox = ox + math.sin(T * (1.5 + hb * 4) + cc) * c * 6
          oy = oy + math.cos(T * (1.1 + hb * 3) + r) * c * 3
        end
        -- the fill: a smear wave left to right
        if smear > 0.05 then ox = ox - smear * 6 * math.max(0, math.sin(cc * 0.4 - T * 3)) end
        local t = b.frz > 0 and b.ft or T
        local x0, y0 = cc * 8, r * 8
        if b.cor > 0.1 then
          -- corrupted: bit-noise stripes
          local st = floor(T * 10)
          for k = 0, 3 do
            if K.hash(cc + r * 16, k + st * 4) < 0.55 then
              put(2 + b.cor * 7, x0, y0 + k * 2, 8 - floor(K.hash(k + st, cc + r) * 5), 1)
            end
          end
        else
          for j = 0, 1 do
            for k = 0, 1 do
              local x, y = x0 + k * 4, y0 + j * 4
              local l, sz = scene(x + 2 + ox, y + 2 + oy, t)
              dot(l, sz, x, y)
            end
          end
          if b.frz > 0 then put(2, x0, y0, 8, 1) end
          -- a moved block shows its seams
          local mv = math.abs(b.px) + math.abs(b.py)
          if mv > 6 then put(1 + mid * 1.5, x0, y0, 5, 1) end
        end
      end
    end
    -- the horizon line, held across the blocks
    K.dashes(2 + lo * 2 + amp, HY, 6, 8, T * 3)
    K.grain(function(u, v) return u * 128, v * 64 end, 2 + hi * 10 + c * 8, 4 + hi * 3)
  end

  function M.draw(S)
    if K.view == 2 then draw2(S) else draw1(S) end
  end

  M.init()
  return M
end
