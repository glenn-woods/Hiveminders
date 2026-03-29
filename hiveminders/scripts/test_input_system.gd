extends Node

## Simple test script — prints input system state and reacts to actions.
## Run the project with F5 in Godot and watch the Output panel at the bottom.
## Press 1 to switch to base context, 2 for isometric, 3 for third_person.

func _ready():
	print("=== Input System Test ===")
	print("Active context: ", InputSystem.get_active_context_name())
	print("Active scheme:  ", InputSystem.get_active_scheme())
	print("")
	print("Press 1 = base context, 2 = isometric, 3 = third_person")
	print("Then try the actions for that context.")
	print("")
	print("Base:         Escape=pause, Tab=toggle_mode")
	print("Isometric:    LMB=select, WASD=camera_pan, ScrollUp/Down=zoom")
	print("Third Person: WASD=move (vector), E=interact, LMB=attack")
	print("")
	print("Use a controller to see scheme auto-switch.")
	print("")

	InputSystem.active_scheme_changed.connect(_on_scheme_changed)
	InputSystem.context_changed.connect(_on_context_changed)


func _unhandled_key_input(event: InputEvent):
	if not event.is_pressed():
		return
	# Use raw key checks for context switching (these aren't InputMap actions)
	if event is InputEventKey:
		match event.keycode:
			KEY_1:
				_switch_to("base")
			KEY_2:
				_switch_to("isometric")
			KEY_3:
				_switch_to("third_person")


func _switch_to(context_name: String) -> void:
	# Pop everything back to base, then push the target
	while InputSystem.get_active_context_name() != "base" and InputSystem.get_active_context_name() != "":
		InputSystem.pop_context()
	if context_name != "base":
		InputSystem.push_context(context_name)
	print("--- Switched to '%s' context ---" % context_name)


func _process(_delta):
	var ctx := InputSystem.get_active_context_name()

	# Only check actions that exist in the current context
	match ctx:
		"base":
			if InputMap.has_action("pause") and Input.is_action_just_pressed("pause"):
				print("[base] pause pressed!")
			if InputMap.has_action("toggle_mode") and Input.is_action_just_pressed("toggle_mode"):
				print("[base] toggle_mode pressed!")
		"isometric":
			if InputMap.has_action("select") and Input.is_action_just_pressed("select"):
				print("[isometric] select pressed!")
			if InputMap.has_action("camera_pan") and Input.is_action_pressed("camera_pan"):
				print("[isometric] camera_pan held")
			if InputMap.has_action("camera_zoom_in") and Input.is_action_just_pressed("camera_zoom_in"):
				print("[isometric] camera_zoom_in!")
			if InputMap.has_action("camera_zoom_out") and Input.is_action_just_pressed("camera_zoom_out"):
				print("[isometric] camera_zoom_out!")
		"third_person":
			if InputMap.has_action("interact") and Input.is_action_just_pressed("interact"):
				print("[third_person] interact pressed!")
			if InputMap.has_action("attack") and Input.is_action_just_pressed("attack"):
				print("[third_person] attack pressed!")
			if InputMap.has_action("move_left"):
				var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
				if move.length() > 0.1:
					print("[third_person] move: ", move)


func _on_scheme_changed(scheme):
	var scheme_name := "KEYBOARD_MOUSE" if scheme == InputSystem.InputScheme.KEYBOARD_MOUSE else "GAMEPAD"
	print("[scheme] Switched to: ", scheme_name)


func _on_context_changed(context_name):
	print("[context] Changed to: ", context_name)
