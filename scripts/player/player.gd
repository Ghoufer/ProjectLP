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
	
	if event.is_action_pressed("light_attack"):
		combat_component.attack(AttackData.AttackType.LIGHT)
	elif event.is_action_pressed("heavy_attack"):
		combat_component.attack(AttackData.AttackType.HEAVY)
	

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
	var camera_basis : Basis = camera_controller.global_transform.basis
	var is_rolling = state_machine.state.state_name == PlayerState.states.find_key(PlayerState.states.ROLLING).capitalize()
	var is_attacking = state_machine.state.state_name == PlayerState.states.find_key(PlayerState.states.ATTACKING).capitalize()
	
	# Remover inclinação vertical da câmera para movimento horizontal
	var camera_forward : Vector3 = -camera_basis.z
	var camera_right : Vector3 = -camera_basis.x
	
	camera_forward.y = 0
	camera_right.y = 0
	
	camera_forward = -camera_forward.normalized()
	camera_right = -camera_right.normalized()
	
	if (is_rolling or is_attacking) and not movement_input:
		direction = -visuals.global_transform.basis.z
	else:
		direction = (camera_right * movement_input.x + camera_forward * movement_input.y).normalized()
	
	if not is_on_floor():
		if not is_rolling and not is_attacking:
			velocity.y -= gravity * delta
		else:
			velocity.y -= gravity / ROLL_VELOCITY * delta
	
	if direction and not is_attacking:
		velocity.x = lerp(velocity.x, direction.x * stats.current_move_speed, 0.1)
		velocity.z = lerp(velocity.z, direction.z * stats.current_move_speed, 0.1)
	
	if visuals:
		var target_rotation = atan2(-direction.x, -direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_rotation, 5.0 * delta)
	
