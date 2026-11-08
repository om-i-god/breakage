-- drill: a drill bit seen end-on, spinning. its flutes are a tight spiral
-- that winds on steadily, faster with energy, and spins up hard on a
-- ratchet, which also stamps that many concentric rings out from the tip.
-- around the bit runs a ring of segments, one per slice of the break: the
-- slice playing lights up (a reversed slice lights from the inside out,
-- with a back-tick), and the last few stay warm. the kick bites: the
-- spiral pulls in and the core glows; snares and ticks throw swarf off the
-- edge in curls that fly out to the sides. chaos adds flutes, shakes them
-- off true and scatters the swarf
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  local CX, CY = 64, 32
  local RB = 24                        -- the bit's radius
  local RS = 28                        -- the slice ring's radius

  local rot, spin, bite, stamps, swarf, slit, nsl

  function M.init()
    rot, spin, bite = 0, 0, 0
    stamps, swarf, slit = {}, {}, {}
    nsl = 8
  end
  M.clear = M.init

  function M.kick(v) bite = math.max(bite, K.num(v, 1)) end

  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 16)
    spin = math.min(9, spin + 2 + n * 0.8)
    for k = 1, math.min(n, 8) do
      if #stamps >= 8 then table.remove(stamps, 1) end
      stamps[#stamps + 1] = {t0 = K.T + (k - 1) * 0.045, k = k, n = n}
    end
  end

  local function throw(v, big)
    if #swarf >= 20 then table.remove(swarf, 1) end
    local a = rot * 0.5 + K.rnd() * K.TAU
    local c = K.chaos
    swarf[#swarf + 1] = {a = a, t0 = K.T, v = K.num(v, 1), sp = 40 + K.rnd() * 30 + c * 30,
      curl = (K.rnd() - 0.5) * (2 + c * 4), big = big}
  end
  function M.snare(v) throw(v, true); throw(K.num(v, 1) * 0.6, false) end
  function M.tick() throw(0.5, false) end
  function M.hat(v) if K.rnd() < 0.3 then throw(K.num(v, 1) * 0.4, false) end end

  function M.brk(i, n, rev)
    nsl = clamp(math.floor(K.num(n, 8)), 1, 32)
    i = clamp(math.floor(K.num(i, 1)), 1, nsl)
    slit[i] = {t0 = K.T, rev = rev == true}
  end

  -- the arc of slice i of n, as a few segments, at radius r
  local function seg(lv, i, n, r, rot0)
    local gap = math.min(0.08, K.TAU / n * 0.2)
    local a0 = rot0 + (i - 1) / n * K.TAU + gap
    local a1 = rot0 + i / n * K.TAU - gap
    K.ring(lv, CX, CY, r, math.max(2, math.floor(24 / n + 1)), a0, a1)
  end

  function M.draw(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi = A[K.LO], A[K.HI]
    bite = bite * math.exp(-DT / 0.12)
    spin = spin * math.exp(-DT / 0.6)
    local omega = 0.6 + e * 2.2 + spin + (K.playing and 0.4 or 0)
    rot = (rot + omega * K.DTS) % (K.TAU * 1000)

    -- the slice ring: every slice a dim arc, the playing one bright
    local n = nsl
    local r0 = -math.pi / 2
    for i = 1, n do
      local L = slit[i]
      local lv = 1.5
      if L then
        local age = K.T - L.t0
        lv = 1.5 + 10 * math.exp(-age / 0.25) + 2 * math.exp(-age / 2)
        if age > 6 then slit[i] = nil end
      end
      seg(lv + hi * 1.5, i, n, RS, r0)
      if L and K.T - L.t0 < 0.4 then
        local u = (K.T - L.t0) / 0.4
        local rr = L.rev and (RS - 1 - u * 3) or (RS + 1 + u * 3)
        seg((8 - 6 * u), i, n, rr, r0)
        if L.rev then
          local am = r0 + (i - 0.5) / n * K.TAU
          line(6 * (1 - u), CX + math.cos(am) * (RS - 4), CY + math.sin(am) * (RS - 4),
            CX + math.cos(am - 0.15) * (RS - 1), CY + math.sin(am - 0.15) * (RS - 1))
        end
      end
    end
    -- the slice index ticks just outside, every quarter of the ring
    for q = 0, 3 do
      local a = r0 + q / 4 * K.TAU
      put(2, CX + math.cos(a) * (RS + 3), CY + math.sin(a) * (RS + 3), 1, 1)
    end

    -- the bit: flutes as spirals winding in to the tip
    local arms = 2 + math.floor(c * 3 + 0.5)
    local blur = 1 / (1 + math.max(0, omega - 2) * 0.12)     -- fast spin smears the flutes dim
    local scale = 1 - bite * 0.18
    for k = 0, arms - 1 do
      local a0 = rot + k / arms * K.TAU
      local px, py
      for q = 0, 20 do
        local f = q / 20
        local r = (2 + f * (RB - 2)) * scale
        local a = a0 + f * 5.2
        if c > 0.2 then r = r + (K.hash(q + k * 31 + math.floor(T * 10) * 7, 3) - 0.5) * c * 3 end
        local x, y = CX + math.cos(a) * r, CY + math.sin(a) * r
        if px then line((2.5 + f * 2.5 + lo * 2 + e * 1.5) * blur, px, py, x, y) end
        px, py = x, y
      end
    end
    -- the bit's rim and its cutting edge, and the core
    K.ring(1.5 + lo * 2, CX, CY, RB * scale + 1, 24)
    K.disc(1.5 + bite * 8 + lo * 3, CX, CY, 2.5 * scale + 0.5)

    -- ratchet stamps: concentric repeats running out from the tip
    for i = #stamps, 1, -1 do
      local St = stamps[i]
      local u = (K.T - St.t0) / 0.5
      if u >= 1 then table.remove(stamps, i)
      elseif u >= 0 then
        local r = 3 + u * (RS + 10) + St.k * 1.5
        K.ring((6 - St.k * 0.5) * (1 - u) ^ 1.5, CX, CY, r, 20)
      end
    end

    -- swarf: curls thrown off the edge, flying out and fading
    for i = #swarf, 1, -1 do
      local W = swarf[i]
      local age = K.T - W.t0
      local u = age / 0.9
      if u >= 1 then table.remove(swarf, i)
      else
        local d = RB + age * W.sp
        local a = W.a + W.curl * age
        local x, y = CX + math.cos(a) * d * 1.6, CY + math.sin(a) * d * 0.6
        local lv = (4 + 8 * W.v) * (1 - u)
        local tx, ty = math.cos(a + 1.3) * (W.big and 4 or 2), math.sin(a + 1.3) * (W.big and 3 or 1.5)
        line(lv, x - tx, y - ty, x + tx, y + ty)
      end
    end

    -- the speed lines either side, more and faster with the spin
    local sl = math.floor(3 + omega * 1.2)
    for k = 1, math.min(sl, 9) do
      local y = 4 + K.hash(k, 9) * 56
      local x = (K.hash(k, 10) * 30 + T * (20 + omega * 18)) % 34
      put(1 + hi * 2, x, y, 4, 1)
      put(1 + hi * 2, 127 - x - 4, 63 - y, 4, 1)
    end
  end

  M.init()
  return M
end
