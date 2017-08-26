local input_states = require("define.input_states")
local input_actions = require("define.input_actions")

local M = {}

M.MIN_MOVEMENT = 30

local function ensure_node(node_or_id)
	return (type(node_or_id) == "string") and gui.get_node(node_or_id) or node_or_id
end

function M.create(node, config)
  assert(node)
  node = ensure_node(node)
  config = config or {}

  return {
    node = node,
    force = vmath.vector3(0),
    children = {},
  }
end

function M.add_child(instance, node)
  assert(instance)
  assert(node)
  node = ensure_node(node)

  table.insert(instance.children, node)
end

function M.remove_child(instance, node)
  assert(instance)
  assert(node)
  node = ensure_node(node)

  for i, child in pairs(instance.children) do
    if child == node then
      table.remove(instance.children, i)
      return true
    end
  end
end

function M.add_force(instance, x, y)
  assert(instance)
  assert(x)
  assert(y)

  instance.force.x = instance.force.x + x
  instance.force.y = instance.force.y + y
end

function M.set_state(instance, to_state)
	assert(instance)
	assert(to_state)

	instance.state = to_state
end

function M.on_input(instance, action_id, action)
  assert(instance)
  assert(action)

  if action_id == input_actions.TOUCH then
    if action.pressed then
  		if gui.pick_node(instance.node, action.x, action.y) then
  			M.set_state(instance, input_states.STATE_PRESSED)

        -- abort former movement
        for _, child in pairs(instance.children) do
          gui.cancel_animation(child, gui.PROP_POSITION)
        end

        return true
  		end

  	elseif action.released and instance.state == input_states.STATE_PRESSED then
      M.set_state(instance, input_states.STATE_IDLE)
      if vmath.length(instance.force) < M.MIN_MOVEMENT then
        instance.force.x = 0
        instance.force.y = 0
        return true
      else
        -- release
        for _, child in pairs(instance.children) do
          local pos = gui.get_position(child)
          pos.x = pos.x + instance.force.x
          pos.y = pos.y + instance.force.y
          gui.animate(child, gui.PROP_POSITION, pos, gui.EASING_LINEAR, 2)
        end
        instance.force.x = 0
        instance.force.y = 0
      end

    elseif instance.state == input_states.STATE_PRESSED then
      -- apply movement
      M.add_force(instance, action.dx, action.dy)
      if vmath.length(instance.force) < M.MIN_MOVEMENT then
        return true
      end

      for _, child in pairs(instance.children) do
        local pos = gui.get_position(child)
        pos.x = pos.x + action.dx
        pos.y = pos.y + action.dy
        gui.set_position(child, pos)
      end
    end
  end
end

return M
