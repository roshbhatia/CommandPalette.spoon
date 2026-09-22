local root = assert(arg[1], "hammerspoon root is required")

package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
package.preload["command_palette.fzf"] = function()
  return {
    ensure = function() end,
    index_path = function(name)
      return "/tmp/palette-panel-test/" .. name
    end,
    write_index = function() end,
    filter = function() end,
  }
end
package.preload["sysinit.pkg.utils.json_loader"] = function()
  return {
    load_json_file = function()
      return nil
    end,
    get_config_path = function()
      return ""
    end,
  }
end

local callback = nil
local scripts = {}
local view = { visible = false }
local alerts = {}
local bindings = {}
local copied = {}
local tasks = {}

function view:windowStyle()
  return self
end

function view:allowTextEntry()
  return self
end

function view:transparent()
  return self
end

function view:level()
  return self
end

function view:shadow()
  return self
end

function view:html()
  return self
end

function view:frame(rect)
  if rect == nil then
    return self.rect or { x = 0, y = 0, w = 920, h = 400 }
  end
  self.rect = rect
  return self
end

function view:isVisible()
  return self.visible
end

function view:show()
  self.visible = true
  return self
end

function view:hide()
  self.visible = false
  return self
end

function view:evaluateJavaScript(script)
  scripts[#scripts + 1] = script
  return self
end

local screen = {
  frame = function()
    return { x = 0, y = 0, w = 1440, h = 900 }
  end,
}

_G.hs = {
  alert = {
    show = function(message)
      alerts[#alerts + 1] = message
    end,
  },
  configdir = root,
  drawing = { windowLevels = { modalPanel = 1 } },
  fs = {
    attributes = function()
      return nil
    end,
  },
  hotkey = {
    bind = function(mods, key, work)
      bindings[key] = { mods = mods, work = work }
    end,
  },
  image = {
    imageFromPath = function(path)
      return { path = path }
    end,
  },
  json = {
    encode = function()
      return "[]"
    end,
  },
  mouse = {
    getCurrentScreen = function()
      return screen
    end,
  },
  pasteboard = {
    writeObjects = function(images)
      copied = images
      return true
    end,
  },
  screen = {
    allScreens = function()
      return { screen, screen }
    end,
    mainScreen = function()
      return screen
    end,
    watcher = {
      new = function()
        return { start = function() end }
      end,
    },
  },
  timer = {
    doAfter = function()
      return { stop = function() end }
    end,
  },
  eventtap = {
    event = { types = { leftMouseDown = 1 } },
    new = function()
      return {
        start = function(self)
          return self
        end,
        stop = function(self)
          return self
        end,
      }
    end,
  },
  task = {
    new = function(tool, callback_work, args)
      local task = { tool = tool, args = args, started = false }
      function task:start()
        self.started = true
        callback_work(0, "", "")
      end
      tasks[#tasks + 1] = task
      return task
    end,
  },
  webview = {
    usercontent = {
      new = function()
        return {
          setCallback = function(_, work)
            callback = work
          end,
        }
      end,
    },
    new = function()
      return view
    end,
  },
}

local options = require("command_palette.options")
options.root = root
local panel = require("command_palette.panel")
panel.prewarm()
-- The dataset goes into the page as the text it is on disk, so anything that is
-- not a JSON array is dropped rather than pasted in as script.
panel.emoji("")
panel.emoji("<!doctype html>")
panel.emoji('[{"cp":"x","code":"x"}]')
panel.shell_commands({ "git" })

assert(callback ~= nil, "launcher callback was not registered")
callback({ body = { action = "loaded" } })

local emoji_sent = 0
local saw_commands = false
for _, script in ipairs(scripts) do
  if script:match("^setEmoji%(") then
    emoji_sent = emoji_sent + 1
  end
  saw_commands = saw_commands or script:match("^setCommands%(") ~= nil
end

assert(emoji_sent == 1, "emoji initialization was dropped, or a non-JSON dataset reached the page")
assert(saw_commands, "shell command initialization was dropped before page load")

-- A transient list learns that it lost the panel, which is what lets a pick
-- report a cancel instead of leaving its caller waiting.
local cancels = 0
panel.show({
  name = "pick",
  rows = { { text = "one" } },
  placeholder = "Which",
  closed = function()
    cancels = cancels + 1
  end,
})
assert(panel.visible(), "show left the panel hidden")
callback({ body = { action = "close" } })
assert(cancels == 1, "the page closing the panel never reached the list")
callback({ body = { action = "close" } })
assert(cancels == 1, "an already closed panel reported closing again")

print("panel tests passed")
