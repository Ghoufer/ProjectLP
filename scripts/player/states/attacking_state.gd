extends State

@onready var combat_component : CombatComponent = owner.get_node("CombatComponent")
@onready var animation_player : AnimationPlayer = owner.animation_player

var current_combo : Combo
var current_combo_index : int = 0
var current_weapon : Weapon
var attack_timer : float = 0.0
var can_queue_next_attack : bool = false
var friction : float

func _enter(_previous_state_path: String, data: Dictionary = {}) -> void:
	current_combo = data.get("combo_sequence", null)
	current_weapon = data.get("weapon", null)
	current_combo_index = data.get("combo_index", 0)
	attack_timer = 0.0
	can_queue_next_attack = false
	friction = owner.stats.current_move_speed * 4.0
	
	if current_combo == null:
		finished.emit("Idle", {})
		return
	
	combat_component.play_attack_animation(current_combo, current_combo_index)
	
	await get_tree().create_timer(current_combo.attacks[current_combo_index].windup_time).timeout
	
	_apply_forward_push()
	
	# Start weapon hit detection
	if current_weapon:
		current_weapon.start_attack()
	

func _update(delta: float) -> void:
	attack_timer += delta
	
	# Get attack data based on weapon or default
	var attack_data : AttackData = _get_current_attack_data()
	
	if attack_data:
		var total_time : float = attack_data.get_total_duration()
		var windup_end : float = attack_data.windup_time
		var attack_end : float = windup_end + attack_data.attack_time
		
		# Enable combo queueing during attack phase
		if attack_timer >= windup_end and attack_timer < attack_end:
			can_queue_next_attack = true
		
		# End attack when complete
		if attack_timer >= total_time:
			_end_attack()
	else:
		# Fallback: use animation length
		if animation_player and not animation_player.is_playing():
			_end_attack()

func _physics_update(_delta: float) -> void:
	if owner.velocity != Vector3.ZERO and owner.is_on_floor():
		owner.velocity.x = lerp(owner.velocity.x, 0.0, 1 - exp(-friction * get_physics_process_delta_time()))
		owner.velocity.z = lerp(owner.velocity.z, 0.0, 1 - exp(-friction * get_physics_process_delta_time()))
	
	if not owner.is_on_floor():
		owner.velocity.y -= owner.gravity * _delta
	

func _exit() -> void:
	if current_weapon:
		current_weapon.end_attack()

func _end_attack() -> void:
	if current_weapon:
		current_weapon.end_attack()
	finished.emit("Idle", {})

func _queue_next_combo_attack(attack_type: AttackData.AttackType) -> void:
	# Check if there's a next attack in combo
	if current_combo_index + 1 < current_combo.attacks.size():
		# Check if next attack matches the input type
		if current_combo.attacks[current_combo_index + 1].attack_type == attack_type:
			var next_combo_data : Dictionary = {
				"combo_sequence": current_combo,
				"combo_index": current_combo_index + 1,
				"weapon": current_weapon
			}
			finished.emit("Attacking", next_combo_data)
	

func _get_current_attack_data() -> AttackData:
	if current_weapon == null:
		return null
	
	var attack_type : AttackData.AttackType
	
	if current_combo.attacks.size() > 0 and current_combo_index < current_combo.attacks.size() - 1:
		attack_type = current_combo.attacks[current_combo_index].attack_type
	
	match attack_type:
		AttackData.AttackType.LIGHT:
			return current_weapon.weapon_data.light_attack_data
		AttackData.AttackType.HEAVY:
			return current_weapon.weapon_data.heavy_attack_data
		AttackData.AttackType.SPECIAL:
			return current_weapon.weapon_data.special_attack_data
	
	return null

func _apply_forward_push() -> void:
	var push_amount = current_combo.attacks[current_combo_index].forward_push
	
	if push_amount > 0.0:
		var push_direction = -owner.visuals.global_transform.basis.z
		
		if owner.has_method("move_and_slide"):
			owner.velocity += push_direction * push_amount
		elif owner.has_method("apply_impulse"):
			owner.apply_impulse(push_direction * push_amount)
		elif owner is Node3D:
			owner.global_position += push_direction * push_amount
	
