-- All coordinates are in a 620 x 620 design space. The renderer scales this
-- space uniformly. Keep the visual proportions here and tune its final size
-- from manifest.ini or the HUD scale setting.
return {
  baseSize = 620,
  centerX = 310,
  centerY = 304,

  outerRadius = 286,
  innerRadius = 268,
  dialRadius = 256,
  rpmRadius = 245,
  rpmSegments = 36,
  rpmStart = math.rad(-210),
  rpmEnd = math.rad(30),

  turnIndicatorRadius = 230,
  turnIndicatorScale = 0.80,

  coreFrameHalfWidth = 132,
  coreFrameHalfHeight = 149,
  coreFrameChamfer = 22,
  coreHalfWidth = 108,
  coreHalfHeight = 112,
  coreChamfer = 18,
  coreOffsetY = 4,

  steeringY = 177,
  steeringHalfWidth = 66,

  pedalY = 247,
  pedalHeight = 154,
  pedalWidth = 25,
  brakeX = 132,
  throttleX = 463,

  speedY = 111,
  speedUnitY = 144,
  gearY = 276,
  gearFontSize = 148,
  rpmY = 401,
  rpmLabelY = 431,

  clutchLabelY = 454,
  clutchX = 269,
  clutchY = 468,
  clutchWidth = 82,
  clutchHeight = 6,

  electronicsX = 181,
  electronicsY = 478,
  electronicsWidth = 59,
  electronicsHeight = 54,
  electronicsGap = 7,

  shelfTopY = 463,
  shelfBottomY = 545,
  shelfTopHalfWidth = 154,
  shelfBottomHalfWidth = 128,

  warningY = 561
}
