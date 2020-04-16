-- This variable must be global so that it is properly shared between different scripts which import it
-- There's probably something I'm not understanding about Lua as to why this is, but
-- I know that declaring this variable as local breaks behavior
-- (as if every place which imports it has a different copy that doesn't share state)
_ScreenState = {screen_dirty = true}

function _ScreenState.mark_screen_dirty(screen_dirty)
  _ScreenState.screen_dirty = screen_dirty
end

function _ScreenState.is_screen_dirty()
  return _ScreenState.screen_dirty
end

return _ScreenState
