extends Node
class_name StatBuff

enum BuffType {
	ADD,
	MULTIPLY
}

@export var stat : Stats.BuffableStats
@export var buff_amount : float
@export var buff_type : BuffType

func _init(
	_buff_amount: float = 1.0, 
	_buff_type: StatBuff.BuffType = BuffType.MULTIPLY,
	_stat: Stats.BuffableStats = Stats.BuffableStats.MAX_HEALTH
) -> void:
	buff_amount = _buff_amount
	buff_type = _buff_type
	stat = _stat
	
