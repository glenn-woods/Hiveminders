## Unit tests for CsvBindingsParser error conditions and edge cases.
## Run this script as a standalone scene (extends Node) or attach it to a test runner.
##
## Requirements covered: 1.5, 4.1, 4.2, 4.3, 4.4, 4.5
extends Node

const HEADER := "context,action,action_type,gamepad,keyboard_mouse"

func _ready() -> void:
	test_wrong_header_returns_error()
	test_missing_header_returns_error()
	test_invalid_action_type_returns_error()
	test_invalid_gamepad_token_returns_error()
	test_invalid_keyboard_mouse_token_returns_error()
	test_duplicate_action_in_context_returns_error()
	test_empty_input_returns_error_with_path()
	test_empty_binding_cell_no_gamepad_binding()
	test_empty_binding_cell_no_keyboard_binding()
	test_happy_path_three_contexts()
	print("All CsvBindingsParser unit tests passed.")


# ---------------------------------------------------------------------------
# Req 4.1 — Missing / wrong header
# ---------------------------------------------------------------------------

func test_wrong_header_returns_error() -> void:
	var csv := "context,action,action_type,gamepad\nbase,pause,BOOL,joy_button:6"
	var result := CsvBindingsParser.parse(csv)
	assert(result.errors.size() > 0,
		"Expected an error for wrong header but got none")
	assert(_any_error_contains(result.errors, "expected header 'context,action,action_type,gamepad,keyboard_mouse'"),
		"Error should mention the expected header. Got: %s" % str(result.errors))


func test_missing_header_returns_error() -> void:
	# Completely absent header — first line is a data row.
	var csv := "base,pause,BOOL,joy_button:6,key:Escape"
	var result := CsvBindingsParser.parse(csv)
	assert(result.errors.size() > 0,
		"Expected an error for missing header but got none")
	assert(_any_error_contains(result.errors, "expected header 'context,action,action_type,gamepad,keyboard_mouse'"),
		"Error should mention the expected header. Got: %s" % str(result.errors))


# ---------------------------------------------------------------------------
# Req 4.2 — Invalid action_type
# ---------------------------------------------------------------------------

func test_invalid_action_type_returns_error() -> void:
	var csv := "%s\nbase,pause,INVALID_TYPE,joy_button:6,key:Escape" % HEADER
	var result := CsvBindingsParser.parse(csv)
	assert(result.errors.size() > 0,
		"Expected an error for invalid action_type but got none")
	# Must mention the row number (2) and the bad value.
	assert(_any_error_contains(result.errors, "2"),
		"Error should contain the row number. Got: %s" % str(result.errors))
	assert(_any_error_contains(result.errors, "INVALID_TYPE"),
		"Error should contain the invalid value. Got: %s" % str(result.errors))


# ---------------------------------------------------------------------------
# Req 4.3 — Invalid event token
# ---------------------------------------------------------------------------

func test_invalid_gamepad_token_returns_error() -> void:
	var csv := "%s\nbase,pause,BOOL,BADTOKEN,key:Escape" % HEADER
	var result := CsvBindingsParser.parse(csv)
	assert(result.errors.size() > 0,
		"Expected an error for invalid gamepad token but got none")
	assert(_any_error_contains(result.errors, "2"),
		"Error should contain the row number. Got: %s" % str(result.errors))
	assert(_any_error_contains(result.errors, "gamepad"),
		"Error should mention the 'gamepad' column. Got: %s" % str(result.errors))
	assert(_any_error_contains(result.errors, "BADTOKEN"),
		"Error should contain the invalid token. Got: %s" % str(result.errors))


func test_invalid_keyboard_mouse_token_returns_error() -> void:
	var csv := "%s\nbase,pause,BOOL,joy_button:6,BADKBTOKEN" % HEADER
	var result := CsvBindingsParser.parse(csv)
	assert(result.errors.size() > 0,
		"Expected an error for invalid keyboard_mouse token but got none")
	assert(_any_error_contains(result.errors, "2"),
		"Error should contain the row number. Got: %s" % str(result.errors))
	assert(_any_error_contains(result.errors, "keyboard_mouse"),
		"Error should mention the 'keyboard_mouse' column. Got: %s" % str(result.errors))
	assert(_any_error_contains(result.errors, "BADKBTOKEN"),
		"Error should contain the invalid token. Got: %s" % str(result.errors))


# ---------------------------------------------------------------------------
# Req 4.4 — Duplicate action in same context
# ---------------------------------------------------------------------------

