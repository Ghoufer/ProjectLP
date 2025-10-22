@tool
extends Node

const item_paths : Dictionary = {
	"normal_rock": preload("res://assets/models/items/supplies/normal_rock/normal_rock.tscn"),
	"wooden_stick": preload("res://assets/models/items/supplies/wooden_stick/wooden_stick.tscn"),
	"wood_sword": preload("res://assets/models/items/weapons/wood_sword.tscn"),
	"gold_bar": preload("res://assets/models/items/supplies/gold_bar.tscn")
}

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
	
