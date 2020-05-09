--- ReverbPedal
-- @classmod ReverbPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local ReverbPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
ReverbPedal.id = "reverb"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
ReverbPedal.peak_cpu = 31

function ReverbPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Size & Decay", "Shimmer & Tone"},
    i:_default_section(),
  }
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_tone"]:set_marker_position(1, 75)

  return i
end

function ReverbPedal:name(short)
  return short and "VERB" or "Reverb"
end

function ReverbPedal.params()
  local id_prefix = ReverbPedal.id

  local size_control = {
    id = id_prefix .. "_size",
    name = "Size",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local decay_control = {
    id = id_prefix .. "_decay",
    name = "Decay Time",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local shimmer_control = {
    id = id_prefix .. "_shimmer",
    name = "Shimmer",
    type = "control",
    controlspec = Controlspecs.mix(0),
  }
  local tone_control = {
    id = id_prefix .. "_tone",
    name = "Tone",
    type = "control",
    controlspec = Controlspecs.MIX,
  }

  return {
    {{size_control, decay_control}, {shimmer_control, tone_control}},
    Pedal._default_params(id_prefix),
  }
end

return ReverbPedal
