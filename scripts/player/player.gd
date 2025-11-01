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

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

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
	

func _process(delta: float) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_rotation.x += tilt_input * delta
		mouse_rotation.x = clamp(mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
		mouse_rotation.y += rotation_input * delta
		
		camera_rotation = Vector3(mouse_rotation.x, mouse_rotation.y, 0.0)
		
		camera_controller.transform.basis = Basis.from_euler(camera_rotation)
		camera_controller.rotation.z = 0.0
		
		rotation_input = 0.0
		tilt_input = 0.0
	

func _physics_process(_delta: float) -> void:
	movement_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	

func update_movement(delta: float) -> void:
	var direction : Vector3 = Vector3.ZERO
	var camera_basis = camera_controller.global_transform.basis
		
	# Remover inclinação vertical da câmera para movimento horizontal
	var camera_forward = -camera_basis.z
	var camera_right = -camera_basis.x
	
	camera_forward.y = 0
	camera_right.y = 0
	
	camera_forward = -camera_forward.normalized()
	camera_right = -camera_right.normalized()
	
	direction = (camera_right * movement_input.x + camera_forward * movement_input.y).normalized()

	if direction:
		velocity.x = lerp(velocity.x, direction.x * stats.current_move_speed, 0.1)
		velocity.z = lerp(velocity.z, direction.z * stats.current_move_speed, 0.1)
	
	if visuals:
		var target_rotation = atan2(-direction.x, -direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rotation, 5.0 * delta)
