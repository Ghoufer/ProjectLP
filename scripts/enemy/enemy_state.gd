extends State
class_name EnemyState

var enemy : Enemy

enum states { 
	IDLE, PATROLLING,
	SEARCHING, CHASING,
	ATTACKING
}

func _ready() -> void:
	await owner.ready
	enemy = owner as Enemy
	assert(
		enemy != null,
		"The EnemyState state type must be used only in the enemy scene. 
		It needs the owner to be an Enemy node."
	)
	
