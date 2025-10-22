extends Resource
class_name InventoryData

const HOTBAR_SIZE : int = 9
const BACKPACK_SIZE : int = 27

@export var hotbar : Array[ItemStack] = []
@export var backpack : Array[ItemStack] = []

func _init() -> void:
	update_info()
	

func update_info() -> void:
	hotbar.resize(HOTBAR_SIZE)
	backpack.resize(BACKPACK_SIZE)
	
