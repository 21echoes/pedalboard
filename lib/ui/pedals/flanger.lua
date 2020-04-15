--- FlangerPedal
-- @classmod FlangerPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local FlangerPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
FlangerPedal.id = "flanger"

function FlangerPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Rate & Depth", "Fdbk & Delay"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function FlangerPedal:name(short)
  return short and "FLNG" or "Flanger"
end

function FlangerPedal.params()
  local id_prefix = FlangerPedal.id

  local rate_control = {
    id = id_prefix .. "_rate",
    name = "Rate",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }
  local depth_control = {
    id = id_prefix .. "_depth",
    name = "Depth",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }
  local feedback_control = {
    id = id_prefix .. "_feedback",
    name = "Feedback",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }
  local predelay_control = {
    id = id_prefix .. "_predelay",
    name = "Pre-delay",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }

  return {
    {{rate_control, depth_control}, {feedback_control, predelay_control}},
    Pedal._default_params(id_prefix),
  }
end

return FlangerPedal
