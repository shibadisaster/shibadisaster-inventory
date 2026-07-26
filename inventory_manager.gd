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


## Sets the hovered_slot to whichever InventorySlot is most appropriate.
func update_hovered_slot(delta: float) -> void:
	var old_hovered_slot: InventorySlot = hovered_slot
	
	if len(currently_hovered_slots) > 0: hovered_slot = currently_hovered_slots[0]
	else: hovered_slot = null	
	

## Updates target_slot and visuals of the projection_ghost.
func update_projection_ghost() -> void:
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
		

## Called by InventorySlots when they are hovered over. (maybe should be private?)
func slot_hovered(slot: InventorySlot):
	currently_hovered_slots.append(slot)
	

## Called by InventorySlots when unhovered. (maybe should be private?)
func slot_unhovered(slot: InventorySlot):
	currently_hovered_slots.erase(slot)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("InventoryClick"):
		if hovered_slot:
			if !item_ghost: attempt_item_pickup(hovered_slot)
			else: attempt_item_drop()


## Creates an InventoryItemGhost (item_ghost) based on the item in slot then removes that item from slot.
func attempt_item_pickup(slot: InventorySlot) -> void:
	if slot.stored_item_parent:
		var slot_with_stored_item = slot.stored_item_parent
		var ghost: InventoryItemGhost = InventoryItemGhost.instantiate()
		ghost.stored_item = slot_with_stored_item.stored_item.duplicate()
		ghost.update_visuals()
		ghost.initial_positioning(slot_with_stored_item)
		
		$CanvasLayer.add_child(ghost)
		self.item_ghost = ghost
		
		attempt_item_remove(slot_with_stored_item)
		

## i dont know anymore
func attempt_item_drop() -> void:
	var check_result: ItemPlaceError = check_item_place()
	
	if check_result == ItemPlaceError.NO_ERROR: 
		# If no items in the placement...
		if self.hovered_slot.parent_grid.stacking_allowed: 
			# AND target grid supports stacking...
			# Then just place the item in the new slot (we know it will fit with no conflicts)
			attempt_item_place(self.hovered_slot, self.item_ghost.stored_item)
			remove_item_ghost()
		else: 
			# AND target grid disallows stacking...
			var new_single_item: Resource = self.item_ghost.stored_item.duplicate()
			if new_single_item.get("inventory_stack_size"): new_single_item.inventory_stack_size = 1
			attempt_item_place(self.hovered_slot, new_single_item)
			deduct_from_item_ghost(1)
			
	elif check_result == ItemPlaceError.SLOT_ALREADY_OCCUPIED: 
		# If there is already an item in the area of the placement...
		if self.hovered_slot.parent_grid.stacking_allowed and check_if_stackable(): 
			# AND it can stack...
			attempt_item_add_to_stack()
		else:
			if check_if_replaceable(): attempt_item_replace()
			
	else: # Else, throw an error.
		print(ITEM_PLACE_ERROR_READABLE[check_result])


func remove_item_ghost() -> void:
	self.item_ghost.queue_free()
	self.item_ghost = null


## Returns the InventorySlot containing the item to be replaced IF it can be replaced. Replacement can occur IF there is only one item intersecting the new placement.
func check_if_replaceable() -> InventorySlot: 
	if !hovered_slot or !item_ghost: return null
	var intersecting_slots: Array[InventorySlot] = hovered_slot.parent_grid.get_intersecting_item_slots(
		hovered_slot.slot_coord, 
		item_ghost.stored_item
	)
	if len(intersecting_slots) == 1: return intersecting_slots[0]
	else: return null


## Replaces a slot (if possible) by "simultaneously" placing the new item and picking up the original one.
func attempt_item_replace() -> void:
	var slot_to_be_replaced: InventorySlot = check_if_replaceable()
	if slot_to_be_replaced:
		var old_item_ghost: InventoryItemGhost = self.item_ghost
		attempt_item_pickup(slot_to_be_replaced) # Make a ghost for the replaced slot
		attempt_item_place(self.hovered_slot, old_item_ghost.stored_item)
		if projection_ghost: 
			projection_ghost.stored_item = item_ghost.stored_item
			projection_ghost.update_visuals()
			projection_ghost.reset_fade()
		old_item_ghost.queue_free()


