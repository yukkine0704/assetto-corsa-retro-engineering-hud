-- All coordinates are in a 620 x 620 design space. The renderer scales this
-- space uniformly. Keep the visual proportions here and tune its final size
-- from manifest.ini or the HUD scale setting.
return {
  baseSize = 620,
  centerX = 310,
  centerY = 304,
  viewportOffsetY = -10,

  outerRadius = 286,
  innerRadius = 260,
  dialRadius = 256,
  rpmRadius = 245,
  rpmTrackWidth = 21,
  rpmSegmentWidth = 14,
  rpmSegments = 36,
  rpmStart = math.rad(-210),
  rpmEnd = math.rad(30),

  turnIndicatorRadius = 270,
  turnIndicatorAngle = math.rad(6),
  turnCutHalfLength = 20,
  turnCutHalfDepth = 8,
  indicatorBlinkPeriod = 0.42,
  shiftBlinkPeriod = 0.18,

  coreFrameHalfWidth = 112,
  coreFrameHalfHeight = 142,
  coreFrameChamfer = 22,
  coreHalfWidth = 100,
  coreHalfHeight = 108,
  coreChamfer = 18,
  coreOffsetY = 4,

  steeringY = 177,
  steeringHalfWidth = 66,

  pedalY = 235,
  pedalHeight = 148,
  pedalWidth = 25,
  brakeX = 145,
  throttleX = 440,

  speedY = 111,
  speedUnitY = 144,
  gearY = 272,
  gearFontSize = 148,
  rpmY = 392,
  rpmLabelY = 419,

  clutchLabelY = 441,
  clutchX = 269,
  clutchY = 454,
  clutchWidth = 82,
  clutchHeight = 6,

  electronicsX = 181,
  electronicsY = 477,
  electronicsWidth = 59,
  electronicsHeight = 56,
  electronicsGap = 7,

  shelfTopY = 462,
  shelfBottomY = 555,
  shelfTopHalfWidth = 154,
  shelfBottomHalfWidth = 128,

  warningY = 571
}
