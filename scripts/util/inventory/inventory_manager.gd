extends Node
class_name InventoryManager

signal update_hotbar_ui(new_hotbar)
signal update_backpack_ui(new_backpack)
signal toggle_inventory(value)

@export var inventory_data : InventoryData

var hotbar : Array[ItemStack] = []
var backpack : Array[ItemStack] = []
var is_inventory_open : bool = false
var is_inventory_full : bool = false
var items_to_add : Array[Item] = []
var inventory_busy : bool = false

func _ready() -> void:
	if inventory_data:
		hotbar = inventory_data.hotbar
		backpack = inventory_data.backpack
		update_hotbar_ui.emit(hotbar)
		update_backpack_ui.emit(backpack)
		is_inventory_full = check_inventory_full()
	

func _process(_delta: float) -> void:
	if not is_inventory_full:
		if not inventory_busy and items_to_add.size() > 0:
			inventory_busy = true
			add_new_stack(items_to_add[0].item, items_to_add[0])
			items_to_add.erase(items_to_add[0])
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		is_inventory_open = !is_inventory_open
		toggle_inventory.emit(is_inventory_open)
	

func _on_pickup_area_body_entered(body: Node3D) -> void:
	if body.auto_pickup:
		items_to_add.append(body)
	

func _on_pickup_area_body_exited(body: Node3D) -> void:
	items_to_add.erase(body)
	

func _on_interaction_ray_interacted(body: Item) -> void:
	items_to_add.push_front(body)
	

#region -> Manager functions
func check_inventory_full() -> bool:
	var all_slots: Array[ItemStack] = hotbar + backpack
	
	if find_first_empty(all_slots): return false
	
	for stack in all_slots:
		if stack.quantity < stack.item_data.max_stack:
			return false
	return true

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

func add_new_stack(new_stack: ItemStack, body: Node3D) -> bool:
	var initial_quantity : int = new_stack.quantity
	var leftover_quantity : int = new_stack.quantity
	
	leftover_quantity = try_to_add_to_inventory(leftover_quantity, new_stack, hotbar, update_hotbar_ui)
	
	if leftover_quantity > 0:
		leftover_quantity = try_to_add_to_inventory(leftover_quantity, new_stack, backpack, update_backpack_ui)
	
	is_inventory_full = check_inventory_full()
	
	if leftover_quantity == initial_quantity:
		inventory_busy = false
		return false
	
	if leftover_quantity != 0:
		new_stack.quantity = leftover_quantity
		Global.spawn_item(new_stack, body)
	
	inventory_busy = false
	body.create_pickup_animation()
	
	return true

func try_to_add_to_inventory(leftover_quantity: int, stack_to_add: ItemStack, array: Array[ItemStack], update_signal: Signal) -> int:
	var available_slot_index : int
	var item_path : String = stack_to_add.item_data.item_path
	
	available_slot_index = find_available_slot(array, item_path)
	
	while(available_slot_index > -1):
		leftover_quantity = try_to_add_stack(leftover_quantity, available_slot_index, array, update_signal)
		if leftover_quantity != 0:
			available_slot_index = find_available_slot(array, item_path)
		else: available_slot_index = -1
	
	if leftover_quantity != 0:
		stack_to_add.quantity = leftover_quantity
		available_slot_index = find_first_empty(array)
		if available_slot_index > -1:
			leftover_quantity = 0
			array[available_slot_index] = stack_to_add
	
	update_signal.emit(array)
	
	return leftover_quantity

func try_to_add_stack(leftover_quantity: int, available_slot_index: int, array: Array[ItemStack], ui_signal: Signal) -> int:
	var max_stack : int = array[available_slot_index].item_data.max_stack
	var quantity_sum : int = leftover_quantity + array[available_slot_index].quantity
	
	if quantity_sum <= max_stack:
		leftover_quantity = 0
		array[available_slot_index].quantity = quantity_sum
		ui_signal.emit(array)
	else:
		## Found but not enough space
		leftover_quantity  = abs(quantity_sum - max_stack)
		array[available_slot_index].quantity = max_stack
		ui_signal.emit(array)
		
	return leftover_quantity
#endregion
