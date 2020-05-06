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
    {"Position", "Model/Alt"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function RingsPedal:name(short)
  return short and "RNGS" or "MI Rings"
end

function RingsPedal.params()
  local id_prefix = RingsPedal.id

  local pitch_control = {
    id = id_prefix .. "_pit",
    name = "Pitch",
    type = "control",
    -- TODO: ideally this would be 0-127, but controlspecs larger than ~100 steps can skip values
    controlspec = ControlSpec.new(24, 103, "lin", 1, 60, ""), -- c3 by default
  }
  local structure_control = {
    id = id_prefix .. "_struct",
    name = "Structure",
    type = "control",
    controlspec = Controlspecs.mix(28),
  }
  local brightness_control = {
    id = id_prefix .. "_bright",
    name = "Brightness",
    type = "control",
    controlspec = Controlspecs.MIX,
  }

  local damp_control = {
    id = id_prefix .. "_damp",
    name = "Damping",
    type = "control",
    controlspec = Controlspecs.MIX,
  }

  local position_control = {
    id = id_prefix .. "_pos",
    name = "Position",
    type = "control",
    controlspec = Controlspecs.mix(33),
  }

  local model_control = {
    id = id_prefix .. "_model",
    name = "Model",
    type = "option",
    options = {"Modal", "Sym. Strings", "String", "FM", "Chords", "Karplusverb"},
  }

  -- TODO: changing mode should rename the tabs to match what the controls do in the new mode
  -- also, show different words for the models?
  local easteregg_control = {
    id = id_prefix .. "_easteregg",
    name = "Disastrous Peace",
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
