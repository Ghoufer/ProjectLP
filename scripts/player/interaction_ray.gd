extends RayCast3D

var collider

func _physics_process(_delta: float) -> void:
	if is_colliding():
		collider = get_collider()
		Global.emit_signal("set_interaction_ray_collided", true)
		
		if collider is InteractionArea:
			collider._on_interaction_ray_collided()
			
			if Input.is_action_just_pressed("interact"):
				collider._on_interact()
	else:
		collider = null
		Global.emit_signal("set_interaction_ray_collided", false)
	
