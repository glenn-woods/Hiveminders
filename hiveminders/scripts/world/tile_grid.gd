class_name TileGrid
extends Node3D

@export var x_size: int = 128
@export var y_size: int = 128
@export var z_size: int = 8

var _block_ids: PackedStringArray
var _floor_ids: PackedStringArray
var _components: Dictionary = {}
var _dirty_levels: Dictionary = {}

## Rendering and collision — managed internally per z-level.
var _mesh_gen: VoxelMeshGenerator = null
var _z_level_meshes: Dictionary = {}   # int -> MeshInstance3D
var _z_level_bodies: Dictionary = {}   # int -> StaticBody3D


func _ready() -> void:
	initialize()


func initialize() -> void:
	var total := x_size * y_size * z_size
	_block_ids.resize(total)
	_block_ids.fill("air")
	_floor_ids.resize(total)
	_floor_ids.fill("empty")
	_components.clear()
	_dirty_levels.clear()


func _index(x: int, y: int, z: int) -> int:
	return x + y * x_size + z * x_size * y_size


func is_in_bounds(x: int, y: int, z: int) -> bool:
	return x >= 0 and x < x_size and y >= 0 and y < y_size and z >= 0 and z < z_size


func _mark_dirty(z: int) -> void:
	_dirty_levels[z] = true


# --- Block / Floor ---

func get_block(x: int, y: int, z: int) -> String:
	if not is_in_bounds(x, y, z):
		return ""
	return _block_ids[_index(x, y, z)]


func set_block(x: int, y: int, z: int, type_id: String) -> bool:
	if not is_in_bounds(x, y, z):
		return false
	_block_ids[_index(x, y, z)] = type_id
	if type_id != "air" and get_floor(x, y, z) == "empty":
		_floor_ids[_index(x, y, z)] = type_id
	_mark_dirty(z)
	return true


func get_floor(x: int, y: int, z: int) -> String:
	if not is_in_bounds(x, y, z):
		return ""
	return _floor_ids[_index(x, y, z)]


func set_floor(x: int, y: int, z: int, type_id: String) -> bool:
	if not is_in_bounds(x, y, z):
		return false
	if type_id == "empty" and get_block(x, y, z) != "air":
		_block_ids[_index(x, y, z)] = "air"
	_floor_ids[_index(x, y, z)] = type_id
	_mark_dirty(z)
	return true


# --- Components ---

func add_component(x: int, y: int, z: int, component: TileComponent) -> bool:
	if not is_in_bounds(x, y, z):
		return false
	var idx := _index(x, y, z)
	if not _components.has(idx):
		_components[idx] = []
	var list: Array = _components[idx]
	if not list.has(component):
		list.append(component)
	return true


func remove_component(x: int, y: int, z: int, component: TileComponent) -> bool:
	if not is_in_bounds(x, y, z):
		return false
	var idx := _index(x, y, z)
	if not _components.has(idx):
		return false
	var list: Array = _components[idx]
	var pos := list.find(component)
	if pos == -1:
		return false
	list.remove_at(pos)
	if list.is_empty():
		_components.erase(idx)
	return true


func get_components(x: int, y: int, z: int) -> Array:
	if not is_in_bounds(x, y, z):
		return []
	return _components.get(_index(x, y, z), [])


# --- Z-level access ---

func get_z_level(z: int):
	if z < 0 or z >= z_size:
		return null
	var result := {}
	for x in range(x_size):
		result[x] = {}
		for y in range(y_size):
			result[x][y] = {
				"block": get_block(x, y, z),
				"floor": get_floor(x, y, z),
				"components": get_components(x, y, z)
			}
	return result


# ---------------------------------------------------------------------------
# Rendering and collision
# ---------------------------------------------------------------------------

## Call once after initialize() to set up the mesh generator.
## registry should be the TypeRegistry autoload node.
func setup_rendering(registry: Node) -> void:
	_mesh_gen = VoxelMeshGenerator.new(self, registry)


## Generates meshes and collision for all z-levels. Call after populating tiles.
func build_all_meshes() -> void:
	if _mesh_gen == null:
		push_warning("TileGrid: setup_rendering() must be called before build_all_meshes().")
		return
	for z in range(z_size):
		_rebuild_z_level(z)
	_dirty_levels.clear()


## Call each frame (or when needed) to rebuild any dirty z-levels.
func rebuild_dirty_levels() -> void:
	if _mesh_gen == null or _dirty_levels.is_empty():
		return
	for z: int in _dirty_levels.keys():
		_rebuild_z_level(z)
	_dirty_levels.clear()


## Rebuilds the mesh and collision for a single z-level.
func _rebuild_z_level(z: int) -> void:
	# Free existing nodes
	if _z_level_meshes.has(z):
		_z_level_meshes[z].queue_free()
		_z_level_meshes.erase(z)
	if _z_level_bodies.has(z):
		_z_level_bodies[z].queue_free()
		_z_level_bodies.erase(z)

	var mesh: ArrayMesh = _mesh_gen.generate_z_level_mesh(z)
	if mesh == null:
		return

	# Visual mesh
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)
	_z_level_meshes[z] = mi

	# Collision from mesh faces
	var faces: PackedVector3Array = mesh.get_faces()
	if faces.size() > 0:
		var body := StaticBody3D.new()
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		var col := CollisionShape3D.new()
		col.shape = shape
		body.add_child(col)
		add_child(body)
		_z_level_bodies[z] = body
