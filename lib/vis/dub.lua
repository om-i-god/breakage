-- dub. view 1: a sound-system yard at night, two big stacks either side, fog
-- on the ground, and every rim / snare dropping a ring on the yard that echoes.
-- view 2: inside a tape echo: a loop of tape runs past erase, record and three
-- playback heads; each hit is written on the tape and comes back fainter at
-- the echo time, a VU needle swings and the spring tank shakes underneath.
-- view 3: the dubplate: a record turning on the deck, seen from above at a
-- slant; every hit is cut into the groove under the needle and its echoes
-- are cut in after it, a spiral of fading marks wound round the record.
--
-- view 1: the kick pumps the cones (air rings puff out of them) and pools a
-- glow on the yard; rim / snare / clap drop rings on the floor that spread
-- out under the fog, repeating fainter at the echo time until the feedback
-- dies; congas puff small rings at the stacks' feet, cowbell / clave / metal
-- ping a bright line across a horn; closed hats glint on the tweeters, open
-- hats throw sparks up out of the fog, rides twinkle the stars; a fill
-- sounds the siren: waves rise out of the horns. a light walks the back wall
-- through the bar, and over the phrase the moon climbs and the stars come
-- out; the last bar of the phrase thickens the fog. energy thickens the fog
-- and the glow, chaos jitters and doubles the rings and ghosts the stacks,
-- and kickless stretches let the glow die into a thick fog bank.
-- view 2: hits write marks at the record head; the marks ride the tape and
-- light each playback head they pass (one head at rest, more with energy and
-- chaos), and each pass writes a fainter copy back (the feedback); the kick
-- slams the VU and the capstan, snares and echoes twang the springs, closed
-- hats flick the erase head, open hats write a faint hiss; every bar cuts a
-- splice into the tape and the phrase lamps fill along the chassis.
-- view 3: the record turns once a bar; the needle sits on the right and
-- winds inward over the phrase, so the marks spiral in. the kick sends a
-- wave out across the grooves and thumps the label and the tonearm; snares
-- cut long arcs, claps a pair, rims a nick, each followed by its echoes at
-- the echo time, fainter by the feedback; congas and toms cut the inner
-- grooves, bells ping the label; closed hats spark the needle, open hats
-- lift dust off the vinyl, rides sparkle the strobe dots; a ratchet cuts a
-- row of ticks; a fill pulls the record back (a spinback) and the siren
-- lamp burns. energy brightens the sheen and the marks, chaos warps the
-- record and doubles the cuts, kickless the platter drags and a haze hangs
-- over it.
--
-- the ears: view 1, the lows pool the glow and pump the cones, the mids open
-- and light the horns, warm the mid cabinets and ring the yard, the highs
-- glint the stars, tweeters and fog; view 2, the lows swell the tape and the
-- rollers and the tank's transducers, the mids light the heads and shake the
-- springs, the highs glitter on the oxide and in the tank; the lows and the
-- level light the side rails. view 3, the lows swell the grooves and the
-- platter's rim, the mids light the sheen and the label, the highs throw
-- dust glints over the vinyl, the level lights the strobe dots.
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

  -- the phrase (all views), eased: 0 at its first bar, 1 at its end
  local pp = 0
  local sparks                        -- view 1: open-hat sparks over the fog
  local pings                         -- view 1: bell pings across a horn
  local splice                        -- view 2: the bar's splice lamp

  -- view 3: the dubplate
  local pmarks, pemits, motes
  local rot, spin                     -- the record's angle, its speed (1 = a bar a turn)
  local kwave                         -- kick waves: {t0, v}
  local lthump, arm, nsp, slamp       -- label thump, tonearm bounce, needle spark, siren lamp
  local rn                            -- the needle's radius, eased
  local MAXPM = 18

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
    pp = 0
    sparks, pings, splice = {}, {}, 0
    pmarks, pemits, motes = {}, {}, {}
    rot, spin = 0, 1
    kwave = {}
    lthump, arm, nsp, slamp = 0, 0, 0, 0
    rn = 40
  end
  M.clear = M.init

  -- view 3: cut a mark into the groove under the needle (or at angle a)
  local function cut(lv, len, kind, r, a)
    if #pmarks >= MAXPM then
      local mi, ml = 1, math.huge
      for i = 1, #pmarks do if pmarks[i].lv < ml then mi, ml = i, pmarks[i].lv end end
      table.remove(pmarks, mi)
    end
    pmarks[#pmarks + 1] = {a = a or (-0.35 - rot), r = r or rn, lv = lv, len = len, kind = kind or 1,
      t0 = K.T, j = (K.rnd() - 0.5) * 2}
    nsp = math.max(nsp, lv / 12)
  end
  local function pecho(lv, len, kind)
    if #pemits >= 6 then table.remove(pemits, 1) end
    pemits[#pemits + 1] = {lv = lv, len = len, kind = kind, n = 0, next = K.NOW + K.echo_t}
  end

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

  function M.snare(v)
    v = K.num(v, 1); drop(v, 20); flash = math.max(flash, 0.7); spr[1] = spr[1] + 1.6 * v; spr[2] = spr[2] + 1.0 * v
    cut(5 + 6 * v, 0.42, 1); pecho(5 + 6 * v, 0.42, 1)
  end
  function M.rim(v)
    v = K.num(v, 1); drop(v * 0.8, 28); spr[2] = spr[2] + 0.6 * v
    cut(4 + 5 * v, 0.1, 3); pecho(4 + 5 * v, 0.1, 3)
  end
  function M.clap(v)
    v = K.num(v, 1); drop(v * 0.9, 16); spr[1] = spr[1] + v
    cut(4 + 6 * v, 0.16, 2); pecho(4 + 6 * v, 0.16, 2)
  end

  function M.kick(v)
    v = K.num(v, 1)
    cone = 1
    glow = math.max(glow, 0.5 + 0.5 * v)
    for side = 0, 1 do
      if #puffs < 12 then puffs[#puffs + 1] = {t0 = K.T, side = side, b = 1, v = v} end
    end
    vuv = vuv + 9 * v
    cap = 1
    spr[1] = spr[1] + 0.3 * v; spr[2] = spr[2] + 0.3 * v
    if #kwave >= 4 then table.remove(kwave, 1) end
    kwave[#kwave + 1] = {t0 = K.T, v = v}
    lthump, arm = 1, math.max(arm, v)
  end

  local function spark(n, lv)
    for _ = 1, n do
      if #sparks >= 10 then table.remove(sparks, 1) end
      sparks[#sparks + 1] = {x = 40 + K.rnd() * 48, y = GY + 6 + K.rnd() * 14, t0 = K.T, lv = lv,
        dx = (K.rnd() - 0.5) * 6}
    end
  end
  local function mote(n, lv)
    for _ = 1, n do
      if #motes >= 12 then table.remove(motes, 1) end
      local a, r = K.rnd() * K.TAU, 14 + K.rnd() * 28
      motes[#motes + 1] = {a = a, r = r, t0 = K.T, lv = lv}
    end
  end

  function M.hat(v, open)
    v = K.num(v, 1)
    if open then
      write(1.5 + 2 * v, 1, false)
      spark(2, 4 + 5 * v)
      mote(2, 4 + 5 * v)
    else
      erasel = math.max(erasel, 0.25 * v)
      nsp = math.max(nsp, 0.35 + 0.4 * v)
    end
  end
  function M.ride(v)
    v = K.num(v, 1)
    erasel = math.max(erasel, 0.2 * v)
    mote(1, 3 + 3 * v)
  end

  function M.perc(kind, v)
    v = K.num(v, 1)
    if kind == 1 or kind == 2 or kind == 7 or kind == 13 or kind == 17 or kind == 18 then
      local side = K.rnd() < 0.5 and 0 or 1
      spawn(3 + 4 * v, side == 0 and 22 or 106, 55, 12)
      write(2 + 4 * v, 1)
      cut(3 + 4 * v, 0.08, 4, 15 + K.rnd() * 6, K.rnd() * K.TAU)
    elseif kind == 3 or kind == 4 or kind == 6 or kind == 21 or kind == 11 or kind == 8 then
      if #pings >= 4 then table.remove(pings, 1) end
      pings[#pings + 1] = {side = K.rnd() < 0.5 and 0 or 1, t0 = K.T, v = v}
      flash = math.max(flash, 0.3 * v)
      write(2 + 3 * v, 1, false)
      lthump = math.max(lthump, 0.6 * v)
    else
      flash = math.max(flash, 0.4 * v)
      write(2 + 3 * v, 1, false)
      if kind == 15 then ghost = math.max(ghost, 0.8) end
      cut(2 + 3 * v, 0.05, 4)
    end
  end
  function M.tom(v)
    v = K.num(v, 1)
    local side = K.rnd() < 0.5 and 0 or 1
    spawn(3 + 5 * v, side == 0 and 22 or 106, 55, 10)
    write(2 + 4 * v, 2)
    cut(4 + 5 * v, 0.22, 4, 16 + K.rnd() * 4, K.rnd() * K.TAU)
  end

  function M.brk(s, n)
    s, n = K.num(s, 1), math.max(1, K.num(n, 8))
    local x = 40 + (s - 0.5) / n * 48
    spawn(4, x, CY + 2, 18)
    if s % 2 == 1 then write(2.5, 1, false) end
    cut(3, 0.06, 3, 38, (s - 0.5) / n * K.TAU)
  end
  function M.tick() ghost = math.max(ghost, 0.5); nsp = math.max(nsp, 0.3) end

  function M.fill()
    siren = 1
    for k = 0, 2 do
      if #rings >= MAXR then table.remove(rings, 1) end
      rings[#rings + 1] = {t0 = K.T + k * 0.15, lv = 7 - k, x = CX, y = CY, sp = 24, seed = k * 7}
    end
    hl[1], hl[2], hl[3] = 1, 1, 1
    spin = -2.2                                  -- the selector pulls it back
    slamp = 1
  end

  function M.bar()
    splice = 1
    write(5, 1, false)
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
    for k = 0, math.min(n, 8) - 1 do cut(12 - k * 0.5, 0.04, 5, rn, -0.35 - rot + 0.13 * k) end
    arm = math.max(arm, 1)
    nsp = 1
    if #kwave >= 4 then table.remove(kwave, 1) end
    kwave[#kwave + 1] = {t0 = K.T, v = 1}
    lthump = math.max(lthump, 0.7)
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
    line(edge * 0.6, fx0, bot, fx1, bot)
    -- the horn: a flared slot lit by the mids, the snare and the siren
    local hlv = 1.2 + mid * 5 + K.env.snare * 4 + siren * 6 + flash * 2
    local hx = x0 + w / 2
    for k = 0, 3 do
      local yy = top + 3 + k * 2
      local hw = 6 + mid * 4 - k * 1.5 + siren * math.sin(K.T * 9 + k) * 1.5
      put(hlv * (1 - k * 0.2), hx - hw, yy, hw * 2, 1)
    end
    -- the mid cabinet's dividers warm with the body of the mix
    line(edge * 0.8 + mid * 2.5, fx0, top + 11, fx1, top + 11)
    line(edge * 0.8 + mid * 2.5, fx0, top + 30, fx1, top + 30)
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
    local lo, hi, kl, mid = A[K.LO], A[K.HI], K.kickless, A[K.MID]
    echoes(c)
    local g = math.max(gs, lo * 0.6) * (1 - kl * 0.6)
    local cb = math.min(1.4, cs * (1 + e * 0.4))

    -- the sky: stars, a low moon in the haze, and a sodium glow behind
    -- the rooftops
    -- (more of them come out as the phrase goes on; the ride twinkles them)
    local rd = K.env.ride
    for i = 0, 21 do
      local x, y = math.floor(K.hash(i, 1) * 127), 1 + math.floor(K.hash(i, 2) * 14)
      if x > 34 and x < 94 and K.hash(i, 4) < 0.5 + pp * 0.5 + kl * 0.3 then
        local tw = 0.5 + 0.5 * math.sin(T * (0.5 + K.hash(i, 3)) + i * 1.7)
        put(1 + tw * (0.8 + hi * 2.5 + kl * 1.5 + rd * 3), x, y, 1, 1)
      end
    end
    -- the moon climbs through the phrase
    local mx, my = 54, 11.5 - pp * 4 + math.sin(T * 0.05) * 0.5
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
    -- a lamp walks the back wall through the bar
    local wx = 38 + K.bar_ph * 50
    put(2 + lo * 2 + e * 1.5 + K.bar_pulse * 2, wx, GY - 1, 3, 1)
    put(1 + lo + e, wx - 3, GY - 1, 3, 1)

    -- the floor: dim rows running back, the kick's glow pooling between
    -- the stacks, wider and brighter toward us
    for y = GY + 3, 63, 4 do
      local u = (y - GY) / (63 - GY)
      local off = (T * 3 * (0.3 + u)) % 9
      if y > 51 then K.dashes(1, y, 1 + math.floor(u * 3), 9, off + y * 3)
      else K.dashes(1, y, 1 + math.floor(u * 3), 9, off + y * 3, 37, 91) end
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
        local lv = R.lv * (1 - u) ^ 1.1 * (0.6 + mid * 0.7) + hi * 1.5 * (1 - u)
        local jit = c * 3.5 * (1 - u)
        fring(lv, R.x, R.y, r, jit, R.seed)
        if age < 0.35 + mid * 0.2 then fring(lv * 0.6, R.x, R.y, r + 1.5, jit, R.seed + 1) end
        if c > 0.4 and i % 2 == 0 then
          fring(lv * 0.5, R.x + c * 5 * math.sin(R.seed), R.y + 1, r * 0.8, jit * 2, R.seed + 3)
        end
      end
    end
    if flash > 0.05 then put(3 + flash * 9, CX - 1, CY - 1, 3, 1) end
    if mid > 0.08 then
      for k = 0, 1 do
        local r = 5 + k * 6 + mid * 4 + math.sin(T * 1.3 + k) * 0.8
        fring(mid * (3 - k), CX, CY, r, 0, 90 + k)
      end
    end

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
    -- bells ping a bright line across a horn and out into the night
    for i = #pings, 1, -1 do
      local P = pings[i]
      local u = (K.T - P.t0) / 0.45
      if u >= 1 then table.remove(pings, i)
      elseif u >= 0 then
        local hx = P.side == 0 and 17 or 111
        local l = (3 + 8 * P.v) * (1 - u)
        line(l, hx - 6, 6, hx + 6, 6)
        local d = P.side == 0 and 1 or -1
        line(l * 0.5, hx + d * (8 + u * 14), 6, hx + d * (12 + u * 20), 6)
      end
    end
    -- the siren: waves rise out of the horns
    if siren > 0.05 then
      for side = 0, 1 do
        local hx = side == 0 and 17 or 111
        for k = 0, 1 do
          local ph = ((T * 1.6 + k * 0.5) % 1)
          K.ring(siren * 6 * (1 - ph), hx, 6, 4 + ph * 14, 8, math.pi + 0.35, K.TAU - 0.35)
        end
      end
    end

    -- the fog: a bank on the horizon and drifting banks through the yard,
    -- lit warmer where the kick's glow is
    K.gradient(GY - 3, GY + 6, function(y) return (0.35 + kl * 0.5 + e * 0.2) * (1 - math.abs(y - GY - 1) / 6) end,
      nil, 37, 91)
    -- (the phrase's last bar thickens it)
    local fd = 0.17 + 0.12 * e + 0.2 * kl + 0.12 * clamp((pp - 0.93) * 14, 0, 1)
    K.haze(28, GY + 4, 100, 54, fd, 1, T * 6)
    if g > 0.25 then K.haze(40, GY + 6, 88, 50, fd * g, 2, T * 6 + 30) end
    K.grain(function(u, v) return 30 + u * 68, GY - 4 + v * 22 end, 3 + hi * 14 + e * 6 + ghost * 20, 3 + hi * 4)
    -- open hats throw sparks up out of the fog
    for i = #sparks, 1, -1 do
      local P = sparks[i]
      local u = (K.T - P.t0) / 0.7
      if u >= 1 then table.remove(sparks, i)
      elseif u >= 0 then
        local x, y = P.x + P.dx * u, P.y - u * 9
        put(P.lv * (1 - u), x, y, 1, 1)
        if u < 0.4 then put(P.lv * 0.4 * (1 - u), x, y + 1, 1, 2) end
      end
    end
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
    -- the highs glitter between the kicks (the hats' place)
    local hiq = hi * (1 - K.env.kick) ^ 3
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
    -- the lows swell the tape's body, the highs make its oxide glitter
    local tb = 1 + e * 0.25 + lo * 0.2
    put(tb, XL, TCY + TR - 2, RUN, 5)
    put(tb, XL, TCY - TR - 2, RUN, 5)
    for _, cx in ipairs({XL, XR}) do
      local a0 = cx == XR and -math.pi / 2 or math.pi / 2
      for dr = -2, 2 do K.ring(tb, cx, TCY, TR + dr, 12, a0, a0 + math.pi) end
    end
    for k = 0, 18 do
      local s = (k * P / 19 + tp) % P
      tmark(1 + e + hiq * 3.5 * (0.5 + 0.5 * math.sin(T * 13 + k * 2.1)), s, 1)
    end
    -- the guide rollers: spokes turning with the tape
    for _, cx in ipairs({XL, XR}) do
      local rot = tp / (TR - 4)
      K.ring(2 + caps * 3 + lo * 1.5, cx, TCY, 6, 12)
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
      local l = (on and 1.2 or 0.8) + mid * 1.1
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
    K.dashes(1, 43, 3, 4, 0, 3, 125)
    line(1.5, 3, 43, 3, 62)
    line(1.5, 124, 43, 124, 62)
    for k = 1, 2 do
      local by = 48 + (k - 1) * 9
      local sk = sps[k]
      -- (the transducers at the tank's ends throb with the lows)
      put(math.min(8, 1.5 + sk * 2 + lo * 3), 5, by - 3, 3, 7)
      put(math.min(8, 1.5 + sk * 2 + lo * 3), 119, by - 3, 3, 7)
      local amp = math.min(2.4, sk * (0.6 + c * 0.4)) + 0.15 + mid * 0.7
      local lv = math.min(4, 1 + sk * 1.2 + mid * 0.7)
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
    -- the phrase lamps between the deck and the tank, and the splice lamp
    local pf = pp * 16
    for k = 0, 15 do
      local on = clamp(pf - k, 0, 1)
      put(1 + on * (1.5 + e) + (k == math.floor(pf) and K.bar_pulse * 3 or 0), 34 + k * 4, 40, 2, 1)
    end
    put(1 + splice * 9, 28, 40, 3, 1)
    K.grain(function(u, w) return 6 + u * 116, 44 + w * 17 end, 2 + hi * 10 + (spr[1] + spr[2]) * 3, 2 + hi * 4)
    -- the highs: the chassis screws and the tape's edge catch the light
    for k = 0, 9 do
      local x = XL + 4 + k * 8
      local tw = 0.5 + 0.5 * math.sin(T * (7 + k) + k * 1.9)
      put(hiq * 4 * tw, x, TCY - TR - 3, 2, 1)
      put(hiq * 4 * (1 - tw), x + 3, TCY + TR + 3, 2, 1)
    end
    -- the oxide's sheen along both tape edges, sliding with the tape
    -- glints riding across the bottom run of the tape
    for k = 0, 11 do
      local x = XL + (k * 7 + tp * 1.0) % RUN
      put(hiq * 4 * (0.5 + 0.5 * math.sin(T * 8 + k * 2.3)), x, TCY + TR - 2, 1, 5)
    end
    -- and the air in the spring tank shimmers
    K.haze(8, 45, 119, 61, hiq * 0.35, 1, -T * 9)
    -- the chassis' side rails glow with the lows, the level and the hits
    line(lo * 2.5 + A[K.AMP] * 1.2, 5, 8, 5, 38)
    line(lo * 2.5 + A[K.AMP] * 1.2, 122, 8, 122, 38)
  end

  ---------------------------------------------------------------- view 3
  -- the dubplate: the platter's centre, its radius and the slant (y squash)
  local PCX, PCY, PSQ = 54, 33, 0.56
  local NA = -0.35                    -- the needle's angle on the screen
  local GR0, GRN, GRD = 13, 8, 3.8    -- grooves: first radius, count, pitch
  local PIV_X, PIV_Y = 116, 7         -- the tonearm's pivot

  local function pxy(a, r)
    return PCX + math.cos(a) * r, PCY + math.sin(a) * r * PSQ
  end

  -- an ellipse filled a row at a time
  local function oval(l, cx, cy, rx, ry)
    if not (ry > 0.5) then return end
    for dy = -math.floor(ry), math.floor(ry) do
      local hw = rx * math.sqrt(math.max(0, 1 - (dy / ry) ^ 2))
      if hw >= 0.5 then put(l, cx - hw, cy + dy, hw * 2, 1) end
    end
  end

  -- the echoes of view 3: each comes back under the needle, fainter
  local function pechoes()
    for i = #pemits, 1, -1 do
      local em = pemits[i]
      local n = 0
      while K.NOW >= em.next and n < 4 do
        em.lv = em.lv * K.echo_fb
        em.n = em.n + 1
        if em.lv >= 1.3 then cut(em.lv, em.len, em.kind) end
        em.next = em.next + K.echo_t
        n = n + 1
      end
      if em.lv < 1.3 or em.n >= 8 then table.remove(pemits, i) end
    end
  end

  local function draw3(S)
    local T, DT, DTS, e, c = K.T, K.DT, K.DTS, K.energy, K.chaos
    local lo, hi, kl, mid, amp = A[K.LO], A[K.HI], K.kickless, A[K.MID], A[K.AMP]
    pechoes()
    -- the motor: a turn a bar, dragging kickless; a spinback eases home
    local per = math.max(0.6, K.beat_sec * 4)
    local sp_to = (K.playing and 1 or 0.45) * (1 - kl * 0.3)
    spin = K.follow(spin, sp_to, spin < 0 and 0.35 or 0.6, DT)
    rot = (rot + DTS * K.TAU / per * spin) % (K.TAU * 64)
    -- the needle winds in over the phrase
    rn = K.follow(rn, 41 - pp * 25, 0.6, DT)
    lthump = lthump * math.exp(-DT / 0.15)
    arm = arm * math.exp(-DT / 0.12)
    nsp = nsp * math.exp(-DT / 0.1)
    slamp = slamp * math.exp(-DT / 0.6)
    local warp = c * c * 2.2                  -- chaos: a warped plate
    local wob = 0.05 * c * math.sin(T * 3.1)

    -- the plinth: a dim frame, the pitch fader, the start button, the lamps
    line(1.3, 1, 2, 1, 61)
    line(1.3, 126, 2, 126, 61)
    for _, p in ipairs({{3, 1}, {120, 1}, {3, 62}, {120, 62}}) do put(1.5, p[1], p[2], 5, 1) end
    line(1.5, 118, 28, 118, 58)
    for k = 0, 6 do put(1, 115, 29 + k * 5, 2, 1) end
    local fy = 43 + math.sin(T * 0.11) * 1.5 - (K.bar_pulse * 0.5)
    put(3 + e * 2 + mid * 2, 116, fy, 5, 2)
    put(2 + K.env.kick * 6 + lo * 2, 6, 57, 4, 3)                -- start / stop
    put(1.5 + (K.playing and 3 or 0), 13, 58, 3, 1)               -- 33
    put(1.5 + slamp * 9, 18, 58, 3, 1)                             -- the siren lamp
    -- the strobe light at the platter's foot, and its dots round the rim;
    -- locked they stand still, chaos sets them drifting, rides sparkle them
    put(2 + amp * 4, 8, 47, 2, 2)
    local drift = (K.playing and 0 or T * 0.4) + c * T * 0.9 + (1 - spin) * T * 0.3
    for k = 0, 35 do
      local a = k / 36 * K.TAU + drift
      local x, y = pxy(a, 47.5)
      local face = 0.5 + 0.5 * math.cos(a - 2.4)            -- nearer the lamp
      put(0.6 + face * (0.6 + amp * 2.5 + K.env.ride * 4) + (k % 4 == 0 and 0.5 or 0), x, y, 1, 1)
    end
    -- the platter's rim (the lows swell it) and the record's edge
    K.ring(1 + lo * 0.4 + lthump * 1.2, PCX, PCY, 45.5 + lo * 0.8, 28, 0, K.TAU, PSQ)
    K.ring(0.8 + e * 0.4, PCX, PCY, 43, 26, 0, K.TAU, PSQ)

    -- the grooves, a sheen across them from the light (two opposite
    -- wedges that stay put while the record turns), the kick's waves
    -- running out through them
    local ash = 2.3 + math.sin(T * 0.07) * 0.2
    -- the light's two wedges on the black vinyl, filled a row at a time
    -- (wider with energy, brighter with the highs and the mids)
    local ww = 0.22 + e * 0.18 + kl * 0.1
    local wl = 0.9 + hi * 1.6 + mid * 0.5 + e * 0.6
    for layer = 0, 1 do
    local wd = layer == 0 and ww * 1.7 or ww
    local wlv = layer == 0 and wl * 0.55 or wl
    for side = 0, 1 do
      local a1, a2 = ash + side * math.pi - wd, ash + side * math.pi + wd
      local c1, c2 = math.cos(a1) / math.sin(a1), math.cos(a2) / math.sin(a2)
      local sg = side == 0 and 1 or -1
      for dy = 1, 24 do
        local y = PCY + sg * dy
        local v = sg * dy / PSQ
        local R = 42.5
        if math.abs(v) < R then
          local ua, ub = v * c1, v * c2
          if ua > ub then ua, ub = ub, ua end
          local lim = math.sqrt(R * R - v * v)
          local inner = math.abs(v) < 11 and math.sqrt(121 - v * v) or 0
          if ub > 0 then ua = math.max(ua, inner) else ub = math.min(ub, -inner) end
          ua, ub = math.max(ua, -lim), math.min(ub, lim)
          if ub - ua >= 1 then put(wlv, PCX + ua, y, ub - ua, 1) end
        end
      end
    end
    end
    local shl = 1.4 + mid * 1.3 + e * 0.6 + kl * 1 + hi * 0.5
    local segs = 18
    for gi = 0, GRN - 1 do
      local r0 = GR0 + gi * GRD + lo * 0.5 * math.sin(T * 2 + gi)
      local kw = 0
      for _, W in ipairs(kwave) do
        local kr = GR0 + (T - W.t0) * 130
        kw = kw + W.v * 1.7 * math.exp(-((r0 - kr) / 3) ^ 2) * math.max(0, 1 - (T - W.t0) * 3)
      end
      -- (black vinyl: a groove shows only where the light or a wave catches it)
      local base = 0.12 + e * 0.1 + kw + lo * 0.12
      local px, py
      for k = 0, segs do
        local a = k / segs * K.TAU
        local r = r0 + warp * math.sin(2 * (a - rot)) * (r0 / 40) + wob * r0
        local x, y = pxy(a, r)
        if px then
          local am = a - K.TAU / segs * 0.5
          local sh = math.max(0, math.cos(2 * (am - ash))) ^ 8
          local l = base + sh * shl
          if l >= 0.5 then line(l, px, py, x, y) end
        end
        px, py = x, y
      end
    end
    for i = #kwave, 1, -1 do if T - kwave[i].t0 > 0.4 then table.remove(kwave, i) end end

    -- the marks cut in the vinyl, turning with it, fading over a few turns
    for i = #pmarks, 1, -1 do
      local m = pmarks[i]
      local age = T - m.t0
      local lv = m.lv * math.exp(-age / (per * (1 + e * 0.5 + kl)))
      if lv < 0.8 then table.remove(pmarks, i)
      else
        local a0 = m.a + rot
        local r = m.r + warp * math.sin(2 * (a0 - rot)) * (m.r / 40) + wob * m.r
        local l = math.min(12, lv * (0.6 + e * 0.2) + mid * 0.8)
        if m.kind == 2 then
          for d = 0, 1 do
            local aa = a0 + d * 0.22
            local x0, y0 = pxy(aa, r)
            local x1, y1 = pxy(aa + m.len * 0.5, r)
            line(l, x0, y0, x1, y1)
          end
        elseif m.kind == 3 or m.kind == 5 then
          local x0, y0 = pxy(a0, r - 1.2)
          local x1, y1 = pxy(a0, r + 1.2)
          line(l, x0, y0, x1, y1)
        else
          local n = math.max(1, math.floor(m.len / 0.14))
          local px, py = pxy(a0, r)
          for k = 1, n do
            local x, y = pxy(a0 + m.len * k / n, r)
            line(l * (1 - 0.25 * k / n), px, py, x, y)
            px, py = x, y
          end
        end
        -- chaos doubles the cut a groove over
        if c > 0.45 and i % 2 == 0 then
          local x0, y0 = pxy(a0 + m.j * 0.2, r + GRD)
          local x1, y1 = pxy(a0 + m.j * 0.2 + math.max(0.06, m.len), r + GRD)
          line(l * 0.45 * c, x0, y0, x1, y1)
        end
      end
    end

    -- the label: printed halves turning, thumping on the kick, a bell's ping
    local lr = 9.5 + lthump * 0.8
    oval(1.5 + mid * 1.5 + lthump * 1.5 + e * 0.5, PCX, PCY, lr, lr * PSQ)
    local la = rot
    local ax, ay = math.cos(la) * (lr - 1.5), math.sin(la) * (lr - 1.5) * PSQ
    line(3.5 + mid * 3 + lthump * 3, PCX - ax, PCY - ay, PCX + ax, PCY + ay)
    local bx, by = pxy(la + 1.9, lr * 0.55)
    put(3 + mid * 3 + e * 2, bx - 1, by, 3, 1)
    K.ring(2 + lthump * 4, PCX, PCY, lr + 0.5, 12, 0, K.TAU, PSQ)
    put(9 + lthump * 3, PCX - 1, PCY - 1, 2, 2)                  -- the spindle

    -- the tonearm: pivot, arm, headshell, the needle's spark
    local nx, ny = pxy(NA, rn)
    ny = ny - arm * 1.5
    K.ring(2.5 + e, PIV_X, PIV_Y, 4.5, 10)
    put(3 + e * 2, PIV_X - 1, PIV_Y - 1, 3, 3)
    line(2.5 + e, PIV_X + 3, PIV_Y - 3, 124, 1)                    -- the counterweight's rod
    put(2.5 + lo * 2, 121, 1, 4, 3)
    local ex, ey = nx + 9, ny - 9                                  -- the elbow
    line(4 + e * 1.5 + arm * 2, PIV_X, PIV_Y, ex, ey)
    line(4 + e * 1.5 + arm * 2, ex, ey, nx + 2, ny - 2)
    put(4 + arm * 3, nx, ny - 3, 4, 2)                              -- the headshell
    put(math.min(13, 3 + nsp * 10 + hi * 2), nx, ny, 1, 1)
    if nsp > 0.2 then put(nsp * 5, nx - 1, ny + 1, 3, 1) end

    -- open hats lift dust off the vinyl, the highs glint it all over
    for i = #motes, 1, -1 do
      local P = motes[i]
      local u = (T - P.t0) / 0.9
      if u >= 1 then table.remove(motes, i)
      elseif u >= 0 then
        local x, y = pxy(P.a + rot * 0.15, P.r)
        put(P.lv * (1 - u), x, y - u * 7, 1, 1)
      end
    end
    -- (fixed specks of dust turning with the record, lit by the highs)
    for k = 0, 23 do
      local x, y = pxy(K.hash(k, 61) * K.TAU + rot, 12 + K.hash(k, 62) * 30)
      local tw = 0.5 + 0.5 * math.sin(T * (6 + K.hash(k, 63) * 5) + k * 2.3)
      put(hi * (1 + 5 * tw), x, y, 1, 1)
    end
    K.grain(function(u, w)
      local a, r = u * K.TAU, 14 + w * 28
      return pxy(a, r)
    end, 2 + hi * 14 + e * 3 + K.env.tick * 10, 2 + hi * 5)
    -- kickless: a haze hangs over the record
    if kl > 0.05 then K.haze(14, 12, 96, 56, kl * 0.28, 1, T * 3) end
  end

  function M.draw(S)
    glow = K.follow(glow, 0, 0.35, K.DT)
    gs = K.follow(gs, glow, 0.08, K.DT)
    cs = K.follow(cs, cone, 0.05, K.DT)
    cone = cone * math.exp(-K.DT / 0.12)
    flash = flash * math.exp(-K.DT / 0.2)
    siren = siren * math.exp(-K.DT / 0.6)
    ghost = ghost * math.exp(-K.DT / 0.3)
    splice = splice * math.exp(-K.DT / 0.25)
    local pl = math.floor(K.num(S and S.phrase_len, 16))
    if not (pl >= 1 and pl <= 256) then pl = 16 end
    local pto = clamp((K.num(S and S.phrase_pos, 0) % pl + K.bar_ph) / pl, 0, 1)
    pp = K.follow(pp, pto, 0.5, K.DT)
    if K.view == 2 then
      echoes(K.chaos)
      draw2(S)
    elseif K.view == 3 then
      draw3(S)
    else
      draw1(S)
    end
  end

  M.init()
  return M
end
