class_name InputGenerators
extends RefCounted

## Lightweight random-data generators for the input-system property-based tests.
## Every public static function returns a valid, fully-initialised resource instance
## built from randomised values.


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Returns a random string of the given length using lowercase ASCII letters.
static func random_string(length: int = 8) -> String:
	var chars := "abcdefghijklmnopqrstuvwxyz"
	var result := ""
	for i in range(length):
		result += chars[randi() % chars.length()]
	return result


# ---------------------------------------------------------------------------
# Resource generators
# ---------------------------------------------------------------------------

## Returns an ActionDefinition with a random name and a random ActionType (0-2).
static func random_action_definition() -> ActionDefinition:
	var def := ActionDefinition.new()
	def.action_name = "action_" + random_string()
	def.action_type = (randi() % 3) as ActionDefinition.ActionType
	return def


## Returns an ActionBinding for the given action_name with 1-3 random InputEvents.
static func random_action_binding(action_name: String) -> ActionBinding:
	var binding := ActionBinding.new()
	binding.action_name = action_name
	var event_count: int = (randi() % 3) + 1
	for i in range(event_count):
		binding.events.append(random_input_event())
	return binding


## Returns a fully-wired InputContextBindings resource.
## If num_actions is -1 a random count between 1 and 20 is chosen.
## For every generated action, matching gamepad and keyboard bindings are created.
static func random_input_context_bindings(num_actions: int = -1) -> InputContextBindings:
	var ctx := InputContextBindings.new()
	ctx.context_name = "ctx_" + random_string()

	if num_actions < 0:
		num_actions = (randi() % 20) + 1

	for i in range(num_actions):
		var action_def := random_action_definition()
		ctx.actions.append(action_def)
		ctx.gamepad_bindings.append(random_action_binding(action_def.action_name))
		ctx.keyboard_mouse_bindings.append(random_action_binding(action_def.action_name))

	return ctx


## Returns a random InputEvent chosen from the four qualifying types:
## InputEventKey, InputEventMouseButton, InputEventJoypadButton, InputEventJoypadMotion.
static func random_input_event() -> InputEvent:
	var kind: int = randi() % 4
	match kind:
		0:
			var ev := InputEventKey.new()
			# Pick a random physical keycode from a small representative set.
			var keys: Array[int] = [
				KEY_A, KEY_B, KEY_C, KEY_D, KEY_E, KEY_F, KEY_G,
				KEY_W, KEY_S, KEY_SPACE, KEY_SHIFT, KEY_CTRL,
				KEY_ESCAPE, KEY_TAB, KEY_ENTER,
			]
			ev.physical_keycode = keys[randi() % keys.size()] as Key
			ev.pressed = true
			return ev
		1:
			var ev := InputEventMouseButton.new()
			var buttons: Array[int] = [
				MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE,
			]
			ev.button_index = buttons[randi() % buttons.size()] as MouseButton
			ev.pressed = true
			return ev
		2:
			var ev := InputEventJoypadButton.new()
			var joy_buttons: Array[int] = [
				JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y,
				JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER,
				JOY_BUTTON_START, JOY_BUTTON_BACK,
			]
			ev.button_index = joy_buttons[randi() % joy_buttons.size()] as JoyButton
			ev.pressed = true
			return ev
		_:
			var ev := InputEventJoypadMotion.new()
			var axes: Array[int] = [
				JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y,
				JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y,
				JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT,
			]
			ev.axis = axes[randi() % axes.size()] as JoyAxis
			ev.axis_value = randf_range(0.3, 1.0) * ([-1.0, 1.0][randi() % 2])
			return ev


## Returns a random InputScheme value (GAMEPAD or KEYBOARD_MOUSE).
static func random_scheme() -> InputSystem.InputScheme:
	if randi() % 2 == 0:
		return InputSystem.InputScheme.GAMEPAD
	return InputSystem.InputScheme.KEYBOARD_MOUSE
