extends Node3D

# Chunk settings
@export var chunk_size: int = 8
@export var render_distance: int = 1
@export var noise_seed: int = 0
@export var noise_resolution: float = 0.5
@export var noise_amplitude: float = 10.0
@export var height_threshold: float = 0.5
@export var update: bool = false
@export var vertical_chunks: int = 4
# New: Noise falloff parameters
@export var noise_falloff_start: float = 50.0  # Height where noise starts to fade
@export var noise_falloff_range: float = 25.0  # Range over which noise fades to zero

# Noise generator
var noise := FastNoiseLite.new()

# Dictionary to store loaded chunks
var loaded_chunks = {}

# Player reference
@onready var player: CharacterBody3D = $"../Player"

func _ready() -> void:
	noise.seed = noise_seed

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if update:
			update_chunks()
			update = false
	else:
		if player != null:
			update_chunks_around_player()

func update_chunks_around_player() -> void:
	var player_chunk_x = floor(player.global_position.x / chunk_size)
	var player_chunk_y = floor(player.global_position.y / chunk_size)
	var player_chunk_z = floor(player.global_position.z / chunk_size)
	
	var active_chunks = {}
	
	# Calculate min and max Y chunks based on noise falloff
	var max_height = noise_falloff_start + noise_falloff_range
	var min_y = floor(-max_height / chunk_size)
	var max_y = floor(max_height / chunk_size)
	
	for x in range(player_chunk_x - render_distance, player_chunk_x + render_distance + 1):
		for y in range(max(min_y, player_chunk_y - render_distance), 
					  min(max_y, player_chunk_y + render_distance) + 1):
			for z in range(player_chunk_z - render_distance, player_chunk_z + render_distance + 1):
				var chunk_key = str(x) + "," + str(y) + "," + str(z)
				active_chunks[chunk_key] = true
				
				if not loaded_chunks.has(chunk_key):
					create_chunk(x, y, z)
	
	var chunks_to_remove = []
	for chunk_key in loaded_chunks.keys():
		if not active_chunks.has(chunk_key):
			chunks_to_remove.append(chunk_key)
	
	for chunk_key in chunks_to_remove:
		unload_chunk(chunk_key)

func create_chunk(chunk_x: int, chunk_y: int, chunk_z: int) -> void:
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
	# New: Pass noise falloff parameters
	chunk_instance.noise_falloff_start = noise_falloff_start
	chunk_instance.noise_falloff_range = noise_falloff_range
	
	add_child(chunk_instance)
	loaded_chunks[str(chunk_x) + "," + str(chunk_y) + "," + str(chunk_z)] = chunk_instance
	
	chunk_instance.generate_terrain()

func unload_chunk(chunk_key: String) -> void:
	if loaded_chunks.has(chunk_key):
		var chunk = loaded_chunks[chunk_key]
		chunk.queue_free()
		loaded_chunks.erase(chunk_key)

func update_chunks() -> void:
	var max_height = noise_falloff_start + noise_falloff_range
	var min_y = floor(-max_height / chunk_size)
	var max_y = floor(max_height / chunk_size)
	
	for y in range(max(-1, min_y), min(2, max_y + 1)):
		create_chunk(0, y, 0)

func regenerate_all_terrain() -> void:
	for chunk_key in loaded_chunks.keys():
		var chunk = loaded_chunks[chunk_key]
		chunk.noise_resolution = noise_resolution
		chunk.noise_amplitude = noise_amplitude
		chunk.height_threshold = height_threshold
		chunk.noise_falloff_start = noise_falloff_start
		chunk.noise_falloff_range = noise_falloff_range
		chunk.generate_terrain()
