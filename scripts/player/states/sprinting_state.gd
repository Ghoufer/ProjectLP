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
	
	if not player.is_on_floor():
		finished.emit(states.find_key(states.FALLING))
	
	if not Input.is_action_pressed("sprint"):
		finished.emit(states.find_key(states.MOVING))
	
	if Input.is_action_pressed("roll"):
		finished.emit(states.find_key(states.ROLLING))
	
	if Input.is_action_pressed("light_attack"):
		finished.emit(states.find_key(states.ATTACKING))
	
	player.move_and_slide()
	
