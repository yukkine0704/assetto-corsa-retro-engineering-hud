local Theme = require('src/theme')
local Layout = require('src/layout')
local U = require('src/utils')

local M = {}
local C = Theme.colors

local function point(origin, scale, x, y)
  return origin + vec2(x * scale, y * scale)
end

local function centeredText(text, size, center, color)
  local measured = ui.measureDWriteText(text, size)
  ui.dwriteDrawText(text, size, center - measured / 2, color)
end

local function drawArc(center, radius, startAngle, endAngle, color, width, segments)
  ui.pathClear()
  ui.pathArcTo(center, radius, startAngle, endAngle, segments or 32)
  ui.pathStroke(color, false, width)
end

local function drawLine(p1, p2, color, width)
  ui.drawLine(p1, p2, color, width)
end

local function drawOctagon(center, halfWidth, halfHeight, chamfer, fill, stroke, strokeWidth)
  local function p(x, y)
    return center + vec2(x, y)
  end

  ui.pathClear()
  ui.pathLineTo(p(-halfWidth + chamfer, -halfHeight))
  ui.pathLineTo(p(halfWidth - chamfer, -halfHeight))
  ui.pathLineTo(p(halfWidth, -halfHeight + chamfer))
  ui.pathLineTo(p(halfWidth, halfHeight - chamfer))
  ui.pathLineTo(p(halfWidth - chamfer, halfHeight))
  ui.pathLineTo(p(-halfWidth + chamfer, halfHeight))
  ui.pathLineTo(p(-halfWidth, halfHeight - chamfer))
  ui.pathLineTo(p(-halfWidth, -halfHeight + chamfer))
  ui.pathFillConvex(fill)

  ui.pathClear()
  ui.pathLineTo(p(-halfWidth + chamfer, -halfHeight))
  ui.pathLineTo(p(halfWidth - chamfer, -halfHeight))
  ui.pathLineTo(p(halfWidth, -halfHeight + chamfer))
  ui.pathLineTo(p(halfWidth, halfHeight - chamfer))
  ui.pathLineTo(p(halfWidth - chamfer, halfHeight))
  ui.pathLineTo(p(-halfWidth + chamfer, halfHeight))
  ui.pathLineTo(p(-halfWidth, halfHeight - chamfer))
  ui.pathLineTo(p(-halfWidth, -halfHeight + chamfer))
  ui.pathStroke(stroke, true, strokeWidth)
end

local function drawArrowBadge(center, direction, scale, active, backdrop)
  local d = direction
  local function p(x, y)
    return center + vec2(x * d * scale, y * scale)
  end

  local fill = active and C.cyanDim or backdrop
  local stroke = active and C.cyan or C.outline

  ui.pathClear()
  ui.pathLineTo(p(-38, -17))
  ui.pathLineTo(p(18, -17))
  ui.pathLineTo(p(38, 0))
  ui.pathLineTo(p(18, 17))
  ui.pathLineTo(p(-38, 17))
  ui.pathLineTo(p(-47, 0))
  ui.pathFillConvex(fill)

  ui.pathClear()
  ui.pathLineTo(p(-38, -17))
  ui.pathLineTo(p(18, -17))
  ui.pathLineTo(p(38, 0))
  ui.pathLineTo(p(18, 17))
  ui.pathLineTo(p(-38, 17))
  ui.pathLineTo(p(-47, 0))
  ui.pathStroke(stroke, true, 2.0 * scale)

  drawLine(p(-24, 0), p(17, 0), stroke, 3.2 * scale)
  drawLine(p(2, -9), p(17, 0), stroke, 3.2 * scale)
  drawLine(p(2, 9), p(17, 0), stroke, 3.2 * scale)
end

