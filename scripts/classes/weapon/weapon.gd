extends Node3D
class_name Weapon

@export var weapon_data : WeaponData

@onready var hit_detection : Area3D = %HitDetection

var current_owner : Node3D = null
var is_equipped : bool = false

func _ready() -> void:
	if hit_detection:
		hit_detection.monitoring = false
	

func equip(new_owner: Node3D) -> void:
	current_owner = new_owner
	is_equipped = true
	
	if new_owner.has_node("WeaponAttachment"):
		get_parent().remove_child(self)
		new_owner.get_node("WeaponAttachment").add_child(self)
		global_transform = new_owner.get_node("WeaponAttachment").global_transform
	

func unequip() -> void:
	is_equipped = false
	current_owner = null
	

func get_combo_sequence(combo_index: int) -> Combo:
	if combo_index < weapon_data.combos.size():
		return weapon_data.combos[combo_index]
	return null

func start_attack() -> void:
	if hit_detection:
		hit_detection.monitoring = true
	

func end_attack() -> void:
	if hit_detection:
		hit_detection.monitoring = false
	

func modify_damage(new_damage: int) -> int:
	return weapon_data.base_damage + new_damage

func get_attack_speed_multiplier() -> float:
	return weapon_data.attack_speed
