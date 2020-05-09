--- CloudsPedal
-- @classmod CloudsPedal

local ControlSpec = require "controlspec"
local UI = require "ui"
local Pedal = include("lib/ui/pedals/pedal")
local Controlspecs = include("lib/ui/util/controlspecs")
local ScreenState = include("lib/ui/util/screen_state")

local CloudsPedal = Pedal:new()
-- Must match this pedal's .sc file's *id
CloudsPedal.id = "clouds"

function CloudsPedal:new(bypass_by_default)
  local i = Pedal:new(bypass_by_default)
  setmetatable(i, self)
  self.__index = self

  i._sections_by_mode = {
    -- Granular
    {
      {"Pitch/Pos", "Size/Density"},
      {"Texture/Stereo", "Fdbk/Freeze"},
      {"Fidelity & Mode"},
      i:_default_section(),
    },
    -- Pitch Shift
    {
      {"Pitch/Pos", "Size/Diffuse"},
      {"Tone/Stereo", "Fdbk/Freeze"},
      {"Fidelity & Mode"},
      i:_default_section(),
    },
    -- Looper
    {
      {"Pitch/Pos", "Size/Diffuse"},
      {"Tone/Stereo", "Fdbk/Freeze"},
      {"Fidelity & Mode"},
      i:_default_section(),
    },
    -- Spectral
    {
      {"Pitch/Buf", "Warp/Smear"},
      {"Noise/Stereo", "Fdbk/Capture"},
      {"Fidelity & Mode"},
      i:_default_section(),
    },
  }
  i.sections = i._sections_by_mode[1]
  i:_complete_initialization()
  i._param_id_to_widget[i.id .. "_pit"]:set_marker_position(1, 0)
  i._param_id_to_widget[i.id .. "_pit"].start_value = 0

  return i
end

function CloudsPedal:name(short)
  return short and "CLOUD" or "MI Clouds"
end

function CloudsPedal.params()
  local id_prefix = CloudsPedal.id

  local pitch_control = {
    id = id_prefix .. "_pit",
    name = "Pitch Shift",
    type = "control",
    controlspec = ControlSpec.new(-48, 48, "lin", 1, 0, "st"),
  }
  local pos_control = {
    id = id_prefix .. "_pos",
    name = "Position",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local size_control = {
    id = id_prefix .. "_size",
    name = "Size",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local dens_control = {
    id = id_prefix .. "_dens",
    name = "Density",
    type = "control",
    controlspec = Controlspecs.mix(33),
  }
  local tex_control = {
    id = id_prefix .. "_tex",
    name = "Texture",
    type = "control",
    controlspec = Controlspecs.MIX,
  }
  local spread_control = {
    id = id_prefix .. "_spread",
    name = "Stereo Spread",
    type = "control",
    controlspec = Controlspecs.mix(0),
  }
  local fb_control = {
    id = id_prefix .. "_fb",
    name = "Feedback",
    type = "control",
    controlspec = Controlspecs.mix(20),
  }
  local freeze_control = {
    id = id_prefix .. "_freeze",
    name = "Freeze",
    type = "option",
    options = {"Off", "Frozen"},
  }
  local lofi_control = {
    id = id_prefix .. "_lofi",
    name = "Fidelity",
    type = "option",
    options = {"Hi-Fi", "Lo-Fi"},
  }
  local mode_control = {
    id = id_prefix .. "_mode",
    name = "Mode",
    type = "option",
    options = {"Granular", "Pitch Shift", "Looper", "Spectral"}
  }

  return {
    {{pitch_control, pos_control}, {size_control, dens_control}},
    {{tex_control, spread_control}, {fb_control, freeze_control}},
    {{lofi_control, mode_control}},
    Pedal._default_params(id_prefix),
  }
end

function CloudsPedal:_update_section()
  self.sections = self._sections_by_mode[params:get(self.id.."_mode")]
  Pedal._update_section(self)
end

function CloudsPedal:_set_value_from_param_value(param_id, value)
  if param_id == self.id .. "_dens" and params:get(self.id.."_mode") == 1 then
    local dens_dial = self._param_id_to_widget[param_id]
    dens_dial:set_value(value)
    -- Explain the way the density param works
    if value == 50 then
      dens_dial.title = "Off"
    elseif value < 50 then
      dens_dial.title = "Reg: "..((50 - value) * 2)
    else
      dens_dial.title = "Rnd: "..((value - 50) * 2)
    end
    ScreenState.mark_screen_dirty(true)
    self:_message_engine_for_param_change(param_id, value)
    return
  end
  Pedal._set_value_from_param_value(self, param_id, value)
end

return CloudsPedal
