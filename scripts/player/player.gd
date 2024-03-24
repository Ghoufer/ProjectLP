extends CharacterBody3D

@export var TILT_LOWER_LIMIT := deg_to_rad(-85.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(85.0)
@export var CAMERA_CONTROLLER : Node3D
@export var MOUSE_SENSITIVITY : float = 0.5

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var mouse_input : bool = false
var rotation_input : float
var tilt_input : float
var mouse_rotation : Vector3
var player_rotation : Vector3
var camera_rotation : Vector3

var gravity = 12.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event.is_action_pressed('exit'):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	
	if mouse_input:
		rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		tilt_input = -event.relative.y * MOUSE_SENSITIVITY

func update_camera(delta):
	mouse_rotation.x += tilt_input * delta
	mouse_rotation.x = clamp(mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	mouse_rotation.y += rotation_input * delta
	
	player_rotation = Vector3(0.0, mouse_rotation.y, 0.0)
	camera_rotation = Vector3(mouse_rotation.x, 0.0, 0.0)
	
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0
	
	global_transform.basis = Basis.from_euler(player_rotation)
	
	rotation_input = 0.0
	tilt_input = 0.0

func _process(delta):
	update_camera(delta)

func _physics_process(delta):
	# Add the gravity.
	#if not is_on_floor():
		#velocity.y -= gravity * delta
	
	if Input.is_action_pressed("jump"):
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_pressed("move_down"):
		velocity.y = -JUMP_VELOCITY
	else:
		velocity.y = 0
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		if is_on_floor():
			velocity.x = lerp(velocity.x, direction.x * SPEED, 0.1)
			velocity.z = lerp(velocity.z, direction.z * SPEED, 0.1)
		else:
			velocity.x = lerp(direction.x * SPEED, direction.x * SPEED / 2, 0.3)
			velocity.z = lerp(direction.z * SPEED, direction.z * SPEED / 2, 0.3)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
