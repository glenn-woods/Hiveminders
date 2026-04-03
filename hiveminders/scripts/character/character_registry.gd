extends Node

## Loads all CharacterClass resources and provides lookup.
## Also stores the player's current selection for scene transitions.

@export var characters_path: String = "res://data/characters/"

## The character class the player selected. Set by character select screen,
## read by the game scene when spawning units.
var selected_class: CharacterClass = null

## class_id -> CharacterClass
var _classes: Dictionary = {}

## Ordered list for UI iteration.
var _class_list: Array[CharacterClass] = []


func _ready() -> void:
	_load_characters()


func get_character_class(class_id: String) -> CharacterClass:
	return _classes.get(class_id, null)


func get_all_classes() -> Array[CharacterClass]:
	return _class_list


func _load_characters() -> void:
	var dir := DirAccess.open(characters_path)
	if dir == null:
		push_error("CharacterRegistry: could not open '%s'" % characters_path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := characters_path.path_join(file_name)
			var res := ResourceLoader.load(full_path)
			if res is CharacterClass:
				var cc: CharacterClass = res
				if cc.class_id.is_empty():
					push_warning("CharacterRegistry: '%s' has empty class_id — skipping." % full_path)
				elif _classes.has(cc.class_id):
					push_warning("CharacterRegistry: duplicate class_id '%s' — skipping." % cc.class_id)
				else:
					_classes[cc.class_id] = cc
					_class_list.append(cc)
		file_name = dir.get_next()
	dir.list_dir_end()
