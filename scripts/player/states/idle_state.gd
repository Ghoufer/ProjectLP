extends PlayerState

var friction : float = 0.2

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	player.animation_player.play('Idle', player.animation_blend)
	

func _physics_update(_delta: float) -> void:
	if Input.is_action_pressed("jump") and player.is_on_floor():
		finished.emit(states.find_key(states.JUMPING))
	
	if Input.is_action_pressed("roll") and player.is_on_floor():
		finished.emit(states.find_key(states.ROLLING))
	
	if not player.is_on_floor():
		finished.emit(states.find_key(states.FALLING))
	
	if player.movement_input != Vector2.ZERO:
		finished.emit(states.find_key(states.MOVING))
	
	if player.velocity != Vector3.ZERO:
		player.velocity.x = lerp(player.velocity.x, 0.0, friction)
		player.velocity.z = lerp(player.velocity.z, 0.0, friction)
	
	player.velocity.y = 0
	player.move_and_slide()
	
