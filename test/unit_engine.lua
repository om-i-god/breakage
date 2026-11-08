-- static checks on the SuperCollider engine for things a Mac test run
-- can't catch because they only go wrong on the norns' ARM build, plus the
-- engine <-> design.md contract

local function read(p)
  local f = assert(io.open(p))
  local s = f:read("a"); f:close()
  return s
end
local function source() return read("lib/Engine_Breakage.sc") end

-- norns' sqrt returns NaN for 0 and denormals; one NaN freezes the master's
-- Amplitude followers for good. every sqrt must clamp its input first
test("engine: every sqrt is clamped away from zero", function()
  local n = 0
  for line in source():gmatch("[^\n]+") do
    if not line:match("^%s*//") and line:find("%.sqrt") then
      n = n + 1
      assert(line:find("%.max%([%d%.e%-]+%)%.sqrt"), "unguarded sqrt: " .. line)
    end
  end
  assert(n > 0, "expected the glitch crush sqrt")
end)

test("engine: master sanitizes both inputs", function()
  local m = source():match("SynthDef%(\\brk_master.-%}%)%.add")
  assert(m, "brk_master not found")
  local _, c = m:gsub("Sanitize%.ar%(In%.ar", "")
  assert(c == 2, "expected Sanitize on dry and main inputs, found " .. c)
end)

test("engine: no SC2-era Mix.ar", function()
  assert(not source():find("Mix%.ar%("), "use Mix(...), not the SC2 array form")
end)

test("engine: every SynthDef is brk_-prefixed", function()
  for name in source():gmatch("SynthDef%(%(?\"?\\?([%w_]+)") do
    assert(name:match("^brk_"), "SynthDef not brk_-prefixed: " .. name)
  end
end)

-- `t_foo` is a trigger arg that sclang exposes as `foo`; a second arg named
-- `foo` makes the SynthDef fail silently
test("engine: no SynthDef has both t_x and x args", function()
  local n = 0
  for body in source():gmatch("SynthDef%((.-)%}%)%.add") do
    local args = body:match("arg%s+(.-);")
    if args then
      n = n + 1
      local names = {}
      for a in args:gmatch("([%a_][%w_]*)%s*[=,]?") do names[a] = true end
      for a in pairs(names) do
        local base = a:match("^t_(.+)")
        assert(not (base and names[base]), "SynthDef has both " .. a .. " and " .. tostring(base))
      end
    end
  end
  assert(n > 20, "expected to find the SynthDefs' arg lists, found " .. n)
end)

-- the design table: | name | args | notes |, between the Engine interface
-- heading and the tweak keys
local function design()
  local d = read("docs/design.md")
  local sec = assert(d:match("## Engine interface.-\n(.-)\nTweak keys"), "engine section not found")
  local cmds = {}
  for name, args in sec:gmatch("\n| ([%w_]+) | ([^|]*) |") do
    if name ~= "command" then
      local fmt
      if name == "break_load" then fmt = "s"
      elseif name == "tweak" then fmt = "sf"
      else
        local stripped = args:gsub("%b()", "")
        local n = 0
        for _ in stripped:gmatch("[%w_]+") do n = n + 1 end
        fmt = string.rep("f", n)
      end
      cmds[name] = fmt
    end
  end
  local keys = {}
  local tk = assert(d:match("Tweak keys(.-)\nRouting:"), "tweak keys not found")
  for span in tk:gmatch("`([^`]+)`") do
    for k in span:gmatch("[%w_]+") do keys[#keys + 1] = k end
  end
  return cmds, keys
end

test("engine: every command matches the design table's format", function()
  local want = design()
  local have = {}
  for name, fmt in source():gmatch("addCommand%(\\([%w_]+), \"(%a*)\"") do have[name] = fmt end
  local n = 0
  for name, fmt in pairs(want) do
    n = n + 1
    assert(have[name], "missing command: " .. name)
    assert(have[name] == fmt, name .. ": format " .. have[name] .. ", design says " .. fmt)
  end
  for name in pairs(have) do assert(want[name], "command not in design: " .. name) end
  assert(n == 14, "expected 14 design commands, parsed " .. n)
end)

test("engine: every design tweak key exists", function()
  local _, keys = design()
  local src = source()
  local have = {}
  for k in src:gmatch("\\([%w_]+) %->") do have[k] = true end
  assert(#keys >= 40, "parsed only " .. #keys .. " tweak keys")
  for _, k in ipairs(keys) do assert(have[k], "tweak key missing: " .. k) end
end)
