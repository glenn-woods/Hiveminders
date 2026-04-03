extends Node

## Manages player slots across scenes. Up to 4 players.
## Persists as an autoload so the game scene knows who's playing.

const MAX_PLAYERS: int = 4

## Slot colors for focus rings — one per player slot.
const SLOT_COLORS: Array[Color] = [
	Color(1.0, 0.85, 0.2, 1.0),   # Gold
	Color(0.3, 0.8, 1.0, 1.0),    # Cyan
	Color(1.0, 0.4, 0.6, 1.0),    # Pink
	Color(0.5, 1.0, 0.4, 1.0),    # Lime
]

var _slots: Array[PlayerSlot] = []


func get_slots() -> Array[PlayerSlot]:
	return _slots


func get_slot_count() -> int:
	return _slots.size()


## Returns the slot for a given device, or null if not joined.
func get_slot_by_device(device_id: int) -> PlayerSlot:
	for slot in _slots:
		if slot.device_id == device_id:
			return slot
	return null


## Try to join a new player from the given device.
## Returns the new slot, or null if already joined or full.
func join(device_id: int) -> PlayerSlot:
	if _slots.size() >= MAX_PLAYERS:
		return null
	if get_slot_by_device(device_id) != null:
		return null
	var slot := PlayerSlot.new()
	slot.slot_index = _slots.size()
	slot.device_id = device_id
	_slots.append(slot)
	return slot


## Remove a player slot by device. Returns true if removed.
func leave(device_id: int) -> bool:
	for i in range(_slots.size()):
		if _slots[i].device_id == device_id:
			_slots.remove_at(i)
			# Re-index remaining slots
			for j in range(_slots.size()):
				_slots[j].slot_index = j
			return true
	return false


## Clear all slots (e.g. returning to main menu).
func clear() -> void:
	_slots.clear()


## Returns true if all joined players are ready.
func all_ready() -> bool:
	if _slots.is_empty():
		return false
	for slot in _slots:
		if not slot.is_ready:
			return false
	return true


## Get the slot color for a given slot index.
func get_slot_color(slot_index: int) -> Color:
	if slot_index >= 0 and slot_index < SLOT_COLORS.size():
		return SLOT_COLORS[slot_index]
	return Color.WHITE
