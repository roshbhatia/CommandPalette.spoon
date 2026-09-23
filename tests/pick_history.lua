local root = assert(arg[1])
package.path = root .. "/?.lua;" .. package.path
local saved = {}
hs = {
  settings = {
    get = function(key)
      return saved[key]
    end,
    set = function(key, value)
      saved[key] = value
    end,
  },
}
local history = require("command_palette.pick_history")
local now = 10000000
os.time = function()
  return now
end
local rows = { { text = "gh dash" }, { text = "Firefox" }, { text = "Neovim (Octo)" } }
assert(history.sort("pull", rows)[1] == rows[1])
history.touch("pull", rows[2])
history.touch("pull", rows[2])
assert(history.sort("pull", rows)[1] == rows[2])
assert(history.sort("actions", rows)[1] == rows[1])
now = now + 21 * 24 * 60 * 60
history.touch("pull", rows[3])
assert(history.sort("pull", rows)[1] == rows[3])
history.touch("pull", nil)
assert(history.sort("pull", rows)[1] == rows[3])
assert(rows[1].text == "gh dash")
package.loaded["command_palette.pick_history"] = nil
assert(require("command_palette.pick_history").sort("pull", rows)[1] == rows[3])
saved["CommandPalette.pick.broken"] = "invalid"
assert(history.sort("broken", rows)[1] == rows[1])
print("Picker frecency: stable ties, frequency, decay, isolation, cancellation, and persistence passed")
