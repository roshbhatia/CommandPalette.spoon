local M = {}
local half_life = 7 * 24 * 60 * 60

local function load(scope)
  local value = hs.settings.get("CommandPalette.pick." .. scope)
  return type(value) == "table" and value or {}
end

local function score(entry, now)
  if type(entry) ~= "table" or type(entry.score) ~= "number" or type(entry.at) ~= "number" then
    return 0
  end
  return entry.score * 2 ^ (-math.max(0, now - entry.at) / half_life)
end

function M.sort(scope, rows)
  if not scope then
    return rows
  end
  local history, now, ranked = load(scope), os.time(), {}
  for index, row in ipairs(rows) do
    ranked[index] = { row = row, score = score(history[row.id or row.text], now), index = index }
  end
  table.sort(ranked, function(a, b)
    if a.score ~= b.score then
      return a.score > b.score
    end
    return a.index < b.index
  end)
  local sorted = {}
  for index, entry in ipairs(ranked) do
    sorted[index] = entry.row
  end
  return sorted
end

function M.touch(scope, row)
  if not scope or not row then
    return
  end
  local history, now = load(scope), os.time()
  local key = row.id or row.text
  history[key] = { score = score(history[key], now) + 1, at = now }
  hs.settings.set("CommandPalette.pick." .. scope, history)
end

return M
