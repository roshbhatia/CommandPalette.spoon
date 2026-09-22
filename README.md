# CommandPalette.spoon

A Hammerspoon command palette with application search, actions, and optional sources.

Install this repository as `~/.hammerspoon/Spoons/CommandPalette.spoon`, then add:

```lua
hs.loadSpoon("CommandPalette")
spoon.CommandPalette
  :configure({})
  :bindHotkeys({ toggle = { { "cmd" }, "space" } })
  :start()
```

Loading the Spoon does not start sources or bind keys. `start()` and `stop()` are idempotent.
Stop before changing configuration. Stopping removes owned hotkeys, timers, watchers, tasks, and the webview.

## Picking from your own list

`pick` shows a transient list in the panel instead of the base list and reports the chosen row.
Use it to reuse the palette for a prompt of your own.

```lua
spoon.CommandPalette:pick({
  placeholder = "owner/repo#123",
  verb = "Review",
  rows = {
    { text = "gh dash", detail = "Dashboard, checks, and review actions", label = "Review", glyph = "command" },
    { text = "Firefox", detail = "Open on github.com", label = "Review", glyph = "command" },
  },
}, function(row)
  if row == nil then
    return -- dismissed; open nothing
  end
  hs.alert.show(row.text)
end)
```

The callback gets the chosen row and the held modifiers, or `nil` when the panel is dismissed,
so a caller that opens something on a pick opens nothing on an escape. The base list is put back
under the panel either way. `pick` requires a started Spoon.

## Optional sources

Pass these keys to `configure`. External command values are executable paths.

| Key | Source |
| --- | --- |
| `appDirs`, `appExcludes` | Application directories and excluded bundle names |
| `clipboard = true` | In-memory clipboard history; disabled by default |
| `wezterm` | WezTerm panes |
| `sy` | Seshy sessions |
| `fftabs`, `firefoxProfileRoot` | Firefox tabs and profile watcher |
| `fd`, `timeout`, `fileRoots`, `fileExcludes` | Bounded file indexing |
| `fzf` | External matching for large indexes |
| `bat` | Syntax-highlighted previews |
| `shell` | Zsh command completion and shell actions |
| `emoji` | Path to the emoji JSON dataset |
| `screenshots` | Optional `area`, `window`, and `screen` callbacks |
| `commands` | Personal entries with `label` and `run` or `url` |
| `theme` | Optional `base16` colors and `transparency.enable` |

`stateDir` defaults to `hs.configdir .. "/CommandPalette-state"`.
`recencyFile` and `emojiFile` can preserve an existing history location.
The Spoon keeps personal shortcuts, host paths, and themes in the caller's configuration.

```sh
nix develop -c lua tests/lifecycle.lua "$PWD"
nix build .#checks.aarch64-darwin.palette
```

Extracted from [sysinit](https://github.com/roshbhatia/sysinit/tree/6b71b078a36964ab3610c24af7c76b179ce667e7/modules/darwin/home/hammerspoon). MIT licensed.
