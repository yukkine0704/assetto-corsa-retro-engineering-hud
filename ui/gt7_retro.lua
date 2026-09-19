local Theme = require('src/theme')
local Layout = require('src/gt7_retro_layout')
local U = require('src/utils')

local M = {}
local C = Theme.colors

local function point(origin, scale, x, y)
  return origin + vec2(x * scale, y * scale)
end

local function withAlpha(color, alpha)
  return Theme.withAlpha(color, U.clamp(alpha, 0, 1))
end

local function centeredText(text, size, center, color)
  local measured = ui.measureDWriteText(text, size)
  ui.dwriteDrawText(text, size, center - measured / 2, color)
end

local function drawLine(p1, p2, color, width)
  ui.drawLine(p1, p2, color, width)
end

local function drawArc(center, radius, startAngle, endAngle, color, width, segments)
  ui.pathClear()
  ui.pathArcTo(center, radius, startAngle, endAngle, segments or 32)
  ui.pathStroke(color, false, width)
end

local function ellipsePoint(center, radiusX, radiusY, angle)
  return center + vec2(math.cos(angle) * radiusX, math.sin(angle) * radiusY)
end

local function drawEllipseSegment(center, radiusX, radiusY, startAngle, endAngle, color, width, steps)
  local previous = ellipsePoint(center, radiusX, radiusY, startAngle)
  for i = 1, steps or 5 do
    local angle = startAngle + (endAngle - startAngle) * i / (steps or 5)
    local current = ellipsePoint(center, radiusX, radiusY, angle)
    drawLine(previous, current, color, width)
    previous = current
  end
end

local function buildPolygon(origin, scale, coordinates)
  ui.pathClear()
  for _, coordinate in ipairs(coordinates) do
    ui.pathLineTo(point(origin, scale, coordinate[1], coordinate[2]))
  end
end

local function drawPolygon(origin, scale, coordinates, fill, stroke, strokeWidth)
  buildPolygon(origin, scale, coordinates)
  ui.pathFillConvex(fill)
  buildPolygon(origin, scale, coordinates)
  ui.pathStroke(stroke, true, strokeWidth * scale)
end

local function alertPulse(state, settings, redline)
  if redline then
    if settings.animateRedlineAlert == false then return true end
    return math.floor(state.clock / Layout.redlineBlinkPeriod) % 2 == 0
  end
  if settings.animateShiftAlert == false then return true end
  return math.floor(state.clock / Layout.shiftBlinkPeriod) % 2 == 0
end

local function indicatorLit(state, settings)
  if settings.animateIndicators == false then return true end
  if type(state.indicatorPhase) == 'boolean' then return state.indicatorPhase end
  if type(state.indicatorPhase) == 'number' then return state.indicatorPhase > 0.5 end
  return math.floor(state.clock / Layout.indicatorPeriod) % 2 == 0
end

local function flagColor(state)
  local flag = state.raceFlagType
  if type(flag) ~= 'number' or flag == 0 then return nil end

  -- Match the established digital-mode mapping of CSP flag values.
  if flag == 2 then return C.flagYellow end
  if flag == 5 or flag == 8 then return C.red end
  if flag == 12 then return C.shiftBlue end
  if flag == 13 or flag == 14 then return C.primary end
  return nil
end

local function flagBlinkOn(state, settings)
  if settings == nil or settings.animateFlagAlert ~= false then
    return math.floor(state.clock / Layout.flagBlinkPeriod) % 2 == 0
  end
  return true
end

local function rpmColor(fraction, active, state, settings)
  local warning = state.rpmWarningFraction or 0.86
  local redline = state.rpmRedlineFraction or 0.96
  local shiftZoneStart = math.max(0, math.min(warning, redline - 0.14))
  if not active then return C.inactive end

  if fraction >= redline then
    if state.rpmRedline then
      return alertPulse(state, settings, true) and C.red or C.amber
    end
    return C.red
  end
  if fraction >= shiftZoneStart then
    return state.rpmWarning and alertPulse(state, settings, false) and C.shiftBlue or C.shiftBlueDim
  end
  return C.primary
