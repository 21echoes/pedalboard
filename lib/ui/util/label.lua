
local Label = {}
Label.__index = Label

function Label.new(i)
  i = i or {}
  setmetatable(i, Label)
  i.__index = Label

  if i.center_x == nil then i.center_x = 0 end
  if i.y == nil then i.y = 0 end
  if i.level == nil then i.level = 15 end
  if i.text == nil then i.text = "" end
  if i.font_face == nil then i.font_face = 1 end
  if i.font_size == nil then i.font_size = 8 end

  return i
end

function Label:redraw()
  screen.move(self.center_x, self.y)
  screen.font_face(self.font_face)
  screen.font_size(self.font_size)
  screen.level(self.level)
  screen.text_center(self.text)
  -- Reset back to defaults
  screen.font_face(1)
  screen.font_size(8)
  screen.level(15)
  -- Prevent a stray line being drawn
  screen.stroke()
end

return Label