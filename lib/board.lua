--- Board
-- @classmod Board

local UI = require "ui"
local VolumePedal = include("lib/pedals/volume")

local pedal_classes = {VolumePedal}

local Board = {}
Board.__index = Board

function Board.new()
  local i = {}
  setmetatable(i, Board)

  i.pedals = {}
  i.pending_pedal_class_index = 0
  i:_setup_tabs()

  return i
end

function Board:key(n, z, set_page_index, add_page, swap_page)
  -- Key-up currently has no meaning
  if z ~= 1 then
    return false
  end

  if n == 2 then
    -- K2 means nothing on the New slot
    if self:_is_new_slot(self.tabs.index) then
      return false
    end
    -- Jump to focused pedal's page
    set_page_index(self.tabs.index + 1)
    return true
  elseif n == 3 then
    -- No pedal swap is pending
    if self:_pending_pedal_class() == nil then
      return false
    end

    -- We're on the "New?" slot, so add the pending pedal
    if self:_is_new_slot(self.tabs.index) then
      initial_tab_index = self.tabs.index
      pedal_instance = self:_pending_pedal_class().new()
      table.insert(self.pedals, pedal_instance)
      self:_setup_tabs()
      add_page(pedal_instance)
      -- Jump to page for new pedal
      set_page_index(initial_tab_index + 1)
      return true
    end

    -- We're on an existing slot, and the pending pedal type is different than the current type
    if self:_slot_has_pending_switch(self.tabs.index) then
      initial_tab_index = self.tabs.index
      pedal_instance = self:_pending_pedal_class().new()
      self.pedals[initial_tab_index] = pedal_instance
      self:_setup_tabs()
      swap_page(initial_tab_index + 1, pedal_instance)
      -- Jump to page for new pedal
      set_page_index(initial_tab_index + 1)
      return true
    end
  end

  return false
end

function Board:enc(n, delta)
  if n == 2 then
    -- Change which pedal slot is focused
    self.tabs:set_index_delta(util.clamp(delta, -1, 1), false)
    -- TODO: set self.pending_pedal_class_index to the index of the pedal for the current slot, or 0 if on the New slot
    return true
  elseif n == 3 then
    -- Change the type of pedal we're considering adding or switching to
    if self:_pending_pedal_class() == nil then
      self.pending_pedal_class_index = 0
    end
    -- Clamp min as 1 if on active slot, or 0 if on New slot
    minimum = (not self:_is_new_slot(self.tabs.index)) and 1 or 0
    self.pending_pedal_class_index = util.clamp(self.pending_pedal_class_index + delta, minimum, #pedal_classes)
    return true
  end

  return false
end

function Board:redraw()
  self.tabs:redraw()
  for i, title in ipairs(self.tabs.titles) do
    self:_render_tab_content(i)
  end
end

function Board:_setup_tabs()
  tab_names = {}
  for i, pedal in ipairs(self.pedals) do
    table.insert(tab_names, pedal.name)
  end
  -- TODO: only add "New?" if below max
  table.insert(tab_names, "New?")
  self.tabs = UI.Tabs.new(1, tab_names)
end

function Board:_render_tab_content(i)
  offset, width = self:_get_offset_and_width(i)
  if i == self.tabs.index then
    center_x = offset + (width / 2)
    center_y = 38
    if self:_is_new_slot(i) then
      if self:_pending_pedal_class() == nil then
        -- Render "No Pedal Selected" as centered text
        screen.move(center_x, center_y)
        screen.text_center(self:_name_of_pending_pedal())
      else
        -- Render "Add {name of the new pedal}" as centered text
        screen.move(center_x, center_y - 4)
        screen.text_center("Add")
        screen.move(center_x, center_y + 4)
        screen.text_center(self:_name_of_pending_pedal())
      end
      return
    elseif self:_slot_has_pending_switch(i) then
      -- Render "Switch to {name of the new pedal}" as centered text
      screen.move(center_x, center_y - 4)
      screen.text_center("Switch to")
      screen.move(center_x, center_y + 4)
      screen.text_center(self:_name_of_pending_pedal())
      return
    end
  end
  -- TODO: Ask pedal instance to render as tab with width and offset
  -- self.pedals[i]:render_as_tab(offset, width)
end

function Board:_get_offset_and_width(i)
  num_tabs = (#self.tabs.titles == 0) and 1 or #self.tabs.titles
  width = 128 / num_tabs
  offset = width * (i - 1)
  return offset, width
end

function Board:_pending_pedal_class()
  if self.pending_pedal_class_index == nil or self.pending_pedal_class_index == 0 then
    return nil
  end
  return pedal_classes[self.pending_pedal_class_index]
end

function Board:_slot_has_pending_switch(i)
  if self:_pending_pedal_class() == nil then
    return false
  end
  return self:_name_of_pending_pedal() ~= self.pedals[i].name
end

function Board:_name_of_pending_pedal()
  pending_pedal_class = self:_pending_pedal_class()
  if pending_pedal_class == nil then
    return "No Selection"
  end
  return pending_pedal_class.name
end

function Board:_is_new_slot(i)
  -- TODO: return false if max slots are already full
  return i == #self.tabs.titles
end

return Board
