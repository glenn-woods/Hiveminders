# Implementation Plan: Tile Grid System

## Overview

Implement the tile grid system for Hiveminders in GDScript. Build data definition classes (BlockTypeDef, FloorTypeDef), a CSV-driven TypeRegistry autoload, the core TileGrid with flat-array storage and structural invariants, a TileComponent base class, a VoxelMeshGenerator for per-z-level mesh building with face culling, and wire everything into the main scene. All new scripts go in `hiveminders/scripts/world/`, CSV data in `hiveminders/data/`, tests in `hiveminders/tests/`.

## Tasks

- [x] 1. Create type definition data classes and CSV data files
  - [x] 1.1 Create `hiveminders/scripts/world/block_type_def.gd` (BlockTypeDef)
    - `class_name BlockTypeDef extends RefCounted`
    - Properties: `type_id: String`, `display_name: String`, `material: StandardMaterial3D`, `is_air: bool`
    - _Requirements: 6.1_

  - [x] 1.2 Create `hiveminders/scripts/world/floor_type_def.gd` (FloorTypeDef)
    - `class_name FloorTypeDef extends RefCounted`
    - Properties: `type_id: String`, `display_name: String`, `material: StandardMaterial3D`, `is_empty: bool`
    - _Requirements: 6.2_

  - [x] 1.3 Create `hiveminders/data/block_types.csv`
    - Header: `type_id,display_name,is_air,color`
    - Rows: air (true, no color), stone (false, #808080), dirt (false, #8B6914)
    - _Requirements: 6.1, 6.6_

  - [x] 1.4 Create `hiveminders/data/floor_types.csv`
    - Header: `type_id,display_name,is_empty,color`
    - Rows: empty (true, no color), stone (false, #808080), dirt (false, #8B6914)
    - _Requirements: 6.2, 6.6_

- [x] 2. Implement TypeRegistry autoload
  - [x] 2.1 Create `hiveminders/scripts/world/type_registry.gd` (TypeRegistry)
    - `class_name TypeRegistry extends Node`
    - Exported paths: `block_types_path`, `floor_types_path` defaulting to `res://data/block_types.csv` and `res://data/floor_types.csv`
    - In `_ready()`: parse both CSV files using `FileAccess.open()`, split lines, validate headers, create `BlockTypeDef`/`FloorTypeDef` per row
    - Create `StandardMaterial3D` with `albedo_color` from hex color column; null material for air/empty
    - Store definitions in `_block_types` and `_floor_types` dictionaries keyed by `type_id`
    - Implement `get_block_type()`, `get_floor_type()`, `get_block_type_ids()`, `get_floor_type_ids()`
    - Log errors via `push_error()` for malformed rows, missing files, wrong headers, duplicate IDs, empty IDs, invalid booleans, invalid colors
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [x] 2.2 Register TypeRegistry as autoload in `hiveminders/project.godot`
    - Add `TypeRegistry="*res://scripts/world/type_registry.gd"` to the `[autoload]` section
    - _Requirements: 6.3, 6.4_


- [x] 3. Implement TileComponent base class
  - [x] 3.1 Create `hiveminders/scripts/world/tile_component.gd` (TileComponent)
    - `class_name TileComponent extends RefCounted`
    - Single method: `get_component_type() -> String` returning `""` (overridden by subclasses)
    - _Requirements: 5.1, 5.2, 5.3_

- [x] 4. Implement TileGrid core
  - [x] 4.1 Create `hiveminders/scripts/world/tile_grid.gd` (TileGrid) with grid initialization and coordinate validation
    - `class_name TileGrid extends Node3D`
    - Exported properties: `x_size`, `y_size`, `z_size` (defaults 128, 128, 8)
    - `initialize()`: allocate `_block_ids` and `_floor_ids` as `PackedStringArray` of size `x_size * y_size * z_size`, fill with `"air"` and `"empty"` respectively; clear `_components` and `_dirty_levels`
    - `_index(x, y, z) -> int`: flat index formula `x + y * x_size + z * x_size * y_size`
    - `is_in_bounds(x, y, z) -> bool`: validate all three coordinates against grid dimensions
    - Call `initialize()` from `_ready()`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3_

  - [x] 4.2 Implement block and floor get/set methods with structural invariants
    - `get_block(x, y, z) -> String`: return type_id or `""` on out-of-bounds
    - `set_block(x, y, z, type_id) -> bool`: store type_id, enforce block-requires-floor invariant (auto-set floor to match block type when placing non-air block on empty floor), mark z-level dirty
    - `get_floor(x, y, z) -> String`: return type_id or `""` on out-of-bounds
    - `set_floor(x, y, z, type_id) -> bool`: store type_id, enforce invariant (auto-set block to air when setting floor to empty on tile with non-air block), mark z-level dirty
    - Out-of-bounds operations return `false` without modifying state
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 9.1, 9.2_

  - [x] 4.3 Implement component system methods
    - `add_component(x, y, z, component) -> bool`: add to sparse `_components` dictionary, no duplicate instances
    - `remove_component(x, y, z, component) -> bool`: remove specific component instance
    - `get_components(x, y, z) -> Array`: return component list or empty array
    - Out-of-bounds operations return `false` or empty array
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [x] 4.4 Implement z-level access method
    - `get_z_level(z)`: return 2D Dictionary `{x: {y: {block, floor, components}}}` for the given z-level
    - Return `null` for out-of-bounds z
    - _Requirements: 10.1, 10.2_

- [x] 5. Checkpoint - Verify core grid logic
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Unit tests for TypeRegistry and TileGrid
  - [x] 6.1 Create `hiveminders/tests/test_tile_grid.gd` with unit tests
    - Test grid initialization: default dimensions, all tiles start as air/empty (Req 1.1, 1.2, 1.3)
    - Test coordinate validation: in-bounds returns true, out-of-bounds returns false (Req 2.1, 2.2, 2.3)
    - Test block get/set: set and retrieve block types (Req 3.1, 3.2)
    - Test block-requires-floor invariant: placing non-air block on empty floor auto-sets floor (Req 3.3, 9.1, 9.2)
    - Test setting block to air retains existing floor (Req 3.4)
    - Test floor get/set: set and retrieve floor types (Req 4.1, 4.2)
    - Test floor-to-empty invariant: setting floor to empty on non-air block auto-clears block (Req 4.3)
    - Test component add/remove/get and duplicate prevention (Req 5.1, 5.2, 5.3, 5.4)
    - Test z-level access returns correct 2D structure (Req 10.1, 10.2)
    - Test out-of-bounds operations return failure indicators without modifying state (Req 2.2)
    - Test dirty level tracking: modifying a tile marks its z-level dirty
    - Use small grid dimensions (e.g. 4×4×2) for fast test execution
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3, 5.4, 9.1, 9.2, 10.1, 10.2_


  - [ ]* 6.2 Write property test: block-requires-floor invariant holds after any sequence of set_block/set_floor calls
    - **Property 1: Block-requires-floor invariant**
    - Generate random sequences of `set_block()` and `set_floor()` calls on a small grid, assert that for every tile, if block is non-air then floor is non-empty
    - Run 100+ iterations
    - **Validates: Requirements 9.1, 9.2**

  - [ ]* 6.3 Write property test: out-of-bounds operations never modify grid state
    - **Property 2: Out-of-bounds safety**
    - Generate random out-of-bounds coordinates, snapshot grid state before operation, call set_block/set_floor/add_component, assert grid state unchanged
    - Run 100+ iterations
    - **Validates: Requirements 2.2**

  - [ ]* 6.4 Write property test: index round-trip consistency
    - **Property 3: Index round-trip**
    - For random valid (x, y, z), call `set_block()` then `get_block()`, assert the returned type_id matches what was set
    - Run 100+ iterations
    - **Validates: Requirements 3.1, 3.2, 4.1, 4.2**

  - [ ]* 6.5 Write property test: component add is idempotent for same instance
    - **Property 4: Component add idempotency**
    - Add the same component instance to a tile multiple times, assert `get_components()` contains it exactly once
    - Run 100+ iterations
    - **Validates: Requirements 5.4**

  - [ ]* 6.6 Write property test: setting block to air preserves floor
    - **Property 5: Air block preserves floor**
    - Set a non-air block (which auto-sets floor), then set block to air, assert floor is unchanged
    - Run 100+ iterations
    - **Validates: Requirements 3.4**

  - [ ]* 6.7 Write property test: setting floor to empty clears block
    - **Property 6: Empty floor clears block**
    - Set a non-air block on a tile, then set floor to empty, assert block is now air
    - Run 100+ iterations
    - **Validates: Requirements 4.3**

  - [ ]* 6.8 Write property test: grid size matches configured dimensions
    - **Property 7: Grid size consistency**
    - Create grids with random small dimensions, assert `_block_ids.size()` and `_floor_ids.size()` equal `x_size * y_size * z_size`
    - Run 100+ iterations
    - **Validates: Requirements 1.1, 1.4**

  - [ ]* 6.9 Write property test: dirty level tracking
    - **Property 8: Dirty level tracking**
    - After modifying a tile at z-level Z, assert Z is in `_dirty_levels`; levels not modified are not dirty
    - Run 100+ iterations
    - **Validates: Requirements 8.2**

  - [ ]* 6.10 Write property test: z-level access returns correct tile data
    - **Property 9: Z-level data consistency**
    - Set random blocks/floors on a small grid, call `get_z_level(z)`, assert returned data matches individual `get_block()`/`get_floor()` calls for every (x, y) in that level
    - Run 100+ iterations
    - **Validates: Requirements 10.1**

  - [ ]* 6.11 Write property test: TypeRegistry lookup consistency
    - **Property 10: Registry lookup returns correct definitions**
    - For each type_id returned by `get_block_type_ids()`, assert `get_block_type(type_id)` is non-null and has matching `type_id` field; same for floor types
    - **Validates: Requirements 6.3, 6.4, 6.5**

  - [ ]* 6.12 Write property test: unknown type_id returns null from registry
    - **Property 11: Unknown type returns null**
    - Generate random strings not in the registered type IDs, assert `get_block_type()` and `get_floor_type()` return null
    - Run 100+ iterations
    - **Validates: Requirements 6.5**

- [x] 7. Checkpoint - Verify all grid and registry tests
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Implement VoxelMeshGenerator
  - [x] 8.1 Create `hiveminders/scripts/world/voxel_mesh_generator.gd` (VoxelMeshGenerator)
    - `class_name VoxelMeshGenerator extends RefCounted`
    - `const FLOOR_HEIGHT_RATIO: float = 0.125`
    - Implement `_should_render_face(grid, x, y, z, dir) -> bool`: return true if neighbor in direction is air or out-of-bounds (boundary faces always rendered)
    - Implement `generate_z_level_mesh(grid, z) -> ArrayMesh`:
      - Iterate all (x, y) in the z-level
      - For non-air blocks: use `SurfaceTool` to emit cube faces, cull faces adjacent to other non-air blocks
      - For non-empty floors where block above is air (or at top z-level): emit thin slab geometry of height `FLOOR_HEIGHT_RATIO`
      - Cull shared faces between floor slabs and adjacent blocks of matching material
      - Group faces by material into separate `SurfaceTool` surfaces within one `ArrayMesh`
      - Return null if level is entirely air with no visible floors
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [ ]* 8.2 Write property test: face culling correctness
    - **Property 12: Hidden faces are never rendered**
    - Generate small grids with random block placements, for each interior face between two non-air blocks assert `_should_render_face()` returns false
    - Run 100+ iterations
    - **Validates: Requirements 7.2**

  - [ ]* 8.3 Write property test: floor visibility
    - **Property 13: Floors visible only when block above is air**
    - Generate small grids with random block/floor placements, assert floor geometry is only produced for tiles where floor is non-empty AND block above is air (or top z-level)
    - Run 100+ iterations
    - **Validates: Requirements 7.3**

- [x] 9. Integrate into main scene
  - [x] 9.1 Wire TileGrid and mesh regeneration into `hiveminders/scripts/main_scene.gd`
    - Create a `TileGrid` instance in `_ready()` and add as child node
    - After grid initialization, generate meshes for each z-level using `VoxelMeshGenerator.generate_z_level_mesh()` and add resulting `MeshInstance3D` nodes as children of the TileGrid
    - Implement dirty-level mesh regeneration: in `_process()` (or via signal), check `_dirty_levels`, regenerate affected z-level meshes, clear dirty flags
    - _Requirements: 8.1, 8.2_

- [x] 10. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- All new scripts go in `hiveminders/scripts/world/`
- CSV data files go in `hiveminders/data/`
- Tests go in `hiveminders/tests/test_tile_grid.gd`
- TypeRegistry is registered as an autoload in project.godot
- Use small grid dimensions (4×4×2) in tests for fast execution
- Property tests follow the existing pattern in `hiveminders/tests/helpers/input_generators.gd`
