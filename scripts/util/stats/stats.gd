extends Resource
class_name Stats

const BASE_LEVEL_XP : float = 100.0

enum BuffableStats { MAX_HEALTH, ATTACK, DEFENCE }

@export var base_max_health : int = 50
@export var base_attack : int = 10
@export var base_defence : int = 10
@export var experience : int = 0 : set = _on_experience_set

signal health_depleted
signal health_changed(cur_health: int, max_health: int)

var current_max_health : int = 50
var current_attack : int = 10
var current_defence : int = 10
var current_health : int = 0 : set = _on_health_set
var level : int:
	get: return floor(max(1.0, sqrt(experience / BASE_LEVEL_XP) + 0.5))

func _init() -> void:
	setup_stats.call_deferred()
	

func setup_stats() -> void:
	recalculate_stats()
	current_health = current_max_health
	

func recalculate_stats() -> void:
	pass

func _on_health_set(new_value: int) -> void:
	current_health = clampi(new_value, 0, current_max_health)
	
	health_changed.emit(current_health, current_max_health)
	
	if current_health <= 0:
		health_depleted.emit()
	

func _on_experience_set(new_value: int) -> void:
	var old_value : int = level
	
	experience = new_value
	
	if not old_value == level:
		recalculate_stats() 
	
