local root = assert(arg[1])
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
local started, stopped, toggled, bound, deleted = 0, 0, 0, 0, 0
hs = {
  configdir = "/tmp/palette-test",
  spoons = {
    scriptPath = function()
      return root
    end,
  },
  hotkey = {
    bind = function()
      bound = bound + 1
      return {
        delete = function()
          deleted = deleted + 1
        end,
      }
    end,
  },
}
package.preload.command_palette = function()
  return {
    setup = function()
      started = started + 1
    end,
    stop = function()
      stopped = stopped + 1
    end,
    toggle = function()
      toggled = toggled + 1
    end,
  }
end
local spoon = dofile(root .. "/init.lua")
assert(started == 0 and bound == 0, "loading must not start sources or bind keys")
spoon:configure({ clipboard = false }):bindHotkeys({ toggle = { { "cmd" }, "space" } })
assert(bound == 0)
spoon:start():start():toggle()
assert(started == 1 and bound == 1 and toggled == 1)
spoon:stop():stop():toggle()
assert(stopped == 1 and deleted == 1 and toggled == 1)
spoon:start():stop()
assert(started == 2 and stopped == 2 and bound == deleted)
local callbacks, terminated, results = {}, 0, 0
hs.task = {
  new = function(_, callback)
    callbacks[#callbacks + 1] = callback
    return {
      terminate = function()
        terminated = terminated + 1
      end,
    }
  end,
}
local tasks = require("command_palette.tasks")
tasks.new("test", function()
  results = results + 1
end, {})
tasks.stop()
callbacks[1](0, "late")
assert(terminated == 1 and results == 0, "stopped tasks must not deliver late results")
tasks.new("test", function()
  results = results + 1
end, {})
callbacks[2](0, "current")
tasks.stop()
assert(results == 1 and terminated == 1)
print("lifecycle tests passed")
