--- TunerPedal
-- @classmod TunerPedal

local ControlSpec = require "controlspec"
local MusicUtil = require "musicutil"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")
local Label = include("lib/ui/util/label")
local ScreenState = include("lib/ui/util/screen_state")

local TunerPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
TunerPedal.id = "tuner"

function TunerPedal:new(bypass_by_default)
  -- Always bypass by default
  local i = Pedal:new(true)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {""},
    i:_default_section(),
  }
  i:_complete_initialization()

  i._pitch_poll = poll.set("pitch_in_l")
  i._pitch_poll.callback = function(value) i:_pitch_poll_callback(value) end
  i._pitch_poll.time = 0.066
  i._pitch_poll:start()
  i._detected_freq = nil
  i._detected_note = nil
  i._detection_is_active = false
  i._detected_note_label = Label.new({center_x = 64, y = 24, font_size = 16})
  i._test_note_label = Label.new({center_x = 32, y = 56})
  i._a3_freq_label = Label.new({center_x = 96, y = 56})
  i._detected_note_tab_label = Label.new({y = 24, font_size = 16})
  i._test_note_tab_label = Label.new({y = 56})

  return i
end

function TunerPedal:cleanup()
  i._pitch_poll:stop()
  Pedal.cleanup(self)
end

function TunerPedal:name(short)
  return short and "TUNER" or "Tuner"
end

function TunerPedal.params()
  local id_prefix = TunerPedal.id

  local test_tone_note_control = {
    id = id_prefix .. "_test_tone_note",
    name = "Test Tone Note",
    type = "control",
    formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    -- TODO: ideally this would be 0-127, but controlspecs larger than ~100 steps can skip values
    controlspec = ControlSpec.new(24, 103, "lin", 1, 69, ""), -- a3 by default
  }
  local a3_freq_control = {
    id = id_prefix .. "_a3_freq",
    name = "A3 Frequency",
    type = "control",
    controlspec = ControlSpec.new(415, 465, "lin", 0.5, 440, "Hz"),
  }

  return {
    {{test_tone_note_control, a3_freq_control}},
    Pedal._default_params(id_prefix),
  }
end

function TunerPedal:redraw()
  -- All sections other than the first one are handled by the superclass
  if self.section_index > 1 then
    Pedal.redraw(self)
    return
  end

  -- Right arrow when there's a section to our left
  -- (taken from superclass, not worth abstracting)
  if self.section_index < #self.sections then
    screen.move(128, 6)
    screen.level(3)
    screen.text_right(">")
  end

  -- Custom UI
  if self._detected_note then
    self._detected_note_label.text = MusicUtil.note_num_to_name(self._detected_note, true)
  else
    self._detected_note_label.text = "~"
  end
  if self._detection_is_active then
    self._detected_note_label.level = 15
  else
    self._detected_note_label.level = 3
  end
  local test_tone_note = params:get(self.id .. "_test_tone_note")
  self._test_note_label.text = test_tone_note and "Hear: " .. MusicUtil.note_num_to_name(test_tone_note, true) or ""
  local a3_freq = params:get(self.id .. "_a3_freq")
  self._a3_freq_label.text = a3_freq and "A3: " .. a3_freq .. " Hz" or ""

  self._detected_note_label:redraw()
  self._test_note_label:redraw()
  self._a3_freq_label:redraw()

  self:_draw_meter(8, 112, 40, true)
end

function TunerPedal:render_as_tab(offset, width, is_active)
  self._detected_note_tab_label.center_x = offset + width / 2
  self._test_note_tab_label.center_x = offset + width / 2

  if self._detected_note then
    self._detected_note_tab_label.text = MusicUtil.note_num_to_name(self._detected_note)
  else
    self._detected_note_tab_label.text = "~"
  end
  if self._detection_is_active then
    self._detected_note_tab_label.level = is_active and 15 or 6
  else
    self._detected_note_tab_label.level = is_active and 3 or 1
  end
  local test_tone_note = params:get(self.id .. "_test_tone_note")
  local a3_freq = params:get(self.id .. "_a3_freq")
  if test_tone_note and a3_freq then
    local test_tone_freq = MusicUtil.note_num_to_freq(test_tone_note) * a3_freq/440
    if width < 64 then
      self._test_note_tab_label.text = MusicUtil.note_num_to_name(test_tone_note, true)
    else
      self._test_note_tab_label.text = MusicUtil.note_num_to_name(test_tone_note, true) .. " " .. test_tone_freq .. " Hz"
    end
    local mix = params:get(self.id .. "_mix")
    local bypass = params:get(self.id .. "_bypass")
    -- Bypass of 1 means "Effect Enabled", 2 means "Bypassed"
    local effective_mix = bypass == 1 and mix or 0
    local brightness_scale = is_active and 15 or 6
    self._test_note_tab_label.level = math.ceil((effective_mix/100) * brightness_scale)
  else
    self._test_note_tab_label.text = ""
    self._test_note_tab_label.level = 0
  end

  self._detected_note_tab_label:redraw()
  self._test_note_tab_label:redraw()

  self:_draw_meter(offset + 2, width - 4, 40, is_active)
