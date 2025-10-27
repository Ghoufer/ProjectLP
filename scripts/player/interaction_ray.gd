extends RayCast3D

signal interacted(body: Item)

var collider

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and collider:
		if collider is InteractionArea:
			interacted.emit(collider.get_owner())
	

func _physics_process(_delta: float) -> void:
	if is_colliding():
		if not collider:
			collider = get_collider()
		elif collider.global_position != get_collision_point():
			if collider != get_collider():
				sttoped_colliding(collider)
				
			collider = get_collider()
			
			if collider is InteractionArea:
				collider.collided.emit()
	elif collider:
		sttoped_colliding(collider)
		collider = null
	

func sttoped_colliding(col: Object) -> void:
	if col is InteractionArea:
		col.not_collided.emit()
	
