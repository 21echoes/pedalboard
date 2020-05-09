--- RingModulator
-- @classmod RingModulator

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")
local JustIntonation = include("lib/ui/util/just_intonation")
local ScreenState = include("lib/ui/util/screen_state")

local RingModulator = Pedal:new()
-- Must match this pedal's .sc file's *id
RingModulator.id = "ringmod"

function RingModulator:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Intvl & Follow", "Shape & Tone"},
    i:_default_section(),
  }
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_interval"]:set_marker_position(1, 0)
  i._param_id_to_widget[i.id .. "_interval"].start_value = 0
  i._param_id_to_widget[i.id .. "_tone"]:set_marker_position(1, 75)

  -- Map the exponential control to a more linear-looking dial
  local freq_dial = i._param_id_to_widget[i.id .. "_freq"]
  freq_dial.min_value = 0
  freq_dial.max_value = 100
  freq_dial.start_value = 0

  return i
end

function RingModulator:name(short)
  return short and "RING" or "Ring Mod"
end

function RingModulator.params()
  local id_prefix = RingModulator.id

  local interval_control = {
    id = id_prefix .. "_interval",
    name = "Interval",
    type = "control",
    controlspec = ControlSpec.new(-24, 24, "lin", 1, 0, "st"),
  }
  local freq_control = {
    id = id_prefix .. "_freq",
    name = "Frequency",
    type = "control",
    controlspec = ControlSpec.new(20, 20000, 'exp', 1, 440, "Hz")
  }
  local follow_control = {
    id = id_prefix .. "_follow",
    name = "Follow Pitch?",
    type = "option",
    options = {"Free", "Follow"},
    default = 2,
  }
  local shape_control = {
    id = id_prefix .. "_shape",
    name = "Mod Shape",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local tone_control = {
    id = id_prefix .. "_tone",
    name = "Tone",
    type = "control",
    controlspec = Controlspecs.MIX,
  }

  return {
    {{interval_control, freq_control, follow_control}, {shape_control, tone_control}},
    Pedal._default_params(id_prefix),
  }
end

function RingModulator:_position_for_widget(section_index, tab_index, widget_index, widget_type)
  -- Treat freq as if it was at widget_index 1 and follow as if it was at widget index 2
  if section_index == 1 and tab_index == 1 and widget_index > 1 then
    widget_index = widget_index - 1
  end
  return Pedal._position_for_widget(self, section_index, tab_index, widget_index, widget_type)
end

function RingModulator:enc(n, delta)
  -- Select which of interval or freq to message, and route to follow correctly
  if self.section_index == 1 and self.tabs.index == 1 then
    local showing_freq = params:get(self.id .. "_follow") == 1
    local widget_index = n - 1
    if showing_freq or widget_index ~= 1 then
      widget_index = widget_index + 1
    end
    param_id = self._param_ids[self.section_index][self.tabs.index][widget_index]
    params:delta(param_id, delta)
    return true
  end
  return Pedal.enc(self, n, delta)
end

function RingModulator:redraw()
  -- subtly adapted from Pedal:redraw so that we skip drawing the hidden widget
  local showing_freq = params:get(self.id .. "_follow") == 1
  for tab_index, tab in ipairs(self._widgets[self.section_index]) do
    for widget_index, widget in ipairs(tab) do
      local skip_redraw = false
      if self.section_index == 1 and tab_index == 1 then
        skip_redraw = (widget_index == 1 and showing_freq) or (widget_index == 2 and not showing_freq)
      end
      if not skip_redraw then
        widget:redraw()
      end
    end
  end

  -- The remainder is identical to Pedal:redraw
  self.tabs:redraw()
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

function RingModulator:_set_value_from_param_value(param_id, value)
  if param_id == self.id .. "_follow" then
    self:_update_section()
  elseif param_id == self.id .. "_freq" then
    -- Map the exponential control to a more linear-looking dial
    local dial_value = util.explin(20, 20000, 0, 100, value)
    local freq_dial = self._param_id_to_widget[param_id]
    freq_dial:set_value(dial_value)
    freq_dial.title = value
    ScreenState.mark_screen_dirty(true)
    self:_message_engine_for_param_change(param_id, value)
    return
  end
  Pedal._set_value_from_param_value(self, param_id, value)
end

function RingModulator:_message_engine_for_param_change(param_id, value)
  if param_id == self.id .. "_interval" then
    local freq_mul = JustIntonation.calculate_freq_mul(value)
    engine.ringmod_freq_mul(freq_mul)
    return
  end
  Pedal._message_engine_for_param_change(self, param_id, value)
end

function RingModulator:_update_section()
  -- Change tab text depending on Follow value
  if self.section_index == 1 then
    local showing_freq = params:get(RingModulator.id .. "_follow") == 1
    if showing_freq then
      self.tabs = UI.Tabs.new(1, {"Freq & Follow", "Shape & Tone"})
      return
    end
  end
  Pedal._update_section(self)
end

return RingModulator
