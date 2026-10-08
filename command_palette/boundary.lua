local M = {}

function M.url(value)
  if type(value) ~= "string" or value:find("[%c%s]") or not value:match("^[%a][%w+.-]*:.+$") then
    return nil, "Expected a URL with a scheme and no unescaped whitespace"
  end
  return value
end

local function valid(value, seen)
  local kind = type(value)
  if kind == "nil" or kind == "string" or kind == "boolean" then
    return true
  elseif kind == "number" then
    return value == value and value ~= math.huge and value ~= -math.huge
  elseif kind ~= "table" or seen[value] then
    return false
  end
  seen[value] = true
  for key, item in pairs(value) do
    if (type(key) ~= "string" and type(key) ~= "number") or not valid(key, seen) or not valid(item, seen) then
      seen[value] = nil
      return false
    end
  end
  seen[value] = nil
  return true
end

function M.encode(value)
  if not valid(value, {}) then
    return nil, "Payload contains a cycle or a value JSON cannot represent"
  end
  local ok, encoded = pcall(hs.json.encode, value)
  if not ok or type(encoded) ~= "string" then
    return nil, "JSON encoding failed"
  end
  return encoded
end

return M