local function drawRpmArc(center, scale, state)
  local segmentCount = Layout.rpmSegments
  local span = (Layout.rpmEnd - Layout.rpmStart) / segmentCount
  local filled = math.floor(state.rpmNormalized * segmentCount + 0.5)

  drawArc(center, Layout.rpmRadius * scale, Layout.rpmStart, Layout.rpmEnd, C.outlineDim, 15 * scale, 72)

  for i = 1, segmentCount do
    local a1 = Layout.rpmStart + (i - 1) * span + 0.012
    local a2 = Layout.rpmStart + i * span - 0.012
    local fraction = i / segmentCount
    local color = C.inactive
    if i <= filled then
      if fraction >= state.rpmRedlineFraction then
        color = C.red
      elseif fraction >= state.rpmWarningFraction then
        color = C.amber
      else
        color = C.primary
      end
    end
    drawArc(center, Layout.rpmRadius * scale, a1, a2, color, 10 * scale, 5)
  end

  -- Major RPM index marks are intentionally sparse: peripheral readability
  -- beats a dense speedometer-like number ring.
  for i = 0, 9 do
    local angle = Layout.rpmStart + (Layout.rpmEnd - Layout.rpmStart) * i / 9
    local tickInner = U.polar(center, Layout.rpmRadius * scale - 18 * scale, angle)
    local tickOuter = U.polar(center, Layout.rpmRadius * scale - 8 * scale, angle)
    drawLine(tickInner, tickOuter, i >= 8 and C.red or C.outline, 2 * scale)
    local labelPosition = U.polar(center, Layout.rpmRadius * scale - 38 * scale, angle)
    centeredText(tostring(i), 22 * scale, labelPosition, i >= 8 and C.primary or C.secondary)
  end
end

local function drawSteering(center, origin, scale, state)
  if not state.showSteering then return end

  local y = point(origin, scale, Layout.centerX, Layout.steeringY).y
  local left = point(origin, scale, Layout.centerX - Layout.steeringHalfWidth, Layout.steeringY)
  local right = point(origin, scale, Layout.centerX + Layout.steeringHalfWidth, Layout.steeringY)
  drawLine(left, right, C.outlineSoft, 3 * scale)
  drawLine(point(origin, scale, Layout.centerX, Layout.steeringY - 8),
    point(origin, scale, Layout.centerX, Layout.steeringY + 8), C.primary, 2 * scale)

  local markerX = Layout.centerX + state.steeringInput * Layout.steeringHalfWidth
  ui.drawCircleFilled(point(origin, scale, markerX, Layout.steeringY), 5 * scale,
    math.abs(state.steeringInput) > 0.04 and C.cyan or C.primary, 18)

  local steeringLabel = state.steeringAngle and string.format('%+03d°', U.round(state.steeringAngle)) or 'INPUT'
  centeredText(steeringLabel, 9 * scale, point(origin, scale, Layout.centerX, Layout.steeringY + 15), C.secondary)
end

