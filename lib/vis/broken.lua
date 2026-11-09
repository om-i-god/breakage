-- broken. view 1: a pane of glass in front of a night city that the snares crack with clean radial fractures, shards falling away, healing on phrase edges.
-- view 2: a shattered mirror whose shards each show an offset copy of the moonlit city across the water, shifting and shearing on the hits.
-- view 3: from behind a cracked windscreen at a rainy night intersection: wipers, the car ahead, the signal over the junction.
--
-- view 1: behind the glass, a moon in drifting cloud over a sodium glow,
-- far blocks in dim mass with a beacon blinking slowly on the tallest, an
-- elevated line in front of them where a train runs through on some bars,
-- near blocks black with lit windows and a neon sign, cars streaking along
-- the wet street under the lamps. the pane has a frame and a slow sliding
-- glare. every snare strikes it: straight fractures race out from the
-- impact to the frame, joined by rings of web, bright as they run and
-- settling to a pale scar; a cell or two of the web breaks loose and falls
-- away. a clap chips a smaller star, a rim a tiny one; the kick shakes the
-- frame, rings the scars brighter and lifts the glow; a
-- closed hat runs a glint out along a fracture, an open hat flares the
-- glare across the glass; percussion lights windows, a tom a column of
-- them floor by floor, ticks flicker the neon, break slices send cars by;
-- a ratchet stitches a row of small stars, a fill flashes the scars. the
-- phrase switches the city on window by window and heals the pane at its
-- edge. energy lights the city, runs more trains and lengthens the
-- fractures, chaos splinters them with branches, doubles each strike and
-- glitches the windows; kickless, the city dims into haze and drips run
-- down the glass.
-- view 2: the mirror broken into triangles. each shard shows the same scene
-- (clouds, the moon rising through the phrase, the towers and their
-- windows, the water with their reflections and the moon's glade) from its
-- own place. a snare knocks a handful of shards to new offsets, a clap
-- shears a whole column, a rim flips a single shard; the kick breathes
-- them all outward and swells the moon, closed hats glint along an edge,
-- open hats trace a whole shard; percussion lights a tower's windows, a
-- tom rings the water, a ratchet knocks a chain of shards one after
-- another, a fill shivers them all. chaos throws them further, flips some
-- and splinters them; a phrase edge (and a kickless stretch, slowly, under
-- mist) pulls the mirror back toward whole.
-- view 3: the road runs away to the junction under a signal on its wire,
-- shops either side, a neon sign, the car ahead waiting with its tail
-- lights, oncoming headlights growing out of the rain, our own lights
-- pooling on the wet road. the wipers sweep once a bar (intermittent when
-- the energy is low, steady when it is up) and clear the drops they pass.
-- a snare is a stone: a star chip in the windscreen, laminated, so it
-- stays; a clap runs a long crack out from the newest chip, a rim nicks
-- it; the kick flares the brake lights ahead and bobs the dashboard; a
-- closed hat lands a drop that splats, an open hat a drop that runs; perc
-- flickers the shop sign, a tom splashes a puddle, break slices and the
-- bars of a red light send cross traffic over the junction; a ratchet is
-- a burst of hail, a fill the hazards. the signal changes through the
-- phrase. energy brings the rain and the traffic, chaos branches the
-- cracks and jitters the wipers; kickless, the car ahead pulls away into
-- the fog and the rain softens.
--
-- the ears: view 1, the lows raise the sodium glow and pool the street
-- lamps on the wet road, the mids switch on the windows and the neon and
-- ring through the cracks, the highs glitter the stars, the glare and the
-- light along the fractures, the level lights the clouds and the moon;
-- view 2, the lows swell and light the moon, the mids light the towers'
-- windows, the highs glitter on the water and the shard edges, the level
-- lifts the horizon and the clouds; view 3, the lows light our headlight
-- pool and the brake lights, the mids the signal, the shops and the neon,
-- the highs the rain, the level the fog and the dashboard.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, exp = math.sin, math.cos, math.floor, math.max, math.min, math.abs, math.exp
  local PI, TAU = math.pi, K.TAU

  local function phrase(S)
    local pl = max(1, floor(K.num(S and S.phrase_len, 16) or 16))
    local pp = K.num(S and S.phrase_pos, 0) or 0
    return clamp((pp % pl) / pl, 0, 1)
  end

  ----------------------------------------------------------------------
  -- the city (view 1), fixed by hash
  ----------------------------------------------------------------------
  local FAR, NEAR = {}, {}
  local GY = 54                          -- street level
  local TY = 29                          -- the elevated line
  do
    local x, i = 0, 0
    while x < 130 do
      local w = 6 + floor(K.hash(i, 11) * 10)
      local top = 22 + floor(K.hash(i, 12) * 12)
      for xx = x, x + w - 1 do FAR[xx // 2] = top end
      x, i = x + w, i + 1
    end
    x, i = 0, 0
    while x < 130 do
      local w = 10 + floor(K.hash(i, 21) * 14)
      local gap = K.hash(i, 22) < 0.3 and 4 or 0
      local top = 33 + floor(K.hash(i, 23) * 13)
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
  -- the tallest far block carries the beacon
  local BEACON = 0
  for c = 1, 62 do if FAR[c] < FAR[BEACON] then BEACON = c end end
  -- the near windows: 2x2 cells on a 4px grid inside the near blocks
  local WIN = {}
  for x = 2, 124, 4 do
    local top = NEAR[x // 2]
    if NEAR[(x + 1) // 2] == top then
      for y = top + 3, GY - 4, 4 do
        local i = #WIN + 1
        WIN[i] = {x = x, y = y, on = K.hash(i, 31), tv = K.hash(i, 32) < 0.08}
      end
    end
  end
  local NW = #WIN
  -- the neon sign hangs off a near block
  local SGX = 71
  local SGY = math.min(NEAR[SGX // 2] + 2, GY - 15)

  local cracks, shards, glints, cars, drips, pending, trains
  local shake, wlit, heal_t, glare_f, flash, neon_f
  local shake_dir = 1
  local MAXC = 3

  local function edge_dist(x, y, a)
    local ca, sa = cos(a), sin(a)
    local t = 999
    if ca > 0.001 then t = min(t, (126 - x) / ca) elseif ca < -0.001 then t = min(t, (1 - x) / ca) end
    if sa > 0.001 then t = min(t, (62 - y) / sa) elseif sa < -0.001 then t = min(t, (1 - y) / sa) end
    return max(2, t)
  end

  -- a strike: n rays to (toward) the frame, rings of web across them
  local function make(x, y, v, size)
    local c, e = K.chaos, K.energy
    local n = floor(5 + v * 2 + c * 3)
    if size < 0.5 then n = 4 + floor(K.rnd() * 2) end
    local rays = {}
    local a0 = K.rnd() * TAU
    local reach = (14 + v * 24 + e * 14) * size
    for i = 1, n do
      local a = a0 + (i - 1) / n * TAU + (K.rnd() - 0.5) * (0.5 / n * TAU)
      local L = min(edge_dist(x, y, a), reach * (0.6 + 0.5 * K.rnd()))
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
    local r = min(C.rs[k] * R.j[k], R.L)
    return C.x + cos(R.a) * r, C.y + sin(R.a) * r, C.rs[k] * R.j[k] <= R.L
  end

  local function drop_shard(C)
    if #C.rs < 3 or #shards >= 10 then return end
    local i = 1 + floor(K.rnd() * #C.rays)
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

  -- strike list L; the oldest live crack heals when it is full
  local function strike(L, x, y, v, size, maxc, drops)
    local live = 0
    for _, C in ipairs(L) do if not C.heal then live = live + 1 end end
    if live >= maxc then
      for _, C in ipairs(L) do if not C.heal then C.heal = K.T; break end end
    end
    -- full of fading scars: this one only rings through the glass
    if #L >= maxc + 2 then flash = max(flash, 0.5 * v); return nil end
    local C = make(x, y, v, size)
    L[#L + 1] = C
    if drops and size >= 0.5 then
      local nd = 1 + floor(K.energy * 1.5 + K.chaos * 2)
      for _ = 1, nd do drop_shard(C) end
    end
    return C
  end

  -- the fractures of list L, shifted by (sx, sy); lv0 scales them
  local function draw_cracks(L, sx, sy, hi, mid, lv0)
    local T = K.T
    for ci = #L, 1, -1 do
      local C = L[ci]
      local age = T - C.t0
      local gone = 0
      if C.heal then gone = clamp((T - C.heal) / 0.6, 0, 1) end
      if gone >= 1 then table.remove(L, ci)
      else
        local grow = clamp(age / 0.3, 0, 1)
        local settle = exp(-age / 0.35)
        local lv = (1 + C.v * 0.6 + hi * 0.6 + mid * 1.5 * clamp((age - 0.3) / 0.5, 0, 1)
          + settle * (2.5 + 3 * C.v) + flash * 3) * (1 - gone) * lv0
        local ext = grow * (1 - gone)
        local ox, oy = C.x + sx, C.y + sy
        for i = 1, #C.rays do
          local R = C.rays[i]
          local Ln = R.L * ext
          local ca, sa = cos(R.a), sin(R.a)
          line(lv, ox, oy, ox + ca * Ln, oy + sa * Ln)
          if R.br and ext > R.br[1] then
            local bx, by = ox + ca * R.L * R.br[1], oy + sa * R.L * R.br[1]
            local bl = R.br[3] * clamp((ext - R.br[1]) / 0.3, 0, 1)
            line(lv * 0.7, bx, by, bx + cos(R.br[2]) * bl, by + sin(R.br[2]) * bl)
          end
        end
        if grow >= 1 then
          for k = 1, #C.rs do
            for i = 1, #C.rays do
              local x1, y1, o1 = ray_pt(C, i, k)
              local x2, y2, o2 = ray_pt(C, i + 1, k)
              if o1 and o2 then
                local hole = C.gone[i] == k or C.gone[i] == k - 1
                line(hole and lv * 1.1 or lv * 0.7, x1 + sx, y1 + sy, x2 + sx, y2 + sy)
              end
            end
          end
          -- the highs: light crawling out along each fracture
          if hi > 0.05 then
            for i = 1, #C.rays do
              local R = C.rays[i]
              local u = (T * (0.9 + (i % 3) * 0.3) + i * 0.37) % 1
              local r = R.L * u * (1 - gone)
              put(hi * 6 * sin(PI * u) * lv0, ox + cos(R.a) * r - 1, oy + sin(R.a) * r, 2, 1)
            end
          end
        end
        if age < 0.4 then put((4 + 6 * settle) * lv0, ox - 1, oy - 1, 2, 2)
        else put(lv, ox, oy, 1, 1) end
      end
    end
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
          o.col = i
          o.cx = (t[1][1] + t[2][1] + t[3][1]) / 3
          o.cy = (t[1][2] + t[2][2] + t[3][2]) / 3
          o.flip = K.hash(n, seed + 5) < 0.2
          TRI[n] = o
        end
      end
    end
  end

  local MOX = 88
  local TOWERS = {{8, 30, 9}, {20, 25, 6}, {29, 33, 10}, {44, 27, 7}, {54, 34, 12}, {70, 29, 8}, {82, 33, 6},
    {93, 26, 9}, {106, 31, 7}, {116, 28, 12}}
  local HZ = 40
  local moon_y, tlit, ripples, knocks, shiver = 20, {}, {}, {}, 0

  ----------------------------------------------------------------------
  -- the windscreen (view 3)
  ----------------------------------------------------------------------
  local VPX, VPY = 64, 25               -- the road's vanishing point
  local DY = 52                         -- the dashboard's top edge
  local PIV = {{34, 61, 50}, {92, 61, 44}}   -- wiper pivots and lengths
  local chips, runners, raindrops, oncoming, crossers, splashes, hail
  local wip_a, brake, hazard, sign_f, sig, car_d, dash_bob
  local onc_acc = 0
  local function road_hw(y) return 3 + (y - VPY) * 91 / 39 end

  ----------------------------------------------------------------------
  function M.init()
    cracks, shards, glints, cars, drips, pending, trains = {}, {}, {}, {}, {}, {}, {}
    shake, heal_t, glare_f, flash, neon_f = 0, -9, 0, 0, 0
    wlit = {}
    TRI = {}
    layout = 3
    build(layout)
    built = layout
    moon_y, tlit, ripples, knocks, shiver = 20, {}, {}, {}, 0
    for i = 1, #TOWERS do tlit[i] = 0 end
    chips, runners, raindrops, oncoming, crossers, splashes, hail = {}, {}, {}, {}, {}, {}, {}
    wip_a = {PI, PI}
    brake, hazard, sign_f, sig, car_d, dash_bob = 0, 0, 0, 1, 0, 0
    onc_acc = 0
    -- an old scar already in the glass, an old chip in the windscreen
    local C = make(100, 14, 0.4, 0.6)
    C.t0 = -100
    cracks[1] = C
    C = make(98, 18, 0.5, 0.45)
    C.t0 = -100
    chips[1] = C
  end
  M.clear = M.init

  -- view 2's knocks
  local function knock(Tr, v, amt)
    local c = K.chaos
    local r = (3 + 9 * v + 14 * c) * amt
    Tr.tdx, Tr.tdy = (K.rnd() - 0.5) * 2 * r, (K.rnd() - 0.5) * r
    Tr.tsh = (K.rnd() - 0.5) * (0.4 + c * 0.8) * amt
    Tr.hit = K.T
  end
  local function hit_mirror(v, count, amt)
    for _ = 1, count do knock(TRI[1 + floor(K.rnd() * #TRI)], v, amt) end
  end

  -- view 3's stones and drops
  local function chip(v, size)
    local x, y = 14 + K.rnd() * 100, 6 + K.rnd() * 38
    return strike(chips, x, y, v, size, 3, false)
  end
  local function drop(x, y, run, v)
    if #raindrops >= 44 then table.remove(raindrops, 1) end
    raindrops[#raindrops + 1] = {x = x, y = y, t0 = K.T, run = run, v = v or 0.5,
      vy = run and (6 + K.rnd() * 10) or 0, big = K.rnd() < 0.3}
  end

  function M.snare(v)
    v = K.num(v, 1) or 1
    if K.view == 2 then hit_mirror(v, 4 + floor(K.chaos * 5), 1); return end
    if K.view == 3 then
      chip(v, 0.42)
      if K.chaos > 0.6 then chip(v * 0.5, 0.3) end
      return
    end
    local x, y = 16 + K.rnd() * 96, 8 + K.rnd() * 44
    strike(cracks, x, y, v, 1, MAXC, true)
    if K.chaos > 0.5 then strike(cracks, x + (K.rnd() - 0.5) * 30, y + (K.rnd() - 0.5) * 16, v * 0.6, 0.6, MAXC, true) end
  end
  function M.clap(v)
    v = K.num(v, 1) or 1
    if K.view == 2 then
      -- a whole column shears
      local col = 1 + floor(K.rnd() * 5)
      local sh = (K.rnd() - 0.5) * (0.5 + K.chaos)
      for _, Tr in ipairs(TRI) do
        if Tr.col == col then Tr.tsh = sh; Tr.tdy = Tr.tdy + (K.rnd() - 0.5) * 4 * v; Tr.hit = K.T end
      end
      return
    end
    if K.view == 3 then
      -- a long crack runs out from the newest chip
      local C = chips[#chips]
      if not C then return end
      if #runners >= 4 then table.remove(runners, 1) end
      local a = K.rnd() * TAU
      runners[#runners + 1] = {x = C.x, y = C.y, a = a, L = min(edge_dist(C.x, C.y, a), 30 + 50 * v),
        t0 = K.T, seed = floor(K.rnd() * 999), bend = (K.rnd() - 0.5) * 0.6}
      return
    end
    strike(cracks, 10 + K.rnd() * 108, 6 + K.rnd() * 50, v * 0.6, 0.6, MAXC, true)
  end
  function M.rim(v)
    v = K.num(v, 1) or 1
    if K.view == 2 then
      local Tr = TRI[1 + floor(K.rnd() * #TRI)]
      Tr.flip = not Tr.flip
      Tr.hit = K.T
      return
    end
    if K.view == 3 then chip(v * 0.4, 0.3); return end
    strike(cracks, 8 + K.rnd() * 112, 6 + K.rnd() * 52, v * 0.4, 0.35, MAXC, true)
  end
  function M.kick(v)
    v = K.num(v, 1) or 1
    shake = max(shake, v); shake_dir = -shake_dir
    brake = max(brake, v)
    dash_bob = max(dash_bob, v)
  end
  function M.hat(v, open)
    v = K.num(v, 1) or 1
    if K.view == 3 then
      drop(8 + K.rnd() * 112, 3 + K.rnd() * 44, open, v)
      if not open then
        local D = raindrops[#raindrops]
        D.splat = true
      end
      return
    end
    if open then glare_f = max(glare_f, v) end
    if #glints >= 12 then return end
    if K.view == 2 then
      local Tr = TRI[1 + floor(K.rnd() * #TRI)]
      if open then
        glints[#glints + 1] = {tri = Tr, t0 = K.T, v = v, life = 0.6}
      else
        local k = 1 + floor(K.rnd() * 3)
        local P, Q = Tr.v[k], Tr.v[k % 3 + 1]
        glints[#glints + 1] = {x0 = P[1], y0 = P[2], x1 = Q[1], y1 = Q[2], t0 = K.T, v = v, life = 0.3}
      end
      return
    end
    if #cracks == 0 then return end
    local C = cracks[#cracks - floor(K.rnd() * min(3, #cracks))]
    if C.heal then return end
    local R = C.rays[1 + floor(K.rnd() * #C.rays)]
    glints[#glints + 1] = {C = C, R = R, t0 = K.T, v = v, life = open and 0.5 or 0.3}
  end
  local function light(n, lv)
    for _ = 1, n do
      local i = 1 + floor(K.rnd() * NW)
      wlit[i] = {t = K.T, lv = lv}
    end
  end
  -- a column of windows, lit floor by floor upward
  local function climb(lv)
    local i = 1 + floor(K.rnd() * NW)
    local x = WIN[i].x
    local n = 0
    for j = NW, 1, -1 do
      if WIN[j].x == x then
        wlit[j] = {t = K.T + n * 0.06, lv = lv}
        n = n + 1
      end
    end
  end
  function M.perc(_, v)
    v = K.num(v, 1) or 1
    neon_f = max(neon_f, 0.6)
    sign_f = max(sign_f, v)
    tlit[1 + floor(K.rnd() * #TOWERS)] = 1
    light(1, 5 + 5 * v)
  end
  function M.tom(v)
    v = K.num(v, 1) or 1
    climb(5 + 4 * v)
    if #ripples < 4 then ripples[#ripples + 1] = {x = 10 + K.rnd() * 108, y = HZ + 4 + K.rnd() * 18, t0 = K.T} end
    if #splashes < 4 then
      local y = 36 + K.rnd() * 14
      local hw = road_hw(y)
      splashes[#splashes + 1] = {x = VPX + (K.rnd() - 0.5) * hw * 1.6, y = y, t0 = K.T, v = v}
    end
  end
  function M.tick()
    neon_f = max(neon_f, 1)
    sign_f = max(sign_f, 0.6)
  end
  local function crosser(dir, sp)
    if #crossers >= 4 then return end
    crossers[#crossers + 1] = {x = dir > 0 and -14 or 142, dir = dir, sp = sp}
  end
  function M.brk(i, n, rev)
    local dir = rev and -1 or 1
    local sp = 50 + 60 * (K.num(i, 1) or 1) / max(1, K.num(n, 8) or 8)
    if K.view == 3 then crosser(dir, sp * 0.8); return end
    if #cars >= 6 then return end
    cars[#cars + 1] = {x = dir > 0 and -8 or 136, dir = dir, sp = sp, lane = rev and 1 or 0}
  end
  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2) or 2), 1, 10)
    if K.view == 2 then
      -- a chain of shards knocked one after another
      local i = 1 + floor(K.rnd() * #TRI)
      for k = 0, n - 1 do
        if #knocks < 12 then knocks[#knocks + 1] = {t = K.T + k * 0.05, i = (i + k * 2 - 1) % #TRI + 1} end
      end
      return
    end
    if K.view == 3 then
      local x, y = 14 + K.rnd() * 40, 6 + K.rnd() * 30
      local dx, dy = (40 + K.rnd() * 40) / n, (K.rnd() - 0.5) * 4
      for k = 0, n - 1 do
        if #hail < 8 then hail[#hail + 1] = {t = K.T + k * 0.05, x = x + k * dx, y = y + k * dy} end
      end
      return
    end
    local x, y = 10 + K.rnd() * 40, 10 + K.rnd() * 40
    local dx, dy = (50 + K.rnd() * 40) / n, (K.rnd() - 0.5) * 6
    for k = 0, n - 1 do
      if #pending < 12 then pending[#pending + 1] = {t = K.T + k * 0.05, x = x + k * dx, y = y + k * dy} end
    end
  end
  function M.fill()
    shake = 1; light(4, 8)
    flash = 1
    shiver = 1
    hazard = 1
  end
  function M.bar(S)
    local pl = max(1, floor(K.num(S and S.phrase_len, 16) or 16))
    local pp = floor(K.num(S and S.phrase_pos, 1) or 1)
    -- a train along the elevated line on some bars
    if #trains == 0 and K.rnd() < 0.3 + K.energy * 0.5 then
      local dir = K.rnd() < 0.5 and 1 or -1
      local nc = 3 + floor(K.energy * 3)
      trains[1] = {x = dir > 0 and -nc * 11 or 128, dir = dir, sp = 35 + K.energy * 35, n = nc}
    end
    -- cross traffic runs while our light is red
    if sig == 3 then crosser(K.rnd() < 0.5 and 1 or -1, 60 + K.rnd() * 40) end
    if pp % pl == 0 then
      -- the phrase edge: the pane heals, the mirror goes back together
      heal_t = K.T
      for _, C in ipairs(cracks) do if not C.heal then C.heal = K.T end end
      for _, Tr in ipairs(TRI) do Tr.tdx, Tr.tdy, Tr.tsh = 0, 0, 0 end
      layout = layout + 1
      -- the windscreen keeps its chips, but the runners' oldest fades
      if #chips > 2 then chips[1].heal = chips[1].heal or K.T end
    end
  end

  ----------------------------------------------------------------------
  -- view 1
  ----------------------------------------------------------------------
  local function draw_pane(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    local dim = 1 - kl * 0.35
    local ph = phrase(S)
    for i = #pending, 1, -1 do
      local P = pending[i]
      if T >= P.t then table.remove(pending, i); strike(cracks, P.x, P.y, 0.5, 0.4, MAXC, true) end
    end

    -- the moon behind drifting cloud
    local mx, my = 24, 9
    K.disc((2 + amp * 2 + e) * dim, mx, my, 3.2)
    K.ring((1 + amp * 1.5) * dim, mx, my, 6 + lo * 1.5, 14)
    for k = 0, 2 do
      local cx = (k * 61 + T * (2 + k)) % 190 - 30
      local cy = 5 + k * 4
      local hw = 13 + k * 3
      put((1 + amp * 1.2) * dim, cx - hw, cy, hw * 2, 1)
    end

    -- the sky glow behind the far blocks: lows, the kick and the phrase
    local glow = (0.35 + e * 0.6 + lo * 0.9 + K.duck * 0.3 + ph * 0.3) * dim
    for y = 14, 39, 2 do
      local u = (y - 14) / 25
      local d = u * u * glow
      if d > 0.08 then
        local gap = max(4, floor(9 - d * 5))
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
      local x, y = floor(K.hash(i, 51) * 126), 2 + floor(K.hash(i, 52) * 16)
      if y < FAR[x // 2] - 2 then
        local tw = 0.5 + 0.5 * sin(T * (1.5 + K.hash(i, 53) * 3) + i)
        put((0.4 + tw * 0.4 + hi * (1.5 + 3 * tw)) * dim, x, y, 1, 1)
      end
    end
    -- far blocks: dim mass down to the near blocks
    for col = 0, 63 do
      local top = floor(FAR[col])
      local bot = min(floor(NEAR[col]), top + 4, TY)
      if bot > top then put(1, col * 2, top, 2, bot - top) end
    end
    -- the beacon: a slow red blink, read as a soft swell
    do
      local b = max(0, sin(T * 2.1))
      put(1.5 + 6 * b * b * b, BEACON * 2, FAR[BEACON] - 2, 1, 2)
    end
    -- far windows: a sparse twinkle
    for i = 0, 17 do
      local x = floor(K.hash(i, 41) * 63) * 2
      local top = FAR[x // 2]
      local y = floor(top + 2 + K.hash(i, 42) * 8)
      if y < NEAR[x // 2] - 1 and y ~= TY then
        put((1 + 1.5 * sin(T * (0.3 + K.hash(i, 43)) + i) + e + hi * 2.5 * (0.5 + 0.5 * sin(T * 6 + i * 2))) * dim + 0.5, x, y, 1, 1)
      end
    end
    -- the elevated line: its deck and pillars down to the near roofs
    put(1.5 + amp, 0, TY, 128, 1)
    for x = 6, 127, 18 do
      local bot = NEAR[x // 2]
      if bot > TY + 1 then put(1.2, x, TY + 1, 1, bot - TY - 1) end
    end
    for i = #trains, 1, -1 do
      local R = trains[i]
      R.x = R.x + R.dir * R.sp * K.DTS
      if (R.dir > 0 and R.x > 130) or (R.dir < 0 and R.x < -R.n * 11 - 2) then table.remove(trains, i)
      else
        for k = 0, R.n - 1 do
          local x = R.x + k * 11
          put(1.5 * dim, x, TY - 5, 10, 1)
          for w = 0, 3 do
            local fl = K.hash(k * 4 + w, floor(T * 3)) < 0.1 and 0.5 or 1
            put((3 + mid * 4) * fl * dim, x + 1 + w * 2.4, TY - 3, 1, 2)
          end
        end
        -- the headlight's beam along the deck
        local hx = R.dir > 0 and R.x + R.n * 11 or R.x
        line(2.5 * dim, hx, TY - 2, hx + R.dir * 14, TY - 1)
      end
    end
    -- near blocks: black, their roofline edged, windows lit
    for col = 0, 63 do
      local top = NEAR[col]
      if top < GY then put(1.5 + lo * 0.8, col * 2, top, 2, 1) end
    end
    -- the mids and the phrase: more of the city's windows on, and warmer
    local share = 0.08 + e * 0.3 + mid * 0.25 + ph * 0.2
    for i = 1, NW do
      local W = WIN[i]
      local lv = 0
      if W.on < share then lv = (1.5 + mid * 1.5 + W.on * 6) * dim end
      if W.tv then lv = max(lv, 1.5 + 1.2 * sin(T * 7 + i) * sin(T * 2.3 + i * 3)) end
      local L = wlit[i]
      if L then
        local u = (T - L.t) / 0.8
        if u >= 1 then wlit[i] = nil elseif u >= 0 then lv = max(lv, L.lv * (1 - u)) end
      end
      if c > 0.5 and K.hash(i, floor(T * 3)) < (c - 0.5) * 0.3 then lv = 5 - lv * 0.5 end
      if lv >= 0.5 and (W.x < SGX - 2 or W.x > SGX + 6) then put(lv, W.x, W.y, 2, 2) end
    end
    -- the neon sign: three bars, the mids light it, ticks flicker it
    neon_f = neon_f * exp(-DT / 0.2)
    do
      local nl = (2 + mid * 4 + e) * dim
      line(1.5, SGX - 1, SGY - 1, SGX + 5, SGY - 1)
      line(1.5, SGX - 1, SGY + 13, SGX + 5, SGY + 13)
      for k = 0, 2 do
        local f = 1
        if neon_f > 0.05 and K.hash(k, floor(T * 15)) < neon_f * 0.6 then f = 0.3 end
        put(nl * f, SGX, SGY + 1 + k * 4, 4, 2)
      end
      put(mid * 2 * dim, SGX - 3, GY + 1, 11, 1)
    end
    -- the street: a kerb line, lamps pooling on the wet road, cars
    put(1.5, 0, GY, 128, 1)
    for x = 12, 127, 36 do
      put(1.5, x, GY - 8, 1, 8)
      put(3 + lo * 3 * dim, x - 1, GY - 9, 3, 1)
      put(0.6 + lo * 2.5, x - 3 - lo * 3, GY + 1, 7 + lo * 6, 1)
      put(lo * 1.6, x - 2 - lo * 2, GY + 2, 5 + lo * 4, 2)
      -- the reflection: a broken streak down the wet road
      for y = GY + 4, 63, 2 do
        local wob = floor(sin(T * 2 + y * 0.9 + x) * 1.2 + 0.5)
        put((0.6 + lo * 1.8) * dim, x + wob, y, 1, 1)
      end
    end
    local base = (T * (14 + e * 20)) % 160
    for k = 0, 1 + floor(e * 2) do
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
    -- kickless: mist settles between the blocks
    if kl > 0.05 then K.haze(0, 30, 128, GY, kl * 0.35, 1, T * 3) end

    -- the pane: its shake, frame and glare
    shake = shake * exp(-DT / 0.12)
    glare_f = glare_f * exp(-DT / 0.25)
    flash = flash * exp(-DT / 0.4)
    local sx = shake_dir * floor(shake * shake * (1 + e * 0.6) + 0.5)
    local sy = floor(shake * shake * 0.6 + 0.3)
    put(2.5, sx, sy, 128, 1); put(2.5, sx, 63 + sy, 128, 1)
    put(2.5, sx, sy, 1, 64); put(2.5, 127 + sx, sy, 1, 64)
    for k = 0, 1 do
      local gx = (T * (5 + k * 3) + k * 90) % 230 - 60
      -- the glare: a soft sheen in the upper glass, short broken strokes;
      -- an open hat flares it
      for q = 0, 3 do
        local y0 = 3 + q * 5
        line(0.4 + hi * 3 + glare_f * 4, gx + q * 3, y0 + 4, gx + q * 3 + 3, y0)
      end
      if c > 0.4 then line(1, gx + 30, 14, gx + 36, 4) end
    end

    -- (the glass rings with the kick rather than moving: the frame moves)
    draw_cracks(cracks, 0, 0, hi, mid, 1 + shake * 0.25)
    -- falling shards
    for i = #shards, 1, -1 do
      local P = shards[i]
      local t = T - P.t0
      if t >= 0 then
        local cy = P.cy + 0.5 * 90 * t * t
        if cy > 80 then table.remove(shards, i)
        else
          local cx = P.cx + P.vx * t
          local a = P.w * t
          local ca, sa = cos(a), sin(a)
          local q = P.p
          local lv = 6 * max(0.3, 1 - t)
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
      local u = (T - G.t0) / G.life
      if u >= 1 or not G.C then table.remove(glints, i)
      else
        local r = G.R.L * u
        local x = G.C.x + cos(G.R.a) * r
        local y = G.C.y + sin(G.R.a) * r
        put((5 + 7 * G.v) * sin(PI * u), x, y, 1, 1)
      end
    end
    -- kickless: drips running down the glass
    if kl > 0.05 then
      local nd = floor(kl * 7)
      for k = 1, nd do
        local x = floor(K.hash(k, 61) * 120) + 4
        local y = (T * (3 + K.hash(k, 62) * 5) + K.hash(k, 63) * 64) % 72 - 6
        line(1.5 + kl, x, y - 5, x, y)
        put(2 + kl * 2, x, y + 1, 1, 1)
      end
    end
  end

  ----------------------------------------------------------------------
  -- view 2: the mirror
  ----------------------------------------------------------------------
  local tlv, wlv = 1, 1                -- the towers' level, their windows'
  local camp = 0                       -- the level, for the sky

  -- the scene's lit runs on row y: calls emit(x0, x1, lv)
  local function scene_row(y, emit, mr, mlv, gl, hi)
    if y < 0 or y > 63 then return end
    local T = K.T
    local dy = y - moon_y
    if dy * dy <= mr * mr then
      local hw = math.sqrt(mr * mr - dy * dy)
      emit(MOX - hw, MOX + hw, mlv)
    elseif y < HZ - 2 and K.hash(y, 77) < 0.35 then
      local sx = floor(K.hash(y, 78) * 128)
      emit(sx, sx + 1, 1 + hi * 3 + 0.8 * sin(T * 2 + y))
    end
    -- clouds drifting
    if y >= 3 and y <= 16 then
      for k = 0, 2 do
        local cy = 4 + k * 5
        if y == cy then
          local cx = (k * 67 + T * (2.5 + k)) % 190 - 30
          local hw = 10 + k * 3
          emit(cx - hw, cx + hw, 1 + camp * 1.2)
        end
      end
    end
    if y >= 25 and y < HZ then
      for i = 1, #TOWERS do
        local t = TOWERS[i]
        if y >= t[2] then
          if y < HZ - 3 then emit(t[1], t[1] + t[3], (y == t[2]) and 1.5 + tlv or tlv) end
          if (y - t[2]) % 3 == 2 and y < HZ - 1 then
            local wl = wlv + tlit[i] * 4
            for q = 1, t[3] - 2, 3 do
              if K.hash(i * 31 + q, y) < 0.45 + tlit[i] then emit(t[1] + q, t[1] + q + 1, wl) end
            end
          end
        end
      end
    elseif y == HZ then
      emit(0, 128, 2.2)
    elseif y > HZ then
      -- the towers' reflections, broken by the water
      local ry = 2 * HZ - y
      if y <= HZ + 5 then
        for i = 1, #TOWERS do
          local t = TOWERS[i]
          if ry >= t[2] then
            local wob = sin(y * 0.7 + T * 1.5 + i) * 1.2
            emit(t[1] + wob, t[1] + t[3] + wob, 1)
          end
        end
      end
      local w = 2 + (y - HZ) * 0.45
      local wob = sin(y * 0.35 + T * 2) * 1.5
      emit(MOX - w + wob, MOX + w + wob, gl * 0.7)
      if K.hash(y, floor(T * 4)) < 0.25 + hi * 0.5 then
        local gx = floor(K.hash(y, floor(T * 4) + 9) * 128)
        emit(gx, gx + 2, 1 + hi * 4)
      end
    end
  end

  local function draw_mirror(S)
    -- (an old mirror: its silvering takes a little of the light)
    local put = function(l, x, y, w, h) return put(l * 0.8, x, y, w, h) end
    local line = function(l, x0, y0, x1, y1) return line(l * 0.8, x0, y0, x1, y1) end
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    -- the highs glitter between the kicks (the hats' place)
    local hiq = hi * (1 - K.env.kick) ^ 3
    local kl = K.kickless
    if layout ~= built then build(layout); built = layout end
    for i = #knocks, 1, -1 do
      local Q = knocks[i]
      if T >= Q.t then table.remove(knocks, i); knock(TRI[Q.i], 0.8, 0.8) end
    end
    -- the moon rises through the phrase
    moon_y = K.follow(moon_y, 24 - phrase(S) * 14, 2.5, DT)
    local mr = 4.5 + e * 2 + lo * 1.6 + K.env.kick * 0.8
    local mlv = 2.5 + e * 1.2 + lo * 2.6
    local gl = 1.6 + hiq * 2.5 + e * 1
    local kb = K.env.kick * (0.4 + 0.3 * e)
    tlv = 0.85 + mid * 0.9
    wlv = 1.2 + mid * 1.8 + e * 0.5
    camp = amp
    for i = 1, #TOWERS do tlit[i] = tlit[i] * exp(-DT / 0.5) end
    shiver = shiver * exp(-DT / 0.3)
    -- shards ease toward their targets; kickless pulls them home
    for _, Tr in ipairs(TRI) do
      if kl > 0.3 then
        local f = 1 - exp(-DT / 3)
        Tr.tdx, Tr.tdy, Tr.tsh = Tr.tdx * (1 - f), Tr.tdy * (1 - f), Tr.tsh * (1 - f)
      end
      -- eased, but never more than a couple of pixels a frame
      local k = 1 - exp(-DT / 0.12)
      local lim = 30 * DT
      Tr.dx = Tr.dx + clamp((Tr.tdx - Tr.dx) * k, -lim, lim)
      Tr.dy = Tr.dy + clamp((Tr.tdy - Tr.dy) * k, -lim * 0.6, lim * 0.6)
      Tr.sh = Tr.sh + clamp((Tr.tsh - Tr.sh) * k, -lim * 0.02, lim * 0.02)
    end
    -- each shard: scanline its rows, sample the scene at its offset
    for n = 1, #TRI do
      local Tr = TRI[n]
      local V = Tr.v
      local ymin = floor(min(V[1][2], V[2][2], V[3][2]))
      local ymax = math.ceil(max(V[1][2], V[2][2], V[3][2]))
      local bx = (Tr.cx - 64) * 0.035 * kb
      local by = (Tr.cy - 32) * 0.035 * kb
      local drift = c * 1.5 * sin(T * 0.7 + n) + shiver * sin(T * 31 + n * 2)
        + 0.6 * sin(T * 0.23 + n * 1.7)
      for y = max(0, ymin), min(63, ymax - 1) do
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
          xl, xr = floor(xl + 0.5), floor(xr + 0.5)
          local ox = Tr.dx + bx + drift + Tr.sh * (y - Tr.cy)
          local sy = floor(y - Tr.dy - by + 0.5)
          scene_row(sy, function(a, b, lv)
            if Tr.flip then a, b = 2 * Tr.cx - b, 2 * Tr.cx - a end
            a, b = floor(a + ox + 0.5), floor(b + ox + 0.5)
            if a < xl then a = xl end
            if b > xr then b = xr end
            if b > a then put(lv, a, y, b - a, 1) end
          end, mr, mlv, gl, hiq)
        end
      end
    end
    -- kickless: a mist over the water
    if kl > 0.05 then K.haze(0, 36, 128, 60, kl * 0.4, 1, T * 2) end
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
      local fl = max(0, 1 - (T - Tr.hit) / 0.3)
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
      for n = 1, floor(c * 10) do
        local Tr = TRI[1 + (n * 7) % #TRI]
        local a = K.hash(n, layout) * TAU
        line(1.2 + c, Tr.cx, Tr.cy, Tr.cx + cos(a) * 7, Tr.cy + sin(a) * 5)
      end
    end
    -- tom ripples on the water
    for i = #ripples, 1, -1 do
      local R = ripples[i]
      local u = (T - R.t0) / 1.2
      if u >= 1 then table.remove(ripples, i)
      else K.ring(4 * (1 - u), R.x, R.y, 2 + u * 14, 14, 0, TAU, 0.3) end
    end
    -- the frame: a gilt frame's beaded moulding, catching the level
    K.dashes(1 + amp, 0, 2, 4, T * 2); K.dashes(1 + amp, 63, 2, 4, -T * 2); put(1, 0, 0, 1, 64); put(1, 127, 0, 1, 64)
    -- glints along the edges (open hats: around a whole shard)
    for i = #glints, 1, -1 do
      local G = glints[i]
      local u = (T - G.t0) / G.life
      if u >= 1 or G.C then table.remove(glints, i)
      elseif G.tri then
        local V = G.tri.v
        local s = u * 3
        local k = floor(s) % 3 + 1
        local f = s - floor(s)
        local P, Q = V[k], V[k % 3 + 1]
        local lv = (4 + 6 * G.v) * sin(PI * u)
        line(lv * 0.4, V[1][1], V[1][2], V[2][1], V[2][2])
        line(lv * 0.4, V[2][1], V[2][2], V[3][1], V[3][2])
        line(lv * 0.4, V[3][1], V[3][2], V[1][1], V[1][2])
        put(lv, P[1] + (Q[1] - P[1]) * f, P[2] + (Q[2] - P[2]) * f, 1, 1)
      else
        local x, y = G.x0 + (G.x1 - G.x0) * u, G.y0 + (G.y1 - G.y0) * u
        local lv = (5 + 7 * G.v) * sin(PI * u)
        put(lv, x, y, 1, 1)
        if lv > 5 then put(lv * 0.4, x - 1, y, 3, 1) end
      end
    end
  end

  ----------------------------------------------------------------------
  -- view 3: the windscreen
  ----------------------------------------------------------------------
  local function wiper_angle(k)
    -- one sweep a bar, dwelling at rest when the energy is low
    local u
    if K.playing then u = K.bar_ph % 1 else u = (K.T * 0.3) % 1 end
    local dwell = 1 + (1 - K.energy) * 0.9
    u = clamp(u * dwell, 0, 1)
    local s = (1 - cos(TAU * u)) / 2
    local a = PI + (PI - 0.4 - (k == 2 and 0.15 or 0)) * s
    if K.chaos > 0.4 then a = a + sin(K.T * 23 + k) * (K.chaos - 0.4) * 0.08 end
    return a
  end

  local function draw_screen(S)
    -- (seen through the glass at night: the whole view a touch dimmer)
    local put = function(l, x, y, w, h) return put(l * 0.75, x, y, w, h) end
    local line = function(l, x0, y0, x1, y1) return line(l * 0.75, x0, y0, x1, y1) end
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid, amp = A[K.LO], A[K.HI], A[K.MID], A[K.AMP]
    local kl = K.kickless
    local ph = phrase(S)
    brake = brake * exp(-DT / 0.25)
    hazard = max(0, hazard - DT / 2)
    sign_f = sign_f * exp(-DT / 0.2)
    flash = flash * exp(-DT / 0.4)
    dash_bob = dash_bob * exp(-DT / 0.1)
    car_d = K.follow(car_d, kl, 2, DT)
    -- the signal changes through the phrase
    sig = ph < 0.6 and 1 or (ph < 0.72 and 2 or 3)
    for i = #hail, 1, -1 do
      local H = hail[i]
      if H.t then
        if T >= H.t then H.t0, H.t = T, nil end
      else
        local u = (T - H.t0) / 1.5
        if u >= 1 then table.remove(hail, i)
        else
          local lv = 1.2 + 5 * (1 - u) ^ 2
          line(lv, H.x - 2, H.y, H.x + 2, H.y); line(lv, H.x, H.y - 2, H.x, H.y + 2)
          put(lv, H.x - 1, H.y - 1, 1, 1); put(lv, H.x + 1, H.y + 1, 1, 1)
        end
      end
    end

    -- the fog over the junction; the level lifts it
    for y = 19, 24 do
      local hw = 22 + (y - 19) * 4 + kl * 16 + amp * 8 + 3 * sin(T * 0.4 + y)
      put(1 + (kl * 0.6 + amp * 0.6) * (1 - abs(y - 22) / 4), VPX - hw, y, hw * 2, 1)
    end
    if kl > 0.05 then K.haze(0, 10, 128, 32, kl * 0.3, 1, T * 5) end
    -- rain falling beyond the glass
    local nr = floor(8 + hi * 10 + e * 8 - kl * 4)
    for i = 1, nr do
      local x = (K.hash(i, 81) * 140 - T * 9) % 140 - 6
      local y = (T * (40 + K.hash(i, 82) * 20) + K.hash(i, 83) * 60) % 56 - 4
      line(1 + hi, x, y, x - 1, y + 3)
    end

    -- the shops either side: corners, floors running to the junction,
    -- their windows by the mids
    local share = 0.15 + mid * 0.4 + e * 0.2
    for side = -1, 1, 2 do
      local xc = side < 0 and 34 or 94
      local xo = side < 0 and 0 or 127
      local yb = VPY + (61 - (side < 0 and xc or 128 - xc)) * 39 / 91
      line(1.5 + amp, xc, 0, xc, yb)
      for f = 0, 3 do
        local y0 = 2 + f * 10
        local y1 = y0 + (VPY - y0) * 34 / 64
        if f == 0 then line(1, xo, y0, xc, y1) end
        -- a row of windows under each floor line
        for q = 0, 4 do
          local u = (q + 0.5) / 5
          local x = xo + (xc - xo) * u
          local y = y0 + (y1 - y0) * u + 3
          local h = K.hash(q * 7 + f * 31 + (side + 1) * 50, 91)
          if h < share and y < yb - 2 then
            put((1.2 + mid * 1.5 + h * 2) * (1 - kl * 0.3), x - 1, y, 2, 3 - floor(u * 1.5))
          end
        end
      end
    end
    -- the neon sign on the right, flickered by perc and ticks
    do
      local nl = 2 + mid * 4 + e
      line(1.5, 93, 13, 109, 13); line(1.5, 93, 19, 109, 19)
      for k = 0, 3 do
        local f = 1
        if sign_f > 0.05 and K.hash(k, floor(T * 14)) < sign_f * 0.7 then f = 0.25 end
        put(nl * f, 95 + k * 4, 15, 3, 3)
      end
      -- its glow on the wet road
      for y = 36, DY - 1, 3 do put(mid * 1.5, 92 + floor(sin(T * 2 + y) + 0.5), y, 4, 1) end
    end
    -- the signal on its wire over the junction
    line(1.2, 0, 3, 60, 6); line(1.2, 68, 6, 128, 3)
    line(2, 58, 5, 70, 5); line(2, 58, 11, 70, 11)
    for k = 1, 3 do
      local x = 59 + (k - 1) * 4
      local on = k == sig
      put(on and (6 + mid * 3) or 1.2, x, 7, 3, 3)
      if on then
        K.ring(1.5 + mid * 2, x + 1.5, 8.5, 4 + mid, 8)
        -- its reflection down the wet road
        for y = 32, DY - 1, 2 do
          put((1 + mid * 2.5) * (0.5 + 0.5 * sin(T * 3 + y * 1.3)), x + floor(sin(T * 1.7 + y) + 0.5), y, 2, 1)
        end
      end
    end

    -- the road: edges, the crossing, our lights pooling, the centre line
    line(1.2 + lo * 0.8, VPX - 3, VPY, VPX - 3 - (DY - VPY) * 91 / 39, DY)
    line(1.2 + lo * 0.8, VPX + 3, VPY, VPX + 3 + (DY - VPY) * 91 / 39, DY)
    line(1 + amp * 0.6, 34, VPY, 94, VPY)
    for x = floor(VPX - road_hw(32)), VPX + road_hw(32), 4 do put(1.2 + amp, x, 32, 2, 2) end
    for y = 41, DY - 1 do
      local v = (0.6 + lo * 1.8 + brake * 0.6) * (y - 39) / 13 * (1 - kl * 0.3)
      local hw = road_hw(y) * 0.45
      if v >= 1 then put(v, VPX - hw, y, hw * 2, 1)
      elseif v > 0.35 and y % 2 == 0 then put(1, VPX - hw, y, hw * 2, 1) end
    end
    local sp = (sig == 3 and 0.05 or 0.25 + e * 0.4) * (1 - kl * 0.5)
    for k = 0, 5 do
      local u = ((k + T * sp * 6) / 6) % 1
      local y = VPY + (DY - VPY) * u * u
      line(2 + lo * 2, VPX, y, VPX, min(DY - 1, y + 1 + u * 4))
    end

    -- oncoming headlights growing out of the rain
    onc_acc = onc_acc + DT * (0.15 + e * 0.5) * (sig == 3 and 0.3 or 1)
    if onc_acc >= 1 then
      onc_acc = onc_acc - 1
      if #oncoming < 3 then oncoming[#oncoming + 1] = {t0 = T, d = 2.5 + K.rnd() * 1.5} end
    end
    for i = #oncoming, 1, -1 do
      local O = oncoming[i]
      local u = (T - O.t0) / O.d
      if u >= 1 then table.remove(oncoming, i)
      else
        local uu = u * u
        local y = VPY + 1 + (DY - 4 - VPY) * uu
        local x = VPX - 6 - uu * 44
        local sep = 2 + uu * 12
        local lv = 2.5 + u * 5 + lo * 1.5
        put(lv, x - sep / 2, y, 1 + uu * 2, 1)
        put(lv, x + sep / 2, y, 1 + uu * 2, 1)
        if u > 0.4 then K.ring(1 + u * 1.5, x, y, 2 + uu * 7, 10, 0, TAU, 0.5) end
      end
    end
    -- cross traffic over the junction
    for i = #crossers, 1, -1 do
      local C = crossers[i]
      C.x = C.x + C.dir * C.sp * K.DTS
      if C.x < -20 or C.x > 148 then table.remove(crossers, i)
      else
        put(1.8, C.x - 6, VPY - 2, 12, 2)
        put(7, C.x + C.dir * 6, VPY - 1, 1, 1)
        line(2, C.x + C.dir * 7, VPY - 1, C.x + C.dir * 20, VPY)
        put(4, C.x - C.dir * 7, VPY - 1, 1, 1)
      end
    end
    -- the car ahead: it pulls away into the fog when the kick drops out
    do
      local s = 1 - car_d * 0.5
      local cy = 40 - car_d * 8
      local hw = 13 * s
      local dk = 1 - car_d * 0.4
      line(2 * dk, VPX - hw * 0.7, cy - 5 * s, VPX + hw * 0.7, cy - 5 * s)
      line(2 * dk, VPX - hw, cy - 2 * s, VPX - hw * 0.7, cy - 5 * s)
      line(2 * dk, VPX + hw, cy - 2 * s, VPX + hw * 0.7, cy - 5 * s)
      line(2.2 * dk, VPX - hw, cy + 4 * s, VPX + hw, cy + 4 * s)
      local blink = hazard > 0 and (0.5 + 0.5 * sin(T * 9)) * hazard or 0
      local tl = (2.5 + brake * 8 + lo * 1.5 + blink * 5) * dk
      put(tl, VPX - hw, cy, 4 * s, 2)
      put(tl, VPX + hw - 4 * s, cy, 4 * s, 2)
      put((1.5 + brake * 3) * dk, VPX - 2, cy - 4 * s, 4, 1)
      -- their reflection down the wet road
      for y = floor(cy + 5 * s), DY - 1, 2 do
        local wob = floor(sin(T * 2.4 + y) * 0.8 + 0.5)
        local rl = (brake * 3 + lo * 1.5 + 0.8) * dk * (1 - (y - cy) / 20)
        put(rl, VPX - hw + 1 + wob, y, 2, 1)
        put(rl, VPX + hw - 3 + wob, y, 2, 1)
      end
    end
    -- tom splashes in the puddles
    for i = #splashes, 1, -1 do
      local P = splashes[i]
      local u = (T - P.t0) / 0.8
      if u >= 1 then table.remove(splashes, i)
      else K.ring((3 + 3 * P.v) * (1 - u), P.x, P.y, 1 + u * 7, 10, 0, TAU, 0.3) end
    end

    -- the glass: chips and their runners
    draw_cracks(chips, 0, 0, hi, mid, 0.6)
    for i = #runners, 1, -1 do
      local R = runners[i]
      local age = T - R.t0
      local grow = clamp(age / 0.8, 0, 1)
      local lv = 1.5 + mid * 1.5 + exp(-age / 0.3) * 6 + flash * 3
      local px, py = R.x, R.y
      for k = 1, 6 do
        local f = k / 6
        if f > grow then break end
        local a = R.a + R.bend * f + (K.hash(k, R.seed) - 0.5) * 0.4
        local x, y = px + cos(a) * R.L / 6, py + sin(a) * R.L / 6
        line(lv, px, py, x, y)
        if c > 0.4 and K.hash(k, R.seed + 1) < c * 0.5 then
          local ba = a + (K.hash(k, R.seed + 2) < 0.5 and 0.8 or -0.8)
          line(lv * 0.6, x, y, x + cos(ba) * 5, y + sin(ba) * 5)
        end
        px, py = x, y
      end
    end
    -- the drops, and the wipers clearing them
    local rate = (2 + hi * 8 + e * 6) * (1 - kl * 0.5)
    if K.rnd() < rate * DT then drop(4 + K.rnd() * 120, 2 + K.rnd() * 46, K.rnd() < 0.2, 0.4) end
    local a1, a2 = wiper_angle(1), wiper_angle(2)
    local na = {a1, a2}
    for i = #raindrops, 1, -1 do
      local D = raindrops[i]
      local age = T - D.t0
      local gone = age > 7 or D.y > DY - 1
      if not gone then
        for k = 1, 2 do
          local P = PIV[k]
          local dx, dy = D.x - P[1], D.y - P[2]
          if dx * dx + dy * dy < P[3] * P[3] then
            local a = math.atan(dy, dx)
            if a < 0 then a = a + TAU end
            local lo_a, hi_a = min(wip_a[k], na[k]), max(wip_a[k], na[k])
            if a >= lo_a - 0.03 and a <= hi_a + 0.03 then gone = true end
          end
        end
      end
      if gone then table.remove(raindrops, i)
      else
        if D.run then
          D.y = D.y + D.vy * K.DTS
          line(1.5, D.x, D.y - 4, D.x, D.y - 1)
        end
        local fresh = max(0, 1 - age / 0.2)
        put(2 + hi * 1.5 + D.v + fresh * 4, D.x, D.y, 1, 1)
        if D.big then put(1.2 + hi, D.x, D.y + 1, 1, 1) end
        if D.splat and fresh > 0 then K.ring(fresh * 6, D.x, D.y, 1.5 + (1 - fresh) * 2.5, 6) end
      end
    end
    wip_a[1], wip_a[2] = a1, a2
    -- the wipers
    for k = 1, 2 do
      local P = PIV[k]
      local a = na[k]
      local tx, ty = P[1] + cos(a) * P[3], P[2] + sin(a) * P[3]
      local mx, my = P[1] + cos(a) * P[3] * 0.25, P[2] + sin(a) * P[3] * 0.25
      line(2.5 + amp, P[1], P[2], mx, my)
      line(3 + amp, mx, my, tx, ty)
      -- the blade's rubber, a hair behind the arm
      local bx, by = cos(a + PI / 2) * 1.2, sin(a + PI / 2) * 1.2
      line(1.5, mx + bx, my + by, tx + bx, ty + by)
    end
    -- the dashboard: its edge, the instrument hood, the gauges
    local db = floor(dash_bob * 1.2 + 0.5)
    line(1 + amp * 0.6, 0, DY + db, 12, DY + db)
    line(1 + amp * 0.6, 12, DY + db, 16, DY - 4 + db)
    line(1 + amp * 0.6, 16, DY - 4 + db, 44, DY - 4 + db)
    line(1 + amp * 0.6, 44, DY - 4 + db, 48, DY + db)
    line(1 + amp * 0.6, 48, DY + db, 127, DY + db)
    for g = 0, 1 do
      local gx, gy = 23 + g * 15, DY + 4 + db
      K.ring(1.5 + mid * 2, gx, gy, 4.5, 10, PI, TAU)
      local v = g == 0 and clamp(0.2 + lo * 0.6 + e * 0.2, 0, 1) or clamp(0.3 + amp * 0.5, 0, 1)
      local na2 = PI + v * PI
      line(5 + lo * 3, gx, gy, gx + cos(na2) * 4, gy + sin(na2) * 4)
    end
    put(1.5 + hazard * 6 * (0.5 + 0.5 * sin(T * 9)), 62, DY + 4 + db, 3, 2)
    put(1 + amp * 3, 80, DY + 5 + db, 30, 1)
  end

  ----------------------------------------------------------------------
  function M.draw(S)
    if K.view == 2 then draw_mirror(S)
    elseif K.view == 3 then draw_screen(S)
    else draw_pane(S) end
  end

  M.init()
  return M
end
