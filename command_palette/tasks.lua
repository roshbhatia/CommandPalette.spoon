local M = {}
local active = {}
local generation = 0
function M.release(task)
  if active[task] then
    active[task] = nil
    task:setCallback(nil)
  end
end
function M.new(path, callback, args)
  local epoch = generation
  local task
  task = hs.task.new(path, function(...)
    if task then
      M.release(task)
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
    M.release(task)
    task:terminate()
  end
  active = {}
end
return M
