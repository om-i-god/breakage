-- toy. view 1: an open music box on a table at night: a pinned brass cylinder
-- turns against the comb, a dancer turns on her mirror, the wind-up key turns.
-- view 2: a shelf of wind-up toys by a moonlit window: a soldier drummer, a
-- cymbal monkey, a spinning top, a rubber duck, and a little train circling.
-- view 3: a cot mobile in a dark nursery: a moon, a star, a bird and a fish
-- turn on their strings under a wind-up crank, a little bell hangs below the
-- hub, and a night-light on the cot rail throws turning stars on the walls.
--
-- view 1: music-box tines pluck the high teeth of the comb, the skin percs
-- (conga, bongo, talking drum, toms) the low ones, the other perc the middle,
-- and each rings and fades; the kick bumps the whole box and warms the comb;
-- the snare rattles the lid on its hinges and flashes the clasp; closed hats
-- glint the dancer's tiara, open hats send a shimmer out round the mirror;
-- squeaks squash the dancer; clave knocks the key a notch; break slices and
-- ratchets run plucks along the comb (a kick ratchet judders the box, a hat
-- one sparkles the mirror); a fill sweeps the comb and the dancer leaps and
-- spins. every bar chimes a tooth and the lamp swells over the phrase. energy
-- brings up the lamp and the dust in its light, chaos makes the cylinder skip
-- and the dancer judder with a ghost beside her, and kickless stretches wind
-- it all down: the cylinder and the dancer slow, she leans, and moonlight
-- slants in across the lid.
-- view 2: the kick swings the soldier's sticks onto his drum; the snare claps
-- the monkey's cymbals (his eyes go wide); closed hats spin the top up, open
-- hats flash its stripe and set it wobbling; skin percs tap the soldier's
-- drum, bells and metal tap the monkey's cymbals, other perc chuffs the train
-- along the track with a puff of smoke; squeaks squeeze the duck; clave
-- clicks the soldier's sticks; music box tines light the stars in the window;
-- ratchets give the soldier a roll; a fill makes the toys hop. the moon
-- crosses the window over the phrase and every bar the train whistles.
-- energy brightens the moonlight and the toys' paint, chaos makes the toys
-- judder with ghosts and rocks the train, kickless winds the toys down (sticks
-- droop, the top slows and precesses wide, the train crawls).
-- view 3: the kick bounces the mobile on its spring and swings the toys; the
-- snare strikes the bell (rings spread from it); closed hats glint one of the
-- projected stars, open hats flare the night-light's rays; music box tines
-- light up the star field, squeaks flap the bird, skin percs flip the fish,
-- other perc spins the star; clave and every bar turn the crank a notch;
-- ratchets run beads down the strings; a fill whirls the whole mobile. the
-- projection turns once a phrase. low end sets the bounce, mids the toys'
-- paint, highs the twinkle, the level the night-light. energy fills the
-- walls with stars, chaos tangles the strings (the toys judder, ghosts
-- trail them and the stars double), kickless slows the mobile to a drift
-- while the night-light takes the room.
return function(K)
  local M = {}
  local put, line, A, clamp = K.put, K.line, K.A, K.clamp
  local sin, cos, floor, max, min, abs = math.sin, math.cos, math.floor, math.max, math.min, math.abs
  local PI, TAU = math.pi, 2 * math.pi

  ---------------------------------------------------------------- state
  local NT = 15                          -- comb teeth
  local vib, pinlit                      -- per tooth: ring amount, pin glow
  local sched                            -- scheduled plucks {t, k, v}
  local rot, da, kr                      -- cylinder, dancer, key angles
  local wind                             -- wind-up speed 0..1 (kickless runs down)
  local bump, bumpy                      -- kick bump env, the box's eased offset px
  local rattle, clasp, glint, squash     -- snare rattle, clasp flash, hat glint, squeak
  local spin, warm, knock, last_skip     -- fill spin, kick warmth, clave knock, skip step
  -- view 2
  local stick, stick_side, roll          -- soldier stick hits (2), next side, ratchet roll
  local cym, eyes                        -- monkey cymbal clap, eye widen
  local tspin, tph, wob, prec            -- top spin rate, phase, wobble, precession angle
  local duck, trn, tv, puffs, stars      -- duck squeeze, train angle / speed, smoke, star glint
  local hop, click                       -- fill hop, clave click
  local ohat, chime, whistle, leap       -- open-hat shimmer, bar chime, bar whistle, fill leap
  local rjud                             -- a kick ratchet's judder
  -- view 3
  local mr, mrv, mrvE                    -- mobile angle, its spin boost (and eased)
  local sw, swp                          -- per toy: swing amplitude, swing phase
  local flap, flip, flipv                -- bird flap, fish flip target and its eased angle
  local sspin, sang                      -- star spin rate, its angle
  local bell, bellr, rays, crank         -- bell strike, its sound rings, light rays, crank angle
  local sglint, beads, hub               -- star glints {i, v}, beads {k, t0}, hub bounce

  function M.init()
    vib, pinlit = {}, {}
    for k = 1, NT do vib[k], pinlit[k] = 0, 0 end
    sched = {}
    rot, da, kr, wind = 0, 0, 0, 1
    bump, bumpy = 0, 0
    rattle, clasp, glint, squash = 0, 0, 0, 0
    spin, warm, knock, last_skip = 0, 0, 0, -1
    stick, stick_side, roll = {0, 0}, 1, 0
    cym, eyes = 0, 0
    tspin, tph, wob, prec = 3, 0, 0.15, 0
    duck, trn, tv, puffs, stars = 0, 0, 0, {}, 0
    hop, click = 0, 0
    ohat, chime, whistle, leap, rjud = 0, 0, 0, 0, 0
    mr, mrv, mrvE = 0, 0, 0
    sw, swp = {0.3, 0.3, 0.3, 0.3}, {0, 1.3, 2.6, 3.9}
    flap, flip, flipv, sspin, sang = 0, 0, 0, 0, 0
    bell, bellr, rays, crank = 0, {}, 0, 0
    sglint, beads, hub = {}, {}, 0
  end
  M.clear = M.init

  -- a filled ellipse, one rect per row
  local function fell(l, cx, cy, rx, ry)
    if not (rx > 0.3 and ry > 0.3) then return end
    for dy = -floor(ry), floor(ry) do
      local u = dy / ry
      local hw = rx * math.sqrt(max(0, 1 - u * u))
      if hw >= 0.5 then put(l, cx - hw, cy + dy, max(1, hw * 2), 1) end
    end
  end

  local function pluck(k, v)
    k = clamp(floor(K.num(k, 1)), 1, NT)
    vib[k] = math.max(vib[k], 0.4 + 0.6 * v)
    pinlit[k] = 1
  end
  local function pick(v) return 1 + floor(K.rnd() * NT) end

  ---------------------------------------------------------------- events
  function M.kick(v)
    v = K.num(v, 1)
    bump = math.max(bump, v)
    warm = math.max(warm, v)
    stick[stick_side] = 1
    stick_side = 3 - stick_side
    hub = max(hub, v)
    for i = 1, 4 do sw[i] = min(1.4, sw[i] + 0.35 * v * (0.6 + 0.4 * K.hash(i, 51))) end
  end
  function M.snare(v, n)
    v = K.num(v, 1)
    rattle = math.max(rattle, 0.6 + 0.4 * v)
    clasp = math.max(clasp, v)
    cym = 1
    eyes = 1
    bell = max(bell, v)
    if #bellr < 4 then bellr[#bellr + 1] = {t0 = K.T, v = v} end
  end
  function M.hat(v, open)
    v = K.num(v, 1)
    if open then
      ohat = max(ohat, v)
      rays = max(rays, v)
      wob = min(0.9, wob + 0.25 * v)
      tspin = min(9, tspin + 0.5 * v)
    else
      glint = max(glint, 0.7 * v)
      tspin = min(9, tspin + 0.8 * v)
      if #sglint < 6 then sglint[#sglint + 1] = {i = floor(K.rnd() * 40), v = v} end
    end
  end
  function M.perc(kind, v)
    v = K.num(v, 1)
    kind = floor(K.num(kind, 1))
    if kind == 12 or kind == 19 then
      squash = math.max(squash, 0.5 + 0.5 * v)
      duck = math.max(duck, 0.5 + 0.5 * v)
      flap = max(flap, 0.5 + 0.5 * v)
      return
    end
    if kind == 4 then
      knock = 1
      kr = kr + 0.5
      click = 1
      crank = crank + 0.6
      return
    end
    local skin = kind == 1 or kind == 2 or kind == 13 or kind == 17 or kind == 18
    local bellk = kind == 3 or kind == 6 or kind == 10 or kind == 21
    if kind == 11 or kind == 8 then
      pluck(11 + floor(K.rnd() * 5), v)                      -- the high teeth
      if K.rnd() < 0.4 then pluck(10 + floor(K.rnd() * 6), v * 0.7) end
      stars = math.max(stars, v)
    elseif skin then
      pluck(1 + floor(K.rnd() * 5), v * 0.8)                 -- the low teeth
      stick[stick_side] = max(stick[stick_side], 0.5 * v)
      stick_side = 3 - stick_side
      flip = flip + PI * (0.6 + 0.4 * v)
      return
    else
      pluck(5 + floor(K.rnd() * 6), v * 0.7)                 -- the middle
      if bellk then cym = max(cym, 0.55 * v); bell = max(bell, 0.5 * v); return end
      sspin = sspin + 2.5 * v
    end
    tv = tv + 0.6 * v
    if #puffs < 6 then puffs[#puffs + 1] = {t0 = K.T, u = trn, v = v} end
  end
  function M.tom(v)
    v = K.num(v, 1); pluck(1 + floor(K.rnd() * 4), v); tv = tv + 0.4 * v
    flip = flip + PI * 0.7
  end
  function M.tick(kind)
    kr = kr + 0.15
    click = math.max(click, 0.5)
  end
  function M.brk(s, n)
    s, n = K.num(s, 1), math.max(1, K.num(n, 8))
    pluck(1 + floor((s - 1) / n * NT), 0.6)
    tv = tv + 0.15
  end
  function M.ratchet(n, voice)
    n = clamp(floor(K.num(n, 2)), 1, 12)
    local k0 = 1 + floor(K.rnd() * NT)
    local dir = K.rnd() < 0.5 and 1 or -1
    for i = 0, n - 1 do
      if #sched < 24 then sched[#sched + 1] = {t = K.T + i * 0.05, k = (k0 - 1 + i * dir) % NT + 1, v = 0.8 - i * 0.04} end
    end
    roll = math.max(roll, clamp(n / 6, 0.3, 1))
    if voice == "kick" then rjud = 1 elseif voice == "hat" then ohat = max(ohat, 0.7) end
    for i = 1, min(n, 6) do
      if #beads < 12 then beads[#beads + 1] = {k = (i - 1) % 4 + 1, t0 = K.T + i * 0.04} end
    end
    spin = math.max(spin, clamp(n / 8, 0.4, 0.8))      -- the dancer whirls through the burst
  end
  function M.bar(S)
    chime = 1
    whistle = 1
    crank = crank + 0.4
    local b = floor(K.num(type(S) == "table" and S.bar, 0) % 4)
    pluck(NT - b * 2, 0.55)
    if #puffs < 6 then puffs[#puffs + 1] = {t0 = K.T, u = trn, v = 0.5} end
  end
  function M.fill()
    spin = 1
    hop = 1
    leap = 1
    mrv = 1
    for i = 0, NT - 1 do
      if #sched < 24 then sched[#sched + 1] = {t = K.T + i * 0.035, k = i + 1, v = 0.7} end
    end
    tv = tv + 1
  end

  -- how far through the phrase we are, 0..1, smooth across the bar
  local function phrase(S)
    local len = max(1, floor(K.num(S.phrase_len, 16)))
    local pos = K.num(S.phrase_pos, 0) % len
    return clamp((pos + K.bar_ph) / len, 0, 1)
  end

  ---------------------------------------------------------------- view 1
  local CYX0, CYX1, CYY, CYR = 20, 60, 33, 3.5
  local DX = 91                          -- the dancer's axis
  local function tx(k) return 21 + (k - 1) * 2.7 end

  local function draw1(S)
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, mid, kl = A[K.LO], A[K.HI], A[K.MID], K.kickless
    local ph = phrase(S)
    local lamp = 0.4 + e * 0.8 + A[K.AMP] * 1.1 + lo * 0.3 + ph * 0.5 + chime * 0.3
    local by = bumpy + ((rjud > 0.2 and floor(T * 25) % 2 == 0) and 1 or 0)

    -- the room: dim wallpaper sprigs either side of the box, the table
    for y = 2, 58, 6 do
      local o = (y // 6) % 2 * 4
      for x = o + 1, 127, 8 do
        if x < 11 or x > 117 or y < 3 then
          local d = math.abs(x - 64) / 64
          local wv = max(0, sin(x * 0.09 - T * 0.7 + y * 0.06))
          put(1 + (1 - d) * 0.3 * lamp + wv * (0.4 + hi * 1.2 + e * 0.4), x, y, 1, 1)
          if (x + y) % 3 == 0 then put(1, x - 1, y + 1, 3, 1) end
        end
      end
    end
    -- the lamp's warm pool on the wall behind (a dithered glow round the lid)
    K.gradient(0, 30, function(y) return (0.2 + 0.3 * lamp) * (1 - y / 34) end, nil, 0, 11)
    K.gradient(0, 30, function(y) return (0.2 + 0.3 * lamp) * (1 - y / 34) end, nil, 118, 128)
    line(2 + lamp, 0, 61, 127, 61)
    K.dashes(1, 63, 6, 11, 3)
    put(1, 10, 62, 108, 1)                -- the box's shadow on the table
    if warm > 0.15 then                    -- the kick thumps the box's feet on the table
      for _, fx in ipairs({9, 113}) do
        put(2 + warm * 7, fx, 61, 6, 1)
        put(1 + warm * 3, fx - 3 - warm * 3, 60, 2, 1); put(1 + warm * 3, fx + 7 + warm * 3, 60, 2, 1)
      end
    end

    -- the lid, open behind: its frame, a painted crescent moon, the mirror
    local lj = 0
    if rattle > 0.25 then lj = (floor(T * 30) % 2 == 0) and 1 or -1 end
    local ly = 0
    local lf = 2.5 + lamp * 0.8
    line(lf, 20 + lj, 3 + ly, 108 + lj, 3 + ly)
    line(lf, 20 + lj, 3 + ly, 14, 29 + ly)
    line(lf, 108 + lj, 3 + ly, 114, 29 + ly)
    line(1.5, 24 + lj, 6 + ly, 104 + lj, 6 + ly)
    -- the lining: a quilted lattice, a painted crescent moon and stars
    for i = 0, 3 do
      local x = 22 + i * 14
      line(1 + lamp * 0.3 + hi * 1.5, x, 6 + ly, x + 18, 27 + ly)
      line(1 + lamp * 0.3 + hi * 1.5, x + 18, 6 + ly, x, 27 + ly)
    end
    local mlv = 2.5 + e * 1.5 + stars * 4
    K.ring(mlv, 38, 16 + ly, 7, 12, PI * 0.4, PI * 1.6)
    K.ring(mlv * 0.8, 41, 16 + ly, 5.5, 10, PI * 0.5, PI * 1.5)
    put(mlv + 2, 35, 14 + ly, 1, 1)                      -- its eye
    line(mlv, 34, 19 + ly, 36, 20 + ly)            -- and its smile
    for i = 0, 4 do
      local sx, sy = 50 + i * 5, 8 + (i % 2) * 9 + (i % 3) * 2 + ly
      local tw = 0.5 + 0.5 * sin(T * (0.7 + i * 0.3) + i)
      put(1.5 + tw * 1.5 + hi * 4 + stars * 6, sx, sy, 1, 1)
      if stars > 0.3 then put(1 + stars * 3, sx - 1, sy, 3, 1) end
    end
    -- the mirror behind her, with a sheen that the hats catch
    local mx, my = 90, 14 + ly
    K.ring(3.5 + e + glint * 2 + hi * 3, mx, my, 12, 18, 0, TAU, 0.82)
    K.ring(2, mx, my, 13.5, 18, 0, TAU, 0.8)
    for k = 0, 1 do
      local sx0 = mx - 10 + k * 3
      line(2 + glint * 6 + hi * 1.5, sx0, my + 4, sx0 + 4, my - 4)
      line(1.5 + glint * 4, mx + 6 + k * 3, my + 4, mx + 9 + k * 3, my - 2)
    end
    if glint > 0.08 then                                          -- the cymbal's glint
      local gx, gy = mx - 6 + floor(K.hash(floor(T * 4), 3) * 4), my - 4
      line(4 + glint * 8, gx - 2, gy, gx + 2, gy)
      line(4 + glint * 8, gx, gy - 2, gx, gy + 2)
    end
    -- chaos cracks the mirror: shards that catch the light out of step
    if c > 0.2 then
      local cx0, cy0 = mx + 4, my - 3
      for k = 0, 4 do
        local a = K.hash(k, 81) * TAU
        local r = 5 + K.hash(k, 82) * 7
        local fl = 0.5 + 0.5 * sin(T * (2 + k) + k * 1.7)
        line(1 + (c - 0.2) * 5 * fl + hi * 2, cx0, cy0, cx0 + cos(a) * r, cy0 + sin(a) * r * 0.82)
      end
    end
    -- open hats: a shimmer spreading out round the mirror
    if ohat > 0.08 then
      K.ring(2 + ohat * 7, mx, my, 13.5 + (1 - ohat) * 8, 18, 0, TAU, 0.8)
    end
    -- kickless: moonlight slants in across the lid from the right
    if kl > 0.08 then
      for i = 0, 4 do
        local x0 = 70 + i * 9 + sin(T * 0.3 + i) * 2
        line(1 + kl * 1.6 + (i % 2) * 0.5 * kl, x0, 4, x0 - 20, 28)
      end
    end
    -- the clasp on the lid's top edge, flashing on the snare
    put(3 + clasp * 9, 62 + lj, 2 + ly, 4, 2)
    -- hinge chains, rattling
    for s = 0, 1 do
      local hx = s == 0 and 17 or 111
      local sway = rattle * sin(T * 40 + s) * 1.2
      line(2 + rattle * 4, hx, 27, hx + (s == 0 and 6 or -6) + sway, 20)
    end

    -- the open box: the back edge, the velvet floor, the divider
    line(4 + lamp * 0.6, 14, 29, 114, 29)
    line(3, 14, 29, 8, 42)
    line(3, 114, 29, 120, 42)
    for y = 31, 41, 3 do
      local x0 = 14 - (y - 29) * 6 / 13
      K.dashes(1, y, 1, 4, y * 2, floor(x0) + 1, floor(128 - x0) - 1)
    end
    line(2.5, 68, 29, 67, 42)

    -- the cylinder: brass body, end caps, pins turning past
    local cl = 1.6 + e * 0.6 + warm * 1.5 + mid * 1.8
    put(cl, CYX0, CYY - 2 + by, CYX1 - CYX0, 5)
    line(cl + 2, CYX0, CYY - 3 + by, CYX1, CYY - 3 + by)
    line(cl + 0.5, CYX0, CYY + 3 + by, CYX1, CYY + 3 + by)
    put(cl + 2.5 + lo * 2, CYX0 + 2, CYY - 2 + by, CYX1 - CYX0 - 4, 1)   -- its highlight
    K.ring(cl + 1.5, CYX0, CYY + by, CYR, 8, 0, TAU, 1, 0)
    K.ring(cl + 1.5, CYX1, CYY + by, CYR, 8, 0, TAU, 1, 0)
    line(cl + 1, CYX1 + 3, CYY + by, CYX1 + 5, CYY + by)              -- the spindle
    -- the governor fan, whirring with the cylinder
    local fa = rot * 6
    for b = 0, 1 do
      local w = 2.5 * cos(fa + b * PI)
      line(3 + e, 65, CYY - 3 + by + b * 6, 65 + w, CYY - 3 + by + b * 6)
    end
    line(2, 65, CYY - 4 + by, 65, CYY + 4 + by)
    for i = 0, 27 do
      local k = i % NT + 1
      local phi = K.hash(i, 5) * TAU + rot
      local s = sin(phi)
      if s > 0.15 then
        local x = tx(k) + (i >= NT and 1 or 0)
        local y = CYY - CYR * cos(phi)
        local pl = 3 + s * 3 + e
        if cos(phi) < -0.6 then pl = pl + pinlit[k] * 7 end   -- at the comb
        put(min(12, pl), x, y + by, 1, 1)
      end
    end
    -- the comb: a steel base and its teeth, each ringing when plucked
    put(2.5 + warm * 2 + lo * 2.5, 19, 39 + by, 43, 2)
    line(5 + warm * 3 + e + chime * 2, 19, 39 + by, 61, 39 + by)
    for k = 1, NT do
      local x = tx(k)
      local vv = vib[k]
      local w = vv > 0.04 and vv * 1.3 * sin(T * 47 + k * 1.9) or 0
      local lv = min(13, 3.5 + vv * 9 + e * 0.8 + warm * 1.5 + hi * 2)
      local top = 36 - (NT - k) * 0.12
      line(lv, x, 39 + by, x + w, top + by)
      if c > 0.5 and vv > 0.3 then line(lv * 0.4, x + 1.5 + w, 39 + by, x + 1.5 - w, top + by) end
    end

    -- the dancer on her mirror
    local dy = by
    fell(2 + e * 0.8 + glint * 2, DX, 38 + dy, 12, 2.5)
    K.ring(3.5 + e + glint * 3 + chime * 2, DX, 38 + dy, 13, 16, 0, TAU, 0.25)
    dy = dy - floor(sin(PI * (1 - leap)) * 3 * (leap > 0 and 1 or 0) + 0.5)
    local jud = 0
    if c > 0.15 then jud = (K.hash(floor(T * 9), 11) - 0.5) * c * 1.6 end
    local function dancer(l, x0, a, sq)
      local h = 1.45 * (1 - sq * 0.35)
      local lean = kl * 2.5
      local hx = x0 + lean
      local function Y(v) return 38 + dy - (38 - v) * h end
      local wx = x0 + lean * 0.5
      line(l, x0, Y(38), wx, Y(31))                                 -- standing leg
      local kx = x0 + 4.5 * cos(a)
      line(l * 0.85, wx, Y(31), kx, Y(33.5))                        -- the raised leg
      line(l * 0.85, kx, Y(33.5), x0, Y(36))
      local tw = 7 + sq * 3
      fell(l * 0.8, wx, Y(30.5), tw, 2)                            -- the tutu
      for k = 0, 2 do
        local ta = a * 2 + k * TAU / 3
        if sin(ta) > 0 then put(l + 2, wx + (tw - 0.5) * cos(ta), Y(30.5), 1, 1) end
      end
      line(l, wx, Y(30), hx, Y(25))                                 -- torso
      line(l * 0.8, wx + 1, Y(30), hx + 1, Y(25.5))
      local ac, as = cos(a), sin(a)
      local ay = Y(24.5)
      line(l * 0.9, hx, Y(25), hx + 6.5 * ac, ay + as * 1.2)          -- one arm out
      local sx2 = hx - 3 * ac
      line(l * 0.9, hx, Y(25), sx2, Y(24.5))                          -- one in couronne
      K.ring(l * 0.85, sx2 * 0.5 + hx * 0.5, Y(22.5) - 2.5 * h * 0.5, 3, 6, PI, TAU, 1.2)
      K.disc(l + 0.5, hx + 0.5, Y(22.5), 2)
      return hx, Y(21)
    end
    local dl = 6 + e * 2 + lo * 1.2 + mid * 2 + spin * 2
    local hx, hy = dancer(dl, DX, da + jud, squash)
    put(min(13, 5 + glint * 9 + hi * 3), hx - 0.5, hy - 1, 2, 1)       -- tiara
    if c > 0.25 then dancer(1.5 + c * 1.5, DX + sin(T * 1.7) * c * 9, da - 0.6 + jud * 2, squash) end
    -- her reflection in the mirror under her feet
    line(2 + e, DX, 39 + by, DX, 41 + by)

    -- the box front: frame, inlay, wood grain, keyhole, the key
    local fl = 3 + lamp * 0.7
    line(fl + 1, 8, 42, 120, 42)
    line(fl, 8, 42, 8, 60)
    line(fl, 120, 42, 120, 60)
    line(fl - 0.5, 8, 60, 120, 60)
    line(2, 12, 45, 116, 45)
    line(2, 12, 57, 116, 57)
    line(2, 12, 45, 12, 57)
    line(2, 116, 45, 116, 57)
    for g = 0, 2 do
      local gy = 48 + g * 3
      for s = 0, 5 do
        local x0 = 15 + s * 17 + floor(K.hash(g * 7 + s, 13) * 6)
        local w = 6 + floor(K.hash(g * 7 + s, 14) * 7)
        if x0 + w < 54 or x0 > 74 then
          put(1 + lamp * 0.25 + warm * 0.4, x0, gy + (s % 2), w, 1)
        end
      end
    end
    K.ring(3 + lamp + lo * 4 + knock * 6, 64, 50, 3, 8)
    put(3 + lamp + knock * 7, 64, 52, 1, 2)
    -- the key on the box's side
    local kc = cos(kr)
    local kh = 1 + 3.5 * abs(kc)
    line(4 + lamp, 120, 51, 124, 51)
    put(3 + lamp * 0.8 + (kc > 0 and 2 or 0) + knock * 4, 124, 51 - kh, 3, kh * 2 + 1)
    -- dust in the lamp's light over the box
    K.grain(function(u, v) return 14 + u * 100, 4 + v * 34 end, 2 + e * 10 + hi * 16, 3 + e * 3 + hi * 3)
  end

  ---------------------------------------------------------------- view 2
  local SH, SF = 44, 58                  -- the shelf's back and front edges
  local TCX, TCY, TRX, TRY = 64, 54, 60, 4
  local TOYS = {{11, 29}, {40, 64}, {73, 95}, {99, 121}}     -- x spans the train hides behind
  local WX0, WY0, WX1, WY1 = 62, 2, 100, 21                   -- the window
  local TOP_W = {[32] = 0.6, [33] = 0.6, [34] = 0.6, [35] = 0.6, [36] = 2.5, [37] = 5, [38] = 7,
    [39] = 8.5, [40] = 9, [41] = 9, [42] = 8.5, [43] = 7.5, [44] = 6.5, [45] = 5.5, [46] = 4.5,
    [47] = 3.5, [48] = 2.5, [49] = 1.8, [50] = 1.2, [51] = 0.8, [52] = 0.5}

  local function hidden(x)
    for i = 1, #TOYS do if x > TOYS[i][1] and x < TOYS[i][2] then return true end end
    return false
  end

  -- view 2 runs a touch dimmer overall, saving the top levels for the hits
  local G2 = 0.72
  local function draw2(S)
    local function g(l) return l * G2 + max(0, l - 6) * (1 - G2) end
    local put = function(l, ...) K.put(g(l), ...) end
    local line = function(l, ...) K.line(g(l), ...) end
    local fell = function(l, ...) fell(g(l), ...) end
    local T, DT, e, c = K.T, K.DT, K.energy, K.chaos
    local lo, hi, kl = A[K.LO], A[K.HI], K.kickless
    local moon = 0.8 + e * 0.7 + kl * 0.9 + A[K.AMP] * 0.5
    local hp = floor(sin(PI * (1 - hop)) * 2 * (hop > 0 and 1 or 0) + 0.5)
    local ph = phrase(S)
    local mnx = WX0 + 6 + ph * 26                      -- the moon crosses the window over the phrase
    -- chaos: one toy at a time judders
    local function jit(i)
      if c < 0.25 or floor(T * 3) % 4 + 1 ~= i then return 0 end
      return floor((K.hash(floor(T * 8) + i * 31, 17) - 0.5) * c * 5 + 0.5)
    end

    -- the wall: dotted paper stripes round the window
    for x = 3, 127, 8 do
      if x >= WX0 - 1 and x <= WX1 + 1 then put(1, x, WY1 + 3, 1, SH - WY1 - 4)
      else put(1, x, 0, 1, SH - 1) end
    end
    -- the window: frame, panes, the moon, stars, a cloud drifting by
    local fr = 2 + moon * 0.6
    line(fr, WX0, WY0, WX1, WY0); line(fr, WX0, WY1, WX1, WY1)
    line(fr, WX0, WY0, WX0, WY1); line(fr, WX1, WY0, WX1, WY1)
    line(fr - 1, 81, WY0, 81, WY1); line(fr - 1, WX0, 11, WX1, 11)
    put(1.5 + moon * 0.6, WX0 - 2, WY1 + 1, WX1 - WX0 + 5, 1)             -- the sill
    local mny = 7 + 2.5 * (2 * ph - 1) ^ 2
    K.disc(4 + moon * 1.5 + A[K.MID], mnx, mny, 3.5)
    K.ring(1.5 + moon * 0.6 + hi, mnx, mny, 5.5 + lo, 12)
    for i = 0, 6 do
      local sx, sy = WX0 + 2 + floor(K.hash(i, 41) * 16), WY0 + 2 + floor(K.hash(i, 42) * 17)
      if i > 3 then sx = 84 + floor(K.hash(i, 43) * 14); sy = 13 + floor(K.hash(i, 44) * 7) end
      local tw = 0.5 + 0.5 * sin(T * (0.6 + K.hash(i, 45)) + i * 2)
      put(1 + tw * (1 + hi * 2) + stars * 7, sx, sy, 1, 1)
    end
    local cx = (T * 1.5) % 56 - 14
    for r = 0, 1 do
      local x0, x1 = max(WX0 + 1, floor(WX0 + cx + r * 3)), min(WX1, floor(WX0 + cx + 16 - r * 3))
      if x1 > x0 then put(1.5 + moon * 0.4, x0, 14 + r, x1 - x0, 1) end
    end
    -- the moonlight falling down across the wall onto the shelf
    local ml = min(1.6, 0.5 + 0.3 * moon)
    for x = WX0 - 33, WX1 - 1, 2 do
      if x % 8 ~= 3 then
        local y0 = max(WY1 + 2, WY1 + 2 + (WX0 - x) * 35 / 34)
        local y1 = min(SF - 1, WY1 + 2 + (WX1 - x) * 35 / 26)
        if y1 > y0 + 1 then put(ml, x, floor(y0), 1, floor(y1 - y0)) end
      end
    end

    -- the shelf: back edge, front edge, the lip, brackets
    line(1 + moon * 0.3, 0, SH, 127, SH)
    put(1.5 + moon * 0.3 + lo * 0.6, 0, SF, 128, 4)
    for _, bx in ipairs({14, 106}) do
      line(2, bx, 62, bx, 63)
      line(2, bx, 62, bx + 6, 62)
    end

    -- the track round the toys, with its ties
    K.ring(1.5 + e * 0.4, TCX, TCY, TRX, 24, 0, TAU, TRY / TRX)
    for i = 0, 17 do
      local a = i / 18 * TAU
      local x, y = TCX + cos(a) * (TRX - 2), TCY + sin(a) * (TRY - 0.5)
      if sin(a) > 0 or not hidden(x) then put(1.5, x, y, 1, 1) end
    end

    -- the train: an engine and two cars, the far half behind the toys
    local function car(u, eng)
      local s = sin(u)
      local x = TCX + cos(u) * (TRX - 1)
      local y = TCY + s * (TRY - 0.5)
      if c > 0.3 then y = y + floor(sin(T * 13 + u * 3) * c * 1.5 + 0.5) end
      if s < 0 and hidden(x) then return end
      local l = (s < 0 and 2.5 or 4.5) + e * 1.5 + tv * 1.5
      local w = eng and 7 or 6
      put(l, x - w / 2, y - 4, w, 4)
      put(l * 0.5, x - w / 2 + 1, y - 5, w - 2, 1)
      if eng then
        put(l, x + 1, y - 7, 2, 3)                                   -- the chimney
        if whistle > 0.1 then
          for k = 1, 3 do put(2 + whistle * 6, x + 2 + k * 2, y - 8 - k - (1 - whistle) * 3, 1, 1) end
        end
        put(min(13, 6 + tv * 5 + e * 2), x + (sin(u) < 0 and -4 or 3), y - 3, 1, 1)
      else
        put(l + 2, x - 1, y - 3, 2, 1)                               -- a window
      end
      put(l * 0.6, x - w / 2, y, 1, 1); put(l * 0.6, x + w / 2 - 1, y, 1, 1)
    end
    car(trn, true)
    car(trn - 0.15, false)
    car(trn - 0.29, false)
    for i = #puffs, 1, -1 do
      local P = puffs[i]
      local age = T - P.t0
      if age > 1.4 then table.remove(puffs, i)
      else
        local u = age / 1.4
        local x = TCX + cos(P.u) * (TRX - 1) + 2
        local y = TCY + sin(P.u) * (TRY - 0.5) - 9 - age * 8
        K.ring((2 + 4 * P.v) * (1 - u), x + age * 3, y, 1.5 + age * 2.5, 8)
      end
    end

    -- the soldier drummer
    local sx = 20 + jit(1)
    local sy = -hp
    local wl = 3 + e * 1.5 + lo
    put(wl * 0.8, sx - 3, 43 + sy, 2, 8); put(wl * 0.8, sx + 1, 43 + sy, 2, 8)   -- legs
    put(wl + 2, sx - 4, 51 + sy, 3, 1); put(wl + 2, sx + 1, 51 + sy, 3, 1)       -- boots
    put(wl * 0.6, sx - 4, 30 + sy, 9, 13)                              -- the coat
    line(wl + 2, sx - 4, 30 + sy, sx + 4, 40 + sy)                     -- cross belts
    line(wl + 1, sx + 4, 30 + sy, sx - 4, 40 + sy)
    for b = 0, 2 do put(wl + 3, sx, 32 + b * 3 + sy, 1, 1) end
    K.disc(wl + 1, sx, 26.5 + sy, 3)                                   -- the face
    put(wl + 4, sx - 2, 27 + sy, 1, 1); put(wl + 4, sx + 2, 27 + sy, 1, 1)   -- rosy cheeks
    put(wl * 0.5, sx - 4, 14 + sy, 9, 10)                              -- the busby
    line(wl + 1, sx - 4, 23 + sy, sx + 4, 23 + sy)
    put(wl + 3, sx + 3, 11 + sy, 2, 4)                                 -- the plume
    -- his drum
    local skin = min(13, 4 + stick[1] * 7 + stick[2] * 7 + lo * 2 + roll * 3)
    put(2.5 + e, sx - 6, 42 + sy, 13, 6)
    fell(skin, sx, 41.5 + sy, 6.5, 1.5)
    line(4 + e, sx - 6, 47 + sy, sx + 6, 47 + sy)
    for z = 0, 3 do
      line(4 + e, sx - 6 + z * 3, 43 + sy, sx - 4.5 + z * 3, 47 + sy)
      line(4 + e, sx - 3 + z * 3, 43 + sy, sx - 4.5 + z * 3, 47 + sy)
    end
    -- the sticks: up between beats, down on the hits, drooping as he winds down
    local droop = (1 - wind) * 6
    for s = 1, 2 do
      local sg = s == 1 and -1 or 1
      local shx = sx + sg * 4
      local h = max(stick[s], roll * (0.5 + 0.5 * sin(T * 40 + s * PI)))
      local idle = 0.15 + 0.15 * sin(K.beat_ph * TAU + s * PI)
      local u = max(h, idle)
      local hx = shx + sg * 4 + (sg * -1.5 - sg * 4) * u
      local hy = 25 + droop + (37 - 25 - droop) * u
      local tipx = hx + sg * 2 * (1 - u) - sg * 3 * u
      local tipy = hy - 7 * (1 - u) + 3.5 * u
      line(wl, shx, 31 + sy, hx, hy + sy)
      line(min(13, wl + 2 + h * 6), hx, hy + sy, tipx, tipy + sy)
      if c > 0.4 then line(1.5 + c, hx, hy + sy, tipx + sg * 3 * c, tipy + sy - 3) end
    end
    if click > 0.1 then K.ring(4 + click * 8, sx, 22 + sy, 2 + (1 - click) * 4, 8) end
    local kc = cos(kr * 2)
    put(3 + e, sx + 5, 35 + sy, 2, 1)
    put(3 + e + (kc > 0 and 2 or 0), sx + 7, 35 + sy - 3 * abs(kc), 2, 1 + 6 * abs(kc))

    -- the cymbal monkey
    local mx = 52 + jit(2)
    local my = -hp
    local ml = 2.2 + e * 1.2 + lo * 0.5 + A[K.MID] * 1.5
    local nod = floor(sin(T * 1.3) * 0.7 + 0.5) + floor((1 - wind) * 2 + 0.5)
    fell(ml * 0.6, mx, 44 + my, 7, 7)                                  -- body
    fell(ml * 1.1, mx, 45 + my, 4, 4.5)                                -- belly
    fell(ml * 0.8, mx - 6, 51 + my, 3, 1.2); fell(ml * 0.8, mx + 6, 51 + my, 3, 1.2)
    local hy = 30 + my + nod
    K.disc(ml * 0.7, mx - 7, hy - 1, 2.5); K.disc(ml * 0.7, mx + 7, hy - 1, 2.5)   -- ears
    K.disc(ml * 0.8, mx, hy, 6)                                        -- head
    fell(ml + 2, mx, hy + 1.5, 4.5, 3.5)                               -- the face
    local el = min(13, 6 + eyes * 7 + hi * 2)
    local ew = eyes > 0.4 and 2 or 1
    put(el, mx - 3, hy - 1, ew, ew); put(el, mx + 2, hy - 1, ew, ew)
    line(ml + 4 + eyes * 3, mx - 3, hy + 3, mx + 3, hy + 3)           -- the grin
    put(ml * 0.5, mx - 2, hy + 4, 5, 1)
    put(ml + 2, mx - 2, hy - 9, 5, 3)                                  -- the fez
    line(ml + 3, mx + 2, hy - 9, mx + 4, hy - 5)
    -- arms and cymbals: apart, slammed together on the snare
    local sep = 3 + 11 * (1 - cym)
    for s = -1, 1, 2 do
      local cxp = mx + s * sep
      line(ml + 1, mx + s * 6, 40 + my, cxp, 38 + my)
      local cv = min(13, 5 + cym * 8 + hi * 2 + e)
      fell(cv, cxp, 37 + my, 1.5, 5)
      put(cv + 1, cxp, 37 + my, 1, 1)
      if c > 0.4 then fell(1.5 + c, cxp + s * (2 + c * 4), 37 + my, 1, 4) end
    end
    if cym > 0.4 then K.ring(4 + cym * 5, mx, 37 + my, 3 + (1 - cym) * 14, 12, 0, TAU, 0.8) end
    local mk = cos(kr * 2 + 1)
    put(3 + e + (mk > 0 and 2 or 0), mx + 8, 44 + my - 3 * abs(mk), 2, 1 + 6 * abs(mk))

    -- the spinning top: a striped cone on its point, wobbling as it slows
    local tcx = 84 + jit(3)
    local tilt = wob * sin(prec)
    local tl = 2.5 + e * 1.2
    for y = 32, 52 do
      local w = TOP_W[y]
      local x = tcx + (52 - y) * tilt * 0.35
      put(y < 36 and tl + 3 or tl, x - w, y - hp, max(1, w * 2), 1)
      if y >= 37 and y <= 47 then
        for k = 0, 2 do
          local a = tph + k * TAU / 3 + y * 0.12
          local s = sin(a)
          if s > 0 then put(min(12, tl + 2 + s * 4 + hi * 3 + glint * 4), x + w * cos(a), y - hp, 1, 1) end
        end
      end
      if y == 40 or (y == 43 and ohat > 0.2) then
        put(min(12, tl + 3 + glint * 4 + ohat * 6), x - w, y - hp, max(1, w * 2), 1)
      end
    end
    put(1.5, tcx - 4, 53, 9, 1)                                        -- its shadow

    -- the rubber duck, squeezed by the squeaks
    local dx = 111 + jit(4)
    local q = duck
    local dl = 2.5 + e * 1.2 + q * 3
    local dhy = 39 + q * 3 - hp
    fell(dl, dx, 47.5 + q * 1.5 - hp, 8 * (1 + q * 0.3), 4 * (1 - q * 0.35))
    put(dl, dx + 7, 43 + q * 2 - hp, 2, 2)                             -- the tail
    K.disc(dl, dx - 4, dhy, 3.5 * (1 - q * 0.2))
    put(dl + 3, dx - 10, dhy, 3, 2)                                    -- the beak
    put(min(13, dl + 5), dx - 5, dhy - 1, 1, 1)                        -- its eye
    if q > 0.3 then
      for k = -1, 1 do line(4 + q * 7, dx - 12, dhy + k * 2, dx - 14 - q * 2, dhy + k * 3) end
    end

    K.grain(function(u, v) return WX0 - 30 + u * 60, 24 + v * 30 end, 1 + e * 6 + hi * 5, 2 + moon)
  end

  ---------------------------------------------------------------- view 3
  local NLX, NLY = 111, 46               -- the night-light on the cot rail
  local RAIL = 50
  local LEN = {15, 21, 17, 24}           -- the toys' strings
  local ARM = 36

  local function star5(l, x, y, r, a)
    local px, py
    for k = 0, 10 do
      local rr = (k % 2 == 0) and r or r * 0.45
      local aa = a + k * PI / 5
      local qx, qy = x + cos(aa) * rr, y + sin(aa) * rr
      if px then line(l, px, py, qx, qy) end
      px, py = qx, qy
    end
  end

  local function oell(l, x, y, rx, ry) K.ring(l, x, y, rx, 10, 0, TAU, ry / rx) end
  local function hang(k, l, x, y, s, ph, sh)
    local fell = sh and oell or fell
    if k == 1 then                                                  -- the moon
      local ml = sh and l or l + ph * 3 + stars * 3
      K.ring(ml, x, y, 5 * s, 10, PI * 0.4, PI * 1.6)
      K.ring(ml * 0.8, x + 2 * s, y, 3.8 * s, 8, PI * 0.5, PI * 1.5)
      if not sh then put(ml + 1, x - 3 * s, y - 1, 1, 1) end
    elseif k == 2 then                                              -- the star
      if sh then star5(l, x, y, 5 * s, sang); return end
      star5(l + sspin * 2, x, y, 5 * s, sang)
      put(min(13, l + 2 + sspin * 4 + A[K.HI] * 3), x, y, 1, 1)
    elseif k == 3 then                                              -- the bird
      fell(l * 0.8, x, y, 4 * s, 1.8 * s)
      K.disc(l, x + 4 * s, y - 1.5 * s, 1.6 * s)
      put(sh and l or l + 2, x + 6 * s, y - 1.5 * s, 2, 1)
      line(l * 0.8, x - 4 * s, y, x - 7 * s, y - 2 * s)
      local fw = flap > 0.1 and sin(K.T * 32) * 4 * flap or sin(K.T * 2.1 + x * 0.05) * 1.2
      local wl = sh and l or l + flap * 5
      line(wl, x - 1, y - 1, x - 2 * s, y - 3 * s - fw)
      line(wl, x - 2 * s, y - 3 * s - fw, x + 2 * s, y - 1)
    else                                                            -- the fish
      local f = cos(flipv)
      local rx = max(0.8, 4.5 * s * abs(f))
      fell(l * 0.8, x, y, rx, 2.3 * s)
      local tx0 = x - f * (rx + 0.5)
      line(l, tx0, y, tx0 - f * 3 * s, y - 2.5 * s)
      line(l, tx0, y, tx0 - f * 3 * s, y + 2.5 * s)
      line(l * 0.8, tx0 - f * 3 * s, y - 2.5 * s, tx0 - f * 3 * s, y + 2.5 * s)
      if abs(f) > 0.3 and not sh then put(min(13, l + 4), x + f * rx * 0.5, y - 1, 1, 1) end
    end
  end

  local hubE, raysE, starsE, glowP = 0, 0, 0, 0.5
  local function draw3(S)
    local T, e, c = K.T, K.energy, K.chaos
    hubE = K.follow(hubE, hub, 0.05, K.DT)
    raysE = K.follow(raysE, rays, 0.06, K.DT)
    starsE = K.follow(starsE, stars, 0.08, K.DT)
    local hub, rays, stars = hubE, raysE, starsE
    local lo, mid, hi, amp, kl = A[K.LO], A[K.MID], A[K.HI], A[K.AMP], K.kickless
    local ph = phrase(S)
    local glow = 0.5 + amp * 1.2 + kl * 1.2 + e * 0.4 + rays * 0.8

    -- the projected stars turning round the walls, once a phrase
    local n = floor(14 + e * 18 + kl * 6)
    local turn = ph * 160 + T * 1.5
    for i = 0, n - 1 do
      local x = (K.hash(i, 61) * 160 + turn * (0.9 + K.hash(i, 64) * 0.2)) % 160 - 16
      local y = 2 + K.hash(i, 62) * 42
      local tw = 0.5 + 0.5 * sin(T * (1 + K.hash(i, 63) * 2) + i * 2.3)
      local l = 1.4 + tw * (0.8 + hi * 1.6) + kl * 1 + glow * 0.3
      if K.hash(i, 66) < 0.3 then l = l + stars * 5 end
      for j = 1, #sglint do if sglint[j].i == i then l = l + sglint[j].v * 7 end end
      l = min(12, l)
      if l > 6 or K.hash(i, 65) < 0.25 then
        put(l, x - 1, y, 3, 1); put(l, x, y - 1, 1, 3)
      else
        put(l, x, y, 1, 1)
      end
      if c > 0.4 then put(l * 0.4 * c, x + 3 + c * 3, y + 1, 1, 1) end
    end
    -- a low haze over the ceiling
    K.haze(0, 0, 128, 8, 0.15 + 0.25 * kl + 0.15 * amp, 1, T * 3)
    -- the night-light's soft pool on the wall, in scanlines
    glowP = K.follow(glowP, glow, 0.6, K.DT)
    local pr = 34 * (0.8 + 0.12 * min(2.5, glowP))
    for x = NLX - 46, 127, 3 do
      local dx = (x - NLX) / (pr * 1.35)
      local h = pr * math.sqrt(max(0, 1 - dx * dx))
      if h > 2 then
        local y = RAIL - h
        while y < RAIL - 0.5 do
          local sh = min(6, RAIL - y)
          put(1, x, y, 1, sh)
          y = y + sh
        end
      end
    end
    -- the window on the far wall: the night outside, curtains stirring
    local wl = 1.3 + amp * 0.5 + e * 0.3
    line(wl, 6, 6, 30, 6); line(wl, 6, 36, 30, 36)
    line(wl, 6, 6, 6, 36); line(wl, 30, 6, 30, 36); line(wl - 0.5, 18, 6, 18, 36)
    local cx = (T * 1.2) % 40 - 8
    put(1 + amp * 0.6, max(7, 7 + cx), 14, max(1, min(30, 19 + cx) - max(7, 7 + cx)), 1)
    K.disc(3 + kl * 2 + ph * 2, 12, 12, 2)
    for side = 0, 1 do
      for f = 0, 2 do
        local x0 = side == 0 and 3 + f * 2 or 29 + f * 2
        local swy = sin(T * 0.6 + f + side * 2) * (1 + hi * 2 + rays)
        line(1.5 + f * 0.3 + mid, x0, 4, x0 + swy, 40)
      end
    end
    line(1.5 + amp * 0.5, 2, 4, 35, 4)                               -- the curtain rail

    -- the night-light: its glow, its rays, the little dome
    for r = 1, 3 do
      K.ring(min(4, glow * (1.4 - r * 0.3)), NLX, NLY + 2, 4 + r * 4 + lo * 2, 14, PI, TAU)
    end
    for k = 0, 6 do
      local a = PI + (k + 0.5) / 7 * PI + sin(T * 0.4) * 0.05
      local r0, r1 = 7, 12 + rays * 16 + glow * 3
      line(min(9, 1 + glow * 0.6 + rays * 6), NLX + cos(a) * r0, NLY + 2 + sin(a) * r0,
        NLX + cos(a) * r1, NLY + 2 + sin(a) * r1)
    end
    fell(min(11, 3.5 + glow * 2.5), NLX, NLY + 2, 4, 3.5)
    put(min(12, 5 + glow * 2 + rays * 3), NLX - 1, NLY, 2, 1)
    put(3, NLX - 5, NLY + 3, 11, 2)

    -- the cot: the rail and its bars, lit near the night-light
    line(1.6 + mid * 0.6 + e * 0.3, 0, RAIL, 127, RAIL)
    for x = 3, 125, 7 do
      local near = max(0, 1 - abs(x - NLX) / 40)
      local l = 1.2 + near * glow * 1.2 + 0.5 * max(0, sin(x * 0.07 - T * 0.5)) * (0.5 + lo)
      put(l, x, RAIL + 3, 1, 61 - RAIL)
    end

    -- the hook, the spring and the crank
    local hy = 9 + hub * (2 + lo * 2) + sin(T * 1.1) * 0.6
    line(2 + amp, 64, 0, 64, hy - 6)
    for z = 0, 2 do
      local zy = hy - 6 + z * 1.4
      line(2.5 + hub * 3, 62, zy, 66, zy + 0.7)
    end
    put(3 + e + K.bar_pulse * 3, 61, hy - 3, 7, 3)
    local ka = crank + mr * 0.5
    line(4 + e + K.bar_pulse * 3, 68, hy - 2, 68 + cos(ka) * 3, hy - 2 + sin(ka) * 1.5)

    -- the arms
    local tips = {}
    for k = 1, 4 do
      local a = mr + (k - 1) * PI / 2
      tips[k] = {x = 64 + cos(a) * ARM, y = hy + sin(a) * 3, z = sin(a)}
    end
    local al = 2.5 + e * 0.7 + mid
    line(al, tips[1].x, tips[1].y, tips[3].x, tips[3].y)
    line(al, tips[2].x, tips[2].y, tips[4].x, tips[4].y)

    -- the toys and the bell, far side first
    local order = {1, 2, 3, 4}
    table.sort(order, function(a, b) return tips[a].z < tips[b].z end)
    local function toy(k)
      local tp = tips[k]
      local f = 0.55 + 0.45 * (tp.z + 1) / 2
      local s = 0.8 + 0.3 * (tp.z + 1) / 2
      local dx = sw[k] * 4 * sin(swp[k])
      if c > 0.25 then dx = dx + (K.hash(floor(T * 7) + k * 13, 71) - 0.5) * c * 4 end
      local x, y = tp.x + dx, tp.y + LEN[k] + abs(dx) * 0.2
      line(1 + f * 1.3, tp.x, tp.y, x, y - 4 * s)
      for b = 1, #beads do                                           -- ratchet beads run down
        local B = beads[b]
        local u = (T - B.t0) / 0.5
        if B.k == k and u >= 0 and u < 1 then
          put(5 + 6 * (1 - u), tp.x + (x - tp.x) * u, tp.y + (y - 4 * s - tp.y) * u, 1, 1)
        end
      end
      local l = (3 + e * 1.5 + mid * 2) * f
      if c > 0.35 then hang(k, 1.2 + c, x - dx * 0.6 - 3 * c, y + 1, s, ph) end
      hang(k, l, x, y, s, ph)
    end
    -- the toys' big soft shadows thrown up the wall by the night-light
    for k = 1, 4 do
      local tp = tips[k]
      local x, y = tp.x + sw[k] * 4 * sin(swp[k]), tp.y + LEN[k]
      hang(k, min(2, 0.8 + glow * 0.3), NLX + (x - NLX) * 1.7, NLY + (y - NLY) * 1.5, 1.6, 0, true)
    end
    for j = 1, 4 do if tips[order[j]].z < 0 then toy(order[j]) end end
    -- the bell under the hub
    local bsw = bell * sin(T * 17) * 2.5
    local bx, byy = 64 + bsw, hy + 15
    line(1.5 + bell * 2, 64, hy, bx, byy - 3)
    local bl = min(12, 3 + e + bell * 8 + A[K.MID] * 1.5)
    fell(bl, bx, byy, 2.5, 3)
    line(bl, bx - 4, byy + 3, bx + 4, byy + 3)
    put(min(13, bl + 2), bx - bsw * 0.6, byy + 4, 1, 1)
    for i = 1, #bellr do
      local R = bellr[i]
      local u = (T - R.t0) / 0.9
      if u >= 0 and u < 1 then K.ring((1.5 + 4 * R.v) * (1 - u), bx, byy, 5 + u * 16, 16, 0, TAU, 0.55) end
    end
    for j = 1, 4 do if tips[order[j]].z >= 0 then toy(order[j]) end end

    K.grain(function(u, v) return NLX - 40 + u * 40, 20 + v * 28 end, 1 + e * 5 + hi * 5, 2 + glow)
  end

  ---------------------------------------------------------------- frame
  function M.draw(S)
    local DT, DTS = K.DT, K.DTS
    local kl, c, e = K.kickless, K.chaos, K.energy
    wind = K.follow(wind, 1 - 0.75 * kl, 0.8, DT)
    -- scheduled plucks
    for i = #sched, 1, -1 do
      if K.T >= sched[i].t then pluck(sched[i].k, sched[i].v); table.remove(sched, i) end
    end
    -- chaos plucks a stray tooth now and then
    if c > 0.3 and K.rnd() < (c - 0.3) * 0.3 then pluck(1 + floor(K.rnd() * NT), 0.3) end
    for k = 1, NT do
      vib[k] = vib[k] * math.exp(-DT / (0.35 + kl * 0.4))
      pinlit[k] = pinlit[k] * math.exp(-DT / 0.12)
    end
    -- the cylinder turns; chaos makes it skip on the 16ths
    rot = rot + DTS * (0.8 + e * 0.4) * wind
    local st = floor(K.stepf)
    if c > 0.2 and st ~= last_skip then
      last_skip = st
      if K.hash(st, 9) < (c - 0.2) * 0.5 then rot = rot + (K.hash(st, 10) < 0.5 and 0.5 or -0.35) end
    end
    da = da + DTS * (1.1 + spin * 9 + e * 0.5) * wind
    kr = kr + DTS * 0.7 * wind
    -- the kick's bump: a pixel or two, a pixel a frame
    local to = bump > 0.35 and 1 or 0
    if to > bumpy then bumpy = bumpy + 1 elseif to < bumpy then bumpy = bumpy - 1 end
    bump = bump * math.exp(-DT / 0.08)
    warm = warm * math.exp(-DT / 0.25)
    rattle = rattle * math.exp(-DT / 0.15)
    clasp = clasp * math.exp(-DT / 0.12)
    glint = glint * math.exp(-DT / 0.18)
    squash = squash * math.exp(-DT / 0.15)
    spin = spin * math.exp(-DT / 0.8)
    knock = knock * math.exp(-DT / 0.12)
    -- view 2's toys
    for s = 1, 2 do stick[s] = stick[s] * math.exp(-DT / 0.09) end
    roll = roll * math.exp(-DT / 0.35)
    cym = cym * math.exp(-DT / 0.1)
    eyes = eyes * math.exp(-DT / 0.35)
    tspin = K.follow(tspin, 2.5 * wind + e * 1.5, 1.2, DT)
    tph = tph + DTS * tspin * 2
    wob = K.follow(wob, 0.12 + (1 - wind) * 0.7 + c * 0.3, 1.5, DT)
    prec = prec + DTS * (1.5 + tspin * 0.2)
    duck = duck * math.exp(-DT / 0.14)
    tv = tv * math.exp(-DT / 0.6)
    trn = trn + DTS * (0.35 * wind + tv * 1.2 + e * 0.15)
    stars = stars * math.exp(-DT / 0.4)
    hop = max(0, hop - DT / 0.45)
    click = click * math.exp(-DT / 0.1)
    ohat = ohat * math.exp(-DT / 0.3)
    chime = chime * math.exp(-DT / 0.3)
    whistle = whistle * math.exp(-DT / 0.4)
    leap = max(0, leap - DT / 0.5)
    rjud = rjud * math.exp(-DT / 0.25)
    -- view 3's mobile
    mrv = mrv * math.exp(-DT / 1.2)
    mrvE = K.follow(mrvE, mrv, 0.35, DT)
    mr = mr + DTS * (0.35 * wind + e * 0.2 + mrvE * 1.8)
    for i = 1, 4 do
      sw[i] = K.follow(sw[i], 0.12 + (1 - wind) * 0.25 + c * 0.2, 2.5, DT)
      swp[i] = swp[i] + DTS * (2.2 + i * 0.17) * (0.6 + 0.4 * wind)
    end
    flap = flap * math.exp(-DT / 0.3)
    flipv = K.follow(flipv, math.ceil(flip / PI - 1e-6) * PI, 0.1, DT)
    if flip > 1e4 then flip, flipv = flip % TAU, flipv % TAU end
    sang = (sang + DTS * (0.6 + sspin * 5)) % TAU
    sspin = sspin * math.exp(-DT / 0.6)
    bell = bell * math.exp(-DT / 0.25)
    rays = rays * math.exp(-DT / 0.35)
    hub = hub * math.exp(-DT / 0.15)
    for i = #bellr, 1, -1 do if K.T - bellr[i].t0 > 0.9 then table.remove(bellr, i) end end
    for i = #sglint, 1, -1 do
      sglint[i].v = sglint[i].v * math.exp(-DT / 0.25)
      if sglint[i].v < 0.05 then table.remove(sglint, i) end
    end
    for i = #beads, 1, -1 do if K.T - beads[i].t0 > 0.5 then table.remove(beads, i) end end
    if K.view == 2 then draw2(S) elseif K.view == 3 then draw3(S) else draw1(S) end
  end

  M.init()
  return M
end
