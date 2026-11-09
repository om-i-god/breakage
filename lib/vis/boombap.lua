-- boombap. view 1: a turntable seen from above at an angle: the record spins
-- with its grooves and label, the tonearm rides it, the strobe dots run round
-- the platter edge and the pop-up target light leans over it.
-- view 2: a bedroom studio at night: a sampler with sixteen pads and a little
-- LCD waveform, a desk lamp, a window with the city in the rain, and the back
-- of a head in headphones nodding to the kick.
--
-- view 1: vinyl crackle shows as specks of dust catching the light on the
-- record (they ride round with it); pops spark at the needle; the kick
-- wobbles the target light's pool and bobs the needle; the snare lights the
-- strobe dots round the platter edge; hats glint dully on the headshell;
-- break slices and ratchets throw specks; a fill flares the light. energy
-- brightens the grooves and the lamp, chaos makes the needle skip grooves and
-- scratches the record back and forth with a ghost label, and kickless
-- stretches lift the arm off the record (its shadow parts from it).
-- view 2: each voice lights its pad (kick, snare, clap, rim on the bottom
-- row; hats, open hat, ride, shaker; the perc kinds and ticks on the top
-- two rows; break slices walk the pads; ratchets run them); the LCD scrolls
-- the output's waveform; the kick nods the head; crackle hisses on the LCD.
-- energy lights the city and the lamp, chaos glitches the LCD, doubles the
-- pads and thickens the rain, kickless lets the head sway and the rain take over.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs, sqrt = math.sin, math.cos, math.floor, math.max, math.min, math.abs, math.sqrt
  local PI, TAU = math.pi, 2 * math.pi

  ---------------------------------------------------------------- state
  local spin, rv                         -- record angle, its angular speed
  local rn, rn_to                        -- needle groove radius (eased), target
  local specks                           -- dust: {r, a, t0, v}
  local strobe, pool, wob, bob, pop      -- snare strobe, kick light pool, wobble, needle bob, pop spark
  local lift, glint, flare, last_skip    -- arm lift (eased), hat glint, fill flare, skip step
  local scratch = 0                      -- a ratchet's scratch back
  -- view 2
  local pads, sched                      -- pad glow (16), scheduled pad hits
  local wave, wacc                       -- LCD waveform columns, sample clock
  local nod, nodv, hiss                  -- head nod and its speed, LCD hiss

  local NP = 16
  local WN = 30

  function M.init()
    spin, rv = 0, 3.5
    rn, rn_to = 30, 30
    specks = {}
    strobe, pool, wob, bob, pop = 0, 0, 0, 0, 0
    lift, glint, flare, last_skip = 0, 0, 0, -1
    scratch = 0
    pads, sched = {}, {}
    for i = 1, NP do pads[i] = 0 end
    wave, wacc = {}, 0
    for i = 1, WN do wave[i] = 0 end
    nod, nodv, hiss = 0, 0, 0
  end
  M.clear = M.init

  local function fell(l, cx, cy, rx, ry)
    if not (rx > 0.3 and ry > 0.3) then return end
    for dy = -floor(ry), floor(ry) do
      local u = dy / ry
      local hw = rx * sqrt(max(0, 1 - u * u))
      if hw >= 0.5 then put(l, cx - hw, cy + dy, max(1, hw * 2), 1) end
    end
  end

  local function speck(v, r)
    if #specks >= 14 then table.remove(specks, 1) end
    specks[#specks + 1] = {r = r or (12 + K.rnd() * 24), a = K.rnd() * TAU, t0 = K.T, v = v}
  end
  local function pad(i, v) i = clamp(floor(i), 1, NP); pads[i] = max(pads[i], v) end

  ---------------------------------------------------------------- events
  -- pads: 1 kick 2 snare 3 clap 4 rim / 5 hat 6 open hat 7 ride 8 shaker /
  -- 9..16 the perc kinds and the ticks
  function M.kick(v)
    v = K.num(v, 1)
    pool = max(pool, v)
    wob = 1
    bob = 1
    nodv = nodv + 9 * v
    pad(1, v)
  end
  function M.snare(v, n)
    v = K.num(v, 1)
    strobe = max(strobe, v)
    pad(2, v)
    if K.rnd() < 0.5 then speck(0.5 * v) end
  end
  function M.clap(v) v = K.num(v, 1); strobe = max(strobe, 0.8 * v); pad(3, v) end
  function M.rim(v) v = K.num(v, 1); strobe = max(strobe, 0.4 * v); pad(4, v) end
  function M.hat(v, open)
    v = K.num(v, 1)
    glint = max(glint, (open and 0.8 or 0.5) * v)
    pad(open and 6 or 5, v)
  end
  function M.ride(v) v = K.num(v, 1); glint = max(glint, 0.5 * v); pad(7, v) end
  function M.shaker(v) v = K.num(v, 1); glint = max(glint, 0.3 * v); pad(8, v) end
  function M.perc(kind, v)
    v = K.num(v, 1)
    kind = floor(K.num(kind, 1))
    if kind == 15 then
      speck(v); if K.rnd() < 0.6 then speck(v * 0.7) end
      hiss = max(hiss, v)
    end
    pad(9 + (kind - 1) % 8, v)
  end
  function M.tom(v) v = K.num(v, 1); pad(9, v); pool = max(pool, 0.4 * v) end
  function M.tick(kind)
    kind = floor(K.num(kind, 1))
    if kind == 8 or kind == 3 then pop = 1; speck(0.8, rn) end
    pad(9 + (kind + 3) % 8, 0.6)
  end
  function M.brk(s, n)
    s, n = K.num(s, 1), max(1, K.num(n, 8))
    pad((s - 1) % NP + 1, 0.7)
    if s % 3 == 1 then speck(0.4) end
  end
  function M.ratchet(n)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    local p0 = 1 + floor(K.rnd() * NP)
    for i = 0, n - 1 do
      if #sched < 24 then sched[#sched + 1] = {t = K.T + i * 0.05, p = (p0 - 1 + i) % NP + 1} end
    end
    for i = 1, min(n, 4) do speck(0.6) end
    scratch = clamp(n / 6, 0.4, 1)
    strobe = 1
    pop = max(pop, 0.6)
  end
  function M.fill()
    flare = 1
    for i = 0, 7 do
      if #sched < 24 then sched[#sched + 1] = {t = K.T + i * 0.04, p = 16 - i} end
    end
  end

  ---------------------------------------------------------------- view 1
  local PX, PY = 54, 34                   -- the platter's centre
  local SQ = 0.6                          -- the angle we see it at
  local PR = 41                           -- platter radius
  local RR = 37                           -- record radius
  local GROOVES = {14, 17, 20, 22.5, 25, 28, 31, 33.5, 36}
  local PIV_X, PIV_Y = 113, 11            -- the tonearm's pivot

  local function rp(r, a) return PX + r * cos(a), PY + r * sin(a) * SQ end

  local function draw1(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid, kl = A[K.LO], A[K.HI], A[K.MID], K.kickless
    local lamp = 0.6 + e * 0.8 + flare * 0.8

    -- the plinth: dark wood with a lamp-lit corner, its edge and feet
    -- a record sleeve lying in the corner, its cover art a sun and bars
    line(2 + lamp * 0.5, 3, 3, 21, 3); line(2 + lamp * 0.5, 3, 3, 3, 15)
    line(1.5, 21, 3, 21, 9); line(1.5, 3, 15, 10, 15)
    K.ring(2 + lamp * 0.6, 10, 8, 3, 8)
    for k = 0, 2 do put(1.5 + lamp * 0.4, 6 + k * 4, 12, 2, 1) end
    line(2 + lamp * 0.6, 1, 1, 126, 1)
    line(1.5 + lamp * 0.4, 1, 1, 1, 62)
    line(1.5, 126, 1, 126, 62)
    line(1.5, 1, 62, 126, 62)
    for i = 0, 5 do K.dashes(1, 6 + i * 10, 3 + i % 3, 23, i * 7 + 3, 100, 125) end   -- the grain

    -- the platter's side band: the strobe dots, lit by the snare
    local off = (spin * 1.0) % (TAU / 36)
    for k = 0, 35 do
      local a = k * TAU / 36 + off
      local s = sin(a)
      if s > -0.1 then
        local x, y = rp(PR, a)
        put(min(13, 1.5 + s * 1.5 + strobe * 9 * (0.4 + 0.6 * s) + mid * 1.5 + hi * 3), x, y + 2, 1, 1)
      end
    end
    K.ring(2.5 + lo * 1.5 + pool * 2, PX, PY, PR, 28, 0, TAU, SQ)
    K.ring(1.5, PX, PY + 3, PR, 20, 0, PI, SQ)

    -- the record: grooves, a fixed sheen where the lamp catches them, the
    -- quiet runs between tracks a shade darker
    local wow = K.swing * 0.6 * sin(spin)
    for gi, r in ipairs(GROOVES) do
      local gl = 1.3 + e * 0.6 + A[K.AMP] * 1.4 + (gi % 3 == 0 and -0.5 or 0)
      K.ring(gl, PX, PY, r, 18 + floor(r / 3), 0, TAU, SQ)
      local sa = -2.3 + wow * 0.3
      K.ring(min(10, gl + 1.5 + lamp * 1.5 + hi * 3.5), PX, PY, r, 3, sa, sa + 0.5, SQ)
      K.ring(min(8, gl + 1 + lamp), PX, PY, r, 3, sa + PI, sa + PI + 0.35, SQ)
    end
    K.ring(3 + e, PX, PY, RR, 26, 0, TAU, SQ)
    -- the label, turning: a print bar and a logo dot
    local function label(l, x0, ang)
      fell(l, x0, PY, 10, 6)
      K.ring(l + 1.5, x0, PY, 10, 14, 0, TAU, SQ)
      -- the printed name: a bold bar from the hole out, and a smaller one
      for w = -1, 1 do
        local ca, sa = cos(ang + w * 0.12), sin(ang + w * 0.12)
        line(l + 4, x0 + 2.5 * ca, PY + 2.5 * sa * SQ, x0 + 8.5 * ca, PY + 8.5 * sa * SQ)
      end
      local cb, sb = cos(ang + PI), sin(ang + PI)
      line(l + 2.5, x0 + 3 * cb, PY + 3 * sb * SQ, x0 + 7 * cb, PY + 7 * sb * SQ)
      K.ring(l + 2, x0, PY, 2.5, 6, 0, TAU, SQ)
    end
    label(2.5 + lamp * 0.5 + lo + mid * 2.5, PX, spin)
    if c > 0.35 then label(1 + c, PX + sin(T * 2.1) * c * 6, spin - 0.8) end
    put(10, PX, PY, 1, 1)                                            -- the spindle

    -- the dust: specks riding round, glinting as they pass the light
    for i = #specks, 1, -1 do
      local d = specks[i]
      local age = T - d.t0
      if age > 2.5 then table.remove(specks, i)
      else
        local a = d.a + spin
        local x, y = rp(d.r, a)
        local lit = max(0, cos(a + 2.0))
        local lv = (2 + d.v * 9 * (1 - age / 2.5)) * (0.4 + 0.6 * lit) + lit * 2
        put(min(13, lv), x, y, 1, 1)
        if age < 0.15 then put(lv * 0.5, x - 1, y, 3, 1) end
      end
    end

    -- the tonearm: its base, counterweight, the arm and headshell, and its
    -- shadow on the record (parting from it as the arm lifts)
    local na = 0.25
    local nx, ny = rp(rn, na)
    local lh = lift * 5
    local bb = bob > 0.3 and 1 or 0
    K.ring(3 + lamp, PIV_X, PIV_Y, 6, 12, 0, TAU, 0.8)
    fell(2.5, PIV_X, PIV_Y, 4, 3)
    put(5 + lamp, PIV_X + 2, PIV_Y - 6, 4, 4)                         -- the weight
    line(4, PIV_X, PIV_Y, PIV_X + 3, PIV_Y - 4)
    -- shadow
    line(1.5, PIV_X - 2, PIV_Y + 4, nx - 2, ny + 4)
    put(1.5, nx - 5, ny + 3, 5, 2)
    -- the arm, bent near the head
    local ax, ay = nx + 6, ny - 5 - lh - bb
    line(6 + lamp + glint * 2, PIV_X, PIV_Y - lh * 0.3, ax, ay)
    line(5 + lamp, PIV_X, PIV_Y + 1 - lh * 0.3, ax, ay + 1)
    line(6 + lamp, ax, ay, nx, ny - 2 - lh - bb)
    put(5 + glint * 6 + hi * 2, nx - 3, ny - 3 - lh - bb, 5, 2)       -- the headshell
    put(min(13, 6 + glint * 7 + hi * 3), nx - 3, ny - 3 - lh - bb, 1, 1)
    put(min(13, 7 + pop * 6), nx, ny - lh - bb, 1, 1)                -- the needle
    if pop > 0.1 then K.ring(4 + pop * 8, nx, ny, 1.5 + (1 - pop) * 5, 8, 0, TAU, 0.7) end
    -- a scratch burns a bright arc along the groove behind the needle
    if scratch > 0.08 then
      for k = 0, 2 do
        K.ring(min(12, 3 + scratch * 9 - k * 2), PX, PY, rn - 2 + k * 2, 5, na - 0.2, na + 0.3 + scratch * 1.6, SQ)
      end
    end
    -- the arm rest and the lift lever
    put(3, 116, 30, 4, 2)
    line(3 + lift * 6, 121, 22, 121, 26 - lift * 3)

    -- the pitch fader, riding with the swing
    line(2, 118, 38, 118, 58)
    for k = 0, 4 do put(1.5, 120, 38 + k * 5, 2, 1) end
    local fy = 47 + floor(K.swing * 6 - 3 + 0.5)
    put(5 + lamp, 116, fy, 5, 3)
    -- start / stop and 33 / 45
    put(3 + lamp * 0.5, 5, 56, 8, 4)
    put(2 + (K.playing and 3 or 0), 15, 57, 3, 2)
    put(2 + (K.playing and 0 or 3), 20, 57, 3, 2)

    -- the target light: a pop-up lamp in the corner, its pool on the
    -- platter edge wobbling with the kick
    local tlx, tly = 10, 50
    line(3, tlx, tly + 4, tlx, tly)
    put(6 + pool * 6, tlx - 1, tly - 2, 3, 2)
    local wx = wob * sin(T * 30) * 2
    local pr = 3 + pool * 3 + lo * 2
    K.ring(2 + pool * 6 + lo * 2 + flare * 4, 20 + wx, 48, pr, 10, 0, TAU, 0.6)
    if pool > 0.2 then K.ring(1.5 + pool * 3, 20 - wx, 48, pr + 3, 10, 0, TAU, 0.6) end

    -- dust in the lamp light above it all
    K.grain(function(u, v) return 14 + u * 80, 10 + v * 46 end, 1 + e * 6 + hi * 14 + hiss * 10, 3 + e * 2 + hi * 3)
  end

  ---------------------------------------------------------------- view 2
  local WX0, WY0, WX1, WY1 = 66, 2, 124, 31          -- the window
  local CITY = K.profile(function(x)
    local h = 5 + floor(K.hash(x // 6, 51) * 11)
    if x // 6 % 5 == 2 then h = h + 6 end
    return WY1 - h
  end)
  local HX, HY = 104, 40                              -- the head's centre (rest)
  local PADX, PADY = 31, 46                           -- the pads' top-left
  local SX0, SY0, SX1 = 26, 34, 88                    -- the sampler

  -- inside the head's outline? (the rain and the city go behind it)
  local function head_has(x, y, hy)
    local dx, dy = (x - HX) / 11, (y - hy) / 12
    if dx * dx + dy * dy < 1 then return true end
    return y > hy + 9 and abs(x - HX) < 20 - max(0, (hy + 16 - y)) * 0.5
  end

  -- view 2 runs a touch dimmer overall, saving the top levels for the hits
  local G2 = 0.75
  local function draw2(S)
    local function g(l) return l * G2 + max(0, l - 6) * (1 - G2) end
    local put = function(l, ...) K.put(g(l), ...) end
    local line = function(l, ...) K.line(g(l), ...) end
    local fell = function(l, ...) fell(g(l), ...) end
    local ring = function(l, ...) K.ring(g(l), ...) end
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid, kl = A[K.LO], A[K.HI], A[K.MID], K.kickless
    local lamp = 0.6 + e * 0.7 + lo * 0.3 + A[K.AMP] * 0.8
    local hy = HY + floor(nod * 2 + 0.5) + (kl > 0.3 and floor(sin(T * 0.8) * kl * 1.5 + 0.5) or 0)

    -- the window: frame, rainy sky glow, the city with lit windows
    line(3, WX0, WY0, WX1, WY0); line(3, WX0, WY0, WX0, WY1)
    line(3, WX1, WY0, WX1, WY1)
    line(3, 95, WY0, 95, WY1)
    put(2.5, WX0 - 2, WY1 + 1, WX1 - WX0 + 5, 1)
    -- the sky's glow over the city, in fine vertical strokes
    for x = WX0 + 1, WX1 - 1, 2 do
      local top = floor(K.at(CITY, x))
      if not head_has(x, top - 4, hy) then
        put(1, x, max(WY0 + 1, top - 13), 1, 8)
        put(1.4 + e * 0.6 + mid * 0.8, x, top - 5, 1, 5)
      end
    end
    -- the rooftops' edges against the glow
    for x = WX0 + 1, WX1 - 2, 2 do
      local top = floor(K.at(CITY, x))
      if not head_has(x, top, hy) then put(2 + e * 0.5, x, top, 2, 1) end
    end
    for x = WX0 + 1, WX1 - 1, 2 do
      local top = floor(K.at(CITY, x))
      for y = top + 2, WY1, 2 do
        local id = x * 64 + y
        local on = K.hash(id, 52) < 0.2 + e * 0.3
        if on and not head_has(x, y, hy) then
          local tw = K.hash(id + floor(T * 0.3 + K.hash(id, 53) * 9), 54) < 0.9 and 1 or 0
          put((1.5 + K.hash(id, 55) * 2.5 + e) * tw, x, y, 1, 1)
        end
      end
    end
    -- a red light on a mast, blinking slowly
    put((sin(T * 2) > 0.3) and 6 or 2, 78, floor(K.at(CITY, 78)) - 3, 1, 1)
    -- rain on the glass: short slanted streaks falling
    local nr = floor(10 + c * 14 + kl * 10)
    for i = 0, nr - 1 do
      local sp = 18 + K.hash(i, 61) * 14
      local x = WX0 + 2 + (K.hash(i, 62) * (WX1 - WX0 - 4) + T * 3) % (WX1 - WX0 - 4)
      local y = WY0 + 1 + (K.hash(i, 63) * 30 + T * sp) % (WY1 - WY0 - 3)
      if not head_has(x, y, hy) then line(1.5 + K.hash(i, 64) * 1.5 + hi, x, y, x - 1, y + 2) end
    end

    -- the desk lamp: base, arm, shade, and its pool on the desk
    put(3, 4, 44, 12, 2)
    line(3 + lamp, 10, 44, 6, 26)
    line(3 + lamp, 6, 26, 16, 13)
    for k = 0, 3 do line(4 + lamp * 0.8, 13 + k, 11 + k, 21 + k, 15 + k) end
    put(min(13, 7 + lamp * 2), 18, 17, 3, 1)                        -- the bulb
    for k = 0, 5 do                                                  -- its light
      line(1 + lamp * 0.25, 19, 19, 6 + k * 5, 43)
    end
    -- the desk: its back edge and the lamp's warm pool across it
    line(2 + lamp * 0.5, 0, 44, SX0 - 1, 44)
    line(2 + lamp * 0.5, SX1 + 1, 44, 127, 44)
    for x = 1, SX0 - 4, 3 do
      local d = abs(x - 14) / 14
      put(1 + lamp * 0.5 * (1 - d), x, 46 + (x % 2), 1, max(1, floor((1 - d * 0.6) * 15 * (0.5 + lamp * 0.3))))
    end
    -- a shelf of records on the wall: spines, one pulled out
    line(2 + lamp * 0.5, 24, 31, 62, 31)
    for k = 0, 16 do
      local x = 26 + k * 2
      local h = 9 + floor(K.hash(k, 91) * 5)
      if k ~= 11 then put(1 + K.hash(k, 92) * 1.5 + lamp * 0.4, x, 31 - h, 1, h) end
    end
    line(2.5 + lamp * 0.6, 48, 30, 53, 18)
    line(2 + lamp * 0.4, 53, 18, 56, 19)

    -- the sampler: body, LCD, knobs, the pads
    line(4, SX0, SY0, SX1, SY0)
    line(3, SX0, SY0, SX0 - 2, 63)
    line(3, SX1, SY0, SX1 + 2, 63)
    -- the LCD and its waveform
    local lx0, ly0, lx1, ly1 = 31, 36, 61, 43
    put(1.5 + e * 0.5, lx0, ly0, lx1 - lx0, ly1 - ly0)
    local ym = (ly0 + ly1) / 2
    for i = 1, WN do
      local w = wave[(i + floor(wacc)) % WN + 1] or 0
      if c > 0.4 and K.hash(i + floor(T * 6), 71) < c * 0.3 then w = w * 1.8 end
      local h = clamp(w * 3.5, 0, 3.4)
      local x = lx0 + i - 1
      if x < lx1 then
        local hs = (hiss > 0.1 and K.hash(i + floor(T * 20), 72) < hiss * 0.5) and 1 or 0
        put(4 + w * 4, x, ym - h - hs, 1, max(1, h * 2 + hs))
      end
    end
    put(9, lx0 + floor(K.bar_ph * (lx1 - lx0)), ly0, 1, ly1 - ly0)  -- the playhead
    -- knobs and a fader on the right
    for k = 0, 3 do
      local kx, ky = 68 + (k % 2) * 9, 38 + (k // 2) * 8
      ring(3 + e, kx, ky, 2.5, 8)
      local a = -2.4 + K.hash(k, 73) * 3 + (k == 0 and lo or k == 1 and mid or k == 2 and hi or e) * 1.2
      line(6, kx, ky, kx + cos(a) * 2.5, ky + sin(a) * 2.5)
    end
    line(2, 72, 55, 84, 55)
    put(5 + e * 2, 74 + floor(e * 8), 54, 2, 3)
    -- the pads: 4 x 4, bottom row first; dim until hit
    for i = 1, NP do
      local col, row = (i - 1) % 4, 3 - (i - 1) // 4
      local x, y = PADX + col * 7 + floor(row * -0.3), PADY + row * 4
      local p = pads[i]
      local l = 1.2 + p * 11
      put(l, x, y, 6, 3)
      if p > 0.15 then put(min(13, l + 1), x + 1, y + 1, 4, 1) end
      if c > 0.4 and p > 0.4 then put(1.5 + p * 3, x + 2, y - 1, 6, 1) end
    end

    -- the head in headphones, from behind: rim-lit by the window, nodding
    -- (its outline only: the black inside hides the window)
    local rl = 3 + e + lo * 1.5
    ring(rl, HX, hy, 11, 18, PI * 1.05, PI * 1.95, 12 / 11)
    ring(rl * 0.8, HX, hy, 11, 12, -PI * 0.05, PI * 0.25, 12 / 11)
    ring(rl * 0.8, HX, hy, 11, 12, PI * 0.75, PI * 1.05, 12 / 11)
    -- the neck and shoulders
    line(rl, HX - 6, hy + 10, HX - 7, hy + 15)
    line(rl, HX + 6, hy + 10, HX + 7, hy + 15)
    line(rl, HX - 7, hy + 15, HX - 20, hy + 21)
    line(rl, HX + 7, hy + 15, HX + 20, hy + 21)
    -- the headphones: band over the top, cups on the sides
    ring(5 + e + lo * 2, HX, hy - 1, 12.5, 14, PI * 1.08, PI * 1.92, 1.1)
    for s = -1, 1, 2 do
      fell(4 + lo * 3 + K.env.kick * 3, HX + s * 12, hy + 1, 2, 4)
      put(min(13, 6 + K.env.kick * 6), HX + s * 12, hy - 1, 1, 3)
    end
    K.grain(function(u, v) return 2 + u * 60, 4 + v * 38 end, 1 + e * 5 + hi * 6, 2 + lamp)
  end

  ---------------------------------------------------------------- frame
  function M.draw(S)
    local DT, DTS = K.DT, K.DTS
    local e, c, kl = K.energy, K.chaos, K.kickless
    -- the record: 33 rpm, scratched back and forth when chaos is up
    local base = K.playing and 3.46 * (1 - 0.15 * kl) or 0.3
    local scr = 0
    if c > 0.45 then scr = (c - 0.45) * 2 * sin(K.T * 4.3) * 9 end
    rv = K.follow(rv, base + scr - scratch * 14, 0.06, DT)
    scratch = scratch * math.exp(-DT / 0.12)
    spin = spin + rv * DTS
    -- the needle works inward over the bars; chaos makes it skip
    rn_to = 34 - (K.bar_ph * 0.5 + 0.25 * sin(K.T * 0.03)) * 14
    local st = floor(K.stepf)
    if c > 0.3 and st ~= last_skip then
      last_skip = st
      if K.hash(st, 81) < (c - 0.3) * 0.6 then rn = rn + (K.hash(st, 82) < 0.5 and 3 or -3); pop = max(pop, 0.5) end
    end
    rn = clamp(K.follow(rn, rn_to, 0.6, DT), 13, 35)
    lift = K.follow(lift, kl > 0.5 and 1 or 0, 0.4, DT)
    strobe = strobe * math.exp(-DT / 0.12)
    pool = pool * math.exp(-DT / 0.25)
    wob = wob * math.exp(-DT / 0.2)
    bob = bob * math.exp(-DT / 0.08)
    pop = pop * math.exp(-DT / 0.12)
    glint = glint * math.exp(-DT / 0.15)
    flare = flare * math.exp(-DT / 0.6)
    hiss = hiss * math.exp(-DT / 0.3)
    -- pads
    for i = #sched, 1, -1 do
      if K.T >= sched[i].t then pad(sched[i].p, 0.8); table.remove(sched, i) end
    end
    for i = 1, NP do pads[i] = pads[i] * math.exp(-DT / 0.16) end
    -- the LCD samples the output
    wacc = wacc + DTS * 12
    local wi = floor(wacc) % WN + 1
    wave[wi] = clamp(A[K.AMP] * (0.6 + 0.4 * sin(K.T * 37)) + K.env.kick * 0.4 + K.env.snare * 0.3, 0, 1)
    -- the nod: a damped spring kicked by the kick
    nodv = nodv + (-nod * 90 - nodv * 11) * DT
    nod = clamp(nod + nodv * DT, -0.5, 1.5)
    if K.view == 2 then draw2(S) else draw1(S) end
  end

  M.init()
  return M
end
