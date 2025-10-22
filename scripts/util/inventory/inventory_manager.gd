extends Node
class_name InventoryManager

const ITEM = preload("res://resources/item/item.tscn")
const NORMAL_ROCK = preload("uid://cx0n2fowyu0ks")

signal update_hotbar_ui(new_hotbar)
signal update_backpack_ui(new_backpack)

@export var inventory_data : InventoryData

var hotbar : Array[ItemStack] = []
var backpack : Array[ItemStack] = []
var is_inventory_full : bool = false

func _ready() -> void:
	if inventory_data:
		hotbar = inventory_data.hotbar
		backpack = inventory_data.backpack
		
		update_hotbar_ui.emit(hotbar)
		update_backpack_ui.emit(backpack)
		Global.add_new_stack.connect(add_new_stack)
	

func add_new_stack(new_stack: ItemStack, body: Node3D) -> void:
	var leftover_quantity : int = new_stack.quantity
	var max_stack : int = new_stack.item_data.max_stack
	var item_path : String = new_stack.item_data.item_path
	var hotbar_item_index : int = find_available_slot(hotbar, item_path)
	var first_empty_hotbar_index : int = find_first_empty(hotbar)
	var first_empty_backpack_index : int = find_first_empty(backpack)
	var quantity_sum : int
	
	if is_inventory_full: return
	
	## Try to find item in hotbar first
	if hotbar_item_index > -1:
		quantity_sum = new_stack.quantity + hotbar[hotbar_item_index].quantity
		
		if quantity_sum <= max_stack:
			hotbar[hotbar_item_index].quantity = quantity_sum
			update_hotbar_ui.emit(hotbar)
		else:
			## Found but not enough space
			leftover_quantity  = abs(quantity_sum - max_stack)
			new_stack.quantity = leftover_quantity
			hotbar[hotbar_item_index].quantity = max_stack
			
			update_hotbar_ui.emit(hotbar)
	
	## Try to find item in backpack
	var backpack_item_index : int = find_available_slot(backpack, item_path)
	
	if backpack_item_index > -1:
		quantity_sum = new_stack.quantity + backpack[backpack_item_index].quantity
		
		if quantity_sum <= max_stack:
			backpack[backpack_item_index].quantity = quantity_sum
			update_backpack_ui.emit(backpack)
		else:
			## Found but not enough space
			leftover_quantity  = abs(quantity_sum - max_stack)
			new_stack.quantity = leftover_quantity
			backpack[backpack_item_index].quantity = max_stack
			
			update_backpack_ui.emit(backpack)
	
	if first_empty_hotbar_index > -1:
		leftover_quantity = 0
		hotbar[first_empty_hotbar_index] = new_stack
		update_hotbar_ui.emit(hotbar)
	
	if first_empty_backpack_index > -1:
		leftover_quantity = 0
		backpack[first_empty_backpack_index] = new_stack
		update_backpack_ui.emit(backpack)
	
	if leftover_quantity != 0:
		is_inventory_full = true
		respawn_item(new_stack, body)
	

func respawn_item(new_stack: ItemStack, body: Node3D) -> void:
	var items_node = get_tree().get_first_node_in_group("Items")
	if items_node:
		var instance : Node = ITEM.instantiate()
		var throw_strength : float = 0.007
		var random_direction : Vector3 = Vector3(randf_range(-1.0, 1.0), body.global_position.y + 1.5, randf_range(-1.0, 1.0)).normalized()
		instance.item = new_stack
		instance.auto_pickup = true
		items_node.add_child(instance)
		instance.global_position = body.global_position + random_direction
		instance.apply_central_impulse(random_direction * throw_strength)
	

#region -> Helper functions
func find_first_empty(array: Array[ItemStack]) -> int:
	return array.find(null)
	

func find_available_slot(array: Array[ItemStack], item_path: String) -> int:
	for index in range(array.size()):
		if array[index]:
			var quantity : int = array[index].quantity
			var max_stack : int =  array[index].item_data.max_stack
			if item_path == array[index].item_data.item_path and quantity < max_stack:
				return index
	return -1
#endregion
