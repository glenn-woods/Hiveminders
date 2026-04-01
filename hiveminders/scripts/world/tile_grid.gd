class_name TileGrid
extends Node3D

@export var x_size: int = 128
@export var y_size: int = 128
@export var z_size: int = 8

var _block_ids: PackedStringArray
var _floor_ids: PackedStringArray
var _components: Dictionary = {}
var _dirty_levels: Dictionary = {}


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
