extends Node3D

## Main game scene — sets up input contexts, TileGrid, units, and cameras.

var _gameplay_contexts: Array[String] = ["third_person", "isometric"]
var _current_index: int = 0
var _grid: TileGrid
var _pause_menu: Node = null

const PauseMenuScene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")

@onready var _unit_manager: UnitManager = $UnitManager
@onready var _tp_camera: Camera3D = $ThirdPersonCamera
@onready var _iso_camera: IsometricCamera = $IsometricCamera


func _ready() -> void:
	InputSystem.push_context(_gameplay_contexts[_current_index])

	# Gather all Unit nodes and hand them to the manager
	var units: Array[Unit] = []
	for child in get_children():
		if child is Unit:
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
