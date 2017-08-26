local button = require("define.gui.button")
local text = require("define.gui.text")

local input_actions = require("define.input_actions")

local M = {}

-------------------------- INPUT HANDLER MANAGEMENT

local function button_input_handler(object, action_id, action)
	if button.on_input(object.button, action_id, action) then
		object.callback(object.button)
		return true
	end
end

local function text_input_handler(object, action_id, action)
	if text.on_input(object.text, action_id, action) then
		--[[ We don't want the behaviour to be different when added to input_manager.
		if action_id == input_actions.ENTER then
			text.blurr(object.text)
		end
		--]]
		return true
	end
end

local TYPE_BUTTON = hash("button")
local TYPE_TEXT_FIELD = hash("text_field")

local input_handlers = {
	[TYPE_BUTTON] = button_input_handler,
	[TYPE_TEXT_FIELD] = text_input_handler,
}

-------------------------- INPUT GROUP MANAGEMENT

local function priority_sort(a, b)
	return a.priority < b.priority
end

local input_groups = {}

function M.add_button(group, button_instance, callback, priority)
	assert(group)
	assert(button_instance)
	assert(callback)
	priority = priority or 0

	local objects = input_groups[group] or {}

	table.insert(objects, {button = button_instance, callback = callback, priority = priority, type = TYPE_BUTTON})
	table.sort(objects, priority_sort)

	input_groups[group] = objects

	return button_instance
end

function M.remove_button(button_instance)
	assert(button_instance)

	for _, objects in pairs(input_groups) do
		for i, object in pairs(objects) do
			if object.button == button_instance then
				table.remove(objects, i)
				return true
			end
		end
	end
	return false
end

function M.add_text(group, text_instance, priority)
	assert(group)
	assert(button_instance)
	assert(callback)
	priority = priority or 0

	local objects = input_groups[group] or {}

	table.insert(objects, {text = text_instance, priority = priority, type = TYPE_TEXT_FIELD})
	table.sort(objects, priority_sort)

	input_groups[group] = objects

	return button_instance
end

function M.remove_text(text_instance)
	assert(text_instance)

	for _, objects in pairs(input_groups) do
		for i, object in pairs(objects) do
			if object.text == text_instance then
				table.remove(objects, i)
				return true
			end
		end
	end
	return false
end

function M.remove_group(group)
	assert(group)

	local objects = input_groups[group] or {}
	while #objects > 0 do
		table.remove(objects)
	end
end

function M.on_input(group, action_id, action)
	assert(group)
	assert(action)

	local objects = input_groups[group] or {}
	for _, object in pairs(objects) do
		if input_handlers[object.type](object, action_id, action) then
			return true
		end
	end
end

function M.acquire()
	msg.post(".", "acquire_input_focus")
end

function M.release()
	msg.post(".", "release_input_focus")
end

return M
