--- DelayPedal
-- @classmod DelayPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/pedals/controlspecs")

local BEAT_DIVISION_OPTIONS = {
  "16th Note",
  "Triplet 8th",
  "Dotted 16th",
  "8th Note",
  "Triplet Quarter",
  "Dotted 8th",
  "Quarter Note",
  "Triplet Half",
  "Dotted Quarter",
  "Half Note",
  "Dotted Half",
  "Whole Note"
}
local BEAT_DIVISION_LOOKUP = {0.25, 1/3, 0.375, 0.5, 2/3, 0.75, 1, 4/3, 1.5, 2, 3, 4}
local CLICK_DURATION = 0.7

local DelayPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
DelayPedal.id = "delay"

function DelayPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Rate", "Feedback"},
    {"Quality & Mode"},
    i:_default_section(),
  }
  i:_complete_initialization()

  bpm_dial = i._param_id_to_widget[i.id .. "_bpm"]
  bpm_dial.units = "bpm"

  i._alt_key_down_time = nil
  i._alt_action_taken = false
  i._tap_times = {}

  return i
end

function DelayPedal:name(short)
  return short and "DEL" or "Delay"
end

function DelayPedal.params()
  local id_prefix = DelayPedal.id

  -- TODO: different control that controls the exact time?
  local bpm_control = {
    id = id_prefix .. "_bpm",
    name = "BPM",
    type = "control",
    controlspec = ControlSpec.new(40, 240, "lin", 1, 110, "bpm")
  }
  local beat_division_control = {
    id = id_prefix .. "_beat_division",
    name = "Rhythm",
    type = "option",
    options = BEAT_DIVISION_OPTIONS,
    default = 7, -- "Quarter Note"
  }
  local feedback_control = {
    id = id_prefix .. "_feedback",
    name = "Feedback",
    type = "control",
    controlspec = Controlspecs.CONTROL_SPEC_MIX,
  }
  local quality_control = {
    id = id_prefix .. "_quality",
    name = "Quality",
    type = "option",
    options = {"Digital", "Analog", "Tape", "Lo-Fi"},
  }
  local mode_control = {
    id = id_prefix .. "_mode",
    name = "Mode",
    type = "option",
    options = {"Default", "Ping-Pong"},
  }

  return {
    {{bpm_control, beat_division_control}, {feedback_control}},
    {{quality_control, mode_control}},
    Pedal._default_params(id_prefix)
  }
end

function DelayPedal:key(n, z)
  if n == 2 then
    -- Key down on K2 enables alt mode
    if z == 1 then
      self._alt_key_down_time = util.time()
      -- Clear out any prior tap-tempo info
      self._tap_times = {}
      return false
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
    -- (Superclass expects z==1 for a click)
    return Pedal.key(self, n, 1)
  elseif n == 3 and z == 1 and self._alt_key_down_time ~= nil then
    -- Clicks on K3 during alt mode starts a tap tempo
    self._alt_action_taken = true
    table.insert(self._tap_times, util.time())
    if #self._tap_times > 6 then
      table.remove(self._tap_times, 1)
    end
    if #self._tap_times > 2 then
      local separations = {}
      for i, click_time in ipairs(self._tap_times) do
        if i > 1 then
          table.insert(separations, click_time - self._tap_times[i - 1])
        end
      end
      local total_separations = 0
      for i, separation in ipairs(separations) do
        total_separations = total_separations + separation
      end
      local average_separation = total_separations / #separations
      params:set(self.id .. "_bpm", 60 / average_separation)
      return true
    end
    return false
  end

  return Pedal.key(self, n, z)
end

function DelayPedal:_message_engine_for_param_change(param_id, value)
  local bpm_param_id = self.id .. "_bpm"
  local beat_division_param_id = self.id .. "_beat_division"
  if param_id == bpm_param_id or param_id == beat_division_param_id then
    local bpm = param_id == bpm_param_id and value or params:get(bpm_param_id)
    if bpm == nil then bpm = 110 end
    local beat_division_option = param_id == beat_division_param_id and value + 1 or params:get(beat_division_param_id)
    if beat_division_option == nil then beat_division_option = 7 end
    local beat_division = BEAT_DIVISION_LOOKUP[beat_division_option]
    local time = 60.0 * beat_division / bpm
    engine.delay_time(time)
    return
  end
  Pedal._message_engine_for_param_change(self, param_id, value)
end

return DelayPedal
