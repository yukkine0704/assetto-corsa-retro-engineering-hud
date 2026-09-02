-- All coordinates are in a 620 x 620 design space. The renderer scales this
-- space uniformly, so visual iteration only needs this file.
return {
  baseSize = 620,
  centerX = 310,
  centerY = 304,

  outerRadius = 286,
  innerRadius = 266,
  dialRadius = 252,
  rpmRadius = 245,
  rpmSegments = 36,
  rpmStart = math.rad(-210),
  rpmEnd = math.rad(30),

  steeringY = 180,
  steeringHalfWidth = 76,

  pedalY = 238,
  pedalHeight = 172,
  pedalWidth = 28,
  brakeX = 122,
  throttleX = 470,

  speedY = 104,
  speedUnitY = 140,
  gearY = 260,
  gearFontSize = 136,
  rpmY = 404,
  rpmLabelY = 445,

  clutchLabelY = 466,
  clutchX = 269,
  clutchY = 481,
  clutchWidth = 82,
  clutchHeight = 6,

  electronicsX = 112,
  electronicsY = 508,
  electronicsWidth = 86,
  electronicsHeight = 66,
  electronicsGap = 8,

  warningY = 592
}
