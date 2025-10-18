extends CharacterBody3D

@export var TILT_LOWER_LIMIT := deg_to_rad(-70.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(70.0)
@export var CAMERA_CONTROLLER : SpringArm3D
@export var MOUSE_SENSITIVITY : float = 0.5
@export var VISUALS : Node3D

const SPEED = 3.0
const JUMP_VELOCITY = 8.0

var mouse_input : bool = false
var rotation_input : float
var tilt_input : float
var mouse_rotation : Vector3
var player_rotation : Vector3
var camera_rotation : Vector3

var gravity = 24.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event.is_action_pressed('exit'):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	
	if mouse_input:
		rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		tilt_input = -event.relative.y * MOUSE_SENSITIVITY

func _process(delta):
	update_camera(delta)

func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var direction : Vector3 = Vector3.ZERO
	
	if input_dir != Vector2.ZERO:
		var camera_basis = CAMERA_CONTROLLER.global_transform.basis
		
		# Remover inclinação vertical da câmera para movimento horizontal
		var camera_forward = -camera_basis.z
		var camera_right = -camera_basis.x
		
		camera_forward.y = 0
		camera_right.y = 0
		
		camera_forward = -camera_forward.normalized()
		camera_right = -camera_right.normalized()
		
		direction = (camera_right * input_dir.x + camera_forward * input_dir.y).normalized()
	
	if direction:
		velocity.x = lerp(velocity.x, direction.x * SPEED, 0.1)
		velocity.z = lerp(velocity.z, direction.z * SPEED, 0.1)
		
		if VISUALS:
			var target_rotation = atan2(-direction.x, -direction.z)
			VISUALS.rotation.y = lerp_angle(VISUALS.rotation.y, target_rotation, 10.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	move_and_slide()

func update_camera(delta):
	mouse_rotation.x += tilt_input * delta
	mouse_rotation.x = clamp(mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	mouse_rotation.y += rotation_input * delta
	
	camera_rotation = Vector3(mouse_rotation.x, mouse_rotation.y, 0.0)
	
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0
	
	rotation_input = 0.0
	tilt_input = 0.0
