extends PlayerState

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	player.stats.current_move_speed = player.stats.base_move_speed
	player.animation_player.play('Walk', player.animation_blend)
	

func _handle_input(_event: InputEvent) -> void:
	if _event.is_action_pressed("jump") and player.is_on_floor():
		finished.emit(states.find_key(states.JUMPING))
	
	if _event.is_action_pressed("roll") and player.is_on_floor():
		finished.emit(states.find_key(states.ROLLING))
	
	if _event.is_action_pressed("light_attack"):
		player.combat_component.attack(AttackData.AttackType.LIGHT)
	
	if _event.is_action_pressed("heavy_attack"):
		player.combat_component.attack(AttackData.AttackType.HEAVY)
	

func _physics_update(_delta: float) -> void:
	if Input.is_action_pressed("sprint"):
		finished.emit(states.find_key(states.SPRINTING))
	
	if player.movement_input != Vector2.ZERO:
		player.update_movement(player.stats.current_move_speed, _delta)
	else:
		finished.emit(states.find_key(states.IDLE))
	
	if not player.is_on_floor():
		finished.emit(states.find_key(states.FALLING))
	
