--- ReverbPedal
-- @classmod ReverbPedal

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
    {"Size & Decay", "Tone"},
    i:_default_section(),
  }
  i:_complete_initialization()

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
  local tone_control = {
    id = id_prefix .. "_tone",
    name = "Tone",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }

  return {
    {{size_control, decay_control}, {tone_control}},
    Pedal._default_params(id_prefix),
  }
end

return ReverbPedal
