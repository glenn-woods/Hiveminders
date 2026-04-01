class_name TileComponent
extends RefCounted

## Base class for modular tile attachments.
## Subclass this to create resource nodes, devices, light sources, etc.

## Returns a string identifying the component type.
## Override in subclasses to return a unique identifier.
func get_component_type() -> String:
	return ""
