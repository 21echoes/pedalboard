--- BitcrusherPedal
-- @classmod BitcrusherPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

local BitcrusherPedal = Pedal:new()
BitcrusherPedal.id = "bitcrusher"

function BitcrusherPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Bits & Samples", "Tone & Gate"},
    i:_default_section(),
  }
  i.dial_bitrate = UI.Dial.new(9, 12, 22, 12, 4, 16, 0.25)
  i.dial_samplerate = UI.Dial.new(34.5, 25, 22, 48000, 1000, 48000, 1000)
  i.dial_tone = UI.Dial.new(72, 12, 22, 50, 0, 100, 1)
  i.dial_gate = UI.Dial.new(97, 25, 22, 50, 0, 100, 1)
  i.dials = {
    {{i.dial_bitrate, i.dial_samplerate}, {i.dial_tone, i.dial_gate}},
    i:_default_dials(),
  }
  i:_complete_initialization()

  return i
end

function BitcrusherPedal:name(short)
  return short and "BITZ" or "Bitcrusher"
end

function BitcrusherPedal.add_params()
  -- There are 4 default_params, plus our custom 3
  params:add_group(BitcrusherPedal:name(), 7)

  -- Must match this pedal's .sc file's *id
  local id_prefix = BitcrusherPedal.id

  local bitrate_id = id_prefix .. "_bitrate"
  params:add({
    id = bitrate_id,
    name = "Bit Rate",
    type = "control",
    controlspec = ControlSpec.new(4, 16, "lin", 0.25, 12, "bits"),
  })

  local samplerate_id = id_prefix .. "_samplerate"
  params:add({
    id = samplerate_id,
    name = "Sample Rate",
    type = "control",
    controlspec = ControlSpec.new(1000, 48000, "lin", 1000, 48000, "Hz"),
  })

  local tone_id = id_prefix .. "_tone"
  params:add({
    id = tone_id,
    name = "Tone",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  local gate_id = id_prefix .. "_gate"
  params:add({
    id = gate_id,
    name = "Noise Gate",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  BitcrusherPedal._param_ids = {
    {{bitrate_id, samplerate_id}, {tone_id, gate_id}},
    Pedal._add_default_params(id_prefix),
  }
end

function BitcrusherPedal:_message_engine_for_param_change(param_id, value)
  if param_id == self.id .. "_bitrate" or param_id == self.id .. "_samplerate" then
    -- Bitrate and samplerate arguments don't need to be coerced to between 0 and 1
    engine[param_id](value)
  else
    engine[param_id](value / 100.0)
  end
end

return BitcrusherPedal
