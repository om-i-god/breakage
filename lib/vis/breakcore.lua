-- breakcore. view 1: a wall of stacked CRT sets in a dark room, each tuned to its own channel (static, test bars, a silhouette, a scope, scrolling text, a film countdown).
-- view 2: a tower of stacked blocks on waste ground at night, knocked apart by the drums and rebuilt on phrase edges.
--
-- view 1: the kick flips a set on the bottom row and flashes every bezel;
-- snares flip one or more sets (more with chaos); a ratchet flips one set
-- over and over as fast as it rattles; hats brighten the static, open hats
-- roll a hold bar down a screen; ticks tear a screen sideways; break slices
-- jump the wall's rows around; a fill cascades every set onto the
-- countdown. energy powers more sets (CRTs collapse to a line and back as
-- they switch), chaos cracks the glass and blacks sets out, and kickless
-- stretches leave three sets glowing in the dark with a haze on the floor.
-- view 2: the kick slams the base (the tower drops and a shock runs along
-- the ground), snares knock blocks out of the tower to tumble and land in
-- the rubble, ratchets spray debris, hats chip, ticks crack blocks, break
-- slices push a row sideways like a jenga block, and on phrase edges (and
-- fills) the missing blocks drop back into place. energy sweeps
-- searchlights across the sky, chaos sways the tower, ghosts it and knocks
-- out more, kickless lets the lights die into fog and floating dust.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local floor = math.floor

  ---------------------------------------------------------------- view 1
  local TVS = {
    {x = 3, y = 39, w = 30, h = 18, panel = true}, {x = 35, y = 40, w = 27, h = 17, panel = true},
    {x = 64, y = 39, w = 30, h = 18, panel = true}, {x = 96, y = 40, w = 29, h = 17, panel = true},
    {x = 6, y = 23, w = 23, h = 15}, {x = 31, y = 24, w = 21, h = 15}, {x = 54, y = 22, w = 24, h = 16},
    {x = 80, y = 24, w = 21, h = 15}, {x = 103, y = 23, w = 22, h = 16},
    {x = 12, y = 9, w = 20, h = 13, ears = true}, {x = 36, y = 10, w = 18, h = 13},
    {x = 58, y = 8, w = 21, h = 13, ears = true}, {x = 83, y = 10, w = 18, h = 13}, {x = 104, y = 11, w = 16, h = 12},
  }
  local NTV = #TVS
  local ROW = {1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3}
  local NCH = 6
  -- the power-on order: the middle of the wall first
  local RANK = {}
  do
    local ord = {}
    for i = 1, NTV do
      local d = TVS[i]
      local cx = d.x + d.w / 2 - 64
      ord[i] = {i = i, k = math.abs(cx) * 0.02 + ROW[i] * 0.25 + K.hash(i, 41) * 0.6}
    end
    table.sort(ord, function(a, b) return a.k < b.k end)
    for r, o in ipairs(ord) do RANK[o.i] = r end
  end

  local tv                              -- per set: ch, glow, p, roll, tear, blk
  local rowdx, rowto                    -- each row's jump (from break slices)
  local hatf, bez, bezto, fogl
  local rq                              -- the ratchet: {i, n, next}
  local fillq                           -- the fill cascade: {i, at}
  local flips = {}                      -- sets waiting to flip (one a frame)

  ---------------------------------------------------------------- view 2
  local GY2 = 57                        -- the ground
  local TX, BW, RH, NR = 46, 12, 5, 9   -- tower left, block w, row h, rows
  local TW = 36
  local blocks, deb, cracks, motes
  local push, pushto
  local slam, shock, sink
  local MAXD = 44
  local CITY = K.profile(function(x)
    local h = 2 + floor(K.hash(x // 8, 51) * 7)
    if x > 6 and x < 18 then h = h + 8 end
    if x > 104 and x < 112 then h = h + 11 end
    return 46 - h
  end)

  local function build()
    blocks = {}
    for r = 0, NR - 1 do
      local xs
      if r % 2 == 0 then xs = {{0, 12}, {12, 12}, {24, 12}}
      else xs = {{0, 6}, {6, 12}, {18, 12}, {30, 6}} end
      for _, b in ipairs(xs) do
        blocks[#blocks + 1] = {r = r, x = b[1], w = b[2], on = true, back = -1, glow = 0, seed = #blocks}
      end
    end
  end

  function M.init()
    tv = {}
    for i = 1, NTV do
      tv[i] = {ch = 1 + floor(K.hash(i, 3) * NCH), glow = 0, p = 1, roll = -1, tear = 0, blk = 0}
    end
    rowdx, rowto = {0, 0, 0}, {0, 0, 0}
    hatf, bez, bezto, fogl = 0, 0, 0, 0
    for k = #flips, 1, -1 do flips[k] = nil end
    rq, fillq = nil, {}
    build()
    deb, cracks, motes = {}, {}, {}
    push, pushto = {}, {}
    for r = 0, NR - 1 do push[r], pushto[r] = 0, 0 end
    slam, shock, sink = 0, -9, 0
  end
  M.clear = M.init

  ---------------------------------------------------------------- events
  local function flip(i, keep)
    if #flips < 8 then flips[#flips + 1] = i end
  end
  local function flip_now(i)
    local s = tv[i]
    if not s then return end
    local n = 1 + floor(K.rnd() * (NCH - 1))
    if n >= s.ch then n = n + 1 end
    s.ch = n
    s.glow = 1
  end

  local function pick(row)
    if row then
      local c = {}
      for i = 1, NTV do if ROW[i] == row then c[#c + 1] = i end end
      return c[1 + floor(K.rnd() * #c)]
    end
    return 1 + floor(K.rnd() * NTV)
  end

  -- knock a block out of the tower
  local function knock(v, prefer)
    local live = {}
    for _, b in ipairs(blocks) do if b.on and b.back < 0 and b.r >= (prefer or 1) then live[#live + 1] = b end end
    if #live == 0 then return end
    local b = live[1 + floor(K.rnd() * #live)]
    b.on = false
    local bx = TX + b.x + push[b.r]
    local by = GY2 - (b.r + 1) * RH
    local dir = (b.x + b.w / 2 < TW / 2) and -1 or 1
    if math.abs(b.x + b.w / 2 - TW / 2) < 4 then dir = K.rnd() < 0.5 and -1 or 1 end
    if #deb >= MAXD then table.remove(deb, 1) end
    deb[#deb + 1] = {x = bx + b.w / 2, y = by + RH / 2, vx = dir * (30 + 40 * v + K.rnd() * 20), vy = -(20 + 30 * v),
      a = 0, va = dir * (4 + K.rnd() * 6), w = b.w, h = RH, lv = 3 + 2 * v, t0 = K.T, big = true, rest = false}
    return bx + b.w / 2, by + RH / 2
  end

  local function shards(x, y, n, sp, lv)
    for _ = 1, n do
      if #deb >= MAXD then table.remove(deb, 1) end
      local a = K.rnd() * K.TAU
      local s = sp * (0.4 + K.rnd() * 0.8)
      deb[#deb + 1] = {x = x, y = y, vx = math.cos(a) * s, vy = math.sin(a) * s - sp * 0.4, a = 0, va = 0,
        w = 1 + floor(K.rnd() * 2), h = 1, lv = lv, t0 = K.T, big = false, rest = false}
    end
  end

  local function rebuild()
    local k = 0
    for _, b in ipairs(blocks) do
      if not b.on then
        b.on, b.back = true, K.T + k * 0.09
        k = k + 1
      end
    end
    for _, d in ipairs(deb) do if d.big then d.fade = K.T end end
  end

  function M.kick(v)
    v = K.num(v, 1)
    flip(pick(1))
    bezto = 1
    slam = 1
    shock = K.T
    sink = 1
    shards(TX + 2, GY2 - 1, 2, 30, 4)
    shards(TX + TW - 2, GY2 - 1, 2, 30, 4)
  end

  function M.snare(v, n)
    v = K.num(v, 1)
    local c = K.chaos
    local m = 1 + floor(c * 2.5 + K.rnd() * 0.8)
    for _ = 1, m do
      local i = pick()
      flip(i)
      if c > 0.5 and K.rnd() < c * 0.4 then tv[i].blk = 0.25 + K.rnd() * 0.3 end
    end
    local x, y = knock(v)
    if c > 0.6 then knock(v * 0.8) end
    if x then shards(x, y, 3, 40, 7) end
  end
  function M.clap(v) M.snare(K.num(v, 1) * 0.8) end

  function M.hat(v, open)
    v = K.num(v, 1)
    hatf = math.max(hatf, 0.5 + 0.5 * v)
    if open then
      local i = pick()
      tv[i].roll = 0
    end
    -- a chip off a block edge
    local b = blocks[1 + floor(K.rnd() * #blocks)]
    if b.on and b.back < 0 then
      shards(TX + b.x + push[b.r] + (K.rnd() < 0.5 and 0 or b.w), GY2 - (b.r + 0.5) * RH, 1, 18, 4)
    end
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    local i = pick()
    tv[i].glow = math.max(tv[i].glow, 0.6 * v)
    if kind == 8 or kind == 11 then tv[i].ch = 6 end
    local b = blocks[1 + floor(K.rnd() * #blocks)]
    b.glow = math.max(b.glow, v)
  end
  function M.tom(v) M.perc(1, v) end

  function M.tick(kind)
    local i = pick()
    tv[i].tear = 1
    if kind == 7 or kind == 3 then tv[i].ch = 1; tv[i].glow = 0.6 end
    local b = blocks[1 + floor(K.rnd() * #blocks)]
    if b.on and #cracks < 12 then cracks[#cracks + 1] = {b = b, t0 = K.T, s = floor(K.rnd() * 999)} end
  end

  function M.brk(s, n, rev)
    s, n = floor(K.num(s, 1)), math.max(1, floor(K.num(n, 8)))
    local r = s % 3 + 1
    local d = (s * 7) % 5 - 2
    if d == 0 then d = rev and -3 or 3 end
    -- one row at a time, once the wall has settled
    if math.abs(rowto[1]) + math.abs(rowto[2]) + math.abs(rowto[3]) < 0.8 then rowto[r] = d end
    local tr = (s - 1) % NR
    pushto[tr] = (rev and -1 or 1) * (3 + (s % 3))
  end

  function M.ratchet(n, voice)
    n = clamp(floor(K.num(n, 2)), 1, 16)
    rq = {i = pick(), n = n, next = K.NOW}
    local x = TX + 6 + K.rnd() * (TW - 12)
    local y = GY2 - 8 - K.rnd() * (NR * RH - 12)
    shards(x, y, math.min(14, n * 2), 55, 8)
    if voice == "snare" or voice == "brk" then knock(0.7) end
  end

  function M.fill()
    fillq = {}
    for i = 1, NTV do fillq[#fillq + 1] = {i = i, at = K.NOW + RANK[i] * 0.04} end
    rebuild()
  end

  function M.bar(S)
    local pp = K.num(S and S.phrase_pos, 1)
    if pp == 0 then rebuild() end
    local gone = 0
    for _, b in ipairs(blocks) do if not b.on then gone = gone + 1 end end
    if gone > #blocks * 0.55 then rebuild() end
  end

  ---------------------------------------------------------------- channels
  local function lv(v) return math.min(13, v) end

  local function ch_static(i, x, y, w, h, g)
    local fr = floor(K.T * 8 + i * 0.37)
    local b = 2 + A[K.HI] * 3 + hatf * 3
    for r = 0, h - 1, 2 do
      local n = 1 + floor(K.hash(fr * 31 + r + i * 97, 5) * 3)
      for k = 1, n do
        local dw = 1 + floor(K.hash(fr + r * 5 + k + i * 11, 8) * 5)
        local hx = K.hash(fr * 7 + r * 13 + k * 3 + i * 51, 6)
        put(lv((b + 3 * K.hash(fr * 3 + r * k + i, 9)) * g), x + hx * (w - dw), y + r, dw, 1)
      end
    end
  end

  local BARL = {9, 8, 7, 6, 5, 4, 3}
  local function ch_bars(i, x, y, w, h, g)
    local bw = w / 7
    local bh = math.max(1, floor(h * 0.62))
    for b = 0, 6 do
      local x0 = floor(x + b * bw)
      local x1 = floor(x + (b + 1) * bw)
      put(lv(BARL[b + 1] * g * 0.6), x0, y, math.max(1, x1 - x0 - 1), bh)
    end
    if h > 4 then
      local yy = y + bh + 1
      local hh = math.max(1, h - bh - 1)
      put(lv(2 * g), x, yy, floor(w * 0.25), hh)
      put(lv(8 * g), x + floor(w * 0.4), yy, floor(w * 0.2), hh)
      put(lv(1.5 * g), x + floor(w * 0.75), yy, w - floor(w * 0.75), hh)
    end
  end

  local function ch_figure(i, x, y, w, h, g)
    local cx = x + w / 2 + math.sin(K.T * 0.7 + i) * 1.5
    local hy = y + h * 0.4 + (K.beat_ph < 0.15 and 1 or 0) * K.energy
    local hr = h * 0.21
    local back = lv((2.5 + A[K.MID] * 2) * g)
    for r = 0, h - 1, 2 do
      local yy = y + r
      local a, b
      local dy = yy - hy
      if math.abs(dy) < hr then
        local hw = math.sqrt(hr * hr - dy * dy)
        a, b = cx - hw, cx + hw
      elseif yy > hy + hr then
        local u = (yy - hy - hr) / math.max(1, y + h - hy - hr)
        local hw = w * (0.12 + 0.24 * math.min(1, u * 1.6))
        a, b = cx - hw, cx + hw
      end
      if a then
        if a > x then put(back, x, yy, a - x, 1) end
        if b < x + w then put(back, b, yy, x + w - b, 1) end
      else
        put(back, x, yy, w, 1)
      end
    end
  end

  local function ch_scope(i, x, y, w, h, g)
    local cy = y + h / 2
    K.dashes(lv(1.5 * g), floor(cy), 2, 4, 0, x, x + w)
    line(lv(1.2 * g), x + w / 2, y, x + w / 2, y + h - 1)
    local amp = (0.25 + A[K.MID] * 0.5 + K.env.snare * 0.4 + K.env.kick * 0.3) * (h / 2 - 1)
    local px, py
    local n = 10
    for k = 0, n do
      local xx = x + k * (w - 1) / n
      local yy = cy + math.sin(k * 1.3 + K.T * (3 + i * 0.3)) * amp * (0.6 + 0.4 * math.sin(k * 0.7 - K.T * 2))
      yy = clamp(yy, y, y + h - 1)
      if px then line(lv((6 + A[K.LO] * 3) * g), px, py, xx, yy) end
      px, py = xx, yy
    end
  end

  local function ch_text(i, x, y, w, h, g)
    local sc = K.T * (2.5 + A[K.HI] * 2.5) + i * 0.43
    local off = sc % 3
    local base = floor(sc / 3)
    local tl = lv((3.5 + hatf * 2) * g)
    for j = 0, floor(h / 3) do
      local yy = y + h - 1 - j * 3 + off - 3
      if yy >= y and yy < y + h then
        local ln = base + j + i * 17
        local xx = x + 1
        for k = 1, 3 do
          local ww = 1 + floor(K.hash(ln * 5 + k, 13) * 7)
          if xx + ww > x + w - 1 then break end
          put(tl, xx, yy, ww, 1)
          xx = xx + ww + 2
        end
      end
    end
    if K.T % 0.8 < 0.4 then put(lv(6 * g), x + 1, y + h - 2, 2, 1) end
  end

  local function ch_count(i, x, y, w, h, g)
    local cx, cy = x + w / 2, y + h / 2
    local r = math.min(w, h) / 2 - 1
    line(lv(1.5 * g), x, cy, x + w - 1, cy)
    line(lv(1.5 * g), cx, y, cx, y + h - 1)
    K.ring(lv(4 * g), cx, cy, r, 12)
    local a = K.T * 5 + i
    line(lv(7 * g), cx, cy, cx + math.cos(a) * r, cy + math.sin(a) * r)
    put(lv(5 * g), cx - 1, cy - 1, 3, 3)
  end

  local CH = {ch_static, ch_bars, ch_figure, ch_scope, ch_text, ch_count}

  ---------------------------------------------------------------- view 1 draw
  local function tv_draw(i, ox, oy, e, c, lo, kl)
    local d, s = TVS[i], tv[i]
    local x, y, w, h = d.x + ox, d.y + oy, d.w, d.h
    local bl = 1.5 + s.glow * 1.8 + bez * (ROW[i] == 1 and 1.5 or 0.5) + lo * 1.2 + s.p * 0.8
    line(bl + 0.6, x, y, x + w - 1, y)
    line(bl, x, y + 1, x, y + h - 1)
    line(bl * 0.8, x + w - 1, y + 1, x + w - 1, y + h - 1)
    line(bl * 0.7, x + 1, y + h - 1, x + w - 2, y + h - 1)
    local sw = w - 4
    if d.panel then
      sw = w - 10
      local px = x + w - 6
      line(1.2, px - 1, y + 2, px - 1, y + h - 3)
      put(1.5 + s.glow * 4 + s.p, px, y + 3, 3, 2)
      put(1.5 + A[K.HI] * 3, px, y + 7, 3, 2)
      put(1.2, px, y + h - 6, 3, 1)
      put(1.2, px, y + h - 4, 3, 1)
      put(2 + s.p * 5 * (0.6 + 0.4 * math.sin(K.T * 3 + i)), px + 1, y + h - 2, 1, 1)
    end
    if d.ears then
      line(1.5 + s.glow, x + w / 2, y, x + w / 2 - 6, y - 7 + math.sin(K.T * 0.4 + i))
      line(1.5 + s.glow, x + w / 2, y, x + w / 2 + 5, y - 6)
    end
    local sx, sy, sh = x + 2, y + 2, h - 4
    local p = s.p
    if p < 0.04 then
      -- dark glass: a glint of the room in the corner, an ember in the middle
      local gl = 1.2 + A[K.HI] * 1.2 + bez * 0.8
      local gx = sx + 2 + floor(math.sin(K.T * 0.3 + i) + 1)
      line(gl, gx, sy + 4, gx + 3, sy + 1)
      line(gl * 0.8, gx + 2, sy + 4, gx + 4, sy + 2)
      put(1 + kl * 0.5, sx + sw / 2, sy + sh / 2, 1, 1)
      return
    end
    local hh = math.max(1, floor(sh * p + 0.5))
    local yy = sy + floor((sh - hh) / 2)
    if hh <= 2 then
      line(math.min(11, 4 + 7 * (1 - p)), sx + sw * (0.5 - p * 2), yy, sx + sw * (0.5 + p * 2), yy)
      return
    end
    local g = (0.4 + 0.25 * e + lo * 0.2 + A[K.MID] * 0.3 + s.glow * 0.3) * (0.35 + 0.65 * p)
    g = g * (1 + kl * 0.25)
    local tx = 0
    if s.tear > 0.05 then tx = floor(s.tear * 4 * (K.hash(floor(K.T * 20) + i, 4) - 0.3)) end
    CH[s.ch](i, sx + tx, yy, sw, hh, math.min(1.15, g))
    if s.roll >= 0 then put(math.min(12, 3 + 4 * g), sx, yy + floor(s.roll * (hh - 1)), sw, 1) end
    -- cracks in the glass
    local ck = K.hash(i, 61)
    if ck < c * 0.75 - 0.12 then
      local cx0 = sx + floor(K.hash(i, 62) * sw)
      local cy0 = sy + floor(K.hash(i, 63) * sh)
      for k = 0, 2 do
        local a = K.hash(i * 3 + k, 64) * K.TAU
        local rl = 4 + K.hash(i * 3 + k, 65) * 9
        local x1 = clamp(cx0 + math.cos(a) * rl, sx, sx + sw - 1)
        local y1 = clamp(cy0 + math.sin(a) * rl, sy, sy + sh - 1)
        line(5 + c * 3, cx0, cy0, x1, y1)
      end
    end
  end

  local function draw1(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl = A[K.LO], A[K.HI], K.kickless

    -- the ratchet and the fill cascade
    if rq then
      while rq and K.NOW >= rq.next do
        flip(rq.i)
        rq.n = rq.n - 1
        rq.next = rq.next + 0.055
        if rq.n <= 0 then rq = nil end
      end
    end
    for k = #fillq, 1, -1 do
      local f = fillq[k]
      if K.NOW >= f.at then tv[f.i].ch = 6; tv[f.i].glow = 1; table.remove(fillq, k) end
    end

    -- how many sets are on
    local non = (6 + e * 8) * (1 - kl) + 3 * kl
    for i = 1, NTV do
      local s = tv[i]
      local dead = K.hash(i, 71) < (c - 0.4) * 0.75
      local want = (RANK[i] <= non and not dead and s.blk <= 0) and 1 or 0
      s.p = K.follow(s.p, want, want > s.p and 0.12 or 0.08, DT)
      if math.abs(s.p - want) < 0.01 then s.p = want end
      s.glow = s.glow * math.exp(-DT / 0.18)
      s.tear = s.tear * math.exp(-DT / 0.12)
      s.blk = s.blk - DT
      if s.roll >= 0 then
        s.roll = s.roll + DT * 2.2
        if s.roll > 1 then s.roll = -1 end
      end
    end
    local moved = false
    for r = 1, 3 do
      rowto[r] = rowto[r] * math.exp(-DT / 0.3)
      local to = floor(rowto[r] + 0.5)
      if not moved and to ~= rowdx[r] then
        rowdx[r] = rowdx[r] + (to > rowdx[r] and 1 or -1)
        moved = true
      end
    end
    -- one set flips a frame (and not while a row jumps)
    if not moved then
      local i = table.remove(flips, 1)
      if i then flip_now(i) end
    end
    fogl = K.follow(fogl, kl, 0.8, DT)

    -- the room: the back wall's panels, cables, the floor and its reflections
    for k = 0, 7 do
      local x = 2 + k * 18 + floor(K.hash(k, 81) * 6)
      line(1, x, 0, x, 6 + floor(K.hash(k, 82) * 4))
    end
    for k = 0, 4 do
      local x0 = 10 + k * 26
      local sag = 4 + math.sin(T * 0.5 + k) * 0.8
      line(1, x0, 0, x0 + 6, sag)
      line(1, x0 + 6, sag, x0 + 12, 1)
    end
    K.gradient(57, 63, function(y) return 0.25 + (y - 57) * 0.08 + e * 0.2 + fogl * 0.3 + K.duck * 0.15 end)
    for i = 1, 4 do
      local d, s = TVS[i], tv[i]
      local rl = (1 + s.p * (1.2 + lo * 1.5 + A[K.AMP] * 1.5 + s.glow * 4)) * (1 - kl * 0.3)
      for k = 0, 2 do
        local x = d.x + 4 + k * 7 + math.sin(T * 1.7 + k + i) * 1.2
        put(rl * (1 - k * 0.15), x + rowdx[1], 58 + k * 2, 4 - k, 1)
      end
    end
    -- the cables between the sets
    line(1.2, 33, 56, 35, 63)
    line(1.2, 94, 56, 92, 63)
    line(1, 62, 57, 64, 63)

    -- the sets
    for i = 1, NTV do tv_draw(i, rowdx[ROW[i]], 0, e, c, lo, kl) end

    -- kickless: a halo around the sets still on, and the haze on the floor
    if fogl > 0.1 then
      for i = 1, NTV do
        local s = tv[i]
        if s.p > 0.5 then
          local d = TVS[i]
          local x0 = d.x + rowdx[ROW[i]] - 2
          local hl = 1 + fogl * (1 + 0.5 * math.sin(K.T * 0.9 + i))
          line(hl, x0, d.y - 2, x0 + d.w + 3, d.y - 2)
          line(hl, x0, d.y - 1, x0, d.y + d.h)
          line(hl, x0 + d.w + 3, d.y - 1, x0 + d.w + 3, d.y + d.h)
          -- its light spilling down the wall to the floor
          K.dashes(hl, 60, 2, 3, i, d.x, d.x + d.w)
        end
      end
      K.haze(0, 52, 128, 64, fogl * 0.45, 1, T * 4)
    end
    -- chaos: sparks off the dead sets
    if c > 0.5 then
      K.grain(function(u, v)
        local i = 1 + floor(u * NTV)
        local d = TVS[i]
        return d.x + v * d.w, d.y + d.h - 1
      end, (c - 0.5) * 30, 7)
    end
    K.grain(function(u, v) return u * 128, 56 + v * 7 end, 2 + hi * 6, 3)
  end

  ---------------------------------------------------------------- view 2 draw
  -- a rotated rectangle's outline
  local function rbox(l, cx, cy, w, h, a)
    local ca, sa = math.cos(a), math.sin(a)
    local hw, hh = w / 2, h / 2
    local xs = {-hw, hw, hw, -hw}
    local ys = {-hh, -hh, hh, hh}
    local px, py = {}, {}
    for k = 1, 4 do
      px[k] = cx + xs[k] * ca - ys[k] * sa
      py[k] = cy + xs[k] * sa + ys[k] * ca
    end
    for k = 1, 4 do
      local j = k % 4 + 1
      line(l, px[k], py[k], px[j], py[j])
    end
  end

  local function draw2(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl, mid = A[K.LO], A[K.HI], K.kickless, A[K.MID]
    slam = slam * math.exp(-DT / 0.15)
    sink = sink * math.exp(-DT / 0.09)
    local drop = 0

    -- the sky: a low sodium glow over a dark city, a moon
    -- the city: an outline lit from below, hatched in the dark
    local hg = (1.3 + e * 0.4 + lo * 0.7) * (1 - kl * 0.3)
    for c = 0, 63 do
      local t0, t1 = floor(CITY[c] + 0.5), floor(CITY[c + 1] + 0.5)
      line(hg, c * 2, t0, c * 2 + 1, t0)
      if t1 ~= t0 then line(hg * 0.8, c * 2 + 2, math.min(t0, t1), c * 2 + 2, math.max(t0, t1)) end
      if c % 2 == 0 then line(1, c * 2 + 1, t0 + 2, c * 2 + 1, 47) end
    end
    for k = 0, 9 do
      local x = floor(K.hash(k, 91) * 126)
      local y = floor(K.at(CITY, x) + 2 + K.hash(k, 92) * 6)
      if y < 46 and (x < TX - 2 or x > TX + TW + 2) then
        put(2 + 1.5 * math.sin(T * 0.3 + k * 2) ^ 2 + e + A[K.AMP] * 2, x, y, 1, 1)
      end
    end
    K.disc(3 + kl * 2, 104, 9, 3.5)
    K.ring(1.5, 104, 9, 6, 12)
    for k = 0, 11 do
      local x, y = floor(K.hash(k, 93) * 127), 1 + floor(K.hash(k, 94) * 20)
      put(1 + (0.5 + 0.5 * math.sin(T * (0.6 + K.hash(k, 95)) + k)) * (1 + hi * 2), x, y, 1, 1)
    end
    -- low clouds drifting over the city
    K.haze(0, 14, 128, 32, 0.22 + e * 0.1 + kl * 0.15, 1, T * 5)
    -- searchlights with energy
    local sl = (e - 0.25) * 1.4 * (1 - kl)
    if sl > 0.05 then
      for k = 0, 1 do
        local bx = k == 0 and 16 or 112
        local a = -math.pi / 2 + math.sin(T * (0.35 + k * 0.1) + k * 2) * 0.6
        for j = -1, 1 do
          local aa = a + j * 0.05
          line(math.min(3, sl * (2 - math.abs(j)) + mid), bx, 47, bx + math.cos(aa) * 60, 47 + math.sin(aa) * 60)
        end
      end
    end

    -- the ground and the shock along it
    line(1.2 + lo * 0.5, 0, GY2, 127, GY2)
    for k = 0, 1 do
      local y = GY2 + 2 + k * 3
      K.dashes(1 + k * 0.3, y, 2 + k, 7 - k, T * (2 + k) + k * 3)
    end
    local sa = T - shock
    if sa < 0.6 then
      local u = sa / 0.6
      local r = 4 + u * 50
      local l = 9 * (1 - u)
      put(l, TX + TW / 2 + 18 + r - 6, GY2 - 1, 6, 1)
      put(l, TX + TW / 2 - 18 - r, GY2 - 1, 6, 1)
      put(l * 0.6, TX + TW / 2 + 18 + r * 0.6 - 3, GY2 + 2, 3, 1)
      put(l * 0.6, TX + TW / 2 - 18 - r * 0.6, GY2 + 2, 3, 1)
    end

    -- the tower
    local glow = 0.2 + e * 0.5 + kl * 0.4 * (0.5 + 0.5 * math.sin(T * 0.8))
    for r = 0, NR - 1 do
      pushto[r] = pushto[r] * math.exp(-DT / 0.35)
      local to = floor(pushto[r] + 0.5)
      if to > push[r] then push[r] = push[r] + 1 elseif to < push[r] then push[r] = push[r] - 1 end
    end
    local function lean(r) return floor(c * math.sin(T * 1.3) * r * 0.5 + 0.5) end
    -- the ghost tower (chaos)
    if c > 0.35 then
      local gx = floor(math.sin(T * 2.1) * c * 6 + 0.5)
      line(1 + c, TX + gx - 2, GY2 - NR * RH, TX + gx - 2, GY2)
      line(1 + c, TX + TW + gx + 2, GY2 - NR * RH, TX + TW + gx + 2, GY2)
      line(1 + c, TX + gx - 2, GY2 - NR * RH - 1, TX + TW + gx + 2, GY2 - NR * RH - 1)
    end
    for _, b in ipairs(blocks) do
      b.glow = b.glow * math.exp(-DT / 0.25)
      if b.on then
        local x = TX + b.x + push[b.r] + lean(b.r)
        local y = GY2 - (b.r + 1) * RH + (b.r == 0 and drop or 0)
        local fade = 1
        if b.back >= 0 then
          local u = (T - b.back) / 0.5
          if u < 0 then fade = 0
          elseif u >= 1 then b.back = -1
          else
            fade = u
            y = y - floor((1 - K.ease(u)) * 14)
          end
        end
        if fade > 0 then
          local fl = (b.r == 0 and slam * 5 or slam * 0.6) + b.glow * 6
          local body = (1 + glow + mid * 0.8 + lo * 2.2 * (1 - b.r / NR) + fl * 0.4) * fade
          for hx = x + 2 + b.seed % 2, x + b.w - 2, 3 do line(body, hx, y + 1, hx, y + RH - 2) end
          line((1.4 + glow * 0.3 + fl * 0.8 + hi * 0.4) * fade, x, y, x + b.w - 1, y)
          line((2.5 + glow + fl * 0.7) * fade, x, y + 1, x, y + RH - 1)
          line((1.5 + fl * 0.5) * fade, x + b.w - 1, y + 1, x + b.w - 1, y + RH - 1)
        end
      else
        -- the hole it left: a dim back face
        local x = TX + b.x + push[b.r] + lean(b.r)
        local y = GY2 - (b.r + 1) * RH + (b.r == 0 and drop or 0)
        line(1, x + 1, y + 2, x + b.w - 2, y + 2)
      end
    end
    -- cracks
    for k = #cracks, 1, -1 do
      local C = cracks[k]
      local u = (T - C.t0) / 1.5
      if u >= 1 or not C.b.on then table.remove(cracks, k)
      else
        local b = C.b
        local x = TX + b.x + push[b.r] + lean(b.r)
        local y = GY2 - (b.r + 1) * RH + (b.r == 0 and drop or 0)
        local cx = x + 2 + K.hash(C.s, 1) * (b.w - 4)
        line(8 * (1 - u), cx, y, cx + 2, y + 2)
        line(8 * (1 - u), cx + 2, y + 2, cx + 1, y + RH - 1)
      end
    end

    -- debris: tumbling blocks and shards, settling in the rubble
    for k = #deb, 1, -1 do
      local d = deb[k]
      if not d.rest then
        d.vy = d.vy + 140 * DT
        d.x, d.y = d.x + d.vx * DT, d.y + d.vy * DT
        d.a = d.a + d.va * DT
        local floor_y = GY2 - (d.big and 2 or 1)
        if d.y >= floor_y then
          d.y = floor_y
          if math.abs(d.vy) < 25 then
            d.rest, d.vx, d.vy, d.va = true, 0, 0, 0
            if d.big then d.a = floor(d.a / (math.pi / 2) + 0.5) * (math.pi / 2) end
          else
            d.vy = -d.vy * 0.35; d.vx = d.vx * 0.6; d.va = d.va * 0.5
          end
        end
      end
      local age = T - d.t0
      local life = d.big and 30 or 1.6
      local f = 1
      if d.fade then f = 1 - (T - d.fade) / 0.5 end
      if age > life or f <= 0 or d.x < -20 or d.x > 148 then table.remove(deb, k)
      else
        if d.big then
          local l = (d.rest and (1.5 + glow * 0.5) or d.lv) * f
          rbox(l, d.x, d.y, d.w, d.h, d.a)
          if d.rest then put(l * 0.6, d.x - d.w / 2 + 1, d.y - 1, d.w - 2, 1) end
        else
          put(d.lv * (1 - age / life), d.x, d.y, d.w, d.h)
        end
      end
    end

    -- kickless: fog over the ground, dust floating up
    if kl > 0.1 then
      K.haze(0, 44, 128, 60, kl * 0.4, 1, T * 3)
      K.grain(function(u, v) return TX - 10 + u * (TW + 20), 20 + v * 36 end, kl * 10, 4)
    end
    K.grain(function(u, v) return u * 128, GY2 + 1 + v * 6 end, 2 + hi * 8 + slam * 10, 3)
  end

  function M.draw(S)
    bezto = bezto * math.exp(-K.DT / 0.12)
    bez = K.follow(bez, bezto, 0.04, K.DT)
    hatf = hatf * math.exp(-K.DT / 0.08)
    if K.view == 2 then draw2(S) else draw1(S) end
  end

  M.init()
  return M
end
