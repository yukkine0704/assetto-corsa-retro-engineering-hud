local M = {}

M.values = ac.storage({
  hudScale = 1.0,
  opacity = 0.96,
  speedUnit = 'km/h',
  rpmWarningFraction = 0.86,
  rpmRedlineFraction = 0.96,
  fallbackRpm = 8000,
  showClutch = true,
  showLights = true,
  showTcAbsLevels = true,
  showSteering = true,
  debug = false
})

local function checkbox(label, key)
  if ui.checkbox(label, M.values[key]) then
    M.values[key] = not M.values[key]
  end
end

function M.draw()
  ui.header('Retro Engineering HUD')
  ui.text('v0.1  /  central driving dial')
  ui.separator()

  M.values.hudScale = ui.slider('HUD scale', M.values.hudScale, 0.65, 1.15, '%.2fx', 2)
  M.values.opacity = ui.slider('Opacity', M.values.opacity, 0.35, 1.0, '%.0f%%', 2)

  if ui.button('Speed unit: ' .. M.values.speedUnit) then
    M.values.speedUnit = M.values.speedUnit == 'km/h' and 'mph' or 'km/h'
  end

  ui.separator()
  ui.text('RPM behavior')
  M.values.rpmWarningFraction = ui.slider(
    'Warning threshold', M.values.rpmWarningFraction, 0.70, 0.98, '%.0f%%', 2)
  M.values.rpmRedlineFraction = ui.slider(
    'Redline threshold', M.values.rpmRedlineFraction, 0.82, 1.0, '%.0f%%', 2)
  M.values.fallbackRpm = ui.slider(
    'Fallback RPM', M.values.fallbackRpm, 4000, 16000, '%.0f rpm', 0)

  ui.separator()
  ui.text('Display')
  checkbox('Show steering marker', 'showSteering')
  checkbox('Show clutch', 'showClutch')
  checkbox('Show lights', 'showLights')
  checkbox('Show TC / ABS levels', 'showTcAbsLevels')
  checkbox('Developer debug view', 'debug')

  ui.separator()
  ui.textWrapped('The main dial remains transparent outside its instrument surface. Resize or move the app through the normal AC app controls.')
end

return M
