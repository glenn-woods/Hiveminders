# Requirements Document

## Introduction

Hiveminders uses a tile-based grid system as the foundation for its isometric dungeon world. The grid is a configurable 3D structure of x_size × y_size × z_size tiles (defaulting to 128×128×8), where each z-level represents a full 2D layer. Grid dimensions are definable at the scene level via constructor arguments or exported properties. Vertically, the world is a "lasagna" of alternating block and floor layers. Floors are thin slabs (approximately 1/8th block height in the z-axis), not flat planes. Each tile holds a block type, a floor type, and a list of modular components for extensibility. Block and floor types are data-driven and loaded from configuration, allowing new materials to be added without code changes. The system provides an API for querying and modifying tiles, enforces structural invariants (e.g. blocks require floors beneath them), and generates voxel meshes for 3D isometric rendering. Internally, all coordinates use 0-based indexing; the display layer may present 1-based level labels to the player (e.g. "Level 1" maps to z=0).

## Glossary

- **TileGrid**: The top-level data structure that stores all tile data for the world grid (dimensions configurable via x_size, y_size, z_size) and provides the public API for tile access and modification.
- **Tile**: A single cell in the grid at integer coordinates (x, y, z), containing a block type, a floor type, and a component list.
- **Block_Type**: A data-driven definition describing a solid material that can fill a tile cell (e.g. stone, dirt, empty). Each block type has a name and material properties.
- **Floor_Type**: A data-driven definition describing the surface beneath a block (e.g. stone, dirt, empty/none). Each floor type has a name and material properties. Floors are rendered as thin slabs (approximately 1/8th block height in the z-axis), not flat planes.
- **Component**: A modular data attachment on a tile used for extensibility (e.g. resource nodes, devices, light sources). Components are stored as a list on each tile.
- **Empty_Block**: A special block type representing an empty/hollow cell. When a tile has an empty block, the floor beneath it is visible during rendering.
- **Empty_Floor**: A special floor type representing no surface. Removing a floor reveals the block on the z-level below.
- **Type_Registry**: A system that loads and stores block type and floor type definitions from CSV files, making them available by identifier at runtime.
- **Voxel_Mesh_Generator**: The system responsible for producing 3D mesh geometry from tile data for isometric rendering. Blocks render as cubes and floors render as thin slabs (approximately 1/8th block height).
- **Z_Level**: A single horizontal layer of the grid at a given z-coordinate, containing a full x_size × y_size 2D grid of tiles.
- **Display_Level**: A 1-based label shown to the player in the UI. "Level 1" maps to z=0, "Level 2" maps to z=1, etc. All internal APIs use 0-based z-coordinates.

## Requirements

### Requirement 1: Grid Initialization

**User Story:** As a developer, I want to create a TileGrid with configurable dimensions, so that the world size can be tuned at the scene level without code changes.

#### Acceptance Criteria

1. WHEN the TileGrid is created with x_size, y_size, and z_size parameters, THE TileGrid SHALL allocate storage for x_size × y_size × z_size tiles addressed by integer coordinates (x, y, z).
2. WHEN the TileGrid is created without explicit dimension parameters, THE TileGrid SHALL use default values of x_size=128, y_size=128, z_size=8.
3. WHEN the TileGrid is created, THE TileGrid SHALL initialize every tile with the air block type, the empty floor type, and an empty component list.
4. THE TileGrid SHALL expose x_size, y_size, and z_size as readable properties.
5. THE TileGrid SHALL accept x_size, y_size, and z_size as constructor arguments or exported properties configurable at the scene level.

### Requirement 2: Tile Coordinate Validation

**User Story:** As a developer, I want the grid to validate coordinates against its configured dimensions, so that out-of-bounds access is handled predictably.

#### Acceptance Criteria

1. WHEN a tile operation is requested with coordinates where x is in [0, x_size - 1], y is in [0, y_size - 1], and z is in [0, z_size - 1], THE TileGrid SHALL perform the operation on the addressed tile.
2. IF a tile operation is requested with coordinates outside the valid range, THEN THE TileGrid SHALL return a failure indicator without modifying grid state.
3. THE TileGrid SHALL provide a method to check whether a given (x, y, z) coordinate is within bounds, returning true or false.

### Requirement 3: Block Type Management

**User Story:** As a developer, I want to get and set block types on tiles, so that the world terrain can be shaped by game systems.

#### Acceptance Criteria

1. THE TileGrid SHALL provide a method to retrieve the block type of a tile at a given (x, y, z) coordinate.
2. WHEN a block type is set on a tile, THE TileGrid SHALL store the new block type on the tile at the specified (x, y, z) coordinate.
3. WHEN a non-air block type is set on a tile that has an empty floor, THE TileGrid SHALL automatically set the floor type to match the block type being placed.
4. WHEN a block type is set to air on a tile, THE TileGrid SHALL retain the existing floor type on that tile.

