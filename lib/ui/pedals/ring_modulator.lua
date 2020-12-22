--- RingModulator
-- @classmod RingModulator

local ControlSpec = require "controlspec"
local UI = require "ui"
local MusicUtil = require "musicutil"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")
local JustIntonation = include("lib/ui/util/just_intonation")
local ScreenState = include("lib/ui/util/screen_state")

local RingModulator = Pedal:new()
-- Must match this pedal's .sc file's *id
RingModulator.id = "ringmod"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
RingModulator.peak_cpu = 13

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
  i._arcify = nil

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
  local pitch_control = {
    id = id_prefix .. "_pitch",
    name = "Pitch",
    type = "control",
    formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    -- TODO: ideally this would be 0-127, but controlspecs larger than ~100 steps can skip values
    controlspec = ControlSpec.new(24, 103, "lin", 1, 60, ""), -- c3 by default
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
    {{interval_control, pitch_control, follow_control}, {shape_control, tone_control}},
    Pedal._default_params(id_prefix),
  }
end

function RingModulator:enter(arcify)
  Pedal.enter(self, arcify)
  self._arcify = arcify
  self:_arcify_maybe_follow()
end

function RingModulator:cleanup()
  Pedal.cleanup(self)
  self._arcify = nil
end

function RingModulator:_position_for_widget(section_index, tab_index, widget_index, widget_type)
  -- Treat pitch as if it was at widget_index 1 and follow as if it was at widget index 2
  if section_index == 1 and tab_index == 1 and widget_index > 1 then
    widget_index = widget_index - 1
  end
  return Pedal._position_for_widget(self, section_index, tab_index, widget_index, widget_type)
end

function RingModulator:enc(n, delta)
  -- Select which of interval or pitch to message, and route to follow correctly
  if self.section_index == 1 and self.tabs.index == 1 then
    local showing_pitch = params:get(self.id .. "_follow") == 1
    local widget_index = n - 1
    if showing_pitch or widget_index ~= 1 then
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
  local showing_pitch = params:get(self.id .. "_follow") == 1
  for tab_index, tab in ipairs(self._widgets[self.section_index]) do
    for widget_index, widget in ipairs(tab) do
      local skip_redraw = false
      if self.section_index == 1 and tab_index == 1 then
        skip_redraw = (widget_index == 1 and showing_pitch) or (widget_index == 2 and not showing_pitch)
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
    self:_arcify_maybe_follow()
  elseif param_id == self.id .. "_pitch" then
    local pitch_widget = self._param_id_to_widget[param_id]
    pitch_widget:set_value(value)
    pitch_widget.title = MusicUtil.note_num_to_name(value, true)
    ScreenState.mark_screen_dirty(true)
    self:_message_engine_for_param_change(param_id, value)
    return
  end
  Pedal._set_value_from_param_value(self, param_id, value)
end

function RingModulator:_message_engine_for_param_change(param_id, value)
  if param_id == self.id .. "_interval" then
    local mod_value = self.modmatrix:mod(self._params_by_id[param_id], value)
    local freq_mul = JustIntonation.calculate_freq_mul(mod_value)
    engine.ringmod_freq_mul(freq_mul)
    return
  elseif param_id == self.id .. "_pitch" then
    local mod_value = self.modmatrix:mod(self._params_by_id[param_id], value)
    local freq = MusicUtil.note_num_to_freq(mod_value)
    engine.ringmod_freq(freq)
    return
  end
  Pedal._message_engine_for_param_change(self, param_id, value)
end

function RingModulator:_update_section()
  -- Change tab text depending on Follow value
  if self.section_index == 1 then
    local showing_pitch = params:get(RingModulator.id .. "_follow") == 1
    if showing_pitch then
      self.tabs = UI.Tabs.new(1, {"Pitch & Follow", "Shape & Tone"})
      return
    end
  end
  Pedal._update_section(self)
end

function RingModulator:_arcify_maybe_follow()
  if params:get("arc_mode") ~= 1 then return end

  local arcify = self._arcify
  if arcify == nil then return end

  local showing_pitch = params:get(self.id .. "_follow") == 1
  if showing_pitch then
    arcify:map_encoder_via_params(1, self.id .. "_pitch")
  else
    arcify:map_encoder_via_params(1, self.id .. "_interval")
  end
  for i=2,3 do
    if (i + 1) <= #self._param_ids_flat - 3 then
      arcify:map_encoder_via_params(i, self._param_ids_flat[(i + 1)])
    else
      arcify:map_encoder_via_params(i, "none")
    end
  end
  arcify:map_encoder_via_params(4, self.id .. "_mix")
end

return RingModulator
