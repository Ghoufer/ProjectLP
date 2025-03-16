extends MeshInstance3D

class_name TerrainChunk

# Terrain generation parameters
var width: float = 10.0
var height: float = 10.0
var noise_resolution: float = 0.5
var noise_amplitude: float = 5.0
var height_threshold: float = 0.5

# Chunk-specific data
var chunk_position = Vector2(0, 0)
var noise_generator: FastNoiseLite = null
var heights := []
var surface_tool := SurfaceTool.new()

# Material/shader reference
var terrain_material = null

func _init():
	# Load the shader material
	terrain_material = load("res://scripts/shaders/low_poly_terrain.tres")

func _ready() -> void:
	generate_terrain()

func generate_terrain() -> void:
	# Initialize arrays
	heights = []
	
	# Use the provided noise generator or create one
	if noise_generator == null:
		noise_generator = FastNoiseLite.new()
		noise_generator.seed = randi()
	
	# Initialize surface tool
	surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Populate heights array with noise values
	# Offset by chunk position
	var x_offset = chunk_position.x * (width - 1)
	var z_offset = chunk_position.y * (height - 1)
	
	for x in range(width):
		heights.append([])
		for y in range(height):
			heights[x].append([])
			for z in range(width):
				var world_x = x + x_offset
				var world_z = z + z_offset
				var noise_value = noise_generator.get_noise_3d(
					world_x * noise_resolution, 
					y * noise_resolution, 
					world_z * noise_resolution
				)
				
				heights[x][y].append(noise_value * noise_amplitude)
	
	# March cubes
	for x in range(width - 1):
		for y in range(height - 1):
			for z in range(width - 1):
				var cube_index = 0
				var cube_positions = []
				
				for i in range(8):
					var corner = MarchingTable.Corners[i] + Vector3(x, y, z)
					var corner_height = heights[int(corner.x)][int(corner.y)][int(corner.z)]
					
					cube_positions.append(corner_height)
					
					if (corner_height > height_threshold): cube_index |= (1 << i)
				
				# Use cube_index to find the correct triangles from the table
				var tri_table = MarchingTable.Triangles[cube_index]
				
				for i in range(0, 15, 3):
					var t0 = tri_table[i]
					var t1 = tri_table[i + 1]
					var t2 = tri_table[i + 2]
					
					if (t0 == -1): break
					
					# Add the triangles
					var edge0 = MarchingTable.Edges[t0]
					var edge1 = MarchingTable.Edges[t1]
					var edge2 = MarchingTable.Edges[t2]
					
					# Interpolate vertices
					var v0 = interpolate_vertices(edge0, heights, x, y, z)
					var v1 = interpolate_vertices(edge1, heights, x, y, z)
					var v2 = interpolate_vertices(edge2, heights, x, y, z)
					
					# Calculate normals for lighting
					var normal = (v1 - v0).cross(v2 - v0).normalized()
					
					# Add normals
					surface_tool.set_normal(normal)
					
					# Add to vertices and triangles lists
					surface_tool.add_vertex(v0)
					surface_tool.add_vertex(v1)
					surface_tool.add_vertex(v2)
	
	# Generate mesh and set material
	update_mesh()

func interpolate_vertices(edge, lerp_heights, x, y, z) -> Vector3:
	var pos0 = Vector3(x, y, z) + edge[0]
	var pos1 = Vector3(x, y, z) + edge[1]
	
	var height0 = lerp_heights[int(pos0.x)][int(pos0.y)][int(pos0.z)]
	var height1 = lerp_heights[int(pos1.x)][int(pos1.y)][int(pos1.z)]
	
	# Linear interpolation between two points
	var t = (height_threshold - height0) / (height1 - height0)
	
	return pos0.lerp(pos1, t)

func update_mesh() -> void:
	# Generate normals for better lighting
	surface_tool.generate_normals()
	
	self.mesh = surface_tool.commit()
	
	# Only set material if mesh was successfully created and has surfaces
	if self.mesh != null and self.mesh.get_surface_count() > 0 and terrain_material != null:
		self.mesh.surface_set_material(0, terrain_material)
