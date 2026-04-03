class_name InputContextBindings
extends Resource

## The unique name of this context (e.g. "base", "isometric", "third_person").
@export var context_name: String = ""

## All actions available in this context.
@export var actions: Array[ActionDefinition] = []

## Bindings used when the active scheme is Gamepad.
@export var gamepad_bindings: Array[ActionBinding] = []

## Bindings used when the active scheme is Keyboard/Mouse.
@export var keyboard_mouse_bindings: Array[ActionBinding] = []

## When true, both schemes' bindings are always registered regardless of the
## active scheme. Use for UI contexts where mouse and controller must coexist.
@export var merge_schemes: bool = false