local function drawPedalBar(origin, scale, x, label, value, color, labelColor, inactiveColor, panelColor)
  local y = Layout.pedalY
  local width = Layout.pedalWidth
  local height = Layout.pedalHeight
  local segmentCount = 12
  local gap = 3 * scale
  local segmentHeight = (height * scale - gap * (segmentCount - 1)) / segmentCount
  local filled = math.floor(value * segmentCount + 0.5)

  local housingLeft = (x - 14) * scale
  local housingRight = (x + width + 14) * scale
  local housingTop = (y - 38) * scale
  local housingBottom = (y + height + 17) * scale
  local chamfer = 10 * scale

  ui.pathClear()
  ui.pathLineTo(origin + vec2(housingLeft + chamfer, housingTop))
  ui.pathLineTo(origin + vec2(housingRight - chamfer, housingTop))
  ui.pathLineTo(origin + vec2(housingRight, housingTop + chamfer))
  ui.pathLineTo(origin + vec2(housingRight, housingBottom - chamfer))
  ui.pathLineTo(origin + vec2(housingRight - chamfer, housingBottom))
  ui.pathLineTo(origin + vec2(housingLeft + chamfer, housingBottom))
  ui.pathLineTo(origin + vec2(housingLeft, housingBottom - chamfer))
  ui.pathLineTo(origin + vec2(housingLeft, housingTop + chamfer))
  ui.pathFillConvex(panelColor)

  ui.pathClear()
  ui.pathLineTo(origin + vec2(housingLeft + chamfer, housingTop))
  ui.pathLineTo(origin + vec2(housingRight - chamfer, housingTop))
  ui.pathLineTo(origin + vec2(housingRight, housingTop + chamfer))
  ui.pathLineTo(origin + vec2(housingRight, housingBottom - chamfer))
  ui.pathLineTo(origin + vec2(housingRight - chamfer, housingBottom))
  ui.pathLineTo(origin + vec2(housingLeft + chamfer, housingBottom))
  ui.pathLineTo(origin + vec2(housingLeft, housingBottom - chamfer))
  ui.pathLineTo(origin + vec2(housingLeft, housingTop + chamfer))
  ui.pathStroke(C.outlineSoft, true, 1.4 * scale)

  centeredText(label, 12 * scale, point(origin, scale, x + width / 2, y - 16), labelColor)
  for i = 1, segmentCount do
    local segmentY = y * scale + (segmentCount - i) * (segmentHeight + gap)
    local topLeft = origin + vec2(x * scale, segmentY)
    local bottomRight = topLeft + vec2(width * scale, segmentHeight)
    ui.drawRectFilled(topLeft, bottomRight, i <= filled and color or inactiveColor)
  end

  local tl = point(origin, scale, x, y)
  local tr = point(origin, scale, x + width, y)
  local br = point(origin, scale, x + width, y + height)
  local bl = point(origin, scale, x, y + height)
  drawLine(tl, tr, C.outlineSoft, 1.5 * scale)
  drawLine(tr, br, C.outlineSoft, 1.5 * scale)
  drawLine(br, bl, C.outlineSoft, 1.5 * scale)
  drawLine(bl, tl, C.outlineSoft, 1.5 * scale)
end

local function drawElectronicsShelf(origin, scale, panelColor)
  local cx = Layout.centerX * scale
  local top = Layout.shelfTopY * scale
  local bottom = Layout.shelfBottomY * scale
  local topHalf = Layout.shelfTopHalfWidth * scale
  local bottomHalf = Layout.shelfBottomHalfWidth * scale
  local notch = 10 * scale

  ui.pathClear()
  ui.pathLineTo(origin + vec2(cx - topHalf + notch, top))
  ui.pathLineTo(origin + vec2(cx + topHalf - notch, top))
  ui.pathLineTo(origin + vec2(cx + topHalf, top + notch))
  ui.pathLineTo(origin + vec2(cx + bottomHalf, bottom))
  ui.pathLineTo(origin + vec2(cx - bottomHalf, bottom))
  ui.pathLineTo(origin + vec2(cx - topHalf, top + notch))
  ui.pathFillConvex(panelColor)

  ui.pathClear()
  ui.pathLineTo(origin + vec2(cx - topHalf + notch, top))
  ui.pathLineTo(origin + vec2(cx + topHalf - notch, top))
  ui.pathLineTo(origin + vec2(cx + topHalf, top + notch))
  ui.pathLineTo(origin + vec2(cx + bottomHalf, bottom))
  ui.pathLineTo(origin + vec2(cx - bottomHalf, bottom))
  ui.pathLineTo(origin + vec2(cx - topHalf, top + notch))
  ui.pathStroke(C.outlineDim, true, 1.5 * scale)
end

local function drawClutch(origin, scale, state)
  centeredText('CLUTCH', 10 * scale, point(origin, scale, Layout.centerX, Layout.clutchLabelY), C.secondary)
  local tl = point(origin, scale, Layout.clutchX, Layout.clutchY)
  local br = tl + vec2(Layout.clutchWidth * scale, Layout.clutchHeight * scale)
  ui.drawRectFilled(tl, br, C.inactive)
  ui.drawRectFilled(tl, tl + vec2(Layout.clutchWidth * scale * state.clutch, Layout.clutchHeight * scale), C.cyan)
end

