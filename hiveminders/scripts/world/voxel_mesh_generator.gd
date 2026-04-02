class_name VoxelMeshGenerator
extends RefCounted

## Height of a floor slab relative to a full block (1.0).
const FLOOR_HEIGHT_RATIO: float = 0.125

## Range of random brightness variation applied per block (±value).
const SHADE_VARIATION: float = 0.10

## The six cardinal directions in grid space.
const FACE_DIRS: Array[Vector3i] = [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1),
]

var _grid: TileGrid
var _registry: Node  # TypeRegistry autoload


func _init(grid: TileGrid, registry: Node) -> void:
	_grid = grid
	_registry = registry


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Generates an ArrayMesh for a single z-level.
## Returns null if z is out of bounds or no geometry was produced.
func generate_z_level_mesh(z: int) -> ArrayMesh:
	if z < 0 or z >= _grid.z_size:
		return null

	# material -> {st: SurfaceTool, count: int}
	var surfaces: Dictionary = {}

	for x in range(_grid.x_size):
		for y in range(_grid.y_size):
			_emit_block_geometry(x, y, z, surfaces)
			_emit_floor_geometry(x, y, z, surfaces)

	if surfaces.is_empty():
		return null

	var mesh: ArrayMesh = ArrayMesh.new()
	for mat: StandardMaterial3D in surfaces:
		var entry: Dictionary = surfaces[mat]
		var st: SurfaceTool = entry["st"]
		st.set_material(mat)
		st.commit(mesh)
	return mesh


# ---------------------------------------------------------------------------
# Block geometry
# ---------------------------------------------------------------------------

func _emit_block_geometry(x: int, y: int, z: int, surfaces: Dictionary) -> void:
	var block_id: String = _grid.get_block(x, y, z)
	var block_def: BlockTypeDef = _registry.get_block_type(block_id)
	if block_def == null or block_def.is_air:
		return
	var mat: StandardMaterial3D = block_def.material
	if mat == null:
		return

	var entry: Dictionary = _get_or_create_surface(surfaces, mat)
	var st: SurfaceTool = entry["st"]

	var v: float = 1.0 + randf_range(-SHADE_VARIATION, SHADE_VARIATION)
	var tint := Color(v, v, v, 1.0)

	for dir: Vector3i in FACE_DIRS:
		if _should_render_face(x, y, z, dir):
			var verts: Array = _cube_face_verts(float(x), float(y), float(z), dir)
			var normal: Vector3 = _dir_to_normal(dir)
			_add_quad(st, verts, normal, entry, tint)


# ---------------------------------------------------------------------------
# Floor slab geometry
# ---------------------------------------------------------------------------

func _emit_floor_geometry(x: int, y: int, z: int, surfaces: Dictionary) -> void:
	var floor_id: String = _grid.get_floor(x, y, z)
	var floor_def: FloorTypeDef = _registry.get_floor_type(floor_id)
	if floor_def == null or floor_def.is_empty:
		return

	# Skip if this tile has a solid block (block covers the floor)
	var block_id: String = _grid.get_block(x, y, z)
	var block_def: BlockTypeDef = _registry.get_block_type(block_id)
	if block_def != null and not block_def.is_air:
		return

	# Skip if block above is solid (floor hidden by ceiling)
	if z + 1 < _grid.z_size:
		var above_id: String = _grid.get_block(x, y, z + 1)
		var above_def: BlockTypeDef = _registry.get_block_type(above_id)
		if above_def != null and not above_def.is_air:
			return

	var mat: StandardMaterial3D = floor_def.material
	if mat == null:
		return

	var entry: Dictionary = _get_or_create_surface(surfaces, mat)
	var st: SurfaceTool = entry["st"]

	# World origin: grid (x,y,z) -> world Vector3(x, z, y)
	var wx: float = float(x)
	var wy: float = float(z)
	var wz: float = float(y)
	var h: float = FLOOR_HEIGHT_RATIO

	var fv: float = 1.0 + randf_range(-SHADE_VARIATION, SHADE_VARIATION)
	var tint := Color(fv, fv, fv, 1.0)

	# Top face (always visible for exposed floor)
	_add_quad(st, [
		Vector3(wx,       wy + h, wz      ),
		Vector3(wx + 1.0, wy + h, wz      ),
		Vector3(wx + 1.0, wy + h, wz + 1.0),
		Vector3(wx,       wy + h, wz + 1.0),
	], Vector3(0, 1, 0), entry, tint)

	# Bottom face
	_add_quad(st, [
		Vector3(wx,       wy, wz + 1.0),
		Vector3(wx + 1.0, wy, wz + 1.0),
		Vector3(wx + 1.0, wy, wz      ),
		Vector3(wx,       wy, wz      ),
	], Vector3(0, -1, 0), entry, tint)

	# Side faces — cull if neighbor has same floor material
	var side_checks: Array = [
		[Vector3i(1, 0, 0),  Vector3(1, 0, 0)],
		[Vector3i(-1, 0, 0), Vector3(-1, 0, 0)],
		[Vector3i(0, 1, 0),  Vector3(0, 0, 1)],
		[Vector3i(0, -1, 0), Vector3(0, 0, -1)],
	]
	for check: Array in side_checks:
		var grid_dir: Vector3i = check[0]
		var world_normal: Vector3 = check[1]
		var nx: int = x + grid_dir.x
		var ny: int = y + grid_dir.y
		if _grid.is_in_bounds(nx, ny, z) and _grid.get_floor(nx, ny, z) == floor_id:
			continue  # Same floor material — cull shared face
		_add_quad(st, _floor_side_verts(wx, wy, wz, h, grid_dir), world_normal, entry, tint)


