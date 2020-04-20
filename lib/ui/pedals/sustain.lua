--- SustainPedal
-- @classmod SustainPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local SustainPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
SustainPedal.id = "sustain"

function SustainPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Drive & Gate", "Tone"},
    i:_default_section(),
  }
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_tone"]:set_marker_position(1, 75)

  return i
end

function SustainPedal:name(short)
  return short and "SUS" or "Sustain"
end

function SustainPedal.params()
  local id_prefix = SustainPedal.id

  local drive_control = {
    id = id_prefix .. "_drive",
    name = "Drive",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local gate_control = {
    id = id_prefix .. "_gate",
    name = "Noise Gate",
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
    {{drive_control, gate_control}, {tone_control}},
    Pedal._default_params(id_prefix),
  }
end

return SustainPedal
