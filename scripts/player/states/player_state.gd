extends State
class_name PlayerState

var player: Player

enum player_states { 
	IDLE, MOVING, 
	JUMPING, FALLING 
}

func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(
		player != null,
		"The PlayerState state type must be used only in the player scene. 
		It needs the owner to be a Player node."
	)
	
