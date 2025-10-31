extends CharacterBody3D
class_name Enemy

@onready var visuals : Node3D = %Visuals
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var collision_shape : CollisionShape3D = %CollisionShape3D

@export var enemy_data : EnemyData

var gravity : float = 24.0

func _ready() -> void:
	if enemy_data and enemy_data.enemy_scene:
		var scene : Node = enemy_data.enemy_scene.instantiate()
		var col : Node = scene.get_node('CollisionShape3D')
		
		collision_shape.shape = col.shape
		collision_shape.transform = col.transform
		animation_player = scene.get_node("AnimationPlayer")
		
		visuals.add_child(scene)
		
	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	move_and_slide()
	
