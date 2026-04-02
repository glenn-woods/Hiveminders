class_name EventTokenParser
extends RefCounted

## Converts a single event token string to an InputEvent.
## Returns [InputEvent, ""] on success, or [null, "error message"] on failure.
static func token_to_event(token: String) -> Array:
	var parts := token.split(":", false)
	if parts.is_empty():
		return [null, "empty token"]

	var prefix := parts[0]

	match prefix:
		"key":
			if parts.size() < 2:
				return [null, "invalid key token: '%s'" % token]
			var key_name := parts[1]
			var keycode := _resolve_keycode(key_name)
			if keycode == KEY_NONE:
				return [null, "unrecognized key name: '%s'" % key_name]
			var event := InputEventKey.new()
			event.keycode = keycode
			event.pressed = true
			return [event, ""]

		"mouse_button":
			if parts.size() < 2:
				return [null, "invalid mouse_button token: '%s'" % token]
			if not parts[1].is_valid_int():
				return [null, "invalid mouse_button index: '%s'" % parts[1]]
			var event := InputEventMouseButton.new()
			event.button_index = parts[1].to_int()
			event.pressed = true
			return [event, ""]

		"joy_button":
			if parts.size() < 2:
				return [null, "invalid joy_button token: '%s'" % token]
			if not parts[1].is_valid_int():
				return [null, "invalid joy_button index: '%s'" % parts[1]]
			var event := InputEventJoypadButton.new()
			event.device = -1  # -1 matches any device
			event.button_index = parts[1].to_int() as JoyButton
			event.pressed = true
			return [event, ""]

		"joy_axis":
			if parts.size() < 3:
				return [null, "invalid joy_axis token: '%s'" % token]
			if not parts[1].is_valid_int():
				return [null, "invalid joy_axis axis index: '%s'" % parts[1]]
			if not parts[2].is_valid_float():
				return [null, "invalid joy_axis value: '%s'" % parts[2]]
			var event := InputEventJoypadMotion.new()
			event.device = -1  # -1 matches any device
			event.axis = parts[1].to_int() as JoyAxis
			event.axis_value = parts[2].to_float()
			return [event, ""]

		_:
			return [null, "unrecognized event token: '%s'" % token]


## Converts an InputEvent to its canonical token string.
## Returns "" if the event type is not supported.
static func event_to_token(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var key_string := OS.get_keycode_string(key_event.keycode)
		if key_string.is_empty():
			return ""
		return "key:" + key_string

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return "mouse_button:" + str(mouse_event.button_index)

	if event is InputEventJoypadButton:
		var joy_btn_event := event as InputEventJoypadButton
		return "joy_button:" + str(joy_btn_event.button_index)

	if event is InputEventJoypadMotion:
		var joy_axis_event := event as InputEventJoypadMotion
		return "joy_axis:" + str(joy_axis_event.axis) + ":" + str(joy_axis_event.axis_value)

	return ""


## Resolves a key name string to a Godot keycode.
## Single uppercase letters A-Z map to ASCII 65-90.
## All other names are resolved via OS.find_keycode_from_string().
static func _resolve_keycode(key_name: String) -> Key:
	# Single uppercase letter: A=65 .. Z=90
	if key_name.length() == 1:
		var c := key_name.unicode_at(0)
		if c >= 65 and c <= 90:
			return c as Key

	var keycode := OS.find_keycode_from_string(key_name)
	return keycode
