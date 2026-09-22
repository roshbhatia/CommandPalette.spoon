local root = hs.spoons.scriptPath():gsub("/+$", "")
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

local obj = {
  name = "CommandPalette",
  version = "0.1.0",
  author = "Roshan Bhatia",
  homepage = "https://github.com/roshbhatia/CommandPalette.spoon",
  license = "MIT",
}
local core
local mapping = {}
local hotkeys = {}
local config = {}

function obj:configure(value)
  assert(not core, "stop CommandPalette before configuring it")
  config = value or {}
  return self
end

function obj:bindHotkeys(value)
  mapping = value or {}
  for _, key in ipairs(hotkeys) do
    key:delete()
  end
  hotkeys = {}
  if core and mapping.toggle then
    local chord = mapping.toggle
    hotkeys[1] = hs.hotkey.bind(chord[1], chord[2], function()
      self:toggle()
    end)
  end
  return self
end

function obj:start()
  if core then
    return self
  end
  for name in pairs(package.loaded) do
    if name == "command_palette" or name:match("^command_palette%.") then
      package.loaded[name] = nil
    end
  end
  local options = require("command_palette.options")
  options.root = root
  options.config = {}
  for key, value in pairs(config) do
    options.config[key] = value
  end
  options.config.stateDir = config.stateDir or (hs.configdir .. "/CommandPalette-state")
  options.config.appDirs = config.appDirs
    or { "/Applications", "/System/Applications", os.getenv("HOME") .. "/Applications" }
  core = require("command_palette")
  core.setup()
  self:bindHotkeys(mapping)
  return self
end

function obj:stop()
  if core then
    core.stop()
  end
  core = nil
  for _, key in ipairs(hotkeys) do
    key:delete()
  end
  hotkeys = {}
  return self
end

function obj:toggle()
  if core then
    core.toggle()
  end
  return self
end

---@param spec table
---@param callback fun(row: table|nil, mods: table|nil)
function obj:pick(spec, callback)
  assert(core, "start CommandPalette before picking with it")
  core.pick(spec, callback)
  return self
end

return obj
