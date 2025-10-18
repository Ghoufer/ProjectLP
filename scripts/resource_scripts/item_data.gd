@tool
extends Resource
class_name ItemData

@export var item_name : String = ''
@export_multiline var description : String = ''
@export var prompt_message : String
@export var stackable : bool = false
@export var icon : CompressedTexture2D
@export var stack_size : int
@export var current_stack : int
@export var usable : bool = false
@export var auto_pickup : bool = false
@export var item_type: types
@export var effect_value = 0
@export var item_path : String

enum types { Supply, Consumable }

func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var paths := Global.item_paths.keys()
	
	list.append({
		"name": "item_path",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(paths)
	})
	
	return list
	
