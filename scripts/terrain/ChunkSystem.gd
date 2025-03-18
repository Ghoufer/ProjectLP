extends Node3D

# Chunk settings
@export var chunk_size: int = 8
@export var render_distance: int = 16
@export var unload_distance: int = 22
@export var noise_seed: int = 0
@export var noise_resolution: float = 0.5
@export var noise_amplitude: float = 10.0
@export var update: bool = false
@export var vertical_chunks: int = 4

# Noise generator
var noise := FastNoiseLite.new()

# Dictionary to store loaded chunks
var loaded_chunks = {}

# Thread pool management
var thread_pool = []
var max_threads: int = 2
var active_threads: int = 0
var chunk_queue = []
var mutex = Mutex.new()
var prev_player_chunk_x: int = 0
var prev_player_chunk_y: int = 0
var prev_player_chunk_z: int = 0

# Player reference
@onready var player: CharacterBody3D = $"../Player"

func _ready() -> void:
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	for i in range(max_threads):
		thread_pool.append(Thread.new())
	
	if unload_distance <= render_distance:
		unload_distance = render_distance + 4

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if update:
			update_chunks()
			update = false
	else:
		if player != null:
			update_chunks_around_player()
	
	if chunk_queue.size() > 0 and active_threads < max_threads:
		mutex.lock()
		while chunk_queue.size() > 0 and active_threads < max_threads:
			for thread in thread_pool:
				if not thread.is_started() and chunk_queue.size() > 0:
					var chunk_data = chunk_queue.pop_front()
					active_threads += 1
					thread.start(_process_chunk_queue.bind(chunk_data))
					break
		mutex.unlock()

func update_chunks_around_player() -> void:
	var player_chunk_x = floor(player.global_position.x / chunk_size)
	var player_chunk_y = floor(player.global_position.y / chunk_size)
	var player_chunk_z = floor(player.global_position.z / chunk_size)
	
	if player_chunk_x == prev_player_chunk_x and \
		player_chunk_y == prev_player_chunk_y and \
		player_chunk_z == prev_player_chunk_z:
		return
	
	prev_player_chunk_x = player_chunk_x
	prev_player_chunk_y = player_chunk_y
	prev_player_chunk_z = player_chunk_z
	
	# Only load chunks at y=0 (2D terrain)
	for x in range(player_chunk_x - render_distance, player_chunk_x + render_distance + 1):
		for z in range(player_chunk_z - render_distance, player_chunk_z + render_distance + 1):
			var chunk_key = str(x) + ",0," + str(z)  # Fix y to 0
			if not loaded_chunks.has(chunk_key):
				mutex.lock()
				chunk_queue.append({
					"x": x,
					"y": 0,  # Force y=0 for 2D terrain
					"z": z,
					"key": chunk_key
				})
				mutex.unlock()
	
	var chunks_to_remove = []
	for chunk_key in loaded_chunks.keys():
		var chunk_coords = chunk_key.split(",")
		var chunk_x = int(chunk_coords[0])
		var chunk_y = int(chunk_coords[1])
		var chunk_z = int(chunk_coords[2])
		
		var distance_x = abs(chunk_x - player_chunk_x)
		var distance_y = abs(chunk_y - player_chunk_y)
		var distance_z = abs(chunk_z - player_chunk_z)
		var max_distance = max(distance_x, max(distance_y, distance_z))
		
		if max_distance > unload_distance:
			chunks_to_remove.append(chunk_key)
	
	for chunk_key in chunks_to_remove:
		unload_chunk(chunk_key)

func _process_chunk_queue(chunk_data) -> void:
	var chunk_x = chunk_data["x"]
	var chunk_y = chunk_data["y"]
	var chunk_z = chunk_data["z"]
	var chunk_key = chunk_data["key"]
	
	var heights = generate_chunk_heights(chunk_x, chunk_y, chunk_z)
	call_deferred("_create_chunk_mesh", chunk_x, chunk_y, chunk_z, chunk_key, heights)

func generate_chunk_heights(chunk_x, chunk_y, chunk_z) -> Array:
	var thread_noise = FastNoiseLite.new()
	thread_noise.seed = noise_seed
	thread_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	var heights = []
	var x_offset = chunk_x * chunk_size
	var z_offset = chunk_z * chunk_size
	
	for x in range(chunk_size + 1):
		heights.append([])
		for z in range(chunk_size + 1):
			var world_x = x + x_offset
			var world_z = z + z_offset
			var noise_value = thread_noise.get_noise_2d(
				world_x * noise_resolution,
				world_z * noise_resolution
			)
			# Map noise (-1 to 1) to height (0 to noise_amplitude)
			var height = (noise_value + 1.0) * 0.5 * noise_amplitude
			heights[x].append(height)
	
	return heights

func _create_chunk_mesh(chunk_x, chunk_y, chunk_z, chunk_key, heights) -> void:
	for thread in thread_pool:
		if thread.is_started() and not thread.is_alive():
			thread.wait_to_finish()
			active_threads -= 1
			break
	
	if not loaded_chunks.has(chunk_key):
		var chunk_instance = TerrainChunk.new()
		chunk_instance.name = "Chunk_" + str(chunk_x) + "_" + str(chunk_y) + "_" + str(chunk_z)
		chunk_instance.position = Vector3(chunk_x * chunk_size, 0, chunk_z * chunk_size)  # y=0 for base position
		chunk_instance.width = chunk_size + 1
		chunk_instance.height = chunk_size + 1
		chunk_instance.chunk_position = Vector3(chunk_x, chunk_y, chunk_z)
		chunk_instance.noise_generator = noise
		chunk_instance.noise_resolution = noise_resolution
		chunk_instance.noise_amplitude = noise_amplitude
		chunk_instance.heights = heights
		
		add_child(chunk_instance)
		loaded_chunks[chunk_key] = chunk_instance
		chunk_instance.create_mesh_from_heights()

func unload_chunk(chunk_key: String) -> void:
	if loaded_chunks.has(chunk_key):
		var chunk = loaded_chunks[chunk_key]
		chunk.queue_free()
		loaded_chunks.erase(chunk_key)

func update_chunks() -> void:
	create_chunk(0, 0, 0)

func create_chunk(chunk_x: int, chunk_y: int, chunk_z: int) -> void:
	var chunk_instance = TerrainChunk.new()
	chunk_instance.name = "Chunk_" + str(chunk_x) + "_" + str(chunk_y) + "_" + str(chunk_z)
	chunk_instance.position = Vector3(chunk_x * chunk_size, 0, chunk_z * chunk_size)
	chunk_instance.width = chunk_size + 1
	chunk_instance.height = chunk_size + 1
	chunk_instance.chunk_position = Vector3(chunk_x, chunk_y, chunk_z)
	chunk_instance.noise_generator = noise
	chunk_instance.noise_resolution = noise_resolution
	chunk_instance.noise_amplitude = noise_amplitude
	
	add_child(chunk_instance)
	loaded_chunks[str(chunk_x) + "," + str(chunk_y) + "," + str(chunk_z)] = chunk_instance
	chunk_instance.generate_terrain()

func regenerate_all_terrain() -> void:
	for chunk_key in loaded_chunks.keys():
		var chunk = loaded_chunks[chunk_key]
		chunk.noise_resolution = noise_resolution
		chunk.noise_amplitude = noise_amplitude
		chunk.generate_terrain()

func _exit_tree() -> void:
	for thread in thread_pool:
		if thread.is_started():
			thread.wait_to_finish()
