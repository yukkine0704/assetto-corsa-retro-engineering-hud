local U = require('src/utils')

local M = {
  CAPACITY = 180,
  INTERVAL = 1 / 30
}

local function blankSample()
  return { throttle = 0, brake = 0 }
end

function M.new()
  local history = {
    head = 0,
    count = 0,
    accumulator = 0,
    samples = {}
  }
  for i = 1, M.CAPACITY do history.samples[i] = blankSample() end
  return history
end

function M.clear(history)
  history.head = 0
  history.count = 0
  history.accumulator = 0
end

local function nextIndex(index)
  return index % M.CAPACITY + 1
end

local function writeSample(history, throttle, brake)
  history.head = nextIndex(history.head)
  local sample = history.samples[history.head]
  sample.throttle = U.clamp(throttle or 0, 0, 1)
  sample.brake = U.clamp(brake or 0, 0, 1)
  history.count = math.min(history.count + 1, M.CAPACITY)
end

function M.update(history, dt, throttle, brake)
  local elapsed = math.max(dt or 0, 0)
  history.accumulator = math.min(history.accumulator + elapsed, 0.25)
  while history.accumulator >= M.INTERVAL do
    history.accumulator = history.accumulator - M.INTERVAL
    writeSample(history, throttle, brake)
  end
end

function M.sampleAt(history, ordinal)
  if ordinal < 0 or ordinal >= history.count then return nil end
  local index = (history.head - history.count + ordinal) % M.CAPACITY + 1
  return history.samples[index]
end

return M
