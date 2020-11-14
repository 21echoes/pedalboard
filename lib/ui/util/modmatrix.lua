local hnds = include("lib/ui/util/hnds")
local ScreenState = include("lib/ui/util/screen_state")
local ControlSpec = require "controlspec"
local tabutil = require "tabutil"

if _ModMatrix ~= nil then
  return _ModMatrix
end
_ModMatrixInstance = nil

_ModMatrix = {}
_ModMatrix.__index = _ModMatrix

local MAX_SLOTS = 4 -- TODO: somehow get from board.lua?
local NIL = 0

function _ModMatrix:new(i)
  if _ModMatrixInstance ~= nil then
    return _ModMatrixInstance
  end

  i = i or {}
  setmetatable(i, _ModMatrix)
  i.__index = _ModMatrix
  i.EMPTY = NIL
  i.lfos = hnds
  i.amp_poll_l = nil
  i.amp_l = 0
  i.amp_poll_r = nil
  i.amp_r = 0
  i.has_initialized = false
  i.pedals = {}
  for j = 1, MAX_SLOTS do
    table.insert(i.pedals, NIL)
  end
  _ModMatrixInstance = i
  return i
end

function _ModMatrix:init(pedal_classes)
  if self.has_initialized then return end
  self.has_initialized = true
  self.pedal_classes = pedal_classes
  local num_targets = 0
  for pedal_index, pedal in ipairs(pedal_classes) do
    for i, param_id in ipairs(pedal._param_ids_flat) do
      local param = pedal._params_by_id[param_id]
      if self.is_targetable(param) then
        num_targets = num_targets + 1
      end
    end
  end
  self.lfos.init(num_targets, function(lfo_index) self:_add_mod_targets(lfo_index) end)

  params:add_group("Envelope Follower", 3 + num_targets)
  params:add_option("envfol_enabled", "Enabled", {"off", "on"}, 2)
  params:add_control("envfol_depth", "Gain", ControlSpec.new(0, 10, "lin", 0.1, 1))
  params:add_number("envfol_offset", "Offset", -100, 100, 0)
  params:add_number("envfol_smoothing", "Smoothing", 0, 10, 4)
  self:_add_mod_targets(self.lfos.number_of_outputs + 1)

  self.amp_poll_l = poll.set("amp_in_l")
  self.amp_poll_l.callback = function(value)
    self.amp_l = ((self.amp_l * params:get("envfol_smoothing")) + value) / (params:get("envfol_smoothing") + 1)
  end
  self.amp_poll_l.time = 0.02
  self.amp_poll_l:start()
  self.amp_poll_r = poll.set("amp_in_r")
  self.amp_poll_r.callback = function(value)
    self.amp_r = ((self.amp_r * params:get("envfol_smoothing")) + value) / (params:get("envfol_smoothing") + 1)
  end
  self.amp_poll_r.time = 0.02
  self.amp_poll_r:start()
end

local param_block_list = {
  "delay_bpm",
  "delay_beat_division",
}

function _ModMatrix.is_targetable(param)
  if param == nil then
    return false
  end
  if param.controlspec == nil and param.type ~= "option" then
    return false
  end
  return not tabutil.contains(param_block_list, param.id)
end

function _ModMatrix:_add_mod_targets(lfo_index)
  for pedal_index, pedal in ipairs(self.pedal_classes) do
    for i, param_id in ipairs(pedal._param_ids_flat) do
      local param = pedal._params_by_id[param_id]
      if self.is_targetable(param) then
        params:add({
          id=self.param_id(param_id, lfo_index),
          name=pedal:name().." "..param.name,
          type="number",
          min=-100,
          max=100,
          default=0,
          action=function(value)
            ScreenState.mark_screen_dirty(true)
          end
        })
      end
    end
  end
end

function _ModMatrix:cleanup()
  self.has_initialized = faslse
  self.lfos.cleanup()
  self.lfos = nil
  self.pedals = nil
end

function _ModMatrix:add_pedal(pedal, index)
  self.pedals[index] = pedal
end

function _ModMatrix:remove_pedal(index)
  self.pedals[index] = NIL
end

function _ModMatrix.param_id(param_id, lfo_index)
  return "modmatrix_"..param_id.."_"..lfo_index
end

function hnds.process()
  if _ModMatrixInstance == nil or _ModMatrixInstance.pedals == nil then return end
  for i, pedal in ipairs(_ModMatrixInstance.pedals) do
    if pedal ~= NIL then
      for i, param_id in ipairs(pedal._param_ids_flat) do
        local param = pedal._params_by_id[param_id]
        if _ModMatrix.is_targetable(param) then
          local value = params:get(param.id)
          -- Coerce to 0-indexed for the engine
          if param.type == "option" then
            value = value - 1
          end
          pedal:_message_engine_for_param_change(param.id, value)
        end
      end
    end
  end
end

function _ModMatrix:mod(param, value)
  if not self.is_targetable(param) then return value end
  if self.lfos == nil then return value end

  -- Transform the "real" range down to 0 -> 1
  local raw_value = 0
  if param.type == "option" then
    -- Options are 0-indexed at this point
    local num_options = #param.options
    raw_value = ((value * 2) + 1) / (num_options * 2.0)
  else
    raw_value = param.controlspec:unmap(value)
  end

  for i = 1, self.lfos.number_of_outputs do
    -- Check the LFO is enabled
    if params:get(i .. "lfo_enabled") == 2 then
      -- Get the LFO value scaled by the modmatrix
      local modmatrix_value = self.lfos[i].value * params:get(self.param_id(param.id, i)) * 0.01
      raw_value = raw_value + modmatrix_value
    end
  end
  -- Then modulate it by the envelope follower modmatrix
  if params:get("envfol_enabled") == 2 then
    local average_env = self.amp_l
    if params:get("num_input_channels") == 2 then
      average_env = (self.amp_l + self.amp_r) * 0.5
    end
    local envfol_modifier = (params:get("envfol_depth") * average_env) + (params:get("envfol_offset") * 0.01)
    local modmatrix_modifier = envfol_modifier * (params:get(self.param_id(param.id, self.lfos.number_of_outputs + 1)) * 0.01)
    raw_value = raw_value + modmatrix_modifier
  end

  -- Transform back to the real range
  if param.type == "option" then
    return math.floor(util.clamp(raw_value, 0, 0.99999) * #param.options)
  end
  return param.controlspec:map(raw_value)
end

return _ModMatrix
