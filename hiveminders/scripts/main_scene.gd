extends Node3D

## Main game scene — sets up input context, TileGrid, and camera.

var _gameplay_contexts: Array[String] = ["third_person", "isometric"]
var _current_index: int = 0
var _grid: TileGrid


func _ready() -> void:
	InputSystem.push_context(_gameplay_contexts[_current_index])

	# Wire camera rig to player
	var player: CharacterBody3D = get_node("Player")
	var cam_rig: Node3D = get_node("CameraRig")
	player.camera_rig = cam_rig

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


func _process(_delta: float) -> void:
	if InputMap.has_action("toggle_mode") and Input.is_action_just_pressed("toggle_mode"):
		InputSystem.pop_context()
		_current_index = (_current_index + 1) % _gameplay_contexts.size()
		InputSystem.push_context(_gameplay_contexts[_current_index])

	# Rebuild any z-levels that changed
	_grid.rebuild_dirty_levels()
