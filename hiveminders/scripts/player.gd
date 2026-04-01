extends CharacterBody3D

## Simple third-person player controller using the input system.
## Uses move_left/right/up/down actions from the third_person context.

@export var move_speed: float = 5.0
@export var rotation_speed: float = 10.0

func _physics_process(delta: float) -> void:
	# Read movement input
	var input_dir := Vector2.ZERO
	if InputMap.has_action("move_left"):
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Convert to 3D movement (XZ plane)
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)

	if direction.length() > 0.1:
		direction = direction.normalized()
		# Rotate to face movement direction
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)

	# Apply gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	move_and_slide()
