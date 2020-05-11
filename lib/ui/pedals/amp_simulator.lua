--- AmpSimulator
-- @classmod AmpSimulator

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")

local AmpSimulator = Pedal:new()
-- Must match this pedal's .sc file's *id
AmpSimulator.id = "ampsimulator"
-- Measure this value by uncommenting the `...context.server.peakCPU...` line at the end of Engine_Pedalboard.alloc
-- Measure with only this pedal on the board, playing in some audio,
-- collect a few samples, and subtract 8 from the max value you see (and round up!)
AmpSimulator.peak_cpu = 8

function AmpSimulator:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i.sections = {
    {"Drive & Room"},
    {"Bass & Mid", "Pres & Treble"},
    i:_default_section(),
  }
  i:_complete_initialization()

  return i
end

function AmpSimulator:name(short)
  return short and "AMP" or "Amp Sim"
end

function AmpSimulator.params()
  local id_prefix = AmpSimulator.id

  local drive_control = {
    id = id_prefix .. "_drive",
    name = "Drive",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local room_control = {
    id = id_prefix .. "_room",
    name = "Room",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local bass_control = {
    id = id_prefix .. "_bass",
    name = "Bass",
    type = "control",
    controlspec = ControlSpec.new(-20, 20, "lin", 0.5, 2, "dB"),
  }
  local mid_control = {
    id = id_prefix .. "_mid",
    name = "Mid",
    type = "control",
    controlspec = ControlSpec.new(-20, 20, "lin", 0.5, -2, "dB"),
  }
  local presence_control = {
    id = id_prefix .. "_presence",
    name = "Presence",
    type = "control",
    controlspec = Controlspecs.mix(30),
  }
  local treble_control = {
    id = id_prefix .. "_treble",
    name = "Treble",
    type = "control",
    controlspec = ControlSpec.new(-20, 20, "lin", 0.5, -2, "dB"),
  }

  -- Default mix of 100%
  local default_params = Pedal._default_params(id_prefix)
  default_params[1][2].controlspec = Controlspecs.mix(100)

  return {
    {{drive_control, room_control}},
    {{bass_control, mid_control}, {presence_control, treble_control}},
    default_params,
  }
end

return AmpSimulator
