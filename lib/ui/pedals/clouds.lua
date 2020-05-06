--- CloudsPedal
-- @classmod CloudsPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local CloudsPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
CloudsPedal.id = "clouds"

function CloudsPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Pitch/Pos", "Size/Density"},
    {"Texture/Stereo", "Fdbk/Mode"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function CloudsPedal:name(short)
  return short and "CLOUD" or "MI Clouds"
end

function CloudsPedal.params()
  local id_prefix = CloudsPedal.id

  local pitch_control = {
    id = id_prefix .. "_pit",
    name = "Pitch Shift",
    type = "control",
    controlspec = ControlSpec.new(-48, 48, "lin", 1, 0, "st"),
  }
  local pos_control = {
    id = id_prefix .. "_pos",
    name = "Position",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local size_control = {
    id = id_prefix .. "_size",
    name = "Size",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local dens_control = {
    id = id_prefix .. "_dens",
    name = "Density",
    type = "control",
    controlspec = Controlspecs.mix(33),
  }
  local tex_control = {
    id = id_prefix .. "_tex",
    name = "Texture",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local spread_control = {
    id = id_prefix .. "_spread",
    name = "Stereo Spread",
    type = "control",
    controlspec = Controlspecs.mix(0),
  }
  local fb_control = {
    id = id_prefix .. "_fb",
    name = "Feedback",
    type = "control",
    controlspec = Controlspecs.mix(20),
  }
  -- TODO: changing mode should rename the tabs to match what the controls do in the new mode
  local mode_control = {
    id = id_prefix .. "_mode",
    name = "Mode",
    type = "option",
    options = {"Granular", "Pitch Shift", "Looper", "Spectral"}
  }

  -- TODO: add lofi and freeze

  return {
    {{pitch_control, pos_control}, {size_control, dens_control}},
    {{tex_control, spread_control}, {fb_control, mode_control}},
    Pedal._default_params(id_prefix),
  }
end


return CloudsPedal
