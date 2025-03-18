extends Node3D

# Chunk settings
@export var chunk_size: int = 2
@export var render_distance: int = 6
@export var unload_distance: int = 16  # Increased to ensure a buffer (must be > render_distance)
@export var noise_seed: int = 0
@export var noise_resolution: float = 0.5
@export var noise_amplitude: float = 10.0
@export var height_threshold: float = 0.5
@export var update: bool = false
@export var vertical_chunks: int = 4

# Noise generator
var noise := FastNoiseLite.new()

# Dictionary to store loaded chunks
var loaded_chunks = {}

# Threads
var chunk_threads = []
var active_threads = []
var max_threads = 2
var thread_data = []
var chunk_queue = []
var mutex = Mutex.new()
var prev_player_chunk_x: int = 0
var prev_player_chunk_y: int = 0
var prev_player_chunk_z: int = 0
var queued_chunks = {}  # Track chunks in the queue

# Player reference
@onready var player: CharacterBody3D = %Player

func _ready() -> void:
	noise.seed = noise_seed
	
	# Initialize threads
	for i in range(max_threads):
		chunk_threads.append(Thread.new())
		active_threads.append(false)
		thread_data.append(null)
	
	if unload_distance <= render_distance:
		unload_distance = render_distance + 4  # Ensure a sufficient buffer

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if update:
			update_chunks()
			update = false
	else:
		if player != null:
			update_chunks_around_player()
	
	# Check for completed threads
	for i in range(max_threads):
		if active_threads[i] and not chunk_threads[i].is_alive():
			chunk_threads[i].wait_to_finish()
			active_threads[i] = false
			
			# Process the result if needed
			if thread_data[i] != null:
				_create_chunk_mesh(
					thread_data[i].x,
					thread_data[i].y,
					thread_data[i].z,
					thread_data[i].key,
					thread_data[i].heights
				)
				thread_data[i] = null
	
	# Start new threads if available
	mutex.lock()
	for i in range(max_threads):
		if not active_threads[i] and chunk_queue.size() > 0:
			var chunk_data = chunk_queue.pop_front()
			thread_data[i] = chunk_data
			active_threads[i] = true
			queued_chunks.erase(chunk_data.key)
			chunk_threads[i].start(_process_chunk_queue.bind(chunk_data, i))
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
	
	# Track which chunks are needed
	var needed_chunks = {}
	
	# Identify needed chunks
	for x in range(player_chunk_x - render_distance, player_chunk_x + render_distance + 1):
		for y in range(player_chunk_y - render_distance, player_chunk_y + render_distance + 1):
			for z in range(player_chunk_z - render_distance, player_chunk_z + render_distance + 1):
				var chunk_key = str(x) + "," + str(y) + "," + str(z)
				needed_chunks[chunk_key] = true
				
				if not loaded_chunks.has(chunk_key) and not queued_chunks.has(chunk_key):
					mutex.lock()
					chunk_queue.append({
						"x": x,
						"y": y,
						"z": z,
						"key": chunk_key
					})
					queued_chunks[chunk_key] = true
					mutex.unlock()
	
	# Unload chunks outside unload_distance
	var chunks_to_remove = []
	for chunk_key in loaded_chunks.keys():
		if not needed_chunks.has(chunk_key):
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
	

func _process_chunk_queue(chunk_data, thread_idx := 0) -> void:
	var chunk_x = chunk_data.x
	var chunk_y = chunk_data.y
	var chunk_z = chunk_data.z
	
	var heights = generate_chunk_heights(chunk_x, chunk_y, chunk_z)
	
	# Store the heights in thread_data for later processing
	mutex.lock()
	if thread_data[thread_idx] != null:
		thread_data[thread_idx].heights = heights
	mutex.unlock()
	


func generate_chunk_heights(chunk_x, chunk_y, chunk_z) -> Array:
	var thread_noise = FastNoiseLite.new()
	thread_noise.seed = noise_seed
	
	var heights = []
	var x_offset = chunk_x * chunk_size
	var y_offset = chunk_y * chunk_size
	var z_offset = chunk_z * chunk_size
	
	for x in range(chunk_size + 1):
		heights.append([])
		for y in range(chunk_size + 1):
			heights[x].append([])
			for z in range(chunk_size + 1):
				var world_x = x + x_offset
				var world_y = y + y_offset
				var world_z = z + z_offset
				var noise_value = thread_noise.get_noise_3d(
					world_x * noise_resolution, 
					world_y * noise_resolution,
					world_z * noise_resolution
				)
				heights[x][y].append(noise_value * noise_amplitude)
	
	return heights

func _create_chunk_mesh(chunk_x, chunk_y, chunk_z, chunk_key, heights) -> void:
	if not loaded_chunks.has(chunk_key):
		var chunk_instance = TerrainChunk.new()
		chunk_instance.name = "Chunk_" + str(chunk_x) + "_" + str(chunk_y) + "_" + str(chunk_z)
		chunk_instance.position = Vector3(chunk_x * chunk_size, chunk_y * chunk_size, chunk_z * chunk_size)
		chunk_instance.width = chunk_size + 1
		chunk_instance.height = chunk_size + 1
		chunk_instance.chunk_position = Vector3(chunk_x, chunk_y, chunk_z)
		chunk_instance.noise_generator = noise
		chunk_instance.noise_resolution = noise_resolution
		chunk_instance.noise_amplitude = noise_amplitude
		chunk_instance.height_threshold = height_threshold
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
	# For editor preview, create a small stack of chunks
	for y in range(-1, 2):
		create_chunk(0, y, 0)

func create_chunk(chunk_x: int, chunk_y: int, chunk_z: int) -> void:
	# For direct creation (editor preview)
	var chunk_instance = TerrainChunk.new()
	chunk_instance.name = "Chunk_" + str(chunk_x) + "_" + str(chunk_y) + "_" + str(chunk_z)
	# Set chunk position
	chunk_instance.position = Vector3(chunk_x * chunk_size, chunk_y * chunk_size, chunk_z * chunk_size)
	
	# Pass terrain generation parameters to the chunk
	chunk_instance.width = chunk_size + 1
	chunk_instance.height = chunk_size + 1
	chunk_instance.chunk_position = Vector3(chunk_x, chunk_y, chunk_z)
	chunk_instance.noise_generator = noise
	chunk_instance.noise_resolution = noise_resolution
	chunk_instance.noise_amplitude = noise_amplitude
	chunk_instance.height_threshold = height_threshold
	
	add_child(chunk_instance)
	loaded_chunks[str(chunk_x) + "," + str(chunk_y) + "," + str(chunk_z)] = chunk_instance
	
	chunk_instance.generate_terrain()

func regenerate_all_terrain() -> void:
	for chunk_key in loaded_chunks.keys():
		var chunk = loaded_chunks[chunk_key]
		chunk.noise_resolution = noise_resolution
		chunk.noise_amplitude = noise_amplitude
		chunk.height_threshold = height_threshold
		chunk.generate_terrain()

func _exit_tree() -> void:
	# Make sure all threads are properly closed
	for i in range(max_threads):
		if active_threads[i]:
			chunk_threads[i].wait_to_finish()
