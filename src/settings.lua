local M = {}

M.lastChange = 'Ready'

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
    M.lastChange = label
  end
end

local function slider(label, key, minimum, maximum, format)
  local value, changed = ui.slider(label, M.values[key], minimum, maximum, format, 1)
  if changed then
    M.values[key] = value
    M.lastChange = label
  end
end

local function resetVisualSettings()
  M.values.hudScale = 0.72
  M.values.backgroundOpacity = 0.72
  M.values.opacity = 1.0
  M.lastChange = 'Visual settings reset'
end

function M.draw()
  ui.header('Retro Engineering HUD')
  ui.text('v0.2  /  central driving dial')
  ui.separator()

  slider('HUD scale', 'hudScale', 0.55, 1.15, '%.2fx')
  slider('Backdrop opacity', 'backgroundOpacity', 0.18, 0.82, '%.0f%%')
  slider('Instrument opacity', 'opacity', 0.55, 1.0, '%.0f%%')

  if ui.button('Reset visual settings') then
    resetVisualSettings()
  end

  if ui.button('Speed unit: ' .. M.values.speedUnit) then
    M.values.speedUnit = M.values.speedUnit == 'km/h' and 'mph' or 'km/h'
    M.lastChange = 'Speed unit'
  end

  ui.separator()
  ui.text('RPM behavior')
  slider('Warning threshold', 'rpmWarningFraction', 0.70, 0.98, '%.0f%%')
  slider('Redline threshold', 'rpmRedlineFraction', 0.82, 1.0, '%.0f%%')
  slider('Fallback RPM', 'fallbackRpm', 4000, 16000, '%.0f rpm')

  ui.separator()
  ui.text('Display')
  checkbox('Show steering marker', 'showSteering')
  checkbox('Show clutch', 'showClutch')
  checkbox('Show lights', 'showLights')
  checkbox('Show TC / ABS levels', 'showTcAbsLevels')
  checkbox('Developer debug view', 'debug')

  ui.separator()
  ui.text('Last change: ' .. M.lastChange)
  ui.textWrapped('The dial is transparent outside its circular surface. Adjust its compact scale and frosted backdrop here; resize or move it through the normal AC app controls.')
end

return M
