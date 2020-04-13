--- DelayPedal
-- @classmod DelayPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

local DelayPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
DelayPedal.id = "delay"

function DelayPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Time & Fdbk", "Quality & Mode"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function DelayPedal:name(short)
  return short and "DEL" or "Delay"
end

function DelayPedal.params()
  local id_prefix = DelayPedal.id

  -- TODO: different control that controls the exact time?
  local time_control = {
    id = id_prefix .. "_time",
    name = "Time",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }
  local feedback_control = {
    id = id_prefix .. "_feedback",
    name = "Feedback",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
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
    {{time_control, feedback_control}, {quality_control, mode_control}},
    Pedal._default_params(id_prefix)
  }
end

return DelayPedal