local function drawHeadlightIcon(center, scale, state)
  local color = state.headlights and (state.highBeams and C.amber or C.cyan) or C.secondary
  ui.drawRectFilled(center - vec2(6 * scale, 8 * scale), center + vec2(1 * scale, 8 * scale), color)
  for i = -1, 1 do
    drawLine(center + vec2(6 * scale, i * 5 * scale), center + vec2(21 * scale, i * 8 * scale), color, 2 * scale)
  end
end

local function drawCell(origin, scale, x, label, value, active, valueColor, drawIcon, panel, panelRaised)
  local y = Layout.electronicsY
  local w = Layout.electronicsWidth
  local h = Layout.electronicsHeight
  local center = point(origin, scale, x + w / 2, y + h / 2)
  local left = x * scale
  local top = y * scale
  local right = (x + w) * scale
  local bottom = (y + h) * scale
  local chamfer = 6 * scale

  ui.pathClear()
  ui.pathLineTo(origin + vec2(left + chamfer, top))
  ui.pathLineTo(origin + vec2(right - chamfer, top))
  ui.pathLineTo(origin + vec2(right, top + chamfer))
  ui.pathLineTo(origin + vec2(right, bottom - chamfer))
  ui.pathLineTo(origin + vec2(right - chamfer, bottom))
  ui.pathLineTo(origin + vec2(left + chamfer, bottom))
  ui.pathLineTo(origin + vec2(left, bottom - chamfer))
  ui.pathLineTo(origin + vec2(left, top + chamfer))
  ui.pathFillConvex(active and panelRaised or panel)

  ui.pathClear()
  ui.pathLineTo(origin + vec2(left + chamfer, top))
  ui.pathLineTo(origin + vec2(right - chamfer, top))
  ui.pathLineTo(origin + vec2(right, top + chamfer))
  ui.pathLineTo(origin + vec2(right, bottom - chamfer))
  ui.pathLineTo(origin + vec2(right - chamfer, bottom))
  ui.pathLineTo(origin + vec2(left + chamfer, bottom))
  ui.pathLineTo(origin + vec2(left, bottom - chamfer))
  ui.pathLineTo(origin + vec2(left, top + chamfer))
  ui.pathStroke(active and C.cyan or C.outlineSoft, true, (active and 2.2 or 1.4) * scale)

  centeredText(label, 10 * scale, point(origin, scale, x + w / 2, y + 15), active and C.primary or C.secondary)
  if drawIcon then
    drawIcon(center + vec2(0, 11 * scale), scale)
  else
    centeredText(value, 25 * scale, point(origin, scale, x + w / 2, y + 42), valueColor or C.primary)
  end
end

local function drawWarning(origin, scale, state)
  local center = point(origin, scale, Layout.centerX, Layout.warningY)
  local radius = 10 * scale
  local p1 = center + vec2(0, -radius)
  local p2 = center + vec2(radius * 0.88, radius)
  local p3 = center + vec2(-radius * 0.88, radius)
  local color = (state.rpmRedline or state.handbrake > 0.9) and C.amber or C.outlineSoft
  drawLine(p1, p2, color, 2 * scale)
  drawLine(p2, p3, color, 2 * scale)
  drawLine(p3, p1, color, 2 * scale)
  drawLine(center + vec2(0, -3 * scale), center + vec2(0, 4 * scale), color, 2 * scale)
  ui.drawCircleFilled(center + vec2(0, 7 * scale), 1.3 * scale, color, 10)
end

local function drawScrews(center, scale)
  local left = U.polar(center, 240 * scale, math.rad(143))
  local right = U.polar(center, 240 * scale, math.rad(37))
  local function drawScrew(screw)
    ui.drawCircleFilled(screw, 7 * scale, C.panelRaised, 24)
    ui.drawCircle(screw, 7 * scale, C.outlineSoft, 24, 1.2 * scale)
    drawLine(screw - vec2(2 * scale, 2 * scale), screw + vec2(2 * scale, 2 * scale), C.outline, 1.4 * scale)
  end
  drawScrew(left)
  drawScrew(right)
