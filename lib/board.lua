--- Board
-- @classmod Board

local UI = require "ui"
local tabutil = require "tabutil"
local VolumePedal = include("lib/pedals/volume")

local pedal_classes = {VolumePedal}
local MAX_SLOTS = math.min(4, #pedal_classes)
local EMPTY_PEDAL = "EMPTY_PEDAL"
local pedal_names = {EMPTY_PEDAL}
for i, pedal_class in ipairs(pedal_classes) do
  table.insert(pedal_names, pedal_class.name())
end

local Board = {}
Board.__index = Board

function Board.new()
  local i = {}
  setmetatable(i, Board)

  i.pedals = {}
  i._pending_pedal_class_index = 0
  i:_setup_tabs()
  i:_reset_callbacks()
  i:_add_param_actions()

  return i
end

function Board:add_params()
  params:add_group("Board", MAX_SLOTS)
  for i = 1, MAX_SLOTS do
    param_id = "pedal_" .. i
    params:add({
      id=param_id,
      name="Pedal " .. i,
      type="option",
      options=pedal_names,
      -- actions are set up during construction in _add_param_actions
    })
  end

  -- Tell each pedal type to set up its params
  for i, pedal_class in ipairs(pedal_classes) do
    pedal_class.add_params()
  end
end

function Board:_add_param_actions()
  for i = 1, MAX_SLOTS do
    param_id = "pedal_" .. i
    params:set_action(param_id, function(value) self:_set_pedal_by_index(i, value) end)
  end
end

function Board:enter()
  -- Called when the page is scrolled to
  self.tabs:set_index(1)
  self:_set_pending_pedal_class_to_match_tab(self.tabs.index)
end

function Board:key(n, z, set_page_index, add_page, swap_page, mark_screen_dirty)
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
      -- Temporarily set these callbacks so the param setter callback can use them
      -- While a bit hacky, this is preferred to having a permanent reference to the parent class for now.
      -- This decision may be revisited later :+1:
      self._add_page = add_page
      self._set_page_index = set_page_index
      self._mark_screen_dirty = mark_screen_dirty
      params:set(
        "pedal_" .. self.tabs.index,
        self:_param_value_for_pedal_name(self:_pending_pedal_class().name())
      )
      return true
    end

    -- We're on an existing slot, and the pending pedal type is different than the current type
    if self:_slot_has_pending_switch(self.tabs.index) then
      -- See above note about these callbacks
      self._swap_page = swap_page
      self._set_page_index = set_page_index
      self._mark_screen_dirty = mark_screen_dirty
      params:set(
        "pedal_" .. self.tabs.index,
        self:_param_value_for_pedal_name(self:_pending_pedal_class().name())
      )
      return true
    end
  end

  return false
end

function Board:enc(n, delta)
  if n == 2 then
    -- Change which pedal slot is focused
    self.tabs:set_index_delta(util.clamp(delta, -1, 1), false)
    self:_set_pending_pedal_class_to_match_tab(self.tabs.index)
    return true
  elseif n == 3 then
    -- Change the type of pedal we're considering adding or switching to
    if self:_pending_pedal_class() == nil then
      self._pending_pedal_class_index = 0
    end
    -- Clamp min as 1 if on active slot, or 0 if on New slot
    -- TODO: allow selecting EMPTY_PEDAL to remove the pedal
    minimum = (not self:_is_new_slot(self.tabs.index)) and 1 or 0
    -- We don't want to allow selection of a pedal already in use in another slot
    -- (primarily due to technical restrictions in how params and SC engines work)
    -- So we make list of pedal classes in the same order as master list, but removing classes in use by other tabs
    indexes_of_active_pedals = {}
    current_pedal_class_index_at_current_tab = 0
    for i = 1, #self.pedals do
      pedal_class_index = self:_get_pedal_class_index_for_tab(i)
      table.insert(indexes_of_active_pedals, pedal_class_index)
      if i == self.tabs.index then
        current_pedal_class_index_at_current_tab = pedal_class_index
      end
    end
    valid_pedal_classes = {}
    pending_index_in_valid_classes = minimum
    for i, pedal_class in ipairs(pedal_classes) do
      if i == current_pedal_class_index_at_current_tab or not tabutil.contains(indexes_of_active_pedals, i) then
        table.insert(valid_pedal_classes, pedal_class)
        if i == self._pending_pedal_class_index then
          pending_index_in_valid_classes = #valid_pedal_classes
        end
      end
    end
    -- We then take our index within that more limited list, and have the encoder scroll us within the limited list
    new_index_in_valid_classes = util.clamp(pending_index_in_valid_classes + delta, minimum, #valid_pedal_classes)
    -- Finally, we map this index within the limited list back to the index in the master list
    if new_index_in_valid_classes == 0 then
      -- If we've selected EMPTY_PEDAL, then we don't need to do any more work, just use that directly
      self._pending_pedal_class_index = 0
    else
      self._pending_pedal_class_index = tabutil.key(pedal_classes, valid_pedal_classes[new_index_in_valid_classes])
    end
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
  use_short_names = self:_use_short_names()
  for i, pedal in ipairs(self.pedals) do
    table.insert(tab_names, pedal.name(use_short_names))
  end
  -- Only add the New slot if we're not yet at the max
  if #self.pedals ~= MAX_SLOTS then
    table.insert(tab_names, "New?")
  end
  self.tabs = UI.Tabs.new(1, tab_names)
end

function Board:_reset_callbacks()
  self._set_page_index = nil
  self._add_page = nil
  self._swap_page = nil
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
        use_short_names = self:_use_short_names()
        screen.move(center_x, center_y - 4)
        screen.text_center(use_short_names and "+" or "Add")
        screen.move(center_x, center_y + 4)
        screen.text_center(self:_name_of_pending_pedal())
      end
      return
    elseif self:_slot_has_pending_switch(i) then
      -- Render "Switch to {name of the new pedal}" as centered text
      use_short_names = self:_use_short_names()
      screen.move(center_x, center_y - 4)
      screen.text_center(use_short_names and "->" or "Switch to")
      screen.move(center_x, center_y + 4)
      screen.text_center(self:_name_of_pending_pedal())
      return
    end
  end

  -- The New slot renders nothing if not highlighted
  if self:_is_new_slot(i) then
    return
  end

  -- Defer to the pedal instance to render as tab
  self.pedals[i]:render_as_tab(offset, width, i == self.tabs.index)
end

function Board:_get_offset_and_width(i)
  num_tabs = (#self.tabs.titles == 0) and 1 or #self.tabs.titles
  width = 128 / num_tabs
  offset = width * (i - 1)
  return offset, width
end

function Board:_pending_pedal_class()
  if self._pending_pedal_class_index == nil or self._pending_pedal_class_index == 0 then
    return nil
  end
  return pedal_classes[self._pending_pedal_class_index]
end

function Board:_slot_has_pending_switch(i)
  pending_pedal_class = self:_pending_pedal_class()
  if self:_pending_pedal_class() == nil then
    return false
  end
  return pending_pedal_class.__index ~= self.pedals[i].__index
end

function Board:_name_of_pending_pedal()
  pending_pedal_class = self:_pending_pedal_class()
  use_short_names = self:_use_short_names()
  if pending_pedal_class == nil then
    return use_short_names and " " or "No Selection"
  end
  return pending_pedal_class.name(use_short_names)
end

function Board:_is_new_slot(i)
  -- None of the slots are the New slot if we're already at the maximum number of slots
  if #self.pedals == MAX_SLOTS then
    return false
  end
  return i == #self.tabs.titles
end

function Board:_get_pedal_class_index_for_tab(i)
  if self:_is_new_slot(i) then
    return 0
  end

  pedal_class_at_i = self.pedals[i].__index
  -- TODO: port to tabutil.key
  for i, pedal_class in ipairs(pedal_classes) do
    if pedal_class_at_i == pedal_class then
      return i
    end
  end
end

function Board:_set_pending_pedal_class_to_match_tab(i)
  self._pending_pedal_class_index = self:_get_pedal_class_index_for_tab(i)
end

function Board:_use_short_names()
  return #self.pedals >= 2
end

function Board:_param_value_for_pedal_name(_pedal_name)
  for i, pedal_name in ipairs(pedal_names) do
    if pedal_name == _pedal_name then
      return i
    end
  end
  return 1
end

function Board:_set_pedal_by_index(slot, name_index)
  -- TODO: this temp callback assignment strategy doesn't seem to work with editing the board from the params menu
  pedal_class_index = name_index - 1
  if pedal_class_index == 0 then
    -- TODO: remove pedal from pages, shift the remaining down
    return
  end
  pedal_class = pedal_classes[pedal_class_index]
  -- The parent has a page for each pedal at 1 beyond the slot index on the board
  page_index = slot + 1
  -- If this slot index is beyond our existing pedals, it adds a new pedal
  if slot > #self.pedals then
    pedal_instance = pedal_class.new()
    table.insert(self.pedals, pedal_instance)
    self:_setup_tabs()
    self._add_page(pedal_instance)
  else
    -- Otherwise, it swaps out an existing pedal for a new one
    -- If this is just the same pedal that's already there, do nothing
    if pedal_class.__index == self.pedals[slot].__index then
      return
    end
    pedal_instance = pedal_class.new()
    self.pedals[slot] = pedal_instance
    self:_setup_tabs()
    self._swap_page(page_index, pedal_instance)
  end
  self._set_page_index(page_index)
  self._mark_screen_dirty(true)
  self:_reset_callbacks()
end

return Board
