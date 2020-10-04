-- Adapted from hnds v0.4 by @justmat
local tau = math.pi * 2

local options = {
  lfotypes = {
    "sine",
    "square",
    "s+h"
    -- TODO: add saw & tri
  }
}

local lfo = {
  number_of_outputs = 3,
  lfo_metro = nil
}
for i = 1, lfo.number_of_outputs do
  lfo[i] = {
    freq = 0.01,
    counter = 1,
    waveform = options.lfotypes[1],
    value = 0,
    depth = 100,
    offset = 0
  }
end

-- redefine in user script ---------
function lfo.process()
end
------------------------------------


local function make_sine(n)
  return 1 * math.sin(((tau / 100) * (lfo[n].counter)) - (tau / (lfo[n].freq)))
end


local function make_square(n)
  return make_sine(n) >= 0 and 1 or -1
end


local function make_sh(n)
  local polarity = make_square(n)
  if lfo[n].prev_polarity ~= polarity then
    lfo[n].prev_polarity = polarity
    return math.random() * (math.random(0, 1) == 0 and 1 or -1)
  else
    return lfo[n].prev
  end
end

function lfo.init(num_targets, add_targets)
  for i = 1, lfo.number_of_outputs do
    params:add_group("LFO "..i, 5 + num_targets)
    -- lfo on/off
    params:add_option(i .. "lfo_enabled", "Enabled", {"off", "on"}, 2)
    -- lfo shape
    params:add_option(i .. "lfo_shape", "Shape", options.lfotypes, 1)
    params:set_action(i .. "lfo_shape", function(value) lfo[i].waveform = options.lfotypes[value] end)
    -- lfo speed
    params:add_control(i .. "lfo_freq", "Freq", controlspec.new(0.01, 10.0, "exp", 0.01, 0.01, "Hz"))
    params:set_action(i .. "lfo_freq", function(value) lfo[i].freq = value end)
    -- lfo depth
    params:add_number(i .. "lfo_depth", "Depth", 0, 100, 100)
    params:set_action(i .. "lfo_depth", function(value) lfo[i].depth = value end)
    -- lfo offset
    params:add_number(i .. "lfo_offset", "Offset", -100, 100, 0)
    params:set_action(i .. "lfo_offset", function(value) lfo[i].offset = value end)
    add_targets(i)
  end

  local lfo_metro = metro.init()
  lfo_metro.time = 0.01
  lfo_metro.count = -1
  lfo_metro.event = function()
    for i = 1, lfo.number_of_outputs do
      if params:get(i .. "lfo_enabled") == 2 then
        local value
        if lfo[i].waveform == "sine" then
          value = make_sine(i)
        elseif lfo[i].waveform == "square" then
          value = make_square(i)
        elseif lfo[i].waveform == "s+h" then
          value = make_sh(i)
        end
        lfo[i].prev = value
        lfo[i].value = math.max(-1.0, math.min(1.0, value)) * (lfo[i].depth * 0.01) + (lfo[i].offset * 0.01)
        lfo[i].counter = lfo[i].counter + lfo[i].freq
      end
    end
    lfo.process()
  end
  lfo_metro:start()
  lfo.lfo_metro = lfo_metro
end

function lfo.cleanup()
  if lfo.lfo_metro ~= nil then
    lfo.lfo_metro:stop()
    lfo.lfo_metro = nil
  end
end

return lfo
