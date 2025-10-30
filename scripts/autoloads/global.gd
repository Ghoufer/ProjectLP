extends Node

const ITEM = preload("res://scenes/item/item.tscn")

# Debug panel
var debug: Variant

func spawn_item(new_stack: ItemStack, body: Node3D, player_dropped: bool = false) -> void:
	var items_node = get_tree().get_first_node_in_group("Items")
	if items_node:
		var throw_direction : Vector3
		var throw_strength : float = 8.0
		var instance : Node = ITEM.instantiate()
		var height_offset : float = body.global_position.y + 0.7
		
		if player_dropped and body is Player:
			var visuals : Node3D = body.get_node("Visuals")
			throw_direction = -visuals.global_transform.basis.z
			instance.player_dropped = body
		else:
			throw_direction = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()
		
		instance.stack = new_stack
		instance.auto_pickup = true
		items_node.add_child(instance)
		instance.global_position = body.global_position
		instance.global_position.y = height_offset
		instance.apply_central_impulse(throw_direction * throw_strength)
	
