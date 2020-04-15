--- ChorusPedal
-- @classmod ChorusPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local ChorusPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
ChorusPedal.id = "chorus"

function ChorusPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Rate & Depth"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function ChorusPedal:name(short)
  return short and "CHO" or "Chorus"
end

function ChorusPedal.params()
  local id_prefix = ChorusPedal.id

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

  return {
    {{rate_control, depth_control}},
    Pedal._default_params(id_prefix),
  }
end

return ChorusPedal
