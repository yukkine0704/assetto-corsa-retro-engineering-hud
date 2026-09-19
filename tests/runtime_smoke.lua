package.path = './?.lua;./?/init.lua;' .. package.path

local Vec2 = {}
Vec2.__index = Vec2
function Vec2.__add(a, b) return vec2(a.x + b.x, a.y + b.y) end
function Vec2.__sub(a, b) return vec2(a.x - b.x, a.y - b.y) end
function Vec2.__mul(a, b)
  if type(a) == 'number' then return vec2(a * b.x, a * b.y) end
  return vec2(a.x * b, a.y * b)
end
function Vec2.__div(a, b) return vec2(a.x / b, a.y / b) end
function vec2(x, y) return setmetatable({ x = x or 0, y = y or 0 }, Vec2) end

function rgbm(r, g, b, mult) return { r = r, g = g, b = b, mult = mult } end

local saved = { layoutVersion = 4, instrumentMode = 'analog' }
local car
local sim = { raceFlagType = nil }
local windowWidth, windowHeight = 460, 460
local pressInstrumentMode = false
local pressSpeedNeedleMode = false
local pressRpmNeedleMode = false
local lastWindowConstraint

ac = {
  storage = function(defaults)
    for key, value in pairs(defaults) do
      if saved[key] == nil then saved[key] = value end
    end
    return saved
  end,
  getCar = function() return car end,
  getSim = function() return sim end,
  getControllerSteerValue = function() return 0 end,
  broadcastSharedEvent = function() end,
  setWindowSizeConstraints = function(id, minimum, maximum)
    lastWindowConstraint = { id = id, minimum = minimum, maximum = maximum }
  end
}

