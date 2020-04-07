--- Pedal
-- @classmod Pedal

local UI = require "ui"
local Controlspecs = include("lib/ui/pedals/controlspecs")

local Pedal = {}
Pedal.id = "pedal"

function Pedal:new(i)
  i = i or {}
  setmetatable(i, self)
  self.__index = self
  -- SUBCLASS: must set the pedal ID, e.g. self.id = "reverb"

  i.section_index = 1;
  i.tab_bypass_label = ""
  i.tab_mix_dial = UI.Dial.new(0, 12, 22, 50, 0, 100, 1)
  -- SUBCLASS: must define sections and dials, e.g.:
  -- i.sections = {
  --   {"Size & Decay", "Tone"},
  --   Pedal._default_section(),
  -- }
  -- i.dial_size = UI.Dial.new(9, 12, 22, 50, 0, 100, 1)
  -- i.dial_decay = UI.Dial.new(34.5, 27, 22, 50, 0, 100, 1)
  -- i.dial_tone = UI.Dial.new(84.5, 19.5, 22, 50, 0, 100, 1)
  -- i.dials = {
  --   {{i.dial_size, i.dial_decay}, {i.dial_tone}},
  --   Pedal._default_dials(),
  -- }

  -- SUBCLASS: must call this to complete setup
  -- i:_complete_initialization()

  return i
end

function Pedal:name(short)
  -- SUBCLASS: must define
  return "Pedal"
end

function Pedal:add_params()
  -- SUBCLASS: must define their custom params (and, for now, the base params as well)
  -- TODO: this superclass handles bypass, mix, in, out
end

function Pedal:_message_engine_for_param_change(param_id, value)
  -- SUBCLASS: must define
  -- TODO: this superclass handles bypass, mix, in, out
end

-- Inner implementation, called by subclasses

function Pedal._default_section()
  return {"Bypass & Mix", "In & Out Gains"}
end

function Pedal._default_dials()
  -- TODO: helpers for dial positioning logic & etc
  -- TODO: consider making bypass always an on/off label
  dial_bypass = UI.Dial.new(9, 12, 22, 0, 0, 1, 1)
  dial_mix = UI.Dial.new(34.5, 27, 22, 50, 0, 100, 1)
  dial_in_gain = UI.Dial.new(72, 12, 22, 0, -60, 12, 1, 0, {0})
  dial_out_gain = UI.Dial.new(97, 27, 22, 0, -60, 12, 1, 0, {0})
  return {{dial_bypass, dial_mix}, {dial_in_gain, dial_out_gain}}
end

function Pedal:_complete_initialization()
  self:_update_section()
  self:_update_active_dials()
  self._param_id_to_dials = {}
  for section_index, section in ipairs(self._param_ids) do
    for tab_index, tab in ipairs(section) do
      for param_index, param_id in ipairs(tab) do
        dial = self.dials[section_index][tab_index][param_index]
        self._param_id_to_dials[param_id] = dial
        self:_set_value_from_param_value(param_id, params:get(param_id))
      end
    end
  end
  self:_add_param_actions()
end

