extends PlayerState

func _physics_update(_delta: float) -> void:
	var forward_direction = -player.visuals.global_transform.basis.z
	
	player.roll_col.disabled = false
	player.normal_col.disabled = true
	player.animation_player.play('Roll', player.animation_blend, 1.5)
	
	# Apply movement in the forward direction
	forward_direction.y = 0
	forward_direction = forward_direction.normalized()
	
	player.velocity.x = forward_direction.x * player.ROLL_VELOCITY
	player.velocity.z = forward_direction.z * player.ROLL_VELOCITY
	player.normal_col.shape.height = player.normal_col.shape.height / 2
	
	player.update_movement(_delta)
	player.move_and_slide()
	
	await player.animation_player.animation_finished
	
	player.roll_col.disabled = true
	player.normal_col.disabled = false
	
	if not player.is_on_floor():
		finished.emit(states.find_key(states.FALLING))
	else:
		finished.emit(states.find_key(states.MOVING))
	
