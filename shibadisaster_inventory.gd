@tool
extends EditorPlugin


func _enable_plugin() -> void:
	add_autoload_singleton("InventoryManager", "./inventory_manager.tscn")
	add_autoload_singleton("InventoryItemHandler", "./inventory_item_handler.gd")
	

func _disable_plugin() -> void:
	remove_autoload_singleton("InventoryManager")
	remove_autoload_singleton("InventoryItemHandler")


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
