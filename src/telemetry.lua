local U = require('src/utils')
local Layout = require('src/layout')
local Gt7Layout = require('src/gt7_retro_layout')

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
    gt7SpeedNeedleNormalized = 0,
    gt7SpeedNeedleVelocity = 0,
    gt7RpmNeedleNormalized = 0,
    gt7RpmNeedleVelocity = 0,
    fuel = nil,
    maxFuel = nil,
    fuelNormalized = 0,
    turboAvailable = false,
    turboBoost = 0,
    turboDisplayMax = 1,
    boostNeedleNormalized = 0,
    boostNeedleVelocity = 0,
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
    engineLifeLeft = nil,
    engineWarning = false,
    ffbAvailable = false,
    ffbSigned = 0,
    ffbMagnitudeRaw = 0,
    ffbMagnitude = 0,
    ffbNeedle = 0,
    ffbNeedleVelocity = 0,
    ffbPercent = 0,
    ffbClipping = false,
    ffbClipHold = 0,
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
    raceFlagType = nil,
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

local function springNeedle(position, velocity, target, dt, spring, damping, maximumVelocity)
  local step = U.clamp(dt or 0, 0, 0.05)
  if step <= 0 then return position, velocity end

  local acceleration = (target - position) * spring - velocity * damping
  velocity = U.clamp(velocity + acceleration * step, -maximumVelocity, maximumVelocity)
  position = U.clamp(position + velocity * step, 0, 1)
  if (position == 0 and velocity < 0) or (position == 1 and velocity > 0) then velocity = 0 end
  return position, velocity
end

local function updateGt7Needles(state, speedTarget, rpmTarget, dt)
  state.gt7SpeedNeedleNormalized, state.gt7SpeedNeedleVelocity = springNeedle(
    state.gt7SpeedNeedleNormalized, state.gt7SpeedNeedleVelocity, speedTarget, dt,
    Gt7Layout.speedNeedleSpring, Gt7Layout.speedNeedleDamping, Gt7Layout.speedNeedleMaxVelocity)
  state.gt7RpmNeedleNormalized, state.gt7RpmNeedleVelocity = springNeedle(
    state.gt7RpmNeedleNormalized, state.gt7RpmNeedleVelocity, rpmTarget, dt,
    Gt7Layout.rpmNeedleSpring, Gt7Layout.rpmNeedleDamping, Gt7Layout.rpmNeedleMaxVelocity)
end

local function updateFfb(state, car, dt)
  local physicsAvailable = U.read(car, 'physicsAvailable', true)
  local raw = U.number(U.read(car, 'ffbFinal', nil), nil)
  state.ffbAvailable = raw ~= nil and physicsAvailable ~= false

  if not state.ffbAvailable then
    state.ffbSigned = 0
    state.ffbMagnitudeRaw = 0
    state.ffbMagnitude = 0
    state.ffbNeedle = 0
    state.ffbNeedleVelocity = 0
    state.ffbPercent = 0
    state.ffbClipping = false
    state.ffbClipHold = 0
    return
  end

  state.ffbSigned = raw
  state.ffbMagnitudeRaw = math.abs(raw)
  local target = U.clamp(state.ffbMagnitudeRaw, 0, 1)
  local step = U.clamp(dt or 0, 0, 0.05)
  -- Faster attack keeps impacts and clipping legible; a slightly slower
  -- release removes high-frequency chatter without making the meter feel late.
  local timeConstant = target > state.ffbMagnitude and 0.055 or 0.12
  local alpha = step > 0 and (1 - math.exp(-step / timeConstant)) or 1
  state.ffbMagnitude = state.ffbMagnitude + (target - state.ffbMagnitude) * alpha
  state.ffbPercent = U.round(U.clamp(state.ffbMagnitude, 0, 1) * 100)

  -- A spring-driven needle gives the lower gauge visible mechanical mass.
  -- It follows the real absolute ffbFinal value; clipping remains tied to the
  -- unsmoothed source below so the warning never inherits the needle delay.
  if step > 0 then
    local acceleration = (target - state.ffbNeedle) * Gt7Layout.ffbNeedleSpring
      - state.ffbNeedleVelocity * Gt7Layout.ffbNeedleDamping
    local velocity = U.clamp(state.ffbNeedleVelocity + acceleration * step,
      -Gt7Layout.ffbNeedleMaxVelocity, Gt7Layout.ffbNeedleMaxVelocity)
    local position = U.clamp(state.ffbNeedle + velocity * step, 0, 1)
    if (position == 0 and velocity < 0) or (position == 1 and velocity > 0) then velocity = 0 end
    state.ffbNeedle = position
    state.ffbNeedleVelocity = velocity
  end

  if state.ffbMagnitudeRaw >= 0.98 then
    state.ffbClipHold = 0.18
  else
    state.ffbClipHold = math.max(0, state.ffbClipHold - step)
  end
  state.ffbClipping = state.ffbClipHold > 0