end

local function drawRpmBar(origin, scale, state, settings)
  local totalWidth = Layout.rpmRight - Layout.rpmLeft
  local segmentWidth = (totalWidth - Layout.rpmGap * (Layout.rpmSegments - 1)) / Layout.rpmSegments
  local rpmFraction = U.clamp(state.rpmNormalized or 0, 0, 1)
  local startFraction = Layout.rpmStartFraction
  local displayedFraction = U.clamp((rpmFraction - startFraction) / (1 - startFraction), 0, 1)
  local filled = rpmFraction >= startFraction
    and math.max(1, math.ceil(displayedFraction * Layout.rpmSegments)) or 0
  for i = 1, Layout.rpmSegments do
    local fraction = startFraction + (1 - startFraction) * i / Layout.rpmSegments
    local x = Layout.rpmLeft + (i - 1) * (segmentWidth + Layout.rpmGap)
    local topLeft = point(origin, scale, x, Layout.rpmTop)
    local bottomRight = point(origin, scale, x + segmentWidth, Layout.rpmTop + Layout.rpmHeight)
    ui.drawRectFilled(topLeft, bottomRight, rpmColor(fraction, i <= filled, state, settings))
  end
end

local function drawTriangle(origin, scale, x, y, direction, color)
  local sign = direction == 'left' and -1 or 1
  drawPolygon(origin, scale, {
    { x + sign * 13, y }, { x - sign * 8, y - 12 }, { x - sign * 8, y + 12 }
  }, color, color, 1)
end

local function drawCenterReadout(origin, scale, state, settings)
  local redlineOn = state.rpmRedline and alertPulse(state, settings, true)
  local valueColor = state.rpmRedline and (redlineOn and C.red or C.amber)
    or (state.rpmWarning and C.amber or C.primary)

  centeredText(state.speedText, 76 * scale, point(origin, scale, 620, 172), C.primary)
  centeredText(state.speedUnit, 19 * scale, point(origin, scale, 620, 224), C.secondary)
  centeredText(state.gearText, 100 * scale, point(origin, scale, 880, 174), valueColor)
  centeredText('GEAR', 14 * scale, point(origin, scale, 880, 232), C.secondary)

  local blink = indicatorLit(state, settings)
  local leftActive = (state.hazardLights or state.leftIndicator) and blink
  local rightActive = (state.hazardLights or state.rightIndicator) and blink
  drawTriangle(origin, scale, 460, 145, 'left', leftActive and C.amber or C.outlineDim)
  drawTriangle(origin, scale, 980, 145, 'right', rightActive and C.amber or C.outlineDim)

  if settings.showSteering ~= false then
    local steering = U.clamp(state.steeringInput or 0, -1, 1)
    local trackLeft = point(origin, scale, 610, 258)
    local trackRight = point(origin, scale, 830, 258)
    drawLine(trackLeft, trackRight, C.outlineDim, 3 * scale)
    drawLine(point(origin, scale, 720, 249), point(origin, scale, 720, 267), C.primary, 2 * scale)
    local markerX = 720 + steering * 104
    ui.drawCircleFilled(point(origin, scale, markerX, 258), 5 * scale, C.cyan, 16)
    centeredText('STEER', 11 * scale, point(origin, scale, 720, 278), C.secondary)
  end
end

local function gaugeAngle(fraction)
  return Layout.gaugeStart + (Layout.gaugeEnd - Layout.gaugeStart) * U.clamp(fraction, 0, 1)
end

