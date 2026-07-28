#@tool


extends Container
class_name InventoryGrid


var InventorySlot = preload("./inventory_slot/inventory_slot.tscn")


@export var inventory_grid_id: String = str(randi())

## Initial shape of the InventoryGrid's slots. Can be expanded later if supported.
@export var initial_shape: Array[Vector2i] = [Vector2i.ZERO]

## Size of each InventorySlot in pixels.
@export var inventory_slot_size: float = 64.0

## A layer refers to a layer of the InventoryGrid that an Item can exist in. Items from different layers can occupy the same space, but Items from the same layer cannot.
@export var layers: Array[String] = ["Default"]

@export var stacking_allowed: bool = true

### Style box override for generated InventorySlots
#@export var stylebox: StyleBox = null

var slots: Dictionary[Vector2i, InventorySlot] = {}


func _enter_tree() -> void:
	_set_default_properties()
	generate_inventory_slots()
	

func _ready() -> void:
	generate_inventory_slots()


func _process(delta: float) -> void:
	update_all_stored_item_parents()


func _set_default_properties() -> void:
	self.offset_transform_enabled = true
	self.offset_transform_visual_only = false
	

func generate_inventory_slots() -> void:
	for slot_coord in initial_shape:
		if slot_coord not in slots.keys():
			generate_slot(slot_coord)
			

func generate_slot(slot_coord: Vector2i) -> void:
	var slot: InventorySlot = InventorySlot.instantiate()
	slot.custom_minimum_size = Vector2(inventory_slot_size, inventory_slot_size)
	slot.custom_maximum_size = Vector2(inventory_slot_size, inventory_slot_size)
	slot.position = (slot_coord * inventory_slot_size) - (Vector2(inventory_slot_size, inventory_slot_size) / 2.0)
	slot.slot_coord = slot_coord
	slot.parent_grid = self
	self.add_child(slot)
	
	slots[slot_coord] = slot


## Returns SPECIFICALLY the 0, 0 or "core slot" of all intersecting items.
func get_intersecting_item_slots(target_slot_coord: Vector2i, item: Resource) -> Array[InventorySlot]:
	var intersecting_item_slots: Array[InventorySlot] = []
	for cell in InventoryItemHandler.extract_item_shape(item):
		var check_coord: Vector2i = target_slot_coord + cell
		if check_coord not in slots.keys(): continue # If check_coord is out of bounds, skip over it
		
		if slots[check_coord].stored_item_parent:
			var intersecting_item_slot: InventorySlot = slots[check_coord].stored_item_parent
			if intersecting_item_slot not in intersecting_item_slots:
				intersecting_item_slots.append(intersecting_item_slot)
				
	return intersecting_item_slots
	
	
func is_item_in_bounds(target_slot_coord: Vector2i, item: Resource) -> bool:
	for cell in item.inventory_shape:
		var check_coord = target_slot_coord + cell
		if check_coord not in slots.keys(): return false
	return true
	

## If called on a coord with a stored_item, updates all other coords taken up by the stored_item to have that coord be the stored_item_parent.
func update_stored_item_parent(slot_coord: Vector2i) -> void:
	if slots[slot_coord].stored_item:
		var parent_slot: InventorySlot = slots[slot_coord]
		for cell in slots[slot_coord].stored_item.inventory_shape:
			var update_coord: Vector2i = slot_coord + cell
			slots[update_coord].stored_item_parent = parent_slot


## Updates all slots taken up by an item to have stored_item_parents.
func update_all_stored_item_parents() -> void:
	for slot_coord in slots.keys():
		slots[slot_coord].stored_item_parent = null
		
	for slot_coord in slots.keys():
		if slots[slot_coord].stored_item:
			update_stored_item_parent(slot_coord)

# okay so there is no way around this i need to move all the helper funcs into here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# for sanity, 
#	ALL things relating to modifying stuff in an inventorygrid should go here (stacking, moving, removing, adding, etc)
# 	ALL things relating to exterior objs or those on a layer above inventorygrids (saving, loading, itemghost, user input, projectionghost) should go in inventorymanager


## Attempts to add an item anywhere it can fit, returning an inventory_stack_size == 0 item Resource if all in the item's stack were able to be added, null, an inventory_stack_size == (n - x) item Resource if it was able to stack some (x) but not all (n), and null if it couldn't fit anywhere.
func auto_add_item(item: Resource) -> Resource:
	return null


