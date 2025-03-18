extends MeshInstance3D

class_name TerrainChunk

# Terrain generation parameters
var width: float = 10.0
var height: float = 10.0
var noise_resolution: float = 0.5
var noise_amplitude: float = 5.0
var height_threshold: float = 0.5

# Chunk-specific data
var chunk_position = Vector3(0, 0, 0)
var noise_generator: FastNoiseLite = null
var heights := []
var surface_tool := SurfaceTool.new()

# Material/shader reference
var terrain_material : ShaderMaterial

func _init():
	terrain_material = load("res://scripts/shaders/low_poly_terrain.tres")

func _ready() -> void:
	# Don't generate terrain immediately - will be called by chunk system
	pass

# Original function maintained for direct calls (editor preview)
func generate_terrain() -> void:
	heights = []
	
	if noise_generator == null:
		noise_generator = FastNoiseLite.new()
		noise_generator.seed = randi()
	
	# Offset by chunk position in 3D
	var x_offset = chunk_position.x * (width - 1)
	var y_offset = chunk_position.y * (height - 1)
	var z_offset = chunk_position.z * (width - 1)
	
	# Generate heights
	for x in range(width):
		heights.append([])
		for y in range(height):
			heights[x].append([])
			for z in range(width):
				var world_x = x + x_offset
				var world_y = y + y_offset
				var world_z = z + z_offset
				var noise_value = noise_generator.get_noise_3d(
					world_x * noise_resolution, 
					world_y * noise_resolution,
					world_z * noise_resolution
				)
				
				heights[x][y].append(noise_value * noise_amplitude)
	
	create_mesh_from_heights()

# Create mesh from pre-computed heights
func create_mesh_from_heights() -> void:
	surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Make sure we have heights data
	if heights.size() == 0:
		return
	
	# Use marching cubes to generate mesh
	for x in range(width - 1):
		for y in range(height - 1):
			for z in range(width - 1):
				try_generate_cube(x, y, z)
	
	update_mesh()

# Separate function for better error handling
func try_generate_cube(x: int, y: int, z: int) -> void:
	var cube_index = 0
	
	# Make sure we have all required data for safety
	if x < 0 or y < 0 or z < 0:
		return
	if x >= width - 1 or y >= height - 1 or z >= width - 1:
		return
	if heights.size() <= x:
		return
	if heights[x].size() <= y: 
		return
	if heights[x][y].size() <= z:
		return
	
	# Check all 8 corners
	for i in range(8):
		if i >= MarchingTable.Corners.size():
			continue
		
		var corner = MarchingTable.Corners[i]
		var corner_x = x + corner.x
		var corner_y = y + corner.y
		var corner_z = z + corner.z
		
		# Skip this corner if out of range
		if corner_x < 0 or corner_x >= width:
			continue
		if corner_y < 0 or corner_y >= height:
			continue
		if corner_z < 0 or corner_z >= width:
			continue
			
		# Get corner height
		var corner_height = heights[corner_x][corner_y][corner_z]
		
		# Add to cube index
		if corner_height > height_threshold:
			cube_index |= (1 << i)
	
	# Skip if we don't have a valid cube_index
	if cube_index < 0 or cube_index >= MarchingTable.Triangles.size():
		return
	
	# Get triangle data
	var tri_table = MarchingTable.Triangles[cube_index]
	
	# Make sure we have valid data
	if not tri_table is Array:
		return
	
	# Generate triangles
	var i = 0
	while i < tri_table.size():
		# Break if we reach the end marker
		if tri_table[i] == -1:
			break
		
		# Make sure we have enough data for a triangle
		if i + 2 >= tri_table.size():
			break
		
		# Get edge indices
		var edge0_idx = tri_table[i]
		var edge1_idx = tri_table[i + 1]
		var edge2_idx = tri_table[i + 2]
		
		# Verify edge indices
		if edge0_idx < 0 or edge0_idx >= MarchingTable.Edges.size():
			i += 3
			continue
		if edge1_idx < 0 or edge1_idx >= MarchingTable.Edges.size():
			i += 3
			continue
		if edge2_idx < 0 or edge2_idx >= MarchingTable.Edges.size():
			i += 3
			continue
		
		# Get edge data
		var edge0 = MarchingTable.Edges[edge0_idx]
		var edge1 = MarchingTable.Edges[edge1_idx]
		var edge2 = MarchingTable.Edges[edge2_idx]
		
		# Calculate vertices
		var v0 = safe_interpolate_vertices(edge0, x, y, z)
		var v1 = safe_interpolate_vertices(edge1, x, y, z)
		var v2 = safe_interpolate_vertices(edge2, x, y, z)
		
		# Skip degenerate triangles
		if v0.distance_to(v1) < 0.001 or v1.distance_to(v2) < 0.001 or v2.distance_to(v0) < 0.001:
			i += 3
			continue
		
		# Calculate normal
		var normal = (v1 - v0).cross(v2 - v0)
		if normal.length() > 0.001:
			normal = normal.normalized()
		else:
			normal = Vector3(0, 1, 0)  # Fallback normal
		
		# Add vertices to surface
		surface_tool.set_normal(normal)
		surface_tool.add_vertex(v0)
		surface_tool.add_vertex(v1)
		surface_tool.add_vertex(v2)
		
		i += 3

# Safe interpolation function
func safe_interpolate_vertices(edge, x, y, z) -> Vector3:
	# Get edge positions
	var pos0 = Vector3(x, y, z) + edge[0]
	var pos1 = Vector3(x, y, z) + edge[1]
	
	# Safely access heights
	var height0 = get_height_safe(pos0.x, pos0.y, pos0.z)
	var height1 = get_height_safe(pos1.x, pos1.y, pos1.z)
	
	# Avoid division by zero
	if abs(height1 - height0) < 0.000001:
		return pos0
	
	var t = (height_threshold - height0) / (height1 - height0)
	t = clamp(t, 0.0, 1.0)
	
	return pos0.lerp(pos1, t)

# Safe access to height data
func get_height_safe(x, y, z) -> float:
	var ix = int(clamp(x, 0, width - 1))
	var iy = int(clamp(y, 0, height - 1))
	var iz = int(clamp(z, 0, width - 1))
	
	if ix < heights.size() and iy < heights[ix].size() and iz < heights[ix][iy].size():
		return heights[ix][iy][iz]
	
	return 0.0

func update_mesh() -> void:
	surface_tool.generate_normals()
	
	self.mesh = surface_tool.commit()
	
	if self.mesh != null and self.mesh.get_surface_count() > 0 and terrain_material != null:
		var mesh_color = StandardMaterial3D.new()
		mesh_color.albedo_color = Color(randf(), randf(), randf())
		mesh_color.next_pass = terrain_material
		
		self.mesh.surface_set_material(0, mesh_color)
		
