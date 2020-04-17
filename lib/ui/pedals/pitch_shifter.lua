--- PitchShifterPedal
-- @classmod PitchShifterPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local PitchShifterPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
PitchShifterPedal.id = "pitchshifter"

local LIMIT_7_RATIOS = {16/15, 9/8, 6/5, 5/4, 4/3, 7/5, 3/2, 8/5, 5/3, 16/9, 15/8, 2}
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

function PitchShifterPedal._calculate_freq_mul(interval, just_temperament, fine)
  local mul_pre_fine
  if just_temperament then
    if interval == 0 then
      mul_pre_fine = 1
    else
      local negative_interval = interval < 0
      if negative_interval then interval = -interval end
      mul_pre_fine = LIMIT_7_RATIOS[((interval - 1) % 12) + 1] * math.ceil(interval / 12)
      if negative_interval then mul_pre_fine = 1 / mul_pre_fine end
    end
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
    local interval = param_id == interval_param_id and value or params:get(interval_param_id)
    if interval == nil then interval = 0 end
    local just_temperament = param_id == temperament_param_id and value == 0 or params:get(temperament_param_id) == 1
    if just_temperament == nil then just_temperament = true end
    local fine_tune = param_id == fine_tune_param_id and value or params:get(fine_tune_param_id)
    if fine_tune == nil then fine_tune = 0 end
    local freq_mul = self._calculate_freq_mul(interval, just_temperament, fine_tune)
    engine.pitchshifter_freq_mul(freq_mul)
    return
  end
  Pedal._message_engine_for_param_change(self, param_id, value)
end

return PitchShifterPedal
