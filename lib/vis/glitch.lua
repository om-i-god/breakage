-- glitch. view 1: a circuit board close up: a clock chip feeding six voice chips down a bus of copper traces, vias, parts and a sheen moving over the solder mask.
-- view 2: a datamoshed picture: a sun on a gridded horizon drawn in halftone blocks that the drums shift, smear, repeat and corrupt, healing slowly.
-- view 3: the signal as a waterfall: ridge after ridge of its spectrum receding into the dark, each voice raising its own peak, sorted and stuttered by the glitches.
--
-- view 1: every hit sends a pulse racing from the clock chip down its trace
-- to that voice's chip (kick, snare, hats top; perc, ticks, breaks below),
-- which lights when it lands: a closed hat is a short quick blip, an open
-- hat a long slow smear, a clap two pulses close together, each perc kind
-- its own shape (a block, a pair of dots, a hollow box); reversed break
-- slices run back to the clock; a ratchet sends a train of pulses; error
-- and crush ticks corrupt a trace with a stutter of lit segments; a fill
-- fires every trace at once. the kick also runs a ripple out along the two
-- power rails. the edge connector is a logic probe stepping through the
-- bar, the status LEDs fill up through the phrase, every bar the clock's
-- pads blink and every phrase a bright sheen sweeps the board. AMP lights
-- the chips and the fingers, LO the rails, the clock and the cap, MID the
-- copper, HI the vias and the sheen. energy fills the bus with faint idle
-- data and brightens the board, chaos reroutes traces through detours and
-- shorts the bus with sparks (and misroutes some pulses), kickless
-- stretches dim the board and the kick chip and leave the clock breathing
-- with slow idle data on every trace.
-- view 2: the kick pumps the sun and melts the blocks around it downward,
-- snares shove a band of blocks sideways, closed hats nudge one block,
-- open hats smear a cluster, ticks corrupt blocks into bit-noise stripes,
-- each perc kind freezes its own block in time, break slices slide a
-- column of blocks, ratchets repeat one row down the picture, a fill smears
-- the whole image; everything heals back slowly. the sun climbs through
-- the phrase, every bar a keyframe line sweeps down healing the blocks it
-- passes, and on the phrase edge the picture blooms: every block drifts
-- along the last hit's motion for a beat. AMP lights the picture, LO heaves
-- the ground and swells the sun, MID lights the road, HI the stars and the
-- sun's halo. energy grows the sun and lights the grid, chaos keeps blocks
-- wobbling loose, kickless sinks the sun to a ring and slows the ground.
-- view 3: a new ridge leaves the front every 16th and recedes up the
-- screen; the front ridge is now. the kick throws up a peak in the lows,
-- the snare one in the mids, the clap a double peak beside it, closed
-- hats a narrow spike in the highs and open hats a ragged plateau, each
-- perc kind a needle at its own place, ticks a single hair, break slices
-- a hump that walks across with the slice (mirrored when reversed). a
-- ratchet stutters the same ridge out again and again, a fill runs a
-- bright wave back through the stack. the first ridge of each bar is lit
-- and drawn on into the floor (the bars recede as a grid), the phrase's
-- first is brighter with posts at its ends, and the strip at the top
-- counts the bar and the phrase. AMP raises the noise floor and lights the
-- bits, LO the low hump and the ground under the front ridge, MID the mid
-- hump and the ridges, HI the high spikes and sparks over them. energy
-- heightens every ridge, chaos shifts and pixel-sorts them, kickless
-- slows the fall and lays mist over the far ridges.
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
  local clks, litf = 0, {0, 0, 0, 0, 0, 0}   -- eased: the big fills never jump
  local MAXP = 28
  local rails                           -- kick ripples along the power rails: t0, v
  local barf, phf, phx                  -- bar blink, phrase sheen sweep
  local phrase_u = 0                    -- 0..1 through the phrase

  ---------------------------------------------------------------- view 2
  local HY = 36                         -- the horizon
  local BC, BR = 16, 8                  -- blocks: 16 x 8 of 8 px
  local blk                             -- per block: ox, oy, frz, ft, cor
  local rep                             -- repeated rows: {row, src, t}
  local pump, pump_t, smear
  local key_t                           -- the keyframe line's start (bar)
  local mosh, mdx, mdy                  -- the phrase bloom and its motion

  ---------------------------------------------------------------- view 3
  local NRID, NCOL = 13, 32             -- ridges, segments per ridge
  local rows                            -- rows[1] newest: {h = {0..NCOL}, bar, phr, sh, srt}
  local row_t                           -- K.T at the last capture
  local live = {}                       -- the front ridge, now
  local hold3 = {}                      -- the peak of live since the last capture
  local spikes                          -- perc / tick / break needles: f, w, v, t0, tau
  local stut, stut_n                    -- a ratchet's frozen ridge, how many more
  local mark_bar, mark_phr, rev_next
  local fill3                           -- K.T when a fill wave set off
  local hz = {}                         -- the hidden-line horizon per screen x
  local rid_id = 0

  function M.init()
    pulses, corrupt, sparks = {}, {}, {}
    lit = {}
    for v = 1, NV do lit[v] = 0 end
    clkf, idle_k, sheen_k = 0, -1, 0
    blk = {}
    for i = 0, BC * BR - 1 do blk[i] = {ox = 0, oy = 0, px = 0, py = 0, frz = 0, ft = 0, cor = 0} end
    rep = {}
    pump, pump_t, smear = 0, 0, 0
    key_t, mosh, mdx, mdy = -9, 0, 0, 0
    rails, barf, phf, phx = {}, 0, 0, -99
    rows, row_t, spikes = {}, 0, {}
    stut, stut_n, mark_bar, mark_phr, rev_next = nil, 0, false, false, false
    fill3 = -9
    for c = 0, NCOL do live[c], hold3[c] = 0, 0 end
  end
  M.clear = M.init

  local function path(v)
    if K.hash(v, 77) < K.chaos * 0.8 - 0.1 then return ALT[v] end
    return ROUTE[v]
  end

  local function send(v, lv, back, delay, spd, tail, shape)
    if #pulses >= MAXP then table.remove(pulses, 1) end
    local to = v
    -- chaos misroutes some
    if K.chaos > 0.5 and K.rnd() < (K.chaos - 0.5) * 0.6 then
      to = 1 + floor(K.rnd() * NV)
      if #sparks < 10 then sparks[#sparks + 1] = {x = 24 + K.rnd() * 60, y = 24 + floor(K.rnd() * 5) * 3, t0 = K.T} end
    end
    pulses[#pulses + 1] = {v = to, s = -(delay or 0), lv = lv, back = back == true, idle = false,
      spd = spd or 1, tail = tail or 4, shape = shape or 0}
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
  -- (view 3) a needle in the spectrum: at f (0..1), width w, decaying
  local function spike(f, w, v, tau)
    if #spikes >= 16 then table.remove(spikes, 1) end
    spikes[#spikes + 1] = {f = f, w = w, v = v, t0 = K.T, tau = tau}
  end
  local function moved(dx, dy) mdx, mdy = clamp(dx, -6, 6), clamp(dy, -6, 6) end

  function M.kick(v)
    v = K.num(v, 1)
    send(1, 6 + 5 * v)
    pump_t = 1
    if #rails >= 4 then table.remove(rails, 1) end
    rails[#rails + 1] = {t0 = K.T, v = v}
    -- melt the blocks around the sun downward
    for c = 6, 9 do
      for r = 2, 4 do
        local b = blk[bi(c, r)]
        b.oy = b.oy - (2 + 3 * v) * K.hash(c * 9 + r + floor(K.T * 7), 6)
      end
    end
    moved(0, -3)
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    send(2, 6 + 5 * v)
    local r = floor(K.rnd() * BR)
    local dx = (K.rnd() < 0.5 and -1 or 1) * (4 + 5 * v)
    shove_row(r, dx)
    moved(dx * 0.5, 0)
  end

  function M.clap(v)
    v = K.num(v, 1)
    send(2, 5 + 4 * v)
    send(2, 4 + 3 * v, false, 9)
    local r = floor(K.rnd() * (BR - 1))
    local dx = (K.rnd() < 0.5 and -1 or 1) * (3 + 3 * v)
    shove_row(r, dx); shove_row(r + 1, -dx)
    spike(0.38, 0.03, 0.9 * v, 0.12)
    spike(0.53, 0.03, 0.8 * v, 0.14)
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    if open then
      -- a long slow smear down the trace; a cluster of blocks smeared
      send(3, 4 + 2 * v, false, 0, 0.55, 9, 0)
      local c, r = floor(K.rnd() * (BC - 2)), floor(K.rnd() * (BR - 1))
      local dx = (K.rnd() < 0.5 and -1 or 1) * 5
      for i = 0, 2 do for j = 0, 1 do
        local b = blk[bi(c + i, r + j)]
        b.ox = b.ox + dx * (1 - i * 0.25)
      end end
      moved(dx * 0.4, 0)
    else
      -- a short quick blip; one block nudged
      send(3, 3 + 3 * v, false, 0, 1.4, 1, 0)
      local b = blk[floor(K.rnd() * BC * BR)]
      b.ox = b.ox + (K.rnd() < 0.5 and -2 or 2)
    end
  end

  function M.perc(kind, v)
    kind = clamp(floor(K.num(kind, 1)), 1, 21)
    v = K.num(v, 1)
    send(4, 5 + 4 * v, false, 0, 0.9, 3, kind % 3)
    -- each kind freezes its own block
    local b = blk[floor(K.hash(kind, 7) * BC * BR) % (BC * BR)]
    b.frz, b.ft = 0.8 + v * 0.6, K.T - 0.3 - K.hash(kind, 8)
    if kind == 11 or kind == 8 then lit[4] = math.max(lit[4], 0.5) end
    spike(0.22 + K.hash(kind, 9) * 0.5, 0.015 + (kind % 3) * 0.01, 0.6 + 0.4 * v, 0.15)
  end
  function M.tom(v) M.perc(1, v) end

  function M.tick(kind)
    kind = floor(K.num(kind, 1))
    if kind == 7 or kind == 3 then
      local v = 1 + floor(K.rnd() * NV)
      local P = ROUTE[v]
      local s0 = K.rnd() * P.total * 0.7
      if #corrupt < 6 then corrupt[#corrupt + 1] = {v = v, s0 = s0, s1 = s0 + 8 + K.rnd() * 14, t0 = K.T} end
      local b = blk[floor(K.rnd() * BC * BR)]
      b.cor = 1
    else
      send(5, 5, false, 0, 1.6, 0, 0)
      local b = blk[floor(K.rnd() * BC * BR)]
      b.ox = b.ox + (K.rnd() - 0.5) * 4
    end
    spike(0.9 + K.rnd() * 0.08, 0.008, 0.7, 0.07)
  end

  function M.brk(s, n, rev)
    s, n = floor(K.num(s, 1)), math.max(1, floor(K.num(n, 8)))
    send(6, 6, rev == true)
    local c = (s - 1) % BC
    for r = 0, BR - 1 do
      local b = blk[bi(c, r)]
      b.oy = b.oy + (rev and -4 or 4)
    end
    spike(0.15 + 0.7 * clamp((s - 0.5) / n, 0, 1), 0.05, 0.7, 0.1)
    if rev then rev_next = true end
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
    -- stutter the front ridge out n times
    stut = {}
    for c = 0, NCOL do stut[c] = live[c] + 3 end
    stut_n = math.min(n, 6)
  end

  function M.fill()
    for v = 1, NV do send(v, 9) end
    smear = 1
    fill3 = K.T
  end

  function M.bar(S)
    barf = 1
    key_t = K.T
    mark_bar = true
    local pl = math.max(1, floor(K.num(S and S.phrase_len, 16)))
    local pp = floor(K.num(S and S.phrase_pos, 1))
    if pp % pl == 0 then
      phx = K.T
      mosh = 1
      mark_phr = true
    end
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
    local v = 0
    if d < 26 then v = math.sin(d / 26 * math.pi) end
    -- the phrase sweep: a brighter band crossing the board once
    if phf > 0.02 then
      local p = (K.T - phx) * 110 - 30
      local q = math.abs(x + y * 0.8 - p)
      if q < 10 then v = v + phf * 1.6 * (1 - q / 10) end
    end
    return v
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
    clks = K.follow(clks, clkf, 0.06, DT)
    for v = 1, NV do
      lit[v] = lit[v] * math.exp(-DT / 0.22)
      litf[v] = K.follow(litf[v], lit[v], 0.06, DT)
    end

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
    -- the edge connector: a logic probe stepping through the bar
    local bp = K.bar_ph * 16
    for k = 0, 15 do
      local d = (bp - k) % 16
      local tr = d < 4 and (1 - d / 4) or 0
      put(1.2 + amp * 1.5 + tr * (3 + amp * 4 + K.env.kick * 3), 46 + k * 2, 63, 1, 1)
    end
    -- the status LEDs: filling up through the phrase
    local pn = phrase_u * 8
    for k = 0, 7 do
      local on = k < floor(pn) and 1 or 0
      local cur = (k == floor(pn)) and (0.5 + 0.5 * math.sin(T * 6)) or 0
      put(1 + on * (2 + amp * 2) + cur * 3 + barf * on * 2, 111 + k * 2, 45, 1, 2)
    end
    -- the power rails, a kick's ripple running out along them
    for ry = 17, 47, 30 do
      K.dashes((1 + lo * 1.5) * dim, ry, 3, 6, T * (3 + lo * 14), 20, 110)
    end
    for k = #rails, 1, -1 do
      local R = rails[k]
      local u = (T - R.t0) / 0.5
      if u >= 1 then table.remove(rails, k)
      else
        local x = 18 + u * 95
        local l = (3 + 6 * R.v) * (1 - u) * dim
        put(l, x, 17, 5, 1); put(l * 0.5, x - 5, 17, 5, 1)
        put(l, x, 47, 5, 1); put(l * 0.5, x - 5, 47, 5, 1)
      end
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
    for v = 1, NV do put(2.5 + lit[v] * 3 + barf * 3, CLK.x + CLK.w, CHIPS[v].bus - 1, 2, 3) end

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
      p.s = p.s + spd * DT * (p.idle and 0.45 or p.spd or 1)
      if p.s >= P.total then
        if not p.idle then lit[p.v] = math.max(lit[p.v], p.lv / 10) end
        table.remove(pulses, k)
      elseif p.s >= 0 then
        local s = p.back and (P.total - p.s) or p.s
        local dir = p.back and 1 or -1
        local tail = p.idle and 3 or (p.tail or 4)
        for j = tail, 0, -1 do
          local x, y = at(P, s + dir * j * 2)
          local l = p.lv * (1 - j / (tail + 1))
          if j == 0 and not p.idle then
            local sh = p.shape or 0
            if sh == 1 then
              put(math.min(12, l), x - 2, y - 1, 2, 2)
              put(math.min(12, l), x + 1, y - 1, 2, 2)
            elseif sh == 2 then
              local m = math.min(12, l)
              put(m, x - 2, y - 2, 5, 1); put(m, x - 2, y + 2, 5, 1)
              put(m, x - 2, y - 1, 1, 3); put(m, x + 2, y - 1, 1, 3)
            else
              put(l * 0.45, x - 2, y - 2, 5, 5)
              put(math.min(12, l), x - 1, y - 1, 3, 3)
            end
          else put(l * 0.8, x, y, 1, 1) end
        end
      end
    end

    -- the chips
    for v = 1, NV do
      local d = (v == 1) and (1 - kl * 0.6) or dim
      local l = lit[v] * 10 + (v == 1 and lo * 2 or 0) + (v == 3 and hi * 2 or 0) + amp * 3
      chip(CHIPS[v], l, litf[v], d)
    end
    -- the clock chip: its can, its LED keeping time
    local C = CLK
    put((1 + clks * 4 + lo * 2.5) * dim, C.x + 1, C.y + 1, C.w - 2, C.h - 2)
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
    sun_y = 30 - phrase_u * 7 + kl * 9 - pump * 1.5
    sun_r = 8 + e * 2 + pump * 2 + lo * 2
    lvk = 0.6 + amp * 0.5
    sp_hi, mid_v = hi, mid
    heave = lo + pump * 0.5
    -- heal; the bar's keyframe line heals the rows it passes faster, the
    -- phrase bloom drags every block along the last hit's motion
    local heal = math.exp(-DT / 1.4)
    local ky = (T - key_t) / math.max(0.2, K.beat_sec * 1.5) * 72 - 4
    local kh = math.exp(-DT / 0.12)
    local md = mosh * DT * 7
    for i = 0, BC * BR - 1 do
      local b = blk[i]
      local h = heal
      local ry = (i // BC) * 8
      if ky > ry - 2 and ky < ry + 10 then h = kh end
      b.ox, b.oy = clamp(b.ox * h + mdx * md * (0.5 + K.hash(i, 3)), -10, 10),
        clamp(b.oy * h + mdy * md * (0.5 + K.hash(i, 4)), -8, 8)
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
    -- the keyframe line sweeping down on the bar
    if ky > -2 and ky < 66 then
      local u = clamp(ky / 64, 0, 1)
      K.dashes(2 + 4 * (1 - u) + hi * 2, floor(ky), 3, 5, T * 40)
    end
    K.grain(function(u, v) return u * 128, v * 64 end, 2 + hi * 10 + c * 8, 4 + hi * 3)
  end

  ---------------------------------------------------------------- view 3 draw
  local exp = math.exp
  local function bump(f, c, w) local d = (f - c) / w; return exp(-d * d) end

  -- the spectrum now, into live[0..NCOL] (px of height at the front)
  local function spectrum(e, kl)
    local T, env = K.T, K.env
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]
    local g = 0.7 + 0.6 * e
    local rag = floor(T * 15)
    for c = 0, NCOL do
      local f = c / NCOL
      local h = (0.8 + amp * 2.5) * (0.55 + 0.45 * math.sin(c * 0.7 + T * 1.3))
        * (0.6 + 0.4 * math.sin(c * 0.23 - T * 0.7))
        + (4 + amp * 2) * (0.5 + 0.5 * math.sin(c * 0.31 + T * 0.9))
        * (0.5 + 0.5 * math.sin(c * 0.13 - T * 0.4 + 1))
        + (4 + mid * 3) * bump(f, 0.5 + 0.38 * math.sin(T * 0.37), 0.06)
      h = h + bump(f, 0.14, 0.07) * (lo * 7 + env.kick * 13 * (1 - kl)
        + kl * 2.5 * (0.5 + 0.5 * math.sin(T * 0.6)))
      h = h + bump(f, 0.46, 0.08) * (mid * 5 + env.snare * 10)
      h = h + bump(f, 0.78, 0.045) * (hi * 5 + env.hat * 9)
      if f > 0.6 and f < 0.97 then h = h + env.ohat * (4 + 4 * K.hash(c + rag * 37, 31)) end
      for i = 1, #spikes do
        local sp = spikes[i]
        local a = sp.v * exp(-(T - sp.t0) / sp.tau) * 12
        if a > 0.2 then h = h + a * bump(f, sp.f, sp.w) end
      end
      local to = clamp(h * g, 0, 24)
      live[c] = K.follow(live[c], to, to > live[c] and 0.035 or 0.12, K.DT)
    end
  end

  local function capture(rdt)
    local h = {}
    local src = hold3
    if stut and stut_n > 0 then src = stut; stut_n = stut_n - 1 end
    for c = 0, NCOL do h[c] = src[c] end
    for c = 0, NCOL do hold3[c] = live[c] end
    if rev_next then
      for c = 0, NCOL // 2 do h[c], h[NCOL - c] = h[NCOL - c], h[c] end
      rev_next = false
    end
    local c = K.chaos
    rid_id = rid_id + 1
    local row = {h = h, bar = mark_bar, phr = mark_phr, sh = 0, drop = K.rnd() < c * 0.25,
      ox = (rid_id % 2) * 2}
    if K.rnd() < c * 0.5 then row.sh = (K.rnd() - 0.5) * c * 30 end
    -- pixel-sort a window of the ridge, tallest first
    if K.rnd() < c - 0.3 then
      local a0 = floor(K.rnd() * (NCOL - 8))
      local a1 = math.min(NCOL, a0 + 6 + floor(K.rnd() * 12))
      local w = {}
      for k = a0, a1 do w[#w + 1] = h[k] end
      table.sort(w, function(x, y) return x > y end)
      for k = a0, a1 do h[k] = w[k - a0 + 1] end
    end
    mark_bar, mark_phr = false, false
    table.insert(rows, 1, row)
    if #rows > NRID then rows[#rows] = nil end
  end

  local function draw3(S)
    local T, DT, e, c, kl = K.T, K.DT, K.energy, K.chaos, K.kickless
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local env = K.env
    for i = #spikes, 1, -1 do
      local sp = spikes[i]
      if T - sp.t0 > sp.tau * 5 or T < sp.t0 then table.remove(spikes, i) end
    end
    spectrum(e, kl)
    for cc = 0, NCOL do if live[cc] > hold3[cc] then hold3[cc] = live[cc] end end
    local rdt = clamp(K.beat_sec * 2, 0.4, 2) * (1 + kl * 0.6)
    if T - row_t > rdt * 4 or T < row_t then row_t = T - rdt end
    while T - row_t >= rdt do
      row_t = row_t + rdt
      capture(rdt)
    end
    local frac = clamp((T - row_t) / rdt, 0, 1)

    -- the strip at the top: bits of data lit by the level, filling up
    -- through the phrase, and the bar's steps under them
    local bk = floor(T * 6)
    local pf = phrase_u * 32
    for k = 0, 31 do
      local on = K.hash(k + bk * 33, 40) < 0.3 + amp * 0.4
      local ph = k < pf
      if on or ph then
        put((on and (1.2 + amp * 3 + hi * 1.5) or 0) + (ph and (1 + barf * 2) or 0), k * 4 + 1, 1, 1, 3)
      end
    end
    local st = K.bar_ph * 16
    for k = 0, 15 do
      local d = (st - k) % 16
      local tr = d < 3 and (1 - d / 3) or 0
      put(1 + tr * (4 + env.kick * 4), k * 8 + 3, 5, 1, 2)
    end

    -- the ridges, front to back, each hiding what is behind it: a comb of
    -- bars standing up from its floor line, capped where the bar ends
    for x = 0, 127 do hz[x] = 64 end
    local fz = (T - fill3) * 14
    local n = #rows
    for k = 0, n do
      local h, z, row, fade
      if k == 0 then h, z, row, fade = live, 0, nil, 1
      else
        row = rows[k]
        h, z = row.h, k - 1 + frac
        fade = (k == NRID) and (1 - frac) or 1
      end
      local sc = 1 / (1 + z * 0.1)
      local yb = 61 - 3.6 * z + 0.08 * z * z
      local xw = 1
      -- each ridge's comb sits at its own fixed offset, so the bars only
      -- ever move up and down as the stack recedes
      local sh = row and (floor(row.sh) + row.ox) or 0
      local fog = sc ^ 1.4
      local lv = (0.8 + 3.4 * fog) * (0.75 + 0.4 * mid + 0.25 * e) * (1 - kl * 0.25)
      local lvb = lv                    -- the bodies: steady, the caps take the hits
      if k == 0 then lv = lv + 0.5 + env.kick * 2 * (1 - kl) + env.snare * 1.5 + amp end
      local marked = row and row.bar
      if marked then lv = lv * 1.25 + 0.6 end
      if row and row.phr then lv = lv + 1.5 end
      if fz < 18 then
        local d = math.abs(z - fz)
        if d < 1.5 then lv = lv + 5 * (1 - d / 1.5) * (1 - fz / 18) end
      end
      lv = math.min(12, lv * fade)
      lvb = math.min(9, lvb * fade)
      local cap = k < 4 or marked
      local step = (k < 5) and 1 or 2
      -- the bars
      for cc = (k % 2 == 1 and step > 1) and 1 or 0, NCOL, step do
        if not (row and row.drop and cc % 4 == 1) then
          local x = cc * 4 + sh
          if x >= 0 and x <= 127 then
            local y = floor(yb - h[cc] * sc * 1.3 + 0.5)
            local bot = math.min(floor(yb + 0.5) + 1, floor(hz[x]))
            if bot > y then
              local hl = math.min(13, lv * (0.55 + h[cc] / 30))
              local bl = lvb * (0.45 + h[cc] / 45) * (k == 0 and 0.7 or 0.9)
              if cap then
                put(bl * 0.75, x, y + 1, 1, bot - y - 1)
                put(math.min(13, hl + 1 + (k == 0 and hi * 2 or 0)), x, y, 1, 1)
              else
                put(bl * 0.8, x, y, 1, bot - y)
              end
            end
          end
        end
      end
      -- the front ridge, and each bar's first, are drawn as a line too
      if k == 0 then
        local px, py, pv
        for cc = 0, NCOL do
          local x = 64 + (cc * 4 - 64) * xw + sh
          local y = yb - h[cc] * sc * 1.3
          local ix = floor(x + 0.5)
          local vis = ix >= 0 and ix <= 127 and y < hz[ix] - 0.5
          if px and (vis or pv) then
            local l = math.min(10, lv * 0.55 + (h[cc] + h[cc - 1]) * 0.06)
            if vis and pv then line(l, px, py, x, y)
            else
              local mx, my = (px + x) / 2, (py + y) / 2
              if vis then line(l, mx, my, x, y) else line(l, px, py, mx, my) end
            end
          end
          px, py, pv = x, y, vis
        end
      end
      -- the horizon now runs along this ridge
      local qx, qy
      local x0, x1 = 999, -999
      for cc = 0, NCOL do
        local x = 64 + (cc * 4 - 64) * xw + sh
        local y = yb - h[cc] * sc * 1.3
        if x < x0 then x0 = x end
        if x > x1 then x1 = x end
        if qx then
          local a, b = math.max(0, math.ceil(qx)), math.min(127, floor(x))
          for xx = a, b do
            local u = (xx - qx) / math.max(0.01, x - qx)
            local yy = qy + (y - qy) * u
            if yy < hz[xx] then hz[xx] = yy end
          end
        end
        qx, qy = x, y
      end
      -- a bar's ridge runs on into the floor, a phrase's has posts
      if marked then
        local gl = (1.5 + 2 * fog + lo * 2) * fade
        local yy = floor(yb + 0.5)
        put(gl, 0, yy, 1, 2); put(gl * 0.7, 2, yy, 1, 2)
        put(gl, 127, yy, 1, 2); put(gl * 0.7, 125, yy, 1, 2)
        if row.phr then
          put(gl + 2, 0, yy - 5, 1, 5)
          put(gl + 2, 127, yy - 5, 1, 5)
        end
      end
    end

    -- the far noise floor, where the ridges fade out
    K.dashes(1 + amp * 0.8, 24, 2, 5, T * 2)
    if kl > 0.05 then K.haze(0, 14, 128, 40, kl * 0.4, 1, T * 3) end
    K.grain(function(u, v)
      local x = floor(u * 127)
      return x, math.max(8, hz[x] - 1 - v * 6)
    end, 2 + hi * 14 + c * 6, 3 + hi * 5)
  end

  function M.draw(S)
    local DT = K.DT
    barf = barf * math.exp(-DT / 0.15)
    phf = math.max(0, 1 - (K.T - phx) / 1.6)
    mosh = mosh * math.exp(-DT / (K.beat_sec * 0.8))
    local pl = math.max(1, K.num(S and S.phrase_len, 16))
    local pp = K.num(S and S.phrase_pos, 0) % pl
    phrase_u = K.follow(phrase_u, clamp(pp / pl, 0, 1), 0.3, DT)
    if K.view == 2 then draw2(S) elseif K.view == 3 then draw3(S) else draw1(S) end
  end

  M.init()
  return M
end
