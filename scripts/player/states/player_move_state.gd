extends LimboState

func _update(delta: float) -> void:
	update_movement(delta)
	
	if agent.movement_input == Vector2.ZERO:
		get_root().dispatch(str(agent.state_transitions.TO_IDLE))
	

func update_movement(delta: float):
	var direction : Vector3 = Vector3.ZERO
	
	if agent.movement_input != Vector2.ZERO:
		var camera_basis = agent.camera_controller.global_transform.basis
		
		# Remover inclinação vertical da câmera para movimento horizontal
		var camera_forward = -camera_basis.z
		var camera_right = -camera_basis.x
		
		camera_forward.y = 0
		camera_right.y = 0
		
		camera_forward = -camera_forward.normalized()
		camera_right = -camera_right.normalized()
		
		direction = (camera_right * agent.movement_input.x + camera_forward * agent.movement_input.y).normalized()
	
	if direction:
		agent.velocity.x = lerp(agent.velocity.x, direction.x * agent.stats.current_move_speed, 0.1)
		agent.velocity.z = lerp(agent.velocity.z, direction.z * agent.stats.current_move_speed, 0.1)
		
		if agent.visuals:
			var target_rotation = atan2(-direction.x, -direction.z)
			agent.visuals.rotation.y = lerp_angle(agent.visuals.rotation.y, target_rotation, 5.0 * delta)
	
