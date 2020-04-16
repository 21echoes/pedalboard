--- OverdrivePedal
-- @classmod OverdrivePedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local OverdrivePedal = Pedal:new()
-- Must match this pedal's .sc file's *id
OverdrivePedal.id = "overdrive"

function OverdrivePedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Drive & Tone"},
    i:_default_section(),
  }
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_tone"]:set_marker_position(1, 75)

  return i
end

function OverdrivePedal:name(short)
  return short and "DRIVE" or "Overdrive"
end

function OverdrivePedal.params()
  local id_prefix = OverdrivePedal.id

  local drive_control = {
    id = id_prefix .. "_drive",
    name = "Drive",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }
  local tone_control = {
    id = id_prefix .. "_tone",
    name = "Tone",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }

  return {
    {{drive_control, tone_control}},
    Pedal._default_params(id_prefix),
  }
end

return OverdrivePedal
