extends PlayerState

func _handle_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("jump") and player.is_on_floor():
		finished.emit(states.find_key(states.JUMPING))
	

func _physics_update(_delta: float) -> void:
	if player.movement_input != Vector2.ZERO:
		if Input.is_action_pressed("sprint") and player.stats.current_move_speed != player.stats.sprint_speed:
			player.stats.current_move_speed = player.stats.sprint_speed
		
		if not Input.is_action_pressed("sprint") and player.stats.current_move_speed == player.stats.sprint_speed:
			player.stats.current_move_speed = player.stats.base_move_speed
		
		player.update_movement(_delta)
	else:
		finished.emit(states.find_key(states.IDLE))
	
	if not player.is_on_floor():
		finished.emit(states.find_key(states.FALLING))
	
	player.move_and_slide()
	
