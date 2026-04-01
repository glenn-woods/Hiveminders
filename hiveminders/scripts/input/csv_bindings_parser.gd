class_name CsvBindingsParser
extends RefCounted

## Result of a parse operation.
class ParseResult:
	var bindings: Array[InputContextBindings] = []
	var errors: Array[String] = []

## Parses a CSV string and returns a ParseResult.
## csv_text: the raw CSV content. path is used only in error messages.
static func parse(csv_text: String, path: String = "") -> ParseResult:
	var result := ParseResult.new()

	# Split on newlines, strip trailing whitespace, discard empty lines.
	var raw_lines := csv_text.split("\n")
	var lines: Array[String] = []
	for raw in raw_lines:
		var stripped := raw.rstrip(" \t\r")
		if not stripped.is_empty():
			lines.append(stripped)

	if lines.is_empty():
		var path_str := path if not path.is_empty() else "<unknown>"
		result.errors.append("CSV input is empty or could not be read (path: '%s')" % path_str)
		return result

	# Validate header row.
	const EXPECTED_HEADER := "context,action,action_type,gamepad,keyboard_mouse"
	if lines[0] != EXPECTED_HEADER:
		result.errors.append(
			"Line 1: expected header 'context,action,action_type,gamepad,keyboard_mouse' but got '%s'" % lines[0]
		)
		return result

	# Track seen (context, action) pairs for duplicate detection.
	# Key: "context\0action", Value: line number of first occurrence.
	var seen_pairs: Dictionary = {}

	# Accumulate rows per context in insertion order.
	# Key: context name, Value: Array of row dicts.
	var context_rows: Dictionary = {}
	var context_order: Array[String] = []

	# Parse data rows (lines[1..]).
	for i in range(1, lines.size()):
		var line_num := i + 1  # 1-based, header is line 1
		var line := lines[i]

		# Split on comma — exactly 5 columns expected.
		var cols := line.split(",", false)
		# Rejoin if there are more than 5 splits (pipe tokens never contain commas,
		# but be defensive: treat columns 4 and 5 as the last two).
		if cols.size() < 5:
			# Pad missing columns with empty strings.
			while cols.size() < 5:
				cols.append("")
		# If somehow more than 5, merge extras into the last column (shouldn't happen).

		var ctx: String = cols[0].strip_edges()
		var action: String = cols[1].strip_edges()
		var action_type_str: String = cols[2].strip_edges()
		var gamepad_cell: String = cols[3].strip_edges()
		var km_cell: String = cols[4].strip_edges()

		# Validate action_type.
		var action_type: ActionDefinition.ActionType
		match action_type_str:
			"BOOL":
				action_type = ActionDefinition.ActionType.BOOL
			"AXIS":
				action_type = ActionDefinition.ActionType.AXIS
			"VECTOR2":
				action_type = ActionDefinition.ActionType.VECTOR2
			_:
				result.errors.append(
					"Line %d: unrecognized action_type '%s', expected BOOL, AXIS, or VECTOR2" % [line_num, action_type_str]
				)
				# Continue processing the rest of the row for other errors.
				action_type = ActionDefinition.ActionType.BOOL

		# Check for duplicate (context, action) pairs.
		var pair_key := ctx + "|" + action
		if seen_pairs.has(pair_key):
			result.errors.append(
				"Line %d: duplicate action '%s' in context '%s'" % [line_num, action, ctx]
			)
		else:
			seen_pairs[pair_key] = line_num

		# Parse gamepad events.
		var gamepad_events: Array[InputEvent] = []
		if not gamepad_cell.is_empty():
			var tokens := gamepad_cell.split("|")
			for raw_token in tokens:
				var token := raw_token.strip_edges()
				if token.is_empty():
					continue
				var token_result := EventTokenParser.token_to_event(token)
				if token_result[0] == null:
					result.errors.append(
						"Line %d, column 'gamepad': unrecognized event token '%s'" % [line_num, token]
					)
				else:
					gamepad_events.append(token_result[0])

		# Parse keyboard_mouse events.
		var km_events: Array[InputEvent] = []
		if not km_cell.is_empty():
			var tokens := km_cell.split("|")
			for raw_token in tokens:
				var token := raw_token.strip_edges()
				if token.is_empty():
					continue
				var token_result := EventTokenParser.token_to_event(token)
				if token_result[0] == null:
					result.errors.append(
						"Line %d, column 'keyboard_mouse': unrecognized event token '%s'" % [line_num, token]
					)
				else:
					km_events.append(token_result[0])

		# Accumulate row data.
		if not context_rows.has(ctx):
			context_rows[ctx] = []
			context_order.append(ctx)

		context_rows[ctx].append({
			"action": action,
			"action_type": action_type,
			"gamepad_events": gamepad_events,
			"km_events": km_events,
		})

	# Build InputContextBindings for each context.
	for ctx in context_order:
		var rows: Array = context_rows[ctx]
		var icb := InputContextBindings.new()
		icb.context_name = ctx

		for row in rows:
			# ActionDefinition.
			var action_def := ActionDefinition.new()
			action_def.action_name = row["action"]
			action_def.action_type = row["action_type"]
			icb.actions.append(action_def)

			# Gamepad binding (only if there are events).
			var gp_events: Array[InputEvent] = row["gamepad_events"]
			if not gp_events.is_empty():
				var gp_binding := ActionBinding.new()
				gp_binding.action_name = row["action"]
				gp_binding.events = gp_events
				icb.gamepad_bindings.append(gp_binding)

			# Keyboard/mouse binding (only if there are events).
			var km_events: Array[InputEvent] = row["km_events"]
			if not km_events.is_empty():
				var km_binding := ActionBinding.new()
				km_binding.action_name = row["action"]
				km_binding.events = km_events
				icb.keyboard_mouse_bindings.append(km_binding)

		result.bindings.append(icb)

	return result
