extends CharacterBody3D
class_name Player

@onready var visuals: Node3D = %Visuals
@onready var state_machine: LimboHSM = %StateMachine
@onready var camera_controller: Node3D = %CameraController

## States
@onready var idle_state: LimboState = %IdleState
@onready var move_state: LimboState = %MoveState

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

func _ready():
	initialize_state_machine()
	

func initialize_state_machine() -> void:
	## Define state transitions
	state_machine.add_transition(state_machine.ANYSTATE, idle_state, str(state_transitions.TO_IDLE))
	state_machine.add_transition(idle_state, move_state, str(state_transitions.TO_MOVE))
	
	## Setup State Machine
	state_machine.initial_state = idle_state
	state_machine.initialize(self)
	state_machine.set_active(true)
	

func _process(delta: float) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		update_camera(delta)
	

func _physics_process(_delta: float) -> void:
	movement_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	

func _unhandled_input(event) -> void:
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
	
