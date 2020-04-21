--- Board
-- @classmod Board

local ControlSpec = require "controlspec"
local UI = require "ui"
local tabutil = require "tabutil"
local Controlspecs = include("lib/ui/util/controlspecs")
local ScreenState = include("lib/ui/util/screen_state")

-- All possible pedals, ordered by something like how common they are
local pedal_classes = {
  include("lib/ui/pedals/delay"),
  include("lib/ui/pedals/reverb"),
  include("lib/ui/pedals/overdrive"),
  include("lib/ui/pedals/chorus"),
  include("lib/ui/pedals/tremolo"),
  include("lib/ui/pedals/distortion"),
  include("lib/ui/pedals/flanger"),
  include("lib/ui/pedals/compressor"),
  include("lib/ui/pedals/sustain"),
  include("lib/ui/pedals/bitcrusher"),
  include("lib/ui/pedals/equalizer"),
  include("lib/ui/pedals/tuner"),
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
  insert_page_at_index,
  remove_page,
  swap_page,
  set_page_index
)
  local i = {}
  setmetatable(i, self)
  self.__index = self

  -- Callbacks to our parent when we take page-editing actions
  i._add_page = add_page
  i._insert_page_at_index = insert_page_at_index
  i._remove_page = remove_page
  i._swap_page = swap_page
  i._set_page_index = set_page_index

  i.pedals = {}
  i._pending_pedal_class_index = 0
  i._manual_action_will_require_param_sync = false
  i._is_syncing_to_params = false
  i._alt_key_down_time = nil
  i._alt_action_taken = false
  i._add_bypassed = false
  i:_setup_tabs()
  i:_add_param_actions()

  return i
end

function Board:add_params()
  params:add({
    id="num_input_channels",
    name="Input Mode",
    type="option",
    options={"Mono", "Stereo"},
    default=(params:get('monitor_mode') == 1 and 2 or 1),
    action=function(value)
      local coerced_value = value
      if value == "Stereo" then coerced_value = 2 elseif value == "Mono" then coerced_value = 1 end
      engine.set_num_input_channels(coerced_value)
    end
  })
  params:add({
    id="input_amp",
    name="Input Gain",
    type="control",
    controlspec=Controlspecs.BOOSTCUT,
    action=function(value) engine.set_input_amp(util.dbamp(value)) end
  })
  params:add({
    id="output_amp",
    name="Output Gain",
    type="control",
    controlspec=Controlspecs.BOOSTCUT,
    action=function(value) engine.set_output_amp(util.dbamp(value)) end
  })

  -- Don't add the group, as for now we're just hiding these params
  -- params:add_group("Board", MAX_SLOTS)
  for i = 1, MAX_SLOTS do
    local param_id = "pedal_" .. i
    params:add({
      id=param_id,
      name="Pedal " .. i,
      type="option",
      options=pedal_names,
      -- actions are set up during construction in _add_param_actions
    })
    -- We're primarily hiding these because this page's UI enforces certain ways to change the board,
    -- while editing via params directly removes some of those restrictions in ways that are difficult to handle
    -- (e.g., putting EMPTY_PEDAL between other pedals, selecting the same pedal twice, etc.))
    -- TODO: figure out why norns/lua/core/paramset:hide doesn't lookup string param_ids for hiding properly
    params:hide(params.lookup[param_id])
  end

  -- Tell each pedal type to set up its params
  for i, pedal_class in ipairs(pedal_classes) do
    pedal_class:add_params()
  end
end

