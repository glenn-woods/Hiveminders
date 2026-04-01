extends Node3D

## Main game scene — sets up the starting input context.

## Gameplay contexts to cycle through with toggle_mode.
var _gameplay_contexts: Array[String] = ["third_person", "isometric"]
var _current_index: int = 0

func _ready() -> void:
	InputSystem.push_context(_gameplay_contexts[_current_index])
	print("=== Main Scene ===")
	print("Context: %s" % InputSystem.get_active_context_name())

func _process(_delta: float) -> void:
	if InputMap.has_action("toggle_mode") and Input.is_action_just_pressed("toggle_mode"):
		InputSystem.pop_context()
		_current_index = (_current_index + 1) % _gameplay_contexts.size()
		InputSystem.push_context(_gameplay_contexts[_current_index])
		print("--- Switched to '%s' ---" % _gameplay_contexts[_current_index])