end

local function drawDebug(origin, scale, state)
  local x = 14 * scale
  local y = 14 * scale
  local w = 230 * scale
  local h = 156 * scale
  ui.drawRectFilled(origin + vec2(x, y), origin + vec2(x + w, y + h), C.debug)
  local rows = {
    string.format('SPD  %s %s', state.speedText, state.speedUnit),
    string.format('GEAR %s   RPM %s', state.gearText, state.rpmText),
    string.format('LIM  %s (%s)', state.rpmLimiter and string.format('%.0f', state.rpmLimiter) or 'n/a', state.rpmSource),
    string.format('STR  %+.2f  %s', state.steeringInput, state.steeringAngle and string.format('%+.0f°', state.steeringAngle) or 'n/a'),
    string.format('PED  T %.2f  B %.2f  C %.2f', state.throttle, state.brake, state.clutch),
    string.format('TC   %s / %s', state.tcLevel and tostring(state.tcLevel) or 'n/a', U.boolText(state.tcActive)),
    string.format('ABS  %s / %s', state.absLevel and tostring(state.absLevel) or 'n/a', U.boolText(state.absActive)),
    string.format('LGT  %s  PIT %s', U.boolText(state.headlights), U.boolText(state.pitLimiter))
  }
  for i, row in ipairs(rows) do
    ui.dwriteDrawText(row, 10 * scale, origin + vec2(x + 9 * scale, y + (i - 1) * 17 * scale + 6 * scale), C.primary)
  end
end

