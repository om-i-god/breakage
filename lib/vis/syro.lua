-- syro: dense data. a dot-matrix sequencer scrolling right to left, one row
-- per voice (kick, snare, clap, hats, open hat / ride, perc, ticks, break):
-- every hit lights its cell at the playhead and the cells keep their glow
-- as they scroll away. a ratchet splits its cell into that many slivers. a
-- column of glyph readouts on the right counts the step, the bar, the
-- tempo and the two axes in a small square font; chaos scrambles their
-- digits, shears the rows of the grid and throws stray cells. energy
-- brightens the matrix and quickens the shimmer of the empty dots
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  local NR = 8                               -- voices
  local RY0, RH = 4, 7                       -- first row's top, row pitch
  local CW = 4                               -- column pitch (px)
  local GX1 = 92                             -- the playhead column's x
  local NC = 24                              -- columns kept
  local PX = 98                              -- the readout panel's left

  -- a 3x5 font: each glyph is 5 rows of 3 bits
  local FONT = {
    ["0"] = {7, 5, 5, 5, 7}, ["1"] = {2, 6, 2, 2, 7}, ["2"] = {7, 1, 7, 4, 7}, ["3"] = {7, 1, 3, 1, 7},
    ["4"] = {5, 5, 7, 1, 1}, ["5"] = {7, 4, 7, 1, 7}, ["6"] = {7, 4, 7, 5, 7}, ["7"] = {7, 1, 2, 2, 2},
    ["8"] = {7, 5, 7, 5, 7}, ["9"] = {7, 5, 7, 1, 7}, ["-"] = {0, 0, 7, 0, 0}, [":"] = {0, 2, 0, 2, 0},
    ["#"] = {5, 7, 5, 7, 5}, ["."] = {0, 0, 0, 0, 2},
  }
  local SCRAM = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "#", "-"}

  local cells                                -- cells[col % NC][row] = {v, t0, n}
  local col_seen, shear, glyph_t
  local echoes = {}

  function M.init()
    cells = {}
    for c = 0, NC - 1 do cells[c] = {} end
    col_seen, shear, glyph_t = nil, {}, 0
    echoes = {}
    for r = 1, NR do shear[r] = 0 end
  end
  M.clear = M.init

  local function col_now() return math.floor(K.stepf) end

  local function mark(row, v, n)
    local c = col_now() % NC
    local old = cells[c][row]
    if old and old.t0 == K.T then n = math.max(n or 1, old.n) end
    cells[c][row] = {v = math.max(K.num(v, 1), old and old.t0 > K.T - 0.1 and old.v or 0), t0 = K.T, n = n or 1}
  end

  function M.kick(v) mark(1, v) end
  function M.snare(v, n) mark(2, v, n) end
  function M.clap(v) mark(3, v) end
  function M.rim(v) mark(3, K.num(v, 1) * 0.6) end
  function M.hat(v, open) if open then mark(5, v) else mark(4, v) end end
  function M.ride(v) mark(5, K.num(v, 1) * 0.7) end
  function M.shaker(v) mark(4, K.num(v, 1) * 0.5) end
  function M.perc(_, v) mark(6, v) end
  function M.tom(v) mark(6, v) end
  function M.tick() mark(7, 0.7) end
  function M.brk(i, n) mark(8, 0.5 + 0.5 * (K.num(i, 1) / math.max(1, K.num(n, 8)))) end

  local VROW = {kick = 1, snare = 2, clap = 3, hat = 4, ride = 5, perc = 6, tom = 6, tick = 7, brk = 8}
  function M.ratchet(n, voice)
    n = clamp(math.floor(K.num(n, 2)), 1, 12)
    mark(VROW[voice] or 2, 1, math.min(n, 8))
    if #echoes >= 6 then table.remove(echoes, 1) end
    echoes[#echoes + 1] = {row = VROW[voice] or 2, n = n, t0 = K.T}
    for r = 1, NR do shear[r] = shear[r] + (K.rnd() - 0.5) * 6 * K.chaos end
  end

  -- a string in the 3x5 font at (x, y); chaos swaps digits for noise
  local function text(lv, x, y, str, scramble)
    for i = 1, #str do
      local ch = str:sub(i, i)
      if scramble > 0 and K.hash(i * 13 + x + math.floor(glyph_t * 9) * 7, y) < scramble then
        ch = SCRAM[1 + math.floor(K.hash(i + math.floor(glyph_t * 11), x + y) * #SCRAM)]
      end
      local g = FONT[ch]
      if g then
        for r = 1, 5 do
          local bits = g[r]
          -- runs of lit bits as one rect each
          local b0 = bits >= 4 and 1 or 0
          local b1 = (bits // 2) % 2
          local b2 = bits % 2
          local xx = x + (i - 1) * 4
          if b0 == 1 and b1 == 1 and b2 == 1 then put(lv, xx, y + r - 1, 3, 1)
          else
            if b0 == 1 and b1 == 1 then put(lv, xx, y + r - 1, 2, 1)
            elseif b0 == 1 then put(lv, xx, y + r - 1, 1, 1) end
            if b1 == 1 and b2 == 1 and b0 == 0 then put(lv, xx + 1, y + r - 1, 2, 1)
            else
              if b1 == 1 and b0 == 0 then put(lv, xx + 1, y + r - 1, 1, 1) end
              if b2 == 1 then put(lv, xx + 2, y + r - 1, 1, 1) end
            end
          end
        end
      end
    end
  end

  local function pad(v, n)
    local s = tostring(math.floor(K.num(v, 0)) % (10 ^ n) // 1)
    s = s:gsub("%.0$", "")
    while #s < n do s = "0" .. s end
    return s
  end

  function M.draw(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi = A[K.LO], A[K.HI]
    glyph_t = glyph_t + K.DTS * (0.6 + c * 3)
    local now = col_now()
    -- a new column clears the cells it overwrites
    if col_seen ~= now then
      if col_seen and now > col_seen and now - col_seen < NC then
        for cc = col_seen + 1, now do cells[cc % NC] = {} end
      elseif col_seen and now ~= col_seen then
        for cc = 0, NC - 1 do cells[cc] = {} end
      end
      col_seen = now
    end
    local sub = K.stepf - now
    for r = 1, NR do shear[r] = shear[r] * math.exp(-DT / 0.4) end

    -- the matrix: dim dots where nothing played, lit cells where it did
    for r = 1, NR do
      local y = RY0 + (r - 1) * RH
      local hs = K.hash(r + math.floor(T * 4) * 17, 4)
      local sh = math.floor(shear[r] + ((c > 0.3 and hs > 1.15 - c * 0.6) and (K.hash(r, math.floor(T * 4)) - 0.5) * c * 8 or 0) + 0.5)
      local rowlo = (r <= 2 and lo or 0) + ((r == 4 or r == 5 or r == 7) and hi or 0)
      for k = 0, NC - 1 do
        local col = now - k
        local x = math.floor(GX1 - k * CW - sub * CW + sh + 0.5)
        if x >= 0 and x <= GX1 + 2 then
          local cell = cells[col % NC][r]
          if cell and k < NC - 1 then
            local age = K.T - cell.t0
            local fade = math.exp(-k / (3 + e * 5))
            local lv = (2 + 8 * cell.v) * (0.6 + 0.5 * e) * fade + (age < 0.15 and 3 * (1 - age / 0.15) or 0) + rowlo * 1.5
            if cell.n > 1 then
              local w = math.max(1, math.floor(3 / cell.n * 1.5))
              for q = 0, math.min(cell.n, 6) - 1 do put(lv * (1 - q * 0.08), x + q * (CW / math.min(cell.n, 6)), y, 1, 4 + (q % 2)) end
            else
              put(lv, x, y, 2, 4)
              if k < 2 then put(lv * 0.5, x + 2, y + 1, 1, 2) end
            end
          elseif (col + r) % 2 == 0 then
            local sh2 = 0.5 + 0.5 * math.sin(T * (2.6 + e * 2) + col * 0.7 + r * 1.1)
            put(0.8 + sh2 * (1 + e * 0.8 + rowlo * 1.5) * (k < 12 and 1 or 0.7), x + 1, y + 2, 1, 1)
          end
        end
      end
      -- the voice's tag at the left
      put(1.5 + rowlo * 2, 0, y + 1, 1, 2)
    end
    -- ratchets: the hit's repeats thrown back along its row as echoes
    for i = #echoes, 1, -1 do
      local E = echoes[i]
      local u = (K.T - E.t0) / 0.9
      if u >= 1 then table.remove(echoes, i)
      else
        local y = RY0 + (E.row - 1) * RH
        for q = 1, E.n do
          local x = GX1 - q * (3 + u * 5)
          put((10 - q * 0.6) * (1 - u), x, y - 1, 2, 6)
        end
      end
    end
    -- the playhead: a bracket around the newest column, brighter on beats
    local beat = (now % 4 == 0) and 1 or 0
    local px = GX1 - sub * CW
    line(2 + beat * 3 * (1 - sub) + K.env.kick * 2, px - 1, RY0 - 2, px + 3, RY0 - 2)
    line(2 + beat * 3 * (1 - sub) + K.env.kick * 2, px - 1, RY0 + NR * RH - 1, px + 3, RY0 + NR * RH - 1)
    -- bar ruler under the grid: every 4th column ticked, the downbeat taller
    for k = 0, NC - 1 do
      local col = now - k
      local x = math.floor(GX1 - k * CW - sub * CW + 1.5)
      if x >= 0 and col % 4 == 0 then put(col % 16 == 0 and 3 or 1.5, x, RY0 + NR * RH + 1, 1, col % 16 == 0 and 3 or 2) end
    end

    -- the readouts: step / bar / tempo / energy / chaos
    line(1.5, PX - 2, 0, PX - 2, 63)
    local sc = c * c * 0.9
    local Sbpm = K.num(S.bpm, 60 / math.max(0.1, K.beat_sec))
    text(3 + K.env.kick * 4, PX, 2, pad(K.step % 1000, 3), sc)
    text(2.5, PX, 9, pad(K.num(S.bar, 0), 3), sc)
    text(2.5, PX, 16, pad(Sbpm, 3), sc)
    text(2 + e * 3, PX, 25, pad(e * 99, 2), sc)
    text(2 + c * 4, PX + 13, 25, pad(c * 99, 2), sc)
    -- small bar meters: lows, mids, highs
    for i, v in ipairs({lo, A[K.MID], hi}) do
      local h = math.floor(v * 18 + 0.5)
      for q = 0, 17, 2 do put(q < h and (2 + q / 18 * 5) or 1, PX + (i - 1) * 5 + 4, 60 - q, 3, 1) end
    end
    if (glyph_t * 1.3) % 1 < 0.5 then put(3, PX + 24, 16, 2, 5) end       -- the cursor
    put(1 + K.env.snare * 6, PX + 22, 33, 3, 3)
    put(1 + K.env.hat * 6 + K.env.ohat * 4, PX + 22, 38, 3, 3)
    -- a scramble line: random cells when chaos is high
    if c > 0.4 then
      for q = 1, math.floor(c * 8) do
        local h = K.hash(q * 3 + math.floor(T * 7) * 11, 8)
        put(2 + c * 3, math.floor(h * 22) * CW, RY0 + math.floor(K.hash(q, math.floor(T * 7)) * NR) * RH + 1, 3, 2)
      end
    end
  end

  M.init()
  return M
end
