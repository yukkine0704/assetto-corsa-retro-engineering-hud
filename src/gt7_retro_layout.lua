-- Dedicated panoramic design space. The renderer always fits this rectangle
-- uniformly into the current CSP app window, so no coordinate depends on the
-- user's resolution and the cluster can safely coexist with the square dials.
return {
  width = 1440,
  height = 500,

  leftCenterX = 220,
  rightCenterX = 1220,
  dialCenterY = 258,
  dialRadius = 174,
  tickRadius = 155,
  needleLength = 124,
  gaugeStart = math.rad(140),
  gaugeEnd = math.rad(400),

  centerLeft = 420,
  centerRight = 1020,
  centerTop = 91,
  centerBottom = 285,

  rpmLeft = 448,
  rpmRight = 992,
  rpmTop = 82,
  rpmHeight = 24,
  rpmSegments = 34,
  rpmGap = 3,

  ffbCenterX = 720,
  ffbCenterY = 408,
  ffbRadiusX = 150,
  ffbRadiusY = 72,
  ffbStart = math.rad(195),
  ffbEnd = math.rad(345),
  ffbSegments = 20,

  indicatorPeriod = 0.42,
  shiftBlinkPeriod = 0.14,
  redlineBlinkPeriod = 0.12
}
