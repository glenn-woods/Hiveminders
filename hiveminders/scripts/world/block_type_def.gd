class_name BlockTypeDef
extends RefCounted

## Unique string identifier (e.g. "stone", "dirt", "air").
var type_id: String = ""

## Human-readable name shown in UI.
var display_name: String = ""

## The color/material used for rendering this block's faces.
## Created from the hex color in the CSV. Null for air.
var material: StandardMaterial3D = null

## Whether this type represents empty space (air).
var is_air: bool = false
