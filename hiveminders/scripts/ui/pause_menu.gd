extends BaseMenu

## Pause menu. Opened by the pause action from any gameplay context.
## Navigation is handled entirely by Godot's built-in GUI system.

## Set to false to prevent pausing (e.g. during cutscenes).
var allow_pause: bool = true

@onready var _overlay: ColorRect = $Overlay
@onready var _settings_btn: Button = $Panel/SettingsButton
@onready var _quit_btn: Button = $Panel/QuitButton


func _ready() -> void:
	super._ready()
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)


func _set_visible(show: bool) -> void:
	if _overlay != null:
		_overlay.visible = show
	if _settings_btn != null:
		_settings_btn.get_parent().visible = show


func _get_first_focus() -> Control:
	return _settings_btn


func _input(event: InputEvent) -> void:
	# Handle pause toggle from any state.
	if event.is_action_pressed("pause"):
		if is_open():
			close()
		elif allow_pause:
			open()
		get_viewport().set_input_as_handled()
		return

	# Delegate ui_cancel to base (closes the menu).
	super._input(event)


func _on_settings() -> void:
	print("[pause_menu] Settings pressed (placeholder)")


func _on_quit() -> void:
	close()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
