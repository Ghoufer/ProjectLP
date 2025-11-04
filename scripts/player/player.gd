extends CharacterBody3D
class_name Player

@onready var visuals : Node3D = %Visuals
@onready var state_machine : StateMachine = %StateMachine
@onready var camera_controller : Node3D = %CameraController
@onready var weapon : Weapon = %Weapon
@onready var combat_component : CombatComponent = %CombatComponent

@export var stats : Stats

const JUMP_VELOCITY : int = 8
const ROLL_VELOCITY : float = 3.5
const TILT_LOWER_LIMIT : float = deg_to_rad(-70.0)
const TILT_UPPER_LIMIT : float = deg_to_rad(70.0)

var animation_player: AnimationPlayer
var mouse_sensitivity : float = 0.5
var mouse_input : bool = false
var rotation_input : float
var tilt_input : float
var mouse_rotation : Vector3
var player_rotation : Vector3
var camera_rotation : Vector3
var movement_input : Vector2

var gravity : float = 24.0
var animation_blend : float = 0.25

func _ready() -> void:
	var player_model : Node3D = visuals.get_children()[0]
	animation_player = player_model.get_node('AnimationPlayer')
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	combat_component.equip_weapon(weapon)
	

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
	move_and_slide()
	
