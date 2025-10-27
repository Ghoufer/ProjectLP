extends Resource
class_name Stats

const BASE_LEVEL_XP : float = 100.0
const STATS_CURVES : Dictionary[BuffableStats, Curve] = {
	BuffableStats.MAX_HEALTH: preload("uid://dhwleywts8a41"),
	BuffableStats.ATTACK: preload("uid://cbn26ak7la8c0"),
	BuffableStats.DEFENCE: preload("uid://b2uyuee83fwyc")
}

enum BuffableStats { MAX_HEALTH, ATTACK, DEFENCE, MOVES_SPEED }

@export var base_move_speed : float = 2.0
@export var base_max_health : int = 50
@export var base_attack : int = 10
@export var base_defence : int = 10
@export var experience : int = 0 : set = _on_experience_set

signal health_depleted
signal health_changed(cur_health: int, max_health: int)

var current_move_speed : float = 2.0
var current_max_health : int = 50
var current_attack : int = 10
var current_defence : int = 10
var current_health : int = 0 : set = _on_health_set
var level : int:
	get: return floor(max(1.0, sqrt(experience / BASE_LEVEL_XP) + 0.5))
var stat_buffs : Array[StatBuff]

func _init() -> void:
	setup_stats.call_deferred()
	

func setup_stats() -> void:
	recalculate_stats()
	current_health = current_max_health
	

func add_buff(buff: StatBuff) -> void:
	stat_buffs.append(buff)
	recalculate_stats.call_deferred()
	

func remove_buff(buff: StatBuff) -> void:
	stat_buffs.erase(buff)
	recalculate_stats.call_deferred()
	

func recalculate_stats() -> void:
	var stat_addens : Dictionary = {} ## Stats that will add
	var stat_multipliers : Dictionary = {} ## Stats that will multiply
	
	for buff in stat_buffs:
		var stat_name : String = BuffableStats.keys()[buff.stat].to_lower()
		
		match buff.buff_type:
			StatBuff.BuffType.ADD:
				if not stat_addens.has(stat_name):
					stat_addens[stat_name] = 0.0
				stat_addens[stat_name] += buff.buff_amount
			StatBuff.BuffType.MULTIPLY:
				if not stat_multipliers.has(stat_name):
					stat_multipliers[stat_name] = 1.0
				stat_multipliers[stat_name] += buff.buff_amount
		
	
	var stat_sample_pos : float = (float(level) / 100.0) - 0.01
	@warning_ignore("narrowing_conversion")
	current_max_health = base_max_health * STATS_CURVES[BuffableStats.MAX_HEALTH].sample(stat_sample_pos)
	@warning_ignore("narrowing_conversion")
	current_attack = base_attack * STATS_CURVES[BuffableStats.ATTACK].sample(stat_sample_pos)
	@warning_ignore("narrowing_conversion")
	current_defence = base_defence * STATS_CURVES[BuffableStats.DEFENCE].sample(stat_sample_pos)
	
	for stat_name in stat_addens:
		var cur_prop_name : String = str("current_" + stat_name)
		set(cur_prop_name, get(cur_prop_name) + stat_addens[stat_name])
	
	for stat_name in stat_multipliers:
		var cur_prop_name : String = str("current_" + stat_name)
		set(cur_prop_name, get(cur_prop_name) * stat_multipliers[stat_name])
	

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
	
