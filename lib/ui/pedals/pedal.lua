--- Pedal
-- @classmod Pedal

local UI = require "ui"
local Controlspecs = include("lib/ui/pedals/controlspecs")
local ScreenState = include("lib/ui/screen_state")
local Label = include("lib/ui/label")

local Pedal = {}
Pedal.id = "pedal"

function Pedal:new(bypass_by_default)
  i = {}
  setmetatable(i, self)
  self.__index = self
  -- SUBCLASS: must set the pedal ID, e.g. self.id = "reverb"

  i.section_index = 1;
  i.tab_bypass_label = Label.new({center_x = 0, y = 56, level = 15, text = ""})
  i.bypass_by_default = bypass_by_default
  i.tab_mix_dial = UI.Dial.new(0, 12, 22, 50, 0, 100, 1)

  -- SUBCLASS: must call this to complete setup
  -- i:_complete_initialization()

  return i
end

function Pedal.params()
  -- SUBCLASS: must define
  -- return Pedal._default_params as the last element in the table
end

function Pedal:name(short)
  -- SUBCLASS: must define
  -- return short and "short_name" or "long_name", where short_name is ideally <= 5 characters
end

-- Inner implementation, called by subclasses

function Pedal:_complete_initialization()
  self:_initialize_widgets()
  self:_update_section()
  self:_update_active_widgets()
  self._param_id_to_widget = {}
  for section_index, section in ipairs(self._param_ids) do
    for tab_index, tab in ipairs(section) do
      for param_index, param_id in ipairs(tab) do
        self._param_id_to_widget[param_id] = self._widgets[section_index][tab_index][param_index]
        local param_value = params:get(param_id)
        if param_id == self.id .. "_bypass" then
          param_value = self.bypass_by_default and 2 or 1
          params:set(param_id, param_value)
        end
        self:_set_value_from_param_value(param_id, param_value)
      end
    end
  end
  self:_add_param_actions()
end

-- TODO: make it so subclass doesn't call these

function Pedal._default_params(id_prefix)
  local bypass_control = {
    id = id_prefix .. "_bypass",
    name = "Bypass",
    type = "option",
    options = {"Effect Enabled", "Bypassed"},
  }
  local mix_control = {
    id = id_prefix .. "_mix",
    name = "Dry/Wet",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }
  local in_gain_control = {
    id = id_prefix .. "_in_gain",
    name = "In Gain",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_GAIN,
  }
  local out_gain_control = {
    id = id_prefix .. "_out_gain",
    name = "Out Gain",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_GAIN,
  }
  return {{bypass_control, mix_control}, {in_gain_control, out_gain_control}}
end

function Pedal:_default_section()
  return {"Bypass & Mix", "In & Out Gains"}
end

-- Public interface

