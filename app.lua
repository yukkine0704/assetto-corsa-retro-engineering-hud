local Settings = require('src/settings')
local Telemetry = require('src/telemetry')
local Dial = require('ui/dial')

local state = Telemetry.new()
local THEME_EVENT = 'retro-engineering-hud/theme/v1'
local themeBroadcastTimer = 1
local lastThemePayload

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

function script.windowMain(_)
  Dial.draw(state, Settings.values)
end

function script.settingsMain(_)
  Settings.draw()
end
