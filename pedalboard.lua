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
-- When adding/changing pedals,
--  K2+K3 defaults to bypassed
--
-- Pedal Pages
-- E2 / E3 change dial values
-- K2 / K3 cycle thru dial pairs
-- Hold K2 tap K3 for tap tempo
--  (where appropriate)
--
-- Mod Matrix Page
-- E2 scrolls vertically
-- E3 changes values
-- K2 / K3 move left / right
--
-- Arc (optional)
-- "Follow" mode:
-- On The Board,
-- each enc controls wet/dry.
-- On Pedal Pages,
-- E1,2,3 change dial values
-- E4 changes wet/dry.
-- On Mod Matrix,
-- E1,2,3,4 change whatever
-- is currently focused.
-- "Fixed" mode:
-- Use the params page
--  to choose which params
--  are controlled by which enc
--
-- Crow (optional)
-- Use the params page
--  to choose which params
--  are controlled
--  by which crow input
--
--
-- v2.3.0 @21echoes

engine.name = "Pedalboard"
local UI = require "ui"
local encoders = require "encoders"
local Board = include("lib/ui/board")
local ModMatrix = include("lib/ui/modmatrix")
local ScreenState = include("lib/ui/util/screen_state")
local Arcify = include("lib/ui/util/arcify")
local Crowify = include("lib/ui/util/crowify")

-- Pages UI management
local pages
local pages_table

-- Variables for the render loop
local SCREEN_FRAMERATE = 15
local screen_refresh_metro

-- User's initial audio settings
local initital_monitor_level
local initital_reverb_onoff
local initital_compressor_onoff

-- Arc control of parameters
local arcify = nil
-- Crow control of parameters
local crowify = nil

