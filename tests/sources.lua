local root = assert(arg[1])
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
local resources, last, clips = {}, nil, 0
local shown, hidden = nil, 0
local function resource()
  local item = { stopped = false }
  function item:stop()
    self.stopped = true
  end
  function item:start()
    return self
  end
  resources[#resources + 1] = item
  return item
end
hs = {
  configdir = "/tmp/palette-sources-test",
  spoons = {
    scriptPath = function()
      return root
    end,
  },
  fs = {
    mkdir = function() end,
    attributes = function()
      return nil
    end,
  },
  caffeinate = {
    get = function()
      return false
    end,
  },
  timer = { doAfter = resource, doEvery = resource },
  pasteboard = { watcher = {
    new = function()
      clips = clips + 1
      return resource()
    end,
  } },
}
package.preload["command_palette.panel"] = function()
  return {
    prewarm = function() end,
    emoji = function() end,
    status = function() end,
    stage = function(value)
      last = value
    end,
    show = function(value)
      shown = value
    end,
    hide = function()
      hidden = hidden + 1
    end,
    visible = function()
      return false
    end,
    stop = function() end,
  }
end
local spoon = dofile(root .. "/init.lua")
spoon:configure({ appDirs = {}, stateDir = "/tmp/palette-sources-test" }):start()
assert(#resources == 5 and clips == 0, "default source lifecycle changed")
for _, action in ipairs(last.actions) do
  assert(action.name ~= "clipboard" and action.name ~= "screenshot", "disabled source exposed an action")
end
spoon:stop()
for _, item in ipairs(resources) do
  assert(item.stopped, "source survived stop")
end
spoon:configure({ appDirs = {}, clipboard = true, screenshots = {} }):start()
assert(clips == 1, "restart did not use new source configuration")
local found = {}
for _, action in ipairs(last.actions) do
  found[action.name] = true
end
assert(found.clipboard and found.screenshot)
spoon:stop()
for _, item in ipairs(resources) do
  assert(item.stopped)
end
spoon:configure({ appDirs = {}, stateDir = "/tmp/palette-sources-test" }):start()
local calls, picked = 0, nil
local function record(row)
  calls = calls + 1
  picked = row
end

spoon:pick({ rows = { { text = "one" }, { text = "two" } }, placeholder = "Which", verb = "Review" }, record)
assert(shown ~= nil and #shown.rows == 2, "pick did not show its own rows")
assert(shown.placeholder == "Which", "pick dropped its placeholder")
assert(shown.hints[1][2] == "Review" and shown.hints[2][2] == "Cancel", "pick hints ignored the verb")

last = nil
shown.choose(shown.rows[2], {})
assert(hidden == 1, "a chosen pick left the panel up")
assert(calls == 1 and picked.text == "two", "pick reported the wrong row")
assert(last ~= nil and last.name == "base", "pick left its own list staged")
shown.closed()
assert(calls == 1, "a chosen pick also reported a cancel")

spoon:pick({ rows = { { text = "one" } } }, record)
last = nil
shown.closed()
assert(calls == 2 and picked == nil, "a dismissed pick did not report a cancel")
assert(last ~= nil and last.name == "base", "a dismissed pick left its own list staged")
spoon:stop()

local history, writes = {}, 0
hs.settings = {
  get = function(key)
    return history[key]
  end,
  set = function(key, value)
    history[key] = value
    writes = writes + 1
  end,
}
spoon:start()
local spec =
  { rows = { { text = "one", target = 1 }, { text = "two", target = 2 } }, historyKey = "pull", showStatus = false }
spoon:pick(spec, record)
assert(shown.showStatus == false)
shown.choose(shown.rows[2], {})
spoon:pick(spec, record)
assert(shown.rows[1].target == 2, "ranked choice lost its original target")
shown.closed()
assert(writes == 1, "dismissal changed history")
spoon:stop()
print("source tests passed")
