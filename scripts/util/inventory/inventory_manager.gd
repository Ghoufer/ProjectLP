extends Node
class_name InventoryManager

@onready var inventory_uis: Control = %Inventories
@onready var swap_slot: ItemSlot = %SwapSlot
@onready var background_panel: PanelContainer = %BackgroundPanel

@export var inventory_containers : Array[InventoryContainer]

signal update_hotbar_ui(new_hotbar)
signal update_backpack_ui(new_backpack)

var is_inventory_open : bool = false
var items_to_add : Array = []
var is_inventory_busy : bool = false
var swap_slot_offset : Vector2

const WOOD_SWORD = preload("uid://4wqbg2sjpasx")
const NORMAL_ROCK = preload("uid://cx0n2fowyu0ks")
const WOODEN_STICK = preload("uid://bp1gedcb3e0fb")

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
			
			inventory_uis.add_child.call_deferred(container_ui)
			container.update_container.emit.call_deferred(container)
	swap_slot_offset = Vector2(0, -swap_slot.custom_minimum_size.y / 2)
	

func _process(_delta: float) -> void:
	if swap_slot.visible:
		swap_slot.position = get_viewport().get_mouse_position() + swap_slot_offset
	
	if not is_inventory_busy and items_to_add.size() > 0:
		is_inventory_busy = true
		
		if items_to_add.front() is Item:
			if not items_to_add.front().player_dropped == self.get_owner():
				add_new_stack(items_to_add.front())
		else:
			add_new_stack(items_to_add.front())
		
		is_inventory_busy = false
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			if swap_slot.stack: put_stack_back()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		is_inventory_open = not is_inventory_open
		background_panel.visible = is_inventory_open
		
		for container in inventory_containers:
			if container.can_toggle:
				container.toggle_ui.emit(is_inventory_open)
	

func _on_background_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if is_inventory_open and swap_slot.stack:
				Global.spawn_item(swap_slot.stack, self.get_owner(), true)
				clear_swap_slot()
	

func _on_slot_clicked(event: InputEvent, slot_index: int, container_id: String, clicked_stack: ItemStack) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			handle_change_slot(slot_index, container_id, clicked_stack)
	

func _on_pickup_area_body_entered(body: Item) -> void:
	if body.auto_pickup:
		items_to_add.push_front(body)
	

func _on_pickup_area_body_exited(body: Item) -> void:
	items_to_add.erase(body)
	

func _on_interaction_ray_interacted(body: Item) -> void:
	items_to_add.push_front(body)
	

#region -> Manager functions
func clear_swap_slot() -> void:
	swap_slot.visible = false
	swap_slot.stack = null
	

## Called when player closes inventory but was holding an item
func put_stack_back() -> void:
	items_to_add.push_front(swap_slot.stack)
	

func handle_change_slot(slot_index: int, container_id: String, stack_to_swap: ItemStack) -> void:
	## This is gonna get the index of the container in inventory_containers
	var which_container : int = inventory_containers.find_custom(
		func find_container(container: InventoryContainer):
			return container_id == container.resource_scene_unique_id
	)
	var container_to_update : InventoryContainer = inventory_containers[which_container]
	
	if not swap_slot.stack:
	## Take the item from slot clicked
		swap_slot.stack = stack_to_swap
		stack_to_swap = null
	elif not stack_to_swap and swap_slot.stack:
	## Put held item into empty clicked slot
		stack_to_swap = swap_slot.stack
		clear_swap_slot()
	else:
		## Check if clicked on equal item
		if stack_to_swap.item_data == swap_slot.stack.item_data:
			var quantity_sum : int = stack_to_swap.quantity + swap_slot.stack.quantity
			if stack_to_swap.item_data.max_stack != 1:
				## If items can be stacked, add the amount that was held
				if quantity_sum > stack_to_swap.item_data.max_stack:
					## If the total sum is higher than max stack, subtract held item quantity
					stack_to_swap.quantity = stack_to_swap.item_data.max_stack
					swap_slot.stack.quantity = quantity_sum - stack_to_swap.item_data.max_stack
				else:
					## Add the amount that was being held
					stack_to_swap.quantity = quantity_sum
					clear_swap_slot()
		else:
			## Clicked on a different item that was being held, so swap them
			var temp : ItemStack = stack_to_swap
			stack_to_swap = swap_slot.stack
			swap_slot.stack = temp
	
	container_to_update.slots[slot_index] = stack_to_swap
	container_to_update.update_container.emit(container_to_update)
	
	swap_slot.visible = true
	

func check_inventory_full(stack_to_check: ItemStack) -> bool:
	var all_slots: Array[ItemStack] = []
	
	for container in inventory_containers:
		all_slots += container.slots
	
	if find_first_empty(all_slots) != -1: return false
	
	for stack in all_slots:
		if stack.item_data == stack_to_check.item_data:
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

func add_new_stack(new_stack: Variant) -> void:
	var body : Node3D = null
	
	if new_stack is Item:
		body = new_stack
		new_stack = new_stack.stack
	
	if check_inventory_full(new_stack):
		is_inventory_busy = false
		if not is_inventory_open and swap_slot.stack:
			Global.spawn_item(new_stack, self.get_owner())
			items_to_add.erase(items_to_add.front())
			clear_swap_slot()
			return
	
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
	
	if leftover_quantity != 0:
		for container in inventory_containers:
			var available_slot_index : int = find_first_empty(container.slots)
			if available_slot_index > -1:
				leftover_quantity = 0
				container.slots[available_slot_index] = new_stack
				container.update_container.emit(container)
				break
	
	is_inventory_busy = false
	
	if leftover_quantity == 0:
		if body:
			body.create_pickup_animation(get_owner().global_position)
		items_to_add.erase(items_to_add.front())
		if not body:
			clear_swap_slot()
		return
	
	## leftover_quantity != 0
	if not check_inventory_full(new_stack):
		Global.spawn_item(new_stack, self.get_owner())
		items_to_add.erase(items_to_add.front())
		if not body:
			clear_swap_slot()
		return
	
	## Inventory full and leftover_quantity != 0
	if body:
		if initial_quantity != leftover_quantity:
			body.create_fraction_pickup_animation(get_owner().global_position)
	else:
		if not is_inventory_open and swap_slot.stack:
			Global.spawn_item(new_stack, self.get_owner())
			items_to_add.erase(items_to_add.front())
			clear_swap_slot()
			return
	

func try_to_add_to_inventory(leftover_quantity: int, stack_to_add: ItemStack, container: Array[ItemStack]) -> int:
	var available_slot_index : int
	var item_path : String = stack_to_add.item_data.item_path
	
	available_slot_index = find_available_slot(container, item_path)
	
	while(available_slot_index > -1):
		leftover_quantity = try_to_add_stack(leftover_quantity, available_slot_index, container)
		if leftover_quantity != 0:
			available_slot_index = find_available_slot(container, item_path)
		else: available_slot_index = -1
	
	return leftover_quantity

func try_to_add_stack(leftover_quantity: int, available_slot_index: int, container: Array[ItemStack]) -> int:
	var max_stack : int = container[available_slot_index].item_data.max_stack
	var quantity_sum : int = leftover_quantity + container[available_slot_index].quantity
	
	if quantity_sum <= max_stack:
		leftover_quantity = 0
		container[available_slot_index].quantity = quantity_sum
	else:
		## Found but not enough space
		leftover_quantity  = abs(quantity_sum - max_stack)
		container[available_slot_index].quantity = max_stack
		
	return leftover_quantity
#endregion
