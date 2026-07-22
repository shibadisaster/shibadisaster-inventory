extends TextureRect
class_name ItemGhost


var stored_item: Resource


func _process(delta: float) -> void:
	update_positioning(delta)


func update_visuals() -> void:
	$".".texture = InventoryItemHandler.extract_item_texture(stored_item)


func update_positioning(delta: float) -> void:
	self.set_global_position(
		lerp(
			self.global_position,
			get_global_mouse_position(),
			40.0 * delta
		)
	)
	$".".offset_transform_rotation = lerp_angle(
		$".".offset_transform_rotation,
		deg_to_rad(InventoryItemHandler.extract_item_rotation(stored_item)),
		20.0 * delta
	)
	

func initial_positioning(slot: InventorySlot) -> void:
	self.set_global_position(
		slot.global_position + 
		Vector2(
			slot.parent_grid.inventory_slot_size / 2.0, slot.parent_grid.inventory_slot_size / 2.0
		)
	)
	$".".offset_transform_rotation = deg_to_rad(InventoryItemHandler.extract_item_rotation(stored_item))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("InventoryRotate"):
		stored_item = InventoryItemHandler.rotate_item(stored_item)
