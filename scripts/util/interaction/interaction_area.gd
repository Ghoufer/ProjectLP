extends Area3D
class_name InteractionArea

signal collided
signal interacted

func _on_interaction_ray_collided() -> void:
	collided.emit()
	

func _on_interact() -> void:
	interacted.emit()
	
