--- OverdrivePedal
-- @classmod OverdrivePedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

local OverdrivePedal = Pedal:new()
OverdrivePedal.id = "overdrive"

function OverdrivePedal:new()
  local i = Pedal:new()
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Drive & Tone"},
    Pedal._default_section(),
  }
  i.dial_drive = UI.Dial.new(22, 19.5, 22, 50, 0, 100, 1)
  i.dial_tone = UI.Dial.new(84.5, 19.5, 22, 50, 0, 100, 1)
  i.dials = {
    {{i.dial_drive, i.dial_tone}},
    Pedal._default_dials(),
  }
  i:_complete_initialization()

  return i
end

function OverdrivePedal:name(short)
  return short and "DRIVE" or "Overdrive"
end

function OverdrivePedal.add_params()
  -- There are 4 default_params, plus our custom 2
  params:add_group(OverdrivePedal:name(), 6)

  -- Must match this pedal's .sc file's *id
  id_prefix = OverdrivePedal.id

  drive_id = id_prefix .. "_drive"
  params:add({
    id = drive_id,
    name = "Drive",
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

  OverdrivePedal._param_ids = {
    {{drive_id, tone_id}},
    Pedal._add_default_params(id_prefix),
  }
end

function OverdrivePedal:_message_engine_for_param_change(param_id, value)
  engine[param_id](value / 100.0)
end

return OverdrivePedal
