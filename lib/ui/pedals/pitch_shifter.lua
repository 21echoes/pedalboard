--- PitchShifterPedal
-- @classmod PitchShifterPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")
local JustIntonation = include("lib/ui/util/just_intonation")

local PitchShifterPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
PitchShifterPedal.id = "pitchshifter"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
PitchShifterPedal.peak_cpu = 1

local SEMITONE = math.pow(2, 1/12)
local CENT = math.pow(2, 1/1200)

function PitchShifterPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Interval", "Tuning & Drift"},
    i:_default_section(),
  }
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_interval"]:set_marker_position(1, 0)
  i._param_id_to_widget[i.id .. "_interval"].start_value = 0

  return i
end

function PitchShifterPedal:name(short)
  return short and "PITCH" or "Pitch Shifter"
end

function PitchShifterPedal.params()
  local id_prefix = PitchShifterPedal.id

  local interval_control = {
    id = id_prefix .. "_interval",
    name = "Interval",
    type = "control",
    controlspec = ControlSpec.new(-24, 24, "lin", 1, 7, "st"),
  }
  local temperament_control = {
    id = id_prefix .. "_temperament",
    name = "Temperament",
    type = "option",
    options = {"JUST-7", "12-TET"},
  }
  local fine_tune_control = {
    id = id_prefix .. "_fine_tune",
    name = "Fine Tuning",
    type = "control",
    controlspec = ControlSpec.new(-50, 50, "lin", 1, 0, "cents"),
  }
  local drift_control = {
    id = id_prefix .. "_drift",
    name = "Drift",
    type = "control",
    controlspec = Controlspecs.mix(0)
  }

  return {
    {{interval_control, temperament_control}, {fine_tune_control, drift_control}},
    Pedal._default_params(id_prefix),
  }
end

function PitchShifterPedal._calculate_freq_mul(interval, just_intonation, fine)
  local mul_pre_fine
  if just_intonation then
    mul_pre_fine = JustIntonation.calculate_freq_mul(interval)
  else
    mul_pre_fine = math.pow(SEMITONE, interval)
  end
  return mul_pre_fine * math.pow(CENT, fine)
end

function PitchShifterPedal:_message_engine_for_param_change(param_id, value)
  local interval_param_id = self.id .. "_interval"
  local temperament_param_id = self.id .. "_temperament"
  local fine_tune_param_id = self.id .. "_fine_tune"
  if param_id == interval_param_id or param_id == temperament_param_id or param_id == fine_tune_param_id then
    local raw_interval = param_id == interval_param_id and value or params:get(interval_param_id)
    if raw_interval == nil then raw_interval = 0 end
    local interval = self.modmatrix:mod(self._params_by_id[interval_param_id], raw_interval)
    local raw_just_intonation = param_id == temperament_param_id and value == 0 or params:get(temperament_param_id) == 1
    if raw_just_intonation == nil then raw_just_intonation = true end
    local just_intonation = self.modmatrix:mod(self._params_by_id[temperament_param_id], raw_just_intonation)
    local raw_fine_tune = param_id == fine_tune_param_id and value or params:get(fine_tune_param_id)
    if raw_fine_tune == nil then raw_fine_tune = 0 end
    local fine_tune = self.modmatrix:mod(self._params_by_id[fine_tune_param_id], raw_fine_tune)
    local freq_mul = self._calculate_freq_mul(interval, just_intonation, fine_tune)
    engine.pitchshifter_freq_mul(freq_mul)
    return
  end
  Pedal._message_engine_for_param_change(self, param_id, value)
end

return PitchShifterPedal
