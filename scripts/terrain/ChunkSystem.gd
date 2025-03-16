@tool
extends Node3D

# Chunk settings
@export var chunk_size: int = 10
@export var render_distance: int = 3
@export var noise_seed: int = 0
@export var noise_resolution: float = 0.5
@export var noise_amplitude: float = 5.0
@export var height_threshold: float = 0.5
@export var update: bool = false

# Noise generator
var noise := FastNoiseLite.new()

# Dictionary to store loaded chunks
var loaded_chunks = {}

# Player reference
@onready var player: CharacterBody3D = $"../Player"


func _ready() -> void:
	# Initialize noise
	noise.seed = noise_seed
	

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		# Editor-only updates
		if update:
			update_chunks()
			update = false
	else:
		# Game runtime updates
		if player != null:
			update_chunks_around_player()

func update_chunks_around_player() -> void:
	# Get player position in chunk coordinates
	var player_chunk_x = floor(player.global_transform.origin.x / chunk_size)
	var player_chunk_z = floor(player.global_transform.origin.z / chunk_size)
	
	# Track which chunks should be active
	var active_chunks = {}
	
	# Generate or activate chunks in render distance
	for x in range(player_chunk_x - render_distance, player_chunk_x + render_distance + 1):
		for z in range(player_chunk_z - render_distance, player_chunk_z + render_distance + 1):
			var chunk_key = str(x) + "," + str(z)
			active_chunks[chunk_key] = true
			
			if not loaded_chunks.has(chunk_key):
				# Chunk isn't loaded, create it
				create_chunk(x, z)
	
	# Unload chunks outside render distance
	var chunks_to_remove = []
	for chunk_key in loaded_chunks.keys():
		if not active_chunks.has(chunk_key):
			chunks_to_remove.append(chunk_key)
	
	for chunk_key in chunks_to_remove:
		unload_chunk(chunk_key)

func create_chunk(chunk_x: int, chunk_z: int) -> void:
	# Create a new TerrainChunk node at runtime
	var chunk_instance = TerrainChunk.new()
	chunk_instance.name = "Chunk_" + str(chunk_x) + "_" + str(chunk_z)
	
	# Set chunk position
	chunk_instance.position = Vector3(chunk_x * chunk_size, 0, chunk_z * chunk_size)
	
	# Pass terrain generation parameters to the chunk
	chunk_instance.width = chunk_size + 1  # +1 for seamless connection
	chunk_instance.height = chunk_size + 1
	chunk_instance.chunk_position = Vector2(chunk_x, chunk_z)
	chunk_instance.noise_generator = noise
	chunk_instance.noise_resolution = noise_resolution
	chunk_instance.noise_amplitude = noise_amplitude
	chunk_instance.height_threshold = height_threshold
	
	# Add to scene and store reference
	add_child(chunk_instance)
	loaded_chunks[str(chunk_x) + "," + str(chunk_z)] = chunk_instance
	
	# Generate mesh
	chunk_instance.generate_terrain()

func unload_chunk(chunk_key: String) -> void:
	if loaded_chunks.has(chunk_key):
		var chunk = loaded_chunks[chunk_key]
		chunk.queue_free()
		loaded_chunks.erase(chunk_key)

func update_chunks() -> void:
	# For editor preview
	create_chunk(0, 0)

# Optional: Force regenerate all terrain with new parameters
func regenerate_all_terrain() -> void:
	for chunk_key in loaded_chunks.keys():
		var chunk = loaded_chunks[chunk_key]
		chunk.noise_resolution = noise_resolution
		chunk.noise_amplitude = noise_amplitude
		chunk.height_threshold = height_threshold
		chunk.generate_terrain()
