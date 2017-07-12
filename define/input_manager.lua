local button = require("define.gui.button")

local M = {}

local function button_input_handler(object, action_id, action)
	if button.on_input(object.button, action_id, action) then
		object.callback(object.button)
		return true
	end
end

local TYPE_BUTTON = hash("button")

local input_handlers = {
	[TYPE_BUTTON] = button_input_handler,
}

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
