local ControlSpec = require "controlspec"

local controlspecs = {}

function controlspecs.mix(default)
  default = default ~= nil and default or 50
  return ControlSpec.new(0, 100, "lin", 0.1, default, "%")
end

function controlspecs.gain(default)
  default = default ~= nil and default or 0
  return ControlSpec.new(-81, 19, "lin", 0.1, default, "dB")
end

function controlspecs.boostcut(default)
  default = default ~= nil and default or 0
  return ControlSpec.new(-20, 20, "lin", 0.1, default, "dB")
end

controlspecs.MIX = controlspecs.mix()
controlspecs.GAIN = controlspecs.gain()
controlspecs.BOOSTCUT = controlspecs.boostcut()

function controlspecs.is_mix(test)
  return controlspecs._specs_are_equal(test, controlspecs.MIX)
end

function controlspecs.is_gain(test)
  return controlspecs._specs_are_equal(test, controlspecs.GAIN)
end

function controlspecs.is_boostcut(test)
  return controlspecs._specs_are_equal(test, controlspecs.BOOSTCUT)
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
