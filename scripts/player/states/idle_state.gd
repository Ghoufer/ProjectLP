extends PlayerState

var friction : float

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	player.animation_player.play('Idle', player.animation_blend)
	friction = player.stats.current_move_speed * 6.0
	

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
	if not player.is_on_floor():
		finished.emit(states.find_key(states.FALLING))
	
	if player.movement_input != Vector2.ZERO:
		finished.emit(states.find_key(states.MOVING))
	
	if player.velocity != Vector3.ZERO:
		player.velocity.x = lerp(player.velocity.x, 0.0, 1 - exp(-friction * get_physics_process_delta_time()))
		player.velocity.z = lerp(player.velocity.z, 0.0, 1 - exp(-friction * get_physics_process_delta_time()))
	
	player.velocity.y = 0

	