function Pedal._add_default_params(id_prefix)
  bypass_id = id_prefix .. "_bypass"
  params:add({
    id = bypass_id,
    name = "Bypass",
    type = "option",
    options = {"Effect Enabled", "Bypassed"},
  })

  mix_id = id_prefix .. "_mix"
  params:add({
    id = mix_id,
    name = "Dry/Wet",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  in_gain_id = id_prefix .. "_in_gain"
  params:add({
    id = in_gain_id,
    name = "In Gain",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_GAIN,
  })

  out_gain_id = id_prefix .. "_out_gain"
  params:add({
    id = out_gain_id,
    name = "Out Gain",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_GAIN,
  })

  return {{bypass_id, mix_id}, {in_gain_id, out_gain_id}}
end

-- Inner implementation

function Pedal:_add_param_actions()
  for section_index, section in ipairs(self._param_ids) do
    for tab_index, tab in ipairs(section) do
      for param_index, param_id in ipairs(tab) do
        params:set_action(param_id, function(value) self:_set_value_from_param_value(param_id, value) end)
      end
    end
  end
end

function Pedal:enter()
  -- Called when the page is scrolled to
end

function Pedal:key(n, z)
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
  -- Going beyond the edge of the current section takes to another section (either direction)
  if self.tabs.index + direction > #self.tabs.titles or self.tabs.index + direction == 0 then
    self.section_index = (self.section_index + direction) % #self.sections
    -- Handle how modulo interacts with 1-indexing
    if self.section_index == 0 then
      self.section_index = #self.sections
    end
    self:_update_section()
    -- If we're moving left, enter a section on the right-most tab
    if direction == -1 then
      self.tabs:set_index(#self.tabs.titles)
    end
  else
    self.tabs:set_index_delta(direction, false)
  end
  self:_update_active_dials()

  return true
end

function Pedal:enc(n, delta)
  -- Change the value of a focused dial
  dial_index = n - 1
  param_id = self._param_ids[self.section_index][self.tabs.index][dial_index]
  if param_id == nil then
    return false
  end
  params:delta(param_id, delta)
  return true
end

function Pedal:redraw()
  self.tabs:redraw()
  for tab_index, tab in ipairs(self.dials[self.section_index]) do
    for dial_index, dial in ipairs(tab) do
      dial:redraw()
    end
  end
  -- Left arrow when there's a section to our left
  if self.section_index > 1 then
    screen.move(0, 6)
    screen.level(3)
    screen.text("<")
  end
  -- Right arrow when there's a section to our left
  if self.section_index < #self.sections then
    screen.move(128, 6)
    screen.level(3)
    screen.text_right(">")
  end
  -- Name of pedal at the bottom
  screen.move(64, 64)
  screen.level(15)
  screen.text_center(self:name())
  -- Prevent a stray line being drawn
  screen.stroke()
end

function Pedal:render_as_tab(offset, width, is_active)
  center_x = offset + (width / 2)
  tab_mix_dial_value = self.tab_mix_dial.value
  self.tab_mix_dial = UI.Dial.new(center_x - 11, 16, 22, tab_mix_dial_value, 0, 100, 1)
  self.tab_mix_dial.active = is_active
  self.tab_mix_dial:redraw()
  if self.tab_bypass_label == "ON" then
    screen.level(is_active and 15 or 6)
  else
    screen.level(is_active and 3 or 1)
  end
  screen.move(center_x, 56)
  screen.text_center(self.tab_bypass_label)
  screen.level(15)
  -- Prevent a stray line being drawn
  screen.stroke()
end

function Pedal:toggle_bypass()
  bypass_param_id = self.id .. "_bypass"
  is_currently_bypassed = params:get(bypass_param_id) == 2
  params:set(bypass_param_id, is_currently_bypassed and 1 or 2)
end

function Pedal:scroll_mix(delta)
  params:delta(self.id .. "_mix", delta)
end

function Pedal:_set_value_from_param_value(param_id, value)
  coerced_value = value
  if param_id == self.id .. "_bypass" then
    -- The options are 1-indexed, but the bypass control expects 0 or 1
    coerced_value = value - 1
    self.tab_bypass_label = value == 1 and "ON" or "OFF"
  elseif param_id == self.id .. "_mix" then
    self.tab_mix_dial:set_value(coerced_value)
  end
  self._param_id_to_dials[param_id]:set_value(coerced_value)

  if param_id == self.id .. "_bypass" then
    engine[self.id .. "_bypass"](coerced_value)
  elseif param_id == self.id .. "_mix" then
    engine[self.id .. "_mix"](coerced_value / 100.0)
  elseif param_id == self.id .. "_in_gain" then
    engine[self.id .. "_in_gain"](util.dbamp(coerced_value))
  elseif param_id == self.id .. "_out_gain" then
    engine[self.id .. "_out_gain"](util.dbamp(coerced_value))
  else
    self:_message_engine_for_param_change(param_id, coerced_value)
  end
end

function Pedal:_update_section()
  self.tabs = UI.Tabs.new(1, self.sections[self.section_index])
end

function Pedal:_update_active_dials()
  current_tab_index = self.tabs.index
  for tab_index, tab in ipairs(self.dials[self.section_index]) do
    for dial_index, dial in ipairs(tab) do
      dial.active = tab_index == current_tab_index
    end
  end
end

return Pedal
