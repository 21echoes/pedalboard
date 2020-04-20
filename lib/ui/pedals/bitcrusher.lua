--- BitcrusherPedal
-- @classmod BitcrusherPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local BitcrusherPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
BitcrusherPedal.id = "bitcrusher"

function BitcrusherPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Bits & Samples", "Tone & Gate"},
    i:_default_section(),
  }
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_tone"]:set_marker_position(1, 75)

  return i
end

function BitcrusherPedal:name(short)
  return short and "BITZ" or "Bitcrusher"
end

function BitcrusherPedal.params()
  local id_prefix = BitcrusherPedal.id

  local bitrate_control = {
    id = id_prefix .. "_bitrate",
    name = "Bit Rate",
    type = "control",
    controlspec = ControlSpec.new(4, 16, "lin", 0.25, 12, "bits"),
  }
  local samplerate_control = {
    id = id_prefix .. "_samplerate",
    name = "Sample Rate",
    type = "control",
    controlspec = ControlSpec.new(1000, 48000, "lin", 1000, 48000, "Hz"),
  }
  local tone_control = {
    id = id_prefix .. "_tone",
    name = "Tone",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local gate_control = {
    id = id_prefix .. "_gate",
    name = "Noise Gate",
    type = "control",
    controlspec = Controlspecs.MIX,
  }

  return {
    {{bitrate_control, samplerate_control}, {tone_control, gate_control}},
    Pedal._default_params(id_prefix),
  }
end

return BitcrusherPedal
