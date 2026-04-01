extends Node

## Emitted when the player switches between gamepad and keyboard/mouse.
signal active_scheme_changed(scheme: InputScheme)

## Emitted when the active input context changes (push or pop).
signal context_changed(context_name: String)

## The two supported device families.
enum InputScheme { GAMEPAD, KEYBOARD_MOUSE }

## Action value types — canonical source; ActionDefinition mirrors these values.
enum ActionType { BOOL, AXIS, VECTOR2 }

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

## Directory containing InputContextBindings .tres resource files.
@export var contexts_path: String = "res://input/contexts/"

## Name of the context to push onto the stack at startup.
@export var initial_context: String = "base"

## Path to the CSV bindings file. When non-empty, CSV loading is used
## instead of scanning the .tres directory.
@export var csv_bindings_path: String = "res://input/input_bindings.csv"

## When true, prints every raw input event as its CSV token to the output.
@export var debug_input: bool = true

## When true, prints whenever a registered action is pressed.
@export var debug_actions: bool = true

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## The device family currently driving input.
var _active_scheme: InputScheme = InputScheme.KEYBOARD_MOUSE

## Stack of active contexts; only the topmost context's bindings are in InputMap.
var _context_stack: Array[InputContextBindings] = []

## Lookup table: context_name -> InputContextBindings (populated in _ready).
var _bindings_registry: Dictionary = {}

## Action names the system has registered in InputMap (used for cleanup in _sync_input_map).
var _registered_actions: Array[String] = []

# ---------------------------------------------------------------------------
# Public getters
# ---------------------------------------------------------------------------

## Returns the current input scheme (GAMEPAD or KEYBOARD_MOUSE).
func get_active_scheme() -> InputScheme:
	return _active_scheme

## Returns the context_name of the topmost context, or "" if the stack is empty.
func get_active_context_name() -> String:
	if _context_stack.is_empty():
		return ""
	return _context_stack.back().context_name

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Pushes a named context onto the stack, syncs InputMap, and emits context_changed.
## No-op with a warning if the context name is not found in the registry.
func push_context(context_name: String) -> void:
	if not _bindings_registry.has(context_name):
		push_warning("InputSystem: unknown context '%s' — push ignored." % context_name)
		return
	_context_stack.push_back(_bindings_registry[context_name])
	_sync_input_map()
	context_changed.emit(context_name)

## Pops the topmost context from the stack, syncs InputMap, and emits context_changed.
## No-op with a warning if only one context remains (base context is never removed).
func pop_context() -> void:
	if _context_stack.size() <= 1:
		push_warning("InputSystem: cannot pop the last context — pop ignored.")
		return
	_context_stack.pop_back()
	_sync_input_map()
	context_changed.emit(_context_stack.back().context_name)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Minimum axis magnitude to treat a joypad motion event as intentional input.
const JOYPAD_MOTION_DEADZONE: float = 0.2

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

## Loads all InputContextBindings resources from the contexts directory,
## populates the bindings registry, pushes the initial context, and syncs InputMap.
func _ready() -> void:
	if not csv_bindings_path.is_empty():
		var file := FileAccess.open(csv_bindings_path, FileAccess.READ)
		if file == null:
			push_error(
				"InputSystem: could not open CSV bindings file '%s' — falling back to directory loading." % csv_bindings_path
			)
			_load_bindings_from_directory(contexts_path)
		else:
			var csv_text := file.get_as_text()
			file.close()
			var parse_result := CsvBindingsParser.parse(csv_text, csv_bindings_path)
			for error in parse_result.errors:
				push_error("InputSystem (CSV): %s" % error)
			for binding: InputContextBindings in parse_result.bindings:
				_bindings_registry[binding.context_name] = binding
	else:
		_load_bindings_from_directory(contexts_path)

	if _bindings_registry.is_empty():
		push_warning("InputSystem: no binding resources found in '%s'." % contexts_path)
		return

	if not _bindings_registry.has(initial_context):
		push_error(
			"InputSystem: initial context '%s' not found in registry. Available: %s"
			% [initial_context, str(_bindings_registry.keys())]
		)
		return

	_context_stack.push_back(_bindings_registry[initial_context])
	_sync_input_map()
	context_changed.emit(initial_context)


