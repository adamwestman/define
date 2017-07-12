
local input_states = require("define.input_states")
local default_button_transitions = require("define.internal.default_button_transitions")

local M = {}

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

function M.create(id, transitions)
	assert(id)
	transitions = transitions or default_button_transitions

	local instance = {
		node = ensure_node(id),
		transitions = transitions,
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
end

function M.on_input(instance, action_id, action)
	assert(instance)
	assert(action)

	if M.is_hidden(instance) or M.is_disabled(instance) then
		return
	end

	if action.pressed then
		if gui.pick_node(instance.node, action.x, action.y) then
			M.set_state(instance, input_states.STATE_PRESSED)
		end
	elseif action.released and instance.state == input_states.STATE_PRESSED then
		M.set_state(instance, input_states.STATE_IDLE)
		if gui.pick_node(instance.node, action.x, action.y) then
			return true
		end
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
