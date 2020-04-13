local ControlSpec = require "controlspec"

local mix = ControlSpec.new(0, 100, "lin", 1, 50, "%")
local gain = ControlSpec.new(-81, 12, "lin", 0.5, 0, "dB")

local controlspecs = {
  CONTROL_SPEC_MIX = mix,
  CONTROL_SPEC_GAIN = gain,
}

function controlspecs.is_mix(test)
  return controlspecs._specs_are_equal(test, mix)
end

function controlspecs.is_gain(test)
  return controlspecs._specs_are_equal(test, gain)
end

function controlspecs._specs_are_equal(a, b)
  return (
    a.minval == b.minval and
    a.maxval == b.maxval and
    a.warp == b.warp and
    a.step == b.step and
    a.default == b.default and
    a.units == b.units
  )
end

return controlspecs
