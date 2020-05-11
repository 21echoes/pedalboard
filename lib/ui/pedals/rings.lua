--- RingsPedal
-- @classmod RingsPedal

local ControlSpec = require "controlspec"
local MusicUtil = require "musicutil"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")
local ScreenState = include("lib/ui/util/screen_state")

local RingsPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
RingsPedal.id = "rings"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
RingsPedal.peak_cpu = 24
RingsPedal.required_files = {
  "/home/we/.local/share/SuperCollider/Extensions/MiRings/MiRings.cpp",
  "/home/we/.local/share/SuperCollider/Extensions/MiRings/MiRings.sc",
  "/home/we/.local/share/SuperCollider/Extensions/MiRings/MiRings.so",
}
RingsPedal.engine_ready = false
RingsPedal.requirements_failed_msg = {
  "For instructions on how",
  "to enable this pedal, check",
  "https://llllllll.co/t/31781",
  "Sleep & re-boot afterward!"
}

function RingsPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i._sections_by_follow_and_mode = {
    -- Free pitch
    {
      -- Default
      {
        {"Pitch/Follow", "Structure"},
        {"Bright/Damp", "Pos/Poly"},
        {"Model/Alt"},
        i:_default_section(),
      },
      -- Disastrous Peace
      {
        {"Pitch/Follow", "Chord"},
        {"Bright/Damp", "FX Amt/Poly"},
        {"FX Type/Alt"},
        i:_default_section(),
      },
    },
    -- Follow with interval
    {
      -- Default
      {
        {"Intvl/Follow", "Structure"},
        {"Bright/Damp", "Pos/Poly"},
        {"Model/Alt"},
        i:_default_section(),
      },
      -- Disastrous Peace
      {
        {"Intvl/Follow", "Chord"},
        {"Bright/Damp", "FX Amt/Poly"},
        {"FX Type/Alt"},
        i:_default_section(),
      },
    },
  }
  i.sections = i._sections_by_follow_and_mode[2][1]
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_interval"]:set_marker_position(1, 0)
  i._param_id_to_widget[i.id .. "_interval"].start_value = 0

  return i
end

function RingsPedal:name(short)
  return short and "RNGS" or "MI Rings"
end

function RingsPedal.params()
  local id_prefix = RingsPedal.id

  local pitch_control = {
    id = id_prefix .. "_pit",
    name = "Pitch",
    type = "control",
    formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    -- TODO: ideally this would be 0-127, but controlspecs larger than ~100 steps can skip values
    controlspec = ControlSpec.new(24, 103, "lin", 1, 60, ""), -- c3 by default
  }
  local interval_control = {
    id = id_prefix .. "_interval",
    name = "Interval",
    type = "control",
    controlspec = ControlSpec.new(-24, 24, "lin", 1, 0, "st"),
  }
  local follow_control = {
    id = id_prefix .. "_follow",
    name = "Follow Pitch?",
    type = "option",
    options = {"Free", "Follow"},
    default = 2,
  }
  local structure_control = {
    id = id_prefix .. "_struct",
    name = "Structure",
    type = "control",
    controlspec = Controlspecs.mix(36),
  }
  local brightness_control = {
    id = id_prefix .. "_bright",
    name = "Brightness",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local damp_control = {
    id = id_prefix .. "_damp",
    name = "Damping",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local position_control = {
    id = id_prefix .. "_pos",
    name = "Position",
    type = "control",
    controlspec = Controlspecs.mix(33),
  }
  local poly_control = {
    id = id_prefix .. "_poly",
    name = "Polyphony",
    type = "control",
    controlspec = ControlSpec.new(1, 4, "lin", 1, 4, ""),
  }
  local model_control = {
    id = id_prefix .. "_model",
    name = "Model",
    type = "option",
    options = {"Modal", "Sym. Strings", "String", "FM", "Chords", "Karplusverb"},
  }
  local easteregg_control = {
    id = id_prefix .. "_easteregg",
    name = "Disastrous Peace",
    type = "option",
    options = {"Off", "On"},
  }

  return {
    {{interval_control, pitch_control, follow_control}, {structure_control}},
    {{brightness_control, damp_control}, {position_control, poly_control}},
    {{model_control, easteregg_control}},
    Pedal._default_params(id_prefix),
  }
end

function RingsPedal:_position_for_widget(section_index, tab_index, widget_index, widget_type)
  -- Treat freq as if it was at widget_index 1 and follow as if it was at widget index 2
  if section_index == 1 and tab_index == 1 and widget_index > 1 then
    widget_index = widget_index - 1
  end
  return Pedal._position_for_widget(self, section_index, tab_index, widget_index, widget_type)
end

function RingsPedal:enc(n, delta)
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

function RingsPedal:redraw()
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


function RingsPedal:_update_section()
  self.sections = self._sections_by_follow_and_mode[params:get(self.id.."_follow")][params:get(self.id.."_easteregg")]
  Pedal._update_section(self)
end

local easter_egg_modes = {"Formant", "Chorus", "Reverb", "Formant 2", "Chorus 2", "Reverb 2"}
function RingsPedal:_set_value_from_param_value(param_id, value)
  local model_param_id = self.id .. "_model"
  local easteregg_param_id = self.id .. "_easteregg"
  if param_id == easteregg_param_id then
    local model_widget = self._param_id_to_widget[model_param_id]
    if value == 2 then
      model_widget.text = easter_egg_modes[params:get(model_param_id)]
    else
      model_widget.text = self._params_by_id[model_param_id].options[params:get(model_param_id)]
    end
    local easteregg_widget = self._param_id_to_widget[easteregg_param_id]
    easteregg_widget.text = self._params_by_id[easteregg_param_id].options[params:get(easteregg_param_id)]
    local tab_index = self.tabs.index
    self:_update_section()
    self.tabs.index = tab_index
    self:_update_active_widgets()
    ScreenState.mark_screen_dirty(true)
    self:_message_engine_for_param_change(param_id, value - 1)
    return
  end
  if param_id == model_param_id and params:get(easteregg_param_id) == 2 then
    local model_widget = self._param_id_to_widget[model_param_id]
    model_widget.text = easter_egg_modes[params:get(model_param_id)]
    ScreenState.mark_screen_dirty(true)
    self:_message_engine_for_param_change(param_id, value - 1)
    return
  end
  local pitch_param_id = self.id .. "_pit"
  if param_id == pitch_param_id then
    local pitch_widget = self._param_id_to_widget[param_id]
    pitch_widget:set_value(value)
    pitch_widget.title = MusicUtil.note_num_to_name(value, true)
    ScreenState.mark_screen_dirty(true)
    self:_message_engine_for_param_change(param_id, value)
    return
  end
  if param_id == self.id .. "_follow" then
    self:_update_section()
  end
  Pedal._set_value_from_param_value(self, param_id, value)
end

return RingsPedal
