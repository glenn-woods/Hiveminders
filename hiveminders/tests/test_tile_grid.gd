## Unit tests for TileGrid.
## Run this script as a standalone scene (extends Node) or attach it to a test runner.
##
## Requirements covered: tile-grid-system
extends Node


func _ready() -> void:
	test_default_dimensions()
	test_custom_dimensions()
	test_initial_state()
	test_is_in_bounds()
	test_set_get_block()
	test_block_requires_floor_invariant()
	test_set_block_to_air_retains_floor()
	test_set_get_floor()
	test_floor_to_empty_clears_block()
	test_out_of_bounds_returns_failure()
	test_out_of_bounds_no_state_change()
	test_add_remove_get_components()
	test_component_no_duplicates()
	test_z_level_access()
	test_z_level_out_of_bounds()
	test_dirty_level_tracking()
	print("All TileGrid unit tests passed.")


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

func _make_grid(xs: int, ys: int, zs: int) -> TileGrid:
	var grid := TileGrid.new()
	grid.x_size = xs
	grid.y_size = ys
	grid.z_size = zs
	add_child(grid)
	grid.initialize()
	return grid


# ---------------------------------------------------------------------------
# 1. Default dimensions
# ---------------------------------------------------------------------------

func test_default_dimensions() -> void:
	var grid := TileGrid.new()
	add_child(grid)
	# Do not call initialize() — _ready() will have been called by add_child.
	assert(grid.x_size == 128,
		"Expected default x_size=128, got %d" % grid.x_size)
	assert(grid.y_size == 128,
		"Expected default y_size=128, got %d" % grid.y_size)
	assert(grid.z_size == 8,
		"Expected default z_size=8, got %d" % grid.z_size)
	grid.queue_free()


# ---------------------------------------------------------------------------
# 2. Custom dimensions
# ---------------------------------------------------------------------------

func test_custom_dimensions() -> void:
	var grid := _make_grid(4, 4, 2)
	assert(grid.x_size == 4,
		"Expected x_size=4, got %d" % grid.x_size)
	assert(grid.y_size == 4,
		"Expected y_size=4, got %d" % grid.y_size)
	assert(grid.z_size == 2,
		"Expected z_size=2, got %d" % grid.z_size)
	grid.queue_free()


# ---------------------------------------------------------------------------
# 3. Initial state — all tiles are "air" block, "empty" floor, no components
# ---------------------------------------------------------------------------

func test_initial_state() -> void:
	var grid := _make_grid(4, 4, 2)
	for z in range(2):
		for y in range(4):
			for x in range(4):
				assert(grid.get_block(x, y, z) == "air",
					"Expected block 'air' at (%d,%d,%d)" % [x, y, z])
				assert(grid.get_floor(x, y, z) == "empty",
					"Expected floor 'empty' at (%d,%d,%d)" % [x, y, z])
				assert(grid.get_components(x, y, z).is_empty(),
					"Expected no components at (%d,%d,%d)" % [x, y, z])
	grid.queue_free()


# ---------------------------------------------------------------------------
# 4. is_in_bounds
# ---------------------------------------------------------------------------

func test_is_in_bounds() -> void:
	var grid := _make_grid(4, 4, 2)
	assert(grid.is_in_bounds(0, 0, 0),
		"(0,0,0) should be in bounds")
	assert(grid.is_in_bounds(3, 3, 1),
		"(3,3,1) should be in bounds")
	assert(not grid.is_in_bounds(-1, 0, 0),
		"(-1,0,0) should be out of bounds")
	assert(not grid.is_in_bounds(4, 0, 0),
		"(4,0,0) should be out of bounds")
	assert(not grid.is_in_bounds(0, 4, 0),
		"(0,4,0) should be out of bounds")
	assert(not grid.is_in_bounds(0, 0, 2),
		"(0,0,2) should be out of bounds")
	grid.queue_free()


# ---------------------------------------------------------------------------
# 5. set_block / get_block
# ---------------------------------------------------------------------------

func test_set_get_block() -> void:
	var grid := _make_grid(4, 4, 2)
	var ok := grid.set_block(1, 1, 0, "stone")
	assert(ok, "set_block(1,1,0,'stone') should return true")
	assert(grid.get_block(1, 1, 0) == "stone",
		"get_block(1,1,0) should return 'stone', got '%s'" % grid.get_block(1, 1, 0))
	grid.queue_free()


# ---------------------------------------------------------------------------
# 6. Block requires floor invariant — setting a non-air block auto-sets floor
# ---------------------------------------------------------------------------

func test_block_requires_floor_invariant() -> void:
	var grid := _make_grid(4, 4, 2)
	grid.set_block(1, 1, 0, "stone")
	assert(grid.get_floor(1, 1, 0) == "stone",
		"Floor should be auto-set to 'stone' when block is placed on empty floor, got '%s'" % grid.get_floor(1, 1, 0))
	grid.queue_free()


# ---------------------------------------------------------------------------
# 7. Setting block to air retains the floor
# ---------------------------------------------------------------------------

func test_set_block_to_air_retains_floor() -> void:
	var grid := _make_grid(4, 4, 2)
	grid.set_block(1, 1, 0, "stone")  # also auto-sets floor to "stone"
	grid.set_block(1, 1, 0, "air")
	assert(grid.get_floor(1, 1, 0) == "stone",
		"Floor should remain 'stone' after block is set to air, got '%s'" % grid.get_floor(1, 1, 0))
	grid.queue_free()


# ---------------------------------------------------------------------------
# 8. set_floor / get_floor
# ---------------------------------------------------------------------------

