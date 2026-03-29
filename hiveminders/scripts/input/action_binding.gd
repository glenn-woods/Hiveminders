class_name ActionBinding
extends Resource

## The action this binding maps events to (must match an ActionDefinition.action_name).
@export var action_name: String = ""

## The input events bound to this action for a specific scheme.
@export var events: Array[InputEvent] = []