end

function M.update(state, dt, settings)
  state.clock = state.clock + math.max(dt or 0, 0)
  state.raceFlagType = U.read(SIM, 'raceFlagType', nil)

  local car = ac.getCar(0)
  if not car then
    state.available = false
    state.ffbAvailable = false
    state.ffbSigned = 0
    state.ffbMagnitudeRaw = 0
    state.ffbMagnitude = 0
    state.ffbNeedle = 0
    state.ffbNeedleVelocity = 0
    state.ffbPercent = 0
    state.ffbClipping = false
    state.ffbClipHold = 0
    state.gt7SpeedNeedleNormalized = 0
    state.gt7SpeedNeedleVelocity = 0
    state.gt7RpmNeedleNormalized = 0
    state.gt7RpmNeedleVelocity = 0
    state.boostNeedleNormalized = 0
    state.boostNeedleVelocity = 0
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
  local speedGaugeMaximum = settings.speedUnit == 'mph' and 200 or 320
  updateGt7Needles(state, U.clamp(state.speedValue / speedGaugeMaximum, 0, 1),
    state.rpmGaugeNormalized, dt)
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
  state.engineLifeLeft = U.number(U.read(car, 'engineLifeLeft', nil), nil)
  state.engineWarning = state.engineLifeLeft ~= nil and state.engineLifeLeft < 850
  updateFfb(state, car, dt)

  state.fuel = U.number(U.read(car, 'fuel', nil), nil)
  state.maxFuel = U.number(U.read(car, 'maxFuel', nil), nil)
  state.fuelNormalized = state.fuel and state.maxFuel and state.maxFuel > 0.1
    and U.clamp(state.fuel / state.maxFuel, 0, 1) or 0
  local turboCount = U.number(U.read(car, 'turboCount', 0), 0)
  state.turboAvailable = turboCount > 0
  state.turboBoost = math.max(0, U.number(U.read(car, 'turboBoost', 0), 0))
  if state.turboAvailable then
    state.turboDisplayMax = math.max(state.turboDisplayMax, 1, math.ceil(state.turboBoost * 2) / 2)
    local boostTarget = U.clamp(state.turboBoost / math.max(state.turboDisplayMax, 0.1), 0, 1)
    state.boostNeedleNormalized, state.boostNeedleVelocity = springNeedle(
      state.boostNeedleNormalized, state.boostNeedleVelocity, boostTarget, dt,
      Gt7Layout.boostNeedleSpring, Gt7Layout.boostNeedleDamping,
      Gt7Layout.boostNeedleMaxVelocity)
  else
    state.turboDisplayMax = 1
    state.boostNeedleNormalized = 0
    state.boostNeedleVelocity = 0
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

  -- CSP exposes the driver's manual limiter selection and the final in-action
  -- state separately. Prefer the selection so the telltale stays lit while
  -- enabled, with the in-action flag as a compatibility fallback.
  local manualLimiter = U.read(car, 'manualPitsSpeedLimiterEnabled', nil)
  if manualLimiter ~= nil then
    state.pitLimiter = manualLimiter
  else
    state.pitLimiter = U.read(car, 'speedLimiterInAction', nil)
  end
end

return M
