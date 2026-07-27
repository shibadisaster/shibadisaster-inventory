extends TextureRect
class_name InventoryItemGhost


var stored_item: Resource

var depleted: bool = false
var depletion_animation_started: bool = false
var target_for_depleted_move: InventorySlot = null


func _process(delta: float) -> void:
	if !depleted: update_positioning(delta)
	update_visuals()
	update_depletion(delta)


func update_visuals() -> void:
	$".".texture = InventoryItemHandler.extract_item_texture(stored_item)
	var stack_size: int = InventoryItemHandler.extract_item_stack_size(stored_item)
	if stack_size == 1: $MarginContainer/Label.text = ""
	else: $MarginContainer/Label.text = str(stack_size)


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


func update_depletion(delta: float) -> void:
	if stored_item.inventory_stack_size <= 0: depleted = true
	
		
func start_depletion_animation() -> void:
	if depleted and target_for_depleted_move:
		var depletion_tween: Tween = get_tree().create_tween()
		depletion_tween.tween_property(
			self, 
			"global_position", 
			target_for_depleted_move.global_position + Vector2(
				target_for_depleted_move.parent_grid.inventory_slot_size / 2.0,
				target_for_depleted_move.parent_grid.inventory_slot_size / 2.0
			), 
			0.1
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		depletion_tween.tween_callback(self.queue_free)
		

func _on_timer_timeout() -> void:
	self.queue_free()
