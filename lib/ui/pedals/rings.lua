--- RingsPedal
-- @classmod RingsPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")
local ScreenState = include("lib/ui/util/screen_state")

local RingsPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
RingsPedal.id = "rings"

function RingsPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i._sections_by_mode = {
    -- Default
    {
      {"Pitch/Struct", "Bright/Damp"},
      {"Pos/Poly", "Model/Alt"},
      i:_default_section(),
    },
    -- Disastrous Peace
    {
      {"Pitch/Chord", "Bright/Damp"},
      {"FX Amt/Poly", "FX Type/Alt"},
      i:_default_section(),
    },
  }
  i.sections = i._sections_by_mode[1]
  i:_complete_initialization()

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
    -- TODO: ideally this would be 0-127, but controlspecs larger than ~100 steps can skip values
    controlspec = ControlSpec.new(24, 103, "lin", 1, 60, ""), -- c3 by default
  }
  local structure_control = {
    id = id_prefix .. "_struct",
    name = "Structure",
    type = "control",
    controlspec = Controlspecs.mix(28),
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
    {{pitch_control, structure_control}, {brightness_control, damp_control}},
    {{position_control, poly_control}, {model_control, easteregg_control}},
    Pedal._default_params(id_prefix),
  }
end

function RingsPedal:_update_section()
  self.sections = self._sections_by_mode[params:get(self.id.."_easteregg")]
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
  Pedal._set_value_from_param_value(self, param_id, value)
end

return RingsPedal
