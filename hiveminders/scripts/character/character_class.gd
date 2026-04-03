class_name CharacterClass
extends Resource

## Unique identifier for this character class.
@export var class_id: String = ""

## Display name shown in UI.
@export var display_name: String = ""

## Primary body color.
@export var body_color: Color = Color.WHITE

## Short description for the selection screen.
@export var description: String = ""

## The 3D scene instantiated in the character select preview viewport.
## Swap this per class for unique meshes, animations, etc.
@export var preview_scene: PackedScene = null

# -----------------------------------------------------------------------
# Stats — defaults for now, expand as gameplay develops.
# -----------------------------------------------------------------------

@export_group("Base Stats")
@export var move_speed: float = 5.0
@export var jump_velocity: float = 6.57
@export var max_health: float = 100.0

# -----------------------------------------------------------------------
# Abilities — placeholder arrays for future systems.
# -----------------------------------------------------------------------

@export_group("Abilities")
## Ability IDs this class starts with.
@export var starting_abilities: PackedStringArray = []

## Passive trait IDs.
@export var passive_traits: PackedStringArray = []
