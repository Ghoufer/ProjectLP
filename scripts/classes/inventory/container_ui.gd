extends Control

@export var ui_node : Node

const SLOT : PackedScene = preload("uid://d0bcn8hlihb05")

func toggle_ui(value: bool) -> void:
	self.visible = value
	

func add_slots(count: int, _on_slot_clicked: Callable) -> void:
	for i in count:
		var instance : Node = SLOT.instantiate().duplicate()
		instance.connect("_on_slot_clicked", _on_slot_clicked)
		ui_node.add_child(instance)
	

func update_container(container : InventoryContainer) -> void:
	var ui_slots : Array[Node] = ui_node.get_children()
	
	if ui_slots.size() > 0:
		for index in container.container_size:
			ui_slots[index].slot_index = index
			ui_slots[index].container_id = container.resource_scene_unique_id
			
			if container.slots[index]:
				ui_slots[index].stack = container.slots[index]
			else:
				ui_slots[index].stack = null
	
	
