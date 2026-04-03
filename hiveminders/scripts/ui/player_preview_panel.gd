class_name PlayerPreviewPanel
extends PanelContainer

## One player's preview window on the character select screen.
## Contains a SubViewport rendering the focused character's preview scene.

var _viewport: SubViewport = null
var _preview_root: Node3D = null
var _current_preview: Node3D = null
var _ready_overlay: Label = null
var _last_focus_index: int = -1


func setup(slot_index: int, slot_color: Color) -> void:
	custom_minimum_size = Vector2(180, 260)

	# Panel border in player color
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 1.0)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = slot_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	# Player label
	var player_label := Label.new()
	player_label.text = "P%d" % (slot_index + 1)
	player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_label.add_theme_color_override("font_color", slot_color)
	vbox.add_child(player_label)

	# SubViewportContainer + SubViewport
	var svc := SubViewportContainer.new()
	svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	svc.stretch = true
	vbox.add_child(svc)

	_viewport = SubViewport.new()
	_viewport.size = Vector2i(180, 200)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.own_world_3d = true  # Isolated 3D world — nothing bleeds between viewports
	svc.add_child(_viewport)

	# Scene root inside viewport
	_preview_root = Node3D.new()
	_viewport.add_child(_preview_root)

	# Camera — positioned to frame a ~2-unit tall capsule
	var cam := Camera3D.new()
	cam.transform = Transform3D(
		Basis(Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1)),
		Vector3(0, 1.0, 4.0)
	)
	cam.look_at_from_position(Vector3(0, 1.0, 4.0), Vector3(0, 1.0, 0), Vector3.UP)
	_viewport.add_child(cam)

	# Directional light
	var light := DirectionalLight3D.new()
	light.transform = Transform3D(Basis.from_euler(Vector3(-0.8, 0.5, 0)), Vector3.ZERO)
	_viewport.add_child(light)

	# Ready overlay label
	_ready_overlay = Label.new()
	_ready_overlay.text = "READY"
	_ready_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ready_overlay.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
	_ready_overlay.visible = false
	vbox.add_child(_ready_overlay)


## Swap the preview to show the given character class's scene.
func show_class(cc: CharacterClass) -> void:
	if _current_preview != null:
		_current_preview.queue_free()
		_current_preview = null

	if cc == null or cc.preview_scene == null:
		return

	_current_preview = cc.preview_scene.instantiate()
	_preview_root.add_child(_current_preview)

	# Apply class visuals if it's a UnitPreview
	if _current_preview.has_method("apply_class"):
		_current_preview.apply_class(cc)


func set_ready(is_ready: bool) -> void:
	if _ready_overlay != null:
		_ready_overlay.visible = is_ready


## Called each refresh — only updates the preview if this slot's focus changed.
func sync_slot(slot: PlayerSlot, classes: Array[CharacterClass]) -> void:
	if slot.focus_index != _last_focus_index:
		_last_focus_index = slot.focus_index
		var cc: CharacterClass = classes[slot.focus_index] if slot.focus_index >= 0 and slot.focus_index < classes.size() else null
		show_class(cc)
	set_ready(slot.is_ready)
