--- Board
-- @classmod Board

local UI = require "ui"
local tabutil = require "tabutil"

local pedal_classes = {
  include("lib/ui/pedals/chorus"),
  include("lib/ui/pedals/delay"),
  include("lib/ui/pedals/distortion"),
  include("lib/ui/pedals/overdrive"),
  include("lib/ui/pedals/reverb"),
  include("lib/ui/pedals/tremolo"),
}
local MAX_SLOTS = math.min(4, #pedal_classes)
local EMPTY_PEDAL = "None"
local pedal_names = {EMPTY_PEDAL}
for i, pedal_class in ipairs(pedal_classes) do
  table.insert(pedal_names, pedal_class:name())
end
local CLICK_DURATION = 0.7

local Board = {}

function Board:new(
  add_page,
  remove_page,
  swap_page,
  set_page_index,
  mark_screen_dirty
)
  local i = {}
  setmetatable(i, self)
  self.__index = self

  -- Callbacks to our parent when we take page-editing actions
  i._add_page = add_page
  i._remove_page = remove_page
  i._swap_page = swap_page
  i._set_page_index = set_page_index
  i._mark_screen_dirty = mark_screen_dirty

  i.pedals = {}
  i._pending_pedal_class_index = 0
  i._alt_key_down_time = nil
  i._alt_action_taken = false
  i:_setup_tabs()
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

function Board:key(n, z)
  if n == 2 then
    -- Key down on K2 enables alt mode
    if z == 1 then
      self._alt_key_down_time = util.time()
      return false
    end

    -- Key up on K2 after an alt action was taken, or even just after a longer held time, counts as nothing
    key_down_duration = util.time() - self._alt_key_down_time
    self._alt_key_down_time = nil
    if self._alt_action_taken or key_down_duration > CLICK_DURATION then
      self._alt_action_taken = false
      return
    end

    -- Otherwise we count this key-up as a click on K2
    -- K2 click means nothing on the New slot
    if self:_is_new_slot(self.tabs.index) then
      return false
    end
    -- Jump to focused pedal's page
    self._set_page_index(self.tabs.index + 1)
    return true
  elseif n == 3 then
    -- Key-up on K3 has no meaning
    if z == 0 then
      return false
    end

    -- Alt+K3 means toggle bypass on current pedal
    if self:_is_alt_mode() then
      if self:_is_new_slot(self.tabs.index) then
        -- No bypass to toggle on the New slot
        return false
      end
      self.pedals[self.tabs.index]:toggle_bypass()
      self._alt_action_taken = true
      return true
    end

    param_value = self:_pending_pedal_class() and self:_param_value_for_pedal_name(self:_pending_pedal_class():name()) or 1

    -- We're on the "New?" slot, so add the pending pedal
    if self:_is_new_slot(self.tabs.index) then
      params:set("pedal_" .. self.tabs.index, param_value)
      return true
    end

    -- We're on an existing slot, and the pending pedal type is different than the current type
    if self:_slot_has_pending_switch(self.tabs.index) then
      params:set("pedal_" .. self.tabs.index, param_value)
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
    -- Alt+E3 changes wet/dry
    if self:_is_alt_mode() then
      if self:_is_new_slot(self.tabs.index) then
        -- No wet/dry to change on the New slot
        return false
      end
      self.pedals[self.tabs.index]:scroll_mix(delta)
      self._alt_action_taken = true
      return true
    end

    -- Change the type of pedal we're considering adding or switching to
    if self:_pending_pedal_class() == nil then
      self._pending_pedal_class_index = 0
    end
    -- Allow selecting EMPTY_PEDAL to remove the pedal
    minimum = 0
    -- We don't want to allow selection of a pedal already in use in another slot
    -- (primarily due to technical restrictions in how params work)
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

function Board:cleanup()
  -- Remove possible circular references
  self._add_page = nil
  self._remove_page = nil
  self._swap_page = nil
  self._set_page_index = nil
  self._mark_screen_dirty = nil
end

function Board:_setup_tabs()
  tab_names = {}
  use_short_names = self:_use_short_names()
  for i, pedal in ipairs(self.pedals) do
    table.insert(tab_names, pedal:name(use_short_names))
  end
  -- Only add the New slot if we're not yet at the max
  if #self.pedals ~= MAX_SLOTS then
    table.insert(tab_names, "New?")
  end
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
        use_short_names = self:_use_short_names()
        screen.move(center_x, center_y - 4)
        screen.text_center(use_short_names and "+" or "Add")
        screen.move(center_x, center_y + 4)
        screen.text_center(self:_name_of_pending_pedal())
      end
      -- Prevent a stray line being drawn
      screen.stroke()
      return
    elseif self:_slot_has_pending_switch(i) then
      use_short_names = self:_use_short_names()
      if self:_pending_pedal_class() == nil then
        -- Render "Remove" as centered text
        screen.move(center_x, center_y)
        screen.text_center(use_short_names and "X" or "Remove")
      else
        -- Render "Switch to {name of the new pedal}" as centered text
        screen.move(center_x, center_y - 4)
        screen.text_center(use_short_names and "->" or "Switch to")
        screen.move(center_x, center_y + 4)
        screen.text_center(self:_name_of_pending_pedal())
      end
      -- Prevent a stray line being drawn
      screen.stroke()
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
    -- The EMPTY_PEDAL is definitely a switch!
    return true
  end
  return pending_pedal_class.__index ~= self.pedals[i].__index
end

function Board:_name_of_pending_pedal()
  pending_pedal_class = self:_pending_pedal_class()
  use_short_names = self:_use_short_names()
  if pending_pedal_class == nil then
    return use_short_names and "None" or "No Selection"
  end
  return pending_pedal_class:name(use_short_names)
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
  pedal_class_index = name_index - 1

  -- The parent has a page for each pedal at 1 beyond the slot index on the board
  page_index = slot + 1

  if pedal_class_index == 0 then
    -- This option means we are removing the pedal in this slot
    -- The engine is zero-indexed
    engine_index = slot - 1
    engine.remove_pedal_at_index(engine_index)
    table.remove(self.pedals, slot)
    self:_setup_tabs()
    self:_set_pending_pedal_class_to_match_tab(self.tabs.index)
    self._remove_page(page_index)
    return
  end
  pedal_class = pedal_classes[pedal_class_index]
  -- If this slot index is beyond our existing pedals, it adds a new pedal
  if slot > #self.pedals then
    pedal_instance = pedal_class:new()
    engine.add_pedal(pedal_instance.id)
    table.insert(self.pedals, pedal_instance)
    self:_setup_tabs()
    self._add_page(pedal_instance)
  else
    -- Otherwise, it swaps out an existing pedal for a new one
    -- If this is just the same pedal that's already there, do nothing
    if pedal_class.__index == self.pedals[slot].__index then
      return
    end
    pedal_instance = pedal_class:new()
    -- The engine is zero-indexed
    engine_index = slot - 1
    engine.swap_pedal_at_index(engine_index, pedal_instance.id)
    self.pedals[slot] = pedal_instance
    self:_setup_tabs()
    self._swap_page(page_index, pedal_instance)
  end
  self._set_page_index(page_index)
  self._mark_screen_dirty(true)
end

function Board:_is_alt_mode()
  return self._alt_key_down_time ~= nil
end

return Board
