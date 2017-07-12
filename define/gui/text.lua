
local input_states = require("define.input_states")
local input_actions = require("define.input_actions")
local default_text_transitions = require("define.internal.default_text_transitions")

local M = {}

M.default_config = {
  keyboard_type = gui.KEYBOARD_TYPE_DEFAULT,
  max_lengt = nil,
}

M.WARNING_TRANSITIONS = false

local function log_w(...)
	if M.WARNING_TRANSITIONS then
		print(...)
	end
end

local function get_transition(transitions, from, to)
	if from == to then
		log_w("Same state, abort", from, to)
		return
	end

	for _, transition in pairs(transitions) do
		if transition.from == from and transition.to == to then
			log_w("Transition from to", from, to)
			return transition
		end
	end

	log_w("WARNING: No transition between", from, to)

	for _, transition in pairs(transitions) do
		if transition.to == to then
			log_w("Fallback: Transition from to", transition.from, to)
			return transition
		end
	end
end

local function ensure_node(node_or_id)
	return (type(node_or_id) == "string") and gui.get_node(node_or_id) or node_or_id
end

local function repaint(instance)
  if instance.state == input_states.STATE_FOCUSED then
    -- todo, add arrow navigation and position
    local display_text = instance.text .. "|"
    gui.set_text(instance.node, display_text)
  else
    gui.set_text(instance.node, instance.text)
  end
end

function M.create(id, config, transitions)
	assert(id)
  config = config or M.default_config -- todo: add merge
	transitions = transitions or default_text_transitions
  local node = ensure_node(id)
	local instance = {
    text = gui.get_text(node),
		node = node,
		transitions = transitions,
    config = config,
	}
	M.set_state(instance, input_states.STATE_IDLE)

	return instance
end

function M.hide(instance)
	assert(instance)

	M.set_state(instance, input_states.STATE_HIDDEN)
end

function M.show(instance)
	assert(instance)

	M.set_state(instance, input_states.STATE_IDLE)
end

function M.is_hidden(instance)
	assert(instance)

	return instance.state == input_states.STATE_HIDDEN
end

function M.disable(instance)
	assert(instance)

	M.set_state(instance, input_states.STATE_DISABLED)
end

function M.enable(instance)
	assert(instance)

	M.set_state(instance, input_states.STATE_IDLE)
end

function M.is_disabled(instance)
	assert(instance)

	return instance.state == input_states.STATE_DISABLED
end

function M.focus()
	assert(instance)

	M.set_state(instance, input_states.STATE_FOCUSED)
end

function M.blurr()
	assert(instance)

	M.set_state(instance, input_states.STATE_IDLE)
end

function M.is_focused(instance)
	assert(instance)

	return instance.state == input_states.STATE_FOCUSED
end

function M.get_text(instance)
  assert(instance)

  return instance.text
end

function M.set_text(instance, text)
  assert(instance)

  instance.text = text

  repaint(instance)
end

function M.set_transitions(instance, transitions)
	assert(instance)

	instance.transitions = transitions
end

function M.set_state(instance, to_state)
	assert(instance)
	assert(to_state)

	local from_state = instance.state
	local transition = get_transition(instance.transitions, from_state, to_state)
	if transition then
		transition.set(instance.node)
	else
		log_w("WARNING: No transition to", to_state)
		return
	end
	instance.state = to_state
  repaint(instance)
end

local function insert_text(instance, text)
  if instance.config.max_lengt then
    local len = string.len(instance.text)
    if len >= instance.config.max_lengt then
      return
    end
  end

  instance.text = instance.text .. text
  repaint(instance)
end

local function erase_text(instance)
  local len = string.len(instance.text)
  if len > 0 then
    instance.text = string.sub(instance.text, 0, len-1)
    repaint(instance)
  end
end

function M.on_input(instance, action_id, action)
	assert(instance)
	assert(action)

	if M.is_hidden(instance) or M.is_disabled(instance) then
		return
	end

  -- handle touch states
  if action_id == input_actions.TOUCH then
    if action.pressed then
  		if gui.pick_node(instance.node, action.x, action.y) then
  			M.set_state(instance, input_states.STATE_PRESSED)
      else
        M.set_state(instance, input_states.STATE_IDLE)
  		end

  	elseif action.released and instance.state == input_states.STATE_PRESSED then
  		if gui.pick_node(instance.node, action.x, action.y) then
        M.set_state(instance, input_states.STATE_FOCUSED)
  			return true
      else
        M.set_state(instance, input_states.STATE_IDLE)
  		end

    end

  -- handle text states
  elseif instance.state == input_states.STATE_FOCUSED then
    if action_id == input_actions.TEXT then
      insert_text(instance, action.text)
      return true

    elseif action_id == input_actions.BACKSPACE then
      if action.pressed or action.repeated then
        erase_text(instance)
      end
      return true

    end

  -- handle hover states
	elseif instance.state == input_states.STATE_IDLE then
		if gui.pick_node(instance.node, action.x, action.y) then
			M.set_state(instance, input_states.STATE_HOVER)
		end
	elseif instance.state == input_states.STATE_HOVER then
		if not gui.pick_node(instance.node, action.x, action.y) then
			M.set_state(instance, input_states.STATE_IDLE)
		end

	end

end

return M