end

function TunerPedal:_draw_meter(x_offset, width, y, is_active)
  -- Adapted from @markwheeler's Tuner

  local highlight_level = is_active and 15 or 6
  local background_level = is_active and 3 or 1

  -- Draw rules
  local num_rules = math.floor(util.clamp(width / 10, 6, 12) / 2) * 2 - 1
  local rule_separation = (width - 1) / (num_rules - 1)
  local center_rule_index = math.ceil(num_rules / 2)
  for i = 1, num_rules do
    local x = util.round(rule_separation * (i - 1)) + 0.5 + x_offset
    if i == center_rule_index then
      if self._detection_is_active then screen.level(highlight_level)
      else screen.level(3) end
      screen.move(x, y - 11)
      screen.line(x, y)
    else
      if self._detection_is_active then screen.level(background_level)
      else screen.level(1) end
      screen.move(x, y - 6)
      screen.line(x, y)
    end
    screen.stroke()
  end

  -- Draw last freq line
  local freq_x
  if self._detected_freq ~= nil then
    local a3_freq = params:get(self.id .. "_a3_freq")
    a3_freq = a3_freq and a3_freq or 440
    local min_freq = MusicUtil.note_num_to_freq(self._detected_note - 0.5) * a3_freq/440
    local max_freq = MusicUtil.note_num_to_freq(self._detected_note + 0.5) * a3_freq/440
    freq_x = util.explin(math.max(min_freq, 0.00001), max_freq, 0, width, self._detected_freq)
    freq_x = util.round(freq_x) + 0.5 + x_offset
  else
    freq_x = (width / 2) + 0.5 + x_offset
  end
  if self._detection_is_active then screen.level(highlight_level)
  else screen.level(background_level) end
  screen.move(freq_x, y - 6)
  screen.line(freq_x, y + 5)
  screen.stroke()

  -- Reset back to defaults
  screen.font_face(1)
  screen.font_size(8)
  screen.level(15)
end

function TunerPedal:_message_engine_for_param_change(param_id, value)
  local a3_freq_id = self.id .. "_a3_freq"
  local test_tone_note_id = self.id .. "_test_tone_note"
  if param_id == a3_freq_id or param_id == test_tone_note_id then
    local a3_freq = param_id == a3_freq_id and value or params:get(a3_freq_id)
    if a3_freq == nil then a3_freq = 440 end
    local test_tone_note = param_id == test_tone_note_id and value or params:get(test_tone_note_id)
    if test_tone_note == nil then test_tone_note = 60 end
    test_tone_freq = MusicUtil.note_num_to_freq(test_tone_note) * a3_freq/440
    engine.tuner_hz(test_tone_freq)
    return
  end
  Pedal._message_engine_for_param_change(self, param_id, value)
end

function TunerPedal:_pitch_poll_callback(value)
  local pitch_detected = value > 0
  if pitch_detected then
    self:_pitch_detected(value)
  end
  if pitch_detected ~= self._detection_is_active then
    self._detection_is_active = pitch_detected
    ScreenState.mark_screen_dirty(true)
  end
end

function TunerPedal:_pitch_detected(freq)
  local detected_freq = freq
  local freq_basis = params:get(self.id .. "_a3_freq")
  freq_basis = freq_basis and freq_basis or 440
  local normalized_freq = freq * 440/freq_basis
  local detected_note = MusicUtil.freq_to_note_num(normalized_freq)
  if detected_freq ~= self._detected_freq then
    self._detected_freq = detected_freq
    ScreenState.mark_screen_dirty(true)
  end
  if detected_note ~= self._detected_note then
    self._detected_note = detected_note
    ScreenState.mark_screen_dirty(true)
  end
end

return TunerPedal
