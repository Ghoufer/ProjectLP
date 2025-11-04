extends PlayerState

var roll_speed : float = 1.0

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	print(_previous_state_path)
	if _previous_state_path == states.find_key(states.SPRINTING).capitalize():
		roll_speed = player.stats.sprint_speed * 1.35
	else:
		roll_speed = player.stats.current_move_speed * 2.0
	

func _physics_update(_delta: float) -> void:
	var forward_direction = -player.visuals.global_transform.basis.z
	
	player.animation_player.play('Roll', player.animation_blend, 1.5)
	
	# Apply movement in the forward direction
	forward_direction.y = 0
	forward_direction = forward_direction.normalized()
	
	player.velocity.x = forward_direction.x * roll_speed
	player.velocity.z = forward_direction.z * roll_speed
	
	if not player.is_on_floor():
		player.velocity.y -= player.gravity / roll_speed * _delta
	
	await player.animation_player.animation_finished
	
	if not player.is_on_floor():
		finished.emit(states.find_key(states.FALLING))
	else:
		finished.emit(states.find_key(states.MOVING))
	
