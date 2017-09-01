# DeFine

_When great is not good enough.. __it needs to be Fine.___

A UI/UX library for the Defold engine, providing fundamental components to build a rich graphical user interface in no time.

# Usage
Add latest zip URL as a [dependency](http://www.defold.com/manuals/libraries/#_setting_up_library_dependencies) in your Defold project: `https://github.com/adamwestman/define/archive/master.zip`

## Input Manager

The __define.input_manager__ provide a shared container to manage all components, allowing them to be grouped and prioritized.

```lua
function init(self)
  input_manager.acquire()

  self.btn_text = input_manager.add_button(self, button.create("text/bg"), function()
    self.current_proxy = TEXT_PROXY
    msg.post(self.current_proxy, "async_load")
  end)
  self.btn_volume = input_manager.add_button(self, button.create("volume/bg"), function()
    self.current_proxy = VOLUME_PROXY
    msg.post(self.current_proxy, "async_load")
  end)
  self.btn_back = input_manager.add_button(self, button.create("back/bg"), function()
    msg.post(self.current_proxy, "unload")
  end)

  button.hide(self.btn_back)
end

function final(self)
	input_manager.release()
end

function on_input(self, action_id, action)
	return input_manager.on_input(self, action_id, action)
end
```

### Buttons

The __define.gui.button__ component allows a gui node to react on user tap actions.

### Text Fields

The __define.gui.text__ component allows users to edit the contents of a text node.

```lua
local text = require "define.gui.text"

function init(self)
  self.name = text.create("name")
  self.place = text.create("place", {max_lengt=10})

  msg.post(".", "acquire_input_focus")
end

function on_input(self, action_id, action)
  if text.on_input(self.name, action_id, action) then
    return true
  elseif text.on_input(self.place, action_id, action) then
    return true
  end
end
```

### State Transitions

All components are built around a state/transition design. This enables the components to be appear and act in depending on needs. Here's an example of how a Checkbox component can be built using the __define.gui.button__ one.

```lua
local button = require "define.gui.button"
local volume_checkbox_transitions = require "examples.volume.volume_checkbox_transitions"

function init(self)
  self.volume = button.create("volume", volume_checkbox_transitions)

  msg.post(".", "acquire_input_focus")
end

function on_input(self, action_id, action)
  if button.on_input(self.volume, action_id, action) then
    self.muted = not self.muted
    button.set_state(self.volume, self.muted and hash("off") or hash("on"))
    sound.set_group_gain(hash("master"), self.muted and 0 or 1)
  end
end
```

Where the transitions handle the checked state.
```lua
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
	input_transitions.create(input_states.STATE_IDLE, hash("on"), input_transitions.to_flipbook(hash("volume_on"))),
	input_transitions.create(input_states.STATE_IDLE, hash("off"), input_transitions.to_flipbook(hash("volume_off"))),
}
```
