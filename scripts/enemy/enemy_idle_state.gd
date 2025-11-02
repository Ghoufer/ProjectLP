extends EnemyState

var timer : Timer
var friction : float = 0.2

func _enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	enemy.animation_player.play("Idle")
	
	timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	

func _update(_delta: float) -> void:
	if timer.is_stopped() and randi_range(0, 1):
		timer.queue_free()
		finished.emit(states.find_key(states.PATROLLING))
	
	if timer.is_stopped():
		timer.start()
	

func _physics_update(_delta: float) -> void:
	if enemy.velocity != Vector3.ZERO:
		enemy.velocity.x = lerp(enemy.velocity.x, 0.0, friction)
		enemy.velocity.z = lerp(enemy.velocity.z, 0.0, friction)
