local U = require('src/utils')
local Layout = require('src/layout')

local M = {}
local SIM = ac.getSim()

local function blankState()
  return {
    available = false,
    clock = 0,
    speedKmh = 0,
    speedValue = 0,
    speedText = '000',
    speedUnit = 'km/h',
    rpm = 0,
    rpmText = '0000',
    rpmLimiter = nil,
    rpmDisplayLimiter = 8000,
    rpmGaugeLimiter = 8000,
    rpmSource = 'fallback',
    rpmNormalized = 0,
    rpmGaugeNormalized = 0,
    analogNeedleNormalized = 0,
    analogNeedleVelocity = 0,
    fuel = nil,
    maxFuel = nil,
    fuelNormalized = 0,
    turboAvailable = false,
    turboBoost = 0,
    turboDisplayMax = 1,
    rpmWarningFraction = 0.86,
    rpmRedlineFraction = 0.96,
    rpmWarning = false,
    rpmRedline = false,
    gear = 0,
    gearText = 'N',
    steeringInput = 0,
    steeringAngle = nil,
    steerLock = nil,
    throttle = 0,
    brake = 0,
    clutch = 0,
    handbrake = 0,
    tcSupported = false,
    tcLevel = nil,
    tcActive = nil,
    absSupported = false,
    absLevel = nil,
    absActive = nil,
    lightsAvailable = false,
    headlights = nil,
    highBeams = nil,
    leftIndicator = nil,
    rightIndicator = nil,
    hazardLights = nil,
    indicatorPhase = nil,
    pitLane = false,
    pitLimiter = nil
  }
end

function M.new()
  return blankState()
end

local function gearLabel(gear)
  if gear == nil then return '—' end
  if gear == 0 then return 'N' end
  if gear == -1 then return 'R' end
  return tostring(gear)
end

local function formattedSpeed(state, value, unit)
  if state.speedValue ~= value or state.speedUnit ~= unit then
    state.speedValue = value
    state.speedUnit = unit
    state.speedText = string.format('%03d', value)
  end
end

local function formattedRpm(state, value)
  if state._rpmValue ~= value then
    state._rpmValue = value
    state.rpmText = string.format('%04d', value)
  end
end

local function formattedGear(state, value)
  if state._gearValue ~= value then
    state._gearValue = value
    state.gearText = gearLabel(value)
  end
end

local function updateAnalogNeedle(state, dt)
  local step = U.clamp(dt or 0, 0, 0.05)
  if step <= 0 then return end

  local acceleration = (state.rpmGaugeNormalized - state.analogNeedleNormalized) * Layout.analogNeedleSpring
    - state.analogNeedleVelocity * Layout.analogNeedleDamping
  local velocity = U.clamp(state.analogNeedleVelocity + acceleration * step,
    -Layout.analogNeedleMaxVelocity, Layout.analogNeedleMaxVelocity)
  local position = U.clamp(state.analogNeedleNormalized + velocity * step, 0, 1)

  if position == 0 or position == 1 then velocity = 0 end
  state.analogNeedleNormalized = position
  state.analogNeedleVelocity = velocity
end

