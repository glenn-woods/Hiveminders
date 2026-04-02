class_name UnitManager
extends Node

## Manages the roster of player-owned units and handles cycling
## the active (controlled) unit via D-pad left/right.
## The halo stays on the selected unit regardless of camera mode.

signal active_unit_changed(unit: Unit)

var _roster: Array[Unit] = []
var _active_index: int = 0
var _tp_camera: Node3D = null  ## Third-person camera (has set_target)
var _is_third_person: bool = true


## Call once after all units are added to the scene tree.
func setup(units: Array[Unit], tp_camera: Node3D) -> void:
	_tp_camera = tp_camera
	_roster.clear()
	for u: Unit in units:
		if u.is_owned:
			_roster.append(u)
	if _roster.is_empty():
		push_warning("UnitManager: no owned units in roster.")
		return
	_active_index = 0
	_activate_current()


func get_active_unit() -> Unit:
	if _roster.is_empty():
		return null
	return _roster[_active_index]


## Called by main_scene when the camera mode changes.
func set_third_person_mode(enabled: bool) -> void:
	_is_third_person = enabled
	var unit := get_active_unit()
	if unit == null:
		return
	if _is_third_person:
		# Returning to 3P — give control back and retarget camera
		unit.is_player_controlled = true
		unit.camera_rig = _tp_camera
		if _tp_camera.has_method("set_target"):
			_tp_camera.set_target(unit)
	else:
		# Entering isometric — release direct control
		unit.is_player_controlled = false
		unit.camera_rig = null


func cycle_next() -> void:
	if _roster.size() <= 1:
		return
	_deactivate_current()
	_active_index = (_active_index + 1) % _roster.size()
	_activate_current()


func cycle_prev() -> void:
	if _roster.size() <= 1:
		return
	_deactivate_current()
	_active_index = (_active_index - 1 + _roster.size()) % _roster.size()
	_activate_current()


func _activate_current() -> void:
	var unit := _roster[_active_index]
	# Halo always shows on the selected unit
	unit.set_halo_visible(true)
	if _is_third_person:
		unit.is_player_controlled = true
		unit.camera_rig = _tp_camera
		if _tp_camera.has_method("set_target"):
			_tp_camera.set_target(unit)
	active_unit_changed.emit(unit)


func _deactivate_current() -> void:
	var unit := _roster[_active_index]
	unit.set_halo_visible(false)
	unit.is_player_controlled = false
	unit.camera_rig = null


func _process(_delta: float) -> void:
	if InputMap.has_action("cycle_unit_next") and Input.is_action_just_pressed("cycle_unit_next"):
		cycle_next()
	if InputMap.has_action("cycle_unit_prev") and Input.is_action_just_pressed("cycle_unit_prev"):
		cycle_prev()
