extends Node

## Simple test script — prints input system state and reacts to actions.
## Run the project with F5 in Godot and watch the Output panel at the bottom.
## toggle_mode cycles between gameplay contexts (third_person ↔ isometric).

## Non-base contexts to cycle through. Add more here as needed.
var _gameplay_contexts: Array[String] = ["third_person", "isometric"]
var _current_index: int = 0

func _ready():
	# Push the starting gameplay context on top of base.
	InputSystem.push_context(_gameplay_contexts[_current_index])

	print("=== Input System Test ===")
	print("Active context: ", InputSystem.get_active_context_name())
	print("Active scheme:  ", InputSystem.get_active_scheme())
	print("")
	print("toggle_mode cycles: %s" % str(_gameplay_contexts))
	print("pause = Escape / Start button")
	print("")

	InputSystem.active_scheme_changed.connect(_on_scheme_changed)
	InputSystem.context_changed.connect(_on_context_changed)


func _process(_delta):
	var ctx := InputSystem.get_active_context_name()

	# Base actions — always available
	if InputMap.has_action("pause") and Input.is_action_just_pressed("pause"):
		print("[%s] pause pressed!" % ctx)

	if InputMap.has_action("toggle_mode") and Input.is_action_just_pressed("toggle_mode"):
		_cycle_context()

	# Context-specific actions
	match ctx:
		"isometric":
			if InputMap.has_action("select") and Input.is_action_just_pressed("select"):
				print("[isometric] select pressed!")
			if InputMap.has_action("camera_pan_left"):
				var pan := Input.get_vector("camera_pan_left", "camera_pan_right", "camera_pan_up", "camera_pan_down")
				if pan.length() > 0.1:
					print("[isometric] camera_pan: ", pan)
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


func _cycle_context() -> void:
	# Pop current gameplay context back to base
	InputSystem.pop_context()
	# Advance to next context in the cycle
	_current_index = (_current_index + 1) % _gameplay_contexts.size()
	InputSystem.push_context(_gameplay_contexts[_current_index])
	print("--- Cycled to '%s' ---" % _gameplay_contexts[_current_index])


func _on_scheme_changed(scheme):
	var scheme_name := "KEYBOARD_MOUSE" if scheme == InputSystem.InputScheme.KEYBOARD_MOUSE else "GAMEPAD"
	print("[scheme] Switched to: ", scheme_name)


func _on_context_changed(context_name):
	print("[context] Changed to: ", context_name)