function Board:_add_param_actions()
  for i = 1, MAX_SLOTS do
    local param_id = "pedal_" .. i
    params:set_action(param_id, function(value)
      self:_set_pedal_by_index(i, value)
    end)
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
      -- Record what tab we started on for our K2+E2 pedal reordering feature (ignoring the new slot)
      if not self:_is_new_slot(self.tabs.index) then
        self._reorder_source = self.tabs.index
        self._reorder_destination = self.tabs.index
      end
      return false
    end

    -- Key up on K2 after scrolling E2 commits a pedal re-order
    if self._reorder_source ~= self._reorder_destination then
      self._alt_key_down_time = nil
      self._alt_action_taken = false
      self:_reorder_pedals()
      return true
    end

    -- Key up on K2 after an alt action was taken, or even just after a longer held time, counts as nothing
    if self._alt_key_down_time then
      local key_down_duration = util.time() - self._alt_key_down_time
      self._alt_key_down_time = nil
      if self._alt_action_taken or key_down_duration > CLICK_DURATION then
        self._alt_action_taken = false
        return false
      end
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

    local add_or_switch = self:_is_new_slot(self.tabs.index) or self:_slot_has_pending_switch(self.tabs.index)

    -- Alt+K3 means toggle bypass on current pedal
    if self:_is_alt_mode() and not self:_is_new_slot(self.tabs.index) and not add_or_switch then
      self.pedals[self.tabs.index]:toggle_bypass()
      self._alt_action_taken = true
      return true
    end

    local param_value = self:_pending_pedal_class() and self:_param_value_for_pedal_name(self:_pending_pedal_class():name()) or 1
    -- If we are in alt mode when adding or swapping a pedal, we want to make the new pedal already bypassed
    self._add_bypassed = false
    if self:_is_alt_mode() and param_value ~= 1 then
      self._add_bypassed = true
      -- In some sense an alt-action was taken, but we're going to turn off alt mode immediately here anyway
      self._alt_action_taken = false
      self._alt_key_down_time = nil
    end

    -- We're on the new slot, so add the pending pedal
    if self:_is_new_slot(self.tabs.index) then
      params:set("pedal_" .. self.tabs.index, param_value)
      return true
    end

    -- We're on an existing slot, and the pending pedal type is different than the current type
    if self:_slot_has_pending_switch(self.tabs.index) then
      if param_value == 1 then
        -- If we're removing a pedal, we're going to need to do some local->param syncing
        self._manual_action_will_require_param_sync = true
      end
      params:set("pedal_" .. self.tabs.index, param_value)
      return true
    end
  end

  return false
end

