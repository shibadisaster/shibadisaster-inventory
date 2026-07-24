extends Node


var InventoryItemGhost = preload("./inventory_item_ghost/inventory_item_ghost.tscn")
var InventoryProjectionGhost = preload("./inventory_projection_ghost/inventory_projection_ghost.tscn")

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
var projection_ghost: InventoryProjectionGhost = null


func _ready() -> void:
	pass
	

func _process(delta: float) -> void:
	update_hovered_slot(delta)
	update_projection_ghost()


func update_hovered_slot(delta: float) -> void:
	var old_hovered_slot: InventorySlot = hovered_slot
	
	if len(currently_hovered_slots) > 0: hovered_slot = currently_hovered_slots[0]
	else: hovered_slot = null	
	
	
func update_projection_ghost() -> void:
	if item_ghost and hovered_slot:
		var error: ItemPlaceError = check_item_place()
		if error == ItemPlaceError.NO_ERROR or error == ItemPlaceError.SLOT_ALREADY_OCCUPIED: # TODO: make cleaner by moving this outward (ItemPlaceError is robust enough to handle it)
			if !projection_ghost: create_projection_ghost()
			projection_ghost.target_slot = hovered_slot
			
			if error == ItemPlaceError.NO_ERROR:
				projection_ghost.valid_placement = true
			elif error == ItemPlaceError.SLOT_ALREADY_OCCUPIED:
				projection_ghost.valid_placement = false
				if check_if_replaceable(): projection_ghost.replaceable_placement = true
				else: projection_ghost.replaceable_placement = false
				
		else: remove_projection_ghost()
	else: remove_projection_ghost()
		
		
func create_projection_ghost() -> void:
	#if !hovered_slot: return
	#if !item_ghost: return
	if projection_ghost: return
	
	var proj_ghost: InventoryProjectionGhost = InventoryProjectionGhost.instantiate()
	proj_ghost.stored_item = item_ghost.stored_item
	proj_ghost.target_slot = hovered_slot
	proj_ghost.initial_position()
	proj_ghost.update_visuals()
	
	hovered_slot.parent_grid.add_child(proj_ghost)
	projection_ghost = proj_ghost
	
	
func remove_projection_ghost() -> void:
	if !projection_ghost: return
	
	projection_ghost.fading_out = true
	projection_ghost = null
		

func slot_hovered(slot: InventorySlot):
	currently_hovered_slots.append(slot)
	

func slot_unhovered(slot: InventorySlot):
	currently_hovered_slots.erase(slot)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("InventoryClick"):
		if hovered_slot:
			if !item_ghost: attempt_item_pickup(hovered_slot)
			else: attempt_item_drop()


func attempt_item_pickup(slot: InventorySlot) -> void:
	if slot.stored_item_parent:
		var slot_with_stored_item = slot.stored_item_parent
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
	elif check_result == ItemPlaceError.SLOT_ALREADY_OCCUPIED:
		attempt_item_replace()
	else:
		print(ITEM_PLACE_ERROR_READABLE[check_result])


func check_if_replaceable() -> InventorySlot: # Returns the InventorySlot to be replaced IF it can be replaced
	if !hovered_slot or !item_ghost: return null
	var intersecting_slots: Array[InventorySlot] = hovered_slot.parent_grid.get_intersecting_item_slots(
		hovered_slot.slot_coord, 
		item_ghost.stored_item
	)
	if len(intersecting_slots) == 1: return intersecting_slots[0]
	else: return null


func attempt_item_replace() -> void:
	var replaced_slot: InventorySlot = check_if_replaceable()
	if replaced_slot:
		var old_item_ghost: InventoryItemGhost = self.item_ghost
		attempt_item_pickup(replaced_slot) # Make a ghost for the replaced slot
		attempt_item_place(self.hovered_slot, old_item_ghost.stored_item)
		if projection_ghost: 
			projection_ghost.stored_item = item_ghost.stored_item
			projection_ghost.update_visuals()
			projection_ghost.reset_fade()
		old_item_ghost.queue_free()


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
	var is_outside_bounds: bool = false
	var is_already_occupied: bool = false
	for cell in InventoryItemHandler.extract_item_shape(item_ghost.stored_item):
		var checked_coord: Vector2i = target_coord + cell
		if checked_coord not in hovered_slot.parent_grid.slots.keys(): 
			is_outside_bounds = true
			break # We break here because SLOT_OUTSIDE_BOUNDS is higher priority than SLOT_ALREADY_OCCUPIED
		if hovered_slot.parent_grid.slots[checked_coord].stored_item_parent: 
			is_already_occupied = true
			
			
	if is_outside_bounds: return ItemPlaceError.SLOT_OUTSIDE_BOUNDS
	if is_already_occupied: return ItemPlaceError.SLOT_ALREADY_OCCUPIED

	return ItemPlaceError.NO_ERROR
