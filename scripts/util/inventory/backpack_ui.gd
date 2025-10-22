extends Node

@onready var h_flow_container: HFlowContainer = %HFlowContainer

const SLOT : PackedScene = preload("res://scenes/UI/slot.tscn")

var inventory : InventoryData = InventoryData.new()

func _ready() -> void:
	for i in inventory.BACKPACK_SIZE:
		var instance : Node = SLOT.instantiate()
		h_flow_container.add_child(instance)
	

func _on_backpack_update_ui(backpack: Array[ItemStack]) -> void:
	var slots : Array[Node] = h_flow_container.get_children()
	
	if backpack.size() > 0:
		inventory.backpack = backpack
		
		for index in inventory.BACKPACK_SIZE:
			if inventory.backpack[index]:
				slots[index].stack = inventory.backpack[index]
	
