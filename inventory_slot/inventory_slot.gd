extends PanelContainer
class_name InventorySlot



var parent_grid: InventoryGrid
var slot_coord: Vector2i

var stored_item: Resource = null
var stored_item_parent: InventorySlot = null
var previous_frame_stored_item_parent: InventorySlot = null

var visual_hover_factor: float = 0.0
var visual_hover_time: float = 0.10


func _ready() -> void:
	#print(parent_grid.inventory_grid_id, slot_coord)
	pass
	
	
func _process(delta: float) -> void:
	update_is_hovered(delta)
	update_visuals()
	previous_frame_stored_item_parent = stored_item_parent


func update_visuals() -> void:
	if stored_item: 
		$CenterContainer/TextureRect.texture = InventoryItemHandler.extract_item_texture(self.stored_item)
		$CenterContainer/TextureRect.offset_transform_rotation = deg_to_rad(InventoryItemHandler.extract_item_rotation(self.stored_item))
		var stack_size: int = InventoryItemHandler.extract_item_stack_size(stored_item)
		$MarginContainer/MarginContainer/StackSize.text = "" if stack_size == 1 else str(stack_size)
	else: 
		$CenterContainer/TextureRect.texture = null
		$MarginContainer/MarginContainer/StackSize.text = ""
	
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
	
	if true: $HoverUnderlay.modulate = Color(1.0, 1.0, 1.0, visual_hover_factor)


func _on_mouse_exited() -> void:
	InventoryManager.slot_unhovered(self)





@onready var square_borders: Dictionary[TextureRect, Array] = {
	$SquareBorders/TopAndTopRight/Edge: [Vector2i(0, -1)],
	$SquareBorders/TopAndTopRight/Corner: [Vector2i(1, -1), [Vector2i(0, -1), Vector2i(1, 0)]],
	$SquareBorders/RightAndBottomRight/Edge: [Vector2i(1, 0)],
	$SquareBorders/RightAndBottomRight/Corner: [Vector2i(1, 1), [Vector2i(1, 0), Vector2i(0, 1)]],
	$SquareBorders/BottomAndBottomLeft/Edge: [Vector2i(0, 1)],
	$SquareBorders/BottomAndBottomLeft/Corner: [Vector2i(-1, 1), [Vector2i(0, 1), Vector2i(-1, 0)]],
	$SquareBorders/LeftAndTopLeft/Edge: [Vector2i(-1, 0)],
	$SquareBorders/LeftAndTopLeft/Corner: [Vector2i(-1, -1), [Vector2i(-1, 0), Vector2i(0, -1)]]
}


func update_borders() -> void:
	if parent_grid.grid_type == parent_grid.GridType.SQUARE:
		$SquareBorders.visible = true
		for border in square_borders.keys():
			border.visible = true
			for offset in square_borders[border]:
				if offset is Vector2i: 
					var check_coord: Vector2i = slot_coord + offset
					if check_coord in parent_grid.slots.keys():
						border.visible = false
						break
				elif offset is Array:
					var check_coord_1: Vector2i = slot_coord + offset[0]
					var check_coord_2: Vector2i = slot_coord + offset[1]
					if (check_coord_1 in parent_grid.slots.keys()) != (check_coord_2 in parent_grid.slots.keys()):
						border.visible = false
						break


func set_background(background_tex: Texture2D, background_tex_modulate: Color) -> void:
	if background_tex: $Background.texture = background_tex
	if background_tex_modulate: $Background.modulate = background_tex_modulate
	

func set_hover_appearance(hover_tex: Texture2D, hover_tex_modulate: Color) -> void:
	if hover_tex: $HoverUnderlay.texture = hover_tex
	if hover_tex_modulate: $HoverUnderlay.modulate = hover_tex_modulate
