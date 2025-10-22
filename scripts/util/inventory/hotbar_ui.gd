extends CanvasLayer

@onready var hotbar_container : HBoxContainer = %HotbarContainer

const SLOT : PackedScene = preload("res://scenes/UI/slot.tscn")

var inventory : InventoryData = InventoryData.new()

func _ready() -> void:
	for i in inventory.HOTBAR_SIZE:
		var instance : Node = SLOT.instantiate()
		hotbar_container.add_child(instance)
	

func _on_hotbar_update_ui(hotbar: Array[ItemStack]) -> void:
	var slots : Array[Node] = hotbar_container.get_children()
		
	if hotbar.size() > 0:
		inventory.hotbar = hotbar
		for index in inventory.HOTBAR_SIZE:
			if inventory.hotbar[index]:
				slots[index].stack = inventory.hotbar[index]
	
