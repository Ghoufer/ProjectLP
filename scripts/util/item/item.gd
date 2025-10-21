extends RigidBody3D
class_name Item

@export var item_data : ItemData
@export var auto_pickup : bool = false

@onready var pickup_area: CollisionShape3D = %PickupAreaCol
@onready var interaction_area: CollisionShape3D = %InteractionAreaCol
@onready var ground_detect: ShapeCast3D = %GroundDetect
@onready var ground_collider: CollisionShape3D = %GroundCollider
@onready var outline_shader := preload('res://scripts/shaders/item_outline.tres')
@onready var interaction_text: Sprite3D = %InteractionText
@onready var interaction_text_sv: SubViewport = %InteractionTextSV
@onready var interaction_text_label: Label = %InteractionTextLabel

# Dropped item animation
var bob_height: float = 0.005
var bob_speed: float = 1.0
var rotation_speed: float = 30.0
var pickup_tween : Tween
var animation_tween : Tween
var rotation_tween : Tween
var random_rotation : float = randf()
var item_gravity : float = 6.0
var last_known_player_pos : Vector3

var instance : Node
var loaded_scene : PackedScene

func _ready() -> void:
	if item_data:
		interaction_text.visible = false
		interaction_text_label.text = "[E] Pegar " + item_data.item_name
		last_known_player_pos = get_tree().get_first_node_in_group("Player").global_position
		
		if not auto_pickup:
			self.gravity_scale = 1.0
			ground_detect.enabled = false
		
		item_data = item_data.duplicate()
		
		loaded_scene = Global.item_paths[item_data.item_path]
		instance = loaded_scene.instantiate()
		instance.rotation.y = randf() * TAU
		
		if auto_pickup:
			interaction_area.disabled = true
		else:
			pickup_area.disabled = true
		
		call_deferred("add_child", instance)
	

func _process(_delta: float) -> void:
	if Global.interaction_ray_collided:
		interaction_text_sv.size = interaction_text_label.size
	
	if not Global.interaction_ray_collided and interaction_text.visible:
		interaction_text.visible = false
	

func _physics_process(delta: float) -> void:
	if not pickup_tween:
		if not ground_detect.is_colliding() and ground_detect.enabled:
			global_position.y -= item_gravity * delta
		elif not animation_tween and auto_pickup:
			create_drop_animation()
		
	
	if pickup_tween:
		create_pickup_animation()
	

#region -> Item drop animation
func create_drop_animation() -> void:
	animation_tween = create_tween()
	animation_tween.set_loops()
	animation_tween.tween_property(instance, "global_position:y", global_position.y + bob_height * 3, bob_speed)
	animation_tween.tween_property(instance, "global_position:y", global_position.y - bob_height, bob_speed)
	
	rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(instance, "rotation:y", instance.rotation.y + TAU, rotation_speed).from(instance.rotation.y)
#endregion

#region -> Item pickup animation and logic
func _on_pickup_area_body_entered(body: Node3D) -> void:
	last_known_player_pos = body.global_position
	create_pickup_animation()
	

func create_pickup_animation() -> void:
	var tween_speed : float = 0.15
	
	animation_tween = null
	last_known_player_pos = get_tree().get_first_node_in_group("Player").global_position
	
	pickup_tween = create_tween()
	pickup_tween.set_parallel()
	pickup_tween.tween_property(instance, "global_position", last_known_player_pos + Vector3(0, 0.8, 0), tween_speed)
	pickup_tween.tween_property(instance, "scale", Vector3(0.1, 0.1, 0.1), tween_speed)
	pickup_tween.connect("finished", Callable(self, "_on_pickup_tween_finished"))
	

func _on_pickup_tween_finished():
	queue_free()
#endregion

#region -> Interaction area logic
func _on_interaction_area_collided() -> void:
	interaction_text.visible = true
	

func _on_interaction_area_interacted() -> void:
	interaction_text.visible = false
	interaction_area.disabled = true
	create_pickup_animation()
#endregion
