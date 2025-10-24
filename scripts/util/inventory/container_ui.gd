extends CanvasLayer

@export var ui_node : Node

const SLOT : PackedScene = preload("res://scenes/UI/slot.tscn")

func toggle_ui(value: bool) -> void:
	self.visible = value
	

func update_ui(count: int) -> void:
	for i in count:
		var instance : Node = SLOT.instantiate().duplicate()
		ui_node.add_child(instance)
	

func update_container(container : InventoryContainer) -> void:
	var ui_slots : Array[Node] = ui_node.get_children()
	
	if ui_slots.size() > 0:
		for index in container.container_size:
			if container.slots[index]:
				ui_slots[index].stack = container.slots[index]
	
