--- WavefolderPedal
-- @classmod WavefolderPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local WavefolderPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
WavefolderPedal.id = "wavefolder"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
WavefolderPedal.peak_cpu = 5

function WavefolderPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Amt & Smooth", "Sym & Expr"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function WavefolderPedal:name(short)
  return short and "FOLD" or "Wavefolder"
end

function WavefolderPedal.params()
  local id_prefix = WavefolderPedal.id

  local amount_control = {
    id = id_prefix .. "_amount",
    name = "Amount",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local smoothing_control = {
    id = id_prefix .. "_smoothing",
    name = "Smoothing",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local symmetry_control = {
    id = id_prefix .. "_symmetry",
    name = "Symmetry",
    type = "control",
    controlspec = Controlspecs.mix(100),
  }
  local expression_control = {
    id = id_prefix .. "_expression",
    name = "Expression",
    type = "control",
    controlspec = Controlspecs.MIX,
  }

  return {
    {{amount_control, smoothing_control}, {symmetry_control, expression_control}},
    Pedal._default_params(id_prefix),
  }
end

return WavefolderPedal
