extends MeshInstance3D

class_name TerrainChunk

signal generation_finished

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

# Threading variables
var is_generating: bool = false
var generation_thread: Thread = null
var generated_mesh_data: Dictionary = {}

func _init():
	# Load the shader material
	terrain_material = load("res://scripts/shaders/low_poly_terrain.tres")

func _ready() -> void:
	pass

func start_async_generation() -> void:
	if is_generating:
		return
	is_generating = true
	generation_thread = Thread.new()
	generation_thread.start(generate_terrain_async)

func generate_terrain_async(userdata) -> void:
	# Generate terrain data in the thread
	var surface_tool_data = generate_terrain_data()
	
	# Store the generated data
	generated_mesh_data = surface_tool_data
	
	# Defer the mesh update to the main thread
	call_deferred("finish_generation")

func generate_terrain_data() -> Dictionary:
	# Initialize arrays
	var local_heights = []
	var local_surface_tool = SurfaceTool.new()
	local_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Use the provided noise generator or create one
	var local_noise_generator = noise_generator
	if local_noise_generator == null:
		local_noise_generator = FastNoiseLite.new()
		local_noise_generator.seed = randi()
	
	# Populate heights array with noise values
	# Offset by chunk position
	var x_offset = chunk_position.x * (width - 1)
	var z_offset = chunk_position.y * (height - 1)
	
	for x in range(width):
		local_heights.append([])
		for y in range(height):
			local_heights[x].append([])
			for z in range(width):
				var world_x = x + x_offset
				var world_z = z + z_offset
				var noise_value = local_noise_generator.get_noise_3d(
					world_x * noise_resolution, 
					y * noise_resolution, 
					world_z * noise_resolution
				)
				
				local_heights[x][y].append(noise_value * noise_amplitude)
	
	# March cubes
	for x in range(width - 1):
		for y in range(height - 1):
			for z in range(width - 1):
				var cube_index = 0
				var cube_positions = []
				
				for i in range(8):
					var corner = MarchingTable.Corners[i] + Vector3(x, y, z)
					var corner_height = local_heights[int(corner.x)][int(corner.y)][int(corner.z)]
					
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
					
					var v0 = interpolate_vertices(edge0, local_heights, x, y, z)
					var v1 = interpolate_vertices(edge1, local_heights, x, y, z)
					var v2 = interpolate_vertices(edge2, local_heights, x, y, z)
					
					var normal = (v1 - v0).cross(v2 - v0).normalized()
					
					local_surface_tool.set_normal(normal)
					local_surface_tool.add_vertex(v0)
					local_surface_tool.add_vertex(v1)
					local_surface_tool.add_vertex(v2)
	
	# Generate normals for better lighting
	local_surface_tool.generate_normals()
	
	return {
		"surface_tool": local_surface_tool,
		"heights": local_heights
	}

func finish_generation() -> void:
	is_generating = false
	if generation_thread != null:
		generation_thread.wait_to_finish()
		generation_thread = null
	
	# Apply the generated data on the main thread
	if not generated_mesh_data.is_empty():
		var st = generated_mesh_data["surface_tool"]
		self.mesh = st.commit()
		
		if self.mesh != null and self.mesh.get_surface_count() > 0 and terrain_material != null:
			self.mesh.surface_set_material(0, terrain_material)
		
		generated_mesh_data.clear()
	
	emit_signal("generation_finished")

func interpolate_vertices(edge, lerp_heights, x, y, z) -> Vector3:
	var pos0 = Vector3(x, y, z) + edge[0]
	var pos1 = Vector3(x, y, z) + edge[1]
	
	var height0 = lerp_heights[int(pos0.x)][int(pos0.y)][int(pos0.z)]
	var height1 = lerp_heights[int(pos1.x)][int(pos1.y)][int(pos1.z)]
	
	var t = (height_threshold - height0) / (height1 - height0)
	
	return pos0.lerp(pos1, t)

func _exit_tree() -> void:
	if is_generating and generation_thread != null:
		generation_thread.wait_to_finish()
		generation_thread = null
