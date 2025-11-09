@tool
extends Resource
class_name ItemData

@export var item_name : String = ''
@export_multiline var description : String = ''
@export var max_stack : int = 999
@export var icon : AtlasTexture = preload("uid://di54m5clr2010")
@export var item_path : ItemPool.ITEMS
