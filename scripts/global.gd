@tool
extends Node

# Debug panel
var debug: Variant

var player : CharacterBody3D

# Interaction variables
var interact_text: String

const item_paths : Dictionary = {
	"normal_rock": preload("res://assets/models/items/normal_rock/normal_rock.tscn"),
	"wooden_stick": preload("res://assets/models/items/wooden_stick/wooden_stick.tscn")
}

signal interact_text_changed(new_value)

func set_new_interact_text(value: String) -> void:
	interact_text = value
	interact_text_changed.emit(interact_text)
	
