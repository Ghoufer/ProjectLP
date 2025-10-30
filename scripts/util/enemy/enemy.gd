extends CharacterBody3D
class_name Enemy

@onready var aggro_area: Area3D = %AggroArea
@onready var vision_rays: Node3D = %VisionRays
@onready var nav_agent : NavigationAgent3D = %NavigationAgent3D

@export var stats : Stats

var gravity : float = 24.0

var has_aggro : bool = false
var max_view_distance : float = 4.0
var angle_between_rays : float = deg_to_rad(5.0)
var angle_cone_of_vision : float = deg_to_rad(45.0)
var turn_speed : float = 5.0
var has_lof : bool = false
var target_position : Vector3 = Vector3.FORWARD
var ray_count : int = int(angle_cone_of_vision / angle_between_rays)

func _ready() -> void:
	look_at(global_position + Vector3.FORWARD)
	generate_vision_rays()
	

func _physics_process(delta: float) -> void:
	var current_location : Vector3 = global_transform.origin
	var next_location : Vector3 = nav_agent.get_next_path_position()
	var direction : Vector3 = (next_location - current_location).normalized()
	var new_velocity : Vector3 = (next_location - current_location).normalized() * stats.current_move_speed
	var bodies_in_area : Array[Node3D] = aggro_area.get_overlapping_bodies()
	
	if not bodies_in_area.is_empty():
		for body in bodies_in_area:
			if body is Player:
				target_position = body.global_position
	
	for ray in vision_rays.get_children():
		if ray.is_colliding() and ray.get_collider() is Player:
			has_lof = true
			target_position = ray.get_collider().global_position
			break
		has_lof = false
	
	if has_lof:
		nav_agent.target_position = target_position
	
	velocity = velocity.move_toward(new_velocity, delta)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	if direction.length() > 0.01:  # Avoid jitter if too close
		if abs(direction.dot(Vector3.UP)) < 0.99:
			look_at(global_position + direction)
	
	move_and_slide()
	

func generate_vision_rays() -> void:
	for index in range(ray_count):
		var ray : RayCast3D = RayCast3D.new()
		var angle : float = angle_between_rays * (index - ray_count / 2.0)
		ray.target_position = Vector3.FORWARD.rotated(Vector3.UP, angle) * max_view_distance
		ray.position.y += 0.5
		ray.collision_mask = 5
		vision_rays.add_child(ray)
		ray.enabled = true
	
