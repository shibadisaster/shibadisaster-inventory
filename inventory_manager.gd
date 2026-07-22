extends Node


var InventoryItemGhost = preload("./inventory_item_ghost/inventory_item_ghost.tscn")

enum ItemPlaceError {
	NO_ERROR,
	SLOT_ALREADY_OCCUPIED,
	SLOT_OUTSIDE_BOUNDS,
	SLOT_NOT_HOVERED,
	GHOST_DOESNT_EXIST
}
const ITEM_PLACE_ERROR_READABLE: Dictionary[ItemPlaceError, String] = {
	ItemPlaceError.NO_ERROR: "N/A",
	ItemPlaceError.SLOT_ALREADY_OCCUPIED: "New placement is already occupied!",
	ItemPlaceError.SLOT_OUTSIDE_BOUNDS: "New placement has a cell out of bounds!",
	ItemPlaceError.SLOT_NOT_HOVERED: "No slot selected!",
	ItemPlaceError.GHOST_DOESNT_EXIST: "No item picked up!"
}

var hovered_slot: InventorySlot = null
var currently_hovered_slots: Array[InventorySlot] = []

var item_ghost: InventoryItemGhost = null


func _ready() -> void:
	pass
	

func _process(delta: float) -> void:
	update_hovered_slot(delta)


func update_hovered_slot(delta: float) -> void:
	var old_hovered_slot: InventorySlot = hovered_slot
	
	if len(currently_hovered_slots) > 0: hovered_slot = currently_hovered_slots[0]
	else: hovered_slot = null	
		

func slot_hovered(slot: InventorySlot):
	currently_hovered_slots.append(slot)
	

func slot_unhovered(slot: InventorySlot):
	currently_hovered_slots.erase(slot)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("InventoryClick"):
		if hovered_slot:
			if !item_ghost: attempt_item_pickup()
			else: attempt_item_drop()


func attempt_item_pickup() -> void:
	if hovered_slot.stored_item_parent and !self.item_ghost:
		var slot_with_stored_item = hovered_slot.stored_item_parent
		var ghost: InventoryItemGhost = InventoryItemGhost.instantiate()
		ghost.stored_item = slot_with_stored_item.stored_item
		ghost.update_visuals()
		ghost.initial_positioning(slot_with_stored_item)
		
		$CanvasLayer.add_child(ghost)
		self.item_ghost = ghost
		
		attempt_item_remove(slot_with_stored_item)
		
		
func attempt_item_drop() -> void:
	var check_result: ItemPlaceError = check_item_place()
	if check_result == ItemPlaceError.NO_ERROR:
		attempt_item_place(self.hovered_slot, self.item_ghost.stored_item)
		self.item_ghost.queue_free()
		self.item_ghost = null
	else:
		print(ITEM_PLACE_ERROR_READABLE[check_result])


func attempt_item_place(slot: InventorySlot, item: Resource) -> bool:
	slot.stored_item = item
	slot.update_visuals()
	for cell in InventoryItemHandler.extract_item_shape(item):
		var slot_coord: Vector2i = slot.slot_coord
		var taken_coord: Vector2i = slot_coord + cell
		# Set each InventorySlot corresponding to a coord actually taken up by the item to reference (0, 0) slot as the parent.
		slot.parent_grid.slots[taken_coord].stored_item_parent = slot
		
	return true
	

func attempt_item_remove(slot: InventorySlot) -> bool:
	if slot.stored_item:
		for cell in InventoryItemHandler.extract_item_shape(slot.stored_item):
			var taken_coord: Vector2i = slot.slot_coord + cell
			slot.parent_grid.slots[taken_coord].stored_item_parent = null
		slot.stored_item = null
		slot.update_visuals()
		return true
	else: return false


func check_item_place() -> ItemPlaceError:
	if !hovered_slot: return ItemPlaceError.SLOT_NOT_HOVERED
	if !item_ghost: return ItemPlaceError.GHOST_DOESNT_EXIST
	
	var target_coord: Vector2i = hovered_slot.slot_coord
	for cell in InventoryItemHandler.extract_item_shape(item_ghost.stored_item):
		var checked_coord: Vector2i = target_coord + cell
		if checked_coord not in hovered_slot.parent_grid.slots.keys(): return ItemPlaceError.SLOT_OUTSIDE_BOUNDS
		if hovered_slot.parent_grid.slots[checked_coord].stored_item_parent: return ItemPlaceError.SLOT_ALREADY_OCCUPIED

	return ItemPlaceError.NO_ERROR
