
local Label = {}
Label.__index = Label

function Label.new(i)
  i = i or {
    center_x = 0,
    y = 0,
    level = 15,
    text = "",
  }
  setmetatable(i, Label)
  i.__index = Label

  return i
end

function Label:redraw()
  screen.move(self.center_x, self.y)
  screen.level(self.level)
  screen.text_center(self.text)
  screen.level(15)
  -- Prevent a stray line being drawn
  screen.stroke()
end

return Label