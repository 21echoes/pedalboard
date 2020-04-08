-- Pedalboard: Chainable FX
--
-- E1 changes page
--
-- Main Page: The Board
-- E2 changes focused slot
-- E3 changes pedal
-- E3 doesn't take effect til K3
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

engine.name = "Pedalboard"
local UI = require "ui"
local encoders = require "encoders"
local Board = include("lib/ui/board")

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

  -- Set up params (delegate to the Board class)
  params:add_separator("Pedalboard")
  Board.add_params()
  params:bang()

  -- Turn off the built-in monitoring, reverb, etc.
  -- TODO: is this good behavior? How do we put the user back where they were before when they leave?
  audio.level_monitor(0.0)
  audio.rev_off()
  audio.comp_off()

  -- Set up pages
  pages_table = {Board:new(
    add_page,
    insert_page_at_index,
    remove_page,
    swap_page,
    set_page_index,
    mark_screen_dirty
  )}
  pages = UI.Pages.new(1, #pages_table)

  -- Set the encoder sensitivities
  _set_encoder_sensitivities()

  -- Render loop
  screen_refresh_metro = metro.init()
  screen_refresh_metro.event = render_loop
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
end

-- Interactions
function key(n, z)
  -- All key presses are routed to the current page's class.
  -- We also provide callbacks for children modifying our state
  screen_dirty = current_page():key(n, z)
end

function enc(n, delta)
  if n == 1 then
    -- E1 changes page
    pages:set_index_delta(util.clamp(delta, -1, 1), false)
    _set_encoder_sensitivities()
    current_page():enter()
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

function cleanup()
  -- deinitialization
  metro.free(screen_refresh_metro)
  screen_refresh_metro = nil
  -- I'm not particularly sure on the details of Lua memory management, so we go a little overboard here maybe
  board = pages_table[1]
  board:cleanup()
  for i, page in ipairs(pages_table) do
    pages_table[i] = nil
  end
  pages_table = nil
  pages = nil
end

-- Utils
function current_page()
  return pages_table[pages.index]
end

function set_page_index(new_page_index)
  pages:set_index(new_page_index)
  current_page():enter()
  _set_encoder_sensitivities()
  screen_dirty = true
end

function add_page(page_instance)
  table.insert(pages_table, page_instance)
  pages = UI.Pages.new(1, #pages_table)
  screen_dirty = true
end

function insert_page_at_index(index, page_instance)
  table.insert(pages_table, index, page_instance)
  pages = UI.Pages.new(1, #pages_table)
  screen_dirty = true
end

function remove_page(index)
  table.remove(pages_table, index)
  pages = UI.Pages.new(1, #pages_table)
  screen_dirty = true
end

function swap_page(index, page_instance)
  pages_table[index] = page_instance
  screen_dirty = true
end

function mark_screen_dirty(is_screen_dirty)
  screen_dirty = is_screen_dirty
end

function _set_encoder_sensitivities()
  -- 1 sensitivity should be a bit slower
  norns.enc.sens(1, 5)
  -- Set the E2 and E3 sensitivities to be quite slower on the Board, otherwise just a bit slower
  norns.enc.sens(2, pages.index == 1 and 5 or 2)
  norns.enc.sens(3, pages.index == 1 and 6 or 2)
end
