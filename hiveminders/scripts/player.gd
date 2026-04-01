extends CharacterBody3D

## Third-person player controller.
## Movement is relative to the camera's facing direction.
## Player always faces the camera's yaw (camera is the aim direction).

@export var move_speed: float = 5.0
@export var rotation_speed: float = 15.0
@export var gravity: float = 9.8
@export var jump_velocity: float = 6.57  # Reaches ~2.2 blocks high

## Set by the scene to the camera rig so we can read its yaw.
var camera_rig: Node3D = null

## Double jump state
var _has_double_jump: bool = false  # Set true when ability is active
var _jumps_remaining: int = 1


func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if InputMap.has_action("move_left"):
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		_jumps_remaining = 2 if _has_double_jump else 1

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
		var cam_yaw: float = atan2(
			-camera_rig.global_transform.basis.z.x,
			-camera_rig.global_transform.basis.z.z
		)
		var forward: Vector3 = Vector3(sin(cam_yaw), 0.0, cos(cam_yaw))
		var right: Vector3 = Vector3(cos(cam_yaw), 0.0, -sin(cam_yaw))
		var move_dir: Vector3 = (right * input_dir.x + forward * -input_dir.y).normalized()
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# Always face camera yaw
	if camera_rig != null:
		var cam_yaw: float = atan2(
			-camera_rig.global_transform.basis.z.x,
			-camera_rig.global_transform.basis.z.z
		)
		rotation.y = lerp_angle(rotation.y, cam_yaw, rotation_speed * delta)

	move_and_slide()
