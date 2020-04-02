--- VolumePedal
-- @classmod VolumePedal

local UI = require "ui"

local VolumePedal = {}
VolumePedal.__index = VolumePedal
VolumePedal.name = "Volume"

function VolumePedal.new()
  local i = {}
  setmetatable(i, VolumePedal)

  -- TODO: make a superclass that has these as the default tabs, with default handlers for them, etc.
  i.tabs_table = {"Bypass & Mix", "In & Out Gains"}
  i.tabs = UI.Tabs.new(1, i.tabs_table)

  dial_bypass = UI.Dial.new(9, 12, 22, 0, 0, 1, 1)
  dial_mix = UI.Dial.new(34.5, 27, 22, 50, 0, 100, 1)
  dial_in_gain = UI.Dial.new(72, 12, 22, 0, -60, 12, 1, 0, {0})
  dial_out_gain = UI.Dial.new(97, 27, 22, 0, -60, 12, 1, 0, {0})
  i.dials = {{dial_bypass, dial_mix}, {dial_in_gain, dial_out_gain}}
  i:_update_active_dials()

  return i
end

function VolumePedal:enter()
  -- Called when the page is scrolled to
end

function VolumePedal:key(n, z)
  -- Key-up currently has no meaning
  if z ~= 1 then
    return false
  end

  -- Change the focused tab
  if n == 2 then
    direction = -1
  elseif n == 3 then
    direction = 1
  end
  self.tabs:set_index_delta(direction, false)
  self:_update_active_dials()

  return true
end

function VolumePedal:enc(n, delta)
  -- Change the value of a focused dial
  dial_index = n - 1
  dial = self.dials[self.tabs.index][dial_index]
  dial:set_value_delta(delta)
  return true
end

function VolumePedal:redraw()
  self.tabs:redraw()
  for tab_index, tab in ipairs(self.dials) do
    for dial_index, dial in ipairs(tab) do
      dial:redraw()
    end
  end
  screen.move(64, 64)
  screen.text_center(self.name)
end


function VolumePedal:_update_active_dials()
  current_tab_index = self.tabs.index
  for tab_index, tab in ipairs(self.dials) do
    for dial_index, dial in ipairs(tab) do
      dial.active = tab_index == current_tab_index
    end
  end
end

return VolumePedal
