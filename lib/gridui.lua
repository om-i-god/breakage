-- breakage / grid
-- a 16x8 performance surface. reads state, acts through the table the main
-- script hands in (A).
--
-- row 1   phrase position (8-bar blocks marked); a fill coming lights the end
-- row 2   energy: lit to the level; press to pull it there
-- row 3   chaos: lit to the level; press to set it
-- row 4   kits 1-8 (pending kit blinks)
-- row 5   parts K S C H R P T G B: brightness = how loud; press = mute
-- row 6   break pads: the 16 slices of the current bar of the loop; press to
--         fire one (lit when a break is loaded)
-- row 7   playhead: the 16ths of the bar; the micro-edit's beat shows dim
-- row 8   1 drop  2 fill  3 mutate  4 strip  5 throw
--         7 break down  8 build  10 stutter  11 tape stop  12 reverse
--         16 play/stop

local GU = {}

GU.PARTS = {"kick", "snare", "clap", "hats", "ride", "perc", "toms", "ticks", "brk"}

local g, A
local flash = {}

function GU.init(actions)
  A = actions
  g = grid.connect()
  g.key = function(x, y, z) GU.key(x, y, z) end
end

local function cols() return (g and g.cols and g.cols > 0) and g.cols or 16 end

function GU.key(x, y, z)
  if z == 0 then return end
  local S = A.S
  flash[x .. "," .. y] = util.time()
  local w = cols()
  if y == 2 then
    A.set_energy((x - 1) / (w - 1))
  elseif y == 3 then
    A.set_chaos((x - 1) / (w - 1))
  elseif y == 4 then
    if x <= 8 then A.set_kit(x) end
  elseif y == 5 then
    local k = GU.PARTS[x]
    if k then A.toggle_mute(k) end
  elseif y == 6 then
    if S.brk_ready then A.pad((S.tstep - (S.tstep % 16)) + (x - 1)) end
  elseif y == 8 then
    local act = ({[1] = "drop", [2] = "fill", [3] = "mutate", [4] = "strip", [5] = "throw",
      [7] = "brk_down", [8] = "build", [10] = "stutter", [11] = "tapestop", [12] = "reverse",
      [16] = "play"})[x]
    if act then A[act]() end
  end
end

function GU.redraw()
  if not g then return end
  local S = A.S
  local now = util.time()
  local w = cols()
  g:all(0)

  -- phrase
  local P = S.phrase_len or 16
  local pos = S.phrase_pos or 0
  for x = 1, w do
    local b = math.floor((x - 1) * P / w)
    local lvl = (b % 8 == 0) and 3 or 1
    if b <= pos then lvl = 6 end
    if b == pos then lvl = 12 end
    g:led(x, 1, lvl)
  end
  if S.fill then g:led(w, 1, 15) end

  -- energy, chaos
  local en = math.floor((S.energy or 0) * (w - 1) + 0.5) + 1
  local ch = math.floor((S.chaos or 0) * (w - 1) + 0.5) + 1
  for x = 1, w do
    g:led(x, 2, x <= en and (x == en and 12 or 5) or 0)
    g:led(x, 3, x <= ch and (x == ch and 15 or 4) or 0)
  end

  -- kits
  local blink = math.floor(now * 4) % 2 == 0
  for x = 1, 8 do
    local lvl = 2
    if x == S.kit then lvl = 13 end
    if x == S.kit_pending then lvl = blink and 15 or 4 end
    g:led(x, 4, lvl)
  end

  -- parts
  for x, k in ipairs(GU.PARTS) do
    local lvl
    if S.mute[k] then lvl = 1
    elseif k == "brk" and not S.brk_ready then lvl = 0
    else lvl = math.floor(3 + (S.gain[k] or 0) * 10) end
    g:led(x, 5, lvl)
  end

  -- break pads + playhead
  local s = (S.tstep or 0) % 16
  for x = 1, math.min(16, w) do
    if S.brk_ready then g:led(x, 6, (x - 1 == s) and 10 or 3) end
    local lvl = (x - 1 == s and S.playing) and 12 or ((x - 1) % 4 == 0 and 3 or 1)
    if S.edit and (x - 1) // 4 + 1 == S.edit.beat then lvl = math.max(lvl, 6) end
    g:led(x, 7, lvl)
  end

  -- actions
  for _, x in ipairs({1, 2, 3, 4, 5, 7, 8, 10, 11, 12, 16}) do
    local lvl = 4
    if x == 1 and S.drop_bars > 0 then lvl = 12 end
    if x == 4 and S.strip_bars > 0 then lvl = 12 end
    if x == 16 and S.playing then lvl = 12 end
    g:led(x, 8, lvl)
  end

  -- press blink
  for k, t in pairs(flash) do
    if now - t < 0.12 then
      local x, y = k:match("(%d+),(%d+)")
      g:led(tonumber(x), tonumber(y), 15)
    else
      flash[k] = nil
    end
  end
  g:refresh()
end

return GU
