class_name VoxelMeshGenerator
extends RefCounted

const FLOOR_HEIGHT_RATIO: float = 0.125  # 1/8th of a block

# Cardinal face directions in grid space (x, y, z where z is vertical)
const FACE_DIRS := [
	Vector3i(1, 0, 0),
	Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0),
	Vector3i(0, -1, 0),
	Vector3i(0, 0, 1),
	Vector3i(0, 0, -1),
]


## Returns true if the face at (x,y,z) in direction dir should be rendered.
## A face is rendered when the neighbor is air or out of bounds.
static func _should_render_face(grid: TileGrid, x: int, y: int, z: int, dir: Vector3i) -> bool:
	var nx := x + dir.x
	var ny := y + dir.y
	var nz := z + dir.z
	if not grid.is_in_bounds(nx, ny, nz):
		return true
	var neighbor_block := grid.get_block(nx, ny, nz)
	var block_def := TypeRegistry.get_block_type(neighbor_block)
	if block_def == null:
		return true
	return block_def.is_air


## Adds a quad (two triangles) to the SurfaceTool with absolute index offset tracking.
static func _add_quad_indexed(st: SurfaceTool, verts: Array, normal: Vector3, index_offset: int) -> void:
	for v in verts:
		st.set_normal(normal)
		st.add_vertex(v)
	st.add_index(index_offset + 0)
	st.add_index(index_offset + 1)
	st.add_index(index_offset + 2)
	st.add_index(index_offset + 0)
	st.add_index(index_offset + 2)
	st.add_index(index_offset + 3)


## Returns the 4 vertices for a cube face given the block origin and direction.
## Grid coords: x=right, y=forward, z=up. World coords: x=x, y=z(grid), z=y(grid).
## So world = Vector3(gx, gz, gy).
static func _cube_face_verts(gx: float, gy: float, gz: float, dir: Vector3i) -> Array:
	# World origin of this block
	var ox := gx
	var oy := gz       # world Y = grid Z
	var oz := gy       # world Z = grid Y

	match dir:
		Vector3i(1, 0, 0):   # +X face (world +X)
			return [
				Vector3(ox + 1, oy,     oz    ),
				Vector3(ox + 1, oy,     oz + 1),
				Vector3(ox + 1, oy + 1, oz + 1),
				Vector3(ox + 1, oy + 1, oz    ),
			]
		Vector3i(-1, 0, 0):  # -X face (world -X)
			return [
				Vector3(ox,     oy,     oz + 1),
				Vector3(ox,     oy,     oz    ),
				Vector3(ox,     oy + 1, oz    ),
				Vector3(ox,     oy + 1, oz + 1),
			]
		Vector3i(0, 1, 0):   # +Y face (world +Z)
			return [
				Vector3(ox,     oy,     oz + 1),
				Vector3(ox + 1, oy,     oz + 1),
				Vector3(ox + 1, oy + 1, oz + 1),
				Vector3(ox,     oy + 1, oz + 1),
			]
		Vector3i(0, -1, 0):  # -Y face (world -Z)
			return [
				Vector3(ox + 1, oy,     oz    ),
				Vector3(ox,     oy,     oz    ),
				Vector3(ox,     oy + 1, oz    ),
				Vector3(ox + 1, oy + 1, oz    ),
			]
		Vector3i(0, 0, 1):   # +Z face (world +Y, top)
			return [
				Vector3(ox,     oy + 1, oz    ),
				Vector3(ox + 1, oy + 1, oz    ),
				Vector3(ox + 1, oy + 1, oz + 1),
				Vector3(ox,     oy + 1, oz + 1),
			]
		Vector3i(0, 0, -1):  # -Z face (world -Y, bottom)
			return [
				Vector3(ox,     oy,     oz + 1),
				Vector3(ox + 1, oy,     oz + 1),
				Vector3(ox + 1, oy,     oz    ),
				Vector3(ox,     oy,     oz    ),
			]
	return []


## Returns the world-space normal for a grid-space direction.
static func _dir_to_normal(dir: Vector3i) -> Vector3:
	match dir:
		Vector3i(1, 0, 0):  return Vector3(1, 0, 0)
		Vector3i(-1, 0, 0): return Vector3(-1, 0, 0)
		Vector3i(0, 1, 0):  return Vector3(0, 0, 1)
		Vector3i(0, -1, 0): return Vector3(0, 0, -1)
		Vector3i(0, 0, 1):  return Vector3(0, 1, 0)
		Vector3i(0, 0, -1): return Vector3(0, -1, 0)
	return Vector3.ZERO


