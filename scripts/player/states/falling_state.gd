extends PlayerState

var friction : float = 0.2

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	player.animation_player.play('Fall', player.animation_blend)
	

func _physics_update(_delta: float) -> void:
	if not player.is_on_floor():
		player.update_movement(_delta)
	
	if player.is_on_floor():
		player.animation_player.play('Jump_Land')
		
		if not player.movement_input:
			finished.emit(states.find_key(states.IDLE))
		elif Input.is_action_pressed("sprint"):
			finished.emit(states.find_key(states.SPRINTING))
		else:
			finished.emit(states.find_key(states.MOVING))
	
	player.move_and_slide()
	
