extends Node

@onready var h_flow_container: HFlowContainer = %HFlowContainer

const SLOT : PackedScene = preload("uid://d0bcn8hlihb05")

var inventory : InventoryContainer = InventoryContainer.new()

func _ready() -> void:
	self.visible = false
	
	for i in inventory.container_size:
		var instance : Node = SLOT.instantiate()
		h_flow_container.add_child(instance)
	
	inventory.connect("container_updated", _on_container_updated)
	

func _on_container_updated(backpack: Array[ItemStack]) -> void:
	var slots : Array[Node] = h_flow_container.get_children()
	
	if backpack.size() > 0:
		inventory.slots = backpack
		print(backpack.size())
		for index in inventory.container_size:
			if inventory.slots[index]:
				slots[index].stack = inventory.slots[index]
	

func _on_inventory_manager_toggle_inventory(value: bool) -> void:
	self.visible = value
	
