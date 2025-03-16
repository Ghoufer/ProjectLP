extends MeshInstance3D

class_name TerrainChunk

# Terrain generation parameters
var width: float = 10.0
var height: float = 10.0
var noise_resolution: float = 0.5
var noise_amplitude: float = 5.0
var height_threshold: float = 0.5
# New: Noise falloff parameters
var noise_falloff_start: float = 50.0
var noise_falloff_range: float = 25.0
var sea_floor_height: float = -0.01

# Chunk-specific data
var chunk_position = Vector3(0, 0, 0)
var noise_generator: FastNoiseLite = null
var heights := []
var surface_tool := SurfaceTool.new()

# Material/shader reference
var terrain_material = null

func _init():
	terrain_material = load("res://scripts/shaders/low_poly_terrain.tres")

func _ready() -> void:
	generate_terrain()

func generate_terrain() -> void:
	heights = []
	
	if noise_generator == null:
		noise_generator = FastNoiseLite.new()
		noise_generator.seed = randi()
	
	surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var x_offset = chunk_position.x * (width - 1)
	var y_offset = chunk_position.y * (height - 1)
	var z_offset = chunk_position.z * (width - 1)
	
	for x in range(width):
		heights.append([])
		for y in range(height):
			heights[x].append([])
			for z in range(width):
				var world_x = x + x_offset
				var world_y = y + y_offset
				var world_z = z + z_offset
				
				var world_height = world_y * height
				
				# Calculate noise falloff factor
				var falloff_factor = 1.0
				var abs_height = abs(world_height)
				
				if abs_height > noise_falloff_start:
					var falloff_distance = abs_height - noise_falloff_start
					falloff_factor = clamp(1.0 - (falloff_distance / noise_falloff_range), 0.0, 1.0)
					falloff_factor = pow(falloff_factor, 2.0)  # Square for smoother falloff
				
				# Get base noise value
				var noise_value = noise_generator.get_noise_3d(
					world_x * noise_resolution, 
					world_y * noise_resolution,
					world_z * noise_resolution
				)
				
				# Apply falloff to noise
				var adjusted_noise = noise_value * noise_amplitude * falloff_factor
				
				# Optional: Add slight height-based variation
				var height_factor = clamp((noise_falloff_start - abs_height) / noise_falloff_start, 0.0, 1.0)
				adjusted_noise *= (1.0 + height_factor * 0.5)  # Boost terrain near center
				
				# Ensure terrain does not go below sea floor height
				if world_height < sea_floor_height:
					adjusted_noise = sea_floor_height - world_height
				
				heights[x][y].append(adjusted_noise)
	
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
				
				var tri_table = MarchingTable.Triangles[cube_index]
				
				for i in range(0, 15, 3):
					var t0 = tri_table[i]
					var t1 = tri_table[i + 1]
					var t2 = tri_table[i + 2]
					
					if (t0 == -1): break
					
					var edge0 = MarchingTable.Edges[t0]
					var edge1 = MarchingTable.Edges[t1]
					var edge2 = MarchingTable.Edges[t2]
					
					var v0 = interpolate_vertices(edge0, heights, x, y, z)
					var v1 = interpolate_vertices(edge1, heights, x, y, z)
					var v2 = interpolate_vertices(edge2, heights, x, y, z)
					
					var normal = (v1 - v0).cross(v2 - v0).normalized()
					
					surface_tool.set_normal(normal)
					
					surface_tool.add_vertex(v0)
					surface_tool.add_vertex(v1)
					surface_tool.add_vertex(v2)
	
	update_mesh()

func interpolate_vertices(edge, lerp_heights, x, y, z) -> Vector3:
	var pos0 = Vector3(x, y, z) + edge[0]
	var pos1 = Vector3(x, y, z) + edge[1]
	
	var height0 = lerp_heights[int(pos0.x)][int(pos0.y)][int(pos0.z)]
	var height1 = lerp_heights[int(pos1.x)][int(pos1.y)][int(pos1.z)]
	
	var t = (height_threshold - height0) / (height1 - height0)
	
	return pos0.lerp(pos1, t)

func update_mesh() -> void:
	surface_tool.generate_normals()
	
	self.mesh = surface_tool.commit()
	
	if self.mesh != null and self.mesh.get_surface_count() > 0 and terrain_material != null:
		self.mesh.surface_set_material(0, terrain_material)
