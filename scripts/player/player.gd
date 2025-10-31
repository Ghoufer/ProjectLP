extends CharacterBody3D
class_name Player

@onready var visuals: Node3D = %Visuals
@onready var camera_controller: Node3D = %CameraController

@export var stats : Stats

const JUMP_VELOCITY : int = 8
const TILT_LOWER_LIMIT : float = deg_to_rad(-70.0)
const TILT_UPPER_LIMIT : float = deg_to_rad(70.0)

var mouse_sensitivity : float = 0.5
var mouse_input : bool = false
var rotation_input : float
var tilt_input : float
var mouse_rotation : Vector3
var player_rotation : Vector3
var camera_rotation : Vector3
var movement_input : Vector2

var gravity : float = 24.0

enum state_transitions {
	TO_IDLE,
	TO_MOVE
}

func _process(delta: float) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		update_camera(delta)
	

func _physics_process(_delta: float) -> void:
	movement_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	

func _unhandled_input(event: InputEvent) -> void:
	mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	
	if mouse_input:
		rotation_input = -event.relative.x * mouse_sensitivity
		tilt_input = -event.relative.y * mouse_sensitivity
	
	if event.is_action_pressed('exit'):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event.is_action_pressed("sprint"):
		stats.current_move_speed = stats.current_move_speed * 2.0
	
	if event.is_action_released("sprint"):
		stats.current_move_speed = stats.base_move_speed
	

func update_camera(delta: float):
	mouse_rotation.x += tilt_input * delta
	mouse_rotation.x = clamp(mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	mouse_rotation.y += rotation_input * delta
	
	camera_rotation = Vector3(mouse_rotation.x, mouse_rotation.y, 0.0)
	
	camera_controller.transform.basis = Basis.from_euler(camera_rotation)
	camera_controller.rotation.z = 0.0
	
	rotation_input = 0.0
	tilt_input = 0.0
	

## Any State
#func _enter() -> void:
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#
#
#func _physics_process(delta: float) -> void:
	#if not agent.is_on_floor():
		#agent.velocity.y -= agent.gravity * delta
	#else:
		#agent.velocity.y = 0
	#
	#if Input.is_action_pressed("jump") and agent.is_on_floor():
		#agent.velocity.y = agent.JUMP_VELOCITY
	#
	#agent.move_and_slide()
	#

## Idle State
#var friction : float = 0.2
#
#func _update(_delta: float) -> void:
	#if agent.movement_input != Vector2.ZERO:
		#get_root().dispatch(str(agent.state_transitions.TO_MOVE))
	#else:
		#agent.velocity.x = lerp(agent.velocity.x, 0.0, friction)
		#agent.velocity.z = lerp(agent.velocity.z, 0.0, friction)
	#

## Move State
#func update_movement(delta: float):
	#var direction : Vector3 = Vector3.ZERO
	#
	#if agent.movement_input != Vector2.ZERO:
		#var camera_basis = agent.camera_controller.global_transform.basis
		#
		## Remover inclinação vertical da câmera para movimento horizontal
		#var camera_forward = -camera_basis.z
		#var camera_right = -camera_basis.x
		#
		#camera_forward.y = 0
		#camera_right.y = 0
		#
		#camera_forward = -camera_forward.normalized()
		#camera_right = -camera_right.normalized()
		#
		#direction = (camera_right * agent.movement_input.x + camera_forward * agent.movement_input.y).normalized()
	#
	#if direction:
		#agent.velocity.x = lerp(agent.velocity.x, direction.x * agent.stats.current_move_speed, 0.1)
		#agent.velocity.z = lerp(agent.velocity.z, direction.z * agent.stats.current_move_speed, 0.1)
		#
		#if agent.visuals:
			#var target_rotation = atan2(-direction.x, -direction.z)
			#agent.visuals.rotation.y = lerp_angle(agent.visuals.rotation.y, target_rotation, 5.0 * delta)
	#
