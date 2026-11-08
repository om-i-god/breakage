-- breakage / visuals
-- eight places on the 128x64 OLED at night, one per kit, drawn from what the
-- drummer is playing and from what the engine hears of itself. greys on
-- black; the dim levels carry the atmosphere and the bright ones are kept
-- for the hits. the pulse shows in every theme, energy loosens and fills the
-- picture, chaos fractures and multiplies it, and nothing strobes.
--
-- adapted from gradient's visuals: the same machine runs under every theme.
--
--   the ears    out_amp / out_lo / out_mid / out_hi from the engine, eased.
--               until one arrives they are made up from the hit envelopes
--   the beat    where we are in the beat and the bar, smooth between 16ths
--   the duck    a ghost sidechain: snaps down on each kick, recovers over
--               the beat; kickless stretches ease in and out
--   the arc     energy and chaos (eased), the echo time
--
-- motion runs on time, not frames: the vis_speed param scales time, and a
-- dropped frame changes nothing but smoothness.
--
-- each theme lives in lib/vis/<name>.lua. it returns a function that takes
-- the kit (K: the helpers below plus a read-only view of the machine,
-- refreshed every frame) and returns {draw = fn(S), and optionally
-- kick(vel), snare(vel, ratchet_n), clap(vel), rim(vel), hat(vel, open),
-- ride(vel), shaker(vel), tom(vel, hz), perc(kind, vel), tick(kind),
-- brk(slice, n, reversed), ratchet(n, voice), fill(kind), bar(S), init(),
-- clear()}. a missing handler falls back: clap -> snare, rim / ride /
-- shaker -> hat, tom -> perc -> hat, brk -> tick -> hat (every other one).
-- events reach only the theme on screen; the kit keeps the envelopes and
-- the history for every theme.
--
-- perc kinds: 1 conga 2 bongo 3 cowbell 4 clave 5 acid 6 metal 7 log 8 plink
-- 9 guiro 10 tambourine.
-- K.view (1 or 2, the vis_view param) picks the theme's second view: every
-- theme draws both. vis_shake (off / soft / hard) jolts the whole picture
-- down a pixel or few on each kick, applied under the themes.
--
-- the glitch: VIS.event("glitch", mode, dur) tears the picture for as long
-- as the engine's glitch insert runs, whatever the theme: a band of rows
-- holds still on each stutter / chop slice while the rest moves on, slides
-- out and home on a reverse, drifts out while the picture dims through a
-- tape stop, and coarsens on a crush.
--
-- robust: a theme that fails to load, or errors while drawing or hearing
-- an event, is swapped for a plain fallback scene (logged once) instead of
-- taking the screen or the script down; every frame has a draw budget.

local VIS = {}

VIS.audio_level = 0
VIS.names = {"dub", "house", "acid", "analord", "syro", "broken", "drill", "gabber",
  "ambient", "rave", "jungle", "industrial", "acoustic", "minipops"}

local FPS = 20
local TAU = 2 * math.pi

-- state (declared before any function that uses it)
local B = 1                             -- brightness scale for this frame
local SP = 1                            -- speed scale (1 at the default 3)
local T = 0                             -- motion time, s (scaled by speed)
local NOW = 0                           -- real time since init, s
local DT, DTS = 1 / FPS, 1 / FPS        -- this frame's real / motion step
local last_clock                        -- util.time() at the last frame
local cur, xf = nil, 0                  -- theme on screen, its fade (0..1)
local THEMES = {}                       -- the loaded theme modules, by index

-- the engine's output, as polled: raw targets and eased followers
local AMP, LO, MID, HI = 1, 2, 3, 4
local A_IDX = {out_amp = AMP, out_lo = LO, out_mid = MID, out_hi = HI}
local raw = {0, 0, 0, 0}
local A = {0, 0, 0, 0}
local RISE = {0.03, 0.03, 0.05, 0.03}           -- s: rise fast...
local FALL = {0.35, 0.25, 0.4, 0.2}             -- ...fall a little slower
local heard = -1                                -- NOW when a poll last arrived

-- envelopes: events set them (by velocity), they decay on time
local env = {kick = 0, snare = 0, clap = 0, rim = 0, hat = 0, ohat = 0, ride = 0,
  shaker = 0, tom = 0, perc = 0, acid = 0, tick = 0, brk = 0, ratchet = 0, fill = 0}
