-- syro: view 1, a dense machine readout: eight voice lanes of envelope history scrolling left past a playhead, with live readouts and meters; view 2, a polar radar clock face: one ring per voice, hits marked at their angle in the bar, the sweep arm is the playhead; view 3, a tracker pattern beside a spectral waterfall: every eighth of the groove a ridge of the spectrum, sliding back toward the horizon.
--
-- view 1: each voice is a lane (BD SD CP HH OH PC TK BR). every hit draws
-- an envelope (a bar as tall as its velocity, with a decay tail as long as
-- the voice rings) at the playhead, and the lane scrolls it away, dimming
-- slowly, so the screen fills with the last bar and a half of the groove.
-- each voice has its own mark: the kick a wide block that washes its lane,
-- the snare a block with a tail, claps a split double stroke, closed hats a
-- tick, open hats a long ringing tail, the ride a dotted one, percussion by
-- kind (drums a bar, metal a hollow bar under a spark, acid and wobble a
-- zigzag, the rest a small block), ticks a pin, break slices a bar as tall
-- as the slice. a ratchet lands as a burst of spikes and its count (x6)
-- flashes in the lane's readout; a fill hatches across every lane. bar
-- lines run through the history, the phrase's first bar doubled. the
-- header counts the step, the bar, the tempo, energy and chaos and the
-- phrase; a digit that changes lights up and settles. the right column
-- shows each lane's last velocity and a peak-hold meter; the floor strip is
-- a scope of the output. energy fills the noise floor, keeps the history
-- brighter for longer and thickens the carriers; chaos shears the lanes,
-- throws ghost copies of the hits and scrambles digits; kickless, the kick
-- lane goes to a dashed standby line with a slow sine idling under it.
-- view 2: the same voices as eight rings of a radar over a range grid.
-- hits mark their ring at the angle they fell in the bar (each voice its
-- own mark: arcs, ticks, pins, double arcs) and glow on as phosphor,
-- re-lit when the arm sweeps over them; the kick throbs the centre and
-- sends a shock ring out; ratchets are radial bursts; a fill spins the
-- rings. an outer arc fills through the phrase, a tick per bar. side
-- panels read out each voice's last step, the tempo, the bar and the bands.
-- energy lengthens the phosphor and the arm's trail, chaos wobbles the
-- rings and splits the arm into ghosts; kickless, the centre idles and the
-- rings drift apart.
-- view 3: on the left a tracker pattern, the cursor row fixed in the middle,
-- each row a step number and eight cells lit by what played; the rows
-- below the cursor are the same steps one bar back, dim, as a memory of
-- what is coming. on the right a spectral waterfall in perspective: every
-- eighth the live spectrum (the four bands with a bump for each voice that
-- played: the kick a wide hill at the low end, the snare and clap in the
-- middle, percussion placed by its kind, hats thin spikes at the top, a
-- ratchet a comb) is laid down as a ridge and slides back to the horizon,
-- the downbeats brighter, a fill lifting the whole ridge. the horizon fills
-- through the phrase. energy raises the ridges and keeps them bright
-- further back, chaos tears and offsets them; kickless, the waterfall
-- sways and the low end idles on a slow wave.
--
-- the ears: view 1, the lows throb the playhead and the kick lane, the
-- mids carry the body lanes' carriers, the highs the hat and tick lanes,
-- the level lights the rail, the backlight and the scope; view 2, the
-- lows swell the centre, the mids and highs light their rings, the level
-- the clock face and the grid; view 3, the live ridge is the four bands
-- (lows at the left, mids, highs at the right), the level lights the
-- horizon glow and the floor lines, the highs glitter on the ridges.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local floor, exp, sin, cos, max, min = math.floor, math.exp, math.sin, math.cos, math.max, math.min

  local NR = 8
  local LY0, LH = 8, 6                  -- lanes: first top, pitch
  local X0, X1 = 9, 94                  -- history span; X1 is the playhead
  local PXS = 2                         -- px per 16th
  local PX = 100                        -- readout column
  local MAXE = 28                       -- events kept per lane

  local FONT = {
    ["0"] = {7, 5, 5, 5, 7}, ["1"] = {2, 6, 2, 2, 7}, ["2"] = {7, 1, 7, 4, 7}, ["3"] = {7, 1, 3, 1, 7},
    ["4"] = {5, 5, 7, 1, 1}, ["5"] = {7, 4, 7, 1, 7}, ["6"] = {7, 4, 7, 5, 7}, ["7"] = {7, 1, 2, 2, 2},
    ["8"] = {7, 5, 7, 5, 7}, ["9"] = {7, 5, 7, 1, 7}, ["-"] = {0, 0, 7, 0, 0}, [":"] = {0, 2, 0, 2, 0},
    ["#"] = {5, 7, 5, 7, 5}, ["."] = {0, 0, 0, 0, 2}, ["x"] = {0, 5, 2, 5, 0},
    A = {7, 5, 7, 5, 5}, F = {7, 4, 6, 4, 4},
    B = {6, 5, 6, 5, 6}, D = {6, 5, 5, 5, 6}, S = {3, 4, 2, 1, 6}, C = {7, 4, 4, 4, 7},
    P = {7, 5, 7, 4, 4}, H = {5, 5, 7, 5, 5}, O = {7, 5, 5, 5, 7}, K = {5, 5, 6, 5, 5},
    T = {7, 2, 2, 2, 2}, R = {6, 5, 6, 5, 5}, E = {7, 4, 6, 4, 7}, X = {5, 5, 2, 5, 5},
  }
  local HEX = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
  local SCRAM = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "#", "-"}
  local LABEL = {"BD", "SD", "CP", "HH", "OH", "PC", "TK", "BR"}
  local WID = {3, 2, 2, 1, 1, 2, 1, 2}           -- envelope bar width per lane
  local TAIL = {7, 4, 3, 0, 9, 3, 0, 2}         -- decay tail (px)
  local ETAU = {0.2, 0.15, 0.12, 0.05, 0.25, 0.1, 0.04, 0.08}
  local VROW = {kick = 1, snare = 2, clap = 3, hat = 4, hats = 4, ride = 5, perc = 6, tom = 6,
    tick = 7, ticks = 7, brk = 8}
  -- percussion kinds by shape: 1 drum, 2 metal, 3 acid / wobble, 4 other
  local PSHAPE = {1, 1, 2, 2, 3, 2, 1, 4, 4, 2, 4, 4, 1, 3, 4, 4, 1, 1, 4, 1, 2}

  -- view 3: the waterfall's spectrum
  local NB = 24                          -- bins across a ridge
  local NROW = 8                         -- ridges kept
  local RSTEP = 4                        -- 16ths per ridge
  local VB = {0.07, 0.40, 0.50, 0.84, 0.91, 0.62, 0.97, 0.24}   -- each voice's place
  local VW = {0.08, 0.05, 0.035, 0.012, 0.035, 0.025, 0.01, 0.05} -- and its width
  local GTAB = {}                        -- [r][b]: the voice's bump at bin b
  for r = 1, NR do
    GTAB[r] = {}
    for b = 0, NB - 1 do
      local u = b / (NB - 1)
      local d = (u - VB[r]) / VW[r]
      GTAB[r][b] = exp(-d * d * 0.5)
    end
  end

  local lanes, bursts, lenv, lpeak, lastv, lastst
  local pos, glyph_t, shear, scope, sc_i, sc_acc
  local fld, arm_ph, kick_t, fills, shock, spin
  local jcur = {}
  -- view 3 state
  local ridges, live, acc, accb, acck, accr, accf, rcount, wf_idle, pat

  local function newrow()
    local p = {}
    for b = 0, NB - 1 do p[b] = 0 end
    return p
  end

  function M.init()
    lanes, bursts, lenv, lpeak, lastv, lastst, shear = {}, {}, {}, {}, {}, {}, {}
    for r = 1, NR do
      lanes[r], bursts[r], lenv[r], lpeak[r], lastv[r], lastst[r], shear[r] = {}, nil, 0, 0, 0, 0, 0
    end
    pos, glyph_t = 0, 0
    scope, sc_i, sc_acc = {}, 0, 0
    for i = 0, 43 do scope[i] = 0 end
    fld = {}
    arm_ph, kick_t = 0, -9
    fills, shock, spin = {}, {}, 0
    for r = 1, NR do jcur[r] = 0 end
    ridges = {}
    live = newrow()
    acc, accb = {}, {0, 0, 0, 0}
    for r = 1, NR do acc[r] = 0 end
    acck, accr, accf = 0, 0, 0
    rcount, wf_idle = 0, 0
    -- the pattern page: [slot][voice] = {v, bar it was played in}
    pat = {}
    for s = 0, 15 do
      pat[s] = {}
      for r = 1, NR do pat[s][r] = {0, -9} end
    end
  end
  M.clear = M.init

  local function mark(r, v, n, kind, ride)
    v = clamp(K.num(v, 1), 0, 1)
    local L = lanes[r]
    local Bu = bursts[r]
    lenv[r] = max(lenv[r], 0.35 + 0.65 * v)
    lpeak[r] = max(lpeak[r], lenv[r])
    lastv[r] = v
    lastst[r] = floor(K.num(K.step, 0)) % 16
    acc[r] = max(acc[r], v)
    local idx = floor(K.num(K.stepf, 0) + 0.6)
    local cell = pat[idx % 16][r]
    if cell[2] ~= idx // 16 then cell[1] = 0 end
    cell[1], cell[2] = max(cell[1], v), idx // 16
    if kind then acck = kind end
    -- the repeats of a ratchet already drawn as its burst
    if n and n > 1 and Bu and K.T - Bu.t < 0.4 then return end
    if #L >= MAXE then table.remove(L, 1) end
    L[#L + 1] = {p = pos, v = v, t = K.T, ph = K.bar_ph, k = kind, ride = ride}
  end

  function M.kick(v)
    mark(1, v); kick_t = K.T
    if #shock < 4 then shock[#shock + 1] = K.T end
  end
  function M.snare(v, n) mark(2, v, K.num(n, 1)) end
  function M.clap(v) mark(3, v) end
  function M.rim(v) mark(3, K.num(v, 1) * 0.6) end
  function M.hat(v, open) if open then mark(5, v) else mark(4, v) end end
  function M.ride(v) mark(5, K.num(v, 1) * 0.7, nil, nil, true) end
  function M.shaker(v) mark(4, K.num(v, 1) * 0.5) end
  function M.perc(k, v) mark(6, v, nil, clamp(floor(K.num(k, 1)), 1, 21)) end
  function M.tom(v) mark(6, v, nil, 1) end
  function M.tick(k) mark(7, 0.4 + 0.1 * clamp(K.num(k, 1), 1, 8)) end
  function M.brk(i, n) mark(8, 0.4 + 0.6 * clamp(K.num(i, 1) / max(1, K.num(n, 8)), 0, 1)) end
  function M.fill()
    for r = 1, NR do lpeak[r] = max(lpeak[r], 0.6) end
    if #fills >= 3 then table.remove(fills, 1) end
    fills[#fills + 1] = {p = pos, t = K.T}
    spin = 1
    accf = 1
  end

  function M.ratchet(n, voice)
    n = clamp(floor(K.num(n, 2)), 2, 12)
    local r = VROW[voice] or 2
    bursts[r] = {p = pos, n = n, t = K.T, ph = K.bar_ph}
    lenv[r], lpeak[r] = 1, 1
    accr = n
    for q = 1, NR do shear[q] = shear[q] + (K.rnd() - 0.5) * (2 + 8 * K.chaos) end
  end

  -- one glyph of the 3x5 font, as a few rects (greedy cover, cached)
  local RECTS = {}
  local function rects(ch)
    local R = RECTS[ch]
    if R then return R end
    local g = FONT[ch]
    R = {}
    if g then
      local lit, done = {}, {}
      for r = 1, 5 do for b = 0, 2 do lit[r * 3 + b] = ((g[r] >> (2 - b)) & 1) == 1 end end
      for r = 1, 5 do
        for b = 0, 2 do
          if lit[r * 3 + b] and not done[r * 3 + b] then
            local w = 1
            while b + w <= 2 and lit[r * 3 + b + w] and not done[r * 3 + b + w] do w = w + 1 end
            local h = 1
            local ok = true
            while ok and r + h <= 5 do
              for q = 0, w - 1 do if not lit[(r + h) * 3 + b + q] or done[(r + h) * 3 + b + q] then ok = false end end
              if ok then h = h + 1 end
            end
            -- a lone pixel heading a column: prefer the column
            if w == 1 and h == 1 then
              local v = 1
              while r + v <= 5 and lit[(r + v) * 3 + b] and not done[(r + v) * 3 + b] do v = v + 1 end
              h = v
            end
            for yy = 0, h - 1 do for q = 0, w - 1 do done[(r + yy) * 3 + b + q] = true end end
            R[#R + 1] = {b, r - 1, w, h}
          end
        end
      end
    end
    RECTS[ch] = R
    return R
  end
  local function glyph(lv, x, y, ch)
    local R = rects(ch)
    for i = 1, #R do
      local q = R[i]
      put(lv, x + q[1], y + q[2], q[3], q[4])
    end
  end

  local function scram(ch, i, x, y, sc)
    if sc > 0 and ch:match("%d") and K.hash(i * 13 + x * 3 + floor(glyph_t * 9) * 7, y) < sc then
      return SCRAM[1 + floor(K.hash(i + floor(glyph_t * 11), x + y) * #SCRAM)]
    end
    return ch
  end

  local function text(lv, x, y, str, sc)
    for i = 1, #str do glyph(lv, x + (i - 1) * 4, y, scram(str:sub(i, i), i, x, y, sc or 0)) end
  end

  -- a field whose changed digits light up and settle
  local function field(key, lv, x, y, str, sc)
    local F = fld[key]
    if not F then F = {s = str, tc = {}}; fld[key] = F end
    for i = 1, #str do
      if F.s:sub(i, i) ~= str:sub(i, i) then F.tc[i] = K.T end
    end
    F.s = str
    for i = 1, #str do
      local fl = F.tc[i] and exp(-(K.T - F.tc[i]) / 0.18) or 0
      glyph(lv + fl * 6, x + (i - 1) * 4, y, scram(str:sub(i, i), i, x, y, sc or 0))
    end
  end

  local function pad(v, n)
    v = floor(K.num(v, 0))
    if v < 0 then v = 0 end
    local s = tostring(v % floor(10 ^ n))
    while #s < n do s = "0" .. s end
    return s
  end

  local function band(r)
    if r == 1 then return A[K.LO] elseif r == 2 or r == 3 or r == 6 or r == 8 then return A[K.MID] * 0.9 end
    return A[K.HI]
  end

  local function phrase(S)
    local pl = max(1, K.num(S.phrase_len, 16))
    return clamp((K.num(S.phrase_pos, 0) + K.bar_ph) / pl, 0, 1), pl
  end

  ----------------------------------------------------------------------
  -- view 1: the lanes
  ----------------------------------------------------------------------
  -- one hit's mark at x (sub-pixel f), by the lane's voice
  local function hitmark(r, E, x, f, by, h, lv, near)
    local w = WID[r]
    if r == 6 and E.k and PSHAPE[E.k] ~= 1 then
      local sh = PSHAPE[E.k]
      if sh == 2 then
        put(lv, x, by - h + 1, 1, 1); put(lv * 0.6, x, by, 1, 1)
        if h > 2 then put(lv * 0.5, x + 1, by - h + 1, 1, h) end
        put(lv + 2, x, by - h - 1, 1, 1)
      elseif sh == 3 then
        line(lv, x, by, x + 1, by - h + 1); line(lv, x + 1, by - h + 1, x + 2, by); line(lv * 0.7, x + 2, by, x + 3, by - h + 2)
      else
        put(lv, x, by - 1, 2, 2)
      end
      return
    end
    if r == 3 then
      put(lv, x, by - h + 1, 1, h); put(lv * 0.7, x + 2, by - h + 2, 1, max(1, h - 1))
      return
    end
    if r == 7 then
      put(lv, x, by - h + 1, 1, h); put(lv + 2, x, by - h, 1, 1)
      return
    end
    if near then
      put(lv * (1 - f), x, by - h + 1, 1, h)
      if w > 1 then put(lv, x + 1, by - h + 1, w - 1, h) end
      if x + w <= X1 + 1 then put(lv * f, x + w, by - h + 1, 1, h) end
    else
      put(lv, x, by - h + 1, w, h)
    end
    local tl = TAIL[r]
    if tl > 0 and h > 1 and x + w + tl <= X1 + 3 then
      if E.ride then
        for q = 1, tl, 2 do put(lv * 0.45, x + w + q, by - h + 1 + floor(q * (h - 1) / tl), 1, 1) end
      else
        line(lv * 0.45, x + w, by - h + 1, x + w + tl, by)
      end
    end
  end

  local fc = 0
  local function draw_lanes(S)
    fc = fc + 1
    local T, e, c = K.T, K.energy, K.chaos
    local amp, lo, hi = A[K.AMP], A[K.LO], A[K.HI]
    local sc = c * c * 0.8
    local scroll = pos * PXS
    local pers = 5 + e * 7
    local sub = scroll % 4
    local base = floor(scroll / 4)
    local ph, pl = phrase(S)

    -- the backlight: a glow behind the newest history, breathing with the level
    local bl = 0.3 + amp * 1.0 + K.duck * 0.4 + e * 0.3
    put(bl, X1 - 3, LY0, 3, NR * LH - 1)
    put(bl * 0.6, X1 - 8, LY0, 5, NR * LH - 1)

    -- bar lines and beat ticks through the history; the phrase's first bar doubled
    local first = floor(pos / 4) * 4
    local bar0 = K.num(S.bar, 0)
    for q = 0, 6 do
      local p = first - q * 4
      local x = floor(X1 - (pos - p) * PXS + 0.5)
      if x >= X0 and x <= X1 then
        if p % 16 == 0 then
          line(1.5 + K.bar_pulse * 2, x, LY0, x, LY0 + NR * LH - 2)
          local bn = floor(bar0 - (first - p) / 16)
          if bn % floor(pl) == 0 and x - 2 >= X0 then line(1.2 + e, x - 2, LY0, x - 2, LY0 + NR * LH - 2) end
        else put(2, x, 57, 1, 1) end
        put(p % 16 == 0 and 4 or 2, x, 7, 1, 1)
      end
    end

    for r = 1, NR do
      local by = LY0 + r * LH - 1
      local bnd = band(r)
      local dead = r == 1 and K.kickless > 0.5
      local jig = 0
      if c > 0.5 then
        jig = (K.hash(r * 31 + floor(pos / 4), 9) - 0.5) * (c - 0.5) * 12
      end
      -- the lane slides toward its sheared place a pixel a frame
      local to = floor(shear[r] + jig + 0.5)
      -- (the lanes take turns, so a shear ripples down the readout)
      if (fc + r) % 3 == 0 then
        if to > jcur[r] then jcur[r] = jcur[r] + 1 elseif to < jcur[r] then jcur[r] = jcur[r] - 1 end
      end
      local sh = jcur[r]
      -- the label
      text((dead and 1 or 1.5) + lenv[r] * 2.5 + bnd * 1.5, 0, by - 4, LABEL[r], 0)
      -- the noise floor: a scrolling dotted baseline, busier with energy
      for j = 0, 21 do
        local x = floor(X1 - j * 4 - sub + sh + 0.5)
        if x >= X0 and x <= X1 then
          local id = (base - j) * 8 + r
          local hh = K.hash(id, 3)
          if hh > 0.93 - e * 0.3 - bnd * 0.15 then put(1.2 + bnd + e, x, by - 1, 1, 1)
          elseif hh > 0.6 - e * 0.2 then put(1 + bnd * 1.5, x, by, 1, 1) end
        end
      end
      do
        local sx = X1 - floor((T * 24 + r * 9) % (X1 - X0))
        put(2 + bnd * 2, sx, by, 2, 1)
      end
      -- the lane's carrier: a dashed trace scrolling with the history, lit
      -- by the band this voice lives in (lo kick, mid body, hi air)
      if bnd > 0.04 then
        local cw = floor(8 + e * 12)
        local cx = X0 + floor((K.hash(r, 17) * 80 - scroll) % (X1 - X0 - cw))
        put(bnd * 4.5, cx, by - 2, cw, 1)
        put(bnd * 2, cx - 6, by - 2, 5, 1)
      end
      if r == 1 then
        -- the kick washes its lane near the playhead
        local kw = K.env.kick * (1 - K.kickless)
        if kw > 0.1 then put(kw * 2 + lo * 0.5, X1 - 9 + sh, by - 4, 9, 5) end
      end
      if dead then
        local off = floor(T * 6) % 4
        for x = X0 + off, X1, 4 do put(1.5, x, by - 2, 2, 1) end
        -- the idle: a slow sine running under the standby line
        local px, py
        for k = 0, 10 do
          local x = X0 + k * (X1 - X0) / 10
          local y = by - 2 + sin(x * 0.12 - T * 1.5) * 1.6 * K.kickless
          if px then line(1 + lo * 2, px, py, x, y) end
          px, py = x, y
        end
      end
      -- the envelopes
      local L = lanes[r]
      while #L > 0 and X1 - (pos - L[1].p) * PXS < X0 - 14 do table.remove(L, 1) end
      for i = 1, #L do
        local E = L[i]
        local d = pos - E.p
        local xf = X1 - d * PXS + sh
        local x = floor(xf)
        local f = xf - x
        local h = clamp(1 + floor(E.v * 4.5), 1, 5)
        local fresh = max(0, 1 - (T - E.t) / 0.12)
        local lv = (1.5 + 6 * E.v) * (0.15 + 0.85 * exp(-d / pers)) * (0.75 + 0.35 * e) + fresh * 3 + bnd * 0.7
        if x >= X0 then hitmark(r, E, x, f, by, h, lv, d < 20) end
        -- chaos: ghost copies thrown ahead of the hit
        if c > 0.3 and i > #L - 6 then
          local gx = x + floor((K.hash(i + r * 40, floor(E.p)) - 0.5) * 20 * c)
          if gx >= X0 and gx <= X1 then put(lv * 0.35 * c, gx, by - h + 2, 1, max(1, h - 1)) end
        end
      end
      -- the burst of a ratchet: n spikes ending at the hit
      local Bu = bursts[r]
      if Bu then
        local d = pos - Bu.p
        local x = floor(X1 - d * PXS + sh + 0.5)
        if x < X0 - 2 * Bu.n then bursts[r] = nil
        else
          local fresh = max(0, 1 - (T - Bu.t) / 0.25)
          local lv = (5 + 4 * exp(-d / pers)) + fresh * 3
          for q = 0, Bu.n - 1 do
            local xx = x - (Bu.n - 1 - q) * 2
            if xx >= X0 then put(lv * (0.7 + 0.3 * q / Bu.n), xx, by - (q % 2 == 0 and 4 or 2), 1, q % 2 == 0 and 5 or 3) end
          end
          if fresh > 0 then line(2 + fresh * 4, x - 2 * Bu.n + 1, by - 5, x + 1, by - 5) end
        end
      end
      -- the playhead LED, the readout and the peak-hold meter
      put(1 + lenv[r] * 10, X1 + 2, by - 4, 2, 5)
      local Bu2 = bursts[r]
      if Bu2 and T - Bu2.t < 0.6 then
        text(4 + 6 * (1 - (T - Bu2.t) / 0.6), PX, by - 4, "x" .. (Bu2.n % 10), 0)
      elseif dead then
        text(1.5, PX, by - 4, "--", 0)
      else
        text(1.5 + lenv[r] * 4, PX, by - 4, pad(lastv[r] * 99, 2), sc)
      end
      local mw = floor(lenv[r] * 16 + bnd * 3 + 0.5)
      if mw > 0 then put(2 + lenv[r] * 3, PX + 9, by - 2, mw, 2) end
      put(1, PX + 9, by, 18, 1)
      put(2 + lpeak[r] * 4, PX + 9 + floor(lpeak[r] * 17), by - 3, 1, 3)
    end
    -- a fill hatches across every lane
    for i = #fills, 1, -1 do
      local F = fills[i]
      local x = floor(X1 - (pos - F.p) * PXS + 0.5)
      if x < X0 - 16 then table.remove(fills, i)
      else
        local fresh = max(0, 1 - (T - F.t) / 0.3)
        local lv = 1.5 + 2 * exp(-(pos - F.p) / pers) + fresh * 3
        for q = 0, 3 do
          local xx = x - q * 4
          if xx >= X0 and xx <= X1 then line(lv, xx, LY0 + NR * LH - 2, xx + 4, LY0) end
        end
      end
    end
    line(1, X1 + 5, LY0, X1 + 5, 63)
    -- the playhead column throbs with the sub (lo); its rail with the level (amp)
    line(1 + lo * 5 + K.env.kick * 3, X1 + 1, LY0, X1 + 1, LY0 + NR * LH - 1)
    line(0.5 + amp * 3, X0 - 1, LY0, X0 - 1, LY0 + NR * LH - 1)

    -- the header: step, bar, tempo, energy, chaos, phrase
    local step = floor(K.num(K.step, 0))
    local bpm = K.num(S.bpm, 60 / max(0.1, K.beat_sec))
    field("st", 2.5 + K.env.kick * 3, 0, 1, pad(step % 16 + 1, 2), sc)
    field("bar", 2, 10, 1, pad(K.num(S.bar, 0), 4), sc)
    field("bpm", 2, 30, 1, pad(bpm, 3), sc)
    glyph(1.5, 45, 1, "E"); field("e", 2 + e * 3, 49, 1, pad(e * 99, 2), sc)
    glyph(1.5, 59, 1, "X"); field("c", 2 + c * 4, 63, 1, pad(c * 99, 2), sc)
    put(1, 73, 3, 21, 1)
    local pw = floor(ph * 21 + 0.5)
    if pw > 0 then put(2.5 + K.bar_pulse * 2, 73, 2, pw, 3) end
    put(4 + K.env.kick * 4, 73 + floor(K.bar_ph * 20), 5, 1, 1)
    -- the beat LEDs
    local bt = (step % 16) // 4
    for q = 0, 3 do
      local on = q == bt and K.playing
      put(on and (4 + K.env.kick * 5) or (1 + amp * 0.8), PX + q * 7, 1, 5, 4)
    end

    -- the floor: a scope of the output and the three bands
    sc_acc = sc_acc + K.DTS
    while sc_acc >= 0.05 do
      sc_acc = sc_acc - 0.05
      sc_i = (sc_i + 1) % 44
      local wob = K.playing and 0 or 0.06 * sin(T * 3.1)
      scope[sc_i] = clamp(amp + wob + (K.hash(sc_i, floor(T)) - 0.5) * 0.08 * (0.3 + e), 0, 1)
    end
    local px, py
    for j = 0, 43 do
      local v = scope[(sc_i - j) % 44]
      local x, y = X1 - j * 2, 63 - v * 5
      if px then line(2 + v * 4, px, py, x, y) end
      px, py = x, y
    end
    put(2 + lo * 6, PX, 58, max(1, floor(lo * 27)), 1)
    put(2 + A[K.MID] * 6, PX, 60, max(1, floor(A[K.MID] * 27)), 1)
    put(2 + hi * 6, PX, 62, max(1, floor(hi * 27)), 1)
  end

  ----------------------------------------------------------------------
  -- view 2: the radar
  ----------------------------------------------------------------------
  local CX, CY = 64, 32
  local function RR(r) return 6 + (r - 1) * 3.3 end

  local function draw_radar(S)
    local T, e, c = K.T, K.energy, K.chaos
    local amp, lo, hi = A[K.AMP], A[K.LO], A[K.HI]
    local kl = K.kickless
    local sc = c * c * 0.8
    local barsec = 4 * K.beat_sec
    if K.playing then arm_ph = K.bar_ph else arm_ph = (arm_ph + K.DTS * 0.07) % 1 end
    local aa = arm_ph * K.TAU - math.pi / 2
    spin = spin * exp(-K.DT / 0.6)

    -- the range grid: cross hairs and diagonals, dotted, lit by the level
    local gl = 0.7 + amp * 1.2
    for k = 0, 3 do
      local a = k * math.pi / 4 + T * 0.01
      local ca, sa = cos(a), sin(a)
      for q = 2, 9 do
        local rr = q * 3.4
        if (q + k) % 2 == 0 then
          put(gl, CX + ca * rr, CY + sa * rr, 1, 1); put(gl, CX - ca * rr, CY - sa * rr, 1, 1)
        end
      end
    end

    -- the rings, each lit by its band and its last hit
    local wseed = floor(T * 2)
    for r = 1, NR do
      local R = RR(r) + kl * (r - 4.5) * 0.35 * (1 + sin(T * 0.4 + r) * 0.5)
      local dead = r == 1 and kl > 0.5
      local bd = band(r) * ((r == 1 or r == 4 or r == 5 or r == 7) and 1 or 0.67)
      local lv = 0.7 + bd * 0.6 + lenv[r] * 1.5 + e * 0.3
      -- a dotted ring (the arm lights the dots it passes)
      local n = dead and 8 or floor(10 + R * 0.85)
      local rot = (r % 2 == 0 and 1 or -1) * (T * 0.02 + spin * 0.5 * (1 + r * 0.1))
      for k = 0, n - 1 do
        local a = k / n * K.TAU + rot
        local rr = R + (c > 0.05 and (K.hash(k + r * 64, wseed) - 0.5) * c * 3 or 0)
        local behind = (aa - a) % K.TAU
        local l = lv + (behind < 0.6 and (1 - behind / 0.6) * (2 + e * 2) or 0)
        put(dead and 1 or l, CX + cos(a) * rr, CY + sin(a) * rr, 1, 1)
      end
    end
    -- the clock face: 16 step ticks, the downbeats longer
    local cur = floor(arm_ph * 16)
    for q = 0, 15 do
      local a = q / 16 * K.TAU - math.pi / 2
      local r0 = (q % 4 == 0) and 29.5 or 31
      -- the face lights with the level (amp)
      local lv = (q % 4 == 0 and 2 or 1) * (1 + 0.5 * amp) + ((q == cur and K.playing) and 4 or 0)
      line(lv, CX + cos(a) * r0, CY + sin(a) * r0, CX + cos(a) * 32.5, CY + sin(a) * 32.5)
    end
    -- the phrase: an arc outside the face, filling, a tick per bar
    do
      local ph, pl = phrase(S)
      if ph > 0.01 then K.ring(2 + K.bar_pulse * 2 + e, CX, CY, 34.5, max(3, floor(ph * 32)), -math.pi / 2, -math.pi / 2 + ph * K.TAU) end
      local nb = clamp(floor(pl), 1, 32)
      for q = 0, nb - 1 do
        local a = q / nb * K.TAU - math.pi / 2
        put(1.2, CX + cos(a) * 36, CY + sin(a) * 33.5, 1, 1)
      end
    end
    -- the arm and its phosphor trail; chaos splits off ghost arms
    local nt = floor(4 + e * 8)
    for k = nt, 1, -1 do
      local a = aa - k * 0.07
      line((2.2 - k * 1.9 / nt) * (0.6 + 0.5 * e), CX + cos(a) * 4, CY + sin(a) * 4,
        CX + cos(a) * 30, CY + sin(a) * 30)
    end
    line(5 + K.env.kick * 3 + lo, CX + cos(aa) * 3, CY + sin(aa) * 3,
      CX + cos(aa) * 31, CY + sin(aa) * 31)
    if c > 0.3 then
      for g = 1, 2 do
        local a = aa + (K.hash(g, floor(T * 1.5)) - 0.5) * c * 3
        line(1.5 + c * 2, CX + cos(a) * 6, CY + sin(a) * 6, CX + cos(a) * 28, CY + sin(a) * 28)
      end
    end
    -- the hits: each voice its mark, phosphor that the arm re-lights
    for r = 1, NR do
      local R = RR(r)
      local L = lanes[r]
      for i = #L, max(1, #L - 10), -1 do
        local E = L[i]
        local age = T - E.t
        local f = exp(-age / (barsec * (0.4 + e * 0.9)))
        if f > 0.08 then
          local a = E.ph * K.TAU - math.pi / 2
          local behind = (aa - a) % K.TAU
          local relit = behind < 0.5 and (1 - behind / 0.5) or 0
          local fresh = max(0, 1 - age / 0.12)
          local lv = (1.2 + 4.2 * E.v) * f + relit * 2 * f + fresh * 2
          local rr = R + (c > 0.3 and (K.hash(i, r) - 0.5) * c * 4 or 0)
          local ca, sa = cos(a), sin(a)
          local shp = (r == 6 and E.k) and PSHAPE[E.k] or 1
          if r == 4 or r == 7 or shp == 2 then
            -- hats, ticks and metal: a radial tick
            local ln = r == 7 and 1 or 1.5 + E.v
            line(lv, CX + ca * (rr - ln), CY + sa * (rr - ln), CX + ca * (rr + ln), CY + sa * (rr + ln))
          elseif shp == 4 then
            put(lv, CX + ca * rr - 1, CY + sa * rr - 1, 2, 2)
          else
            local w = (0.12 + E.v * 0.14 + (r <= 2 and 0.06 or 0) + (r == 5 and 0.2 or 0)) * 9 / R + 0.04
            K.ring(lv, CX, CY, rr, 3, a - w, a + w)
            if r == 3 or shp == 3 then K.ring(lv * 0.6, CX, CY, rr - 1.2, 2, a - w * 0.7, a + w * 0.7) end
          end
          if fresh > 0 then put(lv, CX + ca * (rr + 1.5), CY + sa * (rr + 1.5), 1, 1) end
        end
      end
      local Bu = bursts[r]
      if Bu then
        local age = T - Bu.t
        local f = exp(-age / (barsec * 0.8))
        if f > 0.05 then
          local a0 = Bu.ph * K.TAU - math.pi / 2
          for q = 0, Bu.n - 1 do
            local a = a0 + q * 0.06
            local ln = (q % 2 == 0) and 2.5 or 1.5
            line((5 + 5 * f) * f, CX + cos(a) * (R - ln), CY + sin(a) * (R - ln),
              CX + cos(a) * (R + ln), CY + sin(a) * (R + ln))
          end
        end
      end
    end
    -- the centre: the kick throbs it and sends out a shock ring
    local kp = max(0, 1 - (T - kick_t) / 0.25)
    if kl > 0.5 then
      K.ring(1.5 + sin(T * 2) * 0.5 + lo, CX, CY, 2.5 + sin(T * 0.8), 8)
    else
      K.disc(2 + kp * 6 + lo * 2, CX, CY, 1.5 + kp * 2 + lo * 0.8)
    end
    for i = #shock, 1, -1 do
      local u = (T - shock[i]) / 0.5
      if u >= 1 or u < 0 then table.remove(shock, i)
      else K.ring((1 - u) * (1.5 + lo * 1.5), CX, CY, 3 + u * 16, 16) end
    end
    -- clutter near the arm, thicker with energy
    K.grain(function(u, v)
      local a = aa - u * 0.6
      local rr = 4 + v * 26
      return CX + cos(a) * rr, CY + sin(a) * rr
    end, 4 + e * 24 + hi * 20, 3 + hi * 4)

    -- left panel: each voice, its LED and the step it last fell on
    for r = 1, NR do
      local y = 1 + (r - 1) * 8
      local dead = r == 1 and kl > 0.5
      text(1.5 + lenv[r] * 2, 0, y, LABEL[r], 0)
      put(1 + lenv[r] * 9, 9, y, 2, 5)
      text(1.5 + lenv[r] * 3, 13, y, dead and "--" or pad(lastst[r], 2), sc)
    end
    -- right panel: tempo, bar, the axes and the bands
    local bpm = K.num(S.bpm, 60 / max(0.1, K.beat_sec))
    field("rbpm", 2.5, 103, 1, pad(bpm, 3), sc)
    field("rbar", 2, 99, 8, pad(K.num(S.bar, 0), 4), sc)
    glyph(1.5, 99, 16, "E"); put(1, 104, 18, 24, 1); put(2 + e * 4, 104, 17, max(1, floor(e * 24)), 3)
    glyph(1.5, 99, 23, "X"); put(1, 104, 25, 24, 1); put(2 + c * 4, 104, 24, max(1, floor(c * 24)), 3)
    local bands = {lo, A[K.MID], hi}
    for i = 1, 3 do
      local v = bands[i]
      local h = floor(v * 28 + 0.5)
      local x = 102 + (i - 1) * 9
      put(1, x, 34, 6, 1)
      if h < 28 then put(1, x + 2, 35, 2, 28 - h) end
      if h > 0 then put(1.5 + v * 2, x, 63 - h, 6, h) end
      if h > 3 then put(4 + v * 4, x, 63 - h, 6, 1) end
    end
  end

  ----------------------------------------------------------------------
  -- view 3: the tracker and the waterfall
  ----------------------------------------------------------------------
  local WX0, WX1 = 36, 127              -- the waterfall's span
  local WCX = (WX0 + WX1) / 2
  local HY, FY = 9, 61                  -- horizon, front baseline
  local RH = 17                         -- a ridge's height at the front

  -- the live spectrum: the four bands under a bump for each voice ringing
  local function spectrum(P, vals, lo, mid, hi, amp, rat, fill, kind, T, kl)
    for b = 0, NB - 1 do
      local u = b / (NB - 1)
      local bl = lo * exp(-((u - 0.1) / 0.16) ^ 2) + mid * 0.8 * exp(-((u - 0.5) / 0.2) ^ 2)
        + hi * 0.7 * exp(-((u - 0.88) / 0.14) ^ 2)
      local s = bl * 0.28 + amp * 0.05 + (K.playing and 0.06 or 0.14) * (0.5 + 0.5 * sin(T * 0.9 + u * 11))
      if kl > 0.05 and u < 0.3 then s = s + kl * 0.18 * (0.5 + 0.5 * sin(T * 1.3 - u * 14)) end
      for r = 1, NR do
        local v = vals[r]
        if v > 0.02 then
          local g
          if r == 6 and kind then
            local d = (u - (0.54 + (kind % 8) * 0.025)) / VW[6]
            g = exp(-d * d * 0.5)
          else g = GTAB[r][b] end
          s = s + v * g * (r == 1 and 0.9 or 0.75)
        end
      end
      if rat > 0 and b % 2 == 0 and u > 0.3 then s = s + 0.25 + 0.02 * rat end
      if fill > 0 then s = s + fill * 0.2 * (0.6 + 0.4 * sin(u * 9)) end
      P[b] = min(1.15, s)
    end
  end

  local LIVEV = {}
  local function draw_water(S)
    local T, e, c, DT = K.T, K.energy, K.chaos, K.DT
    local amp, lo, mid, hi = A[K.AMP], A[K.LO], A[K.MID], A[K.HI]
    local kl = K.kickless
    local sc = c * c * 0.8

    -- where the waterfall stands: 16ths when playing, its own slow clock when not
    local rp
    if K.playing then rp = K.stepf / RSTEP
    else wf_idle = wf_idle + K.DTS * 1.2; rp = wf_idle end
    local ri = floor(rp)
    local frac = rp - ri
    -- the bands, held at their peak for the ridge being laid
    accb[1] = max(accb[1], lo); accb[2] = max(accb[2], mid); accb[3] = max(accb[3], hi); accb[4] = max(accb[4], amp)
    if rcount ~= ri then
      rcount = ri
      -- the live ridge, as it stood, is laid down
      local P = newrow()
      for b = 0, NB - 1 do P[b] = live[b] end
      local stp = floor(K.num(K.step, 0))
      table.insert(ridges, 1, {p = P, down = K.playing and (stp % 16) < RSTEP, fill = accf,
        seed = floor(K.hash(ri, 3) * 1000)})
      if #ridges > NROW then ridges[#ridges] = nil end
      for r = 1, NR do acc[r] = 0 end
      accb[1], accb[2], accb[3], accb[4] = 0, 0, 0, 0
      acck, accr, accf = 0, 0, 0
    end

    -- the sky over the horizon: a glow lit by the level, the phrase along it
    local ph = phrase(S)
    local glow = 0.4 + amp * 0.9 + e * 0.4 + K.duck * 0.4
    K.gradient(HY - 5, HY - 1, function(y) return glow * (1 - (HY - y) / 6) end, nil, WX0, WX1 + 1)
    line(1.2 + amp, WX0, HY, WX1, HY)
    local hx = WX0 + floor(ph * (WX1 - WX0))
    line(2.5 + K.bar_pulse * 3 + e, WX0, HY, hx, HY)
    put(5 + K.bar_pulse * 4, hx, HY - 1, 1, 3)

    -- the floor: lines running from the front to the vanishing point
    local sway = kl * 4 * sin(T * 0.5)
    for q = 0, 6 do
      local u = q / 6
      local xf = WX0 + u * (WX1 - WX0)
      local xh = WCX + (xf - WCX) * 0.22 + sway * 0.2
      line(0.7 + amp * 0.5 + (q == 0 and lo or 0), xf + sway, 63, xh, HY + 2)
    end

    -- the ridges, back to front: each its spectrum laid down, sliding away
    local fadeN = NROW + 0.5 + e * 2.5
    local hiq = hi * 3
    local function ridge(P, d, lvb, xo, tear, seed)
      local q = clamp(1 - d / (NROW + 1), 0, 1)
      local z = 1 / (0.22 + 0.78 * q)
      local y0 = HY + (FY - HY) * q ^ 1.6
      local half = (WX1 - WX0) / 2 / z
      local hgt = RH * (0.8 + e * 0.6) / z
      local fade = clamp(1 - d / fadeN, 0, 1)
      local px, py, pv
      for b = 0, NB - 1 do
        local u = b / (NB - 1)
        local x = WCX + sway / z + xo + (u * 2 - 1) * half
        local v = P[b]
        local y = y0 - v * hgt
        if tear and b >= tear and b < tear + 5 then y = y + (K.hash(b + seed, 9) - 0.5) * 6 * c; x = x + 3 * c end
        if px then
          local vv = max(v, pv)
          line(fade * max(1.1, lvb * 0.35 + vv * 2.4), px, py, x, y)
          -- the highs glitter on the crests
          if hiq > 0.3 and v > 0.25 and K.hash(b + seed, floor(T * 6)) < hi * 0.2 then put(fade * hiq + 1, x, y - 1, 1, 1) end
        end
        px, py, pv = x, y, v
      end
    end
    for j = #ridges, 1, -1 do
      local R = ridges[j]
      local d = j - 1 + frac
      local xo = 0
      if c > 0.25 then xo = (K.hash(R.seed, floor(T * 2)) - 0.5) * c * 8 / (1 + d * 0.3) end
      local tear = (c > 0.4 and K.hash(R.seed, 5) < c * 0.6) and floor(K.hash(R.seed, 6) * (NB - 5)) or nil
      ridge(R.p, d, 0.9 + (R.down and 1.6 or 0) + R.fill * 2 + e * 0.6, xo, tear, R.seed)
      if R.down and d < 8 then
        local q = clamp(1 - d / (NROW + 1), 0, 1)
        put(3 + K.bar_pulse * 3, WCX - (WCX - WX0) * (0.22 + 0.78 * q) - 3, HY + (FY - HY) * q ^ 1.6, 2, 1)
      end
    end
    -- the live ridge at the front: what is ringing now
    -- (it holds the slot's peaks, so it is laid down just as it stands)
    for r = 1, NR do LIVEV[r] = max(acc[r] * 0.9, lenv[r] * 0.6) end
    if kl > 0.5 then LIVEV[1] = 0 end
    spectrum(live, LIVEV, accb[1], accb[2], accb[3], accb[4], accr, max(accf, spin * 0.5), acck > 0 and acck or nil, T, kl)
    ridge(live, 0, 2 + K.env.kick * 1.5 + lo * 1.5, 0, nil, 0)
    -- the front edge throbs with the kick
    put(1 + K.env.kick * 2.5 + lo * 1.5, WX0, 63, WX1 - WX0 + 1, 1)
    spin = spin * exp(-DT / 0.6)

    -- the tracker: a page of sixteen rows in two columns, the cursor running
    -- down it; what played this bar is bright, what is still to come shows
    -- last bar's, dim
    local cidx = K.playing and floor(K.num(K.stepf, 0) + 0.6) or floor(wf_idle * RSTEP)
    local cslot, cbar = cidx % 16, cidx // 16
    line(1 + amp * 2, 33, 0, 33, 63)
    for sl = 0, 15 do
      local col, row = sl // 8, sl % 8
      local x, y = col * 17, 9 + row * 6
      local on = sl == cslot
      if on then put(1 + amp * 0.6 + K.env.kick, x, y - 1, 16, 7) end
      glyph((sl % 4 == 0 and 2 or 1) + (on and 2.5 or 0), x, y, HEX[sl + 1])
      local P = pat[sl]
      for r = 1, NR do
        local cell = P[r]
        local cx = x + 5 + (r - 1) + (r > 4 and 1 or 0)
        local lv = 0
        if r == 1 and kl > 0.5 then lv = 0.6
        elseif cell[2] == cbar then lv = 1.5 + 4 * cell[1] * (sl == cslot and 1.3 or 0.8)
        elseif cell[2] == cbar - 1 and cell[1] > 0 then lv = 1 + cell[1]
        end
        if lv >= 0.5 then put(lv, cx, y + (r >= 4 and r ~= 6 and r ~= 8 and 1 or 0), 1, r == 4 and 2 or (r == 7 and 1 or 4))
        else put(0.7 + mid * 0.6, cx, y + 4, 1, 1) end
      end
    end
    -- the header: bar and step, the energy as a meter
    text(1.5 + K.bar_pulse * 1.5, 0, 0, pad(K.num(S.bar, 0), 4), sc)
    put(1, 17, 2, 15, 1)
    put(2 + e * 4, 17, 1, max(1, floor(e * 15)), 1)
    put(2 + c * 4, 17, 4, max(1, floor(c * 15)), 1)
    -- the foot: the four bands as a little bar graph
    local bv = {lo, mid, hi, amp}
    for i = 1, 4 do
      local w = floor(bv[i] * 7 + 0.5)
      put(1, 1 + (i - 1) * 8, 63, 7, 1)
      if w > 0 then put(2 + bv[i] * 5, 1 + (i - 1) * 8, 61, w, 2) end
    end
  end

  function M.draw(S)
    local DT = K.DT
    pos = pos + K.DTS * (K.playing and (4 / max(0.05, K.beat_sec)) or 0.8)
    glyph_t = glyph_t + K.DTS * (0.6 + K.chaos * 3)
    for r = 1, NR do
      lenv[r] = lenv[r] * exp(-DT / ETAU[r])
      lpeak[r] = max(lenv[r], lpeak[r] - DT * 0.5)
      shear[r] = shear[r] * exp(-DT / 0.4)
    end
    if K.view == 2 then draw_radar(S)
    elseif K.view == 3 then draw_water(S)
    else
      spin = spin * exp(-DT / 0.6)
      draw_lanes(S)
    end
  end

  M.init()
  return M
end
