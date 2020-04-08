--- BitcrusherPedal
-- @classmod BitcrusherPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

local BitcrusherPedal = Pedal:new()
BitcrusherPedal.id = "bitcrusher"

function BitcrusherPedal:new()
  local i = Pedal:new()
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Bitrate & Tone"},
    Pedal._default_section(),
  }
  i.dial_bitrate = UI.Dial.new(22, 19.5, 22, 12, 4, 16, 0.25)
  i.dial_tone = UI.Dial.new(84.5, 19.5, 22, 50, 0, 100, 1)
  i.dials = {
    {{i.dial_bitrate, i.dial_tone}},
    Pedal._default_dials(),
  }
  i:_complete_initialization()

  return i
end

function BitcrusherPedal:name(short)
  return short and "BITZ" or "Bitcrusher"
end

function BitcrusherPedal.add_params()
  -- There are 4 default_params, plus our custom 2
  params:add_group(BitcrusherPedal:name(), 6)

  -- Must match this pedal's .sc file's *id
  id_prefix = BitcrusherPedal.id

  bitrate_id = id_prefix .. "_bitrate"
  params:add({
    id = bitrate_id,
    name = "Bitrate",
    type = "control",
    controlspec = ControlSpec.new(4, 16, "lin", 0.25, 12, "bits"),
  })

  tone_id = id_prefix .. "_tone"
  params:add({
    id = tone_id,
    name = "Tone",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  BitcrusherPedal._param_ids = {
    {{bitrate_id, tone_id}},
    Pedal._add_default_params(id_prefix),
  }
end

function BitcrusherPedal:_message_engine_for_param_change(param_id, value)
  if param_id == self.id .. "_bitrate" then
    -- Bitrate argument doesn't need to be coerced to between 0 and 1
    engine[param_id](value)
  else
    engine[param_id](value / 100.0)
  end
end

return BitcrusherPedal
