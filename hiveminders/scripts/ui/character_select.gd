extends Control

## Multiplayer character selection screen.
## Each input device that presses "select" joins as a player slot.
## Players navigate independently and lock in their character.

const HOLD_DURATION: float = 1.0

@onready var _grid: HBoxContainer = $Layout/Grid
@onready var _desc_label: Label = $Layout/Description
@onready var _preview_row: HBoxContainer = $Layout/PreviewRow
@onready var _back_indicator: Label = $BackIndicator
@onready var _start_indicator: Label = $StartIndicator

var _classes: Array[CharacterClass] = []
var _box_nodes: Array[PanelContainer] = []
var _box_base_styles: Array[StyleBoxFlat] = []

## Preview panels — one per joined player slot. slot_index -> PlayerPreviewPanel
var _preview_panels: Dictionary = {}

## Track which character indices are locked (selected by a ready player).
var _locked_indices: Dictionary = {}  # int -> PlayerSlot

## Hold-to-back state (unready player holds cancel).
var _back_holder_device: int = -99  # -99 = nobody
var _back_hold_time: float = 0.0

## Hold-to-start state (ready player holds accept).
var _start_holder_device: int = -99
var _start_hold_time: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	InputSystem.push_context("ui")
	PlayerManager.clear()
	_back_indicator.visible = false
	_start_indicator.visible = false
	_build_boxes()


func _exit_tree() -> void:
	InputSystem.pop_context()


func _build_boxes() -> void:
	_classes = CharacterRegistry.get_all_classes()
	for cc: CharacterClass in _classes:
		var container := PanelContainer.new()
		container.custom_minimum_size = Vector2(120, 140)

		var style := StyleBoxFlat.new()
		style.bg_color = cc.body_color
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.content_margin_left = 8.0
		style.content_margin_right = 8.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		container.add_theme_stylebox_override("panel", style)

		var label := Label.new()
		label.text = cc.display_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		container.add_child(label)

		_grid.add_child(container)
		_box_nodes.append(container)
		_box_base_styles.append(style)


func _input(event: InputEvent) -> void:
	var device := _get_device_id(event)
	if device == -99:
		return  # Unrecognized event type

	# --- Accept / Join ---
	if _is_accept_pressed(event):
		var slot := PlayerManager.get_slot_by_device(device)
		if slot == null:
			# New player joining
			slot = PlayerManager.join(device)
			if slot != null:
				slot.focus_index = _find_first_available(-1)
				_create_preview_panel(slot)
				_refresh_visuals()
		elif not slot.is_ready:
			# Lock in selection
			slot.selected_class = _classes[slot.focus_index]
			slot.is_ready = true
			slot.accept_released_since_ready = false  # Must release before hold-to-start
			_locked_indices[slot.focus_index] = slot
			_refresh_visuals()
		# Hold-to-start: ready player holding accept
		# (handled in _process via _start_holder_device)
		get_viewport().set_input_as_handled()
		return

	# --- Cancel / Back ---
	if _is_cancel_pressed(event):
		var slot := PlayerManager.get_slot_by_device(device)
		if slot == null:
			return
		if slot.is_ready:
			# Un-ready: unlock character
			_locked_indices.erase(slot.focus_index)
			slot.is_ready = false
			slot.selected_class = null
			slot.cancel_released_since_unready = false  # Must release before hold-to-back
			_refresh_visuals()
		# Hold-to-back for unready players handled in _process
		get_viewport().set_input_as_handled()
		return

	# --- Navigation (unready players only) ---
	var slot := PlayerManager.get_slot_by_device(device)
	if slot == null or slot.is_ready:
		return

	var dir := 0
	if _is_nav_left(event):
		dir = -1
	elif _is_nav_right(event):
		dir = 1
	if dir != 0:
		var new_idx := _find_next_available(slot.focus_index, dir, slot)
		if new_idx != -1:
			slot.focus_index = new_idx
			_refresh_visuals()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	# --- Hold-to-back (unready player holds cancel) ---
	# Track release so the un-ready press can't immediately trigger hold-to-back
	for slot in PlayerManager.get_slots():
		if not slot.is_ready and not slot.cancel_released_since_unready:
			if not _is_cancel_held(slot.device_id):
				slot.cancel_released_since_unready = true

	if _back_holder_device != -99:
		var s := PlayerManager.get_slot_by_device(_back_holder_device)
		if s != null and not s.is_ready and s.cancel_released_since_unready and _is_cancel_held(_back_holder_device):
			_back_hold_time += delta
		else:
			_back_holder_device = -99
			_back_hold_time = 0.0
	if _back_holder_device == -99:
		for slot in PlayerManager.get_slots():
			if not slot.is_ready and slot.cancel_released_since_unready and _is_cancel_held(slot.device_id):
				_back_holder_device = slot.device_id
				_back_hold_time = 0.0
				break
	_back_indicator.visible = _back_holder_device != -99
	if _back_holder_device != -99:
		_back_indicator.text = "Returning to menu... %.0f%%" % ((_back_hold_time / HOLD_DURATION) * 100.0)
		if _back_hold_time >= HOLD_DURATION:
			PlayerManager.clear()
			get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
			return

	# --- Hold-to-start (ready player holds accept) ---
	# First, track release so the confirm press can't immediately trigger hold-to-start
	for slot in PlayerManager.get_slots():
		if slot.is_ready and not slot.accept_released_since_ready:
			if not _is_accept_held(slot.device_id):
				slot.accept_released_since_ready = true

	if _start_holder_device != -99:
		var s := PlayerManager.get_slot_by_device(_start_holder_device)
		if s != null and s.is_ready and s.accept_released_since_ready and _is_accept_held(_start_holder_device):
			_start_hold_time += delta
		else:
			_start_holder_device = -99
			_start_hold_time = 0.0
	if _start_holder_device == -99:
		for slot in PlayerManager.get_slots():
			if slot.is_ready and slot.accept_released_since_ready and _is_accept_held(slot.device_id):
				_start_holder_device = slot.device_id
				_start_hold_time = 0.0
				break
	_start_indicator.visible = _start_holder_device != -99
	if _start_holder_device != -99:
		_start_indicator.text = "Starting game... %.0f%%" % ((_start_hold_time / HOLD_DURATION) * 100.0)
		if _start_hold_time >= HOLD_DURATION:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
			return


