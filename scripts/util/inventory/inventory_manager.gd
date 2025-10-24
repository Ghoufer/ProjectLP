extends Node
class_name InventoryManager

@onready var inventories: Control = %Inventories
@onready var swap_slot: ItemSlot = %SwapSlot

@export var inventory_containers : Array[InventoryContainer]

signal update_hotbar_ui(new_hotbar)
signal update_backpack_ui(new_backpack)

var is_inventory_open : bool = false
var is_inventory_full : bool = false
var items_to_add : Array[Item] = []
var inventory_busy : bool = false
var swap_slot_offset : Vector2
var swap_slot_last_container : InventoryContainer
var swap_slot_container_index : int

func _ready() -> void:
	if inventory_containers.size() > 0:
		for container in inventory_containers:
			var container_ui : Node = container.ui.instantiate()
			
			container.slots.resize(container.container_size)
			
			container.toggle_ui.connect(container_ui.toggle_ui)
			container.add_slots.connect(container_ui.add_slots)
			container.update_container.connect(container_ui.update_container)
			
			container.add_slots.emit(container.container_size, _on_slot_clicked)
			container.update_container.emit.call_deferred(container)
			
			inventories.add_child.call_deferred(container_ui)
		is_inventory_full = check_inventory_full()
	swap_slot_offset = Vector2(0, -swap_slot.custom_minimum_size.y / 2)
	

func _process(_delta: float) -> void:
	if swap_slot.visible:
		swap_slot.position = get_viewport().get_mouse_position() + swap_slot_offset
		
	
	if not is_inventory_full:
		if not inventory_busy and items_to_add.size() > 0:
			inventory_busy = true
			add_new_stack(items_to_add[0].item, items_to_add[0])
			items_to_add.erase(items_to_add[0])
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			if swap_slot.stack: clear_swap_slot()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		is_inventory_open = not is_inventory_open
		
		for container in inventory_containers:
			if container.can_toggle:
				container.toggle_ui.emit(is_inventory_open)
	

func _on_slot_clicked(event: InputEvent, clicked_stack: ItemStack) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if clicked_stack:
				swap_slot.stack = clicked_stack
				swap_slot.visible = true
				find_clicked_stack(clicked_stack)
				
	

func clear_swap_slot() -> void:
	swap_slot.visible = false
	if swap_slot_last_container:
		for container in inventory_containers:
			if container.container_name == swap_slot_last_container.container_name:
				container.slots[swap_slot_container_index] = swap_slot.stack
				container.update_container.emit(swap_slot_last_container)
				break
	
	swap_slot.stack = null
	swap_slot_last_container = null
	

func _on_pickup_area_body_entered(body: Node3D) -> void:
	if body.auto_pickup:
		items_to_add.append(body)
	

func _on_pickup_area_body_exited(body: Node3D) -> void:
	items_to_add.erase(body)
	

func _on_interaction_ray_interacted(body: Item) -> void:
	items_to_add.push_front(body)
	

#region -> Manager functions
func check_inventory_full() -> bool:
	var all_slots: Array[ItemStack] = []
	
	for container in inventory_containers:
		all_slots += container.slots
	if find_first_empty(all_slots) != -1: return false
	
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

func find_clicked_stack(stack_to_find: ItemStack) -> void:
	for container in inventory_containers:
		var search : int = container.slots.find(stack_to_find)
		if search != -1:
			swap_slot_container_index = search
			swap_slot_last_container = container
			container.slots[search] = null
			container.update_container.emit.call_deferred(container)
			break
	

func add_new_stack(new_stack: ItemStack, body: Node3D) -> bool:
	var initial_quantity : int = new_stack.quantity
	var leftover_quantity : int = new_stack.quantity
	
	if new_stack.quantity > new_stack.item_data.max_stack:
		initial_quantity = new_stack.item_data.max_stack
		leftover_quantity = new_stack.item_data.max_stack
		new_stack.quantity = new_stack.item_data.max_stack
	
	for container in inventory_containers:
		if leftover_quantity > 0:
			leftover_quantity = try_to_add_to_inventory(leftover_quantity, new_stack, container.slots)
			container.update_container.emit(container)
	
	is_inventory_full = check_inventory_full()
	
	if leftover_quantity == initial_quantity:
		inventory_busy = false
		return false
	
	inventory_busy = false
	body.create_pickup_animation(get_owner().global_position)
	
	if leftover_quantity != 0:
		new_stack.quantity = leftover_quantity
		Global.spawn_item(new_stack, body)
	
	
	return true

func try_to_add_to_inventory(leftover_quantity: int, stack_to_add: ItemStack, array: Array[ItemStack]) -> int:
	var available_slot_index : int
	var item_path : String = stack_to_add.item_data.item_path
	
	available_slot_index = find_available_slot(array, item_path)
	
	while(available_slot_index > -1):
		leftover_quantity = try_to_add_stack(leftover_quantity, available_slot_index, array)
		if leftover_quantity != 0:
			available_slot_index = find_available_slot(array, item_path)
		else: available_slot_index = -1
	
	if leftover_quantity != 0:
		stack_to_add.quantity = leftover_quantity
		available_slot_index = find_first_empty(array)
		if available_slot_index > -1:
			leftover_quantity = 0
			array[available_slot_index] = stack_to_add
	
	return leftover_quantity

func try_to_add_stack(leftover_quantity: int, available_slot_index: int, array: Array[ItemStack]) -> int:
	var max_stack : int = array[available_slot_index].item_data.max_stack
	var quantity_sum : int = leftover_quantity + array[available_slot_index].quantity
	
	if quantity_sum <= max_stack:
		leftover_quantity = 0
		array[available_slot_index].quantity = quantity_sum
	else:
		## Found but not enough space
		leftover_quantity  = abs(quantity_sum - max_stack)
		array[available_slot_index].quantity = max_stack
		
	return leftover_quantity
#endregion
