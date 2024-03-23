extends Node

var terrain_heightmap

func _ready():
	generate_heightmap()

func generate_heightmap():
	var rng = RandomNumberGenerator.new()
	
	terrain_heightmap = FastNoiseLite.new()
	terrain_heightmap.seed = rng.randi()
	terrain_heightmap.noise_type = FastNoiseLite.TYPE_PERLIN