local function drawNeedle(center, scale, fraction, color)
  local angle = gaugeAngle(fraction)
  local tip = U.polar(center, Layout.needleLength * scale, angle)
  local tail = U.polar(center, 22 * scale, angle + math.pi)
  drawLine(tail, tip, withAlpha(C.backlight, 0.18), 12 * scale)
  drawLine(tail, tip, C.outlineDim, 7 * scale)
  drawLine(tail, tip, color, 4 * scale)
  ui.drawCircleFilled(center, 12 * scale, C.panelRaised, 24)
  ui.drawCircle(center, 12 * scale, C.outline, 24, 2 * scale)
  ui.drawCircleFilled(center, 4 * scale, color, 16)
end

local function drawDigitalDialBar(center, scale, activeFraction, state, settings, rpmDial)
  local segmentCount = Layout.digitalDialBarSegments
  local span = (Layout.gaugeEnd - Layout.gaugeStart) / segmentCount
  local filled = math.floor(U.clamp(activeFraction, 0, 1) * segmentCount + 0.5)

  for i = 1, segmentCount do
    local fraction = i / segmentCount
    local startAngle = Layout.gaugeStart + (i - 1) * span + Layout.digitalDialBarGap
    local endAngle = Layout.gaugeStart + i * span - Layout.digitalDialBarGap
    local active = i <= filled
    local color = C.inactive
    if active then
      color = rpmDial and rpmColor(fraction, true, state, settings) or C.cyan
    end
    drawArc(center, Layout.digitalDialBarRadius * scale, startAngle, endAngle,
      color, Layout.digitalDialBarWidth * scale, 5)
  end
end

