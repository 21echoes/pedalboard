--- VibratoPedal
-- @classmod VibratoPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local VibratoPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
VibratoPedal.id = "vibrato"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
VibratoPedal.peak_cpu = 13

function VibratoPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Rate & Depth", "Expression"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function VibratoPedal:name(short)
  return short and "VIBE" or "Vibrato"
end

function VibratoPedal.params()
  local id_prefix = VibratoPedal.id

  local rate_control = {
    id = id_prefix .. "_rate",
    name = "Rate",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local depth_control = {
    id = id_prefix .. "_depth",
    name = "Depth",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local expression_control = {
    id = id_prefix .. "_expression",
    name = "Expression",
    type = "control",
    controlspec = Controlspecs.MIX,
  }

  -- Default mix of 100%
  local default_params = Pedal._default_params(id_prefix)
  default_params[1][2].controlspec = Controlspecs.mix(100)

  return {
    {{rate_control, depth_control}, {expression_control}},
    default_params,
  }
end

return VibratoPedal
