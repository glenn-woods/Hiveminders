class_name ActionDefinition
extends Resource

## Action value types — mirrors InputSystem.ActionType (defined here until InputSystem exists).
enum ActionType {
	BOOL = 0,
	AXIS = 1,
	VECTOR2 = 2,
}

## The unique name of this action (e.g. "pause", "move").
@export var action_name: String = ""

## The value type of this action.
@export var action_type: ActionType = ActionType.BOOL
