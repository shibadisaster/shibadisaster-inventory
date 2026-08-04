extends MarginContainer


@export var inventory_grid: InventoryGrid
@export var scroll_time: float = 0.10
@export var scroll_speed: float = 400.0


@onready var left: Control = $LeftScroller
@onready var right: Control = $RightScroller
@onready var up: Control = $UpScroller
@onready var down: Control = $DownScroller

var left_hovered: bool = false
var right_hovered: bool = false
var up_hovered: bool = false
var down_hovered: bool = false

var left_scroll_timer: float = 0.0
var right_scroll_timer: float = 0.0
var up_scroll_timer: float = 0.0
var down_scroll_timer: float = 0.0

var left_scroll_current_speed: Vector2 = Vector2(0.0, 0.0)
var right_scroll_current_speed: Vector2 = Vector2(0.0, 0.0)
var up_scroll_current_speed: Vector2 = Vector2(0.0, 0.0)
var down_scroll_current_speed: Vector2 = Vector2(0.0, 0.0)


func _process(delta: float) -> void:
	if left_hovered: left_scroll_timer = move_toward(left_scroll_timer, scroll_time, delta)
	else: left_scroll_timer = 0.0
	
	if right_hovered: right_scroll_timer = move_toward(right_scroll_timer, scroll_time, delta)
	else: right_scroll_timer = 0.0
	
	if up_hovered: up_scroll_timer = move_toward(up_scroll_timer, scroll_time, delta)
	else: up_scroll_timer = 0.0
	
	if down_hovered: down_scroll_timer = move_toward(down_scroll_timer, scroll_time, delta)
	else: down_scroll_timer = 0.0
	
	if left_scroll_timer == scroll_time: 
		left_scroll_current_speed = lerp(left_scroll_current_speed, Vector2(-1.0, 0.0) * scroll_speed, 10.0 * delta)
	else: left_scroll_current_speed = lerp(left_scroll_current_speed, Vector2(0.0, 0.0) * scroll_speed, 20.0 * delta)
		
	if right_scroll_timer == scroll_time: 
		right_scroll_current_speed = lerp(right_scroll_current_speed, Vector2(1.0, 0.0) * scroll_speed, 10.0 * delta)
	else: right_scroll_current_speed = lerp(right_scroll_current_speed, Vector2(0.0, 0.0) * scroll_speed, 20.0 * delta)
	
	if up_scroll_timer == scroll_time: 
		up_scroll_current_speed = lerp(up_scroll_current_speed, Vector2(0.0, -1.0) * scroll_speed, 10.0 * delta)
	else: up_scroll_current_speed = lerp(up_scroll_current_speed, Vector2(0.0, 0.0) * scroll_speed, 20.0 * delta)
	
	if down_scroll_timer == scroll_time: 
		down_scroll_current_speed = lerp(down_scroll_current_speed, Vector2(0.0, 1.0) * scroll_speed, 10.0 * delta)
	else: down_scroll_current_speed = lerp(down_scroll_current_speed, Vector2(0.0, 0.0) * scroll_speed, 20.0 * delta)
	
	inventory_grid.move_offset(left_scroll_current_speed * delta)
	inventory_grid.move_offset(right_scroll_current_speed * delta)
	inventory_grid.move_offset(up_scroll_current_speed * delta)
	inventory_grid.move_offset(down_scroll_current_speed * delta)


func _on_left_scroller_mouse_entered() -> void: left_hovered = true
func _on_left_scroller_mouse_exited() -> void: left_hovered = false
func _on_right_scroller_mouse_entered() -> void: right_hovered = true
func _on_right_scroller_mouse_exited() -> void: right_hovered = false
func _on_up_scroller_mouse_entered() -> void: up_hovered = true
func _on_up_scroller_mouse_exited() -> void: up_hovered = false
func _on_down_scroller_mouse_entered() -> void: down_hovered = true
func _on_down_scroller_mouse_exited() -> void: down_hovered = false
