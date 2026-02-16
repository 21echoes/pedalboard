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
    {"Coarse & Fine", "Phase"},
    i:_default_section(),
  }
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_freq"]:set_marker_position(1, 0)
  i._param_id_to_widget[i.id .. "_freq"].start_value = 0
  i._param_id_to_widget[i.id .. "_freq_fine"]:set_marker_position(1, 0)
  i._param_id_to_widget[i.id .. "_freq_fine"].start_value = 0

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
    controlspec = ControlSpec.new(-333, 333, "lin", 1, 0, "Hz")
  }
  local freq_control_fine = {
    id = id_prefix .. "_freq_fine",
    name = "Freq Fine",
    type = "control",
    controlspec = ControlSpec.new(-7, 7, "lin", 0.001, 0, "Hz") -- range is circa a 1/100th of _freq's range.
  }
  local phase_control = {
    id = id_prefix .. "_phase",
    name = "Phase",
    type = "control",
    controlspec = ControlSpec.new(0, 2, "lin", 0.1, 0, "pi"),
    -- formatter = function(param) return util.round(param:get()/math., 0.01).." pi" end
  }

  return {
    {{freq_control, freq_control_fine}, {phase_control}},
    Pedal._default_params(id_prefix),
  }
end

function FrequencyShifterPedal:_message_engine_for_param_change(param_id, value)
   local freq_param_id      = self.id .. "_freq"
   local freq_fine_param_id = self.id .. "_freq_fine"
   local phase_param_id     = self.id .. "_phase"
   if param_id == freq_param_id or param_id == freq_fine_param_id then
      local raw_freq = param_id == freq_param_id and value or params:get(freq_param_id)
      if raw_freq == nil then raw_freq = 0 end
      local freq = self.modmatrix:mod(self._params_by_id[freq_param_id], raw_freq)

      local raw_freq_fine = param_id == freq_fine_param_id and value or params:get(freq_fine_param_id)
      if raw_freq_fine == nil then raw_freq_fine = 0 end
      local freq_fine = self.modmatrix:mod(self._params_by_id[freq_fine_param_id], raw_freq_fine)

      freq = freq + freq_fine
      engine.frequencyshifter_freq(freq)
      return
   elseif param_id == phase_param_id then
      local raw_phase = param_id == phase_param_id and value or params:get(phase_param_id)
      if raw_phase == nil then raw_phase = 0 end
      local phase = self.modmatrix:mod(self._params_by_id[phase_param_id], raw_phase)
      phase_rad = phase * math.pi
      engine.frequencyshifter_phase(phase_rad)
      return
   end
   Pedal._message_engine_for_param_change(self, param_id, value)
end

return FrequencyShifterPedal
