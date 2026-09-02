local M = {}

function M.clamp(value, minimum, maximum)
  if value < minimum then return minimum end
  if value > maximum then return maximum end
  return value
end

function M.read(object, key, fallback)
  if object == nil then return fallback end
  local ok, value = pcall(function() return object[key] end)
  if not ok or value == nil then return fallback end
  return value
end

function M.number(value, fallback)
  return type(value) == 'number' and value or fallback
end

function M.round(value)
  return math.floor(value + 0.5)
end

function M.polar(center, radius, angle)
  return center + vec2(math.cos(angle) * radius, math.sin(angle) * radius)
end

function M.boolText(value)
  if value == nil then return 'n/a' end
  return value and 'yes' or 'no'
end

return M
