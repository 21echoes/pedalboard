--- TremoloPedal
-- @classmod TremoloPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

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
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  depth_id = id_prefix .. "_depth"
  params:add({
    id = depth_id,
    name = "Depth",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  })

  TremoloPedal._param_ids = {
    {{rate_id, depth_id}},
    Pedal._add_default_params(id_prefix),
  }
end

function TremoloPedal:_message_engine_for_param_change(param_id, value)
  engine[param_id](value / 100.0)
end

-- TODO: tap tempo

return TremoloPedal
