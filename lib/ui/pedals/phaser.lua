--- PhaserPedal
-- @classmod PhaserPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local PhaserPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
PhaserPedal.id = "phaser"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
PhaserPedal.peak_cpu = 2

function PhaserPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Rate & Depth"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function PhaserPedal:name(short)
  return short and "PHSR" or "Phaser"
end

function PhaserPedal.params()
  local id_prefix = PhaserPedal.id

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

  return {
    {{rate_control, depth_control}},
    Pedal._default_params(id_prefix),
  }
end

return PhaserPedal
