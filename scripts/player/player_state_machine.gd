extends LimboHSM

func _enter() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

func _physics_process(delta: float) -> void:
	if not agent.is_on_floor():
		agent.velocity.y -= agent.gravity * delta
	else:
		agent.velocity.y = 0
	
	if Input.is_action_pressed("jump") and agent.is_on_floor():
		agent.velocity.y = agent.JUMP_VELOCITY
	
	agent.move_and_slide()
	
