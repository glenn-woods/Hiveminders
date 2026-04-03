extends Node3D

## Main game scene — sets up input contexts, TileGrid, units, and cameras.

var _gameplay_contexts: Array[String] = ["third_person", "isometric"]
var _current_index: int = 0
var _grid: TileGrid
var _pause_menu: Node = null

const PauseMenuScene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
const UnitScene: PackedScene = preload("res://scenes/unit.tscn")

## Spawn positions for up to 4 players.
const SPAWN_POSITIONS: Array[Vector3] = [
	Vector3(0, 1.0, 0),
	Vector3(3, 1.0, 0),
	Vector3(-3, 1.0, 0),
	Vector3(0, 1.0, 3),
]

@onready var _unit_manager: UnitManager = $UnitManager
@onready var _tp_camera: Camera3D = $ThirdPersonCamera
@onready var _iso_camera: IsometricCamera = $IsometricCamera


func _ready() -> void:
	InputSystem.push_context(_gameplay_contexts[_current_index])

	# Spawn units from player slots
	var units: Array[Unit] = []
	var slots := PlayerManager.get_slots()
	for i in range(slots.size()):
		var slot := slots[i]
		var unit: Unit = UnitScene.instantiate()
		unit.is_owned = true
		if slot.selected_class != null:
			unit.body_color = slot.selected_class.body_color
			unit.move_speed = slot.selected_class.move_speed
			unit.jump_velocity = slot.selected_class.jump_velocity
		if i < SPAWN_POSITIONS.size():
			unit.transform.origin = SPAWN_POSITIONS[i]
		add_child(unit)
		units.append(unit)

	# Also add any scene-placed units (e.g. neutral units)
	for child in get_children():
		if child is Unit and child not in units:
			units.append(child)

	_unit_manager.setup(units, _tp_camera)

	# Start in third-person: TP camera active, iso off
	_tp_camera.current = true
	_iso_camera.current = false

	# Create and configure TileGrid
	_grid = TileGrid.new()
	_grid.x_size = 16
	_grid.y_size = 16
	_grid.z_size = 4
	add_child(_grid)
	_grid.initialize()
	_grid.setup_rendering(TypeRegistry)

	# Populate test area
	for x in range(16):
		for y in range(16):
			_grid.set_block(x, y, 0, "stone")
	_grid.set_block(2, 2, 1, "stone")
	_grid.set_block(3, 2, 1, "stone")
	_grid.set_block(2, 3, 1, "stone")

	# Build initial meshes + collision
	_grid.build_all_meshes()

	# Pause menu
	_pause_menu = PauseMenuScene.instantiate()
	add_child(_pause_menu)


func _process(_delta: float) -> void:
	if InputMap.has_action("toggle_mode") and Input.is_action_just_pressed("toggle_mode"):
		_toggle_camera_mode()

	# Rebuild any z-levels that changed
	_grid.rebuild_dirty_levels()


func _toggle_camera_mode() -> void:
	InputSystem.pop_context()
	_current_index = (_current_index + 1) % _gameplay_contexts.size()
	InputSystem.push_context(_gameplay_contexts[_current_index])

	var entering_third_person := _gameplay_contexts[_current_index] == "third_person"

	if entering_third_person:
		# Switch back to third-person camera
		_iso_camera.deactivate()
		_tp_camera.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_unit_manager.set_third_person_mode(true)
	else:
		# Switch to isometric camera
		_tp_camera.current = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		# On first switch, focus on the active unit's position
		var active := _unit_manager.get_active_unit()
		if active != null and not _iso_camera._has_saved_position:
			_iso_camera.focus_on(active.global_position)
		_iso_camera.activate()
		_unit_manager.set_third_person_mode(false)
