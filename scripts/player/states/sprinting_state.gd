extends PlayerState

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	player.stats.current_move_speed = player.stats.sprint_speed
	player.animation_player.play('Sprint', player.animation_blend)
	

func _handle_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("jump") and player.is_on_floor():
		finished.emit(states.find_key(states.JUMPING))
	

func _physics_update(_delta: float) -> void:
	if player.movement_input != Vector2.ZERO:
		player.update_movement(_delta)
	
	if not Input.is_action_pressed("sprint"):
		finished.emit(states.find_key(states.MOVING))
	
	if not player.is_on_floor():
		finished.emit(states.find_key(states.FALLING))
	
	player.move_and_slide()
	
