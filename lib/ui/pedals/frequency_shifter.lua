--- FrequencyShifterPedal
-- @classmod FrequencyShifterPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")

local FrequencyShifterPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
FrequencyShifterPedal.id = "frequencyshifter"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
FrequencyShifterPedal.peak_cpu = 1

function FrequencyShifterPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Freq & Phase"},
    i:_default_section(),
  }
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_freq"]:set_marker_position(1, 0)
  -- i._param_id_to_widget[i.id .. "_freq"].start_value = 0

  return i
end

function FrequencyShifterPedal:name(short)
  return short and "FREQ" or "Freq Shifter"
end

function FrequencyShifterPedal.params()
  local id_prefix = FrequencyShifterPedal.id

  local freq_control = {
    id = id_prefix .. "_freq",
    name = "Freq Coarse",
    type = "control",
    controlspec = ControlSpec.new(-333, 333, "lin", 0.001, 0, "Hz")
    -- controlspec = ControlSpec.new(0.01, 333, "exp", 0.001, 0.01, "Hz") -- exponential unipolar
  }
  local phase_control = {
    id = id_prefix .. "_phase",
    name = "Phase",
    type = "control",
    controlspec = ControlSpec.new(0, math.pi*2, "lin", 0.1, 0, "rad")
  }

  return {
    {{freq_control, phase_control}},
    Pedal._default_params(id_prefix),
  }
end

return FrequencyShifterPedal
