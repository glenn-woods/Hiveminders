## Unit tests for base-context merging in InputSystem._sync_input_map().
## Run this script as a standalone scene (extends Node).
##
## Requirements covered: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 4.2, 4.3, 5.1, 6.1
extends Node

# ---------------------------------------------------------------------------
# State saved before each test and restored after
# ---------------------------------------------------------------------------
var _saved_context_stack: Array[InputContextBindings] = []
var _saved_bindings_registry: Dictionary = {}
var _saved_registered_actions: Array[String] = []
var _saved_active_scheme: InputSystem.InputScheme

func _ready() -> void:
	test_single_context_registers_only_base_actions()
	test_two_contexts_no_overlap_registers_union()
	test_top_context_overrides_colliding_base_action()
	test_non_overridden_base_actions_retain_base_bindings()
	test_pop_back_to_base_restores_base_only_actions()
	test_scheme_switch_while_merged_updates_bindings()
	print("All base-context merging unit tests passed.")

# ---------------------------------------------------------------------------
# Save / Restore helpers — isolate each test from InputSystem global state
# ---------------------------------------------------------------------------

func _save_state() -> void:
	_saved_context_stack = InputSystem._context_stack.duplicate()
	_saved_bindings_registry = InputSystem._bindings_registry.duplicate()
	_saved_registered_actions = InputSystem._registered_actions.duplicate()
	_saved_active_scheme = InputSystem._active_scheme

func _restore_state() -> void:
	# Erase any actions the test registered
	for action_name in InputSystem._registered_actions:
		InputMap.erase_action(action_name)
	InputSystem._context_stack = _saved_context_stack
	InputSystem._bindings_registry = _saved_bindings_registry
	InputSystem._registered_actions = _saved_registered_actions
	InputSystem._active_scheme = _saved_active_scheme
	# Re-sync so InputMap matches restored state
	InputSystem._sync_input_map()

# ---------------------------------------------------------------------------
# Builder helpers
# ---------------------------------------------------------------------------

## Creates an InputContextBindings resource with the given context name,
## action definitions, and per-scheme bindings.
## action_defs: Array of [action_name: String, action_type: ActionDefinition.ActionType]
## kb_bindings: Array of [action_name: String, events: Array[InputEvent]]
## gp_bindings: Array of [action_name: String, events: Array[InputEvent]]
static func _build_context(
	ctx_name: String,
	action_defs: Array,
	kb_bindings: Array = [],
	gp_bindings: Array = []
) -> InputContextBindings:
	var ctx := InputContextBindings.new()
	ctx.context_name = ctx_name

	for def_pair in action_defs:
		var ad := ActionDefinition.new()
		ad.action_name = def_pair[0]
		ad.action_type = def_pair[1]
		ctx.actions.append(ad)

	for kb_pair in kb_bindings:
		var ab := ActionBinding.new()
		ab.action_name = kb_pair[0]
		ab.events = kb_pair[1]
		ctx.keyboard_mouse_bindings.append(ab)

	for gp_pair in gp_bindings:
		var ab := ActionBinding.new()
		ab.action_name = gp_pair[0]
		ab.events = gp_pair[1]
		ctx.gamepad_bindings.append(ab)

	return ctx

