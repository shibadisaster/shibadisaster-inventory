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
