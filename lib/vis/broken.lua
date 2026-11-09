-- broken: view 1, a pane of glass in front of a night city that the snares crack with clean radial fractures, shards falling away, healing on phrase edges; view 2, a shattered mirror whose shards each show an offset copy of the moonlit city, shifting and shearing on the hits.
--
-- view 1: behind the glass, a skyline against a sodium glow: far blocks in
-- dim mass, near blocks black with lit windows, cars streaking along the
-- street. the pane has a frame and a slow sliding glare. every snare
-- strikes it: straight fractures race out from the impact to the frame,
-- joined by rings of web, bright as they run and settling to a pale scar;
-- a cell or two of the web breaks loose and falls away. the kick shakes the
-- pane in its frame (the city behind stays still); hats run glints out
-- along the fractures, a rim chips a small star, percussion lights windows,
-- break slices send cars by. on each phrase edge the pane heals. energy
-- lights the city and lengthens the fractures, chaos splinters them with
-- branches and doubles each strike; kickless, the city dims and drips run
-- down the glass.
-- view 2: the mirror broken into triangles. each shard shows the same scene
-- (moon, skyline, water and the moon's glade) from its own place: a snare
-- knocks a handful of shards to new offsets and shears, the kick breathes
-- them all outward, hats glint on the edges, chaos throws them further and
-- flips some; a phrase edge (and a kickless stretch, slowly) pulls the
-- mirror back toward whole.
--
-- the ears: view 1, the lows raise the sodium glow and pool the street
-- lamps, the mids switch on the city's windows and ring through the cracks,
-- the highs glitter the stars, the glare and the light along the fractures;
-- view 2, the lows swell and light the moon, the mids light
-- the towers, the highs glitter on the water and the shard edges.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  ----------------------------------------------------------------------
  -- the city (view 1), fixed by hash
  ----------------------------------------------------------------------
  local FAR, NEAR = {}, {}
  local GY = 54                          -- street level
  do
    local x, i = 0, 0
    while x < 130 do
      local w = 6 + math.floor(K.hash(i, 11) * 10)
      local top = 24 + math.floor(K.hash(i, 12) * 12)
      for xx = x, x + w - 1 do FAR[xx // 2] = top end
      x, i = x + w, i + 1
    end
    x, i = 0, 0
    while x < 130 do
      local w = 10 + math.floor(K.hash(i, 21) * 14)
      local gap = K.hash(i, 22) < 0.3 and 4 or 0
      local top = 32 + math.floor(K.hash(i, 23) * 14)
      for xx = x, x + w - 1 do NEAR[xx // 2] = top end
      for xx = x + w, x + w + gap - 1 do NEAR[xx // 2] = 64 end
      x, i = x + w + gap, i + 1
    end
    for c = 0, 64 do
      FAR[c] = FAR[c] or 30
      NEAR[c] = NEAR[c] or 64
      if NEAR[c] > GY then NEAR[c] = GY end
    end
  end
  -- the near windows: 2x2 cells on a 4px grid inside the near blocks
  local WIN = {}
  for x = 2, 124, 4 do
    local top = NEAR[x // 2]
    if NEAR[(x + 1) // 2] == top then
      for y = top + 3, GY - 4, 4 do
        local i = #WIN + 1
        WIN[i] = {x = x, y = y, on = K.hash(i, 31), tv = K.hash(i, 32) < 0.1}
      end
    end
  end
  local NW = #WIN

  local cracks, shards, glints, cars, drips, pending
  local shake, wlit, heal_t
  local shake_dir = 1
  local MAXC = 3

  local function edge_dist(x, y, a)
    local ca, sa = math.cos(a), math.sin(a)
    local t = 999
    if ca > 0.001 then t = math.min(t, (126 - x) / ca) elseif ca < -0.001 then t = math.min(t, (1 - x) / ca) end
    if sa > 0.001 then t = math.min(t, (62 - y) / sa) elseif sa < -0.001 then t = math.min(t, (1 - y) / sa) end
    return math.max(2, t)
  end

  -- a strike: n rays to (toward) the frame, rings of web across them
  local function make(x, y, v, size)
    local c, e = K.chaos, K.energy
    local n = math.floor(5 + v * 2 + c * 3)
    if size < 0.5 then n = 4 + math.floor(K.rnd() * 2) end
    local rays = {}
    local a0 = K.rnd() * K.TAU
    local reach = (16 + v * 30 + e * 22) * size
    for i = 1, n do
      local a = a0 + (i - 1) / n * K.TAU + (K.rnd() - 0.5) * (0.5 / n * K.TAU)
      local L = math.min(edge_dist(x, y, a), reach * (0.6 + 0.5 * K.rnd()))
      local br
      if K.rnd() < c * 0.7 then
        local f = 0.35 + K.rnd() * 0.4
        local ba = a + (K.rnd() < 0.5 and 0.5 or -0.5)
        br = {f, ba, L * (0.2 + 0.3 * K.rnd())}
      end
      rays[i] = {a = a, L = L, br = br, j = {0.8 + K.rnd() * 0.4, 0.8 + K.rnd() * 0.4, 0.8 + K.rnd() * 0.4}}
    end
    local rs = size < 0.5 and {3 * size / 0.35} or {4 + 2 * v, 9 + 4 * v, 15 + 5 * v}
    for k = 1, #rs do rs[k] = rs[k] * (0.8 + size * 0.3) end
    return {x = x, y = y, rays = rays, rs = rs, t0 = K.T, v = v, size = size, gone = {}}
  end

  local function ray_pt(C, i, k)
    local R = C.rays[(i - 1) % #C.rays + 1]
    local r = math.min(C.rs[k] * R.j[k], R.L)
    return C.x + math.cos(R.a) * r, C.y + math.sin(R.a) * r, C.rs[k] * R.j[k] <= R.L
  end

  local function drop_shard(C)
    if #C.rs < 3 or #shards >= 10 then return end
    local i = 1 + math.floor(K.rnd() * #C.rays)
    if C.gone[i] then return end
    local k = K.rnd() < 0.5 and 2 or 1
    local x1, y1, o1 = ray_pt(C, i, k)
    local x2, y2, o2 = ray_pt(C, i, k + 1)
    local x3, y3, o3 = ray_pt(C, i + 1, k + 1)
    local x4, y4, o4 = ray_pt(C, i + 1, k)
    if not (o1 and o2 and o3 and o4) then return end
    C.gone[i] = k
    local cx, cy = (x1 + x2 + x3 + x4) / 4, (y1 + y2 + y3 + y4) / 4
    shards[#shards + 1] = {cx = cx, cy = cy, p = {x1 - cx, y1 - cy, x2 - cx, y2 - cy, x3 - cx, y3 - cy, x4 - cx, y4 - cy},
      t0 = K.T + 0.12 + K.rnd() * 0.5, w = (K.rnd() - 0.5) * 4, vx = (K.rnd() - 0.5) * 10}
  end

  local function strike(x, y, v, size)
    local live = 0
    for _, C in ipairs(cracks) do if not C.heal then live = live + 1 end end
    if live >= MAXC then
      for _, C in ipairs(cracks) do if not C.heal then C.heal = K.T; break end end
    end
    if #cracks >= MAXC + 2 then table.remove(cracks, 1) end
    local C = make(x, y, v, size)
    cracks[#cracks + 1] = C
    if size >= 0.5 then
      local nd = 1 + math.floor(K.energy * 1.5 + K.chaos * 2)
      for _ = 1, nd do drop_shard(C) end
    end
    return C
  end

  ----------------------------------------------------------------------
  -- the mirror (view 2): a jittered grid split into triangles
  ----------------------------------------------------------------------
  local GXS = {0, 26, 51, 77, 102, 128}
  local GYS = {0, 21, 43, 64}
  local VX, VY = {}, {}
  local TRI = {}
  local layout, built = 0, -1
  local function build(seed)
    for i = 1, 6 do
      VX[i], VY[i] = {}, {}
      for j = 1, 4 do
        local jx = (i > 1 and i < 6) and (K.hash(i * 7 + j, seed) - 0.5) * 16 or 0
        local jy = (j > 1 and j < 4) and (K.hash(i * 7 + j, seed + 1) - 0.5) * 12 or 0
        VX[i][j], VY[i][j] = GXS[i] + jx, GYS[j] + jy
      end
    end
    local keep = {}
    for i = 1, #TRI do keep[i] = TRI[i] end
    TRI = {}
    for i = 1, 5 do
      for j = 1, 3 do
        local a = {VX[i][j], VY[i][j]}
        local b = {VX[i + 1][j], VY[i + 1][j]}
        local c = {VX[i + 1][j + 1], VY[i + 1][j + 1]}
        local d = {VX[i][j + 1], VY[i][j + 1]}
        local t1, t2
        if (i + j) % 2 == 0 then t1, t2 = {a, b, c}, {a, c, d} else t1, t2 = {a, b, d}, {b, c, d} end
        for _, t in ipairs({t1, t2}) do
          local n = #TRI + 1
          local o = keep[n] or {dx = 0, dy = 0, sh = 0, tdx = 0, tdy = 0, tsh = 0, hit = -9}
          o.v = t
          o.cx = (t[1][1] + t[2][1] + t[3][1]) / 3
          o.cy = (t[1][2] + t[2][2] + t[3][2]) / 3
          o.flip = K.hash(n, seed + 5) < 0.25
          TRI[n] = o
        end
      end
    end
  end

  local moonlo = 0                     -- the lows, eased for the moon (view 2)
  function M.init()
    cracks, shards, glints, cars, drips, pending = {}, {}, {}, {}, {}, {}
    moonlo = 0
    shake, heal_t = 0, -9
    wlit = {}
    TRI = {}
    layout = 3
    build(layout)
    built = layout
    -- an old scar already in the glass
    local C = make(100, 14, 0.4, 0.6)
    C.t0 = -100
    cracks[1] = C
  end
  M.clear = M.init

  local function hit_mirror(v, count, amt)
    local c = K.chaos
    for _ = 1, count do
      local T = TRI[1 + math.floor(K.rnd() * #TRI)]
      local r = (3 + 9 * v + 14 * c) * amt
      T.tdx, T.tdy = (K.rnd() - 0.5) * 2 * r, (K.rnd() - 0.5) * r
      T.tsh = (K.rnd() - 0.5) * (0.4 + c * 0.8) * amt
      T.hit = K.T
    end
  end

  function M.snare(v)
    v = K.num(v, 1)
    if K.view == 2 then hit_mirror(v, 4 + math.floor(K.chaos * 5), 1); return end
    local x, y = 16 + K.rnd() * 96, 8 + K.rnd() * 44
    strike(x, y, v, 1)
    if K.chaos > 0.5 then strike(x + (K.rnd() - 0.5) * 30, y + (K.rnd() - 0.5) * 16, v * 0.6, 0.6) end
  end
  function M.clap(v)
    if K.view == 2 then hit_mirror(K.num(v, 1), 3, 0.7); return end
    strike(10 + K.rnd() * 108, 6 + K.rnd() * 50, K.num(v, 1) * 0.6, 0.6)
  end
  function M.rim(v)
    if K.view == 2 then hit_mirror(K.num(v, 1), 1, 0.5); return end
    strike(8 + K.rnd() * 112, 6 + K.rnd() * 52, K.num(v, 1) * 0.4, 0.35)
  end
  function M.kick(v) shake = math.max(shake, K.num(v, 1)); shake_dir = -shake_dir end
  function M.hat(v, open)
    if #glints >= 12 then return end
    v = K.num(v, 1)
    if K.view == 2 then
      local T = TRI[1 + math.floor(K.rnd() * #TRI)]
      local k = 1 + math.floor(K.rnd() * 3)
      local P, Q = T.v[k], T.v[k % 3 + 1]
      glints[#glints + 1] = {x0 = P[1], y0 = P[2], x1 = Q[1], y1 = Q[2], t0 = K.T, v = v, life = open and 0.5 or 0.3}
      return
    end
    if #cracks == 0 then return end
    local C = cracks[#cracks - math.floor(K.rnd() * math.min(3, #cracks))]
    if C.heal then return end
    local R = C.rays[1 + math.floor(K.rnd() * #C.rays)]
    glints[#glints + 1] = {C = C, R = R, t0 = K.T, v = v, life = open and 0.5 or 0.3}
  end
  local function light(n, lv)
    for _ = 1, n do
      local i = 1 + math.floor(K.rnd() * NW)
      wlit[i] = {t = K.T, lv = lv}
    end
  end
  function M.perc(_, v) light(1, 5 + 5 * K.num(v, 1)) end
  function M.tom(v) light(2, 5 + 4 * K.num(v, 1)) end
  function M.tick() light(1, 4) end
  function M.brk(i, n, rev)
    if #cars >= 6 then return end
    local dir = rev and -1 or 1
    cars[#cars + 1] = {x = dir > 0 and -8 or 136, dir = dir, sp = 50 + 60 * K.num(i, 1) / math.max(1, K.num(n, 8)), lane = rev and 1 or 0}
  end
  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 10)
    if K.view == 2 then hit_mirror(0.8, n, 0.8); return end
    local x, y = 10 + K.rnd() * 40, 10 + K.rnd() * 40
    local dx, dy = (50 + K.rnd() * 40) / n, (K.rnd() - 0.5) * 6
    for k = 0, n - 1 do
      if #pending < 12 then pending[#pending + 1] = {t = K.T + k * 0.05, x = x + k * dx, y = y + k * dy} end
    end
  end
  function M.fill() shake = 1; light(4, 8) end
  function M.bar(S)
    local pl = math.max(1, math.floor(K.num(S and S.phrase_len, 16)))
    if math.floor(K.num(S and S.phrase_pos, 1)) % pl == 0 then
      -- the phrase edge: the pane heals, the mirror goes back together
      heal_t = K.T
      for _, C in ipairs(cracks) do if not C.heal then C.heal = K.T end end
      for _, T in ipairs(TRI) do T.tdx, T.tdy, T.tsh = 0, 0, 0 end
      layout = layout + 1
    end
  end

  ----------------------------------------------------------------------
  -- view 1
  ----------------------------------------------------------------------
  local function draw_pane(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    local kl = K.kickless
    local dim = 1 - kl * 0.35
    for i = #pending, 1, -1 do
      local P = pending[i]
      if K.T >= P.t then table.remove(pending, i); strike(P.x, P.y, 0.5, 0.4) end
    end

    -- the sky glow behind the far blocks
    local glow = (0.35 + e * 0.6 + lo * 0.9 + K.duck * 0.3) * dim
    -- (a stipple that thickens toward the horizon)
    for y = 14, 39, 2 do
      local u = (y - 14) / 25
      local d = u * u * glow
      if d > 0.08 then
        local gap = math.max(2, math.floor(7 - d * 5))
        local lv = 1 + d * 1.5
        local off = (y // 2) % 2
        local run
        for col = 0, 64 do
          local open = col < 64 and y < FAR[col]
          if open then run = run or col * 2
          elseif run then K.dashes(lv, y, 1, gap, off, run, col * 2); run = nil end
        end
      end
    end
    -- the highs: stars glittering above the glow
    for i = 0, 23 do
      local x, y = math.floor(K.hash(i, 51) * 126), 2 + math.floor(K.hash(i, 52) * 16)
      if y < FAR[x // 2] - 2 then
        put(hi * (1.5 + 3 * (0.5 + 0.5 * math.sin(T * (3 + K.hash(i, 53) * 5) + i))) * dim, x, y, 1, 1)
      end
    end
    -- far blocks: dim mass down to the near blocks
    for col = 0, 63 do
      local top = math.floor(FAR[col])
      local bot = math.min(math.floor(NEAR[col]), top + 9, 44)
      if bot > top then put(1, col * 2, top, 2, bot - top) end
      if bot + 3 < NEAR[col] and col % 2 == 0 then put(1, col * 2, bot + 1, 1, 1) end
    end
    -- far windows: a sparse twinkle
    for i = 0, 17 do
      local x = math.floor(K.hash(i, 41) * 63) * 2
      local top = FAR[x // 2]
      local y = math.floor(top + 2 + K.hash(i, 42) * 8)
      if y < NEAR[x // 2] - 1 then
        put((1 + 1.5 * math.sin(T * (0.3 + K.hash(i, 43)) + i) + e + hi * 2.5 * (0.5 + 0.5 * math.sin(T * 6 + i * 2))) * dim + 0.5, x, y, 1, 1)
      end
    end
    -- near blocks: black, their roofline edged, windows lit
    for col = 0, 63 do
      local top = NEAR[col]
      if top < GY then put(1.5 + lo * 0.8, col * 2, top, 2, 1) end
    end
    -- the mids: more of the city's windows on, and warmer
    local share = 0.1 + e * 0.35 + mid * 0.25
    for i = 1, NW do
      local W = WIN[i]
      local lv = 0
      if W.on < share then lv = (1.5 + mid * 1.5 + W.on * 6) * dim end
      if W.tv then lv = math.max(lv, 1.5 + 1.2 * math.sin(T * 7 + i) * math.sin(T * 2.3 + i * 3)) end
      local L = wlit[i]
      if L then
        local u = (K.T - L.t) / 0.8
        if u >= 1 then wlit[i] = nil else lv = math.max(lv, L.lv * (1 - u)) end
      end
      if c > 0.5 and K.hash(i, math.floor(T * 3)) < (c - 0.5) * 0.3 then lv = 5 - lv * 0.5 end
      if lv >= 0.5 then put(lv, W.x, W.y, 2, 2) end
    end
    -- the street: a kerb line, lamps, cars
    put(1.5, 0, GY, 128, 1)
    for x = 12, 127, 36 do
      put(1.5, x, GY - 8, 1, 8)
      put(3 + lo * 3 * dim, x - 1, GY - 9, 3, 1)
      put(0.6 + lo * 2.5, x - 3 - lo * 3, GY + 1, 7 + lo * 6, 1)
      put(lo * 1.6, x - 2 - lo * 2, GY + 2, 5 + lo * 4, 2)
    end
    local base = (T * (14 + e * 20)) % 160
    for k = 0, 1 + math.floor(e * 2) do
      local x = (base + k * 57) % 160 - 16
      put(2.5 * dim, x, GY + 3, 4, 1)
      put(1.5 * dim, x - 2, GY + 3, 2, 1)
      local x2 = 144 - (base * 0.8 + k * 71) % 160
      put(4 * dim, x2, GY + 6, 2, 1)
    end
    for i = #cars, 1, -1 do
      local C = cars[i]
      C.x = C.x + C.dir * C.sp * K.DTS
      if C.x < -12 or C.x > 140 then table.remove(cars, i)
      else
        local y = GY + 3 + C.lane * 3
        put(7, C.x, y, 2, 1)
        line(2.5, C.x - C.dir * 2, y, C.x - C.dir * 14, y)
      end
    end

    -- the pane: its shake, frame and glare
    shake = shake * math.exp(-DT / 0.12)
    local sx = shake_dir * math.floor(shake * shake * (1.6 + e * 0.8) + 0.5)
    local sy = math.floor(shake * shake * 0.8 + 0.3)
    put(2.5, sx, sy, 128, 1); put(2.5, sx, 63 + sy, 128, 1)
    put(2.5, sx, sy, 1, 64); put(2.5, 127 + sx, sy, 1, 64)
    put(1.2, sx + 1, sy + 1, 126, 1); put(1.2, sx + 1, sy + 1, 1, 62)
    for k = 0, 1 do
      local gx = (T * (5 + k * 3) + k * 90) % 230 - 60
      -- the glare: a soft sheen in the upper glass, short broken strokes
      for q = 0, 3 do
        local y0 = 3 + q * 5
        line(0.4 + hi * 3, gx + q * 3 + sx, y0 + 4 + sy, gx + q * 3 + 3 + sx, y0 + sy)
      end
      if c > 0.4 then line(1, gx + 30 + sx, 14 + sy, gx + 36 + sx, 4 + sy) end
    end

    -- the cracks
    for ci = #cracks, 1, -1 do
      local C = cracks[ci]
      local age = K.T - C.t0
      local gone = 0
      if C.heal then gone = clamp((K.T - C.heal) / 0.6, 0, 1) end
      if gone >= 1 then table.remove(cracks, ci)
      else
        local grow = clamp(age / 0.3, 0, 1)
        local settle = math.exp(-age / 0.35)
        local lv = (1.2 + C.v * 0.8 + hi * 0.8 + mid * 2 * clamp((age - 0.3) / 0.5, 0, 1) + settle * (2.5 + 3 * C.v)) * (1 - gone)
        local ext = grow * (1 - gone)
        local ox, oy = C.x + sx, C.y + sy
        for i = 1, #C.rays do
          local R = C.rays[i]
          local L = R.L * ext
          local ca, sa = math.cos(R.a), math.sin(R.a)
          line(lv, ox, oy, ox + ca * L, oy + sa * L)
          if R.br and ext > R.br[1] then
            local bx, by = ox + ca * R.L * R.br[1], oy + sa * R.L * R.br[1]
            local bl = R.br[3] * clamp((ext - R.br[1]) / 0.3, 0, 1)
            line(lv * 0.7, bx, by, bx + math.cos(R.br[2]) * bl, by + math.sin(R.br[2]) * bl)
          end
        end
        if grow >= 1 then
          for k = 1, #C.rs do
            for i = 1, #C.rays do
              local x1, y1, o1 = ray_pt(C, i, k)
              local x2, y2, o2 = ray_pt(C, i + 1, k)
              if o1 and o2 then
                local hole = C.gone[i] == k or C.gone[i] == k - 1
                line((hole and lv * 1.1 or lv * 0.7) * (1 - gone), x1 + sx, y1 + sy, x2 + sx, y2 + sy)
              end
            end
          end
        end
        -- the highs: light crawling out along each fracture
        if hi > 0.05 and grow >= 1 then
          for i = 1, #C.rays do
            local R = C.rays[i]
            local u = (T * (0.9 + (i % 3) * 0.3) + i * 0.37) % 1
            local r = R.L * u * (1 - gone)
            put(hi * 6 * math.sin(math.pi * u), ox + math.cos(R.a) * r - 1, oy + math.sin(R.a) * r, 2, 1)
          end
        end
        if age < 0.4 then put(4 + 6 * settle, ox - 1, oy - 1, 2, 2)
        else put(lv, ox, oy, 1, 1) end
      end
    end
    -- falling shards
    for i = #shards, 1, -1 do
      local P = shards[i]
      local t = K.T - P.t0
      if t >= 0 then
        local cy = P.cy + 0.5 * 90 * t * t
        if cy > 80 then table.remove(shards, i)
        else
          local cx = P.cx + P.vx * t
          local a = P.w * t
          local ca, sa = math.cos(a), math.sin(a)
          local q = P.p
          local lv = 6 * math.max(0.3, 1 - t)
          local px, py
          for k = 0, 4 do
            local j = (k % 4) * 2 + 1
            local x = cx + q[j] * ca - q[j + 1] * sa
            local y = cy + q[j] * sa + q[j + 1] * ca
            if px then line(lv, px, py, x, y) end
            px, py = x, y
          end
        end
      end
    end
    -- glints running out along the fractures
    for i = #glints, 1, -1 do
      local G = glints[i]
      local u = (K.T - G.t0) / G.life
      if u >= 1 or not G.C then table.remove(glints, i)
      else
        local r = G.R.L * u
        local x = G.C.x + math.cos(G.R.a) * r + sx
        local y = G.C.y + math.sin(G.R.a) * r + sy
        put((5 + 7 * G.v) * math.sin(math.pi * u), x, y, 1, 1)
      end
    end
    -- kickless: drips running down the glass
    if kl > 0.05 then
      local nd = math.floor(kl * 7)
      for k = 1, nd do
        local x = math.floor(K.hash(k, 61) * 120) + 4
        local y = (T * (3 + K.hash(k, 62) * 5) + K.hash(k, 63) * 64) % 72 - 6
        line(1.5 + kl, x + sx, y - 5, x + sx, y)
        put(2 + kl * 2, x + sx, y + 1, 1, 1)
      end
      K.haze(0, 30, 128, GY, kl * 0.35, 1, T * 3)
    end
  end

  ----------------------------------------------------------------------
  -- view 2: the mirror
  ----------------------------------------------------------------------
  local MOX, MOY = 88, 16
  local TOWERS = {{8, 30, 9}, {20, 25, 6}, {29, 33, 10}, {44, 27, 7}, {54, 34, 12}, {70, 29, 8}, {82, 33, 6},
    {93, 26, 9}, {106, 31, 7}, {116, 28, 12}}
  local HZ = 40
  local tlv = 1                        -- the towers' level (the mids)

  -- the scene's lit runs on row y: calls emit(x0, x1, lv)
  local function scene_row(y, emit, mr, mlv, gl, hi)
    if y < 0 or y > 63 then return end
    local dy = y - MOY
    if dy * dy <= mr * mr then
      local hw = math.sqrt(mr * mr - dy * dy)
      emit(MOX - hw, MOX + hw, mlv)
    elseif y < HZ - 2 and K.hash(y, 77) < 0.35 then
      local sx = math.floor(K.hash(y, 78) * 128)
      emit(sx, sx + 1, 2 + hi * 3)
    end
    if y >= 25 and y < HZ then
      for i = 1, #TOWERS do
        local t = TOWERS[i]
        if y >= t[2] then emit(t[1], t[1] + t[3], (y == t[2]) and 1.5 + tlv or tlv) end
      end
    elseif y == HZ then
      emit(0, 128, 2.2)
    elseif y > HZ then
            local w = 3 + (y - HZ) * 0.6
      local wob = math.sin(y * 0.35 + K.T * 2) * 1.5
      emit(MOX - w + wob, MOX + w + wob, gl * 0.7)
    end
  end

  local function draw_mirror(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid = A[K.LO], A[K.HI], A[K.MID]
    -- the highs glitter between the kicks (the hats' place)
    local hiq = hi * (1 - K.env.kick) ^ 3
    local kl = K.kickless
    if layout ~= built then build(layout); built = layout end
    -- the lows swell and light the moon; the mids light
    -- the towers; the highs glitter on the water and the edges
    moonlo = lo
    local mr = 4.5 + e * 2 + moonlo * 1.6
    local mlv = 2.5 + e * 1.2 + moonlo * 2.6
    local gl = 1.6 + hiq * 2.5 + e * 1
    local kb = K.env.kick * (0.4 + 0.3 * e)
    tlv = 0.85 + mid * 0.9
    -- shards ease toward their targets; kickless pulls them home
    for _, Tr in ipairs(TRI) do
      if kl > 0.3 then
        local f = 1 - math.exp(-DT / 3)
        Tr.tdx, Tr.tdy, Tr.tsh = Tr.tdx * (1 - f), Tr.tdy * (1 - f), Tr.tsh * (1 - f)
      end
      -- eased, but never more than a couple of pixels a frame
      local k = 1 - math.exp(-DT / 0.12)
      local lim = 30 * DT
      Tr.dx = Tr.dx + clamp((Tr.tdx - Tr.dx) * k, -lim, lim)
      Tr.dy = Tr.dy + clamp((Tr.tdy - Tr.dy) * k, -lim * 0.6, lim * 0.6)
      Tr.sh = Tr.sh + clamp((Tr.tsh - Tr.sh) * k, -lim * 0.02, lim * 0.02)
    end
    -- each shard: scanline its rows, sample the scene at its offset
    for n = 1, #TRI do
      local Tr = TRI[n]
      local V = Tr.v
      local ymin = math.floor(math.min(V[1][2], V[2][2], V[3][2]))
      local ymax = math.ceil(math.max(V[1][2], V[2][2], V[3][2]))
      local bx = (Tr.cx - 64) * 0.035 * kb
      local by = (Tr.cy - 32) * 0.035 * kb
      local drift = c * 1.5 * math.sin(T * 0.7 + n)
      for y = math.max(0, ymin), math.min(63, ymax - 1) do
        local yc = y + 0.5
        local xl, xr = 999, -999
        for k = 1, 3 do
          local P, Q = V[k], V[k % 3 + 1]
          if (P[2] <= yc and Q[2] > yc) or (Q[2] <= yc and P[2] > yc) then
            local x = P[1] + (yc - P[2]) / (Q[2] - P[2]) * (Q[1] - P[1])
            if x < xl then xl = x end
            if x > xr then xr = x end
          end
        end
        if xr > xl then
          xl, xr = math.floor(xl + 0.5), math.floor(xr + 0.5)
          local ox = Tr.dx + bx + drift + Tr.sh * (y - Tr.cy)
          local sy = math.floor(y - Tr.dy - by + 0.5)
          scene_row(sy, function(a, b, lv)
            if Tr.flip then a, b = 2 * Tr.cx - b, 2 * Tr.cx - a end
            a, b = math.floor(a + ox + 0.5), math.floor(b + ox + 0.5)
            if a < xl then a = xl end
            if b > xr then b = xr end
            if b > a then put(lv, a, y, b - a, 1) end
          end, mr, mlv, gl, hiq)
        end
      end
    end
    -- the cracks between the shards, lit where a shard was just knocked
    local base = 1 + e * 0.15 + hiq * 0.8
    for i = 1, 6 do
      for j = 1, 4 do
        if i < 6 and (j > 1 and j < 4) then line(base, VX[i][j], VY[i][j], VX[i + 1][j], VY[i + 1][j]) end
        if j < 4 and (i > 1 and i < 6) then line(base, VX[i][j], VY[i][j], VX[i][j + 1], VY[i][j + 1]) end
      end
    end
    for n = 1, #TRI do
      local Tr = TRI[n]
      local fl = math.max(0, 1 - (K.T - Tr.hit) / 0.3)
      local V = Tr.v
      if n % 2 == 1 then
        -- the diagonal this triangle shares with the next
        local P, Q
        if V[1] == TRI[n + 1].v[1] then P, Q = V[1], V[3] else P, Q = V[2], V[3] end
        line(base, P[1], P[2], Q[1], Q[2])
      end
      if fl > 0 then
        for k = 1, 3 do
          local P, Q = V[k], V[k % 3 + 1]
          line(base + fl * fl * 4, P[1], P[2], Q[1], Q[2])
        end
      end
    end
    -- chaos: hairline splinters inside the shards
    if c > 0.3 then
      for n = 1, math.floor(c * 10) do
        local Tr = TRI[1 + (n * 7) % #TRI]
        local a = K.hash(n, layout) * K.TAU
        line(1.5 + c, Tr.cx, Tr.cy, Tr.cx + math.cos(a) * 7, Tr.cy + math.sin(a) * 5)
      end
    end
    -- the frame
    -- (beaded top and bottom: a gilt frame's moulding)
    K.dashes(1, 0, 2, 4, 0); K.dashes(1, 63, 2, 4, 0); put(1, 0, 0, 1, 64); put(1, 127, 0, 1, 64)
    -- glints along the edges
    for i = #glints, 1, -1 do
      local G = glints[i]
      local u = (K.T - G.t0) / G.life
      if u >= 1 or G.C then table.remove(glints, i)
      else
        local x, y = G.x0 + (G.x1 - G.x0) * u, G.y0 + (G.y1 - G.y0) * u
        local lv = (5 + 7 * G.v) * math.sin(math.pi * u)
        put(lv, x, y, 1, 1)
        if lv > 5 then put(lv * 0.4, x - 1, y, 3, 1) end
      end
    end
  end

  function M.draw(S)
    if K.view == 2 then draw_mirror(S) else draw_pane(S) end
  end

  M.init()
  return M
end
