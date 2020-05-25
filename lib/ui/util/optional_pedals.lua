local OptionalPedals = {}
OptionalPedals.__index = OptionalPedals

function OptionalPedals.add_if_ready(pedal_class)
  if pedal_class:is_engine_ready() then
    return true
  end
  local requirements_satisfied = OptionalPedals.are_requirements_satisfied(pedal_class)
  if requirements_satisfied then
    engine.add_pedal_definition(pedal_class.id)
    pedal_class:update_engine_state()
  end
  engine_state = pedal_class.engine_state
  return requirements_satisfied, engine_state
end

function OptionalPedals.are_requirements_satisfied(pedal_class)
  if pedal_class:is_engine_ready() then return true end
  for i, path in ipairs(pedal_class.required_files) do
    if not util.file_exists(path) then
      return false
    end
  end
  return true
end

return OptionalPedals
