--- SustainPedal
-- @classmod SustainPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

local SustainPedal = Pedal:new()
SustainPedal.id = "sustain"

function SustainPedal:new()
  local i = Pedal:new()
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Drive & Gate", "Tone"},
    Pedal._default_section(),
  }
  i.dial_drive = UI.Dial.new(9, 12, 22, 50, 0, 100, 1)
  i.dial_gate = UI.Dial.new(34.5, 25, 22, 50, 0, 100, 1)
  i.dial_tone = UI.Dial.new(84.5, 19.5, 22, 50, 0, 100, 1)
  i.dials = {
    {{i.dial_drive, i.dial_gate},  {i.dial_tone}},
    Pedal._default_dials(),
  }
  i:_complete_initialization()

  return i
end

function SustainPedal:name(short)
  return short and "SUS" or "Sustain"
end

function SustainPedal.add_params()
  -- There are 4 default_params, plus our custom 3
  params:add_group(SustainPedal:name(), 7)

  -- Must match this pedal's .sc file's *id
  id_prefix = SustainPedal.id

  drive_id = id_prefix .. "_drive"
  params:add({
    id = drive_id,
    name = "Drive",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  gate_id = id_prefix .. "_gate"
  params:add({
    id = gate_id,
    name = "Noise Gate",
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

  SustainPedal._param_ids = {
    {{drive_id, gate_id}, {tone_id}},
    Pedal._add_default_params(id_prefix),
  }
end

function SustainPedal:_message_engine_for_param_change(param_id, value)
  engine[param_id](value / 100.0)
end

return SustainPedal
