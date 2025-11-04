extends Node
class_name CombatComponent

@export var can_combo : bool = true
@export var current_weapon : Weapon

@onready var stats : Stats = get_parent().stats
@onready var state_machine : StateMachine = get_parent().get_node("StateMachine")

var combo_timer : Timer
var pending_combo_input : bool = false
var current_combo_sequence : Combo = null
var current_combo_index : int = 0
var animation_blend : float = 0.25

func _ready() -> void:
	combo_timer = Timer.new()
	combo_timer.one_shot = true
	combo_timer.wait_time = 1.0
	add_child(combo_timer)
	

func equip_weapon(weapon: Weapon) -> void:
	if current_weapon:
		current_weapon.unequip()
	current_weapon = weapon
	current_weapon.equip(get_parent())

func attack(attack_type: AttackData.AttackType) -> void:
	if not can_attack():
		return
	
	if combo_timer.time_left == 0:
		combo_timer.start()
		current_combo_index = 0
		current_combo_sequence = null
	
	var combo_sequence : Combo = get_current_combo_sequence(attack_type)
	
	if current_combo_sequence == combo_sequence and \
		not current_combo_index + 1 > current_combo_sequence.attacks.size() - 1:
			current_combo_index += 1
	else:
		current_combo_index = 0
		current_combo_sequence = combo_sequence
	
	var combo_data : Dictionary = {
		"combo_index": current_combo_index,
		"combo_sequence": combo_sequence,
		"weapon": current_weapon
	}
	
	state_machine._transition_to_next_state("Attacking", combo_data)
	

func can_attack() -> bool:
	return stats.current_health > 0

func get_current_combo_sequence(attack_type: AttackData.AttackType) -> Combo:
	# If we're already in a combo, try to continue it]
	if current_combo_sequence != null and current_combo_index < current_combo_sequence.attacks.size() - 1:
		var next_index = current_combo_index + 1
		if current_combo_sequence.attacks[next_index].attack_type == attack_type:
			return current_combo_sequence
	
	# Otherwise, search for a new combo starting with this attack type
	if current_weapon and current_weapon.weapon_data.combos.size() > 0:
		for combo in current_weapon.weapon_data.combos:
			if combo.attacks.size() > 0 and combo.attacks[0].attack_type == attack_type:
				return combo
	
	# Fallback: create simple combo with generic animation
	var simple_combo : Combo = Combo.new()
	var attack_data : AttackData = AttackData.new()
	
	match attack_type:
		AttackData.AttackType.LIGHT:
			attack_data = current_weapon.weapon_data.light_attack_data
		AttackData.AttackType.HEAVY:
			attack_data = current_weapon.weapon_data.heavy_attack_data
		AttackData.AttackType.SPECIAL:
			attack_data = current_weapon.weapon_data.special_attack_data
	
	simple_combo.attacks.append(attack_data)
	simple_combo.damage_multiplier.append(1.0)
	
	return simple_combo

func play_attack_animation(combo: Combo, attack_index: int) -> void:
	var anim_name : String = combo.attacks[attack_index].animation_name
	
	# Only try to play if an animation name was specified
	if not anim_name.is_empty() and owner.animation_player and owner.animation_player.has_animation(anim_name):
		owner.animation_player.play(anim_name, animation_blend)
	elif not anim_name.is_empty():
		push_warning("Animation '%s' not found on %s" % [anim_name, get_parent().name])
	

func take_damage(amount: int, direction: Vector3 = Vector3.ZERO) -> void:
	var final_damage : float = max(1, amount - stats.current_defence)
	
	stats.current_health -= int(final_damage)
	
	if direction != Vector3.ZERO and get_parent().has_method("apply_knockback"):
		get_parent().apply_knockback(direction * final_damage * 10.0)
	
	#if state_machine.state.name != "Attacking":
		#state_machine._transition_to_next_state("Hit", {"damage": final_damage, "direction": direction})
	