## Attempts to add an item to the specified slot_coord, returning an inventory_stack_size == 0 item Resource if all in the item's stack were able to be added, null, an inventory_stack_size == (n - x) item Resource if it was able to stack some (x) but not all (n), and null if it couldn't fit anywhere.
func add_item(slot_coord: Vector2i, item: Resource, max_stack_amount: int = -1) -> Resource:
	if slot_coord not in slots.keys(): return null
	
	# If stacking is allowed, attempt to increment first...
	if stacking_allowed:
		for cell in item.inventory_shape: # We check all possible cells to see if it overlaps with a stackable item anywhere.
			var target_coord: Vector2i = slot_coord + cell
			if target_coord not in slots.keys(): continue
			
			var increment_result = increment_item_stack(target_coord, item, max_stack_amount)
			if increment_result is Resource: return increment_result
	
	# Then, if not early returned, attempt to place.
	var place_result = place_item(slot_coord, item, max_stack_amount)
	if place_result is Resource: return place_result
	
	# If we get to this point, neither increment_result nor place_result returned a success, so we return a failure.
	return null
	

## Attempts to increment the item stack at slot_coord. Returns null if the stack cannot be incremented (either if at max, doesn't exist, or grid does not support stacking) and an item Resource with the remaining stack amount if it was able to stack. 
func increment_item_stack(slot_coord: Vector2i, item: Resource, max_stack_amount: int = -1) -> Resource:
	if !self.stacking_allowed: return null
	if slot_coord not in slots.keys(): return null
	
	var slot_item_slot: InventorySlot = slots[slot_coord].stored_item_parent
	
	# We should never reach this, this is a failsafe or if this is called manually.
	if !slot_item_slot: return null
	
	var slot_item: Resource = slot_item_slot.stored_item
	
	if !InventoryItemHandler.is_stackable(slot_item, item): return null
	if slot_item.inventory_stack_size >= slot_item.inventory_max_stack_size: return null
	
	# Get lesser between amount in item_ghost and amount until target reaches max_stack_size.
	var amount_to_be_stacked: int = min(
		item.inventory_stack_size, 
		slot_item.inventory_max_stack_size - slot_item.inventory_stack_size
	)
	if max_stack_amount != -1: amount_to_be_stacked = min(max_stack_amount, amount_to_be_stacked)
	
	var new_slot_item: Resource = slot_item.duplicate()
	new_slot_item.inventory_stack_size += amount_to_be_stacked
	slot_item_slot.stored_item = new_slot_item
	item.inventory_stack_size -= amount_to_be_stacked
	
	return item


## Attempts to place the item at the slot coord. Returns null if it can't be placed there and an item Resource with stack amount == 0 if it was able to be placed.
func place_item(slot_coord: Vector2i, item: Resource, max_stack_amount: int = -1) -> Resource:
	if !is_item_in_bounds(slot_coord, item): return null
	if len(get_intersecting_item_slots(slot_coord, item)) != 0: return null
	
	var amount_in_placed_stack: int = item.inventory_stack_size
	if !stacking_allowed: amount_in_placed_stack = min(1, amount_in_placed_stack)
	if max_stack_amount != -1: amount_in_placed_stack = min(amount_in_placed_stack, max_stack_amount)
	
	var remaining_in_item: int = item.inventory_stack_size - amount_in_placed_stack
	
	var new_item = item.duplicate()
	new_item.inventory_stack_size = amount_in_placed_stack
	
	var target_slot: InventorySlot = slots[slot_coord]
	target_slot.stored_item = new_item
	update_all_stored_item_parents()
	
	var original_item = item.duplicate()
	original_item.inventory_stack_size = remaining_in_item
	
	return original_item
	
	
## Removes the item or some amount of items from the slot coord and returns it.
func remove_item(slot_coord: Vector2i, max_stack_amount: int = -1, get_half: bool = false) -> Resource:
	if slot_coord not in slots.keys(): return null
	if !slots[slot_coord].stored_item_parent: return null
	
	var item: Resource = slots[slot_coord].stored_item_parent.stored_item
	
	var amount_to_be_removed: int = item.inventory_stack_size
	if get_half: amount_to_be_removed = ceil(amount_to_be_removed / 2.0)
	if max_stack_amount != -1: amount_to_be_removed = min(amount_to_be_removed, max_stack_amount)
	var remaining_amount: int = item.inventory_stack_size - amount_to_be_removed
	
	if remaining_amount <= 0: slots[slot_coord].stored_item_parent.stored_item = null
	else: 
		var new_item: Resource = item.duplicate()
		new_item.inventory_stack_size = remaining_amount
		slots[slot_coord].stored_item_parent.stored_item = new_item
	
	update_all_stored_item_parents()
	
	item.inventory_stack_size = amount_to_be_removed
	return item
