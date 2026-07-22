extends PanelContainer
class_name InventorySlot


var parent_grid: InventoryGrid
var slot_coord: Vector2i

var stored_item: Resource = null
var stored_item_parent: InventorySlot = null

var visual_hover_factor: float = 0.0
var visual_hover_time: float = 0.05


func _ready() -> void:
	#print(parent_grid.inventory_grid_id, slot_coord)
	pass
	
	
func _process(delta: float) -> void:
	update_is_hovered(delta)
	update_visuals()


func update_visuals() -> void:
	if stored_item: 
		$CenterContainer/TextureRect.texture = InventoryItemHandler.extract_item_texture(self.stored_item)
		$CenterContainer/TextureRect.offset_transform_rotation = deg_to_rad(InventoryItemHandler.extract_item_rotation(self.stored_item))
	else: $CenterContainer/TextureRect.texture = null
	
	if stored_item_parent: self.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else: self.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _on_mouse_entered() -> void:
	InventoryManager.slot_hovered(self)


func update_is_hovered(delta: float) -> void:
	if InventoryManager.hovered_slot == self: 
		visual_hover_factor = move_toward(visual_hover_factor, 1.0, delta / visual_hover_time)
		#$HoveredUnderlay.visible = true
	else:
		visual_hover_factor = move_toward(visual_hover_factor, 0.0, delta / visual_hover_time)
		#$HoveredUnderlay.visible = false
	
	if true: $HoveredUnderlay.modulate = Color(1.0, 1.0, 1.0, visual_hover_factor)


func _on_mouse_exited() -> void:
	InventoryManager.slot_unhovered(self)
