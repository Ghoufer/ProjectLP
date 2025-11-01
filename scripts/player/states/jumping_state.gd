extends PlayerState

var max_height : float

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	max_height = player.velocity.y + player.JUMP_VELOCITY
	

func _physics_update(_delta: float) -> void:
	if Input.is_action_pressed("jump") and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY
	
	if player.velocity.y >= max_height:
		finished.emit(player_states.find_key(player_states.FALLING))
	
	player.update_movement(_delta)
	
	player.move_and_slide()
	
