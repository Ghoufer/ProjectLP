extends RigidBody3D
class_name Pickable

@export var item_data : Resource

@onready var pickup_area: CollisionShape3D = %PickupAreaCol
@onready var interaction_area: CollisionShape3D = %InteractionAreaCol
@onready var outline_shader := preload('res://scripts/shaders/item_outline.tres')

# Dropped item animation
@export var bob_height: float = 0.3
@export var bob_speed: float = 1.0
@export var rotation_speed: float = 2.0
@export var sway_amount: float = 0.2
@export var sway_speed: float = 1.5

var path_name : String
var loaded_scene : PackedScene
var instance : Node
var animation_tween

func _ready() -> void:
	if item_data:
		path_name = item_data.item_path
		loaded_scene = Global.item_paths[path_name]
		instance = loaded_scene.instantiate()
		
		call_deferred("add_child", instance)
		
		if item_data.auto_pickup:
			interaction_area.disabled = true
		else:
			pickup_area.disabled = true
	

func _process(_delta: float) -> void:
	if not Global.interact_text:
		instance.mesh.material.next_pass = null
	

#func _physics_process(_delta: float) -> void:
	#if linear_velocity.y == 0.0:
		#if animation_tween:
			#animation_tween.kill()
		#create_drop_animation()
	#
#
#func create_drop_animation() -> void:
	#animation_tween = create_tween()
	#animation_tween.set_loops()  # Loop infinitely
	#animation_tween.tween_property(instance, "position:y", global_position.y + bob_height, bob_speed / 2.0)
	#animation_tween.tween_property(instance, "position:y", global_position.y, bob_speed / 2.0)
	#

func _on_pickup_area_body_entered(body: Node3D) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", body.position + Vector3(-0.4, 0.6, -0.4), 0.18)
	tween.connect("finished", Callable(self, "_on_tween_finished"))
	

func _on_tween_finished():
	queue_free()
	

func _on_interaction_area_collided() -> void:
	#instance.mesh.material.next_pass = outline_shader
	Global.set_new_interact_text(item_data.prompt_message)
	

func _on_interaction_area_interacted() -> void:
	queue_free()
	
