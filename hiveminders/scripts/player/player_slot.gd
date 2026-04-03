class_name PlayerSlot
extends RefCounted

## Represents one player in the lobby/game.
## device_id: gamepad index (0-3) or -1 for keyboard/mouse.

var slot_index: int = -1
var device_id: int = -1
var selected_class: CharacterClass = null
var is_ready: bool = false

## True once the player has released accept after going ready.
## Prevents the hold-to-start timer from triggering on the same press that confirmed.
var accept_released_since_ready: bool = false

## True once the player has released cancel after un-readying.
## Prevents the hold-to-back timer from triggering on the same press that deselected.
var cancel_released_since_unready: bool = true

## Which character box index this player's cursor is on.
var focus_index: int = 0


func is_keyboard() -> bool:
	return device_id == -1
