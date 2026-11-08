-- acid: an oscilloscope in a dark room. a graticule of faint dots, the
-- screen's rounded bezel, and one trace: a filtered saw whose edge sharpens
-- as the acid perc opens and the highs come up, and whose resonance rings
-- on the edges as a squiggle that decays along the wave. the kick swells
-- the trace and resets its sweep; hats tick dots along the time base under
-- it; the phosphor keeps a faint ghost of the last sweeps. energy brightens
-- and widens it, chaos loses the trigger: the trace splits into jittering
-- copies, and a ratchet stacks a quick run of echoes of it
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  local X0, X1, Y0, Y1 = 3, 124, 3, 54     -- the screen inside the bezel
  local MY = 28                            -- the trace's centre line
  local TB = 59                            -- the time base under the screen
  local N = 60                             -- segments across

  local ghosts, dots, echoes
  local cut, res, amp, kickv, sweep_t0, ph

  function M.init()
    ghosts, dots, echoes = {}, {}, {}
    cut, res, amp, kickv, sweep_t0, ph = 0.2, 0.2, 6, 0, 0, 0
  end
  M.clear = M.init

  function M.kick(v)
    kickv = math.max(kickv, K.num(v, 1))
    sweep_t0 = K.T
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 5 then res = math.min(1.2, res + 0.6 * v); cut = math.min(1, cut + 0.5 * v)
    else cut = math.min(1, cut + 0.15 * v) end
  end

  local function tick_dot(v, big)
    if #dots >= 24 then table.remove(dots, 1) end
    local u = ((K.T - sweep_t0) / math.max(0.2, K.beat_sec)) % 1
    dots[#dots + 1] = {x = X0 + u * (X1 - X0), t0 = K.T, v = v, big = big}
  end
  function M.hat(v, open) tick_dot(K.num(v, 1), open) end
  function M.tick() tick_dot(0.5, false) end

  function M.snare(v) res = math.min(1.2, res + 0.25 * K.num(v, 1)) end

  function M.ratchet(n)
    n = clamp(K.num(n, 2), 1, 10)
    for k = 1, n do
      if #echoes >= 6 then table.remove(echoes, 1) end
      echoes[#echoes + 1] = {t0 = K.T + k * 0.035, dy = (k % 2 == 0 and 1 or -1) * (2 + k * 2.2), k = k}
    end
  end

  -- the wave at u (0..1 across the screen): a saw with nh harmonics plus a
  -- resonant ring at the cutoff that decays after each edge
  local function wave(u, nh, r, phase)
    local t = u * 2.5 + phase
    local y = 0
    for h = 1, nh do y = y + math.sin(h * K.TAU * t) / h end
    local frac = t % 1
    y = y + r * math.sin((nh + 1.5) * K.TAU * t) * math.exp(-frac * 3)
    return y
  end

  local function trace(lv, ys, dy, dx)
    local px, py
    for i = 0, N do
      local x = X0 + (X1 - X0) * i / N + (dx or 0)
      local y = ys[i] + (dy or 0)
      if px then line(lv, px, py, x, y) end
      px, py = x, y
    end
  end

  function M.draw(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi = A[K.LO], A[K.HI]
    kickv = kickv * math.exp(-DT / 0.12)
    cut = K.follow(cut, 0.12 + hi * 0.5 + K.env.acid * 0.4, 0.25, DT)
    res = K.follow(res, 0.15 + K.env.acid * 0.9 + c * 0.25, 0.4, DT)
    amp = K.follow(amp, 4 + lo * 5 + e * 2, 0.1, DT)
    ph = ph + (0.1 + e * 0.15 + hi * 0.12) * K.DTS  -- the scope's free-running drift

    -- the bezel and the graticule
    line(2, X0 - 1, Y0 - 2, X1 + 1, Y0 - 2)
    line(2, X0 - 1, Y1 + 2, X1 + 1, Y1 + 2)
    line(2, X0 - 3, Y0, X0 - 3, Y1)
    line(2, X1 + 3, Y0, X1 + 3, Y1)
    for gx = 0, 10 do
      local x = math.floor(X0 + (X1 - X0) * gx / 10 + 0.5)
      for gy = 0, 6 do
        local y = math.floor(Y0 + (Y1 - Y0) * gy / 6 + 0.5)
        put(1 + (gx == 5 and 0.5 or 0), x, y, 1, 1)
      end
    end
    K.dashes(1, MY, 1, 3, 0, X0, X1)
    for y = Y0, Y1, 3 do put(1, 64, y, 1, 1) end

    -- the trace: harmonics from the cutoff, ring from the resonance
    local nh = 1 + math.floor(cut * 5)
    local a = amp * (1 + kickv * 0.4)
    local jit = c * c
    local ys = {}
    for i = 0, N do
      local u = i / N
      local y = wave(u, nh, res * 1.2, ph)
      if jit > 0.05 then y = y + (K.hash(i + math.floor(T * 8) * 61, 3) - 0.5) * jit * 0.7 end
      ys[i] = clamp(MY - y * a * 0.55, Y0, Y1)
    end
    -- the phosphor's ghosts of the last sweeps
    for gi, g in ipairs(ghosts) do trace(1 + (gi / #ghosts) * 1.2, g) end
    -- chaos: the trigger slips and the trace splits into copies
    if c > 0.25 then
      local nc = 1 + math.floor(c * 1.6)
      for k = 1, nc do
        local dx = (K.hash(k * 7 + math.floor(T * 6), 5) - 0.5) * c * 18
        trace(1 + c * 1.5, ys, (K.hash(k, math.floor(T * 6)) - 0.5) * c * 6, dx)
      end
    end
    -- ratchet echoes stacked above and below
    for i = #echoes, 1, -1 do
      local E = echoes[i]
      local u = (K.T - E.t0) / 0.5
      if u >= 1 then table.remove(echoes, i)
      elseif u >= 0 then trace((3.5 - E.k * 0.3) * (1 - u), ys, E.dy * (1 + u * 0.3)) end
    end
    trace(4 + e * 2 + kickv * 2.5 + hi * 1.5, ys)
    -- the beam's head, sweeping one beat
    local su = ((K.T - sweep_t0) / math.max(0.2, K.beat_sec)) % 1
    local hx = math.floor(su * N + 0.5)
    put(9 + kickv * 3, X0 + (X1 - X0) * hx / N, ys[hx], 1, 1)

    -- keep a ghost a few times a second
    if (#ghosts == 0) or (T - (ghosts.t or 0) > 0.15) then
      local g = {}
      for i = 0, N do g[i] = ys[i] end
      table.insert(ghosts, 1, g)
      ghosts.t = T
      if #ghosts > 2 then table.remove(ghosts) end
    end

    -- the time base: hat ticks along it, the sweep's cursor
    line(1 + lo, X0, TB, X1, TB)
    for x = X0, X1, 12 do put(1.5, x, TB + 1, 1, 2) end
    put(3 + kickv * 6, X0 + su * (X1 - X0), TB - 1, 1, 3)
    for i = #dots, 1, -1 do
      local D = dots[i]
      local u = (K.T - D.t0) / 1.2
      if u >= 1 then table.remove(dots, i)
      else put((3 + 7 * D.v) * (1 - u), D.x, D.big and TB - 3 or TB - 2, 1, D.big and 2 or 1) end
    end
    -- the resonance lamp and the cutoff readout, as bars under the bezel
    put(1 + res * 6, 4, 62, math.max(1, res * 20), 1)
    put(1 + cut * 5, 70, 62, math.max(1, cut * 40), 1)
  end

  M.init()
  return M
end