## Convenience: create a single InputEventKey for a given keycode.
static func _key_event(keycode: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	return ev

## Convenience: create a single InputEventJoypadButton for a given button index.
static func _joy_event(button: JoyButton) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	return ev

## Resets InputSystem to a clean slate and pushes contexts via the stack directly.
## This avoids going through push_context() which emits signals and requires registry.
func _setup_input_system(contexts: Array[InputContextBindings]) -> void:
	# Clear any previously registered actions
	for action_name in InputSystem._registered_actions:
		InputMap.erase_action(action_name)
	InputSystem._registered_actions.clear()
	InputSystem._context_stack.clear()
	InputSystem._bindings_registry.clear()

	for ctx in contexts:
		InputSystem._bindings_registry[ctx.context_name] = ctx
		InputSystem._context_stack.push_back(ctx)

# ---------------------------------------------------------------------------
# 3.2 — Single context registers only base actions
# Requirements: 1.2, 4.3
# ---------------------------------------------------------------------------

func test_single_context_registers_only_base_actions() -> void:
	_save_state()

	var base_ctx := _build_context(
		"base",
		[["pause", ActionDefinition.ActionType.BOOL], ["toggle_mode", ActionDefinition.ActionType.BOOL]],
		[["pause", [_key_event(KEY_ESCAPE)]], ["toggle_mode", [_key_event(KEY_TAB)]]]
	)
	_setup_input_system([base_ctx])
	InputSystem._active_scheme = InputSystem.InputScheme.KEYBOARD_MOUSE
	InputSystem._sync_input_map()

	# Exactly 2 actions registered
	assert(InputSystem._registered_actions.size() == 2,
		"Expected 2 registered actions, got %d" % InputSystem._registered_actions.size())
	assert("pause" in InputSystem._registered_actions,
		"Expected 'pause' to be registered")
	assert("toggle_mode" in InputSystem._registered_actions,
		"Expected 'toggle_mode' to be registered")

	# Verify InputMap has them
	assert(InputMap.has_action("pause"), "InputMap should have 'pause'")
	assert(InputMap.has_action("toggle_mode"), "InputMap should have 'toggle_mode'")

	# No duplicates
	var unique := {}
	for a in InputSystem._registered_actions:
		assert(not unique.has(a), "Duplicate action '%s' found" % a)
		unique[a] = true

	_restore_state()

# ---------------------------------------------------------------------------
# 3.3 — Two contexts, no overlap, registers union
# Requirements: 1.1, 5.1, 6.1
# ---------------------------------------------------------------------------

func test_two_contexts_no_overlap_registers_union() -> void:
	_save_state()

	var base_ctx := _build_context(
		"base",
		[["pause", ActionDefinition.ActionType.BOOL], ["toggle_mode", ActionDefinition.ActionType.BOOL]],
		[["pause", [_key_event(KEY_ESCAPE)]], ["toggle_mode", [_key_event(KEY_TAB)]]]
	)
	var top_ctx := _build_context(
		"isometric",
		[["select", ActionDefinition.ActionType.BOOL], ["camera_zoom_in", ActionDefinition.ActionType.BOOL]],
		[["select", [_key_event(KEY_SPACE)]], ["camera_zoom_in", [_key_event(KEY_EQUAL)]]]
	)
	_setup_input_system([base_ctx, top_ctx])
	InputSystem._active_scheme = InputSystem.InputScheme.KEYBOARD_MOUSE
	InputSystem._sync_input_map()

	# All 4 actions should be registered
	assert(InputSystem._registered_actions.size() == 4,
		"Expected 4 registered actions, got %d" % InputSystem._registered_actions.size())
	for action_name in ["pause", "toggle_mode", "select", "camera_zoom_in"]:
		assert(action_name in InputSystem._registered_actions,
			"Expected '%s' to be registered" % action_name)
		assert(InputMap.has_action(action_name),
			"InputMap should have '%s'" % action_name)

	_restore_state()


# ---------------------------------------------------------------------------
# 3.4 — Top context overrides colliding base action
# Requirements: 2.1, 2.2
# ---------------------------------------------------------------------------

func test_top_context_overrides_colliding_base_action() -> void:
	_save_state()

	# Base defines "pause" with KEY_ESCAPE
	var base_ctx := _build_context(
		"base",
		[["pause", ActionDefinition.ActionType.BOOL]],
		[["pause", [_key_event(KEY_ESCAPE)]]]
	)
	# Top redefines "pause" with KEY_P (different key, different binding)
	var top_ctx := _build_context(
		"gameplay",
		[["pause", ActionDefinition.ActionType.BOOL], ["jump", ActionDefinition.ActionType.BOOL]],
		[["pause", [_key_event(KEY_P)]], ["jump", [_key_event(KEY_SPACE)]]]
	)
	_setup_input_system([base_ctx, top_ctx])
	InputSystem._active_scheme = InputSystem.InputScheme.KEYBOARD_MOUSE
	InputSystem._sync_input_map()

	# "pause" should be registered
	assert(InputMap.has_action("pause"), "InputMap should have 'pause'")

	# The binding should be KEY_P (top), not KEY_ESCAPE (base)
	var events := InputMap.action_get_events("pause")
	assert(events.size() == 1,
		"Expected 1 event for 'pause', got %d" % events.size())
	var ev: InputEventKey = events[0] as InputEventKey
	assert(ev != null, "Expected InputEventKey for 'pause'")
	assert(ev.keycode == KEY_P,
		"Expected KEY_P for 'pause' (top override), got keycode %d" % ev.keycode)

	_restore_state()


# ---------------------------------------------------------------------------
# 3.5 — Non-overridden base actions retain base bindings
# Requirements: 1.3, 2.3
# ---------------------------------------------------------------------------

func test_non_overridden_base_actions_retain_base_bindings() -> void:
	_save_state()

	# Base defines "pause" and "toggle_mode"
	var base_ctx := _build_context(
		"base",
		[["pause", ActionDefinition.ActionType.BOOL], ["toggle_mode", ActionDefinition.ActionType.BOOL]],
		[["pause", [_key_event(KEY_ESCAPE)]], ["toggle_mode", [_key_event(KEY_TAB)]]]
	)
	# Top defines only "select" — does NOT define "pause" or "toggle_mode"
	var top_ctx := _build_context(
		"isometric",
		[["select", ActionDefinition.ActionType.BOOL]],
		[["select", [_key_event(KEY_SPACE)]]]
	)
	_setup_input_system([base_ctx, top_ctx])
	InputSystem._active_scheme = InputSystem.InputScheme.KEYBOARD_MOUSE
	InputSystem._sync_input_map()

	# "toggle_mode" should still have its base binding (KEY_TAB)
	assert(InputMap.has_action("toggle_mode"), "InputMap should have 'toggle_mode'")
	var events := InputMap.action_get_events("toggle_mode")
	assert(events.size() == 1,
		"Expected 1 event for 'toggle_mode', got %d" % events.size())
	var ev: InputEventKey = events[0] as InputEventKey
	assert(ev != null, "Expected InputEventKey for 'toggle_mode'")
	assert(ev.keycode == KEY_TAB,
		"Expected KEY_TAB for 'toggle_mode' (base retained), got keycode %d" % ev.keycode)

	# "pause" should also retain base binding (KEY_ESCAPE)
	assert(InputMap.has_action("pause"), "InputMap should have 'pause'")
	var pause_events := InputMap.action_get_events("pause")
	assert(pause_events.size() == 1,
		"Expected 1 event for 'pause', got %d" % pause_events.size())
	var pause_ev: InputEventKey = pause_events[0] as InputEventKey
	assert(pause_ev != null, "Expected InputEventKey for 'pause'")
	assert(pause_ev.keycode == KEY_ESCAPE,
		"Expected KEY_ESCAPE for 'pause' (base retained), got keycode %d" % pause_ev.keycode)

	_restore_state()

# ---------------------------------------------------------------------------
# 3.6 — Pop back to base restores base-only actions
# Requirements: 4.2, 4.3
# ---------------------------------------------------------------------------

func test_pop_back_to_base_restores_base_only_actions() -> void:
	_save_state()

	var base_ctx := _build_context(
		"base",
		[["pause", ActionDefinition.ActionType.BOOL], ["toggle_mode", ActionDefinition.ActionType.BOOL]],
		[["pause", [_key_event(KEY_ESCAPE)]], ["toggle_mode", [_key_event(KEY_TAB)]]]
	)
	var top_ctx := _build_context(
		"isometric",
		[["select", ActionDefinition.ActionType.BOOL]],
		[["select", [_key_event(KEY_SPACE)]]]
	)

	# Set up registry so pop_context() works (it doesn't use registry, but be safe)
	_setup_input_system([base_ctx, top_ctx])
	InputSystem._active_scheme = InputSystem.InputScheme.KEYBOARD_MOUSE
	InputSystem._sync_input_map()

	# Verify merged state first
	assert(InputMap.has_action("select"), "Before pop: 'select' should be registered")
	assert(InputMap.has_action("pause"), "Before pop: 'pause' should be registered")

	# Pop the top context
	InputSystem.pop_context()

	# After pop, only base actions should remain
	assert(InputSystem._registered_actions.size() == 2,
		"After pop: expected 2 registered actions, got %d" % InputSystem._registered_actions.size())
	assert(InputMap.has_action("pause"), "After pop: 'pause' should still be registered")
	assert(InputMap.has_action("toggle_mode"), "After pop: 'toggle_mode' should still be registered")
	assert(not InputMap.has_action("select"), "After pop: 'select' should NOT be registered")

	_restore_state()


# ---------------------------------------------------------------------------
# 3.7 — Scheme switch while merged updates bindings
# Requirements: 3.1, 3.2, 3.3
# ---------------------------------------------------------------------------

func test_scheme_switch_while_merged_updates_bindings() -> void:
	_save_state()

	# Base: "pause" — KB=Escape, GP=JoyButton6
	var base_ctx := _build_context(
		"base",
		[["pause", ActionDefinition.ActionType.BOOL]],
		[["pause", [_key_event(KEY_ESCAPE)]]],  # keyboard_mouse
		[["pause", [_joy_event(JOY_BUTTON_START)]]]  # gamepad
	)
	# Top: "select" — KB=Space, GP=JoyButton0
	var top_ctx := _build_context(
		"isometric",
		[["select", ActionDefinition.ActionType.BOOL]],
		[["select", [_key_event(KEY_SPACE)]]],  # keyboard_mouse
		[["select", [_joy_event(JOY_BUTTON_A)]]]  # gamepad
	)

	_setup_input_system([base_ctx, top_ctx])

	# Start with KEYBOARD_MOUSE
	InputSystem._active_scheme = InputSystem.InputScheme.KEYBOARD_MOUSE
	InputSystem._sync_input_map()

	# Verify keyboard bindings
	var pause_events_kb := InputMap.action_get_events("pause")
	assert(pause_events_kb.size() == 1, "KB: expected 1 event for 'pause'")
	assert((pause_events_kb[0] as InputEventKey).keycode == KEY_ESCAPE,
		"KB: 'pause' should be KEY_ESCAPE")

	var select_events_kb := InputMap.action_get_events("select")
	assert(select_events_kb.size() == 1, "KB: expected 1 event for 'select'")
	assert((select_events_kb[0] as InputEventKey).keycode == KEY_SPACE,
		"KB: 'select' should be KEY_SPACE")

	# Switch to GAMEPAD
	InputSystem._active_scheme = InputSystem.InputScheme.GAMEPAD
	InputSystem._sync_input_map()

	# Verify gamepad bindings
	var pause_events_gp := InputMap.action_get_events("pause")
	assert(pause_events_gp.size() == 1, "GP: expected 1 event for 'pause'")
	assert(pause_events_gp[0] is InputEventJoypadButton,
		"GP: 'pause' should be InputEventJoypadButton")
	assert((pause_events_gp[0] as InputEventJoypadButton).button_index == JOY_BUTTON_START,
		"GP: 'pause' should be JOY_BUTTON_START")

	var select_events_gp := InputMap.action_get_events("select")
	assert(select_events_gp.size() == 1, "GP: expected 1 event for 'select'")
	assert(select_events_gp[0] is InputEventJoypadButton,
		"GP: 'select' should be InputEventJoypadButton")
	assert((select_events_gp[0] as InputEventJoypadButton).button_index == JOY_BUTTON_A,
		"GP: 'select' should be JOY_BUTTON_A")

	_restore_state()
