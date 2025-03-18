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

# Optimization: Precomputed voxel states and edge vertex cache
var voxel_states = []  # true = solid, false = air
var edge_vertex_cache = {}

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
	
	# Optimization: Precompute voxel states
	precompute_voxel_states()
	create_mesh_from_heights()

# Optimization: Precompute which points are above/below threshold
func precompute_voxel_states() -> void:
	voxel_states = []
	for x in range(width):
		var plane = []
		for y in range(height):
			var line = []
			for z in range(width):
				line.append(heights[x][y][z] > height_threshold)
			plane.append(line)
		voxel_states.append(plane)

# Create mesh from pre-computed heights - optimized version
func create_mesh_from_heights() -> void:
	surface_tool.clear()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Make sure we have heights data
	if heights.size() == 0:
		return
	
	# Optimization: Use batch processing for vertices
	var vertices = []
	var normals = []
	
	# Use marching cubes to generate mesh
	for x in range(width - 1):
		for y in range(height - 1):
			for z in range(width - 1):
				collect_cube_vertices(x, y, z, vertices, normals)
	
	# Optimization: Add all vertices at once
	for i in range(vertices.size()):
		surface_tool.set_normal(normals[i])
		surface_tool.add_vertex(vertices[i])
	
	update_mesh()

# Optimization: Collect vertices for batch processing
func collect_cube_vertices(x: int, y: int, z: int, vertices: Array, normals: Array) -> void:
	var cube_index = 0
	
	# Make sure we have all required data for safety
	if x < 0 or y < 0 or z < 0:
		print("Invalid coordinates: ", x, ", ", y, ", ", z)
		return
	if x >= width - 1 or y >= height - 1 or z >= width - 1:
		print("Out of bounds: ", x, ", ", y, ", ", z)
		return
	
	# Clear edge cache for this cube
	edge_vertex_cache.clear()
	
	# Optimization: Use precomputed voxel states
	# Check all 8 corners
	for i in range(8):
		if i >= MarchingTable.Corners.size():
			print("Invalid corner index: ", i)
			continue
		
		var corner = MarchingTable.Corners[i]
		var corner_x = x + corner.x
		var corner_y = y + corner.y
		var corner_z = z + corner.z
		
		# Skip this corner if out of range
		if corner_x < 0 or corner_x >= width or corner_y < 0 or corner_y >= height or corner_z < 0 or corner_z >= width:
			continue
		
		# Add to cube index using precomputed voxel states
		if voxel_states.size() > corner_x and voxel_states[corner_x].size() > corner_y and voxel_states[corner_x][corner_y].size() > corner_z:
			if voxel_states[corner_x][corner_y][corner_z]:
				cube_index |= (1 << i)
		else:
			print("Voxel states out of bounds at: ", corner_x, ", ", corner_y, ", ", corner_z)
	
	# Skip if we don't have a valid cube_index
	if cube_index < 0 or cube_index >= MarchingTable.Triangles.size():
		print("Invalid cube index: ", cube_index, " (Triangles size: ", MarchingTable.Triangles.size(), ")")
		return
	
	# Get triangle data
	var tri_table = MarchingTable.Triangles[cube_index]
	
	# Make sure we have valid data
	if not tri_table is Array:
		print("tri_table is not an array for cube_index: ", cube_index)
		return
	
	# Generate triangles
	var i = 0
	while i < tri_table.size():
		# Break if we reach the end marker
		if tri_table[i] == -1:
			break
		
		# Make sure we have enough data for a triangle
		if i + 2 >= tri_table.size():
			print("Insufficient triangle data at index: ", i)
			break
		
		# Get edge indices
		var edge0_idx = tri_table[i]
		var edge1_idx = tri_table[i + 1]
		var edge2_idx = tri_table[i + 2]
		
		# Verify edge indices
		if edge0_idx < 0 or edge0_idx >= MarchingTable.Edges.size():
			print("Invalid edge0_idx: ", edge0_idx)
			i += 3
			continue
		if edge1_idx < 0 or edge1_idx >= MarchingTable.Edges.size():
			print("Invalid edge1_idx: ", edge1_idx)
			i += 3
			continue
		if edge2_idx < 0 or edge2_idx >= MarchingTable.Edges.size():
			print("Invalid edge2_idx: ", edge2_idx)
			i += 3
			continue
		
		# Get edge data
		var edge0 = MarchingTable.Edges[edge0_idx]
		var edge1 = MarchingTable.Edges[edge1_idx]
		var edge2 = MarchingTable.Edges[edge2_idx]
		
		# Optimization: Use cached vertices
		var v0 = get_cached_vertex(edge0_idx, edge0, x, y, z)
		var v1 = get_cached_vertex(edge1_idx, edge1, x, y, z)
		var v2 = get_cached_vertex(edge2_idx, edge2, x, y, z)
		
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
		
		# Add vertices and normals to batch arrays
		vertices.append(v0)
		vertices.append(v1)
		vertices.append(v2)
		normals.append(normal)
		normals.append(normal)
		normals.append(normal)
		
		i += 3
	

