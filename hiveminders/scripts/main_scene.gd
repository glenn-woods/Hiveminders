extends Node3D

## Main game scene — sets up the starting input context and TileGrid rendering.

## Gameplay contexts to cycle through with toggle_mode.
var _gameplay_contexts: Array[String] = ["third_person", "isometric"]
var _current_index: int = 0

## TileGrid instance and per-z-level mesh instances.
var _grid: TileGrid
var _z_level_meshes: Dictionary = {}  # int -> MeshInstance3D


func _ready() -> void:
	InputSystem.push_context(_gameplay_contexts[_current_index])
	print("=== Main Scene ===")
	print("Context: %s" % InputSystem.get_active_context_name())

	# Create and configure TileGrid (small dimensions for testing)
	_grid = TileGrid.new()
	_grid.x_size = 16
	_grid.y_size = 16
	_grid.z_size = 4
	add_child(_grid)
	_grid.initialize()

	# Populate test area: fill z-level 0 with stone blocks (16x16 floor)
	for x in range(16):
		for y in range(16):
			_grid.set_block(x, y, 0, "stone")

	# Add a few stone blocks at z-level 1 to test vertical rendering
	_grid.set_block(2, 2, 1, "stone")
	_grid.set_block(3, 2, 1, "stone")
	_grid.set_block(2, 3, 1, "stone")

	# Generate initial meshes for all z-levels
	for z in range(_grid.z_size):
		_regenerate_z_level(z)

	# Clear dirty flags after initial generation
	_grid._dirty_levels.clear()


func _process(_delta: float) -> void:
	if InputMap.has_action("toggle_mode") and Input.is_action_just_pressed("toggle_mode"):
		InputSystem.pop_context()
		_current_index = (_current_index + 1) % _gameplay_contexts.size()
		InputSystem.push_context(_gameplay_contexts[_current_index])
		print("--- Switched to '%s' ---" % _gameplay_contexts[_current_index])

	# Regenerate meshes for dirty z-levels
	if not _grid._dirty_levels.is_empty():
		for z in _grid._dirty_levels.keys():
			_regenerate_z_level(z)
		_grid._dirty_levels.clear()


## Generates or updates the MeshInstance3D for a single z-level.
func _regenerate_z_level(z: int) -> void:
	var mesh := VoxelMeshGenerator.generate_z_level_mesh(_grid, z)

	if _z_level_meshes.has(z):
		var existing: MeshInstance3D = _z_level_meshes[z]
		if mesh != null:
			existing.mesh = mesh
		else:
			existing.queue_free()
			_z_level_meshes.erase(z)
		return

	if mesh == null:
		return

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	_grid.add_child(mi)
	_z_level_meshes[z] = mi
