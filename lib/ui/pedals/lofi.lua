--- LoFiPedal
-- @classmod LoFiPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local LoFiPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
LoFiPedal.id = "lofi"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
LoFiPedal.peak_cpu = 6

function LoFiPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Drive & Tone", "Wow & Noise"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function LoFiPedal:name(short)
  return short and "LO-FI" or "Lo-Fi"
end

function LoFiPedal.params()
  local id_prefix = LoFiPedal.id

  local drive_control = {
    id = id_prefix .. "_drive",
    name = "Drive",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local tone_control = {
    id = id_prefix .. "_tone",
    name = "Tone",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local wow_control = {
    id = id_prefix .. "_wow",
    name = "Wow",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local noise_control = {
    id = id_prefix .. "_noise",
    name = "Noise",
    type = "control",
    controlspec = Controlspecs.MIX,
  }

  -- Default mix of 100%
  local default_params = Pedal._default_params(id_prefix)
  default_params[1][2].controlspec = Controlspecs.mix(100)

  return {
    {{drive_control, tone_control}, {wow_control, noise_control}},
    default_params,
  }
end

return LoFiPedal
