extends LimboState

var friction : float = 0.15

func _update(_delta: float) -> void:
	if agent.movement_input != Vector2.ZERO:
		get_root().dispatch(str(agent.state_transitions.TO_MOVE))
	else:
		agent.velocity.x = lerp(agent.velocity.x, 0.0, friction)
		agent.velocity.z = lerp(agent.velocity.z, 0.0, friction)
	