function init()
  -- Setup our overall rendering style
  screen.level(15)
  screen.aa(0)
  screen.line_width(1)

  -- Some pedals have requirements that may not be satisfied. Check for them now
  Board:add_optional_pedals_if_ready()

  -- Start setting up params (delegate to the Board class)
  params:add_separator("Pedalboard")
  Board:add_params()
  ModMatrix:add_params(Board.pedal_classes)
  setup_arcify()
  setup_crowify()
  params:bang()

  -- Turn off the built-in monitoring, reverb, etc.
  initital_monitor_level = params:get('monitor_level')
  params:set('monitor_level', -math.huge)
  initital_reverb_onoff = params:get('reverb')
  params:set('reverb', 1) -- 1 is OFF
  initital_compressor_onoff = params:get('compressor')
  params:set('compressor', 1) -- 1 is OFF

  -- Set up pages
  pages_table = {
    Board:new(
      add_page,
      insert_page_at_index,
      remove_page,
      swap_page,
      set_page_index
    ),
    ModMatrix:new(),
  }
  pages = UI.Pages.new(1, #pages_table)

  pages_table[1]:enter(arcify)
  _set_encoder_sensitivities()

  -- Render loop
  screen_refresh_metro = metro.init()
  screen_refresh_metro.event = render_loop
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
end

-- Interactions
function key(n, z)
  -- All key presses are routed to the current page's class.
  local screen_dirty = false
  if current_page() then screen_dirty = current_page():key(n, z) end
  ScreenState.mark_screen_dirty(screen_dirty)
end

function enc(n, delta)
  if n == 1 then
    -- E1 changes page
    pages:set_index_delta(util.clamp(delta, -1, 1), false)
    if current_page() then current_page():enter(arcify) end
    _set_encoder_sensitivities()
    ScreenState.mark_screen_dirty(true)
  else
    -- Other encoders are routed to the current page's class
    local screen_dirty = false
    if current_page() then screen_dirty = current_page():enc(n, delta) end
    ScreenState.mark_screen_dirty(screen_dirty)
  end
end

-- Render
function render_loop()
  if ScreenState.is_screen_dirty() then
    ScreenState.mark_screen_dirty(false)
    redraw()
  end
end

function redraw()
  screen.clear()

  -- Redraw both our content and the current page's content
  pages:redraw()
  if current_page() then current_page():redraw() end

  screen.update()
end

function cleanup()
  -- deinitialization
  metro.free(screen_refresh_metro.id)
  screen_refresh_metro = nil
  -- I'm not particularly sure on the details of Lua memory management, so we go a little overboard here maybe
  for i, page in ipairs(pages_table) do
    pages_table[i]:cleanup()
    pages_table[i] = nil
  end
  pages_table = nil
  pages = nil
  -- Put user's audio settings back where they were
  params:set('monitor_level', initital_monitor_level)
  params:set('reverb', initital_reverb_onoff)
  params:set('compressor', initital_compressor_onoff)
end

-- Utils
function current_page()
  if pages_table == nil or pages == nil then return nil end
  return pages_table[pages.index]
end

function modmatrix_page()
  return pages_table[#pages_table]
end

function set_page_index(new_page_index)
  pages:set_index(new_page_index)
  if current_page() then current_page():enter(arcify) end
  _set_encoder_sensitivities()
  ScreenState.mark_screen_dirty(true)
end

function add_page(page_instance)
  -- ModMatrix is always the last page, so we insert one before last
  local index = #pages_table
  table.insert(pages_table, index, page_instance)
  modmatrix_page():add_pedal(page_instance, index - 1)
  pages = UI.Pages.new(1, #pages_table)
  ScreenState.mark_screen_dirty(true)
end

function insert_page_at_index(index, page_instance)
  table.insert(pages_table, index, page_instance)
  modmatrix_page():add_pedal(page_instance, index - 1)
  pages = UI.Pages.new(1, #pages_table)
  ScreenState.mark_screen_dirty(true)
end

function remove_page(index, cleanup)
  cleanup = cleanup == nil and true or cleanup
  page = table.remove(pages_table, index)
  if cleanup then
    page:cleanup()
  end
  modmatrix_page():remove_pedal(index - 1)
  pages = UI.Pages.new(1, #pages_table)
  ScreenState.mark_screen_dirty(true)
end

function swap_page(index, page_instance)
  local old_pedal = pages_table[index]
  pages_table[index] = page_instance
  modmatrix_page():remove_pedal(index - 1)
  modmatrix_page():add_pedal(page_instance, index - 1)
  old_pedal:cleanup()
  ScreenState.mark_screen_dirty(true)
end

function _set_encoder_sensitivities()
  -- 1 sensitivity should be a bit slower
  norns.enc.sens(1, 5)
  -- Set the E2 and E3 sensitivities to be quite slower on the Board, otherwise just a bit slower
  norns.enc.sens(2, pages.index == 1 and 5 or 2)
  norns.enc.sens(3, pages.index == 1 and 6 or 2)
end

function setup_arcify()
  params:add_group("Arc", 5)
  params:add({
    id = "arc_mode",
    name = "Arc Follow Mode",
    type = "option",
    options = {"Follow Screen", "Fixed"},
  })
  arcify = Arcify.new()
  for pedal_index, pedal in ipairs(Board.pedal_classes) do
    for i, param_id in ipairs(pedal._param_ids_flat) do
      arcify:register(param_id)
    end
  end
  ModMatrix:arcify_register(arcify)
  arcify:add_params()
end

function setup_crowify()
  -- Crowify adds its own group
  crowify = Crowify.new()
  for pedal_index, pedal in ipairs(Board.pedal_classes) do
    for i, param_id in ipairs(pedal._param_ids_flat) do
      crowify:register(param_id)
    end
  end
  ModMatrix:crowify_register(crowify)
  crowify:add_params()
end

-- TODO: how do we manage upgrading MiUgens versions?
-- probably: a mi-ugens-version.txt file
-- but... what do we do when that's missing? or when it's *newer* than what we expect?
