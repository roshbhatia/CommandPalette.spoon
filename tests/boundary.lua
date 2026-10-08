local root = assert(arg[1])
package.path = root .. "/?.lua;" .. package.path
local calls = 0
hs = { json = {
  encode = function()
    calls = calls + 1
    return "{}"
  end,
} }
local boundary = require("command_palette.boundary")
assert(boundary.url("x-apple.systempreferences:com.apple.preference.keyboard"))
assert(boundary.url("mailto:test@example.com"))
assert(boundary.url("https://example.com"))
assert(not boundary.url("example.com"))
assert(not boundary.url("https://example.com\nextra"))
assert(not boundary.url(nil))
local cycle = {}
cycle.self = cycle
for _, value in ipairs({ cycle, { callback = function() end }, { number = 0 / 0 }, { number = math.huge } }) do
  assert(not boundary.encode(value))
end
assert(calls == 0, "invalid data must not reach LuaSkin")
assert(boundary.encode({ title = "test", rows = { 1, 2 } }) == "{}")
hs.json.encode = function()
  return nil
end
assert(not boundary.encode({}))
hs.json.encode = function()
  error("native encoder failure")
end
assert(not boundary.encode({}))
print("boundary tests passed")
