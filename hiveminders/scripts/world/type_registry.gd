class_name TypeRegistry
extends Node

@export var block_types_path: String = "res://data/block_types.csv"
@export var floor_types_path: String = "res://data/floor_types.csv"

## ID -> BlockTypeDef
var _block_types: Dictionary = {}
## ID -> FloorTypeDef
var _floor_types: Dictionary = {}


func _ready() -> void:
	_parse_block_types()
	_parse_floor_types()


func _parse_block_types() -> void:
	const EXPECTED_HEADER := "type_id,display_name,is_air,color"
	var file := FileAccess.open(block_types_path, FileAccess.READ)
	if file == null:
		push_error("TypeRegistry: could not open '%s'" % block_types_path)
		return

	var lines := file.get_as_text().split("\n")
	file.close()

	var data_lines: Array[String] = []
	for line in lines:
		if line.strip_edges() != "":
			data_lines.append(line)

	if data_lines.is_empty():
		push_error("TypeRegistry: '%s' line 1: expected header '%s' but got ''" % [block_types_path, EXPECTED_HEADER])
		return

	var header := data_lines[0].strip_edges()
	if header != EXPECTED_HEADER:
		push_error("TypeRegistry: '%s' line 1: expected header '%s' but got '%s'" % [block_types_path, EXPECTED_HEADER, header])
		return

	for i in range(1, data_lines.size()):
		var line_num := i + 1
		var row := data_lines[i].split(",")
		if row.size() != 4:
			push_error("TypeRegistry: '%s' line %d: expected 4 columns but got %d" % [block_types_path, line_num, row.size()])
			continue

		var type_id := row[0].strip_edges()
		var display_name := row[1].strip_edges()
		var is_air_str := row[2].strip_edges()
		var color_str := row[3].strip_edges()

		if type_id == "":
			push_error("TypeRegistry: '%s' line %d: type_id cannot be empty" % [block_types_path, line_num])
			continue

		if _block_types.has(type_id):
			push_error("TypeRegistry: '%s' line %d: duplicate type_id '%s'" % [block_types_path, line_num, type_id])
			continue

		if is_air_str != "true" and is_air_str != "false":
			push_error("TypeRegistry: '%s' line %d: invalid boolean '%s' for column 'is_air', expected 'true' or 'false'" % [block_types_path, line_num, is_air_str])
			continue

		var mat: StandardMaterial3D = null
		if color_str != "":
			if not color_str.begins_with("#") or (color_str.length() != 7 and color_str.length() != 9):
				push_error("TypeRegistry: '%s' line %d: invalid color '%s', expected hex format (e.g. #808080)" % [block_types_path, line_num, color_str])
				continue
			mat = StandardMaterial3D.new()
			mat.albedo_color = Color(color_str)

		var def := BlockTypeDef.new()
		def.type_id = type_id
		def.display_name = display_name
		def.is_air = is_air_str == "true"
		def.material = mat
		_block_types[type_id] = def


func _parse_floor_types() -> void:
	const EXPECTED_HEADER := "type_id,display_name,is_empty,color"
	var file := FileAccess.open(floor_types_path, FileAccess.READ)
	if file == null:
		push_error("TypeRegistry: could not open '%s'" % floor_types_path)
		return

	var lines := file.get_as_text().split("\n")
	file.close()

	var data_lines: Array[String] = []
	for line in lines:
		if line.strip_edges() != "":
			data_lines.append(line)

	if data_lines.is_empty():
		push_error("TypeRegistry: '%s' line 1: expected header '%s' but got ''" % [floor_types_path, EXPECTED_HEADER])
		return

	var header := data_lines[0].strip_edges()
	if header != EXPECTED_HEADER:
		push_error("TypeRegistry: '%s' line 1: expected header '%s' but got '%s'" % [floor_types_path, EXPECTED_HEADER, header])
		return

	for i in range(1, data_lines.size()):
		var line_num := i + 1
		var row := data_lines[i].split(",")
		if row.size() != 4:
			push_error("TypeRegistry: '%s' line %d: expected 4 columns but got %d" % [floor_types_path, line_num, row.size()])
			continue

		var type_id := row[0].strip_edges()
		var display_name := row[1].strip_edges()
		var is_empty_str := row[2].strip_edges()
		var color_str := row[3].strip_edges()

		if type_id == "":
			push_error("TypeRegistry: '%s' line %d: type_id cannot be empty" % [floor_types_path, line_num])
			continue

		if _floor_types.has(type_id):
			push_error("TypeRegistry: '%s' line %d: duplicate type_id '%s'" % [floor_types_path, line_num, type_id])
			continue

		if is_empty_str != "true" and is_empty_str != "false":
			push_error("TypeRegistry: '%s' line %d: invalid boolean '%s' for column 'is_empty', expected 'true' or 'false'" % [floor_types_path, line_num, is_empty_str])
			continue

		var mat: StandardMaterial3D = null
		if color_str != "":
			if not color_str.begins_with("#") or (color_str.length() != 7 and color_str.length() != 9):
				push_error("TypeRegistry: '%s' line %d: invalid color '%s', expected hex format (e.g. #808080)" % [floor_types_path, line_num, color_str])
				continue
			mat = StandardMaterial3D.new()
			mat.albedo_color = Color(color_str)

		var def := FloorTypeDef.new()
		def.type_id = type_id
		def.display_name = display_name
		def.is_empty = is_empty_str == "true"
		def.material = mat
		_floor_types[type_id] = def


func get_block_type(type_id: String) -> BlockTypeDef:
	return _block_types.get(type_id, null)


func get_floor_type(type_id: String) -> FloorTypeDef:
	return _floor_types.get(type_id, null)


func get_block_type_ids() -> Array[String]:
	return Array(_block_types.keys(), TYPE_STRING, "", null)


func get_floor_type_ids() -> Array[String]:
	return Array(_floor_types.keys(), TYPE_STRING, "", null)
