--- DelayPedal
-- @classmod DelayPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

local DelayPedal = Pedal:new()
DelayPedal.id = "delay"

function DelayPedal:new()
  local i = Pedal:new()
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Time & Feedback"},
    Pedal._default_section(),
  }
  i.dial_time = UI.Dial.new(22, 19.5, 22, 50, 0, 100, 1)
  i.dial_feedback = UI.Dial.new(84.5, 19.5, 22, 50, 0, 100, 1)
  i.dials = {
    {{i.dial_time, i.dial_feedback}},
    Pedal._default_dials(),
  }
  i:_complete_initialization()

  return i
end

function DelayPedal:name(short)
  return short and "DEL" or "Delay"
end

function DelayPedal.add_params()
  -- There are 4 default_params, plus our custom 2
  params:add_group(DelayPedal:name(), 6)

  -- Must match this pedal's .sc file's *id
  id_prefix = DelayPedal.id

  time_id = id_prefix .. "_time"
  -- TODO: different control spec that controls the exact time
  params:add({
    id = time_id,
    name = "time",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  feedback_id = id_prefix .. "_feedback"
  params:add({
    id = feedback_id,
    name = "feedback",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  DelayPedal._param_ids = {
    {{time_id, feedback_id}},
    Pedal._add_default_params(id_prefix),
  }
end

function DelayPedal:_message_engine_for_param_change(param_id, value)
  -- once we have explicit times, no /100 coercion for that param
  engine[param_id](coerced_value / 100.0)
end

return DelayPedal
