--- DelayPedal
-- @classmod DelayPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

local DelayPedal = Pedal:new()
DelayPedal.id = "delay"

function DelayPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Time & Mode", "Feedback"},
    i:_default_section(),
  }
  i.dial_time = UI.Dial.new(9, 12, 22, 50, 0, 100, 1)
  -- TODO: this should be a label
  i.dial_mode = UI.Dial.new(34.5, 25, 22, 0, 0, 1, 1)
  i.dial_feedback = UI.Dial.new(84.5, 19.5, 22, 50, 0, 100, 1)
  i.dials = {
    {{i.dial_time, i.dial_mode},  {i.dial_feedback}},
    i:_default_dials(),
  }
  i:_complete_initialization()

  return i
end

function DelayPedal:name(short)
  return short and "DEL" or "Delay"
end

function DelayPedal.add_params()
  -- There are 4 default_params, plus our custom 3
  params:add_group(DelayPedal:name(), 7)

  -- Must match this pedal's .sc file's *id
  id_prefix = DelayPedal.id

  time_id = id_prefix .. "_time"
  -- TODO: different control spec that controls the exact time
  params:add({
    id = time_id,
    name = "Time",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  mode_id = id_prefix .. "_mode"
  params:add({
    id = mode_id,
    name = "Mode",
    type = "option",
    options = {"Stereo", "Ping-Pong"},
  })

  feedback_id = id_prefix .. "_feedback"
  params:add({
    id = feedback_id,
    name = "Feedback",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  DelayPedal._param_ids = {
    {{time_id, mode_id}, {feedback_id}},
    Pedal._add_default_params(id_prefix),
  }
end

function DelayPedal:_set_value_from_param_value(param_id, value)
  coerced_value = value
  if param_id == self.id .. "_mode" then
    -- The options are 1-indexed, but the mode control expects 0-indexed
    coerced_value = value - 1
  end
  Pedal._set_value_from_param_value(self, param_id, coerced_value)
end

function DelayPedal:_message_engine_for_param_change(param_id, value)
  coerced_value = value / 100.0
  if param_id == self.id .. "_mode" then
    -- No dividing by 100 for the mode
    coerced_value = value
  end
  -- once we have explicit times, no /100 coercion for that param
  engine[param_id](coerced_value)
end

return DelayPedal
