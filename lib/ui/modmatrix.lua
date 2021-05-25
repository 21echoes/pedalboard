--- ModMatrix
-- @classmod ModMatrix

local UI = require "ui"
local ScreenState = include("lib/ui/util/screen_state")
local Label = include("lib/ui/util/label")
local ModMatrixUtil = include("lib/ui/util/modmatrix")

local ModMatrix = {}

function ModMatrix:new()
  local i = {}
  setmetatable(i, self)
  self.__index = self

  i.modmatrix = ModMatrixUtil:new()
  i.rows = {}
  i.x = 1
  i.y = 1
  i._arcify = nil

  return i
end

function ModMatrix:add_params(pedal_classes)
  local mm = self.modmatrix
  if mm == nil then
    mm = ModMatrixUtil:new()
  end
  mm:init(pedal_classes)
end

-- TODO: refactor this to share code better with add_params/init
function ModMatrix:arcify_register(arcify)
  local mm = self.modmatrix
  if mm == nil then
    mm = ModMatrixUtil:new()
  end
  mm:arcify_register(arcify)
end

-- TODO: refactor this to share code better with add_params/init
function ModMatrix:crowify_register(crowify)
  local mm = self.modmatrix
  if mm == nil then
    mm = ModMatrixUtil:new()
  end
  mm:crowify_register(crowify)
end

-- Called when the page is scrolled to
function ModMatrix:enter(arcify)
  self._arcify = arcify
  self:_arcify_maybe_follow()
end

function ModMatrix:cleanup()
  self.modmatrix:cleanup()
  self._arcify = nil
end

function ModMatrix:add_pedal(pedal, index)
  self.modmatrix:add_pedal(pedal, index)
  self:_calculate_rows()
end

function ModMatrix:remove_pedal(index)
  self.modmatrix:remove_pedal(index)
  self:_calculate_rows()
end

function ModMatrix:_calculate_rows()
  local rows = {}
  for i = 1,#self.modmatrix.pedals do
    local pedal = self.modmatrix.pedals[i]
    table.insert(rows, { true, pedal:name() })
    for j, param_id in ipairs(pedal._param_ids_flat) do
      local param = pedal._params_by_id[param_id]
      if self.modmatrix.is_targetable(param) then
        table.insert(rows, { false, param })
      end
    end
  end
  self.rows = rows
  self.y = util.clamp(self.y, 1, self:_total_num_rows())
  ScreenState.mark_screen_dirty(true)
end

function ModMatrix:key(n, z)
  -- Key-up currently has no meaning
  if z ~= 1 then
    return false
  end

  -- Change the focused column
  local direction = 0
  if n == 2 then
    direction = -1
  elseif n == 3 then
    direction = 1
  end
  self.x = util.clamp(self.x + direction, 1, self.modmatrix.lfos.number_of_outputs + 1)

  return true
end

local lfo_controls = {
  {"Enabled", "_lfo_enabled"},
  {"Shape", "_lfo_shape"},
  {"Freq", "_lfo_freq"},
  {"Depth", "_lfo_depth"},
  {"Offset", "_lfo_offset"},
}
local num_controls_per_lfo = #lfo_controls + 1
local envfol_controls = {
  {"Enabled", "envfol_enabled"},
  {"Gain", "envfol_depth"},
  {"Offset", "envfol_offset"},
  {"Smoothing", "envfol_smoothing"}
}
local num_envfol_controls = #envfol_controls + 1
local max_x = 125

function ModMatrix:_total_num_rows()
  local num_lfo_controls = num_controls_per_lfo * self.modmatrix.lfos.number_of_outputs
  local num_meta_controls = num_lfo_controls + num_envfol_controls
  return #self.rows + num_meta_controls
end

