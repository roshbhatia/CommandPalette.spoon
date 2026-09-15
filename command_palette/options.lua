local M = { config = {}, root = "" }
function M.mkdir(path)
  local current = ""
  for part in path:gmatch("[^/]+") do
    current = current .. "/" .. part
    hs.fs.mkdir(current)
  end
end
return M
