--- EqualizerPedal
-- @classmod EqualizerPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local EqualizerPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
EqualizerPedal.id = "equalizer"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
EqualizerPedal.peak_cpu = 1

function EqualizerPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Lo Hz & dB", "Hi Hz & dB"},
    {"Mid Hz & dB", "Mid Q"},
    i:_default_section(),
  }
  i:_complete_initialization()
  -- i._param_id_to_widget[i.id .. "_ls_freq"].units = "Hz"
  -- i._param_id_to_widget[i.id .. "_ls_amp"].units = "dB"
  i._param_id_to_widget[i.id .. "_ls_amp"]:set_marker_position(1, 0)
  -- i._param_id_to_widget[i.id .. "_hs_freq"].units = "Hz"
  -- i._param_id_to_widget[i.id .. "_hs_amp"].units = "dB"
  i._param_id_to_widget[i.id .. "_hs_amp"]:set_marker_position(1, 0)
  -- i._param_id_to_widget[i.id .. "_mid_freq"].units = "Hz"
  -- i._param_id_to_widget[i.id .. "_mid_amp"].units = "dB"
  i._param_id_to_widget[i.id .. "_mid_amp"]:set_marker_position(1, 0)

  return i
end

function EqualizerPedal:name(short)
  return short and "EQ" or "Equalizer"
end

function EqualizerPedal.params()
  local id_prefix = EqualizerPedal.id

  local ls_freq_control = {
    id = id_prefix .. "_ls_freq",
    name = "Low Shelf Freq",
    type = "control",
    controlspec = ControlSpec.new(20, 400, "exp", 1, 70, "Hz"),
  }
  local ls_amp_control = {
    id = id_prefix .. "_ls_amp",
    name = "Low Shelf Gain",
    type = "control",
    controlspec = Controlspecs.BOOSTCUT,
  }
  local hs_freq_control = {
    id = id_prefix .. "_hs_freq",
    name = "High Shelf Freq",
    type = "control",
    controlspec = ControlSpec.new(1000, 20000, "exp", 1, 5000, "Hz"),
  }
  local hs_amp_control = {
    id = id_prefix .. "_hs_amp",
    name = "High Shelf Gain",
    type = "control",
    controlspec = Controlspecs.BOOSTCUT,
  }
  local mid_freq_control = {
    id = id_prefix .. "_mid_freq",
    name = "Mid Freq",
    type = "control",
    controlspec = ControlSpec.new(100, 8000, "exp", 1, 1200, "Hz"),
  }
  local mid_amp_control = {
    id = id_prefix .. "_mid_amp",
    name = "Mid Gain",
    type = "control",
    controlspec = Controlspecs.BOOSTCUT,
  }
  local mid_q_control = {
    id = id_prefix .. "_mid_q",
    name = "Mid Resonance",
    type = "control",
    controlspec = ControlSpec.new(0.1, 4, "lin", 0.1, 1, ""),
  }

  -- Default mix of 100%
  local default_params = Pedal._default_params(id_prefix)
  default_params[1][2].controlspec = Controlspecs.mix(100)

  return {
    {{ls_freq_control, ls_amp_control}, {hs_freq_control, hs_amp_control}},
    {{mid_freq_control, mid_amp_control}, {mid_q_control}},
    default_params,
  }
end

function EqualizerPedal:_message_engine_for_param_change(param_id, value)
  local ls_amp_param_id = self.id .. "_ls_amp"
  local hs_amp_param_id = self.id .. "_hs_amp"
  local mid_amp_param_id = self.id .. "_mid_amp"
  if param_id == ls_amp_param_id or param_id == hs_amp_param_id or param_id == mid_amp_param_id then
    engine[param_id](util.dbamp(value))
    return
  end
  Pedal._message_engine_for_param_change(self, param_id, value)
end

return EqualizerPedal