func test_set_get_floor() -> void:
	var grid := _make_grid(4, 4, 2)
	var ok := grid.set_floor(1, 1, 0, "dirt")
	assert(ok, "set_floor(1,1,0,'dirt') should return true")
	assert(grid.get_floor(1, 1, 0) == "dirt",
		"get_floor(1,1,0) should return 'dirt', got '%s'" % grid.get_floor(1, 1, 0))
	grid.queue_free()


# ---------------------------------------------------------------------------
# 9. Setting floor to "empty" clears the block
# ---------------------------------------------------------------------------

func test_floor_to_empty_clears_block() -> void:
	var grid := _make_grid(4, 4, 2)
	grid.set_block(1, 1, 0, "stone")
	grid.set_floor(1, 1, 0, "empty")
	assert(grid.get_block(1, 1, 0) == "air",
		"Block should be cleared to 'air' when floor is set to 'empty', got '%s'" % grid.get_block(1, 1, 0))
	grid.queue_free()


# ---------------------------------------------------------------------------
# 10. Out-of-bounds calls return failure values
# ---------------------------------------------------------------------------

func test_out_of_bounds_returns_failure() -> void:
	var grid := _make_grid(4, 4, 2)
	assert(not grid.set_block(-1, 0, 0, "stone"),
		"set_block(-1,0,0,'stone') should return false")
	assert(grid.get_block(-1, 0, 0) == "",
		"get_block(-1,0,0) should return '', got '%s'" % grid.get_block(-1, 0, 0))
	assert(not grid.set_floor(4, 0, 0, "stone"),
		"set_floor(4,0,0,'stone') should return false")
	grid.queue_free()


# ---------------------------------------------------------------------------
# 11. Out-of-bounds calls do not modify any tile state
# ---------------------------------------------------------------------------

func test_out_of_bounds_no_state_change() -> void:
	var grid := _make_grid(4, 4, 2)
	grid.set_block(-1, 0, 0, "stone")
	grid.set_block(4, 0, 0, "stone")
	grid.set_block(0, -1, 0, "stone")
	grid.set_block(0, 0, 2, "stone")
	for z in range(2):
		for y in range(4):
			for x in range(4):
				assert(grid.get_block(x, y, z) == "air",
					"No tile should be modified by out-of-bounds set_block, found '%s' at (%d,%d,%d)" % [grid.get_block(x, y, z), x, y, z])
	grid.queue_free()


# ---------------------------------------------------------------------------
# 12. add / remove / get components
# ---------------------------------------------------------------------------

func test_add_remove_get_components() -> void:
	var grid := _make_grid(4, 4, 2)
	var comp := TileComponent.new()
	grid.add_component(1, 1, 0, comp)
	var comps := grid.get_components(1, 1, 0)
	assert(comps.size() == 1,
		"Expected 1 component after add, got %d" % comps.size())
	assert(comps[0] == comp,
		"Retrieved component should be the same instance that was added")
	grid.remove_component(1, 1, 0, comp)
	assert(grid.get_components(1, 1, 0).is_empty(),
		"Expected no components after remove")
	grid.queue_free()


# ---------------------------------------------------------------------------
# 13. No duplicate components
# ---------------------------------------------------------------------------

func test_component_no_duplicates() -> void:
	var grid := _make_grid(4, 4, 2)
	var comp := TileComponent.new()
	grid.add_component(1, 1, 0, comp)
	grid.add_component(1, 1, 0, comp)  # add same instance again
	assert(grid.get_components(1, 1, 0).size() == 1,
		"Adding the same component twice should result in exactly 1 entry, got %d" % grid.get_components(1, 1, 0).size())
	grid.queue_free()


# ---------------------------------------------------------------------------
# 14. get_z_level returns correct data for all (x,y) in that level
# ---------------------------------------------------------------------------

func test_z_level_access() -> void:
	var grid := _make_grid(4, 4, 2)
	grid.set_block(0, 0, 0, "stone")
	grid.set_floor(2, 3, 0, "dirt")
	var level := grid.get_z_level(0)
	assert(level != null,
		"get_z_level(0) should not return null")
	assert(level[0][0]["block"] == "stone",
		"Expected block 'stone' at (0,0) in z-level 0, got '%s'" % level[0][0]["block"])
	assert(level[0][0]["floor"] == "stone",
		"Expected floor 'stone' at (0,0) in z-level 0 (auto-set), got '%s'" % level[0][0]["floor"])
	assert(level[2][3]["floor"] == "dirt",
		"Expected floor 'dirt' at (2,3) in z-level 0, got '%s'" % level[2][3]["floor"])
	assert(level[1][1]["block"] == "air",
		"Expected block 'air' at (1,1) in z-level 0, got '%s'" % level[1][1]["block"])
	grid.queue_free()


# ---------------------------------------------------------------------------
# 15. get_z_level out of bounds returns null
# ---------------------------------------------------------------------------

func test_z_level_out_of_bounds() -> void:
	var grid := _make_grid(4, 4, 2)
	assert(grid.get_z_level(2) == null,
		"get_z_level(2) should return null for a 4x4x2 grid")
	assert(grid.get_z_level(-1) == null,
		"get_z_level(-1) should return null")
	grid.queue_free()


# ---------------------------------------------------------------------------
# 16. Dirty level tracking
# ---------------------------------------------------------------------------

func test_dirty_level_tracking() -> void:
	var grid := _make_grid(4, 4, 2)
	grid.set_block(1, 1, 0, "stone")
	assert(grid._dirty_levels.has(0),
		"_dirty_levels should contain key 0 after set_block on z=0")
	assert(not grid._dirty_levels.has(1),
		"_dirty_levels should not contain key 1 when only z=0 was modified")
	grid.queue_free()
