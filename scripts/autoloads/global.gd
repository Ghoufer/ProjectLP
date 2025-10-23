extends Node

const ITEM = preload("res://resources/item/item.tscn")

# Debug panel
var debug: Variant

# Interaction variables
var interaction_ray_collided : bool = false
signal set_interaction_ray_collided(new_value : bool)

signal add_new_stack(new_stack: ItemStack)

func _init() -> void:
	connect("set_interaction_ray_collided", change_interaction_ray_collided)
	

func change_interaction_ray_collided(value: bool) -> void:
	interaction_ray_collided = value
	

func respawn_item(new_stack: ItemStack, body: Node3D) -> void:
	var items_node = get_tree().get_first_node_in_group("Items")
	if items_node:
		var instance : Node = ITEM.instantiate()
		var throw_strength : float = 0.009
		var random_direction : Vector3 = Vector3(randf_range(-1.0, 1.0), body.global_position.y + 1.5, randf_range(-1.0, 1.0)).normalized()
		instance.item = new_stack
		instance.auto_pickup = true
		items_node.add_child(instance)
		instance.global_position = body.global_position + random_direction
		instance.apply_central_impulse(random_direction * throw_strength)
	
