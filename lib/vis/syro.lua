-- syro: view 1, a dense machine readout: eight voice lanes of envelope history scrolling left past a playhead, with live readouts and meters; view 2, a polar radar clock face: one ring per voice, hits marked at their angle in the bar, the sweep arm is the playhead.
--
-- view 1: each voice is a lane (BD SD CP HH OH PC TK BR). every hit draws
-- an envelope (a bar as tall as its velocity, with a decay tail as long as
-- the voice rings) at the playhead, and the lane scrolls it away, dimming
-- slowly, so the screen fills with the last bar and a half of the groove.
-- a ratchet lands as a visible burst of spikes and its count (x6) flashes
-- in the lane's readout. the header counts the step, the bar, the tempo,
-- energy and chaos; a digit that changes lights up and settles, so the
-- numbers flicker with what is actually happening. the right column shows
-- each lane's last velocity and a peak-hold meter; the floor strip is a
-- scope of the output. energy keeps the history brighter for longer, chaos
-- shears the lanes, throws ghost copies of the hits and scrambles digits;
-- kickless, the kick lane goes to a dashed standby line.
-- view 2: the same voices as eight rings of a radar. hits mark their ring
-- at the angle they fell in the bar and glow on as phosphor, re-lit when the
-- arm sweeps over them; the kick throbs the centre; ratchets are radial
-- bursts. side panels read out each voice's last step, the tempo, the bar
-- and the bands. chaos wobbles the rings and splits the arm into ghosts.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

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
    B = {6, 5, 6, 5, 6}, D = {6, 5, 5, 5, 6}, S = {3, 4, 2, 1, 6}, C = {7, 4, 4, 4, 7},
    P = {7, 5, 7, 4, 4}, H = {5, 5, 7, 5, 5}, O = {7, 5, 5, 5, 7}, K = {5, 5, 6, 5, 5},
    T = {7, 2, 2, 2, 2}, R = {6, 5, 6, 5, 5}, E = {7, 4, 6, 4, 7}, X = {5, 5, 2, 5, 5},
  }
  local SCRAM = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "#", "-"}
  local LABEL = {"BD", "SD", "CP", "HH", "OH", "PC", "TK", "BR"}
  local WID = {3, 2, 2, 1, 1, 2, 1, 2}           -- envelope bar width per lane
  local TAIL = {7, 4, 3, 0, 5, 3, 0, 2}         -- decay tail (px)
  local ETAU = {0.2, 0.15, 0.12, 0.05, 0.25, 0.1, 0.04, 0.08}
  local VROW = {kick = 1, snare = 2, clap = 3, hat = 4, hats = 4, ride = 5, perc = 6, tom = 6,
    tick = 7, ticks = 7, brk = 8}

  local lanes, bursts, lenv, lpeak, lastv, lastst
  local pos, glyph_t, shear, scope, sc_i, sc_acc
  local fld, arm_ph, kick_t
  local jcur = {}

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
    for r = 1, NR do jcur[r] = 0 end
  end
  M.clear = M.init

  local function mark(r, v, n)
    v = clamp(K.num(v, 1), 0, 1)
    local L = lanes[r]
    local Bu = bursts[r]
    lenv[r] = math.max(lenv[r], 0.35 + 0.65 * v)
    lpeak[r] = math.max(lpeak[r], lenv[r])
    lastv[r] = v
    lastst[r] = math.floor(K.num(K.step, 0)) % 16
    -- the repeats of a ratchet already drawn as its burst
    if n and n > 1 and Bu and K.T - Bu.t < 0.4 then return end
    if #L >= MAXE then table.remove(L, 1) end
    L[#L + 1] = {p = pos, v = v, t = K.T, ph = K.bar_ph}
  end

  function M.kick(v) mark(1, v); kick_t = K.T end
  function M.snare(v, n) mark(2, v, K.num(n, 1)) end
  function M.clap(v) mark(3, v) end
  function M.rim(v) mark(3, K.num(v, 1) * 0.6) end
  function M.hat(v, open) if open then mark(5, v) else mark(4, v) end end
  function M.ride(v) mark(5, K.num(v, 1) * 0.7) end
  function M.shaker(v) mark(4, K.num(v, 1) * 0.5) end
  function M.perc(_, v) mark(6, v) end
  function M.tom(v) mark(6, v) end
  function M.tick(k) mark(7, 0.4 + 0.1 * K.num(k, 1)) end
  function M.brk(i, n) mark(8, 0.4 + 0.6 * (K.num(i, 1) / math.max(1, K.num(n, 8)))) end
  function M.fill() for r = 1, NR do lpeak[r] = math.max(lpeak[r], 0.6) end end

  function M.ratchet(n, voice)
    n = clamp(math.floor(K.num(n, 2)), 2, 12)
    local r = VROW[voice] or 2
    bursts[r] = {p = pos, n = n, t = K.T, ph = K.bar_ph}
    lenv[r], lpeak[r] = 1, 1
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
    if sc > 0 and ch:match("%d") and K.hash(i * 13 + x * 3 + math.floor(glyph_t * 9) * 7, y) < sc then
      return SCRAM[1 + math.floor(K.hash(i + math.floor(glyph_t * 11), x + y) * #SCRAM)]
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
      local fl = F.tc[i] and math.exp(-(K.T - F.tc[i]) / 0.18) or 0
      glyph(lv + fl * 6, x + (i - 1) * 4, y, scram(str:sub(i, i), i, x, y, sc or 0))
    end
  end

  local function pad(v, n)
    v = math.floor(K.num(v, 0))
    if v < 0 then v = 0 end
    local s = tostring(v % math.floor(10 ^ n))
    while #s < n do s = "0" .. s end
    return s
  end

  local function band(r)
    if r == 1 then return A[K.LO] elseif r == 2 or r == 3 or r == 6 or r == 8 then return A[K.MID] * 0.6 end
    return A[K.HI]
  end

  ----------------------------------------------------------------------
  -- view 1: the lanes
  ----------------------------------------------------------------------
  local function draw_lanes(S)
    local T, e, c = K.T, K.energy, K.chaos
    local sc = c * c * 0.8
    local scroll = pos * PXS
    local pers = 5 + e * 8
    local sub = scroll % 4
    local base = math.floor(scroll / 4)

    -- bar lines and beat ticks through the history
    local first = math.floor(pos / 4) * 4
    for q = 0, 6 do
      local p = first - q * 4
      local x = math.floor(X1 - (pos - p) * PXS + 0.5)
      if x >= X0 and x <= X1 then
        if p % 16 == 0 then line(1.5 + K.bar_pulse * 2, x, LY0, x, LY0 + NR * LH - 2)
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
        jig = (K.hash(r * 31 + math.floor(pos / 4), 9) - 0.5) * (c - 0.5) * 12
      end
      -- the lane slides toward its sheared place a pixel a frame
      local to = math.floor(shear[r] + jig + 0.5)
      if to > jcur[r] then jcur[r] = jcur[r] + 1 elseif to < jcur[r] then jcur[r] = jcur[r] - 1 end
      local sh = jcur[r]
      -- the label
      text((dead and 1 or 1.5) + lenv[r] * 4 + bnd * 2, 0, by - 4, LABEL[r], 0)
      -- the noise floor: a scrolling dotted baseline, busier with energy
      for j = 0, 21 do
        local x = math.floor(X1 - j * 4 - sub + sh + 0.5)
        if x >= X0 and x <= X1 then
          local id = (base - j) * 8 + r
          if K.hash(id, 3) > 0.45 then put(1 + bnd * 1.5, x, by, 1, 1) end
          if K.hash(id, 5) > 0.92 - e * 0.25 - bnd * 0.2 then put(1.2 + bnd, x, by - 1, 1, 1) end
        end
      end
      do
        local sx = X1 - math.floor((T * 24 + r * 9) % (X1 - X0))
        put(2 + bnd * 2, sx, by, 2, 1)
      end
      if dead then
        local off = math.floor(T * 6) % 4
        for x = X0 + off, X1, 4 do put(1.5, x, by - 2, 2, 1) end
      end
      -- the envelopes
      local L = lanes[r]
      while #L > 0 and X1 - (pos - L[1].p) * PXS < X0 - 14 do table.remove(L, 1) end
      local w, tl = WID[r], TAIL[r]
      for i = 1, #L do
        local E = L[i]
        local d = pos - E.p
        local xf = X1 - d * PXS + sh
        local x = math.floor(xf)
        local f = xf - x
        local h = clamp(1 + math.floor(E.v * 4.5), 1, 5)
        local fresh = math.max(0, 1 - (T - E.t) / 0.12)
        local lv = (1.5 + 6 * E.v) * (0.3 + 0.7 * math.exp(-d / pers)) * (0.8 + 0.3 * e) + fresh * 3 + bnd
        if x >= X0 then
          -- split across the pixel it is leaving and the one it enters, so
          -- the scroll glides instead of stepping
          if d < 14 then
            put(lv * (1 - f), x, by - h + 1, 1, h)
            if w > 1 then put(lv, x + 1, by - h + 1, w - 1, h) end
            if x + w <= X1 + 1 then put(lv * f, x + w, by - h + 1, 1, h) end
            if tl > 0 and h > 1 and x + w + tl <= X1 + 3 then line(lv * 0.45, x + w, by - h + 1, x + w + tl, by) end
          else
            put(lv, math.floor(xf + 0.5), by - h + 1, w, h)
          end
        end
        -- chaos: ghost copies thrown ahead of the hit
        if c > 0.3 and i > #L - 6 then
          local gx = x + math.floor((K.hash(i + r * 40, math.floor(E.p)) - 0.5) * 20 * c)
          if gx >= X0 and gx <= X1 then put(lv * 0.35 * c, gx, by - h + 2, 1, math.max(1, h - 1)) end
        end
      end
      -- the burst of a ratchet: n spikes ending at the hit
      local Bu = bursts[r]
      if Bu then
        local d = pos - Bu.p
        local x = math.floor(X1 - d * PXS + sh + 0.5)
        if x < X0 - 2 * Bu.n then bursts[r] = nil
        else
          local fresh = math.max(0, 1 - (T - Bu.t) / 0.25)
          local lv = (5 + 4 * math.exp(-d / pers)) + fresh * 3
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
        text(1.5 + lenv[r] * 8, PX, by - 4, pad(lastv[r] * 99, 2), sc)
      end
      local mw = math.floor(lenv[r] * 16 + bnd * 3 + 0.5)
      if mw > 0 then put(2 + lenv[r] * 5, PX + 9, by - 2, mw, 2) end
      put(1, PX + 9, by, 18, 1)
      put(2 + lpeak[r] * 4, PX + 9 + math.floor(lpeak[r] * 17), by - 3, 1, 3)
    end
    line(1, X1 + 5, LY0, X1 + 5, 63)

    -- the header: step, bar, tempo, energy, chaos, phrase
    local step = math.floor(K.num(K.step, 0))
    local bpm = K.num(S.bpm, 60 / math.max(0.1, K.beat_sec))
    field("st", 2.5 + K.env.kick * 3, 0, 1, pad(step % 16 + 1, 2), sc)
    field("bar", 2, 10, 1, pad(K.num(S.bar, 0), 4), sc)
    field("bpm", 2, 30, 1, pad(bpm, 3), sc)
    glyph(1.5, 45, 1, "E"); field("e", 2 + e * 3, 49, 1, pad(e * 99, 2), sc)
    glyph(1.5, 59, 1, "X"); field("c", 2 + c * 4, 63, 1, pad(c * 99, 2), sc)
    local pl = math.max(1, K.num(S.phrase_len, 16))
    local pp = clamp(K.num(S.phrase_pos, 0) / pl, 0, 1)
    put(1, 73, 3, 21, 1)
    local pw = math.floor(pp * 21 + 0.5)
    if pw > 0 then put(2.5 + K.bar_pulse * 2, 73, 2, pw, 3) end
    -- the beat LEDs
    local bt = (step % 16) // 4
    for q = 0, 3 do
      local on = q == bt and K.playing
      put(on and (4 + K.env.kick * 5) or 1, PX + q * 7, 1, 5, 4)
    end

    -- the floor: a scope of the output and the three bands
    sc_acc = sc_acc + K.DTS
    while sc_acc >= 0.05 do
      sc_acc = sc_acc - 0.05
      sc_i = (sc_i + 1) % 44
      local wob = K.playing and 0 or 0.06 * math.sin(T * 3.1)
      scope[sc_i] = clamp(A[K.AMP] + wob + (K.hash(sc_i, math.floor(T)) - 0.5) * 0.08 * (0.3 + e), 0, 1)
    end
    local px, py
    for j = 0, 43 do
      local v = scope[(sc_i - j) % 44]
      local x, y = X1 - j * 2, 63 - v * 5
      if px then line(2 + v * 4, px, py, x, y) end
      px, py = x, y
    end
    put(2 + A[K.LO] * 6, PX, 58, math.max(1, math.floor(A[K.LO] * 27)), 1)
    put(2 + A[K.MID] * 6, PX, 60, math.max(1, math.floor(A[K.MID] * 27)), 1)
    put(2 + A[K.HI] * 6, PX, 62, math.max(1, math.floor(A[K.HI] * 27)), 1)
  end

  ----------------------------------------------------------------------
  -- view 2: the radar
  ----------------------------------------------------------------------
  local CX, CY = 64, 32
  local function RR(r) return 6 + (r - 1) * 3.3 end

  local function draw_radar(S)
    local T, e, c = K.T, K.energy, K.chaos
    local sc = c * c * 0.8
    local barsec = 4 * K.beat_sec
    if K.playing then arm_ph = K.bar_ph else arm_ph = (arm_ph + K.DTS * 0.07) % 1 end
    local aa = arm_ph * K.TAU - math.pi / 2

    -- the rings, each lit by its band and its last hit
    local wseed = math.floor(T * 2)
    for r = 1, NR do
      local R = RR(r)
      local dead = r == 1 and K.kickless > 0.5
      local lv = 0.8 + band(r) * 0.5 + lenv[r] * 1.5 + e * 0.2
      -- a dotted ring (the arm lights the dots it passes)
      local n = dead and 8 or math.floor(12 + R * 1.1)
      local rot = (r % 2 == 0 and 1 or -1) * T * 0.02
      for k = 0, n - 1 do
        local a = k / n * K.TAU + rot
        local rr = R + (c > 0.05 and (K.hash(k + r * 64, wseed) - 0.5) * c * 3 or 0)
        local behind = (aa - a) % K.TAU
        local l = lv + (behind < 0.6 and (1 - behind / 0.6) * (2 + e * 2) or 0)
        put(dead and 1 or l, CX + math.cos(a) * rr, CY + math.sin(a) * rr, 1, 1)
      end
    end
    -- the clock face: 16 step ticks, the downbeats longer
    local cur = math.floor(arm_ph * 16)
    for q = 0, 15 do
      local a = q / 16 * K.TAU - math.pi / 2
      local r0 = (q % 4 == 0) and 29.5 or 31
      local lv = (q % 4 == 0 and 3 or 1.5) + ((q == cur and K.playing) and 4 or 0)
      line(lv, CX + math.cos(a) * r0, CY + math.sin(a) * r0, CX + math.cos(a) * 32.5, CY + math.sin(a) * 32.5)
    end
    -- the arm and its phosphor trail; chaos splits off ghost arms
    local nt = math.floor(4 + e * 6)
    for k = nt, 1, -1 do
      local a = aa - k * 0.07
      line((2.2 - k * 1.9 / nt) * (0.6 + 0.4 * e), CX + math.cos(a) * 4, CY + math.sin(a) * 4,
        CX + math.cos(a) * 30, CY + math.sin(a) * 30)
    end
    line(5 + K.env.kick * 3 + A[K.LO], CX + math.cos(aa) * 3, CY + math.sin(aa) * 3,
      CX + math.cos(aa) * 31, CY + math.sin(aa) * 31)
    if c > 0.3 then
      for g = 1, 2 do
        local a = aa + (K.hash(g, math.floor(T * 1.5)) - 0.5) * c * 3
        line(1.5 + c * 2, CX + math.cos(a) * 6, CY + math.sin(a) * 6, CX + math.cos(a) * 28, CY + math.sin(a) * 28)
      end
    end
    -- the hits: arcs at their angle, phosphor that the arm re-lights
    for r = 1, NR do
      local R = RR(r)
      local L = lanes[r]
      for i = #L, math.max(1, #L - 16), -1 do
        local E = L[i]
        local age = T - E.t
        local f = math.exp(-age / (barsec * (0.5 + e * 0.7)))
        if f > 0.05 then
          local a = E.ph * K.TAU - math.pi / 2
          local behind = (aa - a) % K.TAU
          local relit = behind < 0.5 and (1 - behind / 0.5) or 0
          local fresh = math.max(0, 1 - age / 0.12)
          local lv = (1.5 + 5 * E.v) * f + relit * 2 * f + fresh * 2
          local w = (0.12 + E.v * 0.14 + (r <= 2 and 0.06 or 0)) * 9 / R + 0.04
          local rr = R + (c > 0.3 and (K.hash(i, r) - 0.5) * c * 4 or 0)
          K.ring(lv, CX, CY, rr, 3, a - w, a + w)
          if E.v > 0.55 then K.ring(lv * 0.6, CX, CY, rr - 1, 2, a - w * 0.7, a + w * 0.7) end
          if fresh > 0 then put(lv, CX + math.cos(a) * (rr + 1.5), CY + math.sin(a) * (rr + 1.5), 1, 1) end
        end
      end
      local Bu = bursts[r]
      if Bu then
        local age = T - Bu.t
        local f = math.exp(-age / (barsec * 0.8))
        if f > 0.05 then
          local a0 = Bu.ph * K.TAU - math.pi / 2
          for q = 0, Bu.n - 1 do
            local a = a0 + q * 0.06
            local ln = (q % 2 == 0) and 2.5 or 1.5
            line((5 + 5 * f) * f, CX + math.cos(a) * (R - ln), CY + math.sin(a) * (R - ln),
              CX + math.cos(a) * (R + ln), CY + math.sin(a) * (R + ln))
          end
        end
      end
    end
    -- the centre: the kick throbs it
    local kp = math.max(0, 1 - (T - kick_t) / 0.25)
    if K.kickless > 0.5 then
      K.ring(1.5 + math.sin(T * 2) * 0.5, CX, CY, 2.5, 8)
    else
      K.disc(2 + kp * 6 + A[K.LO] * 2, CX, CY, 1.5 + kp * 2 + A[K.LO] * 0.5)
    end
    -- clutter near the arm, thicker with energy
    K.grain(function(u, v)
      local a = aa - u * 0.6
      local rr = 4 + v * 26
      return CX + math.cos(a) * rr, CY + math.sin(a) * rr
    end, 4 + e * 18 + A[K.HI] * 20, 3 + A[K.HI] * 4)

    -- left panel: each voice, its LED and the step it last fell on
    for r = 1, NR do
      local y = 1 + (r - 1) * 8
      local dead = r == 1 and K.kickless > 0.5
      text(1.5 + lenv[r] * 2, 0, y, LABEL[r], 0)
      put(1 + lenv[r] * 9, 9, y, 2, 5)
      text(1.5 + lenv[r] * 3, 13, y, dead and "--" or pad(lastst[r], 2), sc)
    end
    -- right panel: tempo, bar, the axes and the bands
    local bpm = K.num(S.bpm, 60 / math.max(0.1, K.beat_sec))
    field("rbpm", 2.5, 103, 1, pad(bpm, 3), sc)
    field("rbar", 2, 99, 8, pad(K.num(S.bar, 0), 4), sc)
    glyph(1.5, 99, 16, "E"); put(1, 104, 18, 24, 1); put(2 + e * 4, 104, 17, math.max(1, math.floor(e * 24)), 3)
    glyph(1.5, 99, 23, "X"); put(1, 104, 25, 24, 1); put(2 + c * 4, 104, 24, math.max(1, math.floor(c * 24)), 3)
    local bands = {A[K.LO], A[K.MID], A[K.HI]}
    for i = 1, 3 do
      local v = bands[i]
      local h = math.floor(v * 28 + 0.5)
      local x = 102 + (i - 1) * 9
      put(1, x, 34, 6, 1)
      if h < 28 then put(1, x + 2, 35, 2, 28 - h) end
      if h > 0 then put(1.5 + v * 2, x, 63 - h, 6, h) end
      if h > 3 then put(4 + v * 4, x, 63 - h, 6, 1) end
    end
  end

  function M.draw(S)
    local DT = K.DT
    pos = pos + K.DTS * (K.playing and (4 / math.max(0.05, K.beat_sec)) or 0.8)
    glyph_t = glyph_t + K.DTS * (0.6 + K.chaos * 3)
    for r = 1, NR do
      lenv[r] = lenv[r] * math.exp(-DT / ETAU[r])
      lpeak[r] = math.max(lenv[r], lpeak[r] - DT * 0.5)
      shear[r] = shear[r] * math.exp(-DT / 0.4)
    end
    if K.view == 2 then draw_radar(S) else draw_lanes(S) end
  end

  M.init()
  return M
end
