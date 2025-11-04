extends PlayerState

var friction : float = 0.2

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	player.animation_player.play('Idle', player.animation_blend)
	

func _handle_input(_event: InputEvent) -> void:
	if _event.is_action_pressed("light_attack"):
		player.combat_component.attack(AttackData.AttackType.LIGHT)
	
	if _event.is_action_pressed("heavy_attack"):
		player.combat_component.attack(AttackData.AttackType.HEAVY)
	

func _physics_update(_delta: float) -> void:
	if not player.is_on_floor():
		finished.emit(states.find_key(states.FALLING))
	
	if Input.is_action_pressed("jump"):
		finished.emit(states.find_key(states.JUMPING))
	
	if Input.is_action_pressed("roll"):
		finished.emit(states.find_key(states.ROLLING))
	
	if player.movement_input != Vector2.ZERO:
		finished.emit(states.find_key(states.MOVING))
	
	if player.velocity != Vector3.ZERO:
		player.velocity.x = lerp(player.velocity.x, 0.0, friction)
		player.velocity.z = lerp(player.velocity.z, 0.0, friction)
	
	player.velocity.y = 0

	
