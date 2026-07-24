extends TextureRect
class_name InventoryProjectionGhost


var target_slot: InventorySlot
var stored_item: Resource
var valid_placement: bool = true
var replaceable_placement: bool = false

var stored_item_rotation: int

var fading_out: bool = false
var fade_timer: float = 0.0

const FADE_DURATION: float = 0.25


func _process(delta: float) -> void:
	update_position(delta)
	update_validity()
	
	if fading_out: fade_out(delta)
	else: fade_in(delta)
	
	var fade_progress: float = 1.0 - (fade_timer / FADE_DURATION)
	self.material.set_shader_parameter("fading", fade_progress)


func update_position(delta: float) -> void:
	if true:
		self.set_position(
			lerp(
				self.position,
				get_target_position(),
				20.0 * delta
			)
		)
		
		$".".offset_transform_rotation = lerp_angle(
			self.offset_transform_rotation,
			deg_to_rad(stored_item_rotation),
			20.0 * delta
		)
	
	if false:
		self.set_position(get_target_position())
		$".".offset_transform_rotation = deg_to_rad(stored_item_rotation)
	
	
func initial_position() -> void:
	self.set_position(get_target_position())
	stored_item_rotation = InventoryItemHandler.extract_item_rotation(stored_item)
	$".".offset_transform_rotation = deg_to_rad(stored_item_rotation)


func get_target_position() -> Vector2:
	var cell_center: Vector2 = Vector2(target_slot.parent_grid.inventory_slot_size / 2.0, target_slot.parent_grid.inventory_slot_size / 2.0)
	return target_slot.position + cell_center


func update_visuals() -> void:
	$".".texture = InventoryItemHandler.extract_item_texture(stored_item)
	stored_item_rotation = InventoryItemHandler.extract_item_rotation(stored_item)
	$".".offset_transform_rotation = deg_to_rad(stored_item_rotation)
	


func update_validity() -> void:
	if valid_placement: self.material.set_shader_parameter("valid", 0)
	else:
		if replaceable_placement: self.material.set_shader_parameter("valid", 1)
		else: self.material.set_shader_parameter("valid", 2)
	
	if valid_placement: modulate = Color.GREEN
	else: modulate = Color.RED
	
	
func fade_out(delta: float) -> void:
	fade_timer -= delta	
	if fade_timer < 0.0: self.queue_free()
	

func fade_in(delta: float) -> void:
	fade_timer = move_toward(fade_timer, FADE_DURATION, delta)
	
	
func reset_fade() -> void:
	fade_timer = 0.0
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("InventoryRotate"):
		stored_item_rotation = (stored_item_rotation + 90) % 360
