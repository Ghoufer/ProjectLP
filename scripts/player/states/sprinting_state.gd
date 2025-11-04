extends PlayerState

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	player.stats.current_move_speed = player.stats.sprint_speed
	player.animation_player.play('Sprint', player.animation_blend)
	

func _handle_input(_event: InputEvent) -> void:
	if _event.is_action_pressed("jump") and player.is_on_floor():
		finished.emit(states.find_key(states.JUMPING))
	
	if _event.is_action_pressed("roll"):
		finished.emit(states.find_key(states.ROLLING))
	
	if _event.is_action_pressed("light_attack"):
		player.combat_component.attack(AttackData.AttackType.LIGHT)
	
	if _event.is_action_pressed("heavy_attack"):
		player.combat_component.attack(AttackData.AttackType.HEAVY)
	

func _physics_update(_delta: float) -> void:
	if player.movement_input != Vector2.ZERO and Input.is_action_pressed("sprint"):
		var direction : Vector3 = Vector3.ZERO
		var camera_basis : Basis = player.camera_controller.global_transform.basis
		
		## Remover inclinação vertical da câmera para movimento horizontal
		var camera_forward : Vector3 = -camera_basis.z
		var camera_right : Vector3 = -camera_basis.x
		
		camera_forward.y = 0
		camera_right.y = 0
		
		camera_forward = -camera_forward.normalized()
		camera_right = -camera_right.normalized()
		
		direction = (camera_right * player.movement_input.x + camera_forward * player.movement_input.y).normalized()
		
		if direction:
			player.velocity.x = lerp(player.velocity.x, direction.x * player.stats.sprint_speed, 0.1)
			player.velocity.z = lerp(player.velocity.z, direction.z * player.stats.sprint_speed, 0.1)
	
		if player.visuals:
			var target_rotation = atan2(-direction.x, -direction.z)
			player.visuals.rotation.y = lerp_angle(player.visuals.rotation.y, target_rotation, 5.0 * _delta)
	else:
		finished.emit(states.find_key(states.MOVING))
	
	if not player.is_on_floor():
		finished.emit(states.find_key(states.FALLING))
	
