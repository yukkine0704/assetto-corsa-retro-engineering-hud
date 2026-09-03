local M = {}

M.lastChange = 'Ready'

M.values = ac.storage({
  layoutVersion = 1,
  hudScale = 0.72,
  opacity = 1.0,
  backgroundOpacity = 0.72,
  speedUnit = 'km/h',
  instrumentMode = 'digital',
  theme = 'dark',
  analogAuxiliaryMode = 'auto',
  rpmWarningFraction = 0.86,
  rpmRedlineFraction = 0.96,
  fallbackRpm = 8000,
  showClutch = true,
  showLights = true,
  showTcAbsLevels = true,
  showSteering = true,
  animateIndicators = true,
  animateShiftAlert = true,
  animateRedlineAlert = true,
  debug = false
})

-- Existing installs have a saved v0.1 scale. Keep a user-selected smaller
-- value, but migrate oversized values to the compact v0.2 presentation once.
if (M.values.layoutVersion or 1) < 3 then
  M.values.hudScale = math.min(M.values.hudScale or 0.72, 0.72)
  M.values.backgroundOpacity = math.max(M.values.backgroundOpacity or 0.72, 0.72)
  M.values.layoutVersion = 3
end

M.values.theme = M.values.theme == 'light' and 'light' or 'dark'

-- A previous settings build could leave both RPM thresholds at 100%. That
-- makes the shift band look permanently dim and prevents the core from ever
-- reaching its amber/red states before the limiter. Restore the intended
-- staged range once, while retaining every other user preference.
if (M.values.layoutVersion or 1) < 4 then
  if (M.values.rpmWarningFraction or 0) >= 0.999 then
    M.values.rpmWarningFraction = 0.86
  end
  if (M.values.rpmRedlineFraction or 0) >= 0.999 then
    M.values.rpmRedlineFraction = 0.96
  end
  M.values.animateShiftAlert = true
  M.values.animateRedlineAlert = true
  M.values.layoutVersion = 4
end

local function normalizeRpmThresholds()
  local redline = math.max(0.82, math.min(M.values.rpmRedlineFraction or 0.96, 1.0))
  local warning = math.max(0.70, math.min(M.values.rpmWarningFraction or 0.86, 0.98))
  M.values.rpmRedlineFraction = redline
  M.values.rpmWarningFraction = math.min(warning, redline - 0.04)
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

-- CSP sliders work with fractions for opacity and RPM thresholds, but their
-- printf formatter does not turn 0.86 into 86%. Draw those controls in human
-- readable percentage points and convert back before persisting them.
local function percentageSlider(label, key, minimum, maximum)
  local value, changed = ui.slider(label, (M.values[key] or minimum) * 100,
    minimum * 100, maximum * 100, '%.0f%%', 1)
  if changed then
    M.values[key] = value / 100
    M.lastChange = label
  end
end

local function resetVisualSettings()
  M.values.hudScale = 0.72
  M.values.backgroundOpacity = 0.72
  M.values.opacity = 1.0
  M.values.theme = 'dark'
  M.lastChange = 'Visual settings reset'
end

local function themeLabel()
  return M.values.theme == 'light' and 'Light' or 'Dark'
end

local function nextAnalogAuxiliaryMode()
  local modes = { 'auto', 'turbo', 'fuel', 'off' }
  local current = M.values.analogAuxiliaryMode or 'auto'
  for i, mode in ipairs(modes) do
    if mode == current then
      M.values.analogAuxiliaryMode = modes[i % #modes + 1]
      return
    end
  end
  M.values.analogAuxiliaryMode = 'auto'
end

function M.draw()
  ui.header('Retro Engineering HUD')
  ui.text('v0.10  /  digital + analog driving dial')
  ui.separator()

  slider('HUD scale', 'hudScale', 0.55, 1.15, '%.2fx')
  percentageSlider('Backdrop opacity', 'backgroundOpacity', 0.18, 0.82)
  percentageSlider('Instrument opacity', 'opacity', 0.55, 1.0)

  if ui.button('Reset visual settings') then
    resetVisualSettings()
  end

  if ui.button('Theme: ' .. themeLabel()) then
    M.values.theme = M.values.theme == 'light' and 'dark' or 'light'
    M.lastChange = 'Theme'
  end

  if ui.button('Speed unit: ' .. M.values.speedUnit) then
    M.values.speedUnit = M.values.speedUnit == 'km/h' and 'mph' or 'km/h'
    M.lastChange = 'Speed unit'
  end

  if ui.button('Instrument mode: ' .. (M.values.instrumentMode == 'analog' and 'Analog dial' or 'Digital dial')) then
    M.values.instrumentMode = M.values.instrumentMode == 'analog' and 'digital' or 'analog'
    M.lastChange = 'Instrument mode'
  end

  if ui.button('Analog lower gauge: ' .. string.upper(M.values.analogAuxiliaryMode or 'auto')) then
    nextAnalogAuxiliaryMode()
    M.lastChange = 'Analog lower gauge'
  end

  ui.separator()
  ui.text('RPM behavior')
  percentageSlider('Warning threshold', 'rpmWarningFraction', 0.70, 0.98)
  percentageSlider('Redline threshold', 'rpmRedlineFraction', 0.82, 1.0)
  normalizeRpmThresholds()
  slider('Fallback RPM', 'fallbackRpm', 4000, 16000, '%.0f rpm')

  ui.separator()
  ui.text('Display')
  checkbox('Show steering marker', 'showSteering')
  checkbox('Show clutch', 'showClutch')
  checkbox('Show lights', 'showLights')
  checkbox('Show TC / ABS levels', 'showTcAbsLevels')
  checkbox('Blink turn indicators', 'animateIndicators')
  checkbox('Blink shift zone', 'animateShiftAlert')
  checkbox('Blink redline alert', 'animateRedlineAlert')
  checkbox('Developer debug view', 'debug')

  ui.separator()
  ui.text('Last change: ' .. M.lastChange)
  ui.textWrapped('The dial is transparent outside its circular surface. Adjust its compact scale and frosted backdrop here; resize or move it through the normal AC app controls.')
end

return M
