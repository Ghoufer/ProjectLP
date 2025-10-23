extends Node
class_name InventoryManager

const ITEM = preload("res://resources/item/item.tscn")
const NORMAL_ROCK = preload("uid://cx0n2fowyu0ks")

signal update_hotbar_ui(new_hotbar)
signal update_backpack_ui(new_backpack)
signal toggle_inventory(value)

@export var inventory_data : InventoryData

var hotbar : Array[ItemStack] = []
var backpack : Array[ItemStack] = []
var is_inventory_full : bool = false
var is_inventory_open : bool = false
var leftover_quantity : int

func _ready() -> void:
	if inventory_data:
		hotbar = inventory_data.hotbar
		backpack = inventory_data.backpack
		
		update_hotbar_ui.emit(hotbar)
		update_backpack_ui.emit(backpack)
		Global.add_new_stack.connect(add_new_stack)
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		is_inventory_open = !is_inventory_open
		toggle_inventory.emit(is_inventory_open)
	

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
	

#region -> Manager functions
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

func add_new_stack(new_stack: ItemStack, body: Node3D) -> void:
	if is_inventory_full: return
	
	leftover_quantity = new_stack.quantity
	
	try_to_add_to_inventory(new_stack, hotbar, update_hotbar_ui)
	
	new_stack.quantity = leftover_quantity
	
	if leftover_quantity > 0:
		try_to_add_to_inventory(new_stack, backpack, update_backpack_ui)
	
	if leftover_quantity != 0:
		is_inventory_full = true
		respawn_item(new_stack, body)
	

func add_to_empty_slot(available_slot_index: int, new_stack: ItemStack, array: Array[ItemStack], ui_signal: Signal) -> int:
	array[available_slot_index] = new_stack
	ui_signal.emit(array)
	return 0

func try_to_add_stack(available_slot_index: int, array: Array[ItemStack], ui_signal: Signal) -> void:
	var max_stack : int = array[available_slot_index].item_data.max_stack
	var quantity_sum : int = leftover_quantity + array[available_slot_index].quantity
	
	if quantity_sum <= max_stack:
		array[available_slot_index].quantity = quantity_sum
		leftover_quantity = 0
		ui_signal.emit(array)
	else:
		## Found but not enough space
		array[available_slot_index].quantity = max_stack
		leftover_quantity  = abs(quantity_sum - max_stack)
		ui_signal.emit(array)

func try_to_add_to_inventory(stack_to_add: ItemStack, array: Array[ItemStack], update_signal: Signal) -> void:
	var available_slot_index : int
	var item_path : String = stack_to_add.item_data.item_path
	
	available_slot_index = find_available_slot(array, item_path)
	
	if available_slot_index > -1:
		try_to_add_stack(available_slot_index, array, update_signal)
		return
	
	available_slot_index = find_first_empty(array)
	
	if available_slot_index > -1:
		add_to_empty_slot(available_slot_index, stack_to_add, array, update_signal)
#endregion