function Board:enc(n, delta)
  if n == 2 then
    -- Alt+E2 re-orders pedals
    if self:_is_alt_mode() then
      -- Alt+E2 doesn't do anything on the New slot
      if self:_is_new_slot(self.tabs.index) then
        return false
      end
      self._alt_action_taken = true
      local direction = util.clamp(delta, -1, 1)
      self._reorder_destination = util.clamp(self._reorder_destination + direction, 1, #self.pedals)
      self:_setup_tabs()
      return true
    end

    -- Change which pedal slot is focused
    self.tabs:set_index_delta(util.clamp(delta, -1, 1), false)
    self:_set_pending_pedal_class_to_match_tab(self.tabs.index)
    return true
  elseif n == 3 then
    -- Alt+E3 changes wet/dry
    if self:_is_alt_mode() then
      -- Alt+E3 doesn't do anything on the New slot
      if self:_is_new_slot(self.tabs.index) then
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
    local minimum = 0
    -- We don't want to allow selection of a pedal already in use in another slot
    -- (primarily due to technical restrictions in how params work)
    -- So we make list of pedal classes in the same order as master list, but removing classes in use by other tabs
    local indexes_of_active_pedals = {}
    local current_pedal_class_index_at_current_tab = 0
    for i = 1, #self.pedals do
      local pedal_class_index = self:_get_pedal_class_index_for_tab(i)
      table.insert(indexes_of_active_pedals, pedal_class_index)
      if i == self.tabs.index then
        current_pedal_class_index_at_current_tab = pedal_class_index
      end
    end
    local valid_pedal_classes = {}
    local pending_index_in_valid_classes = minimum
    for i, pedal_class in ipairs(pedal_classes) do
      if i == current_pedal_class_index_at_current_tab or not tabutil.contains(indexes_of_active_pedals, i) then
        table.insert(valid_pedal_classes, pedal_class)
        if i == self._pending_pedal_class_index then
          pending_index_in_valid_classes = #valid_pedal_classes
        end
      end
    end
    -- We then take our index within that more limited list, and have the encoder scroll us within the limited list
    local new_index_in_valid_classes = util.clamp(pending_index_in_valid_classes + delta, minimum, #valid_pedal_classes)
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
  if self._sync_to_params_on_next_redraw then
    self:_sync_pedals_to_params(true)
  end
  self.tabs:redraw()
  for i, title in ipairs(self.tabs.titles) do
    render_index = i
    -- If we're mid-pedal-reorder, render the after-reorder state
    if self._reorder_source ~= self._reorder_destination then
      if self._reorder_source > self._reorder_destination then
        if i == self._reorder_destination then
          render_index = self._reorder_source
        elseif i > self._reorder_destination and i <= self._reorder_source then
          render_index = i - 1
        end
      else
        if i == self._reorder_destination then
          render_index = self._reorder_source
        elseif i >= self._reorder_source and i < self._reorder_destination then
          render_index = i + 1
        end
      end
    end
    self:_render_tab_content(render_index)
  end
end

function Board:cleanup()
  -- Remove possible circular references
  self._add_page = nil
  self._remove_page = nil
  self._swap_page = nil
  self._set_page_index = nil
end

function Board:_setup_tabs()
  local tab_names = {}
  local use_short_names = self:_use_short_names()
  for i, pedal in ipairs(self.pedals) do
    pedal_name_index = i
    -- If we're mid-pedal-reorder, render the after-reorder state
    if self._reorder_source ~= self._reorder_destination then
      if self._reorder_source > self._reorder_destination then
        if i == self._reorder_destination then
          pedal_name_index = self._reorder_source
        elseif i > self._reorder_destination and i <= self._reorder_source then
          pedal_name_index = i - 1
        end
      else
        if i == self._reorder_destination then
          pedal_name_index = self._reorder_source
        elseif i >= self._reorder_source and i < self._reorder_destination then
          pedal_name_index = i + 1
        end
      end
    end
    table.insert(tab_names, self.pedals[pedal_name_index]:name(use_short_names))
  end
  -- Only add the New slot if we're not yet at the max
  if #self.pedals ~= MAX_SLOTS then
    local new_pedal_title = #self.pedals == 0 and "Add Pedal?" or "Add?"
    table.insert(tab_names, new_pedal_title)
  end
  self.tabs = UI.Tabs.new(1, tab_names)
  -- If we're mid-pedal-reorder, show the reorder destination as the active tab
  if self._reorder_destination then
    self.tabs:set_index(self._reorder_destination)
  end
end

function Board:_render_tab_content(i)
  local offset, width = self:_get_offset_and_width(i)
  if i == self.tabs.index then
    local center_x = offset + (width / 2)
    local center_y = 38
    if self:_is_new_slot(i) then
      if self:_pending_pedal_class() == nil then
        -- Render "No Pedal Selected" as centered text
        screen.move(center_x, center_y)
        screen.text_center(self:_name_of_pending_pedal())
      else
        -- Render "Add {name of the new pedal}" as centered text
        screen.move(center_x, center_y - 4)
        screen.text_center(self:_use_short_names() and "+" or "Add")
        screen.move(center_x, center_y + 4)
        screen.text_center(self:_name_of_pending_pedal())
      end
      -- Prevent a stray line being drawn
      screen.stroke()
      return
    elseif self._reorder_source ~= self._reorder_destination and i == self._reorder_destination then
      -- Render "Move here" as centered text
      screen.level(15)
      screen.move(center_x, center_y - 4)
      screen.text_center("Move")
      screen.move(center_x, center_y + 4)
      screen.text_center("here")
      -- Prevent a stray line being drawn
      screen.stroke()
      return
    elseif self:_slot_has_pending_switch(i) then
      local use_short_names = self:_use_short_names()
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

  -- If we're mid-pedal-reorder, render the after-reorder state
  render_as_active = i == self.tabs.index
  if self._reorder_source ~= self._reorder_destination then
    -- We've already rendered a tab as active in this case
    render_as_active = false
    if self._reorder_source > self._reorder_destination then
      if i == self._reorder_destination then
        i = self._reorder_source
      elseif i > self._reorder_destination and i <= self._reorder_source then
        i = i - 1
      end
    else
      if i == self._reorder_destination then
        i = self._reorder_source
      elseif i >= self._reorder_source and i < self._reorder_destination then
        i = i + 1
      end
    end
  end
  -- Defer to the pedal instance to render as tab
  self.pedals[i]:render_as_tab(offset, width, render_as_active)
end

function Board:_get_offset_and_width(i)
  local num_tabs = (#self.tabs.titles == 0) and 1 or #self.tabs.titles
  local width = 128 / num_tabs
  local offset = width * (i - 1)
  return offset, width
end

function Board:_pending_pedal_class()
  if self._pending_pedal_class_index == nil or self._pending_pedal_class_index == 0 then
    return nil
  end
  return pedal_classes[self._pending_pedal_class_index]
end

function Board:_slot_has_pending_switch(i)
  local pending_pedal_class = self:_pending_pedal_class()
  if self:_pending_pedal_class() == nil then
    -- The EMPTY_PEDAL is definitely a switch!
    return true
  end
  return pending_pedal_class.__index ~= self.pedals[i].__index
end

function Board:_name_of_pending_pedal()
  local pending_pedal_class = self:_pending_pedal_class()
  local use_short_names = self:_use_short_names()
  if pending_pedal_class == nil then
    if #self.pedals == 0 then
      return "E3 to choose, K3 to add"
    end
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

  local pedal_class_at_i = self.pedals[i].__index
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

function Board:_is_alt_mode()
  return self._alt_key_down_time ~= nil
end

function Board:_param_value_for_pedal_name(_pedal_name)
  for i, pedal_name in ipairs(pedal_names) do
    if pedal_name == _pedal_name then
      return i
    end
  end
  return 1
end

function Board:_reorder_pedals()
  local pedal_instance_to_move = self.pedals[self._reorder_source]

  -- remove pedal at reorder_source
  engine.remove_pedal_at_index(self._reorder_source - 1) -- The engine is zero-indexed
  table.remove(self.pedals, self._reorder_source)
  self._remove_page(self._reorder_source + 1, false) -- The parent has a page for each pedal at 1 beyond the slot index on the board

  -- insert the pedal at reorder_destination
  engine.insert_pedal_at_index(self._reorder_destination - 1, pedal_instance_to_move.id) -- The engine is zero-indexed
  table.insert(self.pedals, self._reorder_destination, pedal_instance_to_move)
  self._insert_page_at_index(self._reorder_destination + 1, pedal_instance_to_move) -- The parent has a page for each pedal at 1 beyond the slot index on the board

  -- Re-initialize tabs, pending pedal class, sync params, and clear out re-order state
  local reorder_destination = self._reorder_destination
  self._reorder_source = nil
  self._reorder_destination = nil
  self:_setup_tabs()
  self.tabs:set_index(reorder_destination)
  self:_set_pending_pedal_class_to_match_tab(self.tabs.index)
  self:_sync_pedals_to_params(force)
end

function Board:_set_pedal_by_index(slot, name_index)
  if self._is_syncing_to_params then
    -- See _sync_pedals_to_params for explanation
    if slot == MAX_SLOTS then
      self._is_syncing_to_params = false
      self._manual_action_will_require_param_sync = false
    end
    return
  end

  local pedal_class_index = name_index - 1

  -- The parent has a page for each pedal at 1 beyond the slot index on the board
  local page_index = slot + 1

  if pedal_class_index == 0 then
    -- This option means we are removing the pedal in this slot
    local engine_index = slot - 1 -- The engine is zero-indexed
    engine.remove_pedal_at_index(engine_index)
    table.remove(self.pedals, slot)
    self:_sync_pedals_to_params()
    self:_setup_tabs()
    self:_set_pending_pedal_class_to_match_tab(self.tabs.index)
    self._remove_page(page_index, true)
    return
  end
  pedal_class = pedal_classes[pedal_class_index]
  -- If this slot index is beyond our existing pedals, it adds a new pedal
  if slot > #self.pedals then
    -- pedal instantiation
    local pedal_instance = pedal_class:new(self._add_bypassed)
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
    -- pedal instantiation
    local pedal_instance = pedal_class:new(self._add_bypassed)
    -- The engine is zero-indexed
    local engine_index = slot - 1
    engine.swap_pedal_at_index(engine_index, pedal_instance.id)
    self.pedals[slot] = pedal_instance
    self:_setup_tabs()
    self._swap_page(page_index, pedal_instance)
  end
  self._add_bypassed = false
  self._set_page_index(page_index)
  ScreenState.mark_screen_dirty(true)
end

function Board:_sync_pedals_to_params(force)
  -- Removing a pedal or changing pedal order affects more parameters than just one.
  -- This function keeps the board's and engine's pedal list in sync with the parameter values
  -- by iterating over all the slots and setting the parameter to the board's value.
  -- During this process, we turn off the normal param-setting side-effects
  -- (as we got here via the side-effect we wanted and the board's pedals are in the right state.
  -- we don't want more side-effects)
  if force or self._manual_action_will_require_param_sync then
    self._sync_to_params_on_next_redraw = false
    self._is_syncing_to_params = true
    for i = 1, MAX_SLOTS do
      local param_id = "pedal_" .. i
      local param_value = 1 -- the EMPTY_PEDAL param_value if there's no pedal at self.pedals[i]
      if i <= #self.pedals then
        param_value = self:_param_value_for_pedal_name(self.pedals[i]:name())
      end
      local current_value = params:get(param_id)
      if current_value ~= param_value then
        params:set(param_id, param_value)
      elseif i == MAX_SLOTS then
        -- params:set has no effect if current value == param_value.
        -- So, if we would have cleaned up as a side-effect of the param's action (which we do when i == MAX_SLOTS),
        -- we instead clean up in here directly
        self._is_syncing_to_params = false
        self._manual_action_will_require_param_sync = false
      end
    end
  else
    -- This happened via the norns menu, not an in-app action.
    -- If they're in the norns menu and just took an editing action,
    -- it would be confusing to alter/overwrite their edits.
    -- Instead, sync params once we're back in this app (detected via a call to redraw)
    self._sync_to_params_on_next_redraw = true
  end
end

return Board
