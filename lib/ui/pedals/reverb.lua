--- ReverbPedal
-- @classmod ReverbPedal

local ControlSpec = require "controlspec"
local UI = require "ui"

CONTROL_SPEC_MIX = ControlSpec.new(0, 100, "lin", 1, 50, "%")
CONTROL_SPEC_GAIN = ControlSpec.new(-60, 12, "lin", 0.5, 0, "dB")

local ReverbPedal = {}
ReverbPedal.__index = ReverbPedal
ReverbPedal.id = "reverb"

function ReverbPedal.new()
  local i = {}
  setmetatable(i, ReverbPedal)

  i.section_index = 1;
  i.sections = {
    {"Size & Decay", "Tone"},
    {"Bypass & Mix", "In & Out Gains"},
  }
  i:_update_section()

  -- TODO: helpers for all this positioning logic & etc
  i.dial_size = UI.Dial.new(9, 12, 22, 50, 0, 100, 1)
  i.dial_decay = UI.Dial.new(34.5, 27, 22, 50, 0, 100, 1)
  i.dial_tone = UI.Dial.new(84.5, 19.5, 22, 50, 0, 100, 1)
  -- TODO: consider making bypass always an on/off label
  i.dial_bypass = UI.Dial.new(9, 12, 22, 0, 0, 1, 1)
  i.dial_mix = UI.Dial.new(34.5, 27, 22, 50, 0, 100, 1)
  i.dial_in_gain = UI.Dial.new(72, 12, 22, 0, -60, 12, 1, 0, {0})
  i.dial_out_gain = UI.Dial.new(97, 27, 22, 0, -60, 12, 1, 0, {0})
  i.dials = {
    {{i.dial_size, i.dial_decay}, {i.dial_tone}},
    {{i.dial_bypass, i.dial_mix}, {i.dial_in_gain, i.dial_out_gain}}
  }
  i:_update_active_dials()

  i.tab_bypass_label = ""
  i.tab_mix_dial = UI.Dial.new(0, 12, 22, 50, 0, 100, 1)

  i._param_id_to_dials = {}
  for section_index, section in ipairs(i._param_ids) do
    for tab_index, tab in ipairs(section) do
      for param_index, param_id in ipairs(tab) do
        dial = i.dials[section_index][tab_index][param_index]
        i._param_id_to_dials[param_id] = dial
        i:_set_value_from_param_value(param_id, params:get(param_id))
      end
    end
  end
  i:_add_param_actions()

  return i
end

function ReverbPedal.name(short)
  return short and "VERB" or "Reverb"
end

function ReverbPedal.add_params()
  params:add_group(ReverbPedal.name(), 7)

  -- Must match this pedal's .sc file's *id
  id_prefix = ReverbPedal.id

  size_id = id_prefix .. "_size"
  params:add({
    id = size_id,
    name = "Size",
    type = "control",
    controlspec = CONTROL_SPEC_MIX,
  })

  decay_id = id_prefix .. "_decay"
  params:add({
    id = decay_id,
    name = "Decay Time",
    type = "control",
    controlspec = CONTROL_SPEC_MIX,
  })

  tone_id = id_prefix .. "_tone"
  params:add({
    id = tone_id,
    name = "Tone",
    type = "control",
    controlspec = CONTROL_SPEC_MIX,
  })

  bypass_id = id_prefix .. "_bypass"
  params:add({
    id = bypass_id,
    name = "Bypass",
    type = "option",
    options = {"Effect Enabled", "Bypassed"},
  })

  mix_id = id_prefix .. "_mix"
  params:add({
    id = mix_id,
    name = "Dry/Wet",
    type = "control",
    controlspec = CONTROL_SPEC_MIX,
  })

  in_gain_id = id_prefix .. "_in_gain"
  params:add({
    id = in_gain_id,
    name = "In Gain",
    type = "control",
    controlspec = CONTROL_SPEC_GAIN,
  })

  out_gain_id = id_prefix .. "_out_gain"
  params:add({
    id = out_gain_id,
    name = "Out Gain",
    type = "control",
    controlspec = CONTROL_SPEC_GAIN,
  })

  ReverbPedal._param_ids = {
    {{size_id, decay_id}, {tone_id}},
    {{bypass_id, mix_id}, {in_gain_id, out_gain_id}},
  }
end

function ReverbPedal:_add_param_actions()
  for section_index, section in ipairs(self._param_ids) do
    for tab_index, tab in ipairs(section) do
      for param_index, param_id in ipairs(tab) do
        params:set_action(param_id, function(value) self:_set_value_from_param_value(param_id, value) end)
      end
    end
  end
end

function ReverbPedal:enter()
  -- Called when the page is scrolled to
