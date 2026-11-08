-- gabber: a press shop on the night shift. three stamping presses stand in
-- a row under a gantry; on every kick a ram slams down onto its die (in
-- turn, or all three at the top of the energy) and climbs back slowly,
-- the bed shuddering under it. a pressure gauge at the end of the line
-- reads the energy, its needle trembling with the lows; noise snares
-- throw sparks off the dies that arc down and die on the floor. steam
-- vents as the rams rise. chaos knocks the presses out of step, shakes the
-- gauge and scatters the sparks; a ratchet hammers one press that many
-- times, each blow leaving a fading echo of the ram
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  local PX = {16, 46, 76}                -- the presses' centres
  local RW = 20                          -- a ram's width
  local TOP, UP, DOWN = 5, 15, 33        -- gantry, ram up / down (top edge)
  local RH = 8                           -- ram height
  local BED = 44                         -- the die bed
  local FLOOR = 56
  local GX, GY, GR = 112, 30, 11         -- the gauge

  local ram, hit_t, ghosts, sparks, steam
  local turn, gauge, gvel, shudder

  function M.init()
    ram, hit_t = {0, 0, 0}, {-9, -9, -9}
    ghosts, sparks, steam = {}, {}, {}
    turn, gauge, gvel, shudder = 0, 0, 0, 0
  end
  M.clear = M.init

  local function slam(p, v, delay)
    hit_t[p] = K.T + (delay or 0)
    shudder = math.max(shudder, 0.5 + 0.5 * v)
  end

  function M.kick(v)
    v = K.num(v, 1)
    local e, c = K.energy, K.chaos
    turn = turn % 3 + 1
    if c > 0.5 and K.rnd() < c * 0.6 then turn = 1 + math.floor(K.rnd() * 3) end
    slam(turn, v)
    if e > 0.75 then
      for p = 1, 3 do
        if p ~= turn then slam(p, v * 0.7, c * K.rnd() * 0.08) end
      end
    end
  end

  local function spark(x, n, v)
    for _ = 1, n do
      if #sparks >= 28 then table.remove(sparks, 1) end
      local c = K.chaos
      sparks[#sparks + 1] = {x = x + (K.rnd() - 0.5) * RW, y = BED - 1, vx = (K.rnd() - 0.5) * (50 + c * 60),
        vy = -(15 + K.rnd() * 35 + c * 20), t0 = K.T, v = v}
    end
  end
  function M.snare(v)
    v = K.num(v, 1)
    local p = 1 + math.floor(K.rnd() * 3)
    spark(PX[p], 3 + math.floor(v * 4), v)
  end
  function M.clap(v) spark(PX[1 + math.floor(K.rnd() * 3)], 3, K.num(v, 1) * 0.7) end
  function M.tick() spark(PX[1 + math.floor(K.rnd() * 3)], 1, 0.5) end
  function M.hat(v, open) if open then spark(PX[1 + math.floor(K.rnd() * 3)], 1, K.num(v, 1) * 0.5) end end

  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 12)
    local p = 1 + math.floor(K.rnd() * 3)
    for k = 0, n - 1 do
      if #ghosts >= 12 then table.remove(ghosts, 1) end
      ghosts[#ghosts + 1] = {p = p, t0 = K.T + k * 0.06}
    end
    slam(p, 0.8)
  end

  -- a ram's top edge: slams down in 40 ms, climbs back over most of a beat
  local function ram_y(p)
    local age = K.T - hit_t[p]
    if age < 0 then return UP end
    local down = 0.04
    if age < down then return UP + (DOWN - UP) * (age / down) ^ 2 end
    local up = math.max(0.2, K.beat_sec * 0.8)
    local u = clamp((age - down) / up, 0, 1)
    return DOWN - (DOWN - UP) * K.ease(u)
  end

  function M.draw(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi = A[K.LO], A[K.HI]
    shudder = shudder * math.exp(-DT / 0.12)
    local sh = math.floor(shudder * (1 + e) * math.sin(T * 60) + 0.5)

    -- the gantry and the floor
    line(2.5, 0, TOP, 96, TOP)
    line(1.5, 0, TOP + 2, 96, TOP + 2)
    for x = 2, 94, 8 do line(1, x, TOP, x + 4, TOP + 2) end
    line(2, 0, FLOOR, 127, FLOOR)
    -- hazard stripes along the floor's edge, a conveyor creeping under them
    for x = -4, 127, 6 do line(1.5, x, FLOOR + 6, x + 4, FLOOR + 2) end
    local cv = (T * 5) % 8
    for x = -8, 127, 8 do put(1.5 + lo * 2, x + cv, FLOOR + 1, 3, 1) end
    -- work lamps hung from the gantry, lit by the highs; one flickers
    for k, x in ipairs({30, 61, 92}) do
      local fl = k == 2 and (0.5 + 0.5 * math.sin(T * 13) * math.sin(T * 3.1)) or 1
      put((2 + hi * 6) * fl, x, TOP + 3, 2, 1)
      line((1 + hi * 2) * fl, x - 2, TOP + 4, x + 3, TOP + 4)
    end

    for p = 1, 3 do
      local cx = PX[p]
      local y = ram_y(p)
      local age = K.T - hit_t[p]
      local hot = age >= 0 and age < 0.3 and (1 - age / 0.3) or 0
      -- the piston rod and its cylinder
      put(2, cx - 4, TOP + 3, 9, 7)
      line(3 + hot * 3, cx - 1, TOP + 10, cx - 1, y)
      line(3 + hot * 3, cx + 1, TOP + 10, cx + 1, y)
      -- the ram: an outlined block, a lit edge at the bottom on impact
      local x0 = cx - RW / 2
      line(4 + hot * 4, x0, y, x0 + RW, y)
      line(3, x0, y, x0, y + RH)
      line(3, x0 + RW, y, x0 + RW, y + RH)
      for q = 2, RH - 2, 2 do put(1.5, x0 + 2, y + q, RW - 3, 1) end
      line(4 + hot * 8, x0, y + RH, x0 + RW, y + RH)
      -- the die and its bed, shuddering
      local by = BED + (p == turn and sh or 0)
      put(2.5 + hot * 3 + lo * 2, x0 - 2, by, RW + 5, 2)
      put(1.5, x0 + 1, by + 2, 3, FLOOR - by - 2)
      put(1.5, x0 + RW - 3, by + 2, 3, FLOOR - by - 2)
      -- the shock of the blow, spreading along the bed
      if hot > 0 then
        local w = (1 - hot) * 18 + 3
        line(hot * 9, x0 - w, by - 1, x0 - 2, by - 1)
        line(hot * 9, x0 + RW + 2, by - 1, x0 + RW + w, by - 1)
      end
      -- steam venting as the ram climbs back
      if age > 0.1 and age < 1.2 then
        local u = (age - 0.1) / 1.1
        for k = 0, 2 do
          local sx = cx + (k - 1) * 6 + math.sin(T * 3 + k + p) * 2 * u
          put((2 + e * 2) * (1 - u), sx, TOP + 9 - u * 6 - k, 2, 1)
        end
      end
    end

    -- ratchet echoes: the ram's ghost, hammered again and again
    for i = #ghosts, 1, -1 do
      local G = ghosts[i]
      local u = (K.T - G.t0) / 0.4
      if u >= 1 then table.remove(ghosts, i)
      elseif u >= 0 then
        local x0 = PX[G.p] - RW / 2 - 2 - u * 6
        local y = DOWN - u * 10
        line(6 * (1 - u), x0, y, x0 + RW + 4 + u * 12, y)
        line(4 * (1 - u), x0, y + RH, x0 + RW + 4 + u * 12, y + RH)
      end
    end

    -- sparks: falling arcs, a short streak along their path
    for i = #sparks, 1, -1 do
      local P = sparks[i]
      local age = K.T - P.t0
      local u = age / 0.8
      local x = P.x + P.vx * age
      local y = P.y + P.vy * age + 60 * age * age
      if u >= 1 or y > FLOOR then table.remove(sparks, i)
      else
        local lv = (6 + 6 * P.v) * (1 - u) + hi * 2
        local vx, vy = P.vx, P.vy + 120 * age
        local m = math.sqrt(vx * vx + vy * vy) + 0.01
        line(lv, x - vx / m * 2.5, y - vy / m * 2.5, x, y)
      end
    end

    -- the gauge: energy, trembling with the lows, shaken by chaos
    local tgt = 0.08 + e * 0.8 + lo * 0.12 + (c > 0.3 and (K.hash(math.floor(T * 12), 4) - 0.5) * c * 0.2 or 0)
    gvel = gvel + ((tgt - gauge) * 120 - gvel * 10) * DT
    gauge = clamp(gauge + gvel * DT, 0, 1.05)
    K.ring(3, GX, GY, GR, 20)
    K.ring(1.5, GX, GY, GR + 2, 20)
    for k = 0, 8 do
      local a = math.pi * 0.75 + k / 8 * math.pi * 1.5
      local hot = k >= 6
      line(hot and 4 or 2, GX + math.cos(a) * (GR - 3), GY + math.sin(a) * (GR - 3), GX + math.cos(a) * (GR - 1), GY + math.sin(a) * (GR - 1))
    end
    local ga = math.pi * 0.75 + gauge * math.pi * 1.5 + math.sin(T * 31) * (lo * 0.05 + 0.02)
    line(7 + K.env.kick * 3, GX, GY, GX + math.cos(ga) * (GR - 2), GY + math.sin(ga) * (GR - 2))
    put(4, GX - 1, GY - 1, 2, 2)
    -- the pipe from the gauge down to the line, and a warning lamp
    line(2, GX, GY + GR + 2, GX, FLOOR - 1)
    line(2, 96, FLOOR - 4, GX, FLOOR - 4)
    put(1.5 + (gauge > 0.75 and (0.5 + 0.5 * math.sin(T * 6)) * 6 or 0), GX - 1, 8, 3, 3)
    -- haze in the roof, thicker with energy
    K.haze(0, 0, 128, 14, 0.25 + e * 0.2 + hi * 0.2, 1, T * 6)
  end

  M.init()
  return M
end
