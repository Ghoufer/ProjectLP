@tool
extends Resource
class_name InventoryContainer

const INITIAL_MAX_SLOTS : int = 9

@export var container_name : String = ""
@export var container_size : int = INITIAL_MAX_SLOTS
@export var can_toggle : bool = false
@export var slots : Array[ItemStack] = []
@export var ui : PackedScene

signal toggle_ui(value: bool)
signal add_slots(count: int, _on_slot_clicked: Callable)
signal update_container(container: InventoryContainer, updated_slots: Array[ItemStack])
