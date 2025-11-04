extends PlayerState

var max_height : float

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	player.animation_player.play('Jump', player.animation_blend)
	

func _handle_input(_event: InputEvent) -> void:
	if _event.is_action_pressed("light_attack"):
		player.combat_component.attack(AttackData.AttackType.LIGHT)
	
	if _event.is_action_pressed("heavy_attack"):
		player.combat_component.attack(AttackData.AttackType.HEAVY)
	

func _physics_update(_delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y -= player.gravity * _delta
	
	if Input.is_action_pressed("jump") and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY
	
	if player.velocity.y <= 0:
		finished.emit(states.find_key(states.FALLING))
	
