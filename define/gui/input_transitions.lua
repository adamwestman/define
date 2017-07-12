local M = {}

function M.create(from_state, to_state, set_action)
	assert(from_state)
	assert(to_state)
	assert(type(set_action) == "function")

	return {
		from = from_state,
		to = to_state,
		set = set_action,
	}
end

function M.to_enabled()
	return function(node, done_cb)
		gui.set_enabled(node, true)
		if done_cb then
			done_cb(nil, node)
		end
	end
end

function M.to_disabled()
	return function(node, done_cb)
		gui.set_enabled(node, false)
		if done_cb then
			done_cb(nil, node)
		end
	end
end

function M.to_color(to, duration, easing, playback)
	assert(to)

	duration = duration or 0.2
	easing = easing or gui.EASING_LINEAR
	return function(node, done_cb)
		gui.animate(node, "color", to, easing, duration, 0, done_cb, playback)
	end
end

function M.to_scale(to, duration, easing, playback)
	assert(to)

	duration = duration or 0.2
	easing = easing or gui.EASING_LINEAR
	return function(node, done_cb)
		gui.animate(node, "scale", to, easing, duration, 0, done_cb, playback)
	end
end

function M.to_flipbook(to)
  assert(to)

	return function(node, done_cb)
		gui.play_flipbook(node, to, done_cb)
	end
end

function M.shake(initial_scale)
	initial_scale = initial_scale or vmath.vector3(1)
	local done
	local cb = function(self, node)
		gui.set_scale(node, initial_scale)
		if done then
			done(self, node)
		end
	end

	return function(node, done_cb)
		gui.cancel_animation(node, "scale.x")
		gui.cancel_animation(node, "scale.y")
		gui.set_scale(node, initial_scale)
		local scale = gui.get_scale(node)
		gui.set_scale(node, scale * 1.2)
		gui.animate(node, "scale.x", scale.x, gui.EASING_OUTELASTIC, 0.8)

		done = done_cb
		gui.animate(node, "scale.y", scale.y, gui.EASING_OUTELASTIC, 0.8, 0.05, cb)
	end
end

function M.pulse(initial_scale)
	initial_scale = initial_scale or vmath.vector3(1)

	return function(node, done_cb)
		gui.cancel_animation(node, "scale.x")
		gui.cancel_animation(node, "scale.y")
		gui.set_scale(node, initial_scale)
		local scale = gui.get_scale(node) * 1.2
		gui.animate(node, "scale.x", scale.x, gui.EASING_INOUTCIRC, 2, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
		gui.animate(node, "scale.y", scale.y, gui.EASING_INOUTCIRC, 2, 0.15, nil, gui.PLAYBACK_LOOP_PINGPONG)

		if done_cb then
			done_cb(nil, node)
		end
	end
end

function M.multi_sequence(...)
	local transitions = {...}
	assert(#transitions > 0)

	local i, cb, done
	cb = function(self, node)
		i = i + 1
		if transitions[i] then
			transitions[i](node, cb)
		elseif done then
			done(self, node)
		end
	end
	return function(node, done_cb)
		i = 0
		done = done_cb
		cb(nil, node)
	end
end

function M.multi_parallell(...)
	local transitions = {...}
	local count = #transitions
	assert(count > 0)

	return function(node, done_cb)
		for i, transition in pairs(transitions) do
			if i == count then
				transition(node, done_cb)
			else
				transition(node)
			end
		end
	end
end

return M
