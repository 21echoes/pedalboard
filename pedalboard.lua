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
local Board = include("lib/board")

-- Pages UI management
local pages
local pages_table

-- Variables for the render loop
local SCREEN_FRAMERATE = 15
local screen_refresh_metro
local screen_dirty = true

function init()
  -- Setup our overall rendering style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)

  -- Set up pages
  pages_table = {Board.new()}
  pages = UI.Pages.new(1, #pages_table)

  -- Render loop
  screen_refresh_metro = metro.init()
  screen_refresh_metro.event = render_loop
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
end

-- Interactions
function key(n, z)
  -- All key presses are routed to the current page's class.
  -- We also provide a callback so that the current page can change the page
  screen_dirty = current_page():key(n, z, set_page_index, add_page, swap_page)
end

function enc(n, delta)
  if n == 1 then
    -- E1 changes page
    pages:set_index_delta(util.clamp(delta, -1, 1), false)
    screen_dirty = true
  else
    -- Other encoders are routed to the current page's class
    screen_dirty = current_page():enc(n, delta)
  end
end

-- Render
function render_loop()
  if screen_dirty then
    screen_dirty = false
    redraw()
  end
end

function redraw()
  screen.clear()

  -- Redraw both our content and the current page's content
  pages:redraw()
  current_page():redraw()

  screen.update()
end

-- Utils
function current_page()
  return pages_table[pages.index]
end

function set_page_index(new_page_index)
  pages:set_index(new_page_index)
  screen_dirty = true
end

function add_page(page_instance)
  table.insert(pages_table, page_instance)
  pages = UI.Pages.new(1, #pages_table)
  screen_dirty = true
end

function swap_page(index, page_instance)
  pages_table[index] = page_instance
  screen_dirty = true
end
