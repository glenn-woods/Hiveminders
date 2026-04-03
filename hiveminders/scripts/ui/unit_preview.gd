class_name UnitPreview
extends Node3D

## Lightweight 3D preview node for the character select screen.
## No physics — visuals only. Slowly rotates for presentation.

@export var rotate_speed: float = 1.2

@onready var _body: MeshInstance3D = $Body


func _process(delta: float) -> void:
	rotation.y += rotate_speed * delta


## Apply a character class's visual properties to this preview.
func apply_class(cc: CharacterClass) -> void:
	if _body == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cc.body_color
	_body.set_surface_override_material(0, mat)