# Optimization: Cache vertices for reuse
func get_cached_vertex(edge_idx: int, edge, x: int, y: int, z: int) -> Vector3:
	if edge_vertex_cache.has(edge_idx):
		return edge_vertex_cache[edge_idx]
	
	var vertex = safe_interpolate_vertices(edge, x, y, z)
	edge_vertex_cache[edge_idx] = vertex
	return vertex

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

# Optimization: Direct mesh creation
func update_mesh() -> void:
	surface_tool.generate_normals()
	self.mesh = surface_tool.commit()
	
	if self.mesh != null and self.mesh.get_surface_count() > 0 and terrain_material != null:
		var mesh_color = StandardMaterial3D.new()
		mesh_color.albedo_color = Color(randf(), randf(), randf())
		mesh_color.next_pass = terrain_material
		
		self.mesh.surface_set_material(0, mesh_color)

# Optimization: Multi-threaded mesh generation
func create_mesh_from_heights_threaded() -> void:
	# Make sure we have heights data
	if heights.size() == 0:
		return
	
	# Precompute voxel states
	precompute_voxel_states()
	
	var thread_count = 4
	var threads = []
	var results = []
	
	# Split the chunk into regions
	var regions = []
	var region_size_x = (width - 1) / 2
	var region_size_y = (height - 1) / 2
	var region_size_z = (width - 1) / 2
	
	for i in range(2):
		for j in range(2):
			for k in range(2):
				regions.append({
					"start_x": i * region_size_x,
					"start_y": j * region_size_y,
					"start_z": k * region_size_z,
					"end_x": min((i + 1) * region_size_x, width - 1),
					"end_y": min((j + 1) * region_size_y, height - 1),
					"end_z": min((k + 1) * region_size_z, width - 1)
				})
	
	# Initialize results array
	for i in range(regions.size()):
		results.append({"vertices": [], "normals": []})
	
	# Process each region in a separate thread
	for i in range(min(thread_count, regions.size())):
		var thread = Thread.new()
		threads.append(thread)
		thread.start(generate_region_mesh.bind(regions[i], i, results))
	
	# Wait for threads and combine results
	var all_vertices = []
	var all_normals = []
	
	for i in range(threads.size()):
		threads[i].wait_to_finish()
		all_vertices.append_array(results[i].vertices)
		all_normals.append_array(results[i].normals)
	
	# Create mesh from combined results
	surface_tool.clear()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(all_vertices.size()):
		surface_tool.set_normal(all_normals[i])
		surface_tool.add_vertex(all_vertices[i])
	
	update_mesh()

# Process a region of the chunk in a separate thread
func generate_region_mesh(region, result_index, results) -> void:
	var vertices = []
	var normals = []
	
	var thread_edge_cache = {}
	
	for x in range(region.start_x, region.end_x):
		for y in range(region.start_y, region.end_y):
			for z in range(region.start_z, region.end_z):
				# Clear edge cache for this cube
				thread_edge_cache.clear()
				
				# Similar to collect_cube_vertices but with thread-local cache
				var cube_index = 0
				
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
					
					# Add to cube index
					if voxel_states[corner_x][corner_y][corner_z]:
						cube_index |= (1 << i)
				
				# Skip if we don't have a valid cube_index
				if cube_index < 0 or cube_index >= MarchingTable.Triangles.size():
					continue
				
				# Get triangle data
				var tri_table = MarchingTable.Triangles[cube_index]
				
				# Make sure we have valid data
				if not tri_table is Array:
					continue
				
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
					
					# Use cached vertices for this thread
					var v0 = thread_get_cached_vertex(thread_edge_cache, edge0_idx, edge0, x, y, z)
					var v1 = thread_get_cached_vertex(thread_edge_cache, edge1_idx, edge1, x, y, z)
					var v2 = thread_get_cached_vertex(thread_edge_cache, edge2_idx, edge2, x, y, z)
					
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
					
					# Add vertices and normals to batch arrays
					vertices.append(v0)
					vertices.append(v1)
					vertices.append(v2)
					normals.append(normal)
					normals.append(normal)
					normals.append(normal)
					
					i += 3
	
	# Store results
	results[result_index].vertices = vertices
	results[result_index].normals = normals

# Thread-safe vertex caching
func thread_get_cached_vertex(cache: Dictionary, edge_idx: int, edge, x: int, y: int, z: int) -> Vector3:
	if cache.has(edge_idx):
		return cache[edge_idx]
	
	var vertex = safe_interpolate_vertices(edge, x, y, z)
	cache[edge_idx] = vertex
	return vertex

