--- FlangerPedal
-- @classmod FlangerPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

local FlangerPedal = Pedal:new()
FlangerPedal.id = "flanger"

function FlangerPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Rate & Depth", "Fdbk & Delay"},
    i:_default_section(),
  }
  i.dial_rate = UI.Dial.new(9, 12, 22, 50, 0, 100, 1)
  i.dial_depth = UI.Dial.new(34.5, 25, 22, 50, 0, 100, 1)
  i.dial_feedback = UI.Dial.new(72, 12, 22, 50, 0, 100, 1)
  i.dial_predelay = UI.Dial.new(97, 25, 22, 50, 0, 100, 1)
  i.dials = {
    {{i.dial_rate, i.dial_depth}, {i.dial_feedback, i.dial_predelay}},
    i:_default_dials(),
  }
  i:_complete_initialization()

  return i
end

function FlangerPedal:name(short)
  return short and "FLNG" or "Flanger"
end

function FlangerPedal.add_params()
  -- There are 4 default_params, plus our custom 4
  params:add_group(FlangerPedal:name(), 8)

  -- Must match this pedal's .sc file's *id
  id_prefix = FlangerPedal.id

  rate_id = id_prefix .. "_rate"
  params:add({
    id = rate_id,
    name = "Rate",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  depth_id = id_prefix .. "_depth"
  params:add({
    id = depth_id,
    name = "Depth",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  feedback_id = id_prefix .. "_feedback"
  params:add({
    id = feedback_id,
    name = "Feedback",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  predelay_id = id_prefix .. "_predelay"
  params:add({
    id = predelay_id,
    name = "Pre-delay",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  FlangerPedal._param_ids = {
    {{rate_id, depth_id}, {feedback_id, predelay_id}},
    Pedal._add_default_params(id_prefix),
  }
end

function FlangerPedal:_message_engine_for_param_change(param_id, value)
  engine[param_id](value / 100.0)
end

return FlangerPedal
