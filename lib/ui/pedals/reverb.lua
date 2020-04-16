--- ReverbPedal
-- @classmod ReverbPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local ReverbPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
ReverbPedal.id = "reverb"

function ReverbPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Size & Decay", "Shimmer & Tone"},
    i:_default_section(),
  }
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_tone"]:set_marker_position(1, 75)

  return i
end

function ReverbPedal:name(short)
  return short and "VERB" or "Reverb"
end

function ReverbPedal.params()
  local id_prefix = ReverbPedal.id

  local size_control = {
    id = id_prefix .. "_size",
    name = "Size",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }
  local decay_control = {
    id = id_prefix .. "_decay",
    name = "Decay Time",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }
  local shimmer_control = {
    id = id_prefix .. "_shimmer",
    name = "Shimmer",
    type = "control",
    controlspec = ControlSpec.new(0, 100, "lin", 1, 0, "%"),
  }
  local tone_control = {
    id = id_prefix .. "_tone",
    name = "Tone",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }

  return {
    {{size_control, decay_control}, {shimmer_control, tone_control}},
    Pedal._default_params(id_prefix),
  }
end

function ReverbPedal:_message_engine_for_param_change(param_id, value)
  if param_id == self.id .. "_shimmer" then
    -- The shimmer controlspec is custom, so it doesn't automatically get divided by 100 when sent to the engine
    engine[param_id](value / 100.0)
  else
    Pedal._message_engine_for_param_change(self, param_id, value)
  end
end

return ReverbPedal
