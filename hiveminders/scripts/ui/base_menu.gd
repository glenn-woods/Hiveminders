class_name BaseMenu
extends CanvasLayer

## Reusable base for all menus. Handles:
##   - Pushing/popping the "ui" input context
##   - Pausing/unpausing the scene tree
##   - Showing/hiding the menu
##   - Grabbing focus on the first button
##   - ui_cancel closes the menu
##
## Subclasses override:
##   _get_first_focus() -> Control   — which node gets focus on open
##   _on_cancel()                    — what happens when ui_cancel fires (default: close)

signal menu_closed

var _is_open: bool = false


func _ready() -> void:
	# Menus must keep processing while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_visible(false)


## Open the menu. Subclasses can call super.open() then do extra setup.
func open() -> void:
	if _is_open:
		return
	_is_open = true
	_set_visible(true)
	InputSystem.push_context("ui")
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var focus_target := _get_first_focus()
	if focus_target != null:
		focus_target.grab_focus()


## Close the menu. Subclasses can call super.close() then do extra cleanup.
func close() -> void:
	if not _is_open:
		return
	_is_open = false
	_set_visible(false)
	get_tree().paused = false
	InputSystem.pop_context()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	menu_closed.emit()


func is_open() -> bool:
	return _is_open


## Override to show/hide the menu's visual nodes.
func _set_visible(show: bool) -> void:
	pass


## Override to return the Control that should receive focus when the menu opens.
func _get_first_focus() -> Control:
	return null


## Override to customise cancel behaviour. Default is to close.
func _on_cancel() -> void:
	close()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_cancel()
		get_viewport().set_input_as_handled()
