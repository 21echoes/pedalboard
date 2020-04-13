--- TremoloPedal
-- @classmod TremoloPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

local TremoloPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
TremoloPedal.id = "tremolo"

function TremoloPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Rate & Depth", "Shape"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function TremoloPedal:name(short)
  return short and "TREM" or "Tremolo"
end

function TremoloPedal.params()
  local id_prefix = TremoloPedal.id

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
  local shape_control = {
    id = id_prefix .. "_shape",
    name = "Shape",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }

  return {
    {{rate_control, depth_control}, {shape_control}},
    Pedal._default_params(id_prefix),
  }
end

-- TODO: tap tempo

return TremoloPedal
