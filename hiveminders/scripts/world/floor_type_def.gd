class_name FloorTypeDef
extends RefCounted

## Unique string identifier (e.g. "stone", "dirt", "empty").
var type_id: String = ""

## Human-readable name shown in UI.
var display_name: String = ""

## The color/material used for rendering this floor slab.
## Created from the hex color in the CSV. Null for empty.
var material: StandardMaterial3D = null

## Whether this type represents no floor (empty).
var is_empty: bool = false
