extends Camera3D

## Third-person camera rig. Add as a child of the scene root (not the player).
## Follows a target node and orbits around it via mouse / right stick.

@export var target_path: NodePath
@export var distance: float = 6.0
@export var min_pitch: float = -80.0
@export var max_pitch: float = 60.0
@export var mouse_sensitivity: float = 0.002
@export var stick_sensitivity: float = 2.5
@export var follow_speed: float = 12.0

var _yaw: float = 0.0
var _pitch: float = -25.0  # Slightly looking down
var _target: Node3D = null


func _ready() -> void:
	_target = get_node_or_null(target_path)
	# Capture mouse for FPS-style look
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))


func _process(delta: float) -> void:
	if _target == null:
		return

	# Right stick look (from input actions)
	if InputMap.has_action("look_left"):
		var stick_input: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if stick_input.length() > 0.1:
			_yaw -= stick_input.x * stick_sensitivity * delta
			_pitch -= stick_input.y * stick_sensitivity * delta
			_pitch = clampf(_pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

	# Smoothly follow target position
	var target_pos: Vector3 = _target.global_position + Vector3(0, 1.2, 0)

	# Calculate camera position on a sphere around the target
	var offset: Vector3 = Vector3.ZERO
	offset.x = distance * cos(_pitch) * sin(_yaw)
	offset.y = distance * -sin(_pitch)
	offset.z = distance * cos(_pitch) * cos(_yaw)

	global_position = global_position.lerp(target_pos + offset, follow_speed * delta)
	look_at(target_pos, Vector3.UP)