local function noop() end
ui = {
  windowWidth = function() return windowWidth end,
  windowHeight = function() return windowHeight end,
  measureDWriteText = function(text, size) return vec2(#tostring(text) * size * 0.55, size) end,
  drawCircle = noop,
  drawCircleFilled = noop,
  drawLine = noop,
  drawRectFilled = noop,
  dwriteDrawText = noop,
  pathArcTo = noop,
  pathClear = noop,
  pathFillConvex = noop,
  pathLineTo = noop,
  pathStroke = noop,
  popDWriteFont = noop,
  popStyleVar = noop,
  pushDWriteFont = noop,
  pushStyleVarAlpha = noop,
  header = noop,
  separator = noop,
  text = noop,
  textWrapped = noop,
  checkbox = function() return false end,
  slider = function(_, value) return value, false end,
  button = function(label)
    if pressInstrumentMode and label:find('Instrument mode:', 1, true) == 1 then
      pressInstrumentMode = false
      return true
    end
    if pressSpeedNeedleMode and label:find('Speed dial needle:', 1, true) == 1 then
      pressSpeedNeedleMode = false
      return true
    end
    if pressRpmNeedleMode and label:find('RPM dial needle:', 1, true) == 1 then
      pressRpmNeedleMode = false
      return true
    end
    return false
  end
}

script = {}
require('app')
local Settings = require('src/settings')
local Telemetry = require('src/telemetry')
local DialLayout = require('src/layout')
local Gt7Layout = require('src/gt7_retro_layout')

assert(Settings.values.instrumentMode == 'analog', 'v5 migration must preserve analog')
assert(Settings.values.layoutVersion == 6, 'v6 migration must complete')
assert(Settings.values.gt7SpeedNeedleMode == 'digital'
  and Settings.values.gt7RpmNeedleMode == 'digital',
  'v6 migration must preserve the former direct GT7 needle response')
assert(Gt7Layout.rpmStartFraction == DialLayout.digitalRpmAlertStartFraction,
  'GT7 RPM band must start at the digital lower warning-light threshold')

local expected = { 'gt7_retro', 'digital', 'analog' }
for _, mode in ipairs(expected) do
  pressInstrumentMode = true
  Settings.draw()
  assert(Settings.values.instrumentMode == mode, 'instrument selector cycle failed')
end

Settings.values.instrumentMode = 'gt7_retro'
pressSpeedNeedleMode = true
Settings.draw()
assert(Settings.values.gt7SpeedNeedleMode == 'analog'
  and Settings.values.gt7RpmNeedleMode == 'digital',
  'GT7 speed needle selection must be independent')
pressRpmNeedleMode = true
Settings.draw()
assert(Settings.values.gt7SpeedNeedleMode == 'analog'
  and Settings.values.gt7RpmNeedleMode == 'analog',
  'GT7 RPM needle selection must be independent')

local function makeCar(overrides)
  local value = {
    physicsAvailable = true,
    speedKmh = 128,
    rpm = 4200,
    rpmLimiter = 8000,
    gear = 3,
    steer = 35,
    steerLock = 540,
    gas = 0.62,
    brake = 0.15,
    clutch = 1,
    handbrake = 0,
    fuel = 18,
    maxFuel = 60,
    turboCount = 0,
    turboBoost = 0,
    tractionControlModes = 3,
    tractionControlMode = 2,
    tractionControlInAction = false,
    absModes = 3,
    absMode = 2,
    absInAction = false,
    headlightsActive = false,
    lowBeams = false,
    highBeams = false,
    turningLeftLights = false,
    turningRightLights = false,
    hazardLights = false,
    turningLightsActivePhase = true,
    isInPit = false,
    isInPitlane = false,
    manualPitsSpeedLimiterEnabled = false,
    speedLimiterInAction = false,
    engineLifeLeft = 1000,
    ffbFinal = 0
  }
  for key, override in pairs(overrides or {}) do value[key] = override end
  return value
end

local telemetry = Telemetry.new()
car = makeCar({ ffbFinal = 0.62 })
for _ = 1, 30 do Telemetry.update(telemetry, 1 / 60, Settings.values) end
assert(telemetry.ffbAvailable and telemetry.ffbPercent >= 60 and telemetry.ffbPercent <= 63,
  'FFB must use and smooth ffbFinal magnitude')
assert(telemetry.gt7SpeedNeedleNormalized > 0.3 and telemetry.gt7SpeedNeedleNormalized < 0.5,
  'GT7 analog speed needle must track its own normalized target')
assert(telemetry.gt7RpmNeedleNormalized > 0.45 and telemetry.gt7RpmNeedleNormalized < 0.6,
  'GT7 analog RPM needle must track its own normalized target')
assert(telemetry.ffbNeedle > 0.55 and telemetry.ffbNeedle < 0.70,
  'FFB needle must settle near the live magnitude')

car.ffbFinal = -1.03
Telemetry.update(telemetry, 1 / 60, Settings.values)
assert(telemetry.ffbClipping, 'absolute FFB saturation must trigger clipping')
assert(telemetry.ffbNeedle < 0.9,
  'FFB needle must preserve mechanical inertia during a sudden saturation spike')
for _ = 1, 45 do Telemetry.update(telemetry, 1 / 60, Settings.values) end
assert(telemetry.ffbNeedle > 0.95,
  'FFB needle must reach sustained high load after its inertial sweep')

car.physicsAvailable = false
Telemetry.update(telemetry, 1 / 60, Settings.values)
assert(not telemetry.ffbAvailable and telemetry.ffbPercent == 0,
  'missing physics must use explicit FFB fallback')
assert(telemetry.ffbNeedle == 0 and telemetry.ffbNeedleVelocity == 0,
  'missing physics must park the FFB needle')

local boostTelemetry = Telemetry.new()
car = makeCar({ turboCount = 1, turboBoost = 1.2 })
Telemetry.update(boostTelemetry, 1 / 60, Settings.values)
assert(boostTelemetry.boostNeedleNormalized > 0 and boostTelemetry.boostNeedleNormalized < 0.8,
  'boost needle must preserve inertia on a sudden pressure increase')
for _ = 1, 60 do Telemetry.update(boostTelemetry, 1 / 60, Settings.values) end
assert(boostTelemetry.boostNeedleNormalized > 0.75 and boostTelemetry.boostNeedleNormalized <= 0.81,
  'boost needle must settle at the normalized pressure')
car.turboCount = 0
Telemetry.update(boostTelemetry, 1 / 60, Settings.values)
assert(boostTelemetry.boostNeedleNormalized == 0 and boostTelemetry.boostNeedleVelocity == 0,
  'naturally aspirated cars must park the hidden boost needle')

local scenarios = {
  { mode = 'digital', width = 460, height = 460, car = makeCar({ gear = 0, rpm = 2000 }), unit = 'km/h' },
  { mode = 'analog', width = 740, height = 420, car = makeCar({ gear = -1, rpm = 7000 }), unit = 'mph' },
  { mode = 'gt7_retro', width = 460, height = 460, car = makeCar({ gear = 0, rpm = 4200, ffbFinal = 0 }), unit = 'km/h', scale = 0.55, speedNeedle = 'digital', rpmNeedle = 'analog' },
  { mode = 'gt7_retro', width = 900, height = 360, car = makeCar({ gear = -1, rpm = 7200, ffbFinal = 0.91 }), unit = 'mph', scale = 1.15, speedNeedle = 'analog', rpmNeedle = 'digital' },
  { mode = 'gt7_retro', width = 1200, height = 420, car = makeCar({
    turboCount = 1, turboBoost = 1.2, rpm = 7800, ffbFinal = 1.03,
    turningLeftLights = true, handbrake = 1, headlightsActive = true,
    engineLifeLeft = 600, absInAction = true
  }), unit = 'km/h', scale = 0.72, flag = 2 }
}

for _, scenario in ipairs(scenarios) do
  Settings.values.instrumentMode = scenario.mode
  Settings.values.speedUnit = scenario.unit
  Settings.values.hudScale = scenario.scale or 0.72
  Settings.values.theme = scenario.width > 1000 and 'light' or 'dark'
  Settings.values.gt7SpeedNeedleMode = scenario.speedNeedle or Settings.values.gt7SpeedNeedleMode
  Settings.values.gt7RpmNeedleMode = scenario.rpmNeedle or Settings.values.gt7RpmNeedleMode
  sim.raceFlagType = scenario.flag
  windowWidth, windowHeight, car = scenario.width, scenario.height, scenario.car
  script.update(1 / 60)
  script.windowMain()
end

assert(lastWindowConstraint and lastWindowConstraint.id == 'main'
  and lastWindowConstraint.minimum.x == 320 and lastWindowConstraint.minimum.y == 112,
  'GT7 Retro must expose panoramic mouse-resize constraints')

Settings.values.instrumentMode = 'digital'
script.windowMain()
assert(lastWindowConstraint.minimum.x == 340 and lastWindowConstraint.minimum.y == 340,
  'square modes must restore their original mouse-resize constraints')

car = nil
script.update(1 / 60)
script.windowMain()

print('Runtime smoke scenarios passed')
