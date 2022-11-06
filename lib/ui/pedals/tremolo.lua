--- TremoloPedal
-- @classmod TremoloPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")
local TapTempo = include("lib/ui/util/tap_tempo")

local TremoloPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
TremoloPedal.id = "tremolo"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
TremoloPedal.peak_cpu = 1

function TremoloPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Rate", "Depth & Shape"},
    -- TODO: bias, symmetry
    {"Stereo Phase"},
    i:_default_section(),
  }
  i._tap_tempo = TapTempo.new()
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_bpm"].units = "bpm"
  i._param_id_to_widget[i.id .. "_shape"]:set_marker_position(1, 33)
  i._param_id_to_widget[i.id .. "_shape"]:set_marker_position(2, 67)
  i._param_id_to_widget[i.id .. "_stereo_phase"].units = "°"

  return i
end

function TremoloPedal:name(short)
  return short and "TREM" or "Tremolo"
end

function TremoloPedal.params()
  local id_prefix = TremoloPedal.id

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
  local depth_control = {
    id = id_prefix .. "_depth",
    name = "Depth",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local shape_control = {
    id = id_prefix .. "_shape",
    name = "Shape",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local stereo_phase_control = {
    id = id_prefix .. "_stereo_phase",
    name = "Stereo Phase",
    type = "control",
    controlspec = ControlSpec.new(0, 360, "lin", 1, 0, "°"),
  }

  -- Default mix of 100%
  local default_params = Pedal._default_params(id_prefix)
  default_params[1][2].controlspec = Controlspecs.mix(100)

  return {
    {{bpm_control, beat_division_control}, {depth_control, shape_control}},
    {{stereo_phase_control}},
    default_params
  }
end

function TremoloPedal:key(n, z)
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

function TremoloPedal:_message_engine_for_param_change(param_id, value)
  local bpm_param_id = self.id .. "_bpm"
  local beat_division_param_id = self.id .. "_beat_division"
  if param_id == bpm_param_id or param_id == beat_division_param_id then
    local raw_bpm = param_id == bpm_param_id and value or params:get(bpm_param_id)
    local bpm = self.modmatrix:mod(self._params_by_id[bpm_param_id], raw_bpm)
    local raw_beat_division_option = param_id == beat_division_param_id and value + 1 or params:get(beat_division_param_id)
    local beat_division_option = self.modmatrix:mod(self._params_by_id[beat_division_param_id], raw_beat_division_option - 1) + 1
    local dur = self._tap_tempo.tempo_and_division_to_dur(bpm, beat_division_option)
    engine.tremolo_time(dur)
    return
  end
  Pedal._message_engine_for_param_change(self, param_id, value)
end

return TremoloPedal