## Returns the InventorySlot that can be stacked to IF one of the intersecting items can be stacked to.
func check_if_stackable() -> InventorySlot: 
	if !hovered_slot or !item_ghost: return null
	var intersecting_slots: Array[InventorySlot] = hovered_slot.parent_grid.get_intersecting_item_slots(
		hovered_slot.slot_coord, 
		item_ghost.stored_item
	)
	for intersecting_slot in intersecting_slots:
		var stackable: bool = InventoryItemHandler.is_stackable(item_ghost.stored_item, intersecting_slot.stored_item)
		if stackable: return intersecting_slot
	return null


## Forcefully places the item in its slot without checking validity. We should ONLY call this IF the space for the item is all empty.
func attempt_item_place(slot: InventorySlot, item: Resource) -> bool: 
	slot.stored_item = item
	slot.update_visuals()
	for cell in InventoryItemHandler.extract_item_shape(item):
		var slot_coord: Vector2i = slot.slot_coord
		var taken_coord: Vector2i = slot_coord + cell
		# Set each InventorySlot corresponding to a coord actually taken up by the item to reference (0, 0) slot as the parent.
		slot.parent_grid.slots[taken_coord].stored_item_parent = slot
		
	return true
	

## Clears the item from an InventorySlot and removes stored_item_parent from all other slots occupied by it. REMINDER: only one of the InventorySlots (whichever corresponds to 0, 0 of the item) actually has a stored_item, but ALL InventorySlots occupied by the item have a stored_item_parent.
func attempt_item_remove(slot: InventorySlot) -> bool:
	if slot.stored_item:
		for cell in InventoryItemHandler.extract_item_shape(slot.stored_item):
			var taken_coord: Vector2i = slot.slot_coord + cell
			slot.parent_grid.slots[taken_coord].stored_item_parent = null
		slot.stored_item = null
		slot.update_visuals()
		return true
	else: return false


## Checks for the validity of the item placement. Priority goes as follows: [br][br]
## SLOT_NOT_HOVERED: There is no hovered_slot [br]
## GHOST_DOESNT_EXIST: There is no item_ghost [br]
## SLOT_OUTSIDE_BOUNDS: One of the slots where the placement would be doesn't exist [br]
## SLOT_ALREADY_OCCUPIED: One of the slots where the placement would be already has an item [br]
## NO_ERROR: No error :)
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


## If the target item is able to be stacked to, transfers some amount of items from the item_ghost to the stack.
func attempt_item_add_to_stack() -> bool: 
	# We only call this when check_if_stackable successfully returns a slot
	var stackable_to_slot: InventorySlot = check_if_stackable()
	
	if !stackable_to_slot: return false
	if InventoryItemHandler.extract_item_stack_size(stackable_to_slot.stored_item) >= InventoryItemHandler.extract_item_max_stack_size(stackable_to_slot.stored_item): return false
	
	
	if false: # If player right-clicks to drop just 1 item into the stack
		stackable_to_slot.stored_item = InventoryItemHandler.add_to_stack(stackable_to_slot.stored_item, 1)
		deduct_from_item_ghost(1)
	else:
		var held_stack_size: int = InventoryItemHandler.extract_item_stack_size(item_ghost.stored_item)
		var remaining_until_target_reaches_max: int = (
			InventoryItemHandler.extract_item_max_stack_size(stackable_to_slot.stored_item)
			- InventoryItemHandler.extract_item_stack_size(stackable_to_slot.stored_item)
		)
		
		# Get lesser between amount in item_ghost and amount until target reaches max_stack_size
		var amount_to_add_to_stack: int = min(held_stack_size, remaining_until_target_reaches_max)
		stackable_to_slot.stored_item = InventoryItemHandler.add_to_stack(stackable_to_slot.stored_item, amount_to_add_to_stack)
		deduct_from_item_ghost(amount_to_add_to_stack)
	return true
		

## Deducts some amount of items from the item_ghost and removes it if it reaches 0 stack_size.
func deduct_from_item_ghost(amount: int) -> void:
	item_ghost.stored_item = InventoryItemHandler.add_to_stack(item_ghost.stored_item, -amount)
	item_ghost.update_visuals()
		
	var new_ghost_stack_size: int = InventoryItemHandler.extract_item_stack_size(item_ghost.stored_item)
	if new_ghost_stack_size is int and new_ghost_stack_size <= 0:
		remove_item_ghost()
	
