extends Resource
class_name InventoryGridSaveData


var slot_coords: Array[Vector2i]
var items: Dictionary[Vector2i, Resource] 


func save(grid: InventoryGrid) -> void:
	slot_coords = []
	items = {}
	for slot_coord in grid.slots.keys():
		slot_coords.append(slot_coord)
		var slot: InventorySlot = grid.slots[slot_coord]
		if slot.stored_item:
			items[slot_coord] = slot.stored_item.duplicate()
