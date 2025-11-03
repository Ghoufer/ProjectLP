extends Resource
class_name Combo

@export var combo_name : String = ''
@export var attacks : Array[AttackData] = [] ## The series of attacks in the combo
@export var combo_window : float = 0.0
@export var damage_multiplier : Array[float] = []

func get_damage_multiplier(attack_index: int) -> float:
	if damage_multiplier.is_empty():
		return 1.0
	return damage_multiplier[min(attack_index, damage_multiplier.size() - 1)]
