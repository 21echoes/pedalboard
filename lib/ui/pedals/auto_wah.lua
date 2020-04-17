--- AutoWahPedal
-- @classmod AutoWahPedal

local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local AutoWahPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
AutoWahPedal.id = "autowah"

function AutoWahPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Rate & Depth", "Resonance"},
    {"Mode & Sensitivity"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function AutoWahPedal:name(short)
  return short and "WAWA" or "Auto-Wah"
end

function AutoWahPedal.params()
  local id_prefix = AutoWahPedal.id

  local rate_control = {
    id = id_prefix .. "_rate",
    name = "Rate",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local depth_control = {
    id = id_prefix .. "_depth",
    name = "Depth",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local res_control = {
    id = id_prefix .. "_res",
    name = "Resonance",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local mode_control = {
    id = id_prefix .. "_mode",
    name = "Mode",
    type = "option",
    options = {"Low-Pass", "Band-Pass", "High-Pass"},
  }
  local sensitivity_control = {
    id = id_prefix .. "_sensitivity",
    name = "Sensitivity",
    type = "control",
    controlspec = Controlspecs.MIX,
  }

  -- Default mix of 85%
  local default_params = Pedal._default_params(id_prefix)
  default_params[1][2].controlspec = Controlspecs.mix(85)

  return {
    {{rate_control, depth_control}, {res_control}},
    {{mode_control, sensitivity_control}},
    default_params,
  }
end

return AutoWahPedal