local function drawDialTicks(center, scale, labelValues, formatter, activeFraction, state, settings,
    rpmDial, needleMode)
  if needleMode == 'digital' then
    drawDigitalDialBar(center, scale, activeFraction, state, settings, rpmDial)
  end

  local minorCount = 40
  for i = 0, minorCount do
    local fraction = i / minorCount
    local angle = gaugeAngle(fraction)
    local major = i % 10 == 0
    local outer = U.polar(center, Layout.tickRadius * scale, angle)
    local inner = U.polar(center, (Layout.tickRadius - (major and 15 or 8)) * scale, angle)
    local color = C.primary
    if rpmDial and fraction >= (state.rpmRedlineFraction or 0.96) then color = C.red end
    drawLine(inner, outer, color, (major and 2.6 or 1.2) * scale)
  end

  for i, value in ipairs(labelValues) do
    local fraction = (#labelValues == 1) and 0 or (i - 1) / (#labelValues - 1)
    local labelPosition = U.polar(center, (Layout.tickRadius - 35) * scale, gaugeAngle(fraction))
    centeredText(formatter(value), 18 * scale, labelPosition, C.primary)
  end

  if needleMode ~= 'digital' then
    local needleColor = rpmDial
      and (state.rpmRedline and C.red or (state.rpmWarning and C.amber or C.primary)) or C.primary
    drawNeedle(center, scale, activeFraction, needleColor)
  end
end

local function drawFuelGauge(origin, scale, state)
  local center = point(origin, scale, Layout.leftCenterX, Layout.dialCenterY + 112)
  local radius = 65 * scale
  local startAngle = math.rad(205)
  local endAngle = math.rad(335)
  drawArc(center, radius, startAngle, endAngle, C.inactive, 12 * scale, 20)
  local segments = 10
  local filled = math.floor(U.clamp(state.fuelNormalized or 0, 0, 1) * segments + 0.5)
  for i = 1, segments do
    local a1 = startAngle + (endAngle - startAngle) * (i - 1) / segments + 0.012
    local a2 = startAngle + (endAngle - startAngle) * i / segments - 0.012
    local color = i <= filled and ((state.fuelNormalized or 0) < 0.15 and C.red or C.cyan) or C.inactive
    drawArc(center, radius, a1, a2, color, 8 * scale, 4)
  end
  ui.drawRectFilled(center + vec2(-7 * scale, -9 * scale), center + vec2(6 * scale, 8 * scale), C.primary)
  drawLine(center + vec2(6 * scale, -5 * scale), center + vec2(12 * scale, -1 * scale), C.primary, 2 * scale)
  drawLine(center + vec2(12 * scale, -1 * scale), center + vec2(12 * scale, 8 * scale), C.primary, 2 * scale)
  centeredText('E', 10 * scale, U.polar(center, radius, startAngle), C.secondary)
  centeredText('F', 10 * scale, U.polar(center, radius, endAngle), C.secondary)
  centeredText('FUEL', 11 * scale, center + vec2(0, 28 * scale), C.secondary)
end

local function drawSpeedDial(origin, scale, state, settings, backdropOpacity)
  local center = point(origin, scale, Layout.leftCenterX, Layout.dialCenterY)
  local radius = Layout.dialRadius * scale
  ui.drawCircleFilled(center, radius, withAlpha(C.panel, math.min(0.96, backdropOpacity + 0.18)), 72)
  ui.drawCircle(center, radius, C.metal, 72, 4 * scale)
  ui.drawCircle(center, radius - 8 * scale, C.outline, 72, 2 * scale)
  ui.drawCircle(center, radius - 16 * scale, C.outlineDim, 72, 2 * scale)

  local maximum = settings.speedUnit == 'mph' and 200 or 320
  local labels = settings.speedUnit == 'mph' and { 0, 50, 100, 150, 200 } or { 0, 80, 160, 240, 320 }
  local directFraction = U.clamp((state.speedValue or 0) / maximum, 0, 1)
  local needleFraction = settings.gt7SpeedNeedleMode == 'analog'
    and state.gt7SpeedNeedleNormalized or directFraction
  drawDialTicks(center, scale, labels, function(value) return tostring(value) end,
    needleFraction, state, settings, false, settings.gt7SpeedNeedleMode)
  centeredText(settings.speedUnit, 15 * scale, center + vec2(0, -25 * scale), C.secondary)
  drawFuelGauge(origin, scale, state)
end

local function drawBoostGauge(origin, scale, state)
  local center = point(origin, scale, Layout.rightCenterX, Layout.dialCenterY + 88)
  if not state.turboAvailable then
    centeredText('NAT ASP', 11 * scale, center + vec2(0, 22 * scale), C.outlineSoft)
    return
  end

  local startAngle = math.rad(205)
  local endAngle = math.rad(335)
  local radius = 65 * scale
  drawArc(center, radius, startAngle, endAngle, C.inactive, 12 * scale, 20)
  local pressureNormalized = U.clamp((state.turboBoost or 0)
    / math.max(state.turboDisplayMax or 1, 0.1), 0, 1)
  local needleNormalized = U.clamp(state.boostNeedleNormalized or 0, 0, 1)
  local segments = 10
  local filled = math.floor(pressureNormalized * segments + 0.5)
  for i = 1, segments do
    local a1 = startAngle + (endAngle - startAngle) * (i - 1) / segments + 0.012
    local a2 = startAngle + (endAngle - startAngle) * i / segments - 0.012
    local color = i <= filled and (i >= 9 and C.red or C.cyan) or C.inactive
    drawArc(center, radius, a1, a2, color, 8 * scale, 4)
  end
  local needle = U.polar(center, 48 * scale,
    startAngle + (endAngle - startAngle) * needleNormalized)
  drawLine(center, needle, C.primary, 3 * scale)
  ui.drawCircleFilled(center, 6 * scale, C.outline, 16)
  centeredText('0', 10 * scale, U.polar(center, radius, startAngle), C.secondary)
  centeredText(string.format('%.1f', state.turboDisplayMax or 1), 10 * scale,
    U.polar(center, radius, endAngle), C.secondary)
  centeredText('BOOST', 11 * scale, center + vec2(0, 28 * scale), C.secondary)
end

local function drawRpmDial(origin, scale, state, settings, backdropOpacity)
  local center = point(origin, scale, Layout.rightCenterX, Layout.dialCenterY)
  local radius = Layout.dialRadius * scale
  ui.drawCircleFilled(center, radius, withAlpha(C.panel, math.min(0.96, backdropOpacity + 0.18)), 72)
  ui.drawCircle(center, radius, C.metal, 72, 4 * scale)
  ui.drawCircle(center, radius - 8 * scale, C.outline, 72, 2 * scale)
  ui.drawCircle(center, radius - 16 * scale, C.outlineDim, 72, 2 * scale)

  local maximum = math.max((state.rpmGaugeLimiter or 8000) / 1000, 1)
  local labels = { 0, maximum * 0.25, maximum * 0.5, maximum * 0.75, maximum }
  local needleFraction = settings.gt7RpmNeedleMode == 'analog'
    and state.gt7RpmNeedleNormalized or U.clamp(state.rpmGaugeNormalized or 0, 0, 1)
  drawDialTicks(center, scale, labels, function(value)
    local rounded = U.round(value)
    return math.abs(value - rounded) < 0.01 and tostring(rounded) or string.format('%.1f', value)
  end,
    needleFraction, state, settings, true, settings.gt7RpmNeedleMode)
  centeredText('x1000 RPM', 14 * scale, center + vec2(0, -25 * scale), C.secondary)
  drawBoostGauge(origin, scale, state)
end

local function drawFfb(origin, scale, state)
  local center = point(origin, scale, Layout.ffbCenterX, Layout.ffbCenterY)
  local fraction = state.ffbAvailable and U.clamp(state.ffbNeedle or 0, 0, 1) or 0
  local filled = math.floor(fraction * Layout.ffbSegments + 0.5)
  local span = (Layout.ffbEnd - Layout.ffbStart) / Layout.ffbSegments
  for i = 1, Layout.ffbSegments do
    local a1 = Layout.ffbStart + (i - 1) * span + 0.014
    local a2 = Layout.ffbStart + i * span - 0.014
    local active = i <= filled
    local fraction = i / Layout.ffbSegments
    local color = C.inactive
    if active then
      color = fraction >= 0.9 and (state.ffbClipping and C.red or C.amber) or C.cyan
    elseif fraction >= 0.9 then
      color = C.redDim
    end
    drawEllipseSegment(center, Layout.ffbRadiusX * scale, Layout.ffbRadiusY * scale,
      a1, a2, color, 12 * scale, 5)
  end

  local angle = Layout.ffbStart + (Layout.ffbEnd - Layout.ffbStart) * fraction
  local pivot = center + vec2(0, Layout.ffbNeedlePivotOffsetY * scale)
  local tip = ellipsePoint(center, (Layout.ffbRadiusX - 8) * scale,
    (Layout.ffbRadiusY - 8) * scale, angle)
  local needleColor = not state.ffbAvailable and C.outlineSoft
    or (state.ffbClipping and C.red or (fraction >= 0.9 and C.amber or C.primary))
  drawLine(pivot, tip, withAlpha(C.backlight, 0.16), 10 * scale)
  drawLine(pivot, tip, C.outlineDim, 6 * scale)
  drawLine(pivot, tip, needleColor, 3 * scale)
  ui.drawCircleFilled(pivot, 10 * scale, C.panelRaised, 20)
  ui.drawCircle(pivot, 10 * scale, C.outlineSoft, 20, 2 * scale)
  ui.drawCircleFilled(pivot, 3.5 * scale, needleColor, 16)
end

local function drawPedalBar(origin, scale, x, value, activeColor)
  local segmentCount = Layout.pedalSegments
  local gap = Layout.pedalGap * scale
  local segmentHeight = (Layout.pedalHeight * scale - gap * (segmentCount - 1)) / segmentCount
  local filled = math.floor(U.clamp(value or 0, 0, 1) * segmentCount + 0.5)

  for i = 1, segmentCount do
    local y = Layout.pedalTop * scale + (segmentCount - i) * (segmentHeight + gap)
    local topLeft = origin + vec2(x * scale, y)
    ui.drawRectFilled(topLeft, topLeft + vec2(Layout.pedalWidth * scale, segmentHeight),
      i <= filled and activeColor or C.inactive)
  end
end

local function drawFlagLamps(origin, scale, x, state, settings)
  local color = flagColor(state)
  local lit = color ~= nil and flagBlinkOn(state, settings)
  local lampColor = lit and color or C.inactive
  local centerX = x + Layout.pedalWidth / 2
  for offset = -1, 1, 2 do
    local center = point(origin, scale, centerX + offset * Layout.flagLampSpacing / 2, Layout.flagLampY)
    if lit then ui.drawCircleFilled(center, 8 * scale, withAlpha(color, 0.16), 18) end
    ui.drawCircleFilled(center, Layout.flagLampRadius * scale, lampColor, 18)
  end
end

local function drawPedalsAndFlagLights(origin, scale, state, settings)
  drawPedalBar(origin, scale, Layout.brakeX, state.brake, C.red)
  drawPedalBar(origin, scale, Layout.throttleX, state.throttle, C.cyan)
  drawFlagLamps(origin, scale, Layout.brakeX, state, settings)
  drawFlagLamps(origin, scale, Layout.throttleX, state, settings)
end

local function drawBrakeIcon(center, scale, color)
  ui.drawCircle(center, 12 * scale, color, 24, 2 * scale)
  drawArc(center, 17 * scale, math.rad(120), math.rad(240), color, 2 * scale, 12)
  drawArc(center, 17 * scale, math.rad(-60), math.rad(60), color, 2 * scale, 12)
  centeredText('!', 15 * scale, center, color)
end

local function drawLightIcon(center, scale, color)
  ui.drawRectFilled(center + vec2(-12 * scale, -8 * scale), center + vec2(-4 * scale, 8 * scale), color)
  for i = -1, 1 do
    drawLine(center + vec2(1 * scale, i * 5 * scale), center + vec2(16 * scale, i * 8 * scale), color, 2 * scale)
  end
end

local function drawEngineIcon(center, scale, color)
  -- This icon uses screen-space lines to stay crisp at small HUD scales.
  drawLine(center + vec2(-14 * scale, -8 * scale), center + vec2(10 * scale, -8 * scale), color, 2 * scale)
  drawLine(center + vec2(10 * scale, -8 * scale), center + vec2(15 * scale, -2 * scale), color, 2 * scale)
  drawLine(center + vec2(15 * scale, -2 * scale), center + vec2(15 * scale, 9 * scale), color, 2 * scale)
  drawLine(center + vec2(15 * scale, 9 * scale), center + vec2(-14 * scale, 9 * scale), color, 2 * scale)
  drawLine(center + vec2(-14 * scale, 9 * scale), center + vec2(-14 * scale, -8 * scale), color, 2 * scale)
  drawLine(center + vec2(-8 * scale, -8 * scale), center + vec2(-8 * scale, -13 * scale), color, 2 * scale)
  drawLine(center + vec2(-8 * scale, -13 * scale), center + vec2(2 * scale, -13 * scale), color, 2 * scale)
end

local function drawStatusPod(origin, scale, x, label, available, active, color, icon, backdropOpacity)
  local center = point(origin, scale, x, 443)
  local fill = withAlpha(C.panelRaised, math.max(0.82, math.min(0.98, backdropOpacity + 0.18)))
  ui.drawCircleFilled(center, 23 * scale, fill, 28)
  local iconColor = not available and C.outlineDim or (active and color or C.secondary)
  if icon then icon(center, scale, iconColor) else centeredText(label, 11 * scale, center, iconColor) end
end

local function drawStatusStrips(origin, scale, state, settings, backdropOpacity)
  local fuelLow = state.fuel ~= nil and (state.fuelNormalized or 0) < 0.15
  drawStatusPod(origin, scale, 88, 'FUEL', state.fuel ~= nil, fuelLow, C.red, nil, backdropOpacity)
  drawStatusPod(origin, scale, 146, 'TC', state.tcSupported, state.tcActive == true,
    C.amber, nil, backdropOpacity)
  drawStatusPod(origin, scale, 304, 'PIT', true, state.pitLane or state.pitLimiter == true,
    C.amber, nil, backdropOpacity)
  drawStatusPod(origin, scale, 362, 'LIM', state.pitLimiter ~= nil,
    state.pitLimiter == true, C.amber, nil, backdropOpacity)

  drawStatusPod(origin, scale, 1078, 'ABS', state.absSupported,
    state.absActive == true or state.absLevel == 0, state.absLevel == 0 and C.red or C.amber,
    nil, backdropOpacity)
  local lightsAvailable = settings.showLights and state.lightsAvailable
  drawStatusPod(origin, scale, 1136, 'L', lightsAvailable, lightsAvailable and state.headlights == true,
    state.highBeams and C.amber or C.cyan, lightsAvailable and drawLightIcon or nil, backdropOpacity)
  drawStatusPod(origin, scale, 1294, 'P', true, state.handbrake > 0.05,
    C.red, drawBrakeIcon, backdropOpacity)
  drawStatusPod(origin, scale, 1352, 'ENG', state.engineLifeLeft ~= nil, state.engineWarning,
    C.red, drawEngineIcon, backdropOpacity)
end

local function drawDebug(origin, scale, state, width, height)
  local rows = {
    string.format('FIT %.0fx%.0f', width, height),
    string.format('RPM %.0f / %.0f', state.rpm or 0, state.rpmDisplayLimiter or 0),
    string.format('FFB RAW %+.3f', state.ffbSigned or 0),
    string.format('FFB UI %d%% %s', state.ffbPercent or 0, state.ffbAvailable and 'FINAL' or 'N/A'),
    string.format('TURBO %s %.2f', state.turboAvailable and 'YES' or 'NO', state.turboBoost or 0)
  }
  local topLeft = point(origin, scale, 445, 305)
  ui.drawRectFilled(topLeft, topLeft + vec2(155 * scale, 78 * scale), withAlpha(C.debug, 0.92))
  for i, row in ipairs(rows) do
    ui.dwriteDrawText(row, 9 * scale, topLeft + vec2(7 * scale, (i * 13 - 9) * scale), C.primary)
  end
end

function M.draw(state, settings)
  C = Theme.get(settings.theme)
  local width = ui.windowWidth()
  local height = ui.windowHeight()
  local fittedScale = math.min(width / Layout.width, height / Layout.height)
  -- Window resizing is the primary scale control. The persisted 0.72 default
  -- is neutral here, while the shared slider remains available as a restrained
  -- fine adjustment around the mouse-controlled fitted size.
  local sliderScale = 1 + ((settings.hudScale or 0.72) - 0.72) * 0.6
  local scale = fittedScale * U.clamp(sliderScale, 0.82, 1.28)
  local designWidth = Layout.width * scale
  local designHeight = Layout.height * scale
  local origin = vec2((width - designWidth) / 2, (height - designHeight) / 2)
  local backdropOpacity = settings.backgroundOpacity or 0.72

  ui.pushStyleVarAlpha(settings.opacity or 1)
  ui.pushDWriteFont(Theme.fonts.utility)

  drawRpmBar(origin, scale, state, settings)
  drawCenterReadout(origin, scale, state, settings)
  drawSpeedDial(origin, scale, state, settings, backdropOpacity)
  drawRpmDial(origin, scale, state, settings, backdropOpacity)
  drawPedalsAndFlagLights(origin, scale, state, settings)
  drawFfb(origin, scale, state)
  drawStatusStrips(origin, scale, state, settings, backdropOpacity)
  if settings.debug then drawDebug(origin, scale, state, width, height) end

  ui.popDWriteFont()
  ui.popStyleVar(1)
end

return M
