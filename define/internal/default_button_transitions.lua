local input_states = require("define.input_states")
local input_transitions = require("define.gui.input_transitions")

local COLOR_DARKEN = vmath.vector4(0.8)
local COLOR_DEFAULT = vmath.vector4(1)

return {
	input_transitions.create(input_states.STATE_IDLE, input_states.STATE_PRESSED, input_transitions.multi_parallell(
		input_transitions.shake(),
		input_transitions.to_color(COLOR_DARKEN)
	)),
	input_transitions.create(input_states.STATE_PRESSED, input_states.STATE_IDLE, input_transitions.multi_parallell(
		input_transitions.shake(),
		input_transitions.to_color(COLOR_DEFAULT)
	)),
	input_transitions.create(input_states.STATE_IDLE, input_states.STATE_HIDDEN, input_transitions.to_disabled()),
	input_transitions.create(input_states.STATE_HIDDEN, input_states.STATE_IDLE, input_transitions.to_enabled()),
	input_transitions.create(input_states.STATE_IDLE, input_states.STATE_HOVER, input_transitions.to_color(COLOR_DARKEN)),
	input_transitions.create(input_states.STATE_HOVER, input_states.STATE_IDLE, input_transitions.to_color(COLOR_DEFAULT)),
}