func _create_preview_panel(slot: PlayerSlot) -> void:
	var panel := PlayerPreviewPanel.new()
	panel.setup(slot.slot_index, PlayerManager.get_slot_color(slot.slot_index))
	_preview_row.add_child(panel)
	_preview_panels[slot.slot_index] = panel
	# Show the currently focused class
	if slot.focus_index >= 0 and slot.focus_index < _classes.size():
		panel.show_class(_classes[slot.focus_index])


func _refresh_visuals() -> void:
	# Reset all boxes
	for i in range(_box_nodes.size()):
		var container := _box_nodes[i]
		var base_style: StyleBoxFlat = _box_base_styles[i].duplicate()
		base_style.border_width_left = 0
		base_style.border_width_right = 0
		base_style.border_width_top = 0
		base_style.border_width_bottom = 0

		if _locked_indices.has(i):
			# Grayed out — selected by a ready player
			base_style.bg_color = base_style.bg_color.darkened(0.5)

		container.add_theme_stylebox_override("panel", base_style)

	# Draw focus rings for unready players
	for slot in PlayerManager.get_slots():
		if slot.is_ready:
			continue
		if slot.focus_index < 0 or slot.focus_index >= _box_nodes.size():
			continue
		var container := _box_nodes[slot.focus_index]
		var style: StyleBoxFlat = container.get_theme_stylebox("panel").duplicate()
		var ring_color := PlayerManager.get_slot_color(slot.slot_index)
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = ring_color
		container.add_theme_stylebox_override("panel", style)

	# Update description for the most recently focused slot
	var slots := PlayerManager.get_slots()
	if not slots.is_empty():
		var last_slot: PlayerSlot = slots.back()
		if last_slot.focus_index >= 0 and last_slot.focus_index < _classes.size():
			_desc_label.text = _classes[last_slot.focus_index].description

	# Sync preview panels — only update a panel if its slot's focus changed
	for slot in PlayerManager.get_slots():
		if not _preview_panels.has(slot.slot_index):
			continue
		var panel: PlayerPreviewPanel = _preview_panels[slot.slot_index]
		panel.sync_slot(slot, _classes)

	if slots.is_empty():
		_desc_label.text = "Press A / Enter to join"


## Find the first available (unlocked, not focused by another) character index.
func _find_first_available(exclude_slot_index: int) -> int:
	for i in range(_classes.size()):
		if _is_index_available(i, exclude_slot_index):
			return i
	return 0  # Fallback


## Find the next available index in a direction, wrapping.
func _find_next_available(from: int, dir: int, slot: PlayerSlot) -> int:
	var count := _classes.size()
	for step in range(1, count):
		var idx := (from + dir * step + count) % count
		if _is_index_available(idx, slot.slot_index):
			return idx
	return -1  # Nothing available


func _is_index_available(idx: int, exclude_slot_index: int) -> bool:
	if _locked_indices.has(idx):
		return false
	for slot in PlayerManager.get_slots():
		if slot.slot_index != exclude_slot_index and not slot.is_ready and slot.focus_index == idx:
			return false
	return true


# ---------------------------------------------------------------------------
# Input helpers — raw event inspection, bypassing InputMap for per-device routing
# ---------------------------------------------------------------------------

func _get_device_id(event: InputEvent) -> int:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device
	if event is InputEventKey or event is InputEventMouseButton:
		return -1  # Keyboard/mouse
	return -99  # Unknown


func _is_accept_pressed(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return event.pressed and event.button_index == JOY_BUTTON_A
	if event is InputEventKey:
		return event.pressed and not event.echo and event.keycode == KEY_ENTER
	return false


func _is_cancel_pressed(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return event.pressed and event.button_index == JOY_BUTTON_B
	if event is InputEventKey:
		return event.pressed and not event.echo and event.keycode == KEY_ESCAPE
	return false


func _is_nav_left(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_left")


func _is_nav_right(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_right")


func _is_accept_held(device_id: int) -> bool:
	if device_id == -1:
		return Input.is_key_pressed(KEY_ENTER)
	return Input.is_joy_button_pressed(device_id, JOY_BUTTON_A)


func _is_cancel_held(device_id: int) -> bool:
	if device_id == -1:
		return Input.is_key_pressed(KEY_ESCAPE)
	return Input.is_joy_button_pressed(device_id, JOY_BUTTON_B)
