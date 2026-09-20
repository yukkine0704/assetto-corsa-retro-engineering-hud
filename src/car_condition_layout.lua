-- Compact portrait design space for the independent car-condition window.
-- The renderer fits it uniformly, keeping the car and tyre proportions intact.
return {
  width = 240,
  height = 260,

  carCenterX = 120,
  frontWheelY = 68,
  rearWheelY = 178,
  leftWheelX = 38,
  rightWheelX = 202,
  tyreWidth = 22,
  tyreHeight = 54,

  tyreColdRatio = 0.78,
  tyreOptimumLowRatio = 0.94,
  tyreOptimumHighRatio = 1.08,
  tyreHotRatio = 1.24,

  conditionWarn = 0.35,
  conditionDanger = 0.72,
  punctureBlinkPeriod = 0.18
}
