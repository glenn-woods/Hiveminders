class_name Unit
extends CharacterBody3D

## A controllable unit (player or NPC). Movement only runs when
## is_player_controlled is true. AI will drive uncontrolled units later.

@export var move_speed: float = 5.0
@export var rotation_speed: float = 15.0
@export var gravity: float = 9.8
@export var jump_velocity: float = 6.57

## Visual color applied to the body mesh.
@export var body_color: Color = Color(0.2, 0.6, 0.9, 1.0)

## Whether this unit is currently owned by the player roster.
## Owned units can be cycled to. Unowned units are neutral/AI.
@export var is_owned: bool = true

## Runtime flag — set by UnitManager when this unit is the active one.
var is_player_controlled: bool = false

## Set by UnitManager so the unit can read camera yaw for movement.
var camera_rig: Node3D = null

var _jumps_remaining: int = 1
var _has_double_jump: bool = false

@onready var _body_mesh: MeshInstance3D = $Body
@onready var _arrow_mesh: MeshInstance3D = $Arrow
@onready var _halo: MeshInstance3D = $Halo


func _ready() -> void:
	_apply_body_color()
	set_halo_visible(false)


## Show or hide the golden selection halo above this unit's head.
func set_halo_visible(show: bool) -> void:
	if _halo != null:
		_halo.visible = show


func _apply_body_color() -> void:
	if _body_mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	_body_mesh.set_surface_override_material(0, mat)


func _physics_process(delta: float) -> void:
	# Gravity always applies
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		_jumps_remaining = 2 if _has_double_jump else 1

	if not is_player_controlled:
		# AI will go here later — for now just apply gravity and stop.
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# Player input
	var input_dir := Vector2.ZERO
	if InputMap.has_action("move_left"):
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Jump
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity
			_jumps_remaining -= 1
		elif _jumps_remaining > 0:
			velocity.y = jump_velocity
			_jumps_remaining -= 1

	# Camera-relative movement
	if input_dir.length() > 0.1 and camera_rig != null:
		var cam_basis := camera_rig.global_transform.basis
		var forward := -cam_basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right := cam_basis.x
		right.y = 0.0
		right = right.normalized()
		var move_dir: Vector3 = (right * input_dir.x + forward * -input_dir.y).normalized()
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# Face camera yaw
	if camera_rig != null:
		var cam_forward := -camera_rig.global_transform.basis.z
		cam_forward.y = 0.0
		cam_forward = cam_forward.normalized()
		var target_yaw := atan2(cam_forward.x, cam_forward.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)

	move_and_slide()
