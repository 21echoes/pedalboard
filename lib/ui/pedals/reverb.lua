--- ReverbPedal
-- @classmod ReverbPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

local ReverbPedal = Pedal:new()
ReverbPedal.id = "reverb"

function ReverbPedal:new()
  local i = Pedal:new()
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Size & Decay", "Tone"},
    Pedal._default_section(),
  }
  i.dial_size = UI.Dial.new(9, 12, 22, 50, 0, 100, 1)
  i.dial_decay = UI.Dial.new(34.5, 27, 22, 50, 0, 100, 1)
  i.dial_tone = UI.Dial.new(84.5, 19.5, 22, 50, 0, 100, 1)
  i.dials = {
    {{i.dial_size, i.dial_decay}, {i.dial_tone}},
    Pedal._default_dials(),
  }
  i:_complete_initialization()

  return i
end

function ReverbPedal:name(short)
  return short and "VERB" or "Reverb"
end

function ReverbPedal.add_params()
  -- There are 4 default_params, plus our custom 3
  params:add_group(ReverbPedal:name(), 7)

  -- Must match this pedal's .sc file's *id
  id_prefix = ReverbPedal.id

  size_id = id_prefix .. "_size"
  params:add({
    id = size_id,
    name = "Size",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  decay_id = id_prefix .. "_decay"
  params:add({
    id = decay_id,
    name = "Decay Time",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  tone_id = id_prefix .. "_tone"
  params:add({
    id = tone_id,
    name = "Tone",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  ReverbPedal._param_ids = {
    {{size_id, decay_id}, {tone_id}},
    Pedal._add_default_params(id_prefix),
  }
end

function ReverbPedal:_message_engine_for_param_change(param_id, value)
  engine[param_id](value / 100.0)
end

return ReverbPedal
