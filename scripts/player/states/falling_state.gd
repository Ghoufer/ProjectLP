extends PlayerState

var friction : float = 0.2

func _physics_update(_delta: float) -> void:
	if not player.is_on_floor():
		player.update_movement(_delta)
		player.velocity.y -= player.gravity * _delta
	else:
		finished.emit(states.find_key(states.IDLE))
	
	player.move_and_slide()
	