function Pedal:add_params()
  local param_ids = {}
  local params_to_add = {}
  for section_index, section in ipairs(self.params()) do
    param_ids[section_index] = {}
    for tab_index, tab in ipairs(section) do
      param_ids[section_index][tab_index] = {}
      for param_index, param in ipairs(tab) do
        param_ids[section_index][tab_index][param_index] = param.id
        table.insert(params_to_add, param)
      end
    end
  end
  self._param_ids = param_ids
  local params_by_id = {}
  params:add_group(self:name(), #params_to_add)
  for i, param in ipairs(params_to_add) do
    params_by_id[param.id] = param
    params:add(param)
  end
  self._params_by_id = params_by_id
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
  local direction = 0
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
  self:_update_active_widgets()

  return true
end

function Pedal:enc(n, delta)
  -- Change the value of a focused widget
  local param_id = nil
  -- If there's only one widget, always use it
  if #self._param_ids[self.section_index][self.tabs.index] == 1 then
    param_id = self._param_ids[self.section_index][self.tabs.index][1]
  else
    local widget_index = n - 1
    param_id = self._param_ids[self.section_index][self.tabs.index][widget_index]
  end
  if param_id == nil then
    return false
  end
  params:delta(param_id, delta)
  return true
end

function Pedal:redraw()
  self.tabs:redraw()
  for tab_index, tab in ipairs(self._widgets[self.section_index]) do
    for widget_index, widget in ipairs(tab) do
      widget:redraw()
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
  -- Name of pedal at the bottom, leaving room for the descender
  screen.move(64, 62)
  screen.level(15)
  screen.text_center(self:name())
  -- Prevent a stray line being drawn
  screen.stroke()
end

function Pedal:render_as_tab(offset, width, is_active)
  local center_x = offset + (width / 2)
  self.tab_mix_dial = UI.Dial.new(center_x - 11, 16, 22, self.tab_mix_dial.value, 0, 100, 1)
  self.tab_mix_dial.active = is_active
  self.tab_mix_dial:redraw()
  if self.tab_bypass_label.text == "ON" then
    self.tab_bypass_label.level = is_active and 15 or 6
  else
    self.tab_bypass_label.level = is_active and 3 or 1
  end
  self.tab_bypass_label.center_x = center_x
  self.tab_bypass_label:redraw()
end

function Pedal:toggle_bypass()
  local bypass_param_id = self.id .. "_bypass"
  local is_currently_bypassed = params:get(bypass_param_id) == 2
  params:set(bypass_param_id, is_currently_bypassed and 1 or 2)
end

function Pedal:scroll_mix(delta)
  params:delta(self.id .. "_mix", delta)
end

-- Inner implementation

function Pedal:_add_param_actions()
  for section_index, section in ipairs(self._param_ids) do
    for tab_index, tab in ipairs(section) do
      for param_index, param_id in ipairs(tab) do
        params:set_action(param_id, function(value)
          self:_set_value_from_param_value(param_id, value)
        end)
      end
    end
  end
end

function Pedal:_initialize_widgets()
  local widgets = {}
  for section_index, section in ipairs(self:params()) do
    widgets[section_index] = {}
    for tab_index, tab in ipairs(section) do
      widgets[section_index][tab_index] = {}
      for param_index, param in ipairs(tab) do
        local x, y = self:_position_for_widget(section_index, tab_index, param_index, param.type)
        if param.type == "control" then
          widgets[section_index][tab_index][param_index] = UI.Dial.new(
            x, y, 22,
            param.controlspec.default,
            param.controlspec.minval,
            param.controlspec.maxval,
            param.controlspec.step,
            (not Controlspecs.is_gain(param.controlspec)) and param.controlspec.minval or 0,
            Controlspecs.is_gain(param.controlspec) and {0} or {}
          )
        elseif param.type == "option" then
          widgets[section_index][tab_index][param_index] = Label.new({
            center_x = x,
            y = y,
            level = 15,
            text = param.default or param.options[1],
          })
        end
      end
    end
  end
  self._widgets = widgets
end

function Pedal:_position_for_widget(section_index, tab_index, widget_index, widget_type)
  local tabs = self:params()[section_index]
  local widgets = tabs[tab_index]
  if #tabs == 1 then
    if #widgets == 1 then
      if widget_type == "control" then return 54, 19.5 end
      return 64, 36
    end
    if widget_index == 1 then
      if widget_type == "control" then return 21, 19.5 end
      return 32, 36
    end
    if widget_type == "control" then return 86, 19.5 end
    return 96, 36
  end
  local x, y
  if #widgets == 1 then
    if widget_type == "control" then
      x, y = 21, 19.5
    else
      x, y = 32, 36
    end
  else
    local other_is_dial = widgets[(widget_index % 2) + 1].type == "control"
    if widget_index == 1 then
      if widget_type == "control" then
        if other_is_dial then
          x, y = 9, 13
        else
          x, y = 21, 13
        end
      else
        if other_is_dial then
          x, y = 32, 18
        else
          x, y = 32, 26
        end
      end
    else
      if widget_type == "control" then
        if other_is_dial then
          x, y = 34.5, 26
        else
          x, y = 22, 26
        end
      else
        if other_is_dial then
          x, y = 32, 53
        else
          x, y = 32, 46
        end
      end
    end
  end
  if tab_index == 2 then
    x = x + 64
  end
  return x, y
end

function Pedal:_set_value_from_param_value(param_id, value)
  local coerced_value = value
  if param_id == self.id .. "_bypass" then
    self.tab_bypass_label.text = value == 1 and "ON" or "OFF"
  elseif param_id == self.id .. "_mix" then
    self.tab_mix_dial:set_value(coerced_value)
  end
  local widget = self._param_id_to_widget[param_id]
  if widget.__index == UI.Dial then
    widget:set_value(coerced_value)
  else
    -- We use the un-coerced value
    widget.text = self._params_by_id[param_id].options[value]
    -- Then coerce the index to zero-indexed for the engine
    coerced_value = value - 1
  end
  ScreenState.mark_screen_dirty(true)

  self:_message_engine_for_param_change(param_id, coerced_value)
end

function Pedal:_message_engine_for_param_change(param_id, value)
  param = self._params_by_id[param_id]
  local coerced_value = value
  if param.controlspec ~= nil then
    if Controlspecs.is_mix(param.controlspec) then
      coerced_value = value / 100.0
    elseif Controlspecs.is_gain(param.controlspec) then
      coerced_value = util.dbamp(value)
    end
  end
  engine[param_id](coerced_value)
end

function Pedal:_update_section()
  self.tabs = UI.Tabs.new(1, self.sections[self.section_index])
end

function Pedal:_update_active_widgets()
  for tab_index, tab in ipairs(self._widgets[self.section_index]) do
    for widget_index, widget in ipairs(tab) do
      local is_active = tab_index == self.tabs.index
      if widget.__index == UI.Dial then
        widget.active = is_active
      else
        widget.level = is_active and 15 or 3
      end
    end
  end
end

return Pedal
