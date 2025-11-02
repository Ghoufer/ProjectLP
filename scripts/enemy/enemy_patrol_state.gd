extends EnemyState

var nav_region : NavigationRegion3D

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	enemy.animation_player.play("Walk")
	
	if not nav_region:
		nav_region = get_tree().get_first_node_in_group("NavRegion")
	
	# Generate a random direction and distance
	var random_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	var random_distance = randf_range(2, 5)  # Between 5-10 meters
	var target_position = enemy.global_position + random_direction * random_distance
	
	# Use the navigation agent's map instead
	var map_rid = enemy.nav_agent.get_navigation_map()
	if map_rid:
		target_position = NavigationServer3D.map_get_closest_point(
			map_rid,
			target_position
		)
	
	enemy.nav_agent.target_position = target_position
	

func _physics_update(_delta: float) -> void:
	var current_location : Vector3 = enemy.global_position
	var next_location : Vector3 = enemy.nav_agent.get_next_path_position()
	var direction : Vector3 = (next_location - current_location).normalized()
	var new_velocity : Vector3 = direction * enemy.enemy_data.stats.current_move_speed
	
	if enemy.nav_agent.is_target_reached():
		finished.emit(states.find_key(states.IDLE))
	
	enemy.velocity = enemy.velocity.move_toward(new_velocity, _delta)
	
	if direction.length() > 0.01:
		if abs(direction.dot(Vector3.UP)) < 0.99:
			var target_basis = Basis.looking_at(-direction, Vector3.UP)
			enemy.basis = enemy.basis.slerp(target_basis, _delta * 5.0)
	
	enemy.move_and_slide()
	
