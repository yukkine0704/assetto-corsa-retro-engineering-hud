local Settings = require('src/settings')
local Telemetry = require('src/telemetry')
local Dial = require('ui/dial')

local state = Telemetry.new()

function script.update(dt)
  Telemetry.update(state, dt, Settings.values)
end

function script.windowMain(_)
  Dial.draw(state, Settings.values)
end

function script.settingsMain(_)
  Settings.draw()
end
