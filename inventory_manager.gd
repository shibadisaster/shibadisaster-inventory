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
	update_item_ghost()

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
			if check_if_replaceable(hovered_slot, item_ghost.stored_item): projection_ghost.replaceable_placement = true
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
func slot_hovered(slot: InventorySlot) -> void:
	currently_hovered_slots.append(slot)
	

## Called by InventorySlots when unhovered. (maybe should be private?)
func slot_unhovered(slot: InventorySlot) -> void:
	currently_hovered_slots.erase(slot)
	
	
func create_item_ghost(item: Resource, from_slot: InventorySlot) -> void:
	if !item_ghost:
		var ghost: InventoryItemGhost = InventoryItemGhost.instantiate()
		ghost.stored_item = item.duplicate()
		#ghost.stored_item.inventory_stack_size = amount_to_be_picked_up
		ghost.update_visuals()
		ghost.initial_positioning(from_slot)
		
		$CanvasLayer.add_child(ghost)
		self.item_ghost = ghost

	
func update_item_ghost() -> void:
	if item_ghost:
		if item_ghost.depleted:
			item_ghost.target_for_depleted_move = hovered_slot
			item_ghost.start_depletion_animation()
			self.item_ghost = null


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("InventoryClick") or event.is_action_pressed("InventoryClickSecondary"):
		if hovered_slot:
			if !item_ghost: 
				var pickup_result: Resource = pickup_item(hovered_slot, event.is_action_pressed("InventoryClickSecondary"))
				if pickup_result:
					var target: InventorySlot = hovered_slot.previous_frame_stored_item_parent
					if !target: target = hovered_slot
					create_item_ghost(pickup_result, target)
			else: 
				var drop_result: Resource = drop_item(
					hovered_slot,
					item_ghost.stored_item,
					event.is_action_pressed("InventoryClickSecondary")
				)
				if drop_result is Resource: item_ghost.stored_item = drop_result


##### ACTIONS #####


## Creates an InventoryItemGhost (item_ghost) based on the item in slot then removes that item from slot. If alternate_action, only picks up half.
## Attempts to pickup the item at the specified slot.
func pickup_item(slot: InventorySlot, alternate_action: bool) -> Resource:
	var remove_result: Resource = slot.parent_grid.remove_item(slot.slot_coord)
	return remove_result


## Attempts to add an item in the specified slot, attempting to replace instead if it can't be added.
func drop_item(slot: InventorySlot, item: Resource, alternate_action: bool) -> Resource:
	var add_result: Resource = slot.parent_grid.add_item(hovered_slot.slot_coord, item_ghost.stored_item)
	if add_result is Resource:
		return add_result
	else:
		var replace_result: Resource = replace_item(slot, item)
		return replace_result
		

## Returns the InventorySlot containing the item to be replaced IF it can be replaced. Replacement can occur IF there is only one item intersecting the new placement.
func check_if_replaceable(slot: InventorySlot, item: Resource) -> InventorySlot: 
	if !hovered_slot or !item_ghost: return null
	var intersecting_slots: Array[InventorySlot] = hovered_slot.parent_grid.get_intersecting_item_slots(
		hovered_slot.slot_coord, 
		item_ghost.stored_item
	)
	if len(intersecting_slots) == 1: return intersecting_slots[0]
	else: return null


## Attempts to replace a slot (if possible) by "simultaneously" placing the new item and picking up the original one.
func replace_item(slot: InventorySlot, new_item: Resource) -> Resource:
	var slot_to_be_replaced: InventorySlot = check_if_replaceable(slot, new_item)
	if slot_to_be_replaced:
		print("REPLACEDDDD")
		var original_item = pickup_item(slot_to_be_replaced, false)
		slot.parent_grid.add_item(slot.slot_coord, new_item)
		if projection_ghost: 
			projection_ghost.stored_item = original_item
			projection_ghost.update_visuals()
			projection_ghost.reset_fade()
		return original_item
	else: return null


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
