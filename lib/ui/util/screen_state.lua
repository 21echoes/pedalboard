local ScreenState = {screen_dirty = true}

function ScreenState.mark_screen_dirty(screen_dirty)
  ScreenState.screen_dirty = screen_dirty
end

function ScreenState.is_screen_dirty()
  return ScreenState.screen_dirty
end

return ScreenState
