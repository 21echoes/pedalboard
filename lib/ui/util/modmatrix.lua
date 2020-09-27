local hnds = include("lib/ui/util/hnds")
local ScreenState = include("lib/ui/util/screen_state")

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
  local num_lfo_targets = 0
  for pedal_index, pedal in ipairs(pedal_classes) do
    for i, param_id in ipairs(pedal._param_ids_flat) do
      local param = pedal._params_by_id[param_id]
      if self.is_targetable(param) then
        num_lfo_targets = num_lfo_targets + 1
      end
    end
  end
  self.lfos.init(num_lfo_targets, function(lfo_index) self:_add_lfo_targets(lfo_index) end)
end

function _ModMatrix.is_targetable(param)
  return param ~= nil and param.controlspec ~= nil
end

function _ModMatrix:_add_lfo_targets(lfo_index)
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
          pedal:_message_engine_for_param_change(param.id, params:get(param.id))
        end
      end
    end
  end
end

function _ModMatrix:mod(param, value)
  if not self.is_targetable(param) then return value end
  if self.lfos == nil then return value end
  -- Transform the "real" range down to 0 -> 1
  local raw_value = param.controlspec:unmap(value)
  for i = 1, self.lfos.number_of_outputs do
    -- Check the LFO is enabled
    if params:get(i .. "lfo_enabled") == 2 then
      -- Get the LFO value scaled by the modmatrix
      local modmatrix_value = self.lfos[i].value * params:get(self.param_id(param.id, i)) * 0.01
      raw_value = raw_value + modmatrix_value
    end
  end
  -- Transform back to the real range
  local result = param.controlspec:map(raw_value)
  return result
end

return _ModMatrix
