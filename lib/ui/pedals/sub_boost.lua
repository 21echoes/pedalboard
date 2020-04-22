--- SubBoostPedal
-- @classmod SubBoostPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local SubBoostPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
SubBoostPedal.id = "subboost"

function SubBoostPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"8vb & Shape", "Vol & Sense"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function SubBoostPedal:name(short)
  return short and "SUB" or "Sub Boost"
end

function SubBoostPedal.params()
  local id_prefix = SubBoostPedal.id

  local num_octaves_down_control = {
    id = id_prefix .. "_num_octaves_down",
    name = "# 8vb",
    type = "control",
    controlspec = ControlSpec.new(0, 7, "lin", 1, 2, "8vb"),
  }
  local shape_control = {
    id = id_prefix .. "_shape",
    name = "Shape",
    type = "control",
    controlspec = Controlspecs.mix(33),
  }
  local amp_control = {
    id = id_prefix .. "_amp",
    name = "Volume",
    type = "control",
    controlspec = Controlspecs.mix(50),
  }
  local sensitivity_control = {
    id = id_prefix .. "_sensitivity",
    name = "Sensitivity",
    type = "control",
    controlspec = Controlspecs.mix(40),
  }

  return {
    {{num_octaves_down_control, shape_control}, {amp_control, sensitivity_control}},
    Pedal._default_params(id_prefix),
  }
end

return SubBoostPedal
