--- TremoloPedal
-- @classmod TremoloPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")

-- TODO: put these in a shared place
CONTROL_SPEC_MIX = ControlSpec.new(0, 100, "lin", 1, 50, "%")
CONTROL_SPEC_GAIN = ControlSpec.new(-60, 12, "lin", 0.5, 0, "dB")

local TremoloPedal = Pedal:new()
TremoloPedal.id = "tremolo"

function TremoloPedal:new()
  local i = Pedal:new()
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Rate & Depth"}, -- TODO: shape?
    Pedal._default_section(),
  }
  i.dial_rate = UI.Dial.new(22, 19.5, 22, 50, 0, 100, 1)
  i.dial_depth = UI.Dial.new(84.5, 19.5, 22, 50, 0, 100, 1)
  i.dials = {
    {{i.dial_rate, i.dial_depth}},
    Pedal._default_dials(),
  }
  i:_complete_initialization()

  return i
end

function TremoloPedal:name(short)
  return short and "TREM" or "Tremolo"
end

function TremoloPedal.add_params()
  -- There are 4 default_params, plus our custom 2
  params:add_group(TremoloPedal:name(), 6)

  -- Must match this pedal's .sc file's *id
  id_prefix = TremoloPedal.id

  rate_id = id_prefix .. "_rate"
  params:add({
    id = rate_id,
    name = "Rate",
    type = "control",
    controlspec = CONTROL_SPEC_MIX,
  })

  depth_id = id_prefix .. "_depth"
  params:add({
    id = depth_id,
    name = "Depth",
    type = "control",
    controlspec = CONTROL_SPEC_MIX,
  })

  TremoloPedal._param_ids = {
    {{rate_id, depth_id}},
    Pedal._add_default_params(id_prefix),
  }
end

function TremoloPedal:_message_engine_for_param_change(param_id, value)
  if param_id == "tremolo_rate" then
    engine.tremolo_rate(coerced_value / 100.0)
  elseif param_id == "tremolo_depth" then
    engine.tremolo_depth(coerced_value / 100.0)
  end
end

-- TODO: tap tempo

return TremoloPedal
