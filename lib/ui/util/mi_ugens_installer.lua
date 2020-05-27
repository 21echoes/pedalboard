-- Adapted from @okyeron's installer script
local OptionalPedals = include("lib/ui/util/optional_pedals")
local ScreenState = include("lib/ui/util/screen_state")
local Alert = include("lib/ui/util/alert")
local Label = include("lib/ui/util/label")

local MiUgensInstaller = {}
MiUgensInstaller.__index = MiUgensInstaller

local InstallerStates = {
  NO_FILES = 'NOT DOWNLOADED',
  DOWNLOADING = 'DOWNLOADING',
  INSTALLING = 'INSTALLING',
  WAITING_ON_ENGINE = 'Loading...',
  NEEDS_RESTART = 'NEEDS RESTART',
  SHUTTING_DOWN = 'Shutting down...',
  ALL_READY = 'Ready!',
}
MiUgensInstaller.InstallerStates = InstallerStates

function MiUgensInstaller:new(pedal_class)
  i = {}
  setmetatable(i, self)
  self.__index = self

  i.version = "mi-UGens-linux-v.03"
  i.state = nil
  i.alert = nil
  i.label = Label.new({x=4, y = 60, text="K2 to cancel", align=Label.ALIGN_LEFT})
  i.message = nil
  i.pedal_class = pedal_class
  i:_update_state()

  return i
end

function MiUgensInstaller:_update_state()
  -- These two states indicate ongoing processes which will update state directly when they are finished
  if self.state == InstallerStates.DOWNLOADING or self.state == InstallerStates.INSTALLING then
    return
  end
  -- Otherwise, infer state from file system, engine synthdef success signals, etc.
  if self.pedal_class:is_engine_ready() then
    self:_set_state(InstallerStates.ALL_READY)
  elseif not OptionalPedals.are_requirements_satisfied(self.pedal_class) then
    self:_set_state(InstallerStates.NO_FILES)
  elseif self.pedal_class.engine_state == "pending" then
    self:_set_state(InstallerStates.WAITING_ON_ENGINE)
  else
    self:_set_state(InstallerStates.NEEDS_RESTART)
  end
end

function MiUgensInstaller:key(n, z)
  if not (n == 3 and z == 1) then
    return false
  end
  if self.state == InstallerStates.NO_FILES then
    self:_download_and_install()
    return true
  elseif self.state == InstallerStates.NEEDS_RESTART then
    self:_set_state(InstallerStates.SHUTTING_DOWN)
    -- Adapted from the https://github.com/monome/norns/blob/master/lua/core/menu/sleep.lua
    norns.script.redraw()
    norns.state.clean_shutdown = true
    norns.state.save()
    pcall(cleanup)
    -- TODO
    --if m.tape.rec.sel == TAPE_REC_STOP then audio.tape_record_stop() end
    audio.level_dac(0)
    audio.headphone_gain(0)
    os.execute("sleep 0.5; sudo shutdown now")
  end
end

function MiUgensInstaller:redraw()
  Alert.new(self.message):redraw()
  if self:can_cancel() then
    self.label:redraw()
  end
end

function MiUgensInstaller:cleanup()
  if self._waiting_metro ~= nil then
    self._waiting_metro:stop()
    self._waiting_metro = nil
  end
end

function MiUgensInstaller:can_cancel()
  return (
    self.state ~= InstallerStates.DOWNLOADING
    and self.state ~= InstallerStates.INSTALLING
    and self.state ~= InstallerStates.WAITING_ON_ENGINE
    and self.state ~= InstallerStates.SHUTTING_DOWN
  )
end

function MiUgensInstaller:_download_and_install()
  self:_set_state(InstallerStates.DOWNLOADING)
  print('installing mi-ugens')
  self:_set_message("Downloading...")
  print("starting download...")
  local cmd = "wget -T 180 -q -P /home/we/ " .. self:_get_url()
  print("> "..cmd)
  norns.system_cmd(cmd, function() self:_install_update() end)
end

function MiUgensInstaller:_install_update()
  self:_set_state(InstallerStates.INSTALLING)
  self:_set_message("Unpacking...")
  os.execute("tar -xvf /home/we/"..self.version..".tar -C /home/we/")

  self:_set_message("Installing...")
  os.execute("cp -r /home/we/"..self.version.."/* /home/we/.local/share/SuperCollider/Extensions/")

  self:_set_message("Cleaning up...")
  os.execute("rm -r /home/we/"..self.version)
  os.execute("rm -r /home/we/"..self.version..".tar")

  self:_set_message("Install complete!")
  print('install complete')

  self:_set_state(InstallerStates.WAITING_ON_ENGINE)
  self:_setup_waiting_state()
  engine.add_pedal_definition(self.pedal_class.id)
  self.pedal_class:update_engine_state()
end

function MiUgensInstaller:_get_url()
  return "https://github.com/okyeron/mi-UGens/raw/master/linux-norns-binaries/"..self.version..".tar"
end

function MiUgensInstaller:_set_message(message)
  self.message = {message}
  ScreenState.mark_screen_dirty(true)
end

function MiUgensInstaller:_set_state(state)
  self.state = state
  if state == InstallerStates.NO_FILES then
    self.message = {"This pedal requires", "additional setup.", "While on WiFi,", "press K3 to install", ""}
  elseif state == InstallerStates.NEEDS_RESTART then
    self.message = {"Press K3 to shut down,", "then you can boot", "to complete install"}
  elseif state == InstallerStates.ALL_READY then
    self.message = {"All ready!", "Press K3 to confirm"}
  else
    self.message = {state}
  end
  ScreenState.mark_screen_dirty(true)
end

function MiUgensInstaller:_setup_waiting_state()
  self._waiting_metro = metro.init()
  self._waiting_metro.event = function()
    if self.state == InstallerStates.WAITING_ON_ENGINE and self.pedal_class.engine_state ~= "pending" then
      if self.pedal_class:is_engine_ready() then
        self:_set_state(InstallerStates.ALL_READY)
      else
        self:_set_state(InstallerStates.NEEDS_RESTART)
      end
      self._waiting_metro:stop()
      self._waiting_metro = nil
      ScreenState.mark_screen_dirty(true)
    end
  end
  self._waiting_metro:start(0.25)
end

return MiUgensInstaller