# Optimization: Use greedy meshing for large flat areas
func create_optimized_mesh() -> void:
	# Make sure we have heights data
	if heights.size() == 0:
		return
	
	# Precompute voxel states if not already done
	if voxel_states.size() == 0:
		precompute_voxel_states()
	
	surface_tool.clear()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Process each axis direction
	for axis in range(3):  # 0=X, 1=Y, 2=Z
		greedy_mesh_axis(axis)
	
	update_mesh()

# Greedy meshing for a specific axis
func greedy_mesh_axis(axis: int) -> void:
	# Determine axis order
	var u = (axis + 1) % 3
	var v = (axis + 2) % 3
	
	# Determine dimensions
	var dim_x = width if axis == 0 else (height if axis == 1 else width)
	var dim_y = width if u == 0 else (height if u == 1 else width)
	var dim_z = width if v == 0 else (height if v == 1 else width)
	
	# Mask for marking processed voxels
	var mask = []
	for i in range(dim_y):
		var row = []
		for j in range(dim_z):
			row.append(false)
		mask.append(row)
	
	# Process each slice
	for x in range(dim_x):
		# Reset mask for this slice
		for i in range(dim_y):
			for j in range(dim_z):
				mask[i][j] = false
		
		# Process each cell in the slice
		for y in range(dim_y):
			for z in range(dim_z):
				if mask[y][z]:
					continue
				
				# Get voxel state
				var voxel_state = get_voxel_state(x, y, z, axis)
				
				# Skip empty voxels
				if not voxel_state:
					continue
				
				# Find width and height of rectangle
				var width_run = 1
				while y + width_run < dim_y and \
					  not mask[y + width_run][z] and \
					  get_voxel_state(x, y + width_run, z, axis) == voxel_state:
					width_run += 1
				
				var height_run = 1
				var done = false
				while z + height_run < dim_z and not done:
					for i in range(width_run):
						if mask[y + i][z + height_run] or \
						   get_voxel_state(x, y + i, z + height_run, axis) != voxel_state:
							done = true
							break
					if not done:
						height_run += 1
				
				# Mark cells as processed
				for i in range(width_run):
					for j in range(height_run):
						mask[y + i][z + j] = true
				
				# Create quad
				create_quad(x, y, z, width_run, height_run, axis, voxel_state)

# Get voxel state with axis transformation
func get_voxel_state(x: int, y: int, z: int, axis: int) -> bool:
	var coords = [x, y, z]
	var actual_x = coords[axis % 3]
	var actual_y = coords[(axis + 1) % 3]
	var actual_z = coords[(axis + 2) % 3]
	
	# Check bounds
	if actual_x < 0 or actual_x >= width:
		return false
	if actual_y < 0 or actual_y >= height:
		return false
	if actual_z < 0 or actual_z >= width:
		return false
	
	return voxel_states[actual_x][actual_y][actual_z]

# Create a quad face
func create_quad(x: int, y: int, z: int, width_run: int, height_run: int, axis: int, is_front: bool) -> void:
	# Determine face direction
	var face_dir = Vector3.ZERO
	if axis == 0:
		face_dir = Vector3(1, 0, 0) if is_front else Vector3(-1, 0, 0)
	elif axis == 1:
		face_dir = Vector3(0, 1, 0) if is_front else Vector3(0, -1, 0)
	else:
		face_dir = Vector3(0, 0, 1) if is_front else Vector3(0, 0, -1)
	
	# Determine quad corners
	var corners = []
	if axis == 0:  # X-axis
		corners.append(Vector3(x, y, z))
		corners.append(Vector3(x, y + width_run, z))
		corners.append(Vector3(x, y + width_run, z + height_run))
		corners.append(Vector3(x, y, z + height_run))
	elif axis == 1:  # Y-axis
		corners.append(Vector3(y, x, z))
		corners.append(Vector3(y + width_run, x, z))
		corners.append(Vector3(y + width_run, x, z + height_run))
		corners.append(Vector3(y, x, z + height_run))
	else:  # Z-axis
		corners.append(Vector3(y, z, x))
		corners.append(Vector3(y + width_run, z, x))
		corners.append(Vector3(y + width_run, z + height_run, x))
		corners.append(Vector3(y, z + height_run, x))
	
	# Create triangles
	surface_tool.set_normal(face_dir)
	
	if is_front:
		surface_tool.add_vertex(corners[0])
		surface_tool.add_vertex(corners[1])
		surface_tool.add_vertex(corners[2])
		
		surface_tool.add_vertex(corners[0])
		surface_tool.add_vertex(corners[2])
		surface_tool.add_vertex(corners[3])
	else:
		surface_tool.add_vertex(corners[0])
		surface_tool.add_vertex(corners[2])
		surface_tool.add_vertex(corners[1])
		
		surface_tool.add_vertex(corners[0])
		surface_tool.add_vertex(corners[3])
		surface_tool.add_vertex(corners[2])
