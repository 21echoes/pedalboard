--- DistortionPedal
-- @classmod DistortionPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local DistortionPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
DistortionPedal.id = "distortion"

function DistortionPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Drive & Tone"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function DistortionPedal:name(short)
  return short and "DIST" or "Distortion"
end

function DistortionPedal.params()
  local id_prefix = DistortionPedal.id

  local drive_control = {
    id = id_prefix .. "_drive",
    name = "Drive",
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
    {{drive_control, tone_control}},
    Pedal._default_params(id_prefix),
  }
end

return DistortionPedal
