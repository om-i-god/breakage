-- dub: a sound-system yard at night, in fog. two speaker stacks stand
-- either side of the yard; the kick swells a low glow off the ground and
-- breathes the cones; every rim and snare drops a ring on the yard floor
-- that spreads outward, and at each echo time a fainter copy follows it,
-- until the echo dies. the fog drifts and the highs glint in it; energy
-- thickens the fog and lifts the glow, chaos scatters and wobbles the
-- rings and a ratchet throws a tight burst of them
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  local GY = 44                       -- the ground line (yard horizon)
  local CX, CY = 64, 50               -- where the hits land on the floor
  local MAXR, MAXE = 20, 10

  local rings, emits
  local glow, cone, flash

  function M.init()
    rings, emits = {}, {}
    glow, cone, flash = 0, 0, 0
  end
  M.clear = M.init

  local function spawn(lv, x, y, sp)
    if #rings >= MAXR then table.remove(rings, 1) end
    rings[#rings + 1] = {t0 = K.T, lv = lv, x = x, y = y, sp = sp, seed = math.floor(K.rnd() * 999)}
  end

  local function drop(v, sp)
    local c = K.chaos
    local x = CX + (K.rnd() - 0.5) * (10 + c * 60)
    local y = CY + (K.rnd() - 0.5) * (2 + c * 8)
    local lv = 4 + 6 * v
    spawn(lv, x, y, sp)
    if #emits >= MAXE then table.remove(emits, 1) end
    emits[#emits + 1] = {lv = lv, x = x, y = y, sp = sp, n = 0, next = K.NOW + K.echo_t}
  end

  function M.snare(v) drop(K.num(v, 1), 22); flash = math.max(flash, 0.6) end
  function M.rim(v) drop(K.num(v, 1) * 0.8, 30) end
  function M.clap(v) drop(K.num(v, 1) * 0.9, 18) end

  function M.kick(v) cone = 1; glow = math.max(glow, 0.5 + 0.5 * K.num(v, 1)) end

  function M.ratchet(n)
    n = clamp(K.num(n, 2), 1, 12)
    local x = CX + (K.rnd() - 0.5) * 50
    for k = 0, n - 1 do
      if #rings >= MAXR then table.remove(rings, 1) end
      rings[#rings + 1] = {t0 = K.T - k * 0.06, lv = 6 - k * 0.4, x = x + k * (K.rnd() - 0.5) * 6, y = CY,
        sp = 26, seed = k * 13}
    end
  end

  function M.draw(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi = A[K.LO], A[K.HI]
    -- the echo: each emitter repeats at the echo time, fainter by the feedback
    for i = #emits, 1, -1 do
      local em = emits[i]
      local n = 0
      while K.NOW >= em.next and n < 4 do
        em.lv = em.lv * K.echo_fb
        em.n = em.n + 1
        if em.lv >= 1 then
          local sc = c * 14
          spawn(em.lv, em.x + (K.rnd() - 0.5) * sc, em.y, em.sp)
        end
        em.next = em.next + K.echo_t
        n = n + 1
      end
      if em.lv < 1 or em.n >= 8 then table.remove(emits, i) end
    end
    glow = K.follow(glow, 0, 0.35, DT)
    cone = cone * math.exp(-DT / 0.12)
    flash = flash * math.exp(-DT / 0.2)
    local g = math.max(glow, lo * 0.7)

    -- stars and the sky's faint city lift
    for i = 0, 13 do
      local x, y = math.floor(K.hash(i, 1) * 127), 1 + math.floor(K.hash(i, 2) * 20)
      local tw = 0.5 + 0.5 * math.sin(T * (0.5 + K.hash(i, 3)) + i * 1.7)
      put(0.8 + tw * (0.6 + hi * 2.5), x, y, 1, 1)
    end
    K.gradient(GY - 12, GY - 1, function(y) return 0.05 + (y - GY + 12) / 12 * (0.2 + e * 0.3) end)

    -- the ground: a dim floor with the kick's glow rising off it
    -- the ground: a dim floor, the kick's glow pooling off it in front of
    -- the stacks, wider and brighter toward us
    for y = GY + 1, 63 do
      local u = (y - GY) / (63 - GY)
      local hw = 16 + u * 34 + g * 16
      local v = 0.05 + u * 0.2 + g * (0.2 + u * 1.8) * (0.6 + e * 0.5)
      K.gradient(y, y, function() return v end, nil, math.floor(CX - hw), math.floor(CX + hw))
      if y % 4 == 0 then K.dashes(1, y, 1, 7, T * 0.7 + y * 3) end
    end
    line(2 + g * 4 + K.bar_pulse, 0, GY, 127, GY)

    -- the stacks: a horn top over two bass bins, each bin's cone breathing
    local cb = cone * (1 + e)
    for side = 0, 1 do
      local x0 = side == 0 and 5 or 99
      local w = 24
      local top = GY - 32
      local l = 2 + g * 2
      local bx = x0 + w / 2
      line(l, x0, top, x0 + w, top)
      line(l, x0, top, x0, GY)
      line(l, x0 + w, top, x0 + w, GY)
      line(l * 0.8, x0, top + 8, x0 + w, top + 8)
      line(l * 0.8, x0, top + 20, x0 + w, top + 20)
      -- the horn: a flared slot, lit by the mids and the snare
      local hl = 1.5 + A[K.MID] * 3 + K.env.snare * 4
      line(hl, x0 + 3, top + 2, x0 + w - 3, top + 2)
      line(hl, x0 + 3, top + 6, x0 + w - 3, top + 6)
      line(hl * 0.7, x0 + 3, top + 2, x0 + 3, top + 6)
      line(hl * 0.7, x0 + w - 3, top + 2, x0 + w - 3, top + 6)
      put(1 + hi * 5 + K.env.hat * 4, bx + math.sin(T * 0.6 + side) * 8, top + 4, 1, 1)
      -- the bins
      for b = 0, 1 do
        local cy = top + 14 + b * 12
        local br = 4.6 + cb * (1.2 - b * 0.3) + 0.25 * math.sin(T * 1.1 + side * 2 + b)
        K.ring(2 + cb * 6 + lo * 3, bx, cy, br, 14)
        put(1.5 + cb * 5 + lo * 2, bx, cy, 1, 1)
      end
    end

    -- the rings on the yard floor, spreading and fading
    for i = #rings, 1, -1 do
      local R = rings[i]
      local age = K.T - R.t0
      local life = 2.2 + e
      if age > life then table.remove(rings, i)
      elseif age >= 0 then
        local u = age / life
        local r = 2 + age * R.sp
        local lv = R.lv * (1 - u) ^ 1.5 + hi * (1 - u)
        local jit = c * 3 * (1 - u)
        K.ring(lv, R.x, R.y, r, clamp(8 + r * 0.3, 8, 20), 0, K.TAU, 0.32, jit, R.seed)
        if c > 0.4 and i % 2 == 0 then
          K.ring(lv * 0.5, R.x + c * 4 * math.sin(R.seed), R.y, r * 0.8, 9, 0, K.TAU, 0.32, jit * 2, R.seed + 3)
        end
      end
    end
    if flash > 0.05 then put(3 + flash * 8, CX - 1, CY - 1, 2, 1) end

    -- the fog, drifting slowly through the yard
    K.haze(0, GY - 16, 128, 60, 0.2 + 0.2 * e + 0.15 * K.kickless, 1, T * 6)
    K.grain(function(u, v) return u * 128, GY - 14 + v * 20 end, 3 + hi * 14 + e * 6, 3 + hi * 4)
  end

  M.init()
  return M
end