function M.update(state, dt, settings)
  state.clock = state.clock + math.max(dt or 0, 0)

  local car = ac.getCar(0)
  if not car then
    state.available = false
    return
  end

  state.available = true

  local speedKmh = math.max(U.number(U.read(car, 'speedKmh', 0), 0), 0)
  local speedValue = U.round(settings.speedUnit == 'mph' and speedKmh * 0.621371 or speedKmh)
  formattedSpeed(state, speedValue, settings.speedUnit)
  state.speedKmh = speedKmh

  state.rpm = math.max(U.number(U.read(car, 'rpm', 0), 0), 0)
  local carLimiter = U.number(U.read(car, 'rpmLimiter', nil), nil)
  if carLimiter and carLimiter > 1000 then
    state.rpmLimiter = carLimiter
    state.rpmDisplayLimiter = carLimiter
    state.rpmSource = 'car'
  else
    state.rpmLimiter = nil
    state.rpmDisplayLimiter = math.max(settings.fallbackRpm, 1000)
    state.rpmSource = 'fallback'
  end
  -- Keep the car's exact limiter for alert thresholds, but round the visual
  -- gauge up to the next whole thousand so a 7.5k engine gets a clean 8k
  -- endpoint and the needle/arc can stop between 7 and 8.
  state.rpmGaugeLimiter = math.max(math.ceil(state.rpmDisplayLimiter / 1000) * 1000, 1000)
  state.rpmNormalized = U.clamp(state.rpm / state.rpmDisplayLimiter, 0, 1)
  state.rpmGaugeNormalized = U.clamp(state.rpm / state.rpmGaugeLimiter, 0, 1)
  state.rpmWarningFraction = settings.rpmWarningFraction
  state.rpmRedlineFraction = settings.rpmRedlineFraction
  state.rpmWarning = state.rpmNormalized >= settings.rpmWarningFraction
  state.rpmRedline = state.rpmNormalized >= settings.rpmRedlineFraction
  updateAnalogNeedle(state, dt)
  formattedRpm(state, U.round(state.rpm))

  state.gear = U.number(U.read(car, 'gear', 0), 0)
  formattedGear(state, state.gear)

  local steerAngle = U.number(U.read(car, 'steer', nil), nil)
  local steerLock = U.number(U.read(car, 'steerLock', nil), nil)
  local steeringInput = nil
  if steerAngle and steerLock and math.abs(steerLock) > 0.1 then
    steeringInput = U.clamp(steerAngle / steerLock, -1, 1)
  else
    local ok, controllerSteer = pcall(ac.getControllerSteerValue)
    if ok and type(controllerSteer) == 'number' then
      steeringInput = U.clamp(controllerSteer, -1, 1)
    end
  end
  state.steeringInput = steeringInput or 0
  state.steeringAngle = steerAngle
  state.steerLock = steerLock

  state.throttle = U.clamp(U.number(U.read(car, 'gas', 0), 0), 0, 1)
  state.brake = U.clamp(U.number(U.read(car, 'brake', 0), 0), 0, 1)
  local rawClutch = U.number(U.read(car, 'clutch', nil), nil)
  state.clutch = rawClutch and U.clamp(1 - rawClutch, 0, 1) or 0
  state.handbrake = U.clamp(U.number(U.read(car, 'handbrake', 0), 0), 0, 1)

  state.fuel = U.number(U.read(car, 'fuel', nil), nil)
  state.maxFuel = U.number(U.read(car, 'maxFuel', nil), nil)
  state.fuelNormalized = state.fuel and state.maxFuel and state.maxFuel > 0.1
    and U.clamp(state.fuel / state.maxFuel, 0, 1) or 0
  local turboCount = U.number(U.read(car, 'turboCount', 0), 0)
  state.turboAvailable = turboCount > 0
  state.turboBoost = math.max(0, U.number(U.read(car, 'turboBoost', 0), 0))
  if state.turboAvailable then
    state.turboDisplayMax = math.max(state.turboDisplayMax, 1, math.ceil(state.turboBoost * 2) / 2)
  else
    state.turboDisplayMax = 1
  end

  local tcModes = U.number(U.read(car, 'tractionControlModes', nil), nil)
  state.tcSupported = tcModes ~= nil and tcModes > 0
  state.tcLevel = state.tcSupported and U.number(U.read(car, 'tractionControlMode', nil), nil) or nil
  if state.tcSupported then
    state.tcActive = U.read(car, 'tractionControlInAction', nil)
  else
    state.tcActive = nil
  end

  local absModes = U.number(U.read(car, 'absModes', nil), nil)
  state.absSupported = absModes ~= nil and absModes > 0
  state.absLevel = state.absSupported and U.number(U.read(car, 'absMode', nil), nil) or nil
  if state.absSupported then
    state.absActive = U.read(car, 'absInAction', nil)
  else
    state.absActive = nil
  end

  state.headlights = U.read(car, 'headlightsActive', nil)
  local lowBeams = U.read(car, 'lowBeams', nil)
  state.lightsAvailable = state.headlights ~= nil
  if state.headlights ~= nil and lowBeams ~= nil then
    state.highBeams = state.headlights and not lowBeams
  else
    state.highBeams = nil
  end

  state.leftIndicator = U.read(car, 'turningLeftLights', nil)
  state.rightIndicator = U.read(car, 'turningRightLights', nil)
  state.hazardLights = U.read(car, 'hazardLights', nil)
  state.indicatorPhase = U.read(car, 'turningLightsActivePhase', nil)

  state.pitLane = U.read(car, 'isInPit', false) or U.read(car, 'isInPitlane', false)

  -- Some CSP builds expose a pit-limiter flag on the car, while the installed
  -- local examples do not rely on one. Probe safely and hide it when absent.
  local optionalPitLimiter = U.read(car, 'pitLimiter', nil)
  state.pitLimiter = optionalPitLimiter
end

return M