## Scans a directory for .tres files, loads each as InputContextBindings,
## and adds valid ones to _bindings_registry keyed by context_name.
func _load_bindings_from_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("InputSystem: could not open contexts directory '%s'." % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := path.path_join(file_name)
			var resource := ResourceLoader.load(full_path)
			if resource is InputContextBindings:
				var bindings: InputContextBindings = resource
				if bindings.context_name.is_empty():
					push_warning("InputSystem: resource '%s' has empty context_name — skipping." % full_path)
				elif _bindings_registry.has(bindings.context_name):
					push_warning("InputSystem: duplicate context_name '%s' in '%s' — skipping." % [bindings.context_name, full_path])
				else:
					_bindings_registry[bindings.context_name] = bindings
			else:
				push_warning("InputSystem: '%s' is not an InputContextBindings resource — skipping." % full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


## Detects whether the incoming event implies a scheme switch and, if so,
## updates _active_scheme, re-syncs InputMap, and emits the signal.
func _input(event: InputEvent) -> void:
	var detected_scheme: InputScheme

	if event is InputEventJoypadButton:
		if debug_input and event.pressed:
			print("[input] %s" % EventTokenParser.event_to_token(event))
		detected_scheme = InputScheme.GAMEPAD
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) < JOYPAD_MOTION_DEADZONE:
			return  # Below deadzone — ignore as noise.
		if debug_input:
			print("[input] %s" % EventTokenParser.event_to_token(event))
		detected_scheme = InputScheme.GAMEPAD
	elif event is InputEventKey:
		if debug_input and event.pressed:
			print("[input] %s" % EventTokenParser.event_to_token(event))
		detected_scheme = InputScheme.KEYBOARD_MOUSE
	elif event is InputEventMouseButton:
		if debug_input and event.pressed:
			print("[input] %s" % EventTokenParser.event_to_token(event))
		detected_scheme = InputScheme.KEYBOARD_MOUSE
	else:
		return  # Unrecognised or ignored event type (e.g. InputEventMouseMotion).

	if detected_scheme != _active_scheme:
		_active_scheme = detected_scheme
		_sync_input_map()
		active_scheme_changed.emit(_active_scheme)


## Logs registered actions that were just pressed this frame.
func _process(_delta: float) -> void:
	if not debug_actions:
		return
	var ctx: String = get_active_context_name()
	for action_name: String in _registered_actions:
		if Input.is_action_just_pressed(action_name):
			print("[action] %s  (context: %s)" % [action_name, ctx])

## Clears all system-registered actions from InputMap, then rebuilds from the
## merged base + top context action definitions and the active scheme's bindings.
## When the stack has more than one context, base (index 0) actions are registered
## first, then top context actions are layered on top — top wins on name collision.
func _sync_input_map() -> void:
	# 1. Erase all actions previously registered by this system.
	for action_name in _registered_actions:
		InputMap.erase_action(action_name)
	_registered_actions.clear()

	# 2. If the stack is empty there is nothing to register.
	if _context_stack.is_empty():
		return

	# 3. Identify base and top contexts.
	var base_context: InputContextBindings = _context_stack[0]
	var top_context: InputContextBindings = _context_stack.back()

	# 4. If base == top (stack size 1), register only that context — no merge needed.
	if base_context == top_context:
		for action_def: ActionDefinition in base_context.actions:
			InputMap.add_action(action_def.action_name)
			_registered_actions.append(action_def.action_name)

		var bindings: Array[ActionBinding]
		if _active_scheme == InputScheme.GAMEPAD:
			bindings = base_context.gamepad_bindings
		else:
			bindings = base_context.keyboard_mouse_bindings

		for binding: ActionBinding in bindings:
			if binding.action_name not in _registered_actions:
				push_warning(
					"InputSystem: binding references unknown action '%s' in context '%s' — skipping."
					% [binding.action_name, base_context.context_name]
				)
				continue
			for event: InputEvent in binding.events:
				InputMap.action_add_event(binding.action_name, event)
		return

	# 5. Build merged_actions: base first, then top overlays (top wins on collision).
	var merged_actions: Dictionary = {}  # String → ActionDefinition
	for action_def: ActionDefinition in base_context.actions:
		merged_actions[action_def.action_name] = action_def
	for action_def: ActionDefinition in top_context.actions:
		merged_actions[action_def.action_name] = action_def

	# 6. Register every merged action in InputMap.
	for action_name: String in merged_actions:
		InputMap.add_action(action_name)
		_registered_actions.append(action_name)

	# 7. Build merged_bindings for the active scheme: base first, then top overlays.
	var merged_bindings: Dictionary = {}  # String → ActionBinding
	var base_bindings: Array[ActionBinding]
	var top_bindings: Array[ActionBinding]
	if _active_scheme == InputScheme.GAMEPAD:
		base_bindings = base_context.gamepad_bindings
		top_bindings = top_context.gamepad_bindings
	else:
		base_bindings = base_context.keyboard_mouse_bindings
		top_bindings = top_context.keyboard_mouse_bindings

	for binding: ActionBinding in base_bindings:
		merged_bindings[binding.action_name] = binding
	for binding: ActionBinding in top_bindings:
		merged_bindings[binding.action_name] = binding

	# 8. Attach each merged binding's events to InputMap, skipping unknown actions.
	for action_name: String in merged_bindings:
		if action_name not in _registered_actions:
			push_warning(
				"InputSystem: binding references unknown action '%s' — skipping."
				% action_name
			)
			continue
		var binding: ActionBinding = merged_bindings[action_name]
		for event: InputEvent in binding.events:
			InputMap.action_add_event(action_name, event)
