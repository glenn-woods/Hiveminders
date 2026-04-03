extends Control

## Main menu scene. Entry point of the game.
## Navigation uses Godot's built-in GUI system via the ui input context.

@onready var _start_btn: Button = $Panel/StartButton
@onready var _settings_btn: Button = $Panel/SettingsButton
@onready var _quit_btn: Button = $Panel/QuitButton


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	InputSystem.push_context("ui")
	_start_btn.pressed.connect(_on_start)
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)
	_start_btn.grab_focus()


func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")


func _on_settings() -> void:
	print("[main_menu] Settings pressed (placeholder)")


func _on_quit() -> void:
	get_tree().quit()
