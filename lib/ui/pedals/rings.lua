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
    controlspec = ControlSpec.new(0, 127, "lin", 1, 60, ""),
  }
  local structure_control = {
    id = id_prefix .. "_struct",
    name = "Structure",
    type = "control",
    controlspec = ControlSpec.new(0.00, 1.00, "lin", 0.01, 0.28, ""),
  }
  local brightness_control = {
    id = id_prefix .. "_bright",
    name = "Brightness",
    type = "control",
    controlspec = ControlSpec.new(0.00, 1.00, "lin", 0.01, 0.65, ""),
  }

  local damp_control = {
    id = id_prefix .. "_damp",
    name = "Damping",
    type = "control",
    controlspec = ControlSpec.new(0.00, 1.00, "lin", 0.01, 0.4, ""),
  }

  local position_control = {
    id = id_prefix .. "_pos",
    name = "Position",
    type = "control",
    controlspec = ControlSpec.new(0.00, 1.00, "lin", 0.01, 0.2, ""),
  }

  local model_control = {
    id = id_prefix .. "_model",
    name = "Model",
    type = "control",
    controlspec = ControlSpec.new(0, 5, "lin", 1, 0, ""),
  }

  local easteregg_control = {
    id = id_prefix .. "_easteregg",
    name = "EasterEgg",
    type = "control",
    controlspec = ControlSpec.new(0, 1, "lin", 1, 0, ""),
  }


  return {
    {{pitch_control, structure_control}, {brightness_control, damp_control}},
    {{position_control}, {model_control, easteregg_control}},
    Pedal._default_params(id_prefix),
  }
end


return RingsPedal
