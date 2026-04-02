class_name IsometricCamera
extends Camera3D

## Fixed-height isometric camera. Pannable with left stick/WASD,
## rotatable with right stick. Remembers its XZ position between
## mode swaps so the player returns to where they left off.

@export var height: float = 20.0
@export var pan_speed: float = 20.0
@export var rotate_speed: float = 2.5
@export var pitch_deg: float = -60.0  ## Fixed downward pitch in degrees

var _yaw: float = 0.0
var _center: Vector3 = Vector3.ZERO  ## XZ focus point on the ground
var _has_saved_position: bool = false


## Focus the camera on a world position (used on first activation).
func focus_on(world_pos: Vector3) -> void:
	_center = Vector3(world_pos.x, 0.0, world_pos.z)


func activate() -> void:
	current = true
	_apply_transform()


func deactivate() -> void:
	_has_saved_position = true
	current = false


func _process(delta: float) -> void:
	if not current:
		return

	# Pan — left stick / WASD (relative to camera yaw)
	var pan := Vector2.ZERO
	if InputMap.has_action("camera_pan_left"):
		pan = Input.get_vector("camera_pan_left", "camera_pan_right", "camera_pan_up", "camera_pan_down")
	if pan.length() > 0.1:
		var forward := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
		var right := Vector3(cos(_yaw), 0.0, -sin(_yaw))
		_center += (right * pan.x + forward * -pan.y) * pan_speed * delta

	# Rotate — right stick
	if InputMap.has_action("iso_rotate_left"):
		var rot := Input.get_vector("iso_rotate_left", "iso_rotate_right", "iso_rotate_up", "iso_rotate_down")
		if rot.length() > 0.1:
			_yaw -= rot.x * rotate_speed * delta

	_apply_transform()


func _apply_transform() -> void:
	var pitch_rad := deg_to_rad(pitch_deg)
	var dist := height / sin(-pitch_rad)  # Distance along the look ray
	var horiz := dist * cos(-pitch_rad)

	var offset := Vector3(
		horiz * sin(_yaw),
		height,
		horiz * cos(_yaw),
	)
	global_position = _center + offset
	look_at(_center, Vector3.UP)
