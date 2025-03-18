extends MeshInstance3D

class_name TerrainChunk

var width: float = 10.0
var height: float = 10.0  # Used as depth in z for square chunks
var noise_resolution: float = 0.5
var noise_amplitude: float = 5.0
var height_threshold: float = 0.5
var chunk_position = Vector3(0, 0, 0)
var noise_generator: FastNoiseLite = null
var heights := []  # 2D array [x][z]
var surface_tool := SurfaceTool.new()
var terrain_material: ShaderMaterial

# Physics nodes
var static_body: StaticBody3D
var collision_shape: CollisionShape3D

func _init():
	terrain_material = load("res://scripts/shaders/low_poly_terrain.tres")

func _ready() -> void:
	# Create physics nodes
	static_body = StaticBody3D.new()
	static_body.name = "StaticBody"
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape"
	static_body.add_child(collision_shape)
	add_child(static_body)

func generate_terrain() -> void:
	heights = []
	
	if noise_generator == null:
		noise_generator = FastNoiseLite.new()
		noise_generator.seed = randi()
		noise_generator.noise_type = FastNoiseLite.TYPE_PERLIN
	
	var x_offset = chunk_position.x * (width - 1)
	var z_offset = chunk_position.z * (width - 1)
	
	for x in range(width):
		heights.append([])
		for z in range(width):
			var world_x = x + x_offset
			var world_z = z + z_offset
			var noise_value = noise_generator.get_noise_2d(
				world_x * noise_resolution,
				world_z * noise_resolution
			)
			var height = (noise_value + 1.0) * 0.5 * noise_amplitude
			heights[x].append(height)
	
	create_mesh_from_heights()

func create_mesh_from_heights() -> void:
	surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	if heights.size() == 0:
		return
	
	# Generate heightmap mesh with height_threshold
	for x in range(width - 1):
		for z in range(width - 1):
			var h00 = heights[x][z]
			var h10 = heights[x + 1][z]
			var h01 = heights[x][z + 1]
			var h11 = heights[x + 1][z + 1]
			
			# Triangle 1: (x,z), (x+1,z), (x,z+1)
			var v0 = Vector3(x, h00, z)
			var v1 = Vector3(x + 1, h10, z)
			var v2 = Vector3(x, h01, z + 1)
			var normal = (v1 - v0).cross(v2 - v0).normalized()
			
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v0)
			surface_tool.add_vertex(v1)
			surface_tool.add_vertex(v2)
			
			# Triangle 2: (x+1,z), (x+1,z+1), (x,z+1)
			v0 = Vector3(x + 1, h10, z)
			v1 = Vector3(x + 1, h11, z + 1)
			v2 = Vector3(x, h01, z + 1)
			normal = (v1 - v0).cross(v2 - v0).normalized()
			
			surface_tool.set_normal(normal)
			surface_tool.add_vertex(v0)
			surface_tool.add_vertex(v1)
			surface_tool.add_vertex(v2)
	
	surface_tool.generate_normals()
	self.mesh = surface_tool.commit()
	
	if self.mesh != null and self.mesh.get_surface_count() > 0 and terrain_material != null:
		self.mesh.surface_set_material(0, terrain_material)
	
	# Generate collision shape
	create_collision_shape()

func create_collision_shape() -> void:
	var shape = ConcavePolygonShape3D.new()
	var vertices = self.mesh.get_faces()  # Get the triangle faces from the mesh
	
	# Set the faces for the collision shape
	shape.set_faces(vertices)
	collision_shape.shape = shape
