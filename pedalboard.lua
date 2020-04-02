-- Pedalboard: Chainable FX
--
-- E1 changes page
--
-- Main Page: The Board
-- E2 changes focused slot
-- E3 changes pedal
-- E3 doesnt take effect til K3
-- K2 jumps to pedal page
-- K2 + E2 re-orders pedals
-- K2 + E3 changes wet/dry
-- K2 + K3 toggles bypass
--
-- Pedal Pages
-- E2 / E3 change knob values
-- K2 / K3 cycle thru knob pairs
--
-- v0.1 @21echoes

local UI = require "ui"

-- High level UI management
local pages
local tabs

-- Variables for the render loop
local SCREEN_FRAMERATE = 15
local screen_refresh_metro
local screen_dirty = true

-- UI testing
-- TODO: remove
local dial_l
local dial_r

function init()
  -- Setup our overall rendering style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)

  -- Set up pages and tabs
  pages = UI.Pages.new(1, 3)
  tabs = UI.Tabs.new(1, {"1", "2", "3", "4"})

  -- x, y, size, value, min_value, max_value, rounding, start_value, markers, units, title
  dial_l = UI.Dial.new(9, 19, 22, 25, 0, 100, 1)
  dial_r = UI.Dial.new(34.5, 34, 22, 0.3, -1, 1, 0.01, 0, {0})

  -- Render loop
  screen_refresh_metro = metro.init()
  screen_refresh_metro.event = function()
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
end

-- Interactions
function key(n, z)
  print('key', n, z)
  if z ~= 1 then
    return
  end

  if n == 2 then
    tabs:set_index_delta(-1, false)
  elseif n == 3 then
    tabs:set_index_delta(1, false)
  end

  redraw()
end

function enc(n, delta)
  print('enc', n, delta)

  if n == 1 then
    pages:set_index_delta(util.clamp(delta, -1, 1), false)
  elseif n == 2 then
    dial_l:set_value_delta(delta)
  elseif n == 3 then
    dial_r:set_value_delta(delta)
  end

  redraw()
end

-- Render
function redraw()
  screen.clear()

  pages:redraw()
  tabs:redraw()
  dial_l:redraw()
  dial_r:redraw()

  screen.update()
end
