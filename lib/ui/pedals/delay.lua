--- DelayPedal
-- @classmod DelayPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")
local TapTempo = include("lib/ui/util/tap_tempo")

local DelayPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
DelayPedal.id = "delay"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
DelayPedal.peak_cpu = 7

function DelayPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Rate", "Feedback"},
    {"Quality & Mode"},
    i:_default_section(),
  }
  i._tap_tempo = TapTempo.new()
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_bpm"].units = "bpm"

  return i
end

function DelayPedal:name(short)
  return short and "DEL" or "Delay"
end

function DelayPedal.params()
  local id_prefix = DelayPedal.id

  local bpm_control = {
    id = id_prefix .. "_bpm",
    name = "BPM",
    type = "control",
    controlspec = ControlSpec.new(40, 240, "lin", 1, 110, "bpm")
  }
  local beat_division_control = {
    id = id_prefix .. "_beat_division",
    name = "Rhythm",
    type = "option",
    options = TapTempo.get_beat_division_options(),
    default = TapTempo.get_beat_division_default(),
  }
  local feedback_control = {
    id = id_prefix .. "_feedback",
    name = "Feedback",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local quality_control = {
    id = id_prefix .. "_quality",
    name = "Quality",
    type = "option",
    options = {"Digital", "Analog", "Tape", "Lo-Fi"},
  }
  local mode_control = {
    id = id_prefix .. "_mode",
    name = "Mode",
    type = "option",
    options = {"Default", "Ping-Pong"},
  }

  return {
    {{bpm_control, beat_division_control}, {feedback_control}},
    {{quality_control, mode_control}},
    Pedal._default_params(id_prefix)
  }
end

function DelayPedal:key(n, z)
  local tempo, short_circuit_value = self._tap_tempo:key(n, z)
  if tempo then
    params:set(self.id .. "_bpm", tempo)
  end
  if short_circuit_value ~= nil then
    return short_circuit_value
  end

  if n == 2 and z == 0 then
    -- If we didn't have tap-tempo behavior, we count this key-up as a click on K2
    -- (Superclass expects z==1 for a click)
    return Pedal.key(self, n, 1)
  end
  return Pedal.key(self, n, z)
end

function DelayPedal:_message_engine_for_param_change(param_id, value)
  local bpm_param_id = self.id .. "_bpm"
  local beat_division_param_id = self.id .. "_beat_division"
  if param_id == bpm_param_id or param_id == beat_division_param_id then
    local bpm = param_id == bpm_param_id and value or params:get(bpm_param_id)
    local beat_division_option = param_id == beat_division_param_id and value + 1 or params:get(beat_division_param_id)
    local dur = self._tap_tempo.tempo_and_division_to_dur(bpm, beat_division_option)
    engine.delay_time(dur)
    return
  end
  Pedal._message_engine_for_param_change(self, param_id, value)
end

return DelayPedal
