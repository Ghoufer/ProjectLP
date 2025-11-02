extends PlayerState

var friction : float = 0.2

func _handle_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("jump") and player.is_on_floor():
		finished.emit(states.find_key(states.JUMPING))
	

func _physics_update(_delta: float) -> void:
	if not player.is_on_floor():
		finished.emit(states.find_key(states.FALLING))
	
	if player.movement_input != Vector2.ZERO:
		finished.emit(states.find_key(states.MOVING))
	
	if player.velocity != Vector3.ZERO:
		player.velocity.x = lerp(player.velocity.x, 0.0, friction)
		player.velocity.z = lerp(player.velocity.z, 0.0, friction)
	
	player.velocity.y = 0
	player.move_and_slide()
	
