extends Node

const ITEM = preload("res://resources/item/item.tscn")

# Debug panel
var debug: Variant

func spawn_item(new_stack: ItemStack, body: Node3D, player_dropped: bool = false) -> void:
	var items_node = get_tree().get_first_node_in_group("Items")
	if items_node:
		var instance : Node = ITEM.instantiate()
		var throw_strength : float = 0.01
		var random_direction : Vector3 = Vector3(randf_range(-1.0, 1.0), body.global_position.y + 1.5, randf_range(-1.0, 1.0)).normalized()
		
		if player_dropped:
			instance.player_dropped = body
		
		instance.stack = new_stack
		instance.auto_pickup = true
		items_node.add_child(instance)
		instance.global_position = body.global_position + random_direction
		instance.apply_central_impulse(random_direction * throw_strength)
	
