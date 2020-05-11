local UI = require "ui"

local Alert = {}
Alert.__index = Alert

function Alert.new(text_array)
  local i = {
    text = text_array or {},
    active = true
  }
  setmetatable(i, Alert)
  i.__index = Alert

  return i
end

function Alert:redraw()
  screen.level(0)
  screen.rect(0, 0, 128, 64)
  screen.fill()
  local message = UI.Message.new(self.text)
  message.active = self.active
  message:redraw()
end

return Alert
