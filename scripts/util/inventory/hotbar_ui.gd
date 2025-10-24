extends CanvasLayer

@onready var hotbar_container : HBoxContainer = %HotbarContainer

const SLOT : PackedScene = preload("res://scenes/UI/slot.tscn")

func update_container(inventory : InventoryContainer, hotbar: Array[ItemStack]) -> void:
	var ui_slots : Array[Node] = hotbar_container.get_children()
	
	if ui_slots.size() == 0:
		for i in inventory.container_size:
			var instance : Node = SLOT.instantiate()
			hotbar_container.add_child(instance)
	
	if hotbar.size() > 0:
		inventory.slots = hotbar
		for index in inventory.container_size:
			if inventory.slots[index]:
				ui_slots[index].stack = inventory.slots[index]
	
