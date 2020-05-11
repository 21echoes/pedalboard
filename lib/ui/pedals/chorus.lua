--- ChorusPedal
-- @classmod ChorusPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local ChorusPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
ChorusPedal.id = "chorus"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
ChorusPedal.peak_cpu = 1

function ChorusPedal:new(bypass_by_default)
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

function ChorusPedal:name(short)
  return short and "CHO" or "Chorus"
end

function ChorusPedal.params()
  local id_prefix = ChorusPedal.id

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

return ChorusPedal
