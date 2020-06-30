
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
local MODE_DURATION_MINIMUM = 0.7
local SAMPLE_SIZE_MAX = 6
local SAMPLE_SIZE_MIN = 3

local TapTempo = {}
TapTempo.__index = TapTempo

function TapTempo.new(i)
  i = i or {
    _tap_tempo_mode_start_time = nil,
    _tap_tempo_used = false,
    _tap_times = {},
  }
  setmetatable(i, TapTempo)
  i.__index = TapTempo

  return i
end

function TapTempo:start_tap_tempo_mode()
  self._tap_tempo_mode_start_time = util.time()
  -- Clear out any prior tap-tempo info
  self._tap_times = {}
end

function TapTempo:is_in_tap_tempo_mode()
  return self._tap_tempo_mode_start_time ~= nil
end

function TapTempo:end_tap_tempo_mode()
  -- Returns whether or not tap tempo mode was actually used
  local mode_duration = util.time() - self._tap_tempo_mode_start_time
  self._tap_tempo_mode_start_time = nil
  if self._tap_tempo_used or mode_duration > MODE_DURATION_MINIMUM then
    self._tap_tempo_used = false
    return true
  end
  return false
end

function TapTempo:record_tap()
  -- Returns the tapped tempo, if we have enough data
  self._tap_tempo_used = true
  table.insert(self._tap_times, util.time())
  if #self._tap_times > SAMPLE_SIZE_MAX then
    table.remove(self._tap_times, 1)
  end
  if #self._tap_times >= SAMPLE_SIZE_MIN then
    local separation_total = self._tap_times[#self._tap_times] - self._tap_times[1]
    local average_separation = separation_total / (#self._tap_times - 1)
    return 60 / average_separation
  end
  return nil
end

function TapTempo:key(n, z)
  -- Returns [Optional<tempo:int>, Optional<short_circuit_value:bool>]
  -- If the tempo is returned, do with it what you'd like (typically send to params)
  -- If short_circuit_value is returned, your function should short-circuit by returning that value.
  -- Otherwise, do your usual behavior (for most Pedals, this just means calling super)
  if n == 2 then
    -- Key down on K2 starts up Tap Tempo mode
    if z == 1 then
      self:start_tap_tempo_mode()
      return nil, false
    end

    -- Key up on K2 checks with Tap Tempo if any meaningful tap tempo action happened.
    -- If so, we just count this key-up as ending tap tempo, rather than a click
    if self:is_in_tap_tempo_mode() then
      local tap_tempo_used = self:end_tap_tempo_mode()
      if tap_tempo_used then return nil, false end
    end

    -- Otherwise we count this key-up as a click on K2
    -- (Superclass expects z==1 for a click)
    return nil, nil
  elseif n == 3 and z == 1 and self:is_in_tap_tempo_mode() then
    -- Taps on K3 while in tap tempo mode record the tap and set the BPM if we have determined a tempo
    local tapped_tempo = self:record_tap()
    if tapped_tempo then
      return tapped_tempo, true
    end
    return nil, false
  end

  return nil, nil
end

function TapTempo.tempo_and_division_to_dur(bpm, beat_division_option)
  if bpm == nil then bpm = 110 end
  if beat_division_option == nil then
    beat_division_option = TapTempo.get_beat_division_default()
  end
  local beat_division = BEAT_DIVISION_LOOKUP[beat_division_option]
  return 60.0 * beat_division / bpm
end

function TapTempo.get_beat_division_options()
  return BEAT_DIVISION_OPTIONS
end

function TapTempo.get_beat_division_default()
  return 7
end

return TapTempo
