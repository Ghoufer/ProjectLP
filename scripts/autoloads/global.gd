@tool
extends Node

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
	
