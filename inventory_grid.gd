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


# okay so there is no way around this i need to move all the helper funcs into here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# for sanity, 
#	ALL things relating to modifying stuff in an inventorygrid should go here (stacking, moving, removing, adding, etc)
# 	ALL things relating to exterior objs or those on a layer above inventorygrids (saving, loading, itemghost, user input, projectionghost) should go in inventorymanager


## Attempts to add an item anywhere they can fit, returning an inventory_stack_size == 0 item Resource if all in the item's stack were able to be added, null, an inventory_stack_size == (n - x) item Resource if it was able to stack some (x) but not all (n), and null if it couldn't fit anywhere.
func auto_add_item(item: Resource) -> Resource:
	return null


## Attempts to add an item to the specified slot_coord, returning an inventory_stack_size == 0 item Resource if all in the item's stack were able to be added, null, an inventory_stack_size == (n - x) item Resource if it was able to stack some (x) but not all (n), and null if it couldn't fit anywhere.
func add_item(slot_coord: Vector2i, item: Resource, amount: int = 1) -> Resource:
	return null
	

## Increments the item stack at slot_coord. Returns null if the stack cannot be incremented (either if at max or grid does not support stacking) and an item Resource with the remaining stack amount if it was able to stack. 
func increment_item_stack(slot_coord: Vector2i, item: Resource, amount: int = 1) -> Resource:
	return null


## Places the item at the slot coord. Returns null if it can't be placed there and an item Resource with stack amount == 0 if it was able to be placed.
func place_item(slot_coord: Vector2i, item: Resource, amount: int = 1) -> Resource:
	return null
	
	
## Removes the item from the slot coord and returns it.
func remove_item(slot_coord: Vector2i) -> Resource:
	return null
