extends PlayerState

var friction : float = 0.2

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	player.animation_player.play('Fall', player.animation_blend)
	

func _handle_input(_event: InputEvent) -> void:
	if _event.is_action_pressed("light_attack"):
		player.combat_component.attack(AttackData.AttackType.LIGHT)
	
	if _event.is_action_pressed("heavy_attack"):
		player.combat_component.attack(AttackData.AttackType.HEAVY)
	

func _physics_update(_delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y -= player.gravity * _delta
	
	if player.movement_input:
		player.update_movement(player.stats.sprint_speed, _delta)
	
	if player.is_on_floor():
		player.animation_player.play('Jump_Land')
		finished.emit(states.find_key(states.IDLE))
	
