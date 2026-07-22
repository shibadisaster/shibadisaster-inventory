extends Node


func extract_item_shape(item: Resource) -> Array[Vector2i]:
	var shape = item.get("inventory_shape")
	if shape and shape is Array[Vector2i]: return shape
	else: 
		print("[shibadisaster - Inventory] Item has no inventory_shape! Defaulting to [Vector2i.ZERO].")
		return [Vector2i.ZERO]


func extract_item_texture(item: Resource) -> Texture:
	var tex = item.get("inventory_texture")
	if tex and tex is Texture: return tex
	else: 
		print("[shibadisaster - Inventory] Item has no inventory_texture! Defaulting to fallback texture.")
		return load("res://addons/shibadisaster_inventory/sample_ninepatchrect.png")


func extract_item_rotation(item: Resource) -> int:
	var rot = item.get("inventory_rotation")
	if rot is int: return rot
	else:
		print("[shibadisaster - Inventory] Item has no inventory_rotation! Defaulting to 0 degrees.")
		return 0


func rotate_item(item: Resource) -> Resource:
	var shape: Array[Vector2i] = extract_item_shape(item)
	var rotation: int = extract_item_rotation(item)
	
	var new_item: Resource = item.duplicate()
	
	if item.get("inventory_shape") is Array[Vector2i]:
		var new_shape: Array[Vector2i] = []
		for cell in shape:
			new_shape.append(Vector2i(-cell.y, cell.x))
		new_item.inventory_shape = new_shape
			
	if item.get("inventory_rotation") is int:
		new_item.inventory_rotation = (rotation + 90) % 360
	
	return new_item
