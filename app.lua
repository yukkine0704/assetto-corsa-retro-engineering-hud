local Settings = require('src/settings')
local Telemetry = require('src/telemetry')
local Dial = require('ui/dial')
local Gt7Retro = require('ui/gt7_retro')

local state = Telemetry.new()
local THEME_EVENT = 'retro-engineering-hud/theme/v1'
local themeBroadcastTimer = 1
local lastThemePayload
local lastWindowConstraintMode

local function clampUnit(value, fallback)
  value = tonumber(value)
  if not value then return fallback end
  return math.max(0, math.min(1, value))
end

local function publishTheme(dt)
  themeBroadcastTimer = themeBroadcastTimer + (dt or 0)
  local values = Settings.values
  local theme = values.theme == 'light' and 'light' or 'dark'
  local payload = string.format('%s|%.3f|%.3f', theme,
    clampUnit(values.backgroundOpacity, 0.72), clampUnit(values.opacity, 1))

  if payload ~= lastThemePayload or themeBroadcastTimer >= 1 then
    ac.broadcastSharedEvent(THEME_EVENT, payload)
    lastThemePayload = payload
    themeBroadcastTimer = 0
  end
end

function script.update(dt)
  Telemetry.update(state, dt, Settings.values)
  publishTheme(dt)
end

local function updateWindowConstraints(mode)
  local constraintMode = mode == 'gt7_retro' and 'panoramic' or 'square'
  if constraintMode == lastWindowConstraintMode then return end
  lastWindowConstraintMode = constraintMode

  if ac.setWindowSizeConstraints then
    if constraintMode == 'panoramic' then
      ac.setWindowSizeConstraints('main', vec2(320, 112), vec2(4096, 1440))
    else
      ac.setWindowSizeConstraints('main', vec2(340, 340), vec2(2048, 2048))
    end
  end
end

function script.windowMain(_)
  local mode = Settings.values.instrumentMode
  updateWindowConstraints(mode)
  if mode == 'gt7_retro' then
    Gt7Retro.draw(state, Settings.values)
  else
    Dial.draw(state, Settings.values)
  end
end

function script.settingsMain(_)
  Settings.draw()
end
