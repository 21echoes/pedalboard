local ControlSpec = require "controlspec"

local controlspecs = {
  CONTROL_SPEC_MIX = ControlSpec.new(0, 100, "lin", 1, 50, "%"),
  CONTROL_SPEC_GAIN = ControlSpec.new(-60, 12, "lin", 0.5, 0, "dB")
}

return controlspecs
