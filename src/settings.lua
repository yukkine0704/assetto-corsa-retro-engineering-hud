local M = {}

M.values = ac.storage({
  layoutVersion = 1,
  hudScale = 0.72,
  opacity = 1.0,
  backgroundOpacity = 0.72,
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

-- Existing installs have a saved v0.1 scale. Keep a user-selected smaller
-- value, but migrate oversized values to the compact v0.2 presentation once.
if (M.values.layoutVersion or 1) < 3 then
  M.values.hudScale = math.min(M.values.hudScale or 0.72, 0.72)
  M.values.backgroundOpacity = math.max(M.values.backgroundOpacity or 0.72, 0.72)
  M.values.layoutVersion = 3
end

local function checkbox(label, key)
  if ui.checkbox(label, M.values[key]) then
    M.values[key] = not M.values[key]
  end
end

function M.draw()
  ui.header('Retro Engineering HUD')
  ui.text('v0.2  /  central driving dial')
  ui.separator()

  M.values.hudScale = ui.slider('HUD scale', M.values.hudScale, 0.55, 1.15, '%.2fx', 2)
  M.values.backgroundOpacity = ui.slider('Backdrop opacity', M.values.backgroundOpacity, 0.18, 0.82, '%.0f%%', 2)
  M.values.opacity = ui.slider('Instrument opacity', M.values.opacity, 0.55, 1.0, '%.0f%%', 2)

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
  ui.textWrapped('The dial is transparent outside its circular surface. Adjust its compact scale and frosted backdrop here; resize or move it through the normal AC app controls.')
end

return M
