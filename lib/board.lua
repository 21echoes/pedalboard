--- Board
-- @classmod Board

local UI = require "ui"

local Board = {}
Board.__index = Board

function Board.new()
  local i = {}
  setmetatable(i, Board)

  -- TODO: last slot is always "New?", and changing it to new type adds new "New?" slot after it
  i.tabs_table = {"Volume"}
  i.tabs = UI.Tabs.new(1, i.tabs_table)

  return i
end

function Board:key(n, z, set_page)
  -- Key-up currently has no meaning
  if z ~= 1 then
    return false
  end

  if n == 2 then
    -- Jump to focused pedal's page
    set_page(self.tabs.index + 1)
    return true
  elseif n == 3 then
    -- TODO: If focused pedal has a different pending type than its current type, swap out for new type
  end

  return false
end

function Board:enc(n, delta)
  if n == 2 then
    -- Change which pedal slot is focused
    self.tabs:set_index_delta(util.clamp(delta, -1, 1), false)
    return true
  elseif n == 3 then
    -- TODO: Change the type of the focused pedal (K3 to confirm)
  end

  return false
end

function Board:redraw()
  self.tabs:redraw()
end

return Board