func test_duplicate_action_in_context_returns_error() -> void:
	var csv := (
		"%s\n" % HEADER +
		"base,pause,BOOL,joy_button:6,key:Escape\n" +
		"base,pause,BOOL,joy_button:7,key:P"
	)
	var result := CsvBindingsParser.parse(csv)
	assert(result.errors.size() > 0,
		"Expected an error for duplicate action but got none")
	assert(_any_error_contains(result.errors, "base"),
		"Error should mention the context name. Got: %s" % str(result.errors))
	assert(_any_error_contains(result.errors, "pause"),
		"Error should mention the duplicate action name. Got: %s" % str(result.errors))


# ---------------------------------------------------------------------------
# Req 4.5 — Empty CSV input
# ---------------------------------------------------------------------------

func test_empty_input_returns_error_with_path() -> void:
	var result := CsvBindingsParser.parse("", "res://input/input_bindings.csv")
	assert(result.errors.size() > 0,
		"Expected an error for empty input but got none")
	assert(_any_error_contains(result.errors, "empty or could not be read"),
		"Error should mention 'empty or could not be read'. Got: %s" % str(result.errors))


# ---------------------------------------------------------------------------
# Req 1.5 — Empty binding cells
# ---------------------------------------------------------------------------

func test_empty_binding_cell_no_gamepad_binding() -> void:
	# Empty gamepad cell — keyboard_mouse cell is populated.
	var csv := "%s\nbase,pause,BOOL,,key:Escape" % HEADER
	var result := CsvBindingsParser.parse(csv)
	assert(result.errors.is_empty(),
		"Expected no errors for empty gamepad cell. Got: %s" % str(result.errors))
	assert(result.bindings.size() == 1,
		"Expected 1 context binding. Got: %d" % result.bindings.size())
	var ctx: InputContextBindings = result.bindings[0]
	assert(ctx.gamepad_bindings.is_empty(),
		"Expected no gamepad bindings for empty gamepad cell")
	assert(ctx.keyboard_mouse_bindings.size() == 1,
		"Expected 1 keyboard_mouse binding. Got: %d" % ctx.keyboard_mouse_bindings.size())


func test_empty_binding_cell_no_keyboard_binding() -> void:
	# Empty keyboard_mouse cell — gamepad cell is populated.
	var csv := "%s\nbase,pause,BOOL,joy_button:6," % HEADER
	var result := CsvBindingsParser.parse(csv)
	assert(result.errors.is_empty(),
		"Expected no errors for empty keyboard_mouse cell. Got: %s" % str(result.errors))
	assert(result.bindings.size() == 1,
		"Expected 1 context binding. Got: %d" % result.bindings.size())
	var ctx: InputContextBindings = result.bindings[0]
	assert(ctx.keyboard_mouse_bindings.is_empty(),
		"Expected no keyboard_mouse bindings for empty keyboard_mouse cell")
	assert(ctx.gamepad_bindings.size() == 1,
		"Expected 1 gamepad binding. Got: %d" % ctx.gamepad_bindings.size())


# ---------------------------------------------------------------------------
# Happy-path: three contexts (base, isometric, third_person)
# ---------------------------------------------------------------------------

func test_happy_path_three_contexts() -> void:
	var csv := (
		"%s\n" % HEADER +
		"base,pause,BOOL,joy_button:6,key:Escape\n" +
		"base,toggle_mode,BOOL,joy_button:4,key:Tab\n" +
		"isometric,select,BOOL,joy_button:0,mouse_button:1\n" +
		"isometric,camera_zoom_in,BOOL,joy_button:13,mouse_button:4\n" +
		"isometric,camera_zoom_out,BOOL,joy_button:12,mouse_button:5\n" +
		"third_person,jump,BOOL,joy_button:1,key:Space\n" +
		"third_person,sprint,BOOL,joy_button:5,key:Shift"
	)
	var result := CsvBindingsParser.parse(csv)
	assert(result.errors.is_empty(),
		"Expected no errors for valid CSV. Got: %s" % str(result.errors))
	assert(result.bindings.size() == 3,
		"Expected 3 context bindings. Got: %d" % result.bindings.size())

	# Collect context names for easy lookup.
	var context_names: Array[String] = []
	for b in result.bindings:
		context_names.append(b.context_name)

	assert("base" in context_names, "Expected 'base' context")
	assert("isometric" in context_names, "Expected 'isometric' context")
	assert("third_person" in context_names, "Expected 'third_person' context")

	# Verify action counts per context.
	for b in result.bindings:
		match b.context_name:
			"base":
				assert(b.actions.size() == 2,
					"Expected 2 actions in 'base'. Got: %d" % b.actions.size())
			"isometric":
				assert(b.actions.size() == 3,
					"Expected 3 actions in 'isometric'. Got: %d" % b.actions.size())
			"third_person":
				assert(b.actions.size() == 2,
					"Expected 2 actions in 'third_person'. Got: %d" % b.actions.size())


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _any_error_contains(errors: Array[String], substring: String) -> bool:
	for err in errors:
		if err.contains(substring):
			return true
	return false
