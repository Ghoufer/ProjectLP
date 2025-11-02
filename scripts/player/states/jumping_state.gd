extends PlayerState

var max_height : float

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	player.animation_player.play('Jump', player.animation_blend)
	

func _physics_update(_delta: float) -> void:
	if Input.is_action_pressed("jump") and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY
	
	if player.velocity.y <= 0:
		finished.emit(states.find_key(states.FALLING))
	
	player.update_movement(_delta)
	
	player.move_and_slide()
	