end

function ReverbPedal:key(n, z)
  -- Key-up currently has no meaning
  if z ~= 1 then
    return false
  end

  -- Change the focused tab
  if n == 2 then
    direction = -1
  elseif n == 3 then
    direction = 1
  end
  -- Going beyond the edge of the current section takes to another section (either direction)
  if self.tabs.index + direction > #self.tabs.titles or self.tabs.index + direction == 0 then
    self.section_index = (self.section_index + direction) % #self.sections
    -- Handle how modulo interacts with 1-indexing
    if self.section_index == 0 then
      self.section_index = #self.sections
    end
    self:_update_section()
    -- If we're moving left, enter a section on the right-most tab
    if direction == -1 then
      self.tabs:set_index(#self.tabs.titles)
    end
  else
    self.tabs:set_index_delta(direction, false)
  end
  self:_update_active_dials()

  return true
end

function ReverbPedal:enc(n, delta)
  -- Change the value of a focused dial
  dial_index = n - 1
  param_id = self._param_ids[self.section_index][self.tabs.index][dial_index]
  if param_id == nil then
    return false
  end
  params:delta(param_id, delta)
  return true
end

function ReverbPedal:redraw()
  self.tabs:redraw()
  for tab_index, tab in ipairs(self.dials[self.section_index]) do
    for dial_index, dial in ipairs(tab) do
      dial:redraw()
    end
  end
  -- Left arrow when there's a section to our left
  if self.section_index > 1 then
    screen.move(0, 6)
    screen.level(3)
    screen.text("<")
  end
  -- Right arrow when there's a section to our left
  if self.section_index < #self.sections then
    screen.move(128, 6)
    screen.level(3)
    screen.text_right(">")
  end
  -- Name of pedal at the bottom
  screen.move(64, 64)
  screen.level(15)
  screen.text_center(self.name())
  -- Prevent a stray line being drawn
  screen.stroke()
end

function ReverbPedal:render_as_tab(offset, width, is_active)
  center_x = offset + (width / 2)
  tab_mix_dial_value = self.tab_mix_dial.value
  self.tab_mix_dial = UI.Dial.new(center_x - 11, 16, 22, tab_mix_dial_value, 0, 100, 1)
  self.tab_mix_dial.active = is_active
  self.tab_mix_dial:redraw()
  if self.tab_bypass_label == "ON" then
    screen.level(is_active and 15 or 6)
  else
    screen.level(is_active and 3 or 1)
  end
  screen.move(center_x, 56)
  screen.text_center(self.tab_bypass_label)
  screen.level(15)
  -- Prevent a stray line being drawn
  screen.stroke()
end

function ReverbPedal:toggle_bypass()
  bypass_param_id = self.id .. "_bypass"
  is_currently_bypassed = params:get(bypass_param_id) == 2
  params:set(bypass_param_id, is_currently_bypassed and 1 or 2)
end

function ReverbPedal:scroll_mix(delta)
  params:delta(self.id .. "_mix", delta)
end

function ReverbPedal:_set_value_from_param_value(param_id, value)
  coerced_value = value
  if param_id == "reverb_bypass" then
    -- The options are 1-indexed, but the bypass control expects 0 or 1
    coerced_value = value - 1
    self.tab_bypass_label = value == 1 and "ON" or "OFF"
  elseif param_id == "reverb_mix" then
    self.tab_mix_dial:set_value(coerced_value)
  end
  self._param_id_to_dials[param_id]:set_value(coerced_value)

  -- Tell the engine what you did.
  if param_id == "reverb_size" then
    engine.reverb_size(coerced_value / 100.0)
  elseif param_id == "reverb_decay" then
    engine.reverb_decay(coerced_value / 100.0)
  elseif param_id == "reverb_tone" then
    engine.reverb_tone(coerced_value / 100.0)
  elseif param_id == "reverb_bypass" then
    engine.reverb_bypass(coerced_value)
  elseif param_id == "reverb_mix" then
    engine.reverb_mix(coerced_value / 100.0)
  elseif param_id == "reverb_in_gain" then
    engine.reverb_in_gain(util.dbamp(coerced_value))
  elseif param_id == "reverb_out_gain" then
    engine.reverb_out_gain(util.dbamp(coerced_value))
  end
end

function ReverbPedal:_update_section()
  self.tabs = UI.Tabs.new(1, self.sections[self.section_index])
end

function ReverbPedal:_update_active_dials()
  current_tab_index = self.tabs.index
  for tab_index, tab in ipairs(self.dials[self.section_index]) do
    for dial_index, dial in ipairs(tab) do
      dial.active = tab_index == current_tab_index
    end
  end
end

return ReverbPedal