## Generates an ArrayMesh for a single z-level of the grid.
## Returns null if z is out of bounds or no geometry was generated.
static func generate_z_level_mesh(grid: TileGrid, z: int) -> ArrayMesh:
	if z < 0 or z >= grid.z_size:
		return null

	# material -> SurfaceTool
	var surfaces: Dictionary = {}
	# material -> current vertex index offset
	var vertex_counts: Dictionary = {}

	for x in range(grid.x_size):
		for y in range(grid.y_size):
			var block_id := grid.get_block(x, y, z)
			var block_def: BlockTypeDef = TypeRegistry.get_block_type(block_id)

			# --- Cube geometry for non-air blocks ---
			if block_def != null and not block_def.is_air:
				var mat := block_def.material
				if mat != null:
					if not surfaces.has(mat):
						var st := SurfaceTool.new()
						st.begin(Mesh.PRIMITIVE_TRIANGLES)
						surfaces[mat] = st
						vertex_counts[mat] = 0

					var st: SurfaceTool = surfaces[mat]
					for dir in FACE_DIRS:
						if _should_render_face(grid, x, y, z, dir):
							var verts := _cube_face_verts(float(x), float(y), float(z), dir)
							var normal := _dir_to_normal(dir)
							var offset: int = vertex_counts[mat]
							_add_quad_indexed(st, verts, normal, offset)
							vertex_counts[mat] = offset + 4

			# --- Floor slab geometry ---
			var floor_id := grid.get_floor(x, y, z)
			var floor_def: FloorTypeDef = TypeRegistry.get_floor_type(floor_id)

			if floor_def != null and not floor_def.is_empty:
				# Only render floor when block above is air (or at top z-level)
				var block_above_is_air := true
				if z + 1 < grid.z_size:
					var above_id := grid.get_block(x, y, z + 1)
					var above_def: BlockTypeDef = TypeRegistry.get_block_type(above_id)
					if above_def != null and not above_def.is_air:
						block_above_is_air = false

				# Also skip if this tile has a non-air block (block covers the floor)
				var this_block_is_air := (block_def == null or block_def.is_air)

				if block_above_is_air and this_block_is_air:
					var mat := floor_def.material
					if mat != null:
						if not surfaces.has(mat):
							var st := SurfaceTool.new()
							st.begin(Mesh.PRIMITIVE_TRIANGLES)
							surfaces[mat] = st
							vertex_counts[mat] = 0

						var st: SurfaceTool = surfaces[mat]
						_add_floor_slab(grid, st, vertex_counts, mat, x, y, z, floor_id)

	if surfaces.is_empty():
		return null

	var mesh := ArrayMesh.new()
	for mat in surfaces:
		var st: SurfaceTool = surfaces[mat]
		st.set_material(mat)
		st.commit(mesh)

	return mesh


## Adds floor slab geometry for tile (x, y, z).
## The slab sits at the bottom of the cell with height FLOOR_HEIGHT_RATIO.
static func _add_floor_slab(
	grid: TileGrid,
	st: SurfaceTool,
	vertex_counts: Dictionary,
	mat: StandardMaterial3D,
	x: int, y: int, z: int,
	floor_id: String
) -> void:
	# World origin: Vector3(x, z, y) — grid z maps to world Y
	var wx := float(x)
	var wy := float(z)          # world Y = grid Z (bottom of cell)
	var wz := float(y)          # world Z = grid Y
	var h := FLOOR_HEIGHT_RATIO

	# Top face (always rendered for visible floor)
	var top_normal := Vector3(0, 1, 0)
	var top_verts := [
		Vector3(wx,       wy + h, wz      ),
		Vector3(wx + 1.0, wy + h, wz      ),
		Vector3(wx + 1.0, wy + h, wz + 1.0),
		Vector3(wx,       wy + h, wz + 1.0),
	]
	var offset: int = vertex_counts[mat]
	_add_quad_indexed(st, top_verts, top_normal, offset)
	vertex_counts[mat] = offset + 4

	# Side faces: +X, -X, +Z, -Z in world space (= +x, -x, +y, -y in grid space)
	# Cull a side if the neighbor has the same floor material (adjacent slab)
	var side_dirs := [
		Vector3i(1, 0, 0),   # world +X = grid +x
		Vector3i(-1, 0, 0),  # world -X = grid -x
		Vector3i(0, 1, 0),   # world +Z = grid +y
		Vector3i(0, -1, 0),  # world -Z = grid -y
	]

	for dir in side_dirs:
		var nx := x + dir.x
		var ny := y + dir.y
		# Check if neighbor has same floor material — if so, cull this side
		var render_side := true
		if grid.is_in_bounds(nx, ny, z):
			var neighbor_floor_id := grid.get_floor(nx, ny, z)
			if neighbor_floor_id == floor_id:
				render_side = false

		if render_side:
			var side_verts := _floor_slab_side_verts(wx, wy, wz, h, dir)
			var side_normal := _dir_to_normal(dir)
			offset = vertex_counts[mat]
			_add_quad_indexed(st, side_verts, side_normal, offset)
			vertex_counts[mat] = offset + 4


## Returns the 4 vertices for a floor slab side face.
## wx, wy, wz: world-space origin of the tile. h: slab height.
## dir: grid-space direction (only x and y components used for horizontal sides).
static func _floor_slab_side_verts(wx: float, wy: float, wz: float, h: float, dir: Vector3i) -> Array:
	match dir:
		Vector3i(1, 0, 0):   # world +X side
			return [
				Vector3(wx + 1.0, wy,     wz      ),
				Vector3(wx + 1.0, wy,     wz + 1.0),
				Vector3(wx + 1.0, wy + h, wz + 1.0),
				Vector3(wx + 1.0, wy + h, wz      ),
			]
		Vector3i(-1, 0, 0):  # world -X side
			return [
				Vector3(wx,       wy,     wz + 1.0),
				Vector3(wx,       wy,     wz      ),
				Vector3(wx,       wy + h, wz      ),
				Vector3(wx,       wy + h, wz + 1.0),
			]
		Vector3i(0, 1, 0):   # world +Z side (grid +Y)
			return [
				Vector3(wx,       wy,     wz + 1.0),
				Vector3(wx + 1.0, wy,     wz + 1.0),
				Vector3(wx + 1.0, wy + h, wz + 1.0),
				Vector3(wx,       wy + h, wz + 1.0),
			]
		Vector3i(0, -1, 0):  # world -Z side (grid -Y)
			return [
				Vector3(wx + 1.0, wy,     wz      ),
				Vector3(wx,       wy,     wz      ),
				Vector3(wx,       wy + h, wz      ),
				Vector3(wx + 1.0, wy + h, wz      ),
			]
	return []
