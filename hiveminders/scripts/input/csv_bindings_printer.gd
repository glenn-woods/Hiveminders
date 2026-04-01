class_name CsvBindingsPrinter
extends RefCounted

## Serializes an array of InputContextBindings into a CSV string.
static func print_csv(contexts: Array[InputContextBindings]) -> String:
	var lines: Array[String] = []
	lines.append("context,action,action_type,gamepad,keyboard_mouse")

	# Sort contexts alphabetically by context_name
	var sorted_contexts := contexts.duplicate()
	sorted_contexts.sort_custom(func(a: InputContextBindings, b: InputContextBindings) -> bool:
		return a.context_name < b.context_name
	)

	for context in sorted_contexts:
		for action_def in context.actions:
			var action_type_str := _action_type_to_string(action_def.action_type)

			var gamepad_tokens := _binding_tokens(context.gamepad_bindings, action_def.action_name)
			var keyboard_tokens := _binding_tokens(context.keyboard_mouse_bindings, action_def.action_name)

			lines.append("%s,%s,%s,%s,%s" % [
				context.context_name,
				action_def.action_name,
				action_type_str,
				gamepad_tokens,
				keyboard_tokens,
			])

	return "\n".join(lines)


## Returns the pipe-joined event tokens for the ActionBinding matching action_name,
## or "" if no matching binding is found.
static func _binding_tokens(bindings: Array[ActionBinding], action_name: String) -> String:
	for binding in bindings:
		if binding.action_name == action_name:
			var tokens: Array[String] = []
			for event in binding.events:
				var token := EventTokenParser.event_to_token(event)
				if not token.is_empty():
					tokens.append(token)
			return " | ".join(tokens)
	return ""


## Converts an ActionDefinition.ActionType enum value to its CSV string representation.
static func _action_type_to_string(action_type: ActionDefinition.ActionType) -> String:
	match action_type:
		ActionDefinition.ActionType.BOOL:
			return "BOOL"
		ActionDefinition.ActionType.AXIS:
			return "AXIS"
		ActionDefinition.ActionType.VECTOR2:
			return "VECTOR2"
		_:
			return "BOOL"