function ModMatrix:enc(n, delta)
  local num_lfo_controls = num_controls_per_lfo * self.modmatrix.lfos.number_of_outputs
  local num_meta_controls = num_lfo_controls + num_envfol_controls
  if n == 2 then
    local scroll_delta = util.clamp(delta, -1, 1)
    self.y = util.clamp(self.y + scroll_delta, 1, self:_total_num_rows())
    self:_arcify_maybe_follow()
  elseif n == 3 then
    if self.y > num_meta_controls then
      local row = self.rows[self.y - num_meta_controls]
      local is_title = row[1]
      if is_title then return false end
      local param = row[2]
      local param_id = self.modmatrix.param_id(param.id, self.x)
      params:delta(param_id, delta)
    elseif self.y > num_lfo_controls then
      local envfol_control_index = (self.y - num_lfo_controls - 1)
      local is_title = envfol_control_index == 0
      if is_title then return false end
      local envfol_control = envfol_controls[envfol_control_index]
      params:delta(envfol_control[2], delta)
    else
      local lfo_control_index = (self.y - 1) % num_controls_per_lfo
      local is_title = lfo_control_index == 0
      if is_title then return false end
      local lfo_num = math.floor((self.y - 1) / num_controls_per_lfo) + 1
      local lfo_control = lfo_controls[lfo_control_index]
      params:delta(lfo_num..lfo_control[2], delta)
    end
  end
  return true
end

function ModMatrix:redraw()
  -- Adapted from norns/lua/core/menu/params.lua
  local offset = self.y - 3
  local num_lfo_controls = num_controls_per_lfo * self.modmatrix.lfos.number_of_outputs
  local num_meta_controls = num_lfo_controls + num_envfol_controls
  for i=1,6 do
    local index = offset + i
    local row_index = index - num_meta_controls
    if i==3 then screen.level(15) else screen.level(4) end
    if index >= 1 and row_index < 1 then
      local envfol_index = row_index + num_envfol_controls - 1
      if envfol_index < 0 then
        local lfo_control_index = (index - 1) % num_controls_per_lfo
        local is_title = lfo_control_index == 0
        local lfo_num = math.floor((index - 1) / num_controls_per_lfo) + 1
        if is_title then
          screen.move(0,10*i+2.5)
          screen.line_rel(max_x,0)
          screen.stroke()
          screen.move(63,10*i)
          screen.text_center("LFO "..lfo_num)
        else
          local lfo_control = lfo_controls[lfo_control_index]
          screen.move(0,10*i)
          screen.text(lfo_control[1])
          screen.move(max_x,10*i)
          screen.text_right(params:string(lfo_num..lfo_control[2]))
        end
      else
        local is_title = envfol_index == 0
        if is_title then
          screen.move(0,10*i+2.5)
          screen.line_rel(max_x,0)
          screen.stroke()
          screen.move(63,10*i)
          screen.text_center("Envelope Follower")
        else
          local envfol_control = envfol_controls[envfol_index]
          screen.move(0,10*i)
          screen.text(envfol_control[1])
          screen.move(max_x,10*i)
          screen.text_right(params:string(envfol_control[2]))
        end
      end
    elseif row_index >= 1 and row_index <= #self.rows then
      local is_title = self.rows[row_index][1]
      if is_title then
        screen.move(0,10*i+2.5)
        screen.line_rel(max_x,0)
        screen.stroke()
        screen.move(63,10*i)
        screen.text_center("Mod Matrix: "..self.rows[row_index][2])
      else
        local param = self.rows[row_index][2]
        screen.move(0,10*i)
        screen.text(string.sub(param.name, 1, 10))
        local num_columns = self.modmatrix.lfos.number_of_outputs + 1
        for lfo_index = 1,num_columns do
          local param_id = self.modmatrix.param_id(param.id, lfo_index)
          screen.move(max_x - ((num_columns - lfo_index) * 22),10*i)
          if i==3 and self.x == lfo_index then screen.level(15) else screen.level(4) end
          screen.text_right(params:string(param_id))
        end
      end
    end
  end
end

function ModMatrix:_arcify_maybe_follow()
  if params:get("arc_mode") ~= 1 then return end
  local arcify = self._arcify
  if arcify == nil then return end

  local num_lfo_controls = num_controls_per_lfo * self.modmatrix.lfos.number_of_outputs
  local num_meta_controls = num_lfo_controls + num_envfol_controls
  if self.y > num_meta_controls then
    local row = self.rows[self.y - num_meta_controls]
    local is_title = row[1]
    if is_title then return end
    local param = row[2]
    for i=1,4 do
      arcify:map_encoder_via_params(i, self.modmatrix.param_id(param.id, i))
    end
    return
  end

  if self.y > num_lfo_controls then
    for i=1,4 do
      arcify:map_encoder_via_params(i, envfol_controls[i][2])
    end
    return
  end

  local lfo_num = math.floor((self.y - 1) / num_controls_per_lfo) + 1
  for i=1,4 do
    arcify:map_encoder_via_params(i, lfo_num..lfo_controls[i][2])
  end
end

return ModMatrix