# ---------------------------------------------------------------------------
# Face culling
# ---------------------------------------------------------------------------

func _should_render_face(x: int, y: int, z: int, dir: Vector3i) -> bool:
	var nx: int = x + dir.x
	var ny: int = y + dir.y
	var nz: int = z + dir.z
	if not _grid.is_in_bounds(nx, ny, nz):
		return true  # Boundary face — always render
	var neighbor_id: String = _grid.get_block(nx, ny, nz)
	var neighbor_def: BlockTypeDef = _registry.get_block_type(neighbor_id)
	if neighbor_def == null:
		return true
	return neighbor_def.is_air


# ---------------------------------------------------------------------------
# Geometry helpers
# ---------------------------------------------------------------------------

func _get_or_create_surface(surfaces: Dictionary, mat: StandardMaterial3D) -> Dictionary:
	if not surfaces.has(mat):
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		surfaces[mat] = {"st": st, "count": 0}
	return surfaces[mat]


func _add_quad(st: SurfaceTool, verts: Array, normal: Vector3, entry: Dictionary, tint: Color = Color.WHITE) -> void:
	var offset: int = entry["count"]
	for v: Vector3 in verts:
		st.set_normal(normal)
		st.set_color(tint)
		st.add_vertex(v)
	st.add_index(offset + 0)
	st.add_index(offset + 1)
	st.add_index(offset + 2)
	st.add_index(offset + 0)
	st.add_index(offset + 2)
	st.add_index(offset + 3)
	entry["count"] = offset + 4


## Grid (x,y,z) -> world Vector3(x, z, y). z-up in grid = y-up in Godot.
## FACE_DIRS are in grid space. Winding: counter-clockwise viewed from outside.
func _cube_face_verts(gx: float, gy: float, gz: float, dir: Vector3i) -> Array:
	var x0: float = gx
	var x1: float = gx + 1.0
	var y0: float = gz        # world Y = grid Z
	var y1: float = gz + 1.0
	var z0: float = gy        # world Z = grid Y
	var z1: float = gy + 1.0

	match dir:
		Vector3i(1, 0, 0):   # grid +X = world +X
			return [Vector3(x1,y0,z1), Vector3(x1,y1,z1), Vector3(x1,y1,z0), Vector3(x1,y0,z0)]
		Vector3i(-1, 0, 0):  # grid -X = world -X
			return [Vector3(x0,y0,z0), Vector3(x0,y1,z0), Vector3(x0,y1,z1), Vector3(x0,y0,z1)]
		Vector3i(0, 1, 0):   # grid +Y = world +Z
			return [Vector3(x0,y0,z1), Vector3(x0,y1,z1), Vector3(x1,y1,z1), Vector3(x1,y0,z1)]
		Vector3i(0, -1, 0):  # grid -Y = world -Z
			return [Vector3(x1,y0,z0), Vector3(x1,y1,z0), Vector3(x0,y1,z0), Vector3(x0,y0,z0)]
		Vector3i(0, 0, 1):   # grid +Z = world +Y (top)
			return [Vector3(x0,y1,z0), Vector3(x1,y1,z0), Vector3(x1,y1,z1), Vector3(x0,y1,z1)]
		Vector3i(0, 0, -1):  # grid -Z = world -Y (bottom)
			return [Vector3(x0,y0,z1), Vector3(x1,y0,z1), Vector3(x1,y0,z0), Vector3(x0,y0,z0)]
	return []


func _dir_to_normal(dir: Vector3i) -> Vector3:
	match dir:
		Vector3i(1, 0, 0):  return Vector3(1, 0, 0)   # grid +X = world +X
		Vector3i(-1, 0, 0): return Vector3(-1, 0, 0)  # grid -X = world -X
		Vector3i(0, 1, 0):  return Vector3(0, 0, 1)   # grid +Y = world +Z
		Vector3i(0, -1, 0): return Vector3(0, 0, -1)  # grid -Y = world -Z
		Vector3i(0, 0, 1):  return Vector3(0, 1, 0)   # grid +Z = world +Y (up)
		Vector3i(0, 0, -1): return Vector3(0, -1, 0)  # grid -Z = world -Y (down)
	return Vector3.ZERO


func _floor_side_verts(wx: float, wy: float, wz: float, h: float, dir: Vector3i) -> Array:
	match dir:
		Vector3i(1, 0, 0):
			return [Vector3(wx+1,wy,wz), Vector3(wx+1,wy,wz+1), Vector3(wx+1,wy+h,wz+1), Vector3(wx+1,wy+h,wz)]
		Vector3i(-1, 0, 0):
			return [Vector3(wx,wy,wz+1), Vector3(wx,wy,wz), Vector3(wx,wy+h,wz), Vector3(wx,wy+h,wz+1)]
		Vector3i(0, 1, 0):
			return [Vector3(wx+1,wy+h,wz+1), Vector3(wx+1,wy,wz+1), Vector3(wx,wy,wz+1), Vector3(wx,wy+h,wz+1)]
		Vector3i(0, -1, 0):
			return [Vector3(wx,wy+h,wz), Vector3(wx,wy,wz), Vector3(wx+1,wy,wz), Vector3(wx+1,wy+h,wz)]
	return []