function M.draw(state, settings)
  local width = ui.windowWidth()
  local height = ui.windowHeight()
  local fittedScale = math.min(width, height) / Layout.baseSize
  local scale = fittedScale * settings.hudScale
  local designSize = Layout.baseSize * scale
  local origin = vec2((width - designSize) / 2, (height - designSize) / 2)
  local center = point(origin, scale, Layout.centerX, Layout.centerY)
  local backdropOpacity = settings.backgroundOpacity or 0.72
  local outerSurface = Theme.withAlpha(C.void, backdropOpacity * 0.82)
  local innerSurface = Theme.withAlpha(C.surface, backdropOpacity)
  local coreSurface = Theme.withAlpha(C.panel, math.min(0.92, backdropOpacity + 0.16))
  local raisedSurface = Theme.withAlpha(C.panelRaised, math.min(0.94, backdropOpacity + 0.22))
  local inactiveSurface = Theme.withAlpha(C.inactive, backdropOpacity * 0.8)

  ui.pushStyleVarAlpha(settings.opacity)
  ui.pushDWriteFont(Theme.fonts.utility)

  ui.drawCircleFilled(center, Layout.outerRadius * scale, outerSurface, 96)
  ui.drawCircleFilled(center, Layout.innerRadius * scale, innerSurface, 96)
  ui.drawCircle(center, Layout.outerRadius * scale, C.outlineSoft, 96, 3 * scale)
  ui.drawCircle(center, (Layout.outerRadius - 7) * scale, C.outline, 96, 2 * scale)
  ui.drawCircle(center, (Layout.outerRadius - 14) * scale, C.outlineDim, 96, 5 * scale)
  ui.drawCircle(center, Layout.innerRadius * scale, C.outline, 96, 1.5 * scale)

  drawRpmArc(center, scale, state)

  local leftArrow = U.polar(center, Layout.turnIndicatorRadius * scale, math.rad(-140))
  local rightArrow = U.polar(center, Layout.turnIndicatorRadius * scale, math.rad(-40))
  local leftActive = state.hazardLights or state.leftIndicator and state.indicatorPhase ~= false
  local rightActive = state.hazardLights or state.rightIndicator and state.indicatorPhase ~= false
  drawArrowBadge(leftArrow, -1, scale * Layout.turnIndicatorScale, leftActive == true, raisedSurface)
  drawArrowBadge(rightArrow, 1, scale * Layout.turnIndicatorScale, rightActive == true, raisedSurface)

  drawOctagon(center, Layout.coreFrameHalfWidth * scale, Layout.coreFrameHalfHeight * scale,
    Layout.coreFrameChamfer * scale, Theme.withAlpha(C.panel, backdropOpacity * 0.24), C.outlineSoft, 1.4 * scale)
  drawOctagon(center + vec2(0, Layout.coreOffsetY * scale), Layout.coreHalfWidth * scale,
    Layout.coreHalfHeight * scale, Layout.coreChamfer * scale, coreSurface, C.cyanDim, 2 * scale)
  drawSteering(center, origin, scale, {
    showSteering = settings.showSteering,
    steeringInput = state.steeringInput,
    steeringAngle = state.steeringAngle
  })

  drawPedalBar(origin, scale, Layout.brakeX, 'BRAKE', state.brake, C.red, C.primary,
    inactiveSurface, Theme.withAlpha(C.panel, backdropOpacity * 0.62))
  drawPedalBar(origin, scale, Layout.throttleX, 'THROTTLE', state.throttle, C.cyan, C.primary,
    inactiveSurface, Theme.withAlpha(C.panel, backdropOpacity * 0.62))

  centeredText(state.speedText, 42 * scale, point(origin, scale, Layout.centerX, Layout.speedY), C.primary)
  centeredText(state.speedUnit, 14 * scale, point(origin, scale, Layout.centerX, Layout.speedUnitY), C.secondary)
  centeredText(state.gearText, Layout.gearFontSize * scale, point(origin, scale, Layout.centerX, Layout.gearY), state.rpmRedline and C.amber or C.primary)
  centeredText(state.rpmText, 39 * scale, point(origin, scale, Layout.centerX, Layout.rpmY), state.rpmWarning and C.amber or C.primary)
  centeredText('RPM', 13 * scale, point(origin, scale, Layout.centerX, Layout.rpmLabelY), C.secondary)

  drawElectronicsShelf(origin, scale, Theme.withAlpha(C.panelRaised, backdropOpacity * 0.72))

  if settings.showClutch then drawClutch(origin, scale, state) end

  local cellX = Layout.electronicsX
  local tcValue = state.tcLevel and (settings.showTcAbsLevels and tostring(state.tcLevel) or 'ON') or '—'
  local absValue = state.absLevel and (settings.showTcAbsLevels and tostring(state.absLevel) or 'ON') or '—'
  drawCell(origin, scale, cellX, 'TC', tcValue, state.tcActive == true, state.tcActive and C.amber or C.primary,
    nil, coreSurface, raisedSurface)
  cellX = cellX + Layout.electronicsWidth + Layout.electronicsGap
  drawCell(origin, scale, cellX, 'ABS', absValue, state.absActive == true, state.absActive and C.amber or C.primary,
    nil, coreSurface, raisedSurface)
  cellX = cellX + Layout.electronicsWidth + Layout.electronicsGap
  local lightsShown = settings.showLights and state.lightsAvailable
  drawCell(origin, scale, cellX, 'LIGHTS', lightsShown and 'ON' or '—', lightsShown and state.headlights == true,
    state.highBeams and C.amber or C.cyan, lightsShown and function(centerPosition, iconScale)
      drawHeadlightIcon(centerPosition, iconScale, state)
    end or nil, coreSurface, raisedSurface)
  cellX = cellX + Layout.electronicsWidth + Layout.electronicsGap
  local pitValue = state.pitLimiter ~= nil and (state.pitLimiter and 'ON' or '—') or (state.pitLane and 'P' or '—')
  drawCell(origin, scale, cellX, 'PIT', pitValue, state.pitLimiter == true or state.pitLane,
    state.pitLimiter and C.amber or C.primary, nil, coreSurface, raisedSurface)

  drawWarning(origin, scale, state)
  drawScrews(center, scale)

  if settings.debug then drawDebug(origin, scale, state) end

  ui.popDWriteFont()
  ui.popStyleVar(1)
end

return M
