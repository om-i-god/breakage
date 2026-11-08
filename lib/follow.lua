-- breakage / follow
-- listens to gradient over MIDI. gradient's CC OUT sends, once a bar on one
-- channel: its energy, its dub amount, a phrase pulse (127 on the first bar
-- of each phrase, 0 on the others: every bar, so it doubles as a heartbeat)
-- and, from gradient v0.2, a kickless flag (127 while its kick is out), and
-- its key: key root and chord root (0-11, C = 0) and mode (gradient's KEY >
-- mode number, the same list as breakage's SOUND > scale).
-- its SYNC OUT sends start / stop on its bar one.
--
-- following is automatic: any of these CCs arriving puts breakage in
-- follow; four bars with nothing (or gradient stopping) drops it back to
-- its own arc, which carries on from wherever the energy was.

local F = {}

local dev
local S
local hooks = {}
local last_pulse_bar

local TIMEOUT = 4    -- bars without a CC before going solo
F.N_MODES = 12       -- set by the main script to its scale count

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

-- the step the main loop is on, so a pulse can be placed on the right bar:
-- in the first half of a bar it marks this bar, in the second the next
F.step_in_bar = function() return nil end

local function on_pulse()
  -- the last step played (nil before the first). S.bar was bumped when the
  -- running bar began, so the running bar is S.bar - 1; a pulse late in a
  -- bar, or before we've played, belongs to the next one
  local s = F.step_in_bar()
  local edge = (s and s < 8) and S.bar - 1 or S.bar
  -- learn gradient's phrase length from the spacing of its pulses
  if last_pulse_bar then
    local idx = ({[8] = 1, [16] = 2, [32] = 3, [64] = 4})[edge - last_pulse_bar]
    if idx and params:get("phrase_len") ~= idx then params:set("phrase_len", idx) end
  end
  last_pulse_bar = edge
  local moved = (S.phrase_anchor or 0) % (S.phrase_len or 16) ~= edge % (S.phrase_len or 16)
  S.phrase_anchor = edge
  -- the pulse came in just after this bar started: run the phrase edge late
  if moved and s and s < 8 and hooks.late_phrase then hooks.late_phrase() end
end

local function seen()
  S.f_last_bar = S.bar
  if not S.following and params:get("follow") == 1 then
    S.following = true
    if hooks.changed then hooks.changed(true) end
  end
end

local function event(data)
  local m = midi.to_msg(data)
  if not m then return end
  if m.type == "start" then
    if params:get("follow_transport") == 2 and hooks.start then hooks.start() end
    return
  elseif m.type == "stop" then
    if params:get("follow_transport") == 2 and hooks.stop then hooks.stop() end
    return
  end
  if m.type == "note_on" and m.vel > 0 then
    local nch = params:get("follow_note_ch")
    if nch > 1 and m.ch == nch - 1 and params:get("root") ~= m.note % 12 + 1 then
      params:set("root", m.note % 12 + 1)
    end
    return
  end
  if m.type ~= "cc" or m.ch ~= params:get("follow_ch") or params:get("follow") ~= 1 then return end
  local v = m.val / 127
  if m.cc == params:get("follow_energy_cc") then
    S.f_energy = v
    seen()
  elseif m.cc == params:get("follow_dub_cc") then
    S.f_dub = v
    seen()
  elseif m.cc == params:get("follow_phrase_cc") then
    seen()
    if m.val >= 64 then on_pulse() end
  elseif m.cc == params:get("follow_kickless_cc") then
    S.f_kickless = m.val >= 64
    seen()
  elseif m.cc == params:get("follow_key_cc") then
    seen()
    -- the key lands in breakage's own key param, so it stays put when
    -- gradient goes quiet
    local pc = m.val % 12
    if params:get("follow_key") > 1 and params:get("root") ~= pc + 1 then params:set("root", pc + 1) end
  elseif m.cc == params:get("follow_mode_cc") then
    seen()
    local md = math.max(1, math.min(F.N_MODES, m.val))
    if params:get("follow_key") > 1 and params:get("scale") ~= md then params:set("scale", md) end
  elseif m.cc == params:get("follow_chord_cc") then
    seen()
    S.f_chord = m.val % 12
  end
end

-- once a bar from the conductor's side: has gradient gone quiet?
function F.bar()
  if S.following and (params:get("follow") ~= 1 or S.bar - (S.f_last_bar or -99) > TIMEOUT) then
    S.following = false
    S.f_kickless = false
    S.f_chord = nil
    if hooks.changed then hooks.changed(false) end
  end
end

function F.connect(id)
  if dev then dev.event = nil end
  dev = (id and id > 0) and midi.connect(id) or nil
  if dev then dev.event = event end
end

function F.init(state, h)
  S, hooks = state, h or {}
end

-- for tests: feed raw midi bytes
F._event = function(data) event(data) end

return F
