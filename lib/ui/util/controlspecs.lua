local ControlSpec = require "controlspec"

local controlspecs = {}

function controlspecs.mix(default)
  default = default ~= nil and default or 50
  return ControlSpec.new(0, 100, "lin", 1, default, "%")
end

function controlspecs.gain(default)
  default = default ~= nil and default or 0
  return ControlSpec.new(-81, 12, "lin", 0.5, default, "dB")
end

controlspecs.CONTROL_SPEC_MIX = controlspecs.mix()
controlspecs.CONTROL_SPEC_GAIN = controlspecs.gain()

function controlspecs.is_mix(test)
  return controlspecs._specs_are_equal(test, controlspecs.CONTROL_SPEC_MIX)
end

function controlspecs.is_gain(test)
  return controlspecs._specs_are_equal(test, controlspecs.CONTROL_SPEC_GAIN)
end

function controlspecs._specs_are_equal(a, b)
  return (
    a.minval == b.minval and
    a.maxval == b.maxval and
    a.warp == b.warp and
    a.step == b.step and
    -- a.default == b.default and
    a.units == b.units
  )
end

return controlspecs
