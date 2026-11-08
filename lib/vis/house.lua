-- house: a warehouse at night, looking down the floor toward the booth. the
-- floor is ruled in rows that run off to the back wall and roll slowly
-- toward you; every kick sends a band of light rolling up the floor from
-- the booth to your feet. the roof's rafters run back to the same point and
-- an open hat runs a light along them; the crowd stands in silhouette in
-- front of you, nodding on the beat, and a clap puts their hands up.
-- energy fills the floor and the crowd, chaos doubles and shakes the rows
-- and a ratchet rolls a quick train of bands
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  local VX, VY = 64, 21                -- where it all runs to: the booth
  local NP = 9                        -- people in the crowd
  local MAXP, MAXL = 8, 10

  local pulses, lights, hands
  local prof = {}

  -- a row lit only where it is above the crowd
  local function rowc(l, y, xa, xb)
    xa, xb = xa or 0, xb or 128
    if xa < 0 then xa = 0 end
    if xb > 128 then xb = 128 end
    local run
    for x = xa, xb - 1 do
      if y < prof[x] then run = run or x
      elseif run then put(l, run, y, x - run, 1); run = nil end
    end
    if run then put(l, run, y, xb - run, 1) end
  end
  local booth, kickv
  local adv, adv_to = 0, 0             -- the floor's roll: a row per kick

  -- the crowd: a fixed line-up (x, head height, size)
  local PEOPLE = {}
  for i = 1, NP do
    local x = 6 + (i - 1) * 14.5 + (K.hash(i, 1) - 0.5) * 6
    PEOPLE[i] = {x = x, h = 49 + math.floor(K.hash(i, 2) * 5), r = 3.4 + K.hash(i, 3) * 1.2,
      ph = K.hash(i, 4) * 6.28, on = K.hash(i, 5)}
  end

  function M.init()
    pulses, lights, hands = {}, {}, {}
    for i = 1, NP do hands[i] = 0 end
    booth, kickv = 0, 0
    adv, adv_to = 0, 0
  end
  M.clear = M.init

  local function roll(v, delay)
    if #pulses >= MAXP then table.remove(pulses, 1) end
    pulses[#pulses + 1] = {t0 = K.T + (delay or 0), v = v}
  end

  function M.kick(v)
    v = K.num(v, 1)
    roll(v)
    booth, kickv = 1, v
    adv_to = adv_to + 1
  end

  function M.hat(v, open)
    if not open then return end
    if #lights >= MAXL then table.remove(lights, 1) end
    lights[#lights + 1] = {t0 = K.T, side = K.rnd() < 0.5 and -1 or 1, k = math.floor(K.rnd() * 3), v = K.num(v, 1)}
  end
  function M.ride(v) M.hat(K.num(v, 1) * 0.6, true) end

  function M.clap(v)
    -- a few hands go up, more with energy
    local n = 2 + math.floor((K.energy + K.num(v, 1)) * 3)
    for _ = 1, n do
      local i = 1 + math.floor(K.rnd() * NP)
      hands[i] = 1
    end
  end
  function M.snare(v) if K.rnd() < 0.5 then M.clap(K.num(v, 1) * 0.5) end end

  function M.ratchet(n)
    n = clamp(K.num(n, 2), 1, 12)
    for k = 1, n do roll(0.6, k * K.beat_sec / n * 0.5) end
  end

  -- depth z (1 near .. 24 far) -> floor row / ceiling row
  local function fy(z) return VY + 40 / z end
  local function cy(z) return VY - 22 / z end

  function M.draw(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi = A[K.LO], A[K.HI]
    booth = booth * math.exp(-DT / 0.15)
    adv = K.follow(adv, adv_to, 0.07, DT)
    if adv_to > 1000 then adv_to, adv = adv_to - 1000, adv - 1000 end

    -- the crowd's profile this frame, 1 px wide: heads nodding on the
    -- beat over shoulders, arms up after a clap
    local nod = K.playing and (0.5 + 0.5 * math.cos(K.beat_ph * K.TAU)) or 0
    for x = 0, 127 do prof[x] = 64 end
    local heads = {}
    local nvis = math.floor(5 + e * 3 + 0.5)
    for i, P in ipairs(PEOPLE) do
      hands[i] = hands[i] * math.exp(-DT / 0.35)
      if P.on * NP < nvis or hands[i] > 0.1 then
        local x = P.x + math.sin(T * 0.4 + P.ph) * 1.5
        local hy = P.h + nod * (0.8 + e * 1.4) * (0.6 + 0.4 * math.sin(P.ph))
        local r = P.r
        local sw = r + 6
        for xx = math.floor(x - sw), math.floor(x + sw) do
          if xx >= 0 and xx <= 127 then
            local dx = math.abs(xx + 0.5 - x)
            local top = 64
            if dx <= r then top = hy - math.sqrt(r * r - dx * dx) end
            local sh = hy + r + 2 + math.max(0, dx - r - 1) ^ 1.6 * 0.25
            if dx > r - 0.5 then top = math.min(top, math.max(hy + r * 0.7, sh)) end
            if top < prof[xx] then prof[xx] = top end
          end
        end
        heads[#heads + 1] = x; heads[#heads + 1] = hy; heads[#heads + 1] = r
        if hands[i] > 0.15 then
          local up = hands[i] ^ 0.5 * (9 + e * 4)
          for _, side in ipairs({-1, 1}) do
            local ax = math.floor(x + side * (r + 3.5))
            local ty = hy + r + 1 - up
            for xx = ax, ax + 1 do
              if xx >= 0 and xx <= 127 then prof[xx] = math.min(prof[xx], ty) end
            end
          end
        end
      end
    end

    -- the back wall and the booth light at the end of the room
    put(1 + booth * 4 + lo * 2, VX - 10, VY - 4, 20, 1)
    put(1, VX - 10, VY + 1, 20, 1)
    put(2 + booth * 9 + e * 2, VX - 2, VY - 2, 4, 2)
    put(1 + booth * 3, VX - 5, VY - 2, 2, 1); put(1 + booth * 3, VX + 3, VY - 2, 2, 1)

    -- the roof: rafters running back, trusses across, scrolling toward us
    local sc = (T * 0.08) % 1
    for k = 0, 5 do
      local z = 1.4 + (k + 1 - sc) * 3.4
      local y = math.floor(cy(z) + 0.5)
      local hw = 128 / z * 1.4
      if y >= 0 then line(1 + 1.4 / z * 3 + hi * 1.5, VX - hw, y, VX + hw, y) end
    end
    for k = -3, 3 do
      local x = VX + k * 30
      line(0.8 + hi * 1.5, VX + k * 2, VY - 2, x, 0)
    end
    -- open hats: lights running out along a rafter toward us
    for i = #lights, 1, -1 do
      local L = lights[i]
      local u = (K.T - L.t0) / 0.7
      if u >= 1 then table.remove(lights, i)
      else
        local k = L.side * (1 + L.k)
        local x0, x1 = VX + k * 2, VX + k * 30
        local f = u * u
        local px, py = x0 + (x1 - x0) * f, (VY - 2) * (1 - f)
        local f2 = math.max(0, u - 0.15) ^ 2
        local qx, qy = x0 + (x1 - x0) * f2, (VY - 2) * (1 - f2)
        line((3 + 7 * L.v) * (1 - u), qx, qy, px, py)
      end
    end

    -- the floor: rows rolling slowly toward us; chaos doubles and shakes them
    local rows = math.floor(4 + e * 4)
    local fs = (T * 0.06 + adv) % 1
    for k = 0, rows do
      local z = 1 + (k + 1 - fs) * (9 / rows)
      local y = fy(z)
      local jy = 0
      if c > 0.3 then jy = (K.hash(k + math.floor(T * 8) * 7, 9) - 0.5) * c * 4 end
      local yy = math.floor(y + jy + 0.5)
      if yy < 64 and yy > VY then
        local hw = (yy - VY) * 2.6
        rowc(1 + 0.8 / z + lo * 1.5 / z, yy, math.floor(VX - hw), math.ceil(VX + hw))
        if c > 0.55 and k % 4 == 1 then
          local x0 = math.floor(K.hash(k, math.floor(T * 6)) * 80)
          rowc(1, yy + 2, x0, x0 + 32)
        end
      end
    end
    -- the floor's boards running back
    for k = -5, 5 do
      local x1 = VX + k * 22
      local yb = 44
      local xb = VX + (x1 - VX) * (yb - VY) / (63 - VY)
      line(1 + lo * 1.5, VX + k * 1.5, VY + 2, xb, yb)
    end
    -- the kick's bands rolling up the floor to us
    for i = #pulses, 1, -1 do
      local P = pulses[i]
      local u = (K.T - P.t0) / math.max(0.25, K.beat_sec * 0.9)
      if u >= 1 then table.remove(pulses, i)
      elseif u >= 0 then
        local z = 16 / (1 + u * 15)
        local y = math.floor(fy(z) + 0.5)
        local lv = P.v * (3 + 7 * u) * (1 - u ^ 3) * (0.6 + 0.4 * e) + lo
        if y < 64 then
          local hw = (y - VY) * 2.6
          rowc(lv, y, math.floor(VX - hw), math.ceil(VX + hw))
          if u > 0.4 and y + 1 < 64 then rowc(lv * 0.4, y + 1, math.floor(VX - hw), math.ceil(VX + hw)) end
        end
      end
    end

    -- the crowd: dark figures against the floor, hatched faintly, their
    -- outlines caught in the light from the booth
    for x = 0, 127 do
      local top = math.floor(prof[x] + 0.5)
      if top < 64 then
        if x % 3 == 0 then put(1, x, top + 2, 1, 64 - top - 2) end
        local up = top < 50 and 1.5 or 0
        put(1.5 + booth * 2.5 + lo * 1.5 + up, x, top, 1, 1)
      end
    end
    for k = 1, #heads, 3 do
      K.ring(1.5 + booth * 3 + lo * 1.5, heads[k], heads[k + 1], heads[k + 2], 10)
    end
    K.haze(0, VY - 4, 128, VY + 8, 0.2 + 0.25 * e, 1, T * 5)
  end

  M.init()
  return M
end
