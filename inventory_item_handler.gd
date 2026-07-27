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


func extract_item_id(item: Resource) -> String:
	var id = item.get("inventory_item_id")
	if id is String: return id
	else:
		print("[shibadisaster - Inventory] Item has no inventory_item_id! Defaulting to resource id.")
		return item.resource_name # TODO: figure this out


func is_stackable(item1: Resource, item2: Resource) -> bool:
	#print("Comparing ", item1.name, " to ", item2.name)
	var stacking_criteria: Array[String] = get_stacking_criteria_union(item1, item2) # Even though this should auto-return false if stacking_criteria is different? I didn't think about this that hard :333
	for criterion in stacking_criteria:
		var item1criterion := get_property(item1, criterion)
		var item2criterion := get_property(item2, criterion)
		#print("Checking criterion ", criterion, ", ", str(item1criterion), " vs. ", str(item2criterion))
		if item1criterion != item2criterion: return false
	return true
	
	
func get_stacking_criteria_union(item1: Resource, item2: Resource) -> Array[String]:
	var stacking_criteria_union: Array[String] = []
	for criterion in extract_item_stacking_criteria(item1):
		stacking_criteria_union.append(criterion)
	for criterion in extract_item_stacking_criteria(item2):
		if criterion not in stacking_criteria_union:
			stacking_criteria_union.append(criterion)
	return stacking_criteria_union


func extract_item_max_stack_size(item: Resource) -> int:
	var max_st_size = item.get("inventory_max_stack_size")
	if max_st_size is int: return max_st_size
	else:
		print("[shibadisaster - Inventory] Item has no inventory_max_stack_size! Defaulting to 1.")
		return 1
	

func extract_item_stack_size(item: Resource) -> int:
	var st_size = item.get("inventory_stack_size")
	if st_size is int: return st_size
	else:
		print("[shibadisaster - Inventory] Item has no inventory_stack_size! Defaulting to 1.")
		return 1

	
	
func extract_item_stacking_criteria(item: Resource) -> Array[String]:
	var st_crit = item.get("inventory_stacking_criteria")
	if st_crit and st_crit is Array[String]: return st_crit
	else:
		print("[shibadisaster - Inventory] Item has no inventory_stacking_criteria! Defaulting to only check inventory_shape and inventory_texture.")
		return ["inventory_shape", "inventory_texture"]


func get_property(item: Resource, property: String) -> Variant:
	if property == "inventory_shape": return extract_item_shape(item)
	if property == "inventory_texture": return extract_item_texture(item)
	if property == "inventory_rotation": return extract_item_rotation(item)
	if property == "inventory_item_id": return extract_item_id(item)
	if property == "inventory_max_stack_size": return extract_item_max_stack_size(item)
	if property == "inventory_stack_size": return extract_item_stack_size(item)
	if property == "inventory_stacking_criteria": return extract_item_stacking_criteria(item)
	return item.get(property)


func add_to_stack(item: Resource, amount: int) -> Resource:
	var stack_size: int = extract_item_stack_size(item)
	
	var new_item: Resource = item.duplicate()
	
	if item.get("inventory_stack_size") is int:
		var new_stack_size: int = stack_size + amount
		new_item.inventory_stack_size = new_stack_size
	
	return new_item
