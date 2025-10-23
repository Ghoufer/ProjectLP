extends Area3D
class_name InteractionArea

signal collided
signal interacted
signal not_collided

func _on_interaction_ray_collided() -> void:
	collided.emit()
	

func _on_interaction_raynot_not_collided() -> void:
	not_collided.emit()
	

func _on_interact() -> void:
	interacted.emit()
	
