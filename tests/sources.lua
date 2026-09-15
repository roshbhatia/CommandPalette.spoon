local root = assert(arg[1])
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
local resources, last, clips = {}, nil, 0
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
print("source tests passed")