### Requirement 4: Floor Type Management

**User Story:** As a developer, I want to get and set floor types on tiles, so that walkable surfaces can be created and removed independently of blocks.

#### Acceptance Criteria

1. THE TileGrid SHALL provide a method to retrieve the floor type of a tile at a given (x, y, z) coordinate.
2. WHEN a floor type is set on a tile, THE TileGrid SHALL store the new floor type on the tile at the specified (x, y, z) coordinate.
3. WHEN a floor is set to empty on a tile that has a non-air block, THE TileGrid SHALL set the block type to air before setting the floor to empty.

### Requirement 5: Component System

**User Story:** As a developer, I want to attach, remove, and query components on tiles, so that game entities like resource nodes and devices can be associated with specific locations.

#### Acceptance Criteria

1. THE TileGrid SHALL provide a method to add a component to the component list of a tile at a given (x, y, z) coordinate.
2. THE TileGrid SHALL provide a method to remove a specific component from the component list of a tile at a given (x, y, z) coordinate.
3. THE TileGrid SHALL provide a method to retrieve all components attached to a tile at a given (x, y, z) coordinate, returning an empty list when no components are attached.
4. WHEN a component is added to a tile that already contains the same component instance, THE TileGrid SHALL not add a duplicate entry.

### Requirement 6: Data-Driven Block and Floor Type Definitions

**User Story:** As a developer, I want block and floor types to be defined in configuration data, so that new material types can be added without modifying source code.

#### Acceptance Criteria

1. THE Type_Registry SHALL load block type definitions from a CSV file, where each definition includes an identifier, a display name, and material properties.
2. THE Type_Registry SHALL load floor type definitions from a CSV file, where each definition includes an identifier, a display name, and material properties.
3. THE Type_Registry SHALL provide a method to retrieve a block type definition by its identifier.
4. THE Type_Registry SHALL provide a method to retrieve a floor type definition by its identifier.
5. IF a block type or floor type identifier is requested that does not exist in the Type_Registry, THEN THE Type_Registry SHALL return a null value.
6. THE Type_Registry SHALL include built-in definitions for stone, dirt, and air block types, and stone, dirt, and empty floor types.

### Requirement 7: Voxel Mesh Generation

**User Story:** As a developer, I want the grid to produce 3D mesh geometry from tile data, so that the world can be rendered in the isometric view.

#### Acceptance Criteria

1. WHEN mesh generation is requested for a region of the grid, THE Voxel_Mesh_Generator SHALL produce cube geometry for each tile that has a non-air block type.
2. WHEN mesh generation is requested, THE Voxel_Mesh_Generator SHALL omit cube faces that are adjacent to another non-air block (hidden face culling).
3. WHEN mesh generation is requested, THE Voxel_Mesh_Generator SHALL produce thin slab geometry (approximately 1/8th block height in the z-axis) for each tile that has a non-empty floor type and an air block type above it.
4. WHEN a floor's material matches the block type directly above or below the floor, THE Voxel_Mesh_Generator SHALL cull the shared faces between the floor slab and the adjacent block so they blend seamlessly.
5. WHEN mesh generation is requested, THE Voxel_Mesh_Generator SHALL assign material properties from the block type and floor type definitions to the generated geometry.

### Requirement 8: Main Scene Integration

**User Story:** As a developer, I want the tile grid system to be instantiated and rendered in the existing main scene, so that the world is visible during gameplay.

#### Acceptance Criteria

1. WHEN the main scene is loaded, THE Main_Scene SHALL create a TileGrid instance and add the Voxel_Mesh_Generator output as a child node in the scene tree.
2. WHEN tile data in the TileGrid changes, THE Main_Scene SHALL have a mechanism to trigger mesh regeneration for the affected region.

### Requirement 9: Structural Invariant — Block Requires Floor

**User Story:** As a developer, I want the grid to enforce that solid blocks always have a floor beneath them, so that the world state remains structurally consistent.

#### Acceptance Criteria

1. FOR ALL tiles in the TileGrid, WHEN a tile has a non-air block type, THE TileGrid SHALL ensure that tile also has a non-empty floor type.
2. WHEN a non-air block is placed on a tile with an empty floor, THE TileGrid SHALL set the floor type to match the placed block type before completing the operation.

### Requirement 10: Z-Level Layer Access

**User Story:** As a developer, I want to access and iterate over individual z-levels, so that rendering and simulation systems can process one horizontal layer at a time.

#### Acceptance Criteria

1. THE TileGrid SHALL provide a method to retrieve all tile data for a given z-level as a 2D structure indexed by (x, y).
2. WHEN a z-level index outside the range [0, z_size - 1] is provided, THE TileGrid SHALL return a failure indicator.
