extends RigidBody3D
class_name Item

@export var stack : ItemStack
@export var auto_pickup : bool = false

@onready var interaction_area: CollisionShape3D = %InteractionAreaCol
@onready var ground_collider: CollisionShape3D = %GroundCollider
@onready var outline_shader := preload('res://scripts/shaders/item_outline.tres')
@onready var interaction_text: Sprite3D = %InteractionText
@onready var interaction_text_sv: SubViewport = %InteractionTextSV
@onready var interaction_text_label: Label = %InteractionTextLabel
@onready var pickup_delay_timer: Timer = %PickupDelayTimer

## Dropped item animation
var rotation_speed: float = 30.0
var rotation_tween : Tween
var random_rotation : float = randf()
var item_gravity : float = 12.0

## Pickup animation
var pickup_tween : Tween
var fraction_tween : Tween
var pickup_tween_speed : float = 0.1

var item_mesh : Node
var loaded_scene : PackedScene
var player_dropped : Node3D

func _ready() -> void:
	if stack and stack.item_data:
		interaction_text.visible = false
		interaction_text_label.text = "[E] Pegar " + stack.item_data.item_name + " (" + str(stack.quantity) + ")"
		
		stack = stack.duplicate()
		
		loaded_scene = ItemPool.paths[stack.item_data.item_path]
		item_mesh = loaded_scene.instantiate().duplicate()
		item_mesh.rotation.y = randf() * TAU
	
		add_child(item_mesh, 0)
		
		if auto_pickup:
			interaction_area.disabled = true
			create_drop_animation()
	
	if player_dropped: start_timer(player_dropped)
	

#region Item drop pickup delay
func start_timer(player: Node3D) -> void:
	if player:
		pickup_delay_timer.start()
		pickup_delay_timer.connect("timeout", timer_finished)
	

func timer_finished() -> void:
	player_dropped = null
#endregion

#region -> Item drop animation
func create_drop_animation() -> void:
	rotation_tween = create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(item_mesh, "rotation:y", item_mesh.rotation.y + TAU, rotation_speed).from(item_mesh.rotation.y)
#endregion

#region -> Item pickup animation and logic
func create_pickup_animation(body_position: Vector3) -> void:
	interaction_text.visible = false
	interaction_area.disabled = true
	
	pickup_tween = create_tween()
	pickup_tween.set_parallel()
	pickup_tween.tween_property(item_mesh, "global_position", body_position + Vector3(-0, 0.5, -0), pickup_tween_speed)
	pickup_tween.tween_property(item_mesh, "scale", Vector3(0.1, 0.1, 0.1), pickup_tween_speed)
	pickup_tween.connect("finished", _on_pickup_tween_finished.bind(self))
	

## Call this animation when not the whole quantity got picked
func create_fraction_pickup_animation(body_position: Vector3) -> void:
	var mesh_copy : Node3D = item_mesh.duplicate()
	
	self.add_child(mesh_copy)
	
	fraction_tween = create_tween()
	fraction_tween.set_parallel()
	fraction_tween.tween_property(mesh_copy, "global_position", body_position + Vector3(-0, 0.8, -0), pickup_tween_speed)
	fraction_tween.tween_property(mesh_copy, "scale", Vector3(0.1, 0.1, 0.1), pickup_tween_speed)
	fraction_tween.connect("finished", _on_pickup_tween_finished.bind(mesh_copy))
	

func _on_pickup_tween_finished(body: Node):
	body.call_deferred('queue_free')
#endregion

#region -> Interaction area logic
func _on_interaction_area_collided() -> void:
	interaction_text_sv.size = interaction_text_label.size
	interaction_text.visible = true
	

func _on_interaction_area_not_collided() -> void:
	interaction_text.visible = false
	
#endregion
