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

  -- Keep normal road temperatures from reading as cold blue. A tyre around
  -- 80–85% of its optimum should already transition clearly toward green.
  tyreColdRatio = 0.70,
  tyreOptimumLowRatio = 0.86,
  tyreOptimumHighRatio = 1.08,
  tyreHotRatio = 1.24,

  conditionWarn = 0.35,
  conditionDanger = 0.72,
  punctureBlinkPeriod = 0.18
}
