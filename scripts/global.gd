@tool
extends Node

# Debug panel
var debug: Variant

# Interaction variables
var interact_text: String

const item_paths : Dictionary = {
	"normal_rock": preload("res://assets/models/items/supplies/normal_rock/normal_rock.tscn"),
	"wooden_stick": preload("res://assets/models/items/supplies/wooden_stick/wooden_stick.tscn"),
	"wood_sword": preload("res://assets/models/items/weapons/wood_sword.tscn"),
}

signal interact_text_changed(new_value)

func set_new_interact_text(value: String) -> void:
	interact_text = value
	interact_text_changed.emit(interact_text)
	
