--- RingsPedal
-- @classmod RingsPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local RingsPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
RingsPedal.id = "rings"

function RingsPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Pitch/Struct", "Bright/Damp"}, 
    {"Position", "Model/EasterEgg"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function RingsPedal:name(short)
  return short and "RNGS" or "Rings"
end

function RingsPedal.params()
  local id_prefix = RingsPedal.id

  local pitch_control = {
    id = id_prefix .. "_pit",
    name = "Pitch",
    type = "control",
    controlspec = controlspec.MIDINOTE 
  }
  local structure_control = {
    id = id_prefix .. "_structure",
    name = "Structure",
    type = "control",
    controlspec = Controlspecs.mix(0.28),
  }
  local brightness_control = {
    id = id_prefix .. "_bright",
    name = "Brightness",
    type = "control",
    controlspec = Controlspecs.mix(0.65),
  }

  local damp_control = {
    id = id_prefix .. "_damp",
    name = "Damping",
    type = "control",
    controlspec = Controlspecs.mix(0.4),
  }

  local position_control = {
    id = id_prefix .. "_pos",
    name = "Position",
    type = "control",
    controlspec = Controlspecs.mix(0.2),
  }

  local model_control = {
    id = id_prefix .. "_model",
    name = "Model",
    type = "option",
    options = {"Modal Resonator", "Sympathetic String", "Modulated/Inharmonic String", "2-Op FM Voice", "Sympathetic String Quantized", "String and Reverb"},
  }

  local easteregg_control = {
    id = id_prefix .. "_easteregg",
    name = "EasterEgg",
    type = "option",
    options = {"Off", "On"},
  }


  return {
    {{pitch_control, structure_control}, {brightness_control, damp_control}},
    {{position_control}, {model_control, easteregg_control}},
    Pedal._default_params(id_prefix),
  }
end


return RingsPedal
