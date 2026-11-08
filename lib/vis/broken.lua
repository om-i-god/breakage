-- broken: a pane of glass at night with the street's light sliding across
-- it. every snare cracks it: a star of jagged fracture lines runs out from
-- the strike, ringed by a web of short arcs, bright at first and healing
-- slowly to a faint scar. the kick shakes the shards, each splinter
-- knocked a little its own way; hats glint along the cracks; a rim chips a
-- small star. energy lets the cracks run longer and heal slower, chaos
-- splinters them into more branches and leaves the shards out of true, and
-- a ratchet stitches a row of strikes across the pane
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  local MAXC = 9
  local cracks, glints, shake

  -- a crack: an impact point and its splinters (polylines), each with its
  -- own shake direction
  local function make(x, y, v, size)
    local c = K.chaos
    local e = K.energy
    local legs = {}
    local n = math.floor(4 + v * 3 + c * 4 + K.rnd() * 2)
    local len = (10 + v * 16 + e * 12) * (size or 1)
    local a0 = K.rnd() * K.TAU
    for i = 1, n do
      local a = a0 + i / n * K.TAU + (K.rnd() - 0.5) * 0.6
      local pts = {0, 0}
      local px, py, r = 0, 0, 0
      local segs = 3 + math.floor(K.rnd() * 3)
      local ll = len * (0.5 + K.rnd() * 0.7)
      for _ = 1, segs do
        a = a + (K.rnd() - 0.5) * (0.5 + c * 0.6)
        local step = ll / segs
        px, py = px + math.cos(a) * step, py + math.sin(a) * step
        pts[#pts + 1], pts[#pts + 2] = px, py
        r = r + step
      end
      -- chaos: a branch off the leg's middle
      local br
      if K.rnd() < 0.2 + c * 0.6 then
        local m = 2 * (1 + math.floor(#pts / 4)) - 1
        local bx, by = pts[m], pts[m + 1]
        local ba = a + (K.rnd() < 0.5 and 0.8 or -0.8)
        br = {bx, by, bx + math.cos(ba) * ll * 0.35, by + math.sin(ba) * ll * 0.35}
      end
      legs[i] = {pts = pts, br = br, sx = K.rnd() - 0.5, sy = K.rnd() - 0.5, off = (K.rnd() - 0.5) * c * 3}
    end
    -- the web: short arcs joining neighbouring legs, at a third of the way out
    local web = {}
    for ring = 1, (v > 0.6 and 2 or 1) do
      for i = 1, n do
        local A1, A2 = legs[i].pts, legs[i % n + 1].pts
        local k1 = math.min(#A1 - 1, 1 + 2 * ring)
        local k2 = math.min(#A2 - 1, 1 + 2 * ring)
        if K.rnd() < 0.75 then web[#web + 1] = {i, k1, i % n + 1, k2} end
      end
    end
    return {x = x, y = y, legs = legs, web = web, t0 = K.T, v = v, heal = 4 + e * 6}
  end

  -- a new strike: the oldest crack, if the pane is full, fades out quickly
  -- rather than vanishing
  local function strike(x, y, v, size)
    local live = 0
    for _, C in ipairs(cracks) do if not C.dying then live = live + 1 end end
    if live >= MAXC then
      for _, C in ipairs(cracks) do if not C.dying then C.dying = K.T; break end end
    end
    if #cracks >= MAXC + 10 then
      -- full even of fading ones: drop the faintest
      local wi, wv = 1, 1e9
      for i, C in ipairs(cracks) do
        local f = C.dying and (1 - (K.T - C.dying) / 0.3) or 2
        if f < wv then wi, wv = i, f end
      end
      table.remove(cracks, wi)
    end
    cracks[#cracks + 1] = make(x, y, v, size)
  end
  local pending = {}

  function M.init()
    cracks, glints, shake = {}, {}, 0
    pending = {}
    -- old scars already in the glass
    local r = {12, 9, 0.5, 98, 44, 0.4}
    for i = 1, #r, 3 do
      local c = make(r[i], r[i + 1], r[i + 2], 1)
      c.t0 = -100
      cracks[#cracks + 1] = c
    end
  end
  M.clear = M.init

  function M.snare(v)
    v = K.num(v, 1)
    strike(14 + K.rnd() * 100, 8 + K.rnd() * 48, v, 1)
  end
  function M.clap(v) strike(10 + K.rnd() * 108, 6 + K.rnd() * 52, K.num(v, 1) * 0.6, 0.7) end
  function M.rim(v) strike(8 + K.rnd() * 112, 6 + K.rnd() * 52, K.num(v, 1) * 0.3, 0.35) end
  function M.kick(v) shake = math.max(shake, K.num(v, 1)) end
  function M.hat(v)
    if #glints >= 12 or #cracks == 0 then return end
    local C = cracks[#cracks - math.floor(K.rnd() * math.min(3, #cracks))]
    local L = C.legs[1 + math.floor(K.rnd() * #C.legs)]
    local k = 2 * (1 + math.floor(K.rnd() * (#L.pts / 2 - 1))) + 1
    glints[#glints + 1] = {x = C.x + L.pts[k], y = C.y + L.pts[k + 1], t0 = K.T, v = K.num(v, 1)}
  end
  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 10)
    local x, y = 10 + K.rnd() * 40, 10 + K.rnd() * 44
    local dx, dy = (60 + K.rnd() * 40) / n, (K.rnd() - 0.5) * 6
    for k = 0, n - 1 do
      if #pending < 16 then pending[#pending + 1] = {t = K.T + k * 0.05, x = x + k * dx, y = y + k * dy} end
    end
  end

  function M.draw(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi = A[K.LO], A[K.HI]
    shake = shake * math.exp(-DT / 0.1)
    for i = #pending, 1, -1 do
      local P = pending[i]
      if K.T >= P.t then table.remove(pending, i); strike(P.x, P.y, 0.5, 0.45) end
    end
    local sh0 = shake * (0.8 + e * 0.8) + lo * 0.3

    -- the frame and the light sliding across the glass
    line(2, 0, 0, 127, 0); line(2, 0, 63, 127, 63)
    line(2, 0, 0, 0, 63); line(2, 127, 0, 127, 63)
    for k = 0, 2 do
      local x = ((T * (4 + k * 1.5) + k * 50) % 220) - 60
      local w = 10 + k * 6
      for q = 0, 1 do
        local xx = x + q * (w * 0.6)
        line(1 + hi * 1.2 + (q == 0 and 0.4 or 0), xx, 63, xx + 40, 0)
      end
    end

    -- the cracks: bright when struck, healing to a faint scar
    for ci = #cracks, 1, -1 do
      local C = cracks[ci]
      local age = K.T - C.t0
      local u = clamp(age / C.heal, 0, 1)
      local lv = 1.2 + (C.v * 7 + 2) * (1 - u) ^ 2 + hi * 1.2 * (1 - u * 0.5)
      local sh = sh0 * (1 - u) ^ 2 * (ci > #cracks - 3 and 1 or 0.3)
      local dying = C.dying and clamp((K.T - C.dying) / 0.3, 0, 1) or 0
      lv = lv * (1 - dying)
      if dying >= 1 or (u >= 1 and ci <= #cracks - 6) then table.remove(cracks, ci)
      else
        -- a fresh crack runs out from the strike over a few frames
        local grow = clamp(age / 0.2, 0, 1)
        for _, L in ipairs(C.legs) do
          local ox = C.x + L.sx * sh * 2 + L.off
          local oy = C.y + L.sy * sh * 2 + L.off * 0.5
          local P = L.pts
          local np = math.max(2, math.floor((#P / 2 - 1) * grow + 1.5))
          for k = 1, np - 1 do
            local j = 2 * k - 1
            line(lv * (1 - k * 0.08), ox + P[j], oy + P[j + 1], ox + P[j + 2], oy + P[j + 3])
          end
          if L.br and grow >= 1 then line(lv * 0.6, ox + L.br[1], oy + L.br[2], ox + L.br[3], oy + L.br[4]) end
        end
        if grow >= 1 then
          for _, W in ipairs(C.web) do
            local L1, L2 = C.legs[W[1]], C.legs[W[3]]
            line(lv * 0.5, C.x + L1.pts[W[2]] + L1.sx * sh * 2, C.y + L1.pts[W[2] + 1] + L1.sy * sh * 2,
              C.x + L2.pts[W[4]] + L2.sx * sh * 2, C.y + L2.pts[W[4] + 1] + L2.sy * sh * 2)
          end
        end
        -- the strike's point
        if u < 0.5 then put(lv * 0.8 + 2, C.x - 1, C.y - 1, 2, 2) end
      end
    end

    -- glints on the cracks
    for i = #glints, 1, -1 do
      local G = glints[i]
      local u = (K.T - G.t0) / 0.35
      if u >= 1 then table.remove(glints, i)
      else
        local lv = (4 + 8 * G.v) * math.sin(math.pi * u)
        put(lv, G.x, G.y, 1, 1)
        if lv > 4 then put(lv * 0.4, G.x - 1, G.y, 3, 1); put(lv * 0.4, G.x, G.y - 1, 1, 3) end
      end
    end
    -- dust in the light
    K.grain(function(uu, vv) return uu * 128, vv * 64 end, 2 + hi * 8 + e * 3, 3 + hi * 3)
  end

  M.init()
  return M
end
