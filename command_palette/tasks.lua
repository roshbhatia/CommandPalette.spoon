local M = {}
local active = {}
local generation = 0
function M.new(path, callback, args)
  local epoch = generation
  local task
  task = hs.task.new(path, function(...)
    if task then
      active[task] = nil
    end
    if epoch == generation and callback then
      callback(...)
    end
  end, args)
  if task then
    active[task] = true
  end
  return task
end
function M.stop()
  generation = generation + 1
  for task in pairs(active) do
    task:terminate()
  end
  active = {}
end
return M
