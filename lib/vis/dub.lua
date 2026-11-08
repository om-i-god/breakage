-- dub. view 1: a sound-system yard at night, two big stacks either side, fog
-- on the ground, and every rim / snare dropping a ring on the yard that echoes.
-- view 2: inside a tape echo: a loop of tape runs past erase, record and three
-- playback heads; each hit is written on the tape and comes back fainter at
-- the echo time, a VU needle swings and the spring tank shakes underneath.
--
-- view 1: the kick pumps the cones (air rings puff out of them) and pools a
-- glow on the yard; rim / snare / clap drop rings on the floor that spread
-- out under the fog, repeating fainter at the echo time until the feedback
-- dies; congas puff small rings at the stacks' feet; hats glint in the fog
-- and on the tweeters; a fill sounds the siren up the horns. energy thickens
-- the fog and the glow, chaos jitters and doubles the rings and ghosts the
-- stacks, and kickless stretches let the glow die into a thick fog bank.
-- view 2: hits write marks at the record head; the marks ride the tape and
-- light each playback head they pass (one head at rest, more with energy and
-- chaos), and each pass writes a fainter copy back (the feedback); the kick
-- slams the VU and the capstan, snares and echoes twang the springs.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  ---------------------------------------------------------------- view 1
  local GY = 30                       -- the yard's horizon
  local CX, CY = 64, 47               -- where the hits land on the floor
  local MAXR, MAXE = 11, 8
  local VX = 64                       -- vanishing point x

  -- the skyline behind the yard: rooftops and a tree, black against the glow
  local SKY = K.profile(function(x)
    local h = 2 + math.floor(K.hash(x // 10, 21) * 5)
    if x > 74 and x < 92 then h = h + 4 + math.floor(3 * math.sin((x - 74) / 18 * math.pi)) end
    if x > 40 and x < 46 then h = h + 3 end
    return GY - h
  end)

  local rings, emits, puffs
  local glow, cone, flash, siren, ghost
  local gs, cs = 0, 0                        -- the glow, eased for the big areas

  -- tape echo (view 2)
  local marks
  local tp                            -- the tape's travel, px
  local hl                            -- playback head lamps
  local recl, erasel                  -- record / erase head lamps
  local vu, vuv                       -- the VU needle and its speed
  local spr                           -- the springs' swing (2)
  local cap                           -- capstan glow
  local sps, caps = {0, 0}, 0         -- the same, eased for the drawing
  local MAXM = 32

  function M.init()
    rings, emits, puffs = {}, {}, {}
    glow, cone, flash, siren, ghost = 0, 0, 0, 0, 0
    gs, cs = 0, 0
    marks, tp = {}, 0
    hl = {0, 0, 0}
    recl, erasel = 0, 0
    vu, vuv = 0, 0
    spr = {0, 0}
    cap = 0
    sps, caps = {0, 0}, 0
  end
  M.clear = M.init

  local function spawn(lv, x, y, sp)
    if #rings >= MAXR then table.remove(rings, 1) end
    rings[#rings + 1] = {t0 = K.T, lv = lv, x = x, y = y, sp = sp, seed = math.floor(K.rnd() * 999)}
  end

  -- the tape: write a mark at the record head
  -- full tape: the faintest mark gives way
  local function trim()
    local mi, ml = 1, math.huge
    for i = 1, #marks do if marks[i].lv < ml then mi, ml = i, marks[i].lv end end
    table.remove(marks, mi)
  end
  local function write(lv, w, fb)
    if #marks >= MAXM then trim() end
    marks[#marks + 1] = {s = 20, lv = lv, w = w or 2, fb = fb ~= false, hit = 0}
    recl = math.max(recl, lv / 10)
  end

  local function drop(v, sp, x)
    local c = K.chaos
    x = x or CX + (K.rnd() - 0.5) * (10 + c * 60)
    local y = CY + (K.rnd() - 0.5) * (2 + c * 6)
    local lv = 4 + 7 * v
    spawn(lv, x, y, sp)
    if #emits >= MAXE then table.remove(emits, 1) end
    emits[#emits + 1] = {lv = lv, x = x, y = y, sp = sp, n = 0, next = K.NOW + K.echo_t}
    write(4 + 8 * v, 3)
  end

  function M.snare(v) v = K.num(v, 1); drop(v, 20); flash = math.max(flash, 0.7); spr[1] = spr[1] + 1.6 * v; spr[2] = spr[2] + 1.0 * v end
  function M.rim(v) v = K.num(v, 1); drop(v * 0.8, 28); spr[2] = spr[2] + 0.6 * v end
  function M.clap(v) v = K.num(v, 1); drop(v * 0.9, 16); spr[1] = spr[1] + v end

  function M.kick(v)
    v = K.num(v, 1)
    cone = 1
    glow = math.max(glow, 0.5 + 0.5 * v)
    for side = 0, 1 do
      for b = 1, 1 do
        if #puffs < 12 then puffs[#puffs + 1] = {t0 = K.T, side = side, b = b, v = v} end
      end
    end
    vuv = vuv + 9 * v
    cap = 1
    spr[1] = spr[1] + 0.3 * v; spr[2] = spr[2] + 0.3 * v
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    if open then write(1.5 + 2 * v, 1, false) end
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 1 or kind == 2 or kind == 7 then
      local side = K.rnd() < 0.5 and 0 or 1
      spawn(3 + 4 * v, side == 0 and 22 or 106, 55, 12)
      write(2 + 4 * v, 1)
    else
      flash = math.max(flash, 0.4 * v)
      write(2 + 3 * v, 1, false)
    end
  end
  function M.tom(v) M.perc(1, v) end

  function M.brk(s, n)
    s, n = K.num(s, 1), math.max(1, K.num(n, 8))
    local x = 40 + (s - 0.5) / n * 48
    spawn(4, x, CY + 2, 18)
    if s % 2 == 1 then write(2.5, 1, false) end
  end
  function M.tick() ghost = math.max(ghost, 0.5) end

  function M.fill()
    siren = 1
    for k = 0, 2 do
      if #rings >= MAXR then table.remove(rings, 1) end
      rings[#rings + 1] = {t0 = K.T + k * 0.15, lv = 7 - k, x = CX, y = CY, sp = 24, seed = k * 7}
    end
    hl[1], hl[2], hl[3] = 1, 1, 1
  end

  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 12)
    local x = CX + (K.rnd() - 0.5) * 50
    for k = 0, n - 1 do
      if #rings >= MAXR then table.remove(rings, 1) end
      rings[#rings + 1] = {t0 = K.T - k * 0.06, lv = 7 - k * 0.4, x = x + k * (K.rnd() - 0.5) * 6, y = CY,
        sp = 26, seed = k * 13}
    end
    for k = 0, math.min(n, 6) - 1 do
      if #marks >= MAXM then trim() end
      marks[#marks + 1] = {s = 20 - k * 3, lv = 9 - k, w = 1, fb = false, hit = 0}
    end
    spr[1] = spr[1] + 1
  end

  -- the echo emitters (view 1): each repeats at the echo time, fainter
  local function echoes(c)
    for i = #emits, 1, -1 do
      local em = emits[i]
      local n = 0
      while K.NOW >= em.next and n < 4 do
        em.lv = em.lv * K.echo_fb
        em.n = em.n + 1
        if em.lv >= 1.2 then spawn(em.lv, em.x + (K.rnd() - 0.5) * c * 14, em.y, em.sp) end
        em.next = em.next + K.echo_t
        n = n + 1
      end
      if em.lv < 1.2 or em.n >= 8 then table.remove(emits, i) end
    end
  end

  -- behind a stack's front face?
  local function hidden(x, y)
    if y > 51 then return false end
    return x < 37 or x > 91
  end

  -- a ring on the yard floor: the far half flatter than the near half, the
  -- part behind the horizon and the stacks left out
  local function fring(lv, cx, cy, r, jit, seed)
    local segs = clamp(math.floor(10 + r * 0.15), 10, 16)
    local px, py, pok
    for k = 0, segs do
      local a = K.TAU * k / segs
      local rr = r
      if jit > 0 then rr = r + (K.hash(k % segs + seed * 61, 7) - 0.5) * 2 * jit end
      local s = math.sin(a)
      local x = cx + math.cos(a) * rr * 1.25
      local y = cy + s * rr * (s < 0 and 0.2 or 0.34)
      local ok = y > GY + 0.5 and not hidden(x, y)
      if px and ok and pok then line(lv, px, py, x, y) end
      px, py, pok = x, y, ok
    end
  end

  local function stack(side, g, cb, lo, hi, e, c)
    local x0 = side == 0 and 3 or 97
    local w = 28
    local top, bot = 3, 51
    local mid = A[K.MID]
    local edge = 2.5 + g * 0.7 + e
    -- the side face, receding toward the yard
    local sx, dir = side == 0 and x0 + w or x0, side == 0 and 1 or -1
    -- (in short runs, so a glitch tear moves a slice and not the stack)
    local yt, yb = top + (GY - top) * 0.06, bot - (bot - GY) * 0.06
    local xa = side == 0 and sx + 1 or sx - 3
    for y = yt, yb - 1, 8 do
      local y1 = math.min(yb, y + 8)
      put(1 + g * 0.5, xa, y, 3, y1 - y)
    end
    local ft, fb = top + (GY - top) * 0.11, bot - (bot - GY) * 0.11
    for y = ft, fb - 1, 8 do
      line(edge * 0.7, sx + dir * 4, y, sx + dir * 4, math.min(fb, y + 8) - 1)
    end
    -- the front: three cabinets
    local fx0, fx1 = x0, x0 + w - 1
    line(edge + 1, fx0, top, fx1, top)              -- moonlit top
    for y = top, bot - 1, 8 do
      local y1 = math.min(bot, y + 8)
      line(edge, fx0, y, fx0, y1)
      line(edge, fx1, y, fx1, y1)
    end
    line(edge * 0.8, fx0, top + 11, fx1, top + 11)
    line(edge * 0.8, fx0, top + 30, fx1, top + 30)
    line(edge * 0.6, fx0, bot, fx1, bot)
    -- the horn: a flared slot lit by the mids, the snare and the siren
    local hlv = 1.5 + mid * 3 + K.env.snare * 4 + siren * 6 + flash * 2
    local hx = x0 + w / 2
    for k = 0, 2 do
      local yy = top + 3 + k * 2
      local hw = 9 - k * 2 + siren * math.sin(K.T * 9 + k) * 1.5
      put(hlv * (1 - k * 0.2), hx - hw, yy, hw * 2, 1)
    end
    -- tweeter glints with the hats
    put(1.5 + hi * 6 + K.env.hat * 5, x0 + 3, top + 2, 2, 1)
    put(1.5 + hi * 6 + K.env.ohat * 6, fx1 - 4, top + 2, 2, 1)
    -- two 18" bins, cones breathing
    for b = 0, 1 do
      local cy = top + 21 + b * 19
      local br = 7.5 + cb * (0.8 - b * 0.2) + 0.25 * math.sin(K.T * 1.1 + side * 2 + b)
      K.ring(math.min(9, 2.5 + cb * 3.5 + lo * 1.2), hx, cy, br + 1.5, 14)
      K.ring(math.min(8, 1.5 + cb * 2.5 + lo), hx, cy, br - 1.5, 10)
      K.disc(math.min(11, 2 + cb * 6 + lo * 2), hx, cy, 1.3 + cb * 0.8)
      if c > 0.3 then
        local gx = math.sin(K.T * 2.3 + side * 2 + b * 1.3) * c * 5
        K.ring(1 + c * 2, hx + gx, cy, br + 3, 12)
      end
    end
    -- the amp's power lamp at the stack foot
    put(2 + e * 6 + cb * 3, x0 + 2, bot - 2, 2, 1)
  end

  local function draw1(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl = A[K.LO], A[K.HI], K.kickless
    echoes(c)
    local g = math.max(gs, lo * 0.6) * (1 - kl * 0.6)
    local cb = math.min(1.4, cs * (1 + e * 0.4))

    -- the sky: stars, a low moon in the haze, and a sodium glow behind
    -- the rooftops
    for i = 0, 15 do
      local x, y = math.floor(K.hash(i, 1) * 127), 1 + math.floor(K.hash(i, 2) * 14)
      if x > 34 and x < 94 then
        local tw = 0.5 + 0.5 * math.sin(T * (0.5 + K.hash(i, 3)) + i * 1.7)
        put(1 + tw * (0.8 + hi * 2.5 + kl * 1.5), x, y, 1, 1)
      end
    end
    local mx, my = 54, 9 + math.sin(T * 0.05) * 0.5
    K.disc(2.5 + kl * 1.5 + e, mx, my, 4.5)
    K.disc(3.5 + kl * 2 + e, mx - 1, my - 1, 2.5)
    K.ring(1.2 + g * 0.8, mx, my, 7.5 + g * 1.5, 14)
    K.gradient(GY - 9, GY, function(y)
      local u = (y - GY + 9) / 9
      return 0.6 + u * u * (2 + e * 0.8 + g * 0.8) + kl * 0.3
    end, SKY, 35, 93)
    for i = 0, 5 do                                  -- a few lit windows
      local x = 38 + math.floor(K.hash(i, 31) * 50)
      local y = math.floor(K.at(SKY, x) + 2 + K.hash(i, 32) * 3)
      if y < GY - 1 then put(1.5 + 1.5 * math.sin(T * 0.2 + i * 2) ^ 2 + e, x, y, 1, 1) end
    end
    -- the yard's back wall (the skyline's base) and the horizon
    line(1.5 + g * 3 + K.bar_pulse * 1.5, 37, GY, 91, GY)

    -- the floor: dim rows running back, the kick's glow pooling between
    -- the stacks, wider and brighter toward us
    for y = GY + 3, 63, 4 do
      local u = (y - GY) / (63 - GY)
      local off = (T * 3 * (0.3 + u)) % 9
      if y > 51 then K.dashes(1, y, 2 + math.floor(u * 3), 9, off + y * 3)
      else K.dashes(1, y, 2 + math.floor(u * 3), 9, off + y * 3, 37, 91) end
    end
    for y = GY + 1, 63 do
      local u = (y - GY) / (63 - GY)
      local w = 8 + u * 22 + g * 10 + e * 3
      local v = g * (0.2 + u * 1.1) * (0.6 + e * 0.4)
      for ring_i = 0, 1 do
        local hw = w * (1 - ring_i * 0.45)
        local vv = v * (0.5 + ring_i * 0.6)
        if vv > 0.05 then
          K.gradient(y, y, function() return vv end, nil, math.floor(VX - hw), math.floor(VX + hw))
        end
      end
    end
    -- the rings on the yard floor, spreading and fading
    for i = #rings, 1, -1 do
      local R = rings[i]
      local age = K.T - R.t0
      local life = 2.4 + e + kl * 1.2
      if age > life then table.remove(rings, i)
      elseif age >= 0 then
        local u = age / life
        local r = 2 + age * R.sp * (1 - kl * 0.35)
        local lv = R.lv * (1 - u) ^ 1.1 + hi * 1.5 * (1 - u)
        local jit = c * 3.5 * (1 - u)
        fring(lv, R.x, R.y, r, jit, R.seed)
        if age < 0.35 then fring(lv * 0.6, R.x, R.y, r + 1.5, jit, R.seed + 1) end
        if c > 0.4 and i % 2 == 0 then
          fring(lv * 0.5, R.x + c * 5 * math.sin(R.seed), R.y + 1, r * 0.8, jit * 2, R.seed + 3)
        end
      end
    end
    if flash > 0.05 then put(3 + flash * 9, CX - 1, CY - 1, 3, 1) end

    -- the stacks, with puffs of air out of the cones on each kick
    stack(0, g, cb, lo, hi, e, c)
    stack(1, g, cb, lo, hi, e, c)
    for i = #puffs, 1, -1 do
      local P = puffs[i]
      local u = (K.T - P.t0) / 0.4
      if u >= 1 then table.remove(puffs, i)
      elseif u >= 0 then
        local hx = P.side == 0 and 17 or 111
        K.ring((1 + 3 * P.v) * (1 - u), hx, 24 + P.b * 19, 10.5 + u * 4, 12)
      end
    end

    -- the fog: a bank on the horizon and drifting banks through the yard,
    -- lit warmer where the kick's glow is
    K.gradient(GY - 3, GY + 6, function(y) return (0.35 + kl * 0.5 + e * 0.2) * (1 - math.abs(y - GY - 1) / 6) end,
      nil, 37, 91)
    local fd = 0.17 + 0.12 * e + 0.2 * kl
    K.haze(28, GY + 4, 100, 54, fd, 1, T * 6)
    if g > 0.25 then K.haze(40, GY + 6, 88, 50, fd * g, 2, T * 6 + 30) end
    K.grain(function(u, v) return 30 + u * 68, GY - 4 + v * 22 end, 3 + hi * 14 + e * 6 + ghost * 20, 3 + hi * 4)
  end

  ---------------------------------------------------------------- view 2
  -- the loop: a stadium, bottom run left to right past the heads
  local XL, XR, TCY, TR = 24, 104, 19, 11
  local RUN = XR - XL
  local P = 2 * RUN + 2 * math.pi * TR
  local REC = 20                      -- record head at s = 20 (x 44)
  local HD = 18                       -- head spacing (echo time per head)

  local function at(s)
    s = s % P
    if s < RUN then return XL + s, TCY + TR, 0 end
    s = s - RUN
    if s < math.pi * TR then
      local th = math.pi / 2 - s / TR
      return XR + TR * math.cos(th), TCY + TR * math.sin(th), th
    end
    s = s - math.pi * TR
    if s < RUN then return XR - s, TCY - TR, 1 end
    s = s - RUN
    local th = -math.pi / 2 - s / TR
    return XL + TR * math.cos(th), TCY + TR * math.sin(th), th
  end

  -- a mark across the tape at s
  local function tmark(l, s, w)
    s = s % P
    local x, y, th = at(s)
    if s < RUN or (s >= RUN + math.pi * TR and s < 2 * RUN + math.pi * TR) then
      put(l, x, y - 1, w, 3)
    else
      local cx = (s < RUN + math.pi * TR) and XR or XL
      local ca, sa = math.cos(th), math.sin(th)
      line(l, cx + ca * (TR - 1), TCY + sa * (TR - 1), cx + ca * (TR + 1), TCY + sa * (TR + 1))
    end
  end

  local function draw2(S)
    local T, DT, DTS, e, c = K.T, K.DT, K.DTS, K.energy, K.chaos
    local lo, hi, kl, mid = A[K.LO], A[K.HI], K.kickless, A[K.MID]
    local et = math.max(0.08, K.echo_t)
    local v = HD / et
    local flutter = 1 + c * 0.25 * math.sin(T * 7.3) + c * 0.12 * math.sin(T * 17.1)
    local step = v * DTS * flutter
    tp = (tp + step) % P
    local nheads = 1
    if e > 0.35 or c > 0.3 then nheads = 2 end
    if e > 0.8 or c > 0.6 then nheads = 3 end
    local fb = K.echo_fb

    -- the marks ride the tape: each playback head they pass lights, and
    -- feeds a fainter copy back to the record head
    local nm = #marks
    for i = nm, 1, -1 do
      local m = marks[i]
      local s0 = m.s
      m.s = m.s + step
      for h = 1, 3 do
        local hs = REC + h * HD
        if s0 < hs and m.s >= hs then
          if h <= nheads then
            hl[h] = math.max(hl[h], m.lv / 9)
            spr[1] = spr[1] + m.lv * 0.03
            spr[2] = spr[2] + m.lv * 0.02
            if m.fb then
              local cl = m.lv * fb * (h == 1 and 1 or 0.6)
              if cl >= 1.3 and #marks < MAXM + 4 then
                marks[#marks + 1] = {s = REC + (m.s - hs), lv = cl, w = m.w, fb = true, hit = 0}
              end
            end
          end
        end
      end
      m.lv = m.lv * math.exp(-DTS / 6)
      if m.s >= P + 10 or m.lv < 0.8 then
        erasel = math.max(erasel, m.lv / 10)
        table.remove(marks, i)
      end
    end
    while #marks > MAXM do trim() end
    for h = 1, 3 do hl[h] = hl[h] * math.exp(-DT / 0.15) end
    recl = recl * math.exp(-DT / 0.12)
    erasel = erasel * math.exp(-DT / 0.12)
    cap = cap * math.exp(-DT / 0.2)
    -- the VU: a needle with a little mass
    local tgt = clamp(A[K.AMP] * 0.8 + K.env.kick * 0.25, 0, 1.1)
    vuv = vuv + ((tgt - vu) * 120 - vuv * 14) * DT
    vu = clamp(vu + vuv * DT, -0.05, 1.15)
    for k = 1, 2 do
      spr[k] = math.min(3, spr[k] * math.exp(-DT / (0.4 + e * 0.3)))
      sps[k] = K.follow(sps[k], spr[k], 0.07, DT)
    end
    caps = K.follow(caps, cap, 0.06, DT)

    -- the chassis: a dim plate with its seams and screws
    line(1, 1, 1, 1, 39)
    line(1, 126, 1, 126, 39)
    for _, p in ipairs({{3, 3}, {123, 3}, {3, 37}, {123, 37}}) do put(2, p[1], p[2], 2, 2) end

    -- the tape: its body, edges and oxide grain sliding past
    local tb = 1 + e * 0.25 + lo * 0.2
    put(tb, XL, TCY + TR - 2, RUN, 5)
    put(tb, XL, TCY - TR - 2, RUN, 5)
    for _, cx in ipairs({XL, XR}) do
      local a0 = cx == XR and -math.pi / 2 or math.pi / 2
      for dr = -2, 2 do K.ring(tb, cx, TCY, TR + dr, 12, a0, a0 + math.pi) end
    end
    for k = 0, 18 do
      local s = (k * P / 19 + tp) % P
      tmark(1.5 + e + hi, s, 1)
    end
    -- the guide rollers: spokes turning with the tape
    for _, cx in ipairs({XL, XR}) do
      local rot = tp / (TR - 4)
      K.ring(2 + caps * 3 + lo, cx, TCY, 6, 12)
      for k = 0, 2 do
        local a = rot + k * K.TAU / 3
        line(2 + caps * 2, cx, TCY, cx + math.cos(a) * 5, TCY + math.sin(a) * 5)
      end
      put(3 + caps * 5, cx - 1, TCY - 1, 2, 2)
    end

    -- the marks
    for i = 1, #marks do
      local m = marks[i]
      if m.s >= 0 then
        local j = c > 0.3 and math.sin(T * 11 + i * 1.7) * c * 2 or 0
        tmark(math.min(9, 1.2 + m.lv * 0.8), m.s + j, m.w)
      end
    end

    -- the heads under the bottom run: erase, record, three playback
    local hy = TCY + TR + 4
    local function head(x, lamp, on)
      local l = on and 1.5 or 1
      put(l, x - 3, hy + 1, 7, 4)
      line(l + 1.5, x - 3, hy, x + 3, hy)
      put(math.min(13, 2 + lamp * 11), x, hy - 1, 1, 6)
      if lamp > 0.08 then put(lamp * 7, x - 2, hy - 7, 5, 1) end
      put(on and (3 + lamp * 9) or 1, x, hy + 6, 1, 1)
    end
    head(XL + 10, erasel, true)
    head(XL + REC, recl, true)
    for h = 1, 3 do head(XL + REC + h * HD, hl[h], h <= nheads) end

    -- the VU, inside the loop: an arc, a scale, a needle
    local vx, vy, vr = 64, 23, 10
    K.ring(2 + e, vx, vy, vr, 10, math.pi + 0.5, K.TAU - 0.5)
    for k = 0, 6 do
      local a = math.pi + 0.5 + (math.pi - 1) * k / 6
      local ll = k >= 5 and (3 + lo * 4) or 2
      line(ll, vx + math.cos(a) * (vr + 1), vy + math.sin(a) * (vr + 1), vx + math.cos(a) * (vr + 3), vy + math.sin(a) * (vr + 3))
    end
    local na = math.pi + 0.5 + (math.pi - 1) * clamp(vu, 0, 1.05)
    line(6 + vu * 5, vx, vy, vx + math.cos(na) * (vr - 1), vy + math.sin(na) * (vr - 1))
    put(3, vx - 1, vy, 3, 1)
    -- the knobs: echo time and feedback
    for k, val in ipairs({et / 1.2, fb}) do
      local kx, ky = 44 + (k - 1) * 40, 16
      K.ring(2, kx, ky, 3, 8)
      local a = math.pi * 0.75 + val * math.pi * 1.5
      line(4 + e * 3, kx, ky, kx + math.cos(a) * 3, ky + math.sin(a) * 3)
    end

    -- the spring tank: two coils, swinging with the hits
    line(1, 3, 43, 124, 43)
    line(1.5, 3, 43, 3, 62)
    line(1.5, 124, 43, 124, 62)
    for k = 1, 2 do
      local by = 48 + (k - 1) * 9
      local sk = sps[k]
      put(math.min(7, 2 + sk * 2), 5, by - 2, 3, 5)
      put(math.min(7, 2 + sk * 2), 119, by - 2, 3, 5)
      local amp = math.min(2.4, sk * (0.6 + c * 0.4)) + 0.15
      local lv = math.min(3.4, 1 + sk * 1.2 + mid * 0.4)
      local px, py
      local n = 38
      for j = 0, n do
        local x = 8 + j * 111 / n
        local w = math.sin(x * 0.11 - T * (5 + k)) * amp + math.sin(x * 0.29 + T * 2.5 + k) * amp * 0.35
        local y = by + w + ((j % 2 == 0) and -1.5 or 1.5)
        if px then line(lv, px, py, x, y) end
        px, py = x, y
      end
      if c > 0.45 then
        px = nil
        for j = 0, 18 do
          local x = 8 + j * 111 / 18
          local y = by + math.sin(x * 0.17 + T * 7 + k) * amp * c
          if px then line(1 + c * 0.8, px, py, x, y) end
          px, py = x, y
        end
      end
    end
    -- the tank's lamp: the reverb's tail
    put(2 + (spr[1] + spr[2]) * 1.5, 61, 63, 6, 1)
    K.grain(function(u, w) return 6 + u * 116, 44 + w * 17 end, 2 + hi * 10 + (spr[1] + spr[2]) * 3, 2 + hi * 4)
  end

  function M.draw(S)
    glow = K.follow(glow, 0, 0.35, K.DT)
    gs = K.follow(gs, glow, 0.08, K.DT)
    cs = K.follow(cs, cone, 0.05, K.DT)
    cone = cone * math.exp(-K.DT / 0.12)
    flash = flash * math.exp(-K.DT / 0.2)
    siren = siren * math.exp(-K.DT / 0.6)
    ghost = ghost * math.exp(-K.DT / 0.3)
    if K.view == 2 then
      echoes(K.chaos)
      draw2(S)
    else
      draw1(S)
    end
  end

  M.init()
  return M
end
