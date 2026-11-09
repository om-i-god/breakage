-- breakcore. view 1: a wall of stacked CRT sets in a dark room, each tuned to its own channel (static, test bars, a silhouette, a scope, scrolling text, a film countdown).
-- view 2: a tower of stacked blocks on waste ground at night, knocked apart by the drums and rebuilt by a crane, bar by bar.
-- view 3: the amen on the deck: a record from above under a raking light, the tone arm riding in over the phrase, a 4x4 pad grid of the break's slices beside it.
--
-- view 1: the kick flips a set on the bottom row and flashes every bezel;
-- snares flip one or more sets (more with chaos); claps jolt a whole row of
-- screens brighter; a ratchet flips one set over and over as fast as it
-- rattles; closed hats brighten the static and throw snow over one screen,
-- open hats roll a hold bar down a screen; ticks tear a screen sideways;
-- perc tunes a set to its own channel (congas and toms the scope, cowbell
-- and metal the bars, vox the silhouette, music box the countdown); break
-- slices jump the wall's rows around; a fill cascades every set onto the
-- countdown. every bar a top set changes programme and a vertical-hold
-- band rolls down the wall with the bar; each phrase opens with the whole
-- wall retuning in a cascade, and more sets warm up as the phrase goes on.
-- AMP lights the floor's reflections, LO the bezels and the scopes, MID the
-- pictures, HI the static and the glass. energy powers more sets (CRTs
-- collapse to a line and back as they switch), chaos cracks the glass and
-- blacks sets out, and kickless stretches leave three sets glowing in the
-- dark with a haze on the floor.
-- view 2: the kick slams the base (the tower jolts down and a shock runs
-- along the ground), snares knock blocks out of the tower to tumble and
-- land in the rubble, claps puff dust off its foot, ratchets spray debris,
-- closed hats chip a block's edge and open hats rattle the top row, ticks
-- crack blocks, perc lights a block from inside, break slices push a row
-- sideways like a jenga block. every bar a crane lowers one missing block
-- back on its cable, and on phrase edges (and fills) every block drops
-- home; the moon climbs over the phrase and the searchlights sweep with the
-- bar. LO heaves the base, MID warms the blocks, AMP the city's windows, HI
-- the stars and the edges. energy sweeps searchlights across the sky, chaos
-- sways the tower, ghosts it and knocks out more, kickless lets the lights
-- die into fog and floating dust.
-- view 3: the record turns under a fixed raking light (its grooves catch it
-- in a band, brighter with AMP and energy); the kick thumps the platter
-- and lights the strobe dots round its rim; the snare jolts the tone arm and
-- sparks at the needle; claps flash the label; closed hats crackle dust at
-- the stylus, open hats widen the sheen; break slices light their wedge of
-- the record and their pad (a reversed slice scratches it backwards); a
-- ratchet saws the record back and forth and hammers its pad; ticks skip
-- the needle; perc lights a pad; a fill is a spinback. the needle rides
-- inward over the phrase. LO swells the platter and the pitch fader, MID
-- lights the grooves' band, HI the dust and the pads' edges. energy spins
-- it up to 45, chaos warps the record and cracks it, kickless winds the
-- deck down, dims the pads and lets dust hang in the light.
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
  local rowfl                           -- the clap: a row of screens jolted
  local scp = 0                         -- the scopes' swing, eased
  local phr = 0                         -- the phrase, 0..1 (eased)

  ---------------------------------------------------------------- view 2
  local GY2 = 57                        -- the ground
  local TX, BW, RH, NR = 46, 12, 5, 9   -- tower left, block w, row h, rows
  local TW = 36
  local blocks, deb, cracks, motes
  local push, pushto
  local slam, shock, sink
  local puffs, rattle, crane            -- clap dust, open-hat rattle, the crane's block
  local MAXD = 44
  local CITY = K.profile(function(x)
    local h = 2 + floor(K.hash(x // 8, 51) * 7)
    if x > 6 and x < 18 then h = h + 8 end
    if x > 104 and x < 112 then h = h + 11 end
    return 46 - h
  end)

  ---------------------------------------------------------------- view 3
  local RX, RY, RR = 44, 32, 27         -- the record
  local GR = {}                         -- groove radii
  local NG = 6
  for k = 0, NG - 1 do GR[k] = 9.5 + k * 3.1 + K.hash(k, 101) * 0.8 end
  local PX0, PY0, PS = 90, 30, 8        -- the pad grid: left, top, pitch
  local APX, APY = 110, 9               -- the tone arm's pivot
  local rot, rspd                       -- the record's angle and speed (rad/s)
  local scr                             -- scratches: {t0, n, amp}
  local thump, armj, spark, label, sheen, wedge, wedge_t, spinb, skip
  local sheenf, rowfe = 0, {0, 0, 0}
  local pads, padd                      -- 16 pad glows, and as shown
  local NA = 7                          -- angular steps per groove

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
      tv[i] = {ch = 1 + floor(K.hash(i, 3) * NCH), glow = 0, p = 1, roll = -1, tear = 0, blk = 0, snow = 0, sw = 0, nch = nil}
    end
    rowdx, rowto = {0, 0, 0}, {0, 0, 0}
    hatf, bez, bezto, fogl = 0, 0, 0, 0
    phr = 0
    for k = #flips, 1, -1 do flips[k] = nil end
    rq, fillq = nil, {}
    build()
    deb, cracks, motes = {}, {}, {}
    push, pushto = {}, {}
    for r = 0, NR - 1 do push[r], pushto[r] = 0, 0 end
    slam, shock, sink = 0, -9, 0
    rowfl = {0, 0, 0}
    puffs, rattle, crane = {}, 0, nil
    rot, rspd, scr = 0, 3.5, nil
    thump, armj, spark, label, sheen, spinb, skip = 0, 0, 0, 0, 0, 0, 0
    wedge, wedge_t = {i = 0, n = 16, rev = false}, -9
    pads, padd = {}, {}
    for k = 1, 16 do pads[k], padd[k] = 0, 0 end
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
    -- it collapses to a line, changes channel, and opens again
    s.nch, s.sw = n, 1
    s.glow = math.max(s.glow, 0.6)
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

  local function pad(k, v)
    k = clamp(floor(K.num(k, 1)), 1, 16)
    pads[k] = math.max(pads[k], v)
  end

  local function puff(x, v)
    if #puffs >= 6 then table.remove(puffs, 1) end
    puffs[#puffs + 1] = {x = x, t0 = K.T, v = v}
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
    thump = math.max(thump, 0.6 + 0.4 * v)
    pad(13, 0.5 + 0.5 * v)
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
    armj = math.max(armj, 0.6 + 0.4 * v)
    spark = math.max(spark, v)
    pad(6, 0.6 + 0.4 * v)
  end

  function M.clap(v)
    v = K.num(v, 1)
    local r = 1 + floor(K.rnd() * 3)
    rowfl[r] = math.max(rowfl[r], 0.6 + 0.4 * v)
    flip(pick(r))
    puff(TX - 2, v); puff(TX + TW + 2, v)
    if K.rnd() < 0.5 then knock(v * 0.6, 4) end
    label = math.max(label, 0.6 + 0.4 * v)
    pad(7, 0.5 + 0.5 * v)
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    if open then
      hatf = math.max(hatf, 0.4 + 0.4 * v)
      local i = pick()
      tv[i].roll = 0
      rattle = math.max(rattle, 0.6 + 0.4 * v)
      sheen = math.max(sheen, 0.6 + 0.4 * v)
      pad(4, 0.6 * v)
    else
      hatf = math.max(hatf, 0.5 + 0.5 * v)
      local i = pick()
      tv[i].snow = math.max(tv[i].snow or 0, 0.5 + 0.5 * v)
      -- a chip off a block edge
      local b = blocks[1 + floor(K.rnd() * #blocks)]
      if b.on and b.back < 0 then
        shards(TX + b.x + push[b.r] + (K.rnd() < 0.5 and 0 or b.w), GY2 - (b.r + 0.5) * RH, 1, 18, 4)
      end
      pad(3, 0.4 * v)
    end
  end

  -- perc tunes a set to its own channel: congas / toms the scope, cowbell /
  -- metal the bars, vox the silhouette, music box / plink the countdown
  local PCH = {[1] = 4, [2] = 4, [13] = 4, [17] = 4, [3] = 2, [6] = 2, [21] = 2, [16] = 3, [8] = 6, [11] = 6}
  function M.perc(kind, v)
    v = K.num(v, 1)
    kind = floor(K.num(kind, 1))
    local i = pick()
    tv[i].glow = math.max(tv[i].glow, 0.6 * v)
    if PCH[kind] then tv[i].ch = PCH[kind] end
    local b = blocks[1 + floor(K.rnd() * #blocks)]
    b.glow = math.max(b.glow, v)
    pad(9 + kind % 4, 0.4 + 0.5 * v)
  end
  function M.tom(v) M.perc(1, v) end

  function M.tick(kind)
    local i = pick()
    tv[i].tear = 1
    if kind == 7 or kind == 3 then tv[i].ch = 1; tv[i].glow = 0.6 end
    local b = blocks[1 + floor(K.rnd() * #blocks)]
    if b.on and #cracks < 12 then cracks[#cracks + 1] = {b = b, t0 = K.T, s = floor(K.rnd() * 999)} end
    skip = math.max(skip, 0.7)
    spark = math.max(spark, 0.4)
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
    wedge = {i = (s - 1) % n, n = n, rev = rev == true}
    wedge_t = K.T
    pad((s - 1) % 16 + 1, 0.9)
    if rev then scr = {t0 = K.T, n = 1, amp = 1.2} end
  end

  function M.ratchet(n, voice)
    n = clamp(floor(K.num(n, 2)), 1, 16)
    rq = {i = pick(), n = n, next = K.NOW}
    local x = TX + 6 + K.rnd() * (TW - 12)
    local y = GY2 - 8 - K.rnd() * (NR * RH - 12)
    shards(x, y, math.min(14, n * 2), 55, 8)
    if voice == "snare" or voice == "brk" then knock(0.7) end
    scr = {t0 = K.T, n = n, amp = 1.6}
    pad(({kick = 13, snare = 6, hat = 3, tick = 16, brk = 1})[voice or ""] or 6, 1)
  end

  function M.fill()
    fillq = {}
    for i = 1, NTV do fillq[#fillq + 1] = {i = i, at = K.NOW + RANK[i] * 0.04} end
    rebuild()
    spinb = 1
  end

  function M.bar(S)
    local pl = math.max(1, floor(K.num(S and S.phrase_len, 16)))
    local pp = floor(K.num(S and S.phrase_pos, 1))
    if pp % pl == 0 then
      rebuild()
      -- the phrase opens: the whole wall retunes in a cascade
      fillq = {}
      for i = 1, NTV do fillq[#fillq + 1] = {i = i, at = K.NOW + RANK[i] * 0.11, ch = 1 + floor(K.rnd() * NCH)} end
    else
      -- a top set changes programme
      flip(pick(3))
      -- the crane lowers one missing block back
      if not crane then
        for _, b in ipairs(blocks) do
          if not b.on then
            b.on, b.back = true, K.T + 0.6
            crane = {b = b, t0 = K.T}
            break
          end
        end
      end
    end
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
    local amp = (0.25 + A[K.MID] * 0.4 + scp) * (h / 2 - 1)
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
    local rf = rowfe[ROW[i]] * 0.7
    local bl = 1.5 + s.glow * 1.8 + bez * (ROW[i] == 1 and 1.1 or 0.4) + lo * 1.2 + s.p * 0.8 + rf * 2.5
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
    if s.sw > 0 then p = p * math.abs(1 - 2 * s.sw) end
    local hh = math.max(1, floor(sh * p + 0.5))
    local yy = sy + floor((sh - hh) / 2)
    if hh <= 2 then
      line(math.min(11, 4 + 7 * (1 - p)), sx + sw * (0.5 - p * 2), yy, sx + sw * (0.5 + p * 2), yy)
      return
    end
    local g = (0.4 + 0.25 * e + lo * 0.2 + A[K.MID] * 0.3 + s.glow * 0.3) * (0.35 + 0.65 * p)
    g = g * (1 + kl * 0.25) + rf * 0.35
    local tx = 0
    if s.tear > 0.05 then tx = floor(s.tear * 4 * (K.hash(floor(K.T * 20) + i, 4) - 0.3)) end
    CH[s.ch](i, sx + tx, yy, sw, hh, math.min(0.95, g))
    if s.roll >= 0 then put(math.min(12, 3 + 4 * g), sx, yy + floor(s.roll * (hh - 1)), sw, 1) end
    -- snow (closed hats): bright specks over whatever is on
    if s.snow > 0.08 then
      local fr = floor(K.T * 12)
      for k = 0, 4 do
        local hx = K.hash(fr * 13 + k + i * 7, 17)
        local hy = K.hash(fr * 5 + k * 3 + i, 18)
        put(math.min(11, 3 + s.snow * 7), sx + hx * (sw - 2), yy + hy * (hh - 1), 2, 1)
      end
    end
    -- the vertical hold band rolling down the wall with the bar
    local vb = 4 + K.bar_ph * 58
    if vb >= yy and vb < yy + hh then put(math.min(9, 1.5 + 2.5 * g + A[K.MID] * 2), sx, floor(vb), sw, 1) end
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
        flip_now(rq.i)
        rq.n = rq.n - 1
        rq.next = rq.next + 0.055
        if rq.n <= 0 then rq = nil end
      end
    end
    for k = #fillq, 1, -1 do
      local f = fillq[k]
      if K.NOW >= f.at then tv[f.i].ch = f.ch or 6; tv[f.i].glow = 1; table.remove(fillq, k) end
    end

    local pl = math.max(1, K.num(S and S.phrase_len, 16))
    phr = K.follow(phr, clamp(K.num(S and S.phrase_pos, 0) / pl, 0, 1), 0.6, DT)
    for r = 1, 3 do rowfl[r] = rowfl[r] * math.exp(-DT / 0.16) end
    scp = K.follow(scp, math.min(0.6, K.env.snare * 0.35 + K.env.kick * 0.3), 0.07, DT)
    -- how many sets are on (more as the phrase goes on)
    local non = (5 + e * 8 + phr * 3) * (1 - kl) + 3 * kl
    for i = 1, NTV do
      local s = tv[i]
      local dead = K.hash(i, 71) < (c - 0.4) * 0.75
      local want = (RANK[i] <= non and not dead and s.blk <= 0) and 1 or 0
      s.p = K.follow(s.p, want, want > s.p and 0.12 or 0.08, DT)
      if math.abs(s.p - want) < 0.01 then s.p = want end
      s.glow = s.glow * math.exp(-DT / 0.18)
      s.tear = s.tear * math.exp(-DT / 0.12)
      s.snow = s.snow * math.exp(-DT / 0.1)
      if s.sw > 0 then
        s.sw = math.max(0, s.sw - DT / 0.18)
        if s.sw < 0.5 and s.nch then s.ch, s.nch = s.nch, nil end
      end
      s.blk = s.blk - DT
      if s.roll >= 0 then
        s.roll = s.roll + DT * 2.2
        if s.roll > 1 then s.roll = -1 end
      end
    end
    -- (a row steps only between hits, so its jump never lands on one)
    local hold = K.env.kick > 0.45 or K.env.snare > 0.45 or K.env.clap > 0.45
    local moved = false
    for r = 1, 3 do
      rowto[r] = rowto[r] * math.exp(-DT / 0.3)
      local to = floor(rowto[r] + 0.5)
      if not moved and not hold and to ~= rowdx[r] then
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
    rattle = rattle * math.exp(-DT / 0.2)
    local drop = sink > 0.35 and 1 or 0
    local pl = math.max(1, K.num(S and S.phrase_len, 16))
    phr = K.follow(phr, clamp(K.num(S and S.phrase_pos, 0) / pl, 0, 1), 0.6, DT)

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
    -- the moon climbs over the phrase
    local my = 16 - phr * 9
    K.disc(3 + kl * 2 + A[K.AMP], 104, my, 3.5)
    K.ring(1.5 + hi, 104, my, 6, 12)
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
        local a = -math.pi / 2 + math.sin(K.bar_ph * K.TAU * (k == 0 and 1 or -1) + k * 2 + T * 0.1) * 0.6
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
        if b.r >= NR - 2 and rattle > 0.15 then x = x + floor(math.sin(T * 9 + b.seed) * rattle * 1.6 + 0.5) end
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

    -- the crane: a jib off the top of the screen, its cable lowering a block
    if crane then
      local u = (T - crane.t0) / 1.4
      if u >= 1 then crane = nil
      else
        local b = crane.b
        local x = TX + b.x + push[b.r] + lean(b.r) + b.w / 2
        local ty = GY2 - (b.r + 1) * RH
        local by
        if T < b.back then by = ty - 14 - 12 * (1 - K.ease((T - crane.t0) / 0.6))
        else by = ty - floor((1 - K.ease(math.min(1, (T - b.back) / 0.5))) * 14) end
        local cl = 2.5 * math.sin(math.pi * u) + mid
        line(cl, x, 0, x, by)
        line(cl, x - 2, by, x + 2, by)
        if T < b.back then rbox(3 + hi, x, by + RH / 2 + 1, b.w, RH, math.sin(T * 3) * 0.08) end
      end
    end
    -- dust puffs off the foot (claps)
    for k = #puffs, 1, -1 do
      local P = puffs[k]
      local u = (T - P.t0) / 0.9
      if u >= 1 then table.remove(puffs, k)
      else
        local r = 2 + u * 9
        K.ring((2 + 4 * P.v) * (1 - u), P.x, GY2 - 1 - r * 0.3, r, 8, math.pi, K.TAU, 0.6, 1, k)
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

  ---------------------------------------------------------------- view 3 draw
  local LA = -2.35                      -- where the raking light catches the grooves

  local function draw3(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl, mid, amp = A[K.LO], A[K.HI], K.kickless, A[K.MID], A[K.AMP]
    local pl = math.max(1, K.num(S and S.phrase_len, 16))
    phr = K.follow(phr, clamp(K.num(S and S.phrase_pos, 0) / pl, 0, 1), 0.6, DT)

    -- the deck turns: 33 up to 45 with energy, winding down when kickless;
    -- a fill spins it back, a ratchet saws it, a tick skips it
    local want = (3.46 + e * 1.25) * (1 - kl * 0.65)
    rspd = K.follow(rspd, want, 0.8, DT)
    rot = (rot + DT * (rspd * (1 - spinb) - 9 * spinb * spinb)) % K.TAU
    local ang = rot + skip * 0.5
    if scr then
      local age = T - scr.t0
      local dur = 0.2 + 0.07 * scr.n
      if age > dur then scr = nil
      else ang = ang + scr.amp * math.sin(age / dur * math.pi * math.min(8, scr.n + 1)) * (1 - age / dur) * 0.5 end
    end
    -- chaos warps the record: its centre swims and it squashes as it turns
    local cx = RX + c * 1.4 * math.sin(rot)
    local cy = RY + c * 0.8 * math.cos(rot * 2)
    local sq = 1 - c * 0.06 * (1 + math.sin(rot * 2))
    local bump = thump * 0.8 + lo * 0.6

    -- the plinth: its edge, the dust cover's hinges, the light falling across
    line(1.2 + amp, 2, 1, 2, 62)
    line(1, 125, 1, 125, 62)
    for k = 0, 3 do put(1 + amp, 4 + k * 32 + (k > 1 and 12 or 0), 62, 3, 1) end
    put(1.5, 30, 0, 6, 1); put(1.5, 92, 0, 6, 1)

    -- the platter rim and its strobe dots (the kick lights them)
    K.ring(1.1 + lo * 0.7 + thump * 1.2, cx, cy, RR + 2 + bump, 24, 0, K.TAU, sq)
    local drift = T * (0.12 + (e - 0.4) * 0.4)
    for j = 0, 23 do
      local a = j * K.TAU / 24 + drift
      local d = 1.2 + thump * 5 * (0.6 + 0.4 * math.cos(a - LA)) + lo * 1 + (j % 2) * 0.5
      put(math.min(11, d), cx + math.cos(a) * (RR + 4 + bump), cy + math.sin(a) * (RR + 4 + bump) * sq, 1, 1)
    end

    -- the grooves: dim rings, and two bands where the light catches them
    local band = 0.2 + sheenf * 0.25 + e * 0.08 + mid * 0.08
    local bl = 2.5 + amp * 1.5 + e + mid + sheenf * 2
    for k = 0, NG - 1 do
      local r = GR[k]
      -- the dim groove: broken where the pressing is worn, turning with it
      local gl = 0.8 + K.hash(k, 102) * 0.6 + kl * 0.3
      for j = 0, 5 do
        local a0 = ang + j * K.TAU / 6 + K.hash(k * 7 + j, 109) * 0.4
        K.ring(gl, cx, cy, r, 3, a0, a0 + 0.75, sq)
      end
      local bk = bl * (k % 2 == 0 and 1 or 0.45) * (0.75 + 0.25 * K.hash(k, 103))
      K.ring(bk, cx, cy, r, 3, LA - band, LA + band, sq)
      K.ring(bk * 0.5, cx, cy, r, 3, LA + math.pi - band * 0.7, LA + math.pi + band * 0.7, sq)
    end

    -- the slice's wedge, lit where the break is
    local wu = (T - wedge_t) / 0.45
    if wu < 1 and wedge.n > 0 then
      local a0 = ang + wedge.i / wedge.n * K.TAU
      local a1 = a0 + K.TAU / wedge.n
      local wl = ((wedge.rev and 3.5 or 4.5) * (1 - wu) + 1) * math.min(1, wu * 5 + 0.3)
      for _, a in ipairs({a0, a1}) do
        line(wl, cx + math.cos(a) * 9, cy + math.sin(a) * 9 * sq, cx + math.cos(a) * RR, cy + math.sin(a) * RR * sq)
      end
      for k = 1, NG - 1, 2 do K.ring(wl * 0.7, cx, cy, GR[k], 3, a0, a1, sq) end
    end

    -- the record's own marks, turning with it: dust, a scuff, cracks (chaos)
    for k = 0, 9 do
      local a = ang + K.hash(k, 104) * K.TAU
      local r = 10 + K.hash(k, 105) * 18
      local lit = math.max(0, math.cos(a - LA))
      put(1 + hi * 3 + lit * lit * (2 + hi * 4 + sheenf * 3), cx + math.cos(a) * r, cy + math.sin(a) * r * sq, 1, 1)
    end
    do
      local a = ang + 1.1
      line(1.5 + mid * 1.5, cx + math.cos(a) * 15, cy + math.sin(a) * 15 * sq,
        cx + math.cos(a + 0.18) * 22, cy + math.sin(a + 0.18) * 22 * sq)
    end
    if c > 0.45 then
      local nc = 1 + floor((c - 0.45) * 5)
      for k = 1, nc do
        local a = ang + K.hash(k, 106) * K.TAU
        local px, py = cx + math.cos(a) * 9, cy + math.sin(a) * 9 * sq
        for j = 1, 3 do
          local r = 9 + j * 6.5
          local aj = a + (K.hash(k * 5 + j, 107) - 0.5) * 0.25
          local x, y = cx + math.cos(aj) * r, cy + math.sin(aj) * r * sq
          line(2 + (c - 0.45) * 7, px, py, x, y)
          px, py = x, y
        end
      end
    end

    -- the label: claps flash it, its print turns with the record
    local ll = 2 + label * 6 + kl * 0.8
    K.disc(1.2 + label * 2.5 + amp * 0.6, cx, cy, 6)
    K.ring(ll, cx, cy, 7, 14, 0, K.TAU, sq)
    for k = 0, 1 do
      local a = ang + k * math.pi
      line(3 + label * 5 + mid, cx + math.cos(a) * 2.5, cy + math.sin(a) * 2.5, cx + math.cos(a + 0.7) * 5, cy + math.sin(a + 0.7) * 5)
    end
    put(7, cx - 1, cy - 1, 2, 2)
    if kl > 0.05 then K.haze(14, 3, 76, 62, kl * 0.35, 1, T * 2) end

    -- the tone arm: the needle rides inward over the phrase; the snare
    -- jolts it, a tick skips it
    local rn = RR - 3 - phr * (RR - 13)
    local psi = -0.25 + (1 - rn / RR) * 0.55
    local jx = armj * 2 * math.sin(T * 7) + skip * 1.5
    local nx = cx + math.cos(psi) * rn + jx
    local ny = cy + math.sin(psi) * rn * sq - armj * 1.5
    local ex, ey = nx + 9, ny - 8
    local al = 3 + mid * 2 + armj * 4
    K.disc(2 + lo, APX, APY, 3.5)
    K.ring(3 + mid * 2, APX, APY, 5, 12)
    put(2.5 + amp * 2, APX + 5, APY - 7, 7, 4)
    line(al, APX, APY, ex, ey)
    line(al + 1, ex, ey, nx, ny)
    put(math.min(11, 4 + armj * 5), nx - 1, ny - 1, 3, 2)
    if spark > 0.08 then
      local sl = math.min(12, 2 + spark * 9)
      put(sl, nx - 1, ny + 1, 2, 2)
      for k = 0, 2 do
        local a = -0.5 + k * 1.1 + K.hash(floor(T * 10) + k, 108)
        line(sl * 0.6, nx, ny + 1, nx + math.cos(a) * (2 + spark * 4), ny + 1 + math.sin(a) * (2 + spark * 4))
      end
    end
    -- the stylus crackles: dust in the groove (closed hats, HI)
    K.grain(function(u, v) return nx - 6 + u * 10, ny - 3 + v * 8 end, 2 + hi * 8 + hatf * 25, 4 + hi * 4)

    -- the right-hand side: speed buttons, the level meter, the pads, the pitch fader
    put(e > 0.5 and 5 or 2, 90, 21, 6, 2)
    put(e > 0.5 and 2 or 5, 98, 21, 6, 2)
    put(1.5 + kl * 3, 106, 21, 3, 2)
    local nm = amp * 8
    for k = 0, 7 do
      local u = clamp(nm - k, 0, 1)
      put(1 + u * (1.5 + k * 0.5), 90 + k * 4, 25, 3, 1)
    end
    local step = floor(K.bar_ph * 16) % 16 + 1
    local pd = 1 - kl * 0.4
    for r = 0, 3 do
      for cc = 0, 3 do
        local k = r * 4 + cc + 1
        local x, y = PX0 + cc * PS, PY0 + r * PS
        padd[k] = K.follow(padd[k], pads[k], 0.04, DT)
        local g = padd[k]
        -- a rubber pad: dim at rest, its edge catching the highs, lit when hit
        local f = (1 + g * 9 + (k == step and 1 + lo * 1.2 or 0)) * pd
        put(math.min(11, f), x + 1, y + 1, 5, 5)
        put(1 + hi * 1.2 + g * 2, x + 1, y, 5, 1)
      end
    end
    line(1.2, 125, 30, 125, 61)
    local fy = 54 - lo * 14 - e * 4
    put(3 + lo * 5, 123, fy, 5, 2)
    for k = 0, 5 do put(1, 122, 32 + k * 5, 1, 1) end
  end

  function M.draw(S)
    bezto = bezto * math.exp(-K.DT / 0.12)
    bez = K.follow(bez, bezto, 0.04, K.DT)
    hatf = hatf * math.exp(-K.DT / 0.08)
    local DT = K.DT
    thump = thump * math.exp(-DT / 0.14)
    armj = armj * math.exp(-DT / 0.2)
    spark = spark * math.exp(-DT / 0.12)
    label = label * math.exp(-DT / 0.18)
    sheen = sheen * math.exp(-DT / 0.35)
    sheenf = K.follow(sheenf, sheen, 0.12, DT)
    for r = 1, 3 do rowfe[r] = K.follow(rowfe[r], rowfl[r], 0.07, DT) end
    spinb = spinb * math.exp(-DT / 0.5)
    skip = skip * math.exp(-DT / 0.15)
    for k = 1, 16 do pads[k] = pads[k] * math.exp(-DT / 0.2) end
    if K.view == 2 then draw2(S) elseif K.view == 3 then draw3(S) else draw1(S) end
  end

  M.init()
  return M
end
