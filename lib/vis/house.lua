-- house. view 1: a club at full tilt: a lighting rig sweeping beams through
-- the haze over three rows of crowd that bob on the kick, a mirror ball, and
-- blinders on the truss that fire on the claps.
-- view 2: the drum machine's front panel up close: a 16-step pattern grid
-- per voice with the running light, the step keys and the voice pads.
-- view 3: the booth from the DJ's side: two decks, the mixer between them
-- with its meters, and the floor beyond the booth's edge with its hands up.
--
-- view 1: the kick lifts the beams and drops the crowd's heads; claps fire
-- the blinders and put hands up; open hats and rides flare the beams; the
-- cowbell and hats throw glints off the mirror ball; a fill swings every
-- beam to the middle; a ratchet chases along the fixtures. the truss
-- brightens on the bar, and over the phrase more beams come on and more
-- hands go up. energy brings up more beams, more crowd and thicker haze,
-- chaos splits and crosses the beams and shakes the crowd, and kickless
-- stretches tilt the beams up and slow them while the crowd sways.
-- view 2: every hit lights its voice pad and its cell in the grid at the
-- current step; the cells hold the last bars, so the grid shows the groove.
-- the running light walks the step keys, a ratchet splits the current cell,
-- chaos throws ghost lights and shifts the rows, energy lights the panel;
-- eight lamps by the tempo lamp fill over the phrase.
-- view 3: the left deck plays; over the phrase the right deck is dropped in
-- and the crossfader walks across. the kick thumps the playing labels and
-- the level and low meters, the snare and clap put hands up beyond the
-- booth and kick the mid meter, closed hats spark the needles and the high
-- meter, open hats flare the gooseneck lamp, percs light the cue pads, a
-- ratchet scratches the live deck back and forth, cuts the crossfader and
-- runs the pads, a fill sweeps the filter knob and throws every hand up.
-- energy brings more of the crowd and lights the decks, chaos pushes the
-- platters about and wobbles the meters and the fader, kickless the low EQ
-- is turned down and the crowd sways.
--
-- the ears: view 1, the lows lift the beams and the LED strip, the mids
-- brighten the beams and get the crowd's hands up, the highs throw the
-- mirror ball's spots over the wall and thicken the haze; view 2, the lows
-- backlight the step keys and heave the output meter, the mids light the
-- grid's column dividers, the highs flicker the LEDs, the knob caps and the
-- key strip between the kicks; view 3, the four meters are the level, the
-- lows, the mids and the highs, the lows also swell the platters' rims, the
-- mids and highs the sheen on the vinyl, the level the wash on the far wall.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp

  ---------------------------------------------------------------- view 1
  local NF = 6
  local FX = {12, 33, 54, 74, 95, 116}  -- fixtures on the truss
  local FY = 9
  local MAXG = 14

  -- the crowd: three rows, back to front (x, size, phase)
  local ROWS = {
    {y = 45, r = 2.2, n = 16, lv = 1, bob = 0.8},
    {y = 52, r = 3.2, n = 12, lv = 0, bob = 1.6},
    {y = 62, r = 5.4, n = 8, lv = 0, bob = 2.6},
  }
  local PPL = {}
  for ri, R in ipairs(ROWS) do
    PPL[ri] = {}
    for i = 1, R.n do
      local x = (i - 0.5) * 128 / R.n + (K.hash(i + ri * 31, 1) - 0.5) * 128 / R.n * 0.7
      PPL[ri][i] = {x = x, r = R.r * (0.85 + 0.3 * K.hash(i + ri * 31, 2)),
        ph = K.hash(i + ri * 31, 3) * 6.28, on = K.hash(i + ri * 31, 4), dy = (K.hash(i + ri * 31, 5) - 0.5) * 2}
    end
  end

  local hands, glints
  local blind, flare, conv, chase, chase_t
  local bob                             -- the crowd's drop on the kick, eased
  local bls, sph = 0, 0                         -- the blinders, eased (for the big areas)
  local kup                             -- beams lift on the kick, eased
  local prof = {}                       -- the crowd's top, per column
  local fp = {}                         -- the front rows' top (what hides the back row)

  -- view 2: the pattern memory, voices x 16 steps
  local NV = 5                          -- kick, clap/snare, hat, open/ride, perc
  local pat, pads, keyf, rat, rat_s
  local pp = 0                          -- the phrase, eased (0 .. 1)

  -- view 3: the booth
  local drot = {0, 0}                   -- the decks' angles
  local dspin = {1, 0}                  -- and speeds
  local scratch, lamp, cuep, meter, peakh, bhands, filt

  function M.init()
    hands = {}
    for ri = 1, 3 do hands[ri] = {} for i = 1, ROWS[ri].n do hands[ri][i] = 0 end end
    glints = {}
    blind, flare, conv, chase, chase_t = 0, 0, 0, 0, 0
    bob, kup, bls, sph = 0, 0, 0, 0
    pat, pads = {}, {}
    for v = 1, NV do pat[v] = {} pads[v] = 0 for s = 0, 15 do pat[v][s] = 0 end end
    keyf = {}
    for s = 0, 15 do keyf[s] = 0 end
    rat, rat_s = 0, 0
    pp = 0
    drot, dspin = {0, 0}, {1, 0}
    scratch, lamp, filt = 0, 0, 0
    cuep = {0, 0, 0, 0, 0, 0, 0, 0}
    meter, peakh = {0, 0, 0, 0}, {0, 0, 0, 0}
    bhands = {}
    for i = 1, 14 do bhands[i] = 0 end
  end
  local function bhand(n, lv)
    for _ = 1, n do
      local i = 1 + math.floor(K.rnd() * 14)
      bhands[i] = math.max(bhands[i], lv)
    end
  end
  M.clear = M.init

  local function cur_step() return math.floor(K.num(K.step, 0)) % 16 end

  local function mark(v, vel)
    local s = cur_step()
    pat[v][s] = math.max(pat[v][s], 0.35 + 0.65 * vel)
    pads[v] = math.max(pads[v], 0.4 + 0.6 * vel)
    keyf[s] = math.max(keyf[s], 0.5 + 0.5 * vel)
  end

  local function glint(n, lv)
    for _ = 1, n do
      if #glints >= MAXG then table.remove(glints, 1) end
      local a = K.rnd() * K.TAU
      local d = 8 + K.rnd() * 50
      glints[#glints + 1] = {x = 64 + math.cos(a) * d * 1.2, y = 15 + math.abs(math.sin(a)) * d * 0.5,
        t0 = K.T, lv = lv}
    end
  end

  function M.kick(v)
    v = K.num(v, 1)
    mark(1, v)
    meter[2] = math.max(meter[2], 0.6 + 0.4 * v)
    meter[1] = math.max(meter[1], 0.5 + 0.4 * v)
  end

  function M.clap(v)
    v = K.num(v, 1)
    mark(2, v)
    blind = math.max(blind, 0.5 + 0.5 * v)
    local n = 2 + math.floor((K.energy + v) * 2.5)
    for _ = 1, n do
      local ri = 2 + math.floor(K.rnd() * 2)
      local i = 1 + math.floor(K.rnd() * ROWS[ri].n)
      hands[ri][i] = 1
    end
    bhand(n, 1)
    meter[3] = math.max(meter[3], 0.5 + 0.4 * v)
  end
  function M.snare(v)
    v = K.num(v, 1)
    mark(2, v * 0.8)
    blind = math.max(blind, 0.3 * v)
    if K.rnd() < 0.4 then
      local i = 1 + math.floor(K.rnd() * ROWS[2].n)
      hands[2][i] = math.max(hands[2][i], 0.7)
    end
    meter[3] = math.max(meter[3], 0.4 + 0.5 * v)
    if K.rnd() < 0.5 then bhand(1, 0.7) end
  end
  function M.rim(v) mark(2, K.num(v, 1) * 0.5) end

  function M.hat(v, open)
    v = K.num(v, 1)
    if open then
      mark(4, v)
      flare = math.max(flare, 0.4 + 0.6 * v)
      glint(2, 4 + 5 * v)
      lamp = math.max(lamp, 0.5 + 0.5 * v)
    else
      mark(3, v)
      if K.rnd() < 0.5 then glint(1, 2 + 3 * v) end
    end
    meter[4] = math.max(meter[4], (open and 0.6 or 0.35) + 0.3 * v)
  end
  function M.ride(v) v = K.num(v, 1); mark(4, v * 0.8); flare = math.max(flare, 0.3 * v); glint(1, 3 + 3 * v) end
  function M.shaker(v) mark(3, K.num(v, 1) * 0.6) end

  function M.perc(kind, v)
    v = K.num(v, 1)
    mark(5, v)
    if kind == 3 then glint(4, 5 + 6 * v)      -- the cowbell: the ball lights up
    else glint(1, 3 + 4 * v) end
    local k = 1 + (math.floor(K.num(kind, 1)) - 1) % 8
    cuep[k] = math.max(cuep[k], 0.5 + 0.5 * v)
  end
  function M.tom(v) mark(5, K.num(v, 1)) end
  function M.tick() glint(1, 3) end
  function M.brk(s) s = K.num(s, 1); if s % 2 == 1 then mark(5, 0.35) end; if s % 4 == 1 then glint(1, 4) end end

  function M.fill() conv = 1; filt = 1; bhand(8, 1) end
  function M.bar() end
  function M.ratchet(n)
    n = clamp(math.floor(K.num(n, 2)), 1, 12)
    chase, chase_t = n, K.T
    rat, rat_s = n, cur_step()
    blind = math.max(blind, 0.45)
    glint(math.min(n, 5), 6)
    scratch = 1
    for k = 1, math.min(n, 8) do cuep[k] = math.max(cuep[k], 1 - k * 0.07) end
  end

  -- the crowd's top this frame (and where heads are), 1 px columns
  local heads = {}
  local function crowd(e, c, kl)
    for x = 0, 127 do prof[x], fp[x] = 64, 64 end
    local nh = 0
    for ri = 3, 1, -1 do
      local R = ROWS[ri]
      for i, P in ipairs(PPL[ri]) do
        local h = hands[ri][i]
        hands[ri][i] = h * math.exp(-K.DT / 0.4)
        -- the body of the mix gets the hands up, each dancer on their own swing
        -- (and as the phrase runs on, more hands go up)
        local mid = math.min(1, A[K.MID] + pp * pp * 0.35)
        if mid > 0.1 and K.hash(i + ri * 31, 5) < 0.25 + mid * 0.6 then
          h = math.max(h, mid * (0.55 + 0.45 * math.sin(K.T * 2.1 + P.ph * 3)))
        end
        local show = P.on < 0.6 + e * 0.4 or ri == 3
        if show then
          local sway = math.sin(K.T * (0.5 + kl * 0.7) + P.ph) * (0.8 + kl * 1.6)
          if c > 0.4 then sway = sway + math.sin(K.T * 5.3 + P.ph * 3) * c * 1.5 end
          local x = P.x + sway
          local r = P.r
          local hy = R.y + P.dy + bob * R.bob * (0.7 + 0.3 * math.sin(P.ph)) - r
          for xx = math.floor(x - r * 2.6), math.floor(x + r * 2.6) do
            if xx >= 0 and xx <= 127 then
              local dx = math.abs(xx + 0.5 - x)
              local top
              local sh = hy + r * 1.5 + math.max(0, dx - r * 1.3) * 0.45
              if dx > r * 0.6 then top = sh else top = 64 end
              if dx <= r then top = math.min(top, hy - math.sqrt(r * r - dx * dx)) end
              if top < prof[xx] then prof[xx] = top end
              if ri > 1 and top < fp[xx] then fp[xx] = top end
            end
          end
          if h > 0.15 and ri > 1 then
            local up = h ^ 0.5 * (r * 2.6 + e * 3)
            for _, side in ipairs({-1, 1}) do
              local ax = math.floor(x + side * r * 1.5)
              local ty = hy + r * 0.3 - up
              for xx = ax, ax + (ri == 3 and 1 or 0) do
                if xx >= 0 and xx <= 127 then
                  prof[xx] = math.min(prof[xx], ty)
                  fp[xx] = math.min(fp[xx], ty)
                end
              end
            end
          end
          if nh < 60 then heads[nh + 1], heads[nh + 2], heads[nh + 3] = ri, x, hy; nh = nh + 3 end
        end
      end
    end
    return nh
  end

  local function crowd_top(x)
    x = math.floor(clamp(x, 0, 127))
    return prof[x]
  end

  -- a beam from a fixture to the crowd: a fan of lines, its ends clipped
  local function beam(l, fx, ex, spread)
    local ey = math.max(FY + 6, crowd_top(ex) - 1)
    line(l, fx, FY + 2, ex, ey)
    if spread > 0.5 and l > 1.4 then
      for k = 1, 2 do
        local d = spread * k / 2
        local ll = l * (k == 1 and 0.6 or 0.35)
        for sd = -1, 1, 2 do
          local ex2 = ex + sd * d
          line(ll, fx + sd * 0.5, FY + 2, ex2, math.max(FY + 6, crowd_top(ex2) - 1))
        end
      end
    end
    return ey
  end

  local function draw1(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl, mid = A[K.LO], A[K.HI], K.kickless, A[K.MID]
    local playing = K.playing and 1 or 0
    local nh = crowd(e, c, kl)

    -- the back wall: an LED strip and the booth, dim behind the haze
    local bp = K.bar_ph
    for k = 0, 15 do
      local on = (math.floor(K.stepf) % 16 == k) and playing or 0
      put(1 + on * (2 + e * 2) + lo * 0.6, 8 + k * 7, 33, 5, 1)
    end
    line(1.5, 40, 38, 88, 38)
    put(1, 42, 39, 44, 2)
    put(2 + lo * 4 + K.env.kick * 3, 50, 37, 3, 1)
    put(2 + hi * 4 + K.env.hat * 3, 75, 37, 3, 1)
    -- the haze
    K.haze(0, 12, 128, 42, 0.12 + 0.22 * e + 0.15 * kl + 0.3 * hi, 1, T * 4)
    -- the highs: the mirror ball's spots crawling over the back wall
    if hi > 0.05 then
      for k = 0, 21 do
        local gx = (K.hash(k, 41) * 140 + T * (4 + K.hash(k, 42) * 3)) % 132 - 2
        local gy = 13 + K.hash(k, 43) * 22
        local tw = 0.5 + 0.5 * math.sin(T * (5 + K.hash(k, 44) * 6) + k)
        put(hi * (2 + tw * 4), gx, gy, 2, 1)
      end
    end

    -- the rig: the truss, the fixtures and the blinders
    line(2 + K.bar_pulse * 2, 0, 3, 127, 3)
    line(2 + K.bar_pulse * 2, 0, 7, 127, 7)
    for x = 0, 120, 8 do line(1.2, x, 3, x + 4, 7); line(1.2, x + 4, 7, x + 8, 3) end
    for k = 0, 3 do
      local bx = 20 + k * 28
      put(math.min(12, 2 + blind * 10), bx, 4, 5, 2)
    end

    -- beams: they sweep in mirrored pairs on the bar, lift on the kick,
    -- flare on open hats, swing to the middle on a fill
    local nb = math.floor(2 + e * 4 + pp * 1.5 + 0.5)
    local sw = (0.6 + 0.4 * playing) * (1 - kl * 0.5)
    -- the sweep: slow at rest, half a swing a bar when playing
    sph = (sph + K.DTS * (0.35 * sw + playing * (1 - kl * 0.6) * math.pi / (4 * K.beat_sec))) % 1000
    for i = 1, NF do
      local fx = FX[i]
      local mir = (i <= 3) and 1 or -1
      local on = (i == 3 or i == 4) or ((i - 1) % 5 < nb - 1) or i <= nb
      local ph = sph + i * 0.9
      local tgt = fx + mir * math.sin(ph) * (30 + e * 14)
      tgt = tgt + (64 - tgt) * conv
      local ex = tgt
      local lift = (kl * 0.6 + (1 - kup) * 0.15) -- kickless: beams tilt up
      local lv = (1 + mid * 2.6 + e * 0.8 + kup * 2.6 + flare * 2 + bls * 2) * (on and 1 or 0.45) * (1 - kl * 0.35)
      if chase > 0 then
        local cu = (K.T - chase_t) / 0.4
        if cu < 1 and math.floor(cu * chase) % NF == i - 1 then lv = lv + 6 end
      end
      lv = math.min(10, lv)
      if lift > 0.3 then
        -- tilted up: the beam ends in the haze
        local ey = FY + 20 - lift * 10
        line(lv, fx, FY + 2, ex, ey)
      else
        local ey = beam(lv, fx, ex, 4 + e * 4 + flare * 3)
        if lv > 3 then put(lv * 0.7, ex - 1, ey - 1, 3, 1) end   -- the spot on the crowd
      end
      if c > 0.3 then
        local ex2 = fx - mir * math.sin(ph * 1.7 + 1) * (24 + c * 20)
        beam(lv * 0.6 * c, fx, ex2, 0)
      end
      -- the fixture
      put(2.5 + kup * 2, fx - 2, FY - 1, 5, 2)
      put(math.min(12, 3 + lv * 0.9), fx - 1, FY + 1, 3, 1)
    end

    -- the mirror ball and its glints
    local bx, by = 64, 15
    line(1.5, bx, 7, bx, by - 3)
    K.disc(2 + hi * 2, bx, by, 3)
    put(4 + hi * 6 + K.env.ohat * 4, bx - 1 + math.floor(T * 3) % 3, by - 1, 1, 1)
    for i = #glints, 1, -1 do
      local G = glints[i]
      local u = (K.T - G.t0) / 0.8
      if u >= 1 then table.remove(glints, i)
      else
        local gx = G.x + u * 6
        if G.y < crowd_top(gx) - 1 then put(G.lv * (1 - u), gx, G.y, 2, 1) end
      end
    end

    -- the crowd: the back row hazy, the front rows black with their edges
    -- caught by the light; heads drop on the kick
    local rl = 4 + kup * 3 + bls * 3 + lo * 0.5
    -- (runs of equal columns go out as one rect)
    local r1x, r1a, r1b, r2x, r2a, r2b, r3x, r3a, r3b
    for x = 0, 128 do
      local fa, fb, ta, oa, ob = -1, -1, -1, -1, -1
      if x < 128 then
        local top = math.floor(prof[x] + 0.5)
        local ft = math.floor(fp[x] + 0.5)
        if top < ft then
          local bot = math.min(ft, top + 7)
          if bot > top + 1 then fa, fb = top + 1, bot end
          ta = top
        end
        if ft < 64 then
          -- the outline, joined down to the neighbours so it never breaks
          local nb = math.max(fp[math.max(0, x - 1)], fp[math.min(127, x + 1)])
          oa, ob = ft, ft + math.max(1, math.min(4, math.floor(nb + 0.5) - ft))
        end
      end
      if r1x and (fa ~= r1a or fb ~= r1b) then put(1, r1x, r1a, x - r1x, r1b - r1a); r1x = nil end
      if not r1x and fa >= 0 then r1x, r1a, r1b = x, fa, fb end
      if r2x and ta ~= r2a then put(rl * 0.6, r2x, r2a, x - r2x, 1); r2x = nil end
      if not r2x and ta >= 0 then r2x, r2a = x, ta end
      if r3x and (oa ~= r3a or ob ~= r3b) then put(rl, r3x, r3a, x - r3x, r3b - r3a); r3x = nil end
      if not r3x and oa >= 0 then r3x, r3a, r3b = x, oa, ob end
    end
    K.grain(function(u, v) return u * 128, 12 + v * 26 end, 2 + hi * 10 + e * 4, 2 + hi * 3)
  end

  ---------------------------------------------------------------- view 2
  local GX, GY0, CW, RH = 14, 17, 7, 5    -- the grid: x0, y0, column pitch, row pitch

  local function draw2(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl, mid = A[K.LO], A[K.HI], K.kickless, A[K.MID]
    -- the highs glitter between the kicks (the hats' place)
    local hiq = hi * (1 - K.env.kick) ^ 2
    local playing = K.playing
    local cs = cur_step()
    local sf = K.num(K.stepf, 0)
    local idle = not playing
    if idle then sf = T * 1.5; cs = math.floor(sf) % 16 end

    -- the panel: a frame, a backlight that comes up with the energy
    line(1, 1, 1, 126, 1)
    line(1, 1, 62, 126, 62)
    line(1.5, 1, 1, 1, 62)
    line(1.5, 126, 1, 126, 62)
    K.dashes(1, 14, 2, 4, 0, 3, 125)              -- silkscreened dividers
    K.dashes(1, 43, 2, 4, 0, 3, 125)

    -- the knobs: one per voice, the pointer kicked by its hits; tempo lamp
    local kn = {pads[1], pads[2], pads[3], pads[4], pads[5], hi, lo, e}
    for k = 1, 8 do
      local kx, ky = 10 + (k - 1) * 13, 8
      -- (the knob caps catch the highs)
      K.ring(1.2 + e * 0.5 + hiq * 3 * (0.5 + 0.5 * math.sin(T * 4 + k * 1.3)), kx, ky, 3.5, 10)
      local a = math.pi * 0.75 + (0.3 + 0.6 * kn[k] + 0.08 * math.sin(T * 0.3 + k)) * math.pi * 1.5
      line(2.5 + kn[k] * 5, kx, ky, kx + math.cos(a) * 3.5, ky + math.sin(a) * 3.5)
    end
    local beat_on = playing and (K.beat_ph < 0.15) and 1 or 0
    put(2 + beat_on * 9 + (idle and (1.5 + 1.5 * math.sin(T * 2)) or 0), 114, 6, 4, 2)
    put(1.5 + kl * 8, 114, 10, 4, 1)                 -- the kick-mute lamp
    -- the phrase: eight lamps fill over it
    local pf = pp * 8
    for k = 0, 7 do
      put(1 + clamp(pf - k, 0, 1) * 2.5 + ((k == math.floor(pf)) and K.bar_pulse * 4 or 0), 107 + (k % 4) * 4, 1 + (k // 4) * 2 + 1, 2, 1)
    end

    -- voice pads at the row heads, and the grid
    local dec = math.exp(-DT / math.max(0.5, K.beat_sec * 6))
    for v = 1, NV do
      pads[v] = pads[v] * math.exp(-DT / 0.12)
      local y = GY0 + (v - 1) * RH
      local muted = (v == 1 and kl > 0.5)
      put(muted and 1 or (2 + pads[v] * 9), 4, y, 6, 2)
      local shift = 0
      if c > 0.35 then shift = math.floor(math.sin(T * 1.3 + v * 2.1) * c * 2.5 + 0.5) end
      for s = 0, 15 do
        local val = pat[v][s] * dec
        pat[v][s] = val
        local x = GX + ((s + shift) % 16) * CW
        local l
        if val > 0.05 then
          l = 1.5 + val * 4.5
          if s == cs then l = l + 3 end
          put(math.min(11, l), x, y, 4, 2)
        else
          l = ((s % 4 == 0) and 1.5 or 1) + (s == cs and 2 or 0)
          put(l, x + 1, y, 2, 1)
        end
        if c > 0.6 and val > 0.3 and (s + v) % 3 == 0 then
          put(val * 4 * c, GX + ((s + shift + 8) % 16) * CW + 1, y + 1, 3, 1)
        end
      end
    end
    -- the mids: the grid's backlight glowing up between the columns
    if mid > 0.05 then
      for s = 0, 15 do
        local x = GX + s * CW + 5
        line(mid * ((s % 4 == 3) and 2.6 or 1.6), x, GY0 - 1, x, GY0 + NV * RH - 2)
      end
    end
    -- the playhead: brackets over the current column; a ratchet splits it
    local hx = GX + (sf % 16) * CW
    line(4 + e * 3, hx - 1, GY0 - 2, hx + 5, GY0 - 2)
    line(4 + e * 3, hx - 1, GY0 + NV * RH, hx + 5, GY0 + NV * RH)
    if rat > 0 then
      local age = K.since("ratchet")
      if age < 0.5 then
        local x = GX + rat_s * CW
        for k = 0, math.min(rat, 5) - 1 do
          put(11 * (1 - age * 2), x + k, GY0 - 4, 1, 2)
        end
        put(8 * (1 - age * 2), x, GY0 + NV * RH + 2, 5, 1)
      end
    end

    -- the step keys: 4 groups, an LED over each, the running light
    for s = 0, 15 do
      keyf[s] = keyf[s] * math.exp(-DT / 0.15)
      local x = GX + s * CW
      local grp = (s // 4) % 2
      local any = 0
      for v = 1, NV do any = math.max(any, pat[v][s]) end
      local ledv = any > 0.1 and (1.5 + any * 4) or 1
      local d = math.abs(((sf % 16) - s + 8) % 16 - 8)
      if d < 1 then ledv = ledv + (1 - d) * (playing and 9 or 4) end
      if c > 0.5 and K.hash(s + math.floor(T * 4) * 16, 9) < c * 0.15 then ledv = ledv + 5 end
      -- the highs flicker the LEDs, the lows backlight the keys
      ledv = ledv + hiq * 3 * (0.5 + 0.5 * math.sin(T * 9 + s * 1.7))
      put(math.min(13, ledv), x + 1, 46, 3, 1)
      put(1 + keyf[s] * 6 + e * 0.4 + lo * 1.1, x, 50, 5, 6)
      put(1.5 + grp + keyf[s] * 4 + hiq * 2, x, 49, 5, 1)
    end
    -- a fill: the LEDs ripple out from the playhead
    local fe = K.env.fill
    if fe > 0.1 then
      local r = (1 - fe) * 16
      for side = -1, 1, 2 do
        local s = (math.floor(sf + side * r)) % 16
        put(fe * 9, GX + s * CW + 1, 46, 3, 1)
      end
    end
    K.grain(function(u, w) return 4 + u * 120, 15 + w * 27 end, 1 + hi * 6, 2 + hi * 2)
    -- the output meter along the foot: an LED chain the lows push along
    local ml = math.floor((lo * 0.7 + A[K.AMP] * 0.3) * 30)
    for k = 0, ml - 1 do put(1 + (k > 24 and 2 or 0), 4 + k * 4, 58, 1, 3) end
    put(2 + lo * 4, 4 + ml * 4, 58, 1, 3)
  end

  ---------------------------------------------------------------- view 3
  -- the booth from the DJ's side: two decks, the mixer between them, the
  -- floor beyond the booth's edge
  local DK = {{x = 23, y = 44}, {x = 105, y = 44}}
  local DRX, DRY = 19, 11
  local BY = 27                          -- the booth's front edge

  local function oval(l, cx, cy, rx, ry)
    if not (ry > 0.5) then return end
    for dy = -math.floor(ry), math.floor(ry) do
      local hw = rx * math.sqrt(math.max(0, 1 - (dy / ry) ^ 2))
      if hw >= 0.5 then put(l, cx - hw, cy + dy, hw * 2, 1) end
    end
  end

  local function deck(i, live, e, c, lo, mid, hi)
    local D = DK[i]
    local cx, cy = D.x, D.y
    -- the plinth's corners, the platter's rim, the record, its label
    put(1.5, cx - 22, cy - 15, 3, 1); put(1.5, cx + 20, cy - 15, 3, 1)
    put(1.5, cx - 22, cy + 15, 3, 1); put(1.5, cx + 20, cy + 15, 3, 1)
    K.ring(1 + live * (lo * 0.6 + K.env.kick * 1.2), cx, cy, DRX + 1.5, 20, 0, K.TAU, DRY / DRX)
    K.ring(1, cx, cy, DRX - 4, 16, 0, K.TAU, DRY / DRX)
    -- the sheen on the vinyl, standing still while it turns
    for k = 0, 1 do
      local a = 2.3 + k * math.pi
      local x0, y0 = cx + math.cos(a) * 7, cy + math.sin(a) * 7 * DRY / DRX
      local x1, y1 = cx + math.cos(a) * (DRX - 2), cy + math.sin(a) * (DRX - 2) * DRY / DRX
      line(1.5 + mid * 2 + hi * 2 + e, x0, y0, x1, y1)
    end
    local rot = drot[i]
    oval(2.5 + live * (mid * 2 + K.env.kick * 3 + scratch * 5), cx, cy, 5.5, 3.3)
    -- chaos: the label's print ghosts round as the deck is pushed about
    if c > 0.3 then
      local ga = rot + math.sin(K.T * 5 + i) * c * 1.5
      local gx, gy = math.cos(ga) * 9, math.sin(ga) * 9 * DRY / DRX
      line(1 + c * 3 * live, cx - gx, cy - gy, cx + gx, cy + gy)
    end
    local ax, ay = math.cos(rot) * 5, math.sin(rot) * 5 * DRY / DRX
    line(5 + live * 3, cx - ax, cy - ay, cx + ax, cy + ay)
    put(9, cx, cy, 1, 1)
    -- the tonearm, its needle sparked by the closed hats
    local px, py = cx + (i == 1 and 17 or -17), cy - 12
    local nx, ny = cx + (i == 1 and 9 or -9), cy - 5
    K.ring(2.5, px, py, 2.5, 8)
    line(3.5 + e, px, py, nx + (i == 1 and 2 or -2), ny - 2)
    line(3.5 + e, nx + (i == 1 and 2 or -2), ny - 2, nx, ny)
    if live > 0.3 then put(math.min(13, 3 + K.env.hat * 9 + hi * 3), nx, ny, 1, 1) end
    -- the start lamp and the pitch fader
    put(2 + live * 4, cx + (i == 1 and -20 or 18), cy + 12, 2, 1)
    local fx = cx + (i == 1 and 21 or -22)
    line(1.5, fx, cy - 6, fx, cy + 8)
    put(3 + e * 2, fx - 1, cy + 1 + math.sin(K.T * 0.13 + i) * 2, 3, 2)
  end

  local function draw3(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl, mid, amp = A[K.LO], A[K.HI], K.kickless, A[K.MID], A[K.AMP]
    local playing = K.playing and 1 or 0
    -- the decks: the left one plays; over the phrase the right one is
    -- dropped in and the crossfader walks across
    local xf = K.ease((pp - 0.25) / 0.6)
    local live2 = K.ease((pp - 0.2) * 4)
    scratch = scratch * math.exp(-DT / 0.35)
    for i = 1, 2 do
      local to = i == 1 and (0.4 + 0.6 * playing) or live2 * (0.4 + 0.6 * playing)
      dspin[i] = K.follow(dspin[i], to, 0.3, DT)
      local w = dspin[i] * K.TAU / math.max(0.6, K.beat_sec * 4)
      -- a ratchet scratches the live deck back and forth; chaos too
      local sc = (i == (xf > 0.5 and 2 or 1)) and (scratch * 14 * math.sin(T * 30) + c * c * 6 * math.sin(T * 7.3 + i)) or 0
      drot[i] = (drot[i] + K.DTS * (w + sc)) % (K.TAU * 64)
    end
    filt = filt * math.exp(-DT / 0.9)
    lamp = lamp * math.exp(-DT / 0.3)

    -- the floor beyond: a back wall washed by the lights, heads against
    -- it, hands up on the claps
    local wash = 0.8 + amp * 0.8 + e * 0.4 + K.bar_pulse * 0.8
    for k = 0, 7 do
      local x = (k * 18 + T * (3 + k % 3) + c * 20 * math.sin(T * 1.7 + k)) % 150 - 11
      local w = 10 + 4 * math.sin(T * 0.4 + k)
      put(wash * (0.6 + 0.4 * math.sin(T * 0.9 + k * 1.7)), x, 2 + (k % 3) * 2, w, 1)
    end
    local hb = 0
    for i = 1, 14 do
      local h = bhands[i]
      bhands[i] = h * math.exp(-DT / 0.45)
      if mid > 0.15 and K.hash(i, 33) < mid * 0.7 then
        h = math.max(h, mid * (0.5 + 0.5 * math.sin(T * 2.2 + i)))
      end
      local show = K.hash(i, 34) < 0.55 + e * 0.45
      if show then
        local x = 4 + (i - 0.5) * 120 / 14 + math.sin(T * (0.5 + kl * 0.6) + i) * (1 + kl * 1.5)
        local y = 19 + hb * (0.6 + 0.4 * K.hash(i, 35)) + K.hash(i, 36) * 2
        local r = 2.6 + K.hash(i, 37) * 0.8
        K.disc(1 + lo * 0.5, x, y, r)
        put(1, x - r * 1.6, y + r * 0.6, r * 3.2, math.min(BY - y - r * 0.6, r * 2.2))
        line(1.5 + wash * 0.6, x - r, y - r * 0.6, x + r, y - r * 0.6)  -- the rim light
        if h > 0.15 then
          local up = h ^ 0.5 * 8
          line(2 + h * 4, x - r * 1.3, y, x - r * 1.6, y - up)
          line(2 + h * 4, x + r * 1.3, y, x + r * 1.6, y - up)
        end
      end
    end
    -- the booth's edge and the gooseneck lamp the open hats flare
    put(2 + K.bar_pulse * 2, 0, BY, 128, 3)
    line(2.5, 48, BY, 52, BY - 6)
    put(3 + lamp * 8, 50, BY - 8, 4, 2)
    if lamp > 0.08 then
      for k = 0, 3 do put(lamp * (4 - k), 47 - k, BY - 5 + k * 2, 10 + k * 2, 1) end
    end

    -- the decks
    deck(1, 1, e, c, lo, mid, hi)
    deck(2, live2, e, c, lo, mid, hi)

    -- the mixer: four meters (level, lows, mids, highs) with peak holds,
    -- the EQ knobs over them (a fill sweeps the filter; kickless the lows
    -- are cut), the crossfader walking across over the phrase
    local MX = 47
    line(1.5, MX - 2, BY + 4, MX - 2, 63)
    line(1.5, MX + 35, BY + 4, MX + 35, 63)
    local band = {amp, lo * (1 - kl * 0.7), mid, hi}
    for m = 1, 4 do
      meter[m] = math.max(meter[m] * math.exp(-DT / 0.12), band[m])
      if meter[m] > peakh[m] then peakh[m] = meter[m] else peakh[m] = peakh[m] - DT * 0.4 end
      local x = MX + 2 + (m - 1) * 8
      -- (solid columns: the track dim, the lit part bright, red at the top)
      local mv = clamp(meter[m] + (c > 0.2 and math.sin(T * 9 + m * 2) * c * 0.25 or 0), 0, 1)
      local top = 58 - mv * 22
      if top > 36 then put(1, x, 36, 4, top - 36) end
      if mv > 0.03 then
        local yr = math.min(58, math.max(top, 41))
        if yr < 58 then put(3.5 + mv * 2 + e, x, yr, 4, 58 - yr) end
        if top < 41 then put(8, x, top, 4, 41 - top) end
      end
      local pk = 58 - clamp(peakh[m], 0, 1) * 22
      put(4 + e * 2, x, pk - 1, 4, 1)
      -- the EQ knob over the strip
      local kv = m == 2 and (0.5 - kl * 0.45) or (m == 4 and 0.5 + filt * 0.45 or 0.5 + 0.05 * math.sin(T * 0.3 + m))
      local kx, ky = x + 2, BY + 6
      K.ring(1.5 + e * 0.5, kx, ky, 2.5, 8)
      local a = math.pi * 0.75 + clamp(kv, 0, 1) * math.pi * 1.5
      line(4 + e * 2, kx, ky, kx + math.cos(a) * 2.5, ky + math.sin(a) * 2.5)
    end
    line(1.5, MX + 3, 61, MX + 30, 61)
    -- (a ratchet cuts it back and forth, chaos wobbles it)
    local xk = clamp(xf + scratch * 0.4 * math.sin(T * 40) + c * c * 0.25 * math.sin(T * 3.3), 0, 1)
    put(4 + e * 2 + scratch * 5, MX + 2 + xk * 26, 60, 3, 3)
    -- the cue pads under the decks: percs and ratchets light them
    for k = 1, 8 do
      cuep[k] = cuep[k] * math.exp(-DT / 0.18)
      local x = k <= 4 and (8 + (k - 1) * 8) or (90 + (k - 5) * 8)
      put(1.2 + cuep[k] * 9, x, 61, 5, 2)
    end
    K.grain(function(u, v) return u * 128, 1 + v * 22 end, 2 + hi * 12 + e * 3, 2 + hi * 4)
  end

  function M.draw(S)
    local DT = K.DT
    blind = blind * math.exp(-DT / 0.18)
    bls = K.follow(bls, blind, 0.06, DT)
    flare = flare * math.exp(-DT / 0.3)
    conv = conv * math.exp(-DT / 0.9)
    bob = K.follow(bob, K.duck * (1 - K.kickless), 0.05, DT)
    kup = K.follow(kup, math.max(K.env.kick, A[K.LO] * 0.5), 0.05, DT)
    local pl = math.floor(K.num(S and S.phrase_len, 16))
    if not (pl >= 1 and pl <= 256) then pl = 16 end
    local pto = clamp((K.num(S and S.phrase_pos, 0) % pl + K.bar_ph) / pl, 0, 1)
    pp = K.follow(pp, pto, 0.5, DT)
    if K.view == 2 then draw2(S) elseif K.view == 3 then draw3(S) else draw1(S) end
  end

  M.init()
  return M
end
