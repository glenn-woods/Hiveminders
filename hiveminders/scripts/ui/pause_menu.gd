extends CanvasLayer

## Pause menu UI. Shows a dimmed overlay with Settings and Quit buttons.
## Navigable with mouse, controller, or keyboard via ui context actions.

signal resumed

## Set to false to prevent pausing (e.g. in multiplayer).
var allow_pause: bool = true

var _paused_state: bool = false

@onready var _overlay: ColorRect = $Overlay
@onready var _panel: VBoxContainer = $Panel
@onready var _settings_btn: Button = $Panel/SettingsButton
@onready var _quit_btn: Button = $Panel/QuitButton


func _ready() -> void:
	_overlay.visible = false
	_panel.visible = false
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)
	_settings_btn.focus_neighbor_bottom = _quit_btn.get_path()
	_quit_btn.focus_neighbor_top = _settings_btn.get_path()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _paused_state:
			unpause()
		elif allow_pause:
			pause()
		get_viewport().set_input_as_handled()
		return

	if not _paused_state:
		return

	# UI context actions while paused
	if event.is_action_pressed("back"):
		unpause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("select"):
		# Activate the currently focused button
		var focused: Control = get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.emit_signal("pressed")
		get_viewport().set_input_as_handled()


func pause() -> void:
	_paused_state = true
	_overlay.visible = true
	_panel.visible = true
	InputSystem.push_context("ui")
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_settings_btn.grab_focus()


func unpause() -> void:
	_paused_state = false
	_overlay.visible = false
	_panel.visible = false
	get_tree().paused = false
	InputSystem.pop_context()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	resumed.emit()


func paused_state() -> bool:
	return _paused_state


func _on_settings() -> void:
	print("[pause_menu] Settings pressed (placeholder)")


func _on_quit() -> void:
	get_tree().quit()
