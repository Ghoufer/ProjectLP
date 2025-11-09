extends Resource
class_name AttackData

enum AttackType { LIGHT, HEAVY, SPECIAL }

@export var attack_name : String
@export var windup_time : float
@export var attack_time : float
@export var recovery_time : float
@export var stamina_cost : int
@export var attack_range : float
@export var attack_damage : float
@export var animation_name : String
@export var attack_type : AttackType
@export var forward_push : float

func get_total_duration() -> float:
	return windup_time + attack_time + recovery_time
