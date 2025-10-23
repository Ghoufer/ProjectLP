@tool
extends Resource
class_name ItemData

@export var item_name : String = ''
@export_multiline var description : String = ''
@export var max_stack : int = 999
@export var icon : AtlasTexture = preload("res://assets/icons/item_icons.tres")
@export var item_path : String

"""
Create a dropdown list to reference the object pool
that is stored in the Global script
"""
func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var paths := ItemPool.paths.keys()
	
	list.append({
		"name": "item_path",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(paths)
	})
	
	return list
	
