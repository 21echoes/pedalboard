local OptionalPedals = {}
OptionalPedals.__index = OptionalPedals

function OptionalPedals.add_if_ready(pedal_class)
  local requirements_satisfied = true
  for i, path in ipairs(pedal_class.required_files) do
    if not util.file_exists(path) then
      requirements_satisfied = false
      break
    end
  end
  if requirements_satisfied then
    engine.add_pedal_definition(pedal_class.id)
  end
  return requirements_satisfied
end

return OptionalPedals