local ENV_TAU = {kick = 0.12, snare = 0.12, clap = 0.1, rim = 0.06, hat = 0.05, ohat = 0.2,
  ride = 0.25, shaker = 0.05, tom = 0.15, perc = 0.1, acid = 0.18, tick = 0.04, brk = 0.08,
  ratchet = 0.3, fill = 0.8}
local last = {}                         -- event name -> NOW it last came

-- the glitch tear (see the header): time left, length, mode, band, shift
local gl_t, gl_dur, gl_mode = 0, 0, 0
local gl_y0, gl_y1, gl_dx = 0, 0, 0
local gl_sag = 0
local gl_dx_abs = 0
local gl_dim = 1                        -- tape stop: eased brightness factor
local gl_slice = -1                     -- stutter / chop: the slice being held
local gl_cap = false                    -- this frame captures the held band
local hold, hn = {}, 0                  -- the held band: level, kind, 4 numbers

-- robustness: themes that failed, the per-frame draw budget
local broken = {}
local logged = {}
local OPS_CAP = 1200
local ops = 0

-- the machine
local energy, chaos, trend = 0, 0, 0
local kickless = 0
local duck, duck_age = 0, 99
local beat_ph, bar_ph = 0, 0
local beat_sec = 0.5
local stepf = 0                         -- the 16th counter, smooth between steps
local step_seen, step_t = -1, 0
local bar_kick, bar_pulse = 0, 0
local hist = {}                         -- per bar: {e, c, kl}
local HIST_N = 64
local rseed = 1                         -- the visuals' own dice
local energy_seen = false
local rat_n, rat_voice = 0, nil         -- the last ratchet burst
local slice_i, slice_n, slice_rev = 0, 8, false
local tick_odd = false
local shake_dy = 0                      -- kick shake: whole-picture jolt, px

local K = {A = A, AMP = AMP, LO = LO, MID = MID, HI = HI, TAU = TAU,
  env = env, last = last, hist = hist, HIST_N = HIST_N}

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function num(v, d)
  v = tonumber(v)
  if v == nil or v ~= v or v == math.huge or v == -math.huge then return d end
  return v
end

local function ease(u)
  u = clamp(u, 0, 1)
  return u * u * (3 - 2 * u)
end

local function follow(v, to, tau, dt) return v + (to - v) * (1 - math.exp(-dt / tau)) end

-- own dice so the visuals never disturb (or depend on) math.random
local function rnd()
  rseed = (rseed * 1103515245 + 12345) & 0x7fffffff
  return rseed / 2147483648.0
end

-- a fixed hash 0..1 of an integer (and a salt): for shapes that must not move
local function hash(i, s)
  i = num(i, 0)
  if not (i > -1e9 and i < 1e9) then i = 0 end
  i = math.floor(i) // 1 | 0
  local h = ((i * 374761393 + (s or 0) * 668265263) & 0x7fffffff)
  h = ((h ~ (h >> 13)) * 1274126177) & 0x7fffffff
  return (h ~ (h >> 16)) / 2147483648.0
end

local function opt(id, d)
  local ok, v = pcall(function() return params:get(id) end)
  if ok and type(v) == "number" and v == v then return v end
  return d
end

------------------------------------------------------------------------
-- batched drawing: one fill / stroke per brightness level
------------------------------------------------------------------------

local batch, bn = {}, {}
local lbatch, lbn = {}, {}
for l = 1, 15 do batch[l], bn[l], lbatch[l], lbn[l] = {}, 0, {}, 0 end

local function lvl(l)
  l = l * B
  if not (l >= 0.5) then return nil end                  -- also drops NaN
  l = math.floor(l + 0.5)
  if l > 15 then l = 15 end
  return l
end

local function okc(v) return v == v and v > -1e6 and v < 1e6 end

local function tear(x, y, w)
  if gl_t <= 0 then return x, y, w end
  y = y + gl_sag
  if y >= gl_y0 and y < gl_y1 then
    if gl_mode == 5 then
      local x1 = x + w
      x = (x // 3) * 3
      w = math.max(3, ((x1 + 2) // 3) * 3 - x)
    else
      x = x + gl_dx
    end
  end
  return x, y, w
end

local function held(y)
  return gl_t > 0 and (gl_mode == 1 or gl_mode == 4) and y >= gl_y0 and y < gl_y1
end
local function keep(l, kind, a, b, c, d)
  if gl_cap and hn < 400 then
    hold[hn + 1], hold[hn + 2], hold[hn + 3], hold[hn + 4], hold[hn + 5], hold[hn + 6] = l, kind, a, b, c, d
    hn = hn + 6
  end
end

local function put(l, x, y, w, h)
  w, h = w or 1, h or 1
  if type(x) ~= "number" or type(y) ~= "number" or type(w) ~= "number" or type(h) ~= "number" then return end
  if not (okc(x) and okc(y)) then return end
  if not (w >= 1 and h >= 1 and w < 1e4 and h < 1e4) then return end
  if x >= 128 or y >= 64 or x + w <= 0 or y + h <= 0 then return end
  if ops >= OPS_CAP then return end
  l = lvl(l)
  if not l then return end
  ops = ops + 1
  y = y + shake_dy
  if held(y) then keep(l, 1, x, y, w, h); return end
  x, y, w = tear(x, y, w)
  local b, n = batch[l], bn[l]
  b[n + 1], b[n + 2], b[n + 3], b[n + 4] = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
  bn[l] = n + 4
end

local function line(l, x0, y0, x1, y1)
  if type(x0) ~= "number" or type(y0) ~= "number" or type(x1) ~= "number" or type(y1) ~= "number" then return end
  if not (okc(x0) and okc(y0) and okc(x1) and okc(y1)) then return end
  if (x0 < 0 and x1 < 0) or (x0 > 127 and x1 > 127) or (y0 < 0 and y1 < 0) or (y0 > 63 and y1 > 63) then return end
  if ops >= OPS_CAP then return end
  l = lvl(l)
  if not l then return end
  ops = ops + 1
  y0, y1 = y0 + shake_dy, y1 + shake_dy
  if held(y0) then keep(l, 2, x0, y0, x1, y1); return end
  if gl_t > 0 then
    local dx = 0
    if gl_mode ~= 5 and y0 + gl_sag >= gl_y0 and y0 + gl_sag < gl_y1 then dx = gl_dx end
    x0, x1, y0, y1 = x0 + dx, x1 + dx, y0 + gl_sag, y1 + gl_sag
  end
  local b, n = lbatch[l], lbn[l]
  b[n + 1], b[n + 2], b[n + 3], b[n + 4] = x0 + 0.5, y0 + 0.5, x1 + 0.5, y1 + 0.5
  lbn[l] = n + 4
end

local function discard()
  for l = 1, 15 do bn[l], lbn[l] = 0, 0 end
end

local function flush()
  ops = 0
  if gl_t > 0 and (gl_mode == 1 or gl_mode == 4) then
    for i = 1, hn, 6 do
      local l, kind = hold[i], hold[i + 1]
      if kind == 1 then
        local b, n = batch[l], bn[l]
        b[n + 1], b[n + 2], b[n + 3], b[n + 4] = math.floor(hold[i + 2]), math.floor(hold[i + 3]),
          math.floor(hold[i + 4]), math.floor(hold[i + 5])
        bn[l] = n + 4
      else
        local b, n = lbatch[l], lbn[l]
        b[n + 1], b[n + 2], b[n + 3], b[n + 4] = hold[i + 2] + 0.5, hold[i + 3] + 0.5, hold[i + 4] + 0.5, hold[i + 5] + 0.5
        lbn[l] = n + 4
      end
    end
  end
  gl_cap = false
  for l = 1, 15 do
    local n = bn[l]
    if n > 0 then
      local b = batch[l]
      screen.level(l)
      for i = 1, n, 4 do screen.rect(b[i], b[i + 1], b[i + 2], b[i + 3]) end
      screen.fill()
      bn[l] = 0
    end
  end
  screen.line_width(1)
  for l = 1, 15 do
    local n = lbn[l]
    if n > 0 then
      local b = lbatch[l]
      screen.level(l)
      for i = 1, n, 4 do
        screen.move(b[i], b[i + 1])
        screen.line(b[i + 2], b[i + 3])
      end
      screen.stroke()
      lbn[l] = 0
    end
  end
end

------------------------------------------------------------------------
-- scenery helpers
------------------------------------------------------------------------

-- a skyline profile: prof[c] is the top y of the mass at column 2c (c = 0..64)
local function profile(fn)
  local p = {}
  for c = 0, 64 do p[c] = fn(c * 2) end
  return p
end

local function at(prof, x)
  local c = math.floor(num(x, 0) / 2)
  if c < 0 then c = 0 elseif c > 64 then c = 64 end
  return prof[c]
end

local function mass(l, prof, y_bot, x0, x1)
  for c = (x0 or 0) // 2, math.min(63, ((x1 or 128) - 1) // 2) do
    local top = math.floor(prof[c] + 0.5)
    if top < y_bot then put(l, c * 2, top, 2, y_bot - top) end
  end
end

-- one row lit where it is above the profile (prof may be nil: all of it)
local function row_above(l, y, prof, x0, x1)
  x0, x1 = x0 or 0, x1 or 128
  if not prof then put(l, x0, y, x1 - x0, 1); return end
  local run
  for c = x0 // 2, (x1 - 1) // 2 do
    if y < prof[c] then
      run = run or c * 2
    elseif run then
      put(l, run, y, c * 2 - run, 1); run = nil
    end
  end
  if run then put(l, run, y, x1 - run, 1) end
end

local TH8 = {0, 4, 2, 6, 1, 5, 3, 7}

-- a vertical gradient of whole rows, ordered-dithered between levels
local function gradient(y0, y1, lv, prof, x0, x1)
  for y = y0, y1 do
    local v = lv(y)
    if v == v and v > 0.05 then
      local th = (TH8[y % 8 + 1] + 0.5) / 8
      local l
      if v < 1 then l = (v > th) and 1 or 0
      else
        l = math.floor(v)
        if v - l > th then l = l + 1 end
      end
      if l > 0 then row_above(l, y, prof, x0, x1) end
    end
  end
end

local function dashes(l, y, w, gap, off, x0, x1)
  x0, x1 = x0 or 0, x1 or 128
  off = num(off, 0)
  local s = x0 + (off % gap) - gap
  for x = s, x1 - 1, gap do
    local a, b = math.max(x0, x), math.min(x1, x + w)
    if b > a then put(l, a, y, b - a, 1) end
  end
end

-- haze: drifting banks of dithered fog over a box
local function haze(x0, y0, x1, y1, density, l, drift)
  density = clamp(num(density, 0), 0, 1)
  if density < 0.02 then return end
  drift = num(drift, 0)
  local thr = 1.6 - 3.2 * density
  for y = y0, y1 - 1, 2 do
    local run
    local yo = (y // 2) % 2
    for x = x0 + yo * 2, x1 - 1, 4 do
      local w = math.sin((x + drift) * 0.045 + y * 0.21 + T * 0.13)
        + 0.8 * math.sin((x - drift * 0.6) * 0.083 - y * 0.11 - T * 0.21)
      if w > thr then
        run = run or x
      elseif run then
        dashes(l, y, 2, 4, run - x0 - yo * 2, run, x); run = nil
      end
    end
    if run then dashes(l, y, 2, 4, run - x0 - yo * 2, run, x1) end
  end
end

-- grain: a few short-lived points where `sample(u, v)` says
local grains, grain_acc = {}, 0
local GRAIN_MAX = 18
local function grain(sample, rate, peak)
  grain_acc = grain_acc + num(rate, 0) * DTS
  while grain_acc >= 1 do
    grain_acc = grain_acc - 1
    if #grains < GRAIN_MAX then
      local x, y = sample(rnd(), rnd())
      if x then grains[#grains + 1] = {x = x, y = y, t0 = T, life = 0.15 + 0.25 * rnd(), pk = (peak or 6) * (0.6 + 0.4 * rnd())} end
    end
  end
  for i = #grains, 1, -1 do
    local g = grains[i]
    local u = (T - g.t0) / g.life
    if u >= 1 or u < 0 then table.remove(grains, i)
    else put(g.pk * math.sin(math.pi * u), g.x, g.y, 1, 1) end
  end
end

-- a ring (or an arc a0..a1, radians) of line segments; squash scales y;
-- jit (px) wobbles each vertex by a fixed hash of `seed`
local function ring(l, cx, cy, r, segs, a0, a1, squash, jit, seed)
  r = num(r, 0)
  if not (r > 0.5) or r > 400 then return end
  segs = clamp(math.floor(num(segs, 16)), 3, 48)
  a0, a1 = num(a0, 0), num(a1, TAU)
  squash, jit, seed = num(squash, 1), num(jit, 0), num(seed, 0)
  local px, py
  for k = 0, segs do
    local a = a0 + (a1 - a0) * k / segs
    local rr = r
    if jit > 0 then rr = r + (hash(k % segs + seed * 61, 7) - 0.5) * 2 * jit end
    local x, y = cx + math.cos(a) * rr, cy + math.sin(a) * rr * squash
    if px then line(l, px, py, x, y) end
    px, py = x, y
  end
end

-- a disc of radius r, as one rect per row
local function disc(l, cx, cy, r)
  r = num(r, 0)
  if not (r > 0.3) or r > 200 then return end
  for dy = -math.floor(r), math.floor(r) do
    local hw = math.sqrt(math.max(0, r * r - dy * dy))
    if hw >= 0.5 then put(l, cx - hw, cy + dy, math.max(1, hw * 2), 1) end
  end
end

------------------------------------------------------------------------
-- the machine every theme shares
------------------------------------------------------------------------

local function S_tempo(S)
  local t = num(S.bpm, nil) or num(S.tempo, nil)
  if not t then
    local ok, v = pcall(function() return clock.get_tempo() end)
    t = ok and num(v, 120) or 120
  end
  return clamp(t, 20, 300)
end

local function physics(S)
  local live = heard >= 0 and (NOW - heard) < 1.5
  for k = 1, 4 do
    local to = raw[k]
    if live then
      if k == HI then to = math.max(to, env.hat * 0.35, env.tick * 0.3) end
    else
      local lv = clamp(num(VIS.audio_level, 0), 0, 1)
      if k == AMP then to = math.max(lv, env.kick * 0.6, env.snare * 0.5)
      elseif k == LO then to = math.max(env.kick * 0.9, env.tom * 0.5, lv * 0.5)
      elseif k == MID then to = math.max(env.snare * 0.7, env.clap * 0.6, env.perc * 0.5, env.brk * 0.5, lv * 0.4)
      else to = math.max(env.hat * 0.7, env.ohat * 0.6, env.ride * 0.5, env.shaker * 0.5, env.tick * 0.5, lv * 0.25) end
    end
    A[k] = follow(A[k], to, to > A[k] and RISE[k] or FALL[k], DT)
  end
  local e = clamp(num(S.energy, 0), 0, 1)
  if not energy_seen then energy, energy_seen = e, true end
  local ne = follow(energy, e, 1.5, DT)
  trend = follow(trend, DT > 0 and clamp((ne - energy) / DT * 20, -1, 1) or 0, 3, DT)
  energy = ne
  chaos = follow(chaos, clamp(num(S.chaos, 0), 0, 1), 0.6, DT)
  local kl = S.kickless == true and S.playing ~= false
  kickless = follow(kickless, kl and 1 or 0, 1.5, DT)
  beat_sec = 60 / S_tempo(S)
  local step = num(S.step, 0)
  if step ~= step_seen then step_seen, step_t = step, NOW end
  local sub = clamp((NOW - step_t) / (beat_sec / 4), 0, 0.999)
  local s16 = (step % 16) + sub
  stepf = step + sub
  beat_ph = (s16 % 4) / 4
  bar_ph = s16 / 16
  duck_age = duck_age + DT
  local rec = beat_sec * 0.6
  local ATK = 0.06
  duck = duck_age < ATK and ease(duck_age / ATK) or math.exp(-(duck_age - ATK) / (rec * 0.45))
  for k, v in pairs(env) do env[k] = v * math.exp(-DT / ENV_TAU[k]) end
  local sh = opt("vis_shake", 1)
  -- the jolt steps a pixel a frame toward its depth, so it never jumps
  local sh_to = sh > 1 and math.floor(env.kick * env.kick * (sh == 2 and 1.6 or 3.2) + 0.5) or 0
  if sh_to > shake_dy then shake_dy = shake_dy + 1 elseif sh_to < shake_dy then shake_dy = shake_dy - 1 end
  bar_pulse = follow(bar_pulse, bar_kick, 0.05, DT)
  bar_kick = bar_kick * math.exp(-DT / 0.5)
  local dim_to = (gl_t > 0 and gl_mode == 2) and (0.6 + 0.4 * gl_t / math.max(gl_dur, 0.01)) or 1
  gl_dim = follow(gl_dim, dim_to, 0.15, DT)
  if gl_t > 0 then
    gl_t = math.max(0, gl_t - DT)
    local u = 1 - gl_t / math.max(gl_dur, 0.01)
    local to
    if gl_mode == 1 or gl_mode == 4 then
      local sl = math.floor(u * gl_dur / math.max(0.05, beat_sec / 4))
      if sl ~= gl_slice then gl_slice, gl_cap, hn = sl, true, 0 end
      gl_dx = 0
    else
      if gl_mode == 3 then to = math.floor(gl_dx_abs * math.sin(u * math.pi) + 0.5)
      elseif gl_mode == 2 then to = math.floor(gl_dx_abs * u + 0.5)
      else to = 0 end
      if to > gl_dx then gl_dx = gl_dx + 1 elseif to < gl_dx then gl_dx = gl_dx - 1 end
    end
    gl_sag = 0
    if gl_t == 0 then gl_dx = 0 end
  end
end

-- the echo: S.echo_time / S.echo_fb if the script gives them, else a
-- dotted eighth, with feedback from the dub amount (S.dub) if present
local function echo_params(S)
  local t = num(S.echo_time, nil) or beat_sec * 0.75
  local fb = num(S.echo_fb, nil) or (0.45 + clamp(num(S.dub, 0.5), 0, 1) * 0.35)
  return clamp(t, 0.05, 3), clamp(fb, 0, 0.93)
end

local function sync(S)
  K.T, K.NOW, K.DT, K.DTS, K.SP, K.B = T, NOW, DT, DTS, SP, B
  K.energy, K.chaos, K.trend, K.kickless = energy, chaos, trend, kickless
  K.duck, K.beat_ph, K.bar_ph, K.beat_sec, K.bar_pulse = duck, beat_ph, bar_ph, beat_sec, bar_pulse
  K.echo_t, K.echo_fb = echo_params(S)
  K.swing = clamp(num(S.swing, 0), 0, 1)
  K.glitch = gl_t > 0 and gl_t / math.max(gl_dur, 0.01) or 0
  K.glitch_mode = gl_t > 0 and gl_mode or 0
  K.playing = S.playing ~= false
  K.rat_n, K.rat_voice = rat_n, rat_voice
  K.slice_i, K.slice_n, K.slice_rev = slice_i, slice_n, slice_rev
  K.step = num(S.step, 0)
  K.stepf = stepf
  K.S = S
  K.view = opt("vis_view", 1) == 2 and 2 or 1
end

K.clamp, K.num, K.ease, K.follow, K.rnd, K.hash, K.opt =
  clamp, num, ease, follow, rnd, hash, opt
K.put, K.line, K.profile, K.at, K.mass, K.row_above, K.gradient, K.dashes, K.haze, K.grain =
  put, line, profile, at, mass, row_above, gradient, dashes, haze, grain
K.ring, K.disc = ring, disc

-- a part's gain on the mixer (0 when muted or missing)
K.gain = function(S, part)
  local g = type(S) == "table" and type(S.gain) == "table" and num(S.gain[part], 0) or 0
  return clamp(g, 0, 1)
end

-- seconds since an event last came (99 if never)
K.since = function(name)
  local t = last[name]
  if not t then return 99 end
  return NOW - t
end

sync({})

-- the fallback scene: a floor line breathing with the kick, a slow haze
local FALLBACK = {draw = function()
  local e, d = energy, duck
  local hy = math.floor(40 - e * 6)
  for r = 0, 5 do put(1 + (5 - r) * 0.4, 0, hy + 2 + r * 4, 128, 2) end
  line(5 + e * 5 - d * 3, 0, hy, 127, hy)
  for i = 1, 4 do
    local x = 16 + (i - 1) * 32 + math.sin(T * 0.3 + i) * 4
    put(3 + env.snare * 6 + A[HI] * 4, x, 12 + i * 3, 2, 2)
  end
  put(4 + env.kick * 8 + A[LO] * 2, 62, hy - 1, 4, 1)
end}

local function log_once(i, what, err)
  if logged[i] then return end
  logged[i] = true
  print("breakage visuals: theme " .. tostring(VIS.names[i] or i) .. " " .. what .. ": " .. tostring(err))
end

for i, name in ipairs(VIS.names) do
  local ok, th = pcall(function() return include("lib/vis/" .. name)(K) end)
  if ok and type(th) == "table" and type(th.draw) == "function" then
    THEMES[i] = th
  else
    THEMES[i] = FALLBACK
    log_once(i, "did not load", ok and "no draw function" or th)
  end
end

local function call(i, fname, ...)
  local th = THEMES[i]
  local f = th and not broken[i] and th[fname]
  if type(f) ~= "function" then return false end
  local ok, err = pcall(f, ...)
  if not ok then
    broken[i] = true
    log_once(i, "failed in " .. fname, err)
  end
  return ok
end

------------------------------------------------------------------------
-- dispatch
------------------------------------------------------------------------

function VIS.init()
  for i = #grains, 1, -1 do grains[i] = nil end
  for i = #hist, 1, -1 do hist[i] = nil end
  for k in pairs(last) do last[k] = nil end
  grain_acc = 0
  for k in pairs(env) do env[k] = 0 end
  for k = 1, 4 do raw[k], A[k] = 0, 0 end
  heard = -1
  energy, chaos, trend, kickless, energy_seen = 0, 0, 0, 0, false
  duck, duck_age, beat_ph, bar_ph, beat_sec = 0, 99, 0, 0, 0.5
  step_seen, step_t, bar_kick, bar_pulse = -1, 0, 0, 0
  stepf = 0
  rat_n, rat_voice = 0, nil
  slice_i, slice_n, slice_rev, tick_odd = 0, 8, false, false
  shake_dy = 0
  T, NOW, last_clock = 0, 0, nil
  cur, xf = nil, 0
  rseed = 1
  gl_t, gl_dur, gl_mode, gl_dx, gl_dx_abs, gl_sag = 0, 0, 0, 0, 0, 0
  gl_slice, gl_cap, hn = -1, false, 0
  gl_dim = 1
  ops = 0
  discard()
  for i = 1, #THEMES do
    broken[i] = nil
    local th = THEMES[i]
    if th.init then call(i, "init") elseif th.clear then call(i, "clear") end
  end
end

function VIS.audio(name, v)
  local i = A_IDX[name]
  if not i then return end
  if type(v) ~= "number" or v ~= v then v = 0 end
  raw[i] = clamp(v, 0, 1)
  heard = NOW
end

local function vel(v) return clamp(num(v, 1), 0, 1) end
local function hit(name, v)
  env[name] = math.max(env[name] or 0, 0.3 + 0.7 * v)
  last[name] = NOW
end

-- the drum hits, with their fallbacks when a theme has no handler
local deliver
deliver = function(i, kind, v, a, b, c)
  local th = THEMES[i]
  if kind == "kick" then return call(i, "kick", v) end
  if kind == "snare" then return call(i, "snare", v, a) end
  if kind == "hat" then return call(i, "hat", v, a) end
  if th[kind] then
    if kind == "tom" or kind == "perc" or kind == "brk" or kind == "tick" then return call(i, kind, a, b, c) end
    return call(i, kind, v)
  end
  if kind == "clap" then return deliver(i, "snare", v, 1) end
  if kind == "rim" or kind == "ride" or kind == "shaker" then return deliver(i, "hat", v, kind == "ride") end
  if kind == "tom" then return deliver(i, "perc", v, 1, v) end
  if kind == "perc" then return deliver(i, "hat", v, false) end
  if kind == "brk" then return deliver(i, "tick", 1, 1) end
  if kind == "tick" then
    tick_odd = not tick_odd
    if tick_odd then return deliver(i, "hat", 0.5, false) end
  end
  return false
end

function VIS.event(kind, a, b, c)
  if type(kind) ~= "string" then return end
  local i = cur
  if kind == "kick" then
    local v = vel(a)
    hit("kick", v)
    duck_age = 0
    if i then call(i, "kick", v) end
  elseif kind == "snare" then
    local v = vel(a)
    local n = clamp(math.floor(num(b, 1)), 1, 16)
    hit("snare", v)
    if i then deliver(i, "snare", v, n) end
  elseif kind == "clap" or kind == "rim" or kind == "ride" or kind == "shaker" then
    local v = vel(a)
    hit(kind, v)
    if i then deliver(i, kind, v) end
  elseif kind == "hat" then
    local v = vel(a)
    local open = b == true
    hit(open and "ohat" or "hat", v)
    last.hat = NOW
    if i then deliver(i, "hat", v, open) end
  elseif kind == "tom" then
    local v = vel(a)
    local hz = clamp(num(b, 120), 20, 2000)
    hit("tom", v)
    if i then deliver(i, "tom", v, v, hz) end
  elseif kind == "perc" then
    local k = clamp(math.floor(num(a, 1)), 1, 10)
    local v = vel(b)
    hit("perc", v)
    if k == 5 then hit("acid", v) end
    if i then deliver(i, "perc", v, k, v) end
  elseif kind == "tick" then
    local k = clamp(math.floor(num(a, 1)), 1, 6)
    hit("tick", 0.7)
    if i then deliver(i, "tick", 0.7, k) end
  elseif kind == "brk" then
    local n = clamp(math.floor(num(b, 8)), 1, 64)
    local s = clamp(math.floor(num(a, 1)), 1, n)
    local rev = c == true
    slice_i, slice_n, slice_rev = s, n, rev
    hit("brk", 0.8)
    if i then deliver(i, "brk", 0.8, s, n, rev) end
  elseif kind == "ratchet" then
    local n = clamp(math.floor(num(a, 2)), 1, 16)
    rat_n, rat_voice = n, type(b) == "string" and b or nil
    hit("ratchet", clamp(n / 8, 0.2, 1))
    if i then call(i, "ratchet", n, rat_voice) end
  elseif kind == "fill" then
    hit("fill", 1)
    if i then call(i, "fill", type(a) == "string" and a or "fill") end
  elseif kind == "glitch" then
    local mode = clamp(math.floor(num(a, 1)), 1, 5)
    local dur = clamp(num(b, 0.25), 0.02, 1.5)
    gl_mode, gl_dur, gl_t = mode, dur, dur
    local h = 4 + math.floor(rnd() * 6)
    gl_y0 = math.floor(rnd() * (64 - h))
    gl_y1 = gl_y0 + h
    gl_dx_abs = (2 + math.floor(rnd() * 3)) * (rnd() < 0.5 and -1 or 1)
    gl_dx = 0
    gl_slice, gl_cap, hn = -1, false, 0
    gl_sag = 0
  elseif kind == "bar" then
    local S = type(a) == "table" and a or {}
    bar_kick = 1
    hist[#hist + 1] = {e = clamp(num(S.energy, 0), 0, 1), c = clamp(num(S.chaos, 0), 0, 1),
      kl = S.kickless == true}
    if #hist > HIST_N then table.remove(hist, 1) end
    if i then call(i, "bar", S) end
  end
  -- anything else ("kit", unknown names) is ignored
end

local function frame_dt(dt)
  if dt == nil then
    local now = util and util.time and util.time()
    if type(now) == "number" and last_clock then dt = now - last_clock else dt = 1 / FPS end
    last_clock = now
  end
  if type(dt) ~= "number" or dt ~= dt then dt = 1 / FPS end
  return clamp(dt, 0, 0.25)
end

-- draw theme i. dt (s) is optional: on the norns it comes from the clock
function VIS.draw(i, S, dt)
  i = math.floor(num(i, 1))
  if not THEMES[i] then i = clamp(i, 1, #THEMES) end
  if type(S) ~= "table" then S = {} end
  DT = frame_dt(dt)
  SP = clamp(opt("vis_speed", 3) / 3, 0.1, 5)
  DTS = DT * SP
  NOW = NOW + DT
  T = T + DTS
  local ok, err = pcall(physics, S)
  if not ok then log_once(0, "kit physics", err) end
  if cur == nil then cur = i end
  if i ~= cur then
    xf = xf - DT / 0.25
    if xf <= 0 then
      local old = THEMES[cur]
      if old.clear then call(cur, "clear") elseif old.init then call(cur, "init") end
      for k = #grains, 1, -1 do grains[k] = nil end
      xf, cur = 0, i
      broken[cur] = nil
    end
  else
    xf = math.min(1, xf + DT / 0.5)
  end
  B = opt("vis_brightness", 10) / 10 * ease(xf)
  B = B * gl_dim
  sync(S)
  ops = 0
  if broken[cur] or not call(cur, "draw", S) then
    discard()
    ops = 0
    FALLBACK.draw()
  end
  flush()
end

return VIS
