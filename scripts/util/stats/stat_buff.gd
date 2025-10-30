extends Resource
class_name StatBuff

enum BuffType {
	ADD,
	MULTIPLY,
	SUBTRACT,
	DIVIDE
}

@export var buff_amount : float
@export var buff_type : BuffType
@export var stat : Stats.BuffableStats

func _init(
	_buff_amount: float = 1.0, 
	_buff_type: StatBuff.BuffType = BuffType.MULTIPLY,
	_stat: Stats.BuffableStats = Stats.BuffableStats.MAX_HEALTH
) -> void:
	buff_amount = _buff_amount
	buff_type = _buff_type
	stat = _stat
	
