extends RayCast3D

var collider

func _physics_process(_delta: float) -> void:
	if is_colliding():
		if not collider:
			collider = get_collider()
		elif collider.global_position != get_collision_point():
			if collider != get_collider():
				sttoped_colliding(collider)
				
			collider = get_collider()
			
			if collider is InteractionArea:
				collider._on_interaction_ray_collided()
	

func sttoped_colliding(col: Object) -> void:
	if col is InteractionArea:
		col.not_collided.emit()
	
