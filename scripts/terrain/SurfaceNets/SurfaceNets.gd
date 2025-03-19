extends MeshInstance3D

# Configuration
@export var grid_size: Vector3i = Vector3i(32, 32, 32)  # Increased grid size for better results
@export var isolevel: float = 4.0
@export var initial_amplitude = 10.0
@export var initial_frequency = 0.8

var noise = FastNoiseLite.new()

const LOW_POLY_TERRAIN = preload("res://scripts/shaders/low_poly_terrain.tres")

func _ready():
	noise.noise_type = FastNoiseLite.TYPE_PERLIN  # Or try TYPE_SIMPLEX
	noise.seed = randi()
	noise.frequency = 0.5  # Adjust for detail
	generate_mesh()

func get_density(x: float, y: float, z: float) -> float:
	# Normalize coordinates to control noise scale
	var nx = x * 0.05
	var ny = y * 0.05
	var nz = z * 0.05
	
	var terrain_height = 0.0
	var amplitude = initial_amplitude
	var frequency = initial_frequency
	
	for i in range(4):
		terrain_height += noise.get_noise_3d(nx * frequency, ny * frequency, nz * frequency) * amplitude
		amplitude *= 0.5
		frequency *= 2.0
	
	terrain_height = terrain_height * 10.0 + grid_size.y * 0.3  # Shift terrain up slightly
	
	# Density calculation for terrain
	var density = terrain_height - y
	
	# Add a flat base at the bottom (optional)
	if y < grid_size.y * 0.1:
		density = 10.0
	
	# Add caves (optional)
	if y > grid_size.y * 0.2 and y < grid_size.y * 0.6:
		var cave_noise = noise.get_noise_3d(x * 0.1, y * 0.1, z * 0.1)
		if cave_noise > 0.3:
			density -= 10.0
	
	return density

func generate_mesh():
	# Step 1: Sample the density field
	var density = []
	for x in range(grid_size.x + 1):
		density.append([])
		for y in range(grid_size.y + 1):
			density[x].append([])
			for z in range(grid_size.z + 1):
				density[x][y].append(get_density(x, y, z))
	
	# Create a data structure to hold our mesh data
	var vertices = []
	var normals = []
	var vertex_grid = {}  # Maps cell positions to vertex indices
	
	# Step 2: For each cell, find where the isosurface intersects and place a vertex
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				# Get the density values at the corners of this cell
				var cell_corners = [
					density[x][y][z],
					density[x+1][y][z],
					density[x+1][y][z+1],
					density[x][y][z+1],
					density[x][y+1][z],
					density[x+1][y+1][z],
					density[x+1][y+1][z+1],
					density[x][y+1][z+1]
				]
				
				# Check if this cell intersects the isosurface
				var has_positive = false
				var has_negative = false
				
				for val in cell_corners:
					if val > isolevel:
						has_positive = true
					if val < isolevel:
						has_negative = true
					
					if has_positive and has_negative:
						break
				
				# Skip cells that don't intersect the isosurface
				if not (has_positive and has_negative):
					continue
				
				# Calculate the vertex position as the average of edge intersection points
				var vertex_pos = Vector3.ZERO
				var intersect_count = 0
				
				# For each edge of the cube
				var cube_index = 0
				for i in range(8):
					if cell_corners[i] < isolevel:
						cube_index |= (1 << i)
				
				var edge_bits = SFLookupTable.EDGE_TABLE[cube_index]
				
				for i in range(12):
					if edge_bits & (1 << i):
						# Get corners of this edge
						var c0 = SFLookupTable.EDGE_CORNERS[i][0]
						var c1 = SFLookupTable.EDGE_CORNERS[i][1]
						
						var p0 = SFLookupTable.CORNER_OFFSETS[c0]
						var p1 = SFLookupTable.CORNER_OFFSETS[c1]
						
						var d0 = cell_corners[c0]
						var d1 = cell_corners[c1]
						
						# Prevent division by zero
						if abs(d0 - d1) < 0.0001:
							continue
						
						# Interpolate along the edge to find where it crosses the isosurface
						var t = (isolevel - d0) / (d1 - d0)
						if t < 0 or t > 1:
							continue
							
						var intersection = Vector3(
							x + p0.x + (p1.x - p0.x) * t,
							y + p0.y + (p1.y - p0.y) * t,
							z + p0.z + (p1.z - p0.z) * t
						)
						
						vertex_pos += intersection
						intersect_count += 1
				
				# If we found intersection points, add a vertex
				if intersect_count > 0:
					vertex_pos /= intersect_count
					
					# Add the vertex and store its index
					var vertex_index = vertices.size()
					vertices.append(vertex_pos)
					
					# Add a placeholder normal (will calculate properly later)
					normals.append(Vector3.ZERO)
					
					# Store the vertex index in our grid
					vertex_grid[Vector3i(x, y, z)] = vertex_index
	
	# Step 3: Create triangles by connecting vertices
	var indices = []
	
	# For each cell in the grid
	for x in range(grid_size.x - 1):
		for y in range(grid_size.y - 1):
			for z in range(grid_size.z - 1):
				var base_pos = Vector3i(x, y, z)
				
				# Check each face
				for face_idx in range(SFLookupTable.QUAD_FACES.size()):
					var face = SFLookupTable.QUAD_FACES[face_idx]
					var quad_vertices = []
					
					# Get the four corners of this face
					for corner in face:
						var pos = base_pos + corner
						if vertex_grid.has(pos):
							quad_vertices.append(vertex_grid[pos])
						else:
							# If any corner is missing, skip this face
							quad_vertices = []
							break
					
					# If we have all four corners, create two triangles
					if quad_vertices.size() == 4:
						# Triangle 1 (counter-clockwise to face outward)
						indices.append(quad_vertices[0])
						indices.append(quad_vertices[1])
						indices.append(quad_vertices[2])
						
						# Triangle 2 (counter-clockwise to face outward)
						indices.append(quad_vertices[0])
						indices.append(quad_vertices[2])
						indices.append(quad_vertices[3])
						
						# Add contribution to vertex normals
						var normal = SFLookupTable.DIRECTIONS[face_idx]
						normals[quad_vertices[0]] += normal
						normals[quad_vertices[1]] += normal
						normals[quad_vertices[2]] += normal
						normals[quad_vertices[3]] += normal
	
	# Normalize all normals
	for i in range(normals.size()):
		if normals[i].length_squared() > 0.0001:
			normals[i] = normals[i].normalized()
		else:
			# Fallback normal if we couldn't calculate one
			normals[i] = Vector3(0, 1, 0)
	
	# Create the mesh
	if vertices.size() > 0 and indices.size() > 0:
		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		# Add all vertices with their normals
		for i in range(vertices.size()):
			surface_tool.set_normal(normals[i])
			surface_tool.add_vertex(vertices[i])
		
		# Add all indices
		for i in range(0, indices.size(), 3):
			surface_tool.add_index(indices[i])
			surface_tool.add_index(indices[i+1])
			surface_tool.add_index(indices[i+2])
		
		# Generate proper normals and tangents
		surface_tool.generate_normals()
		
		# Create the mesh
		var new_mesh = surface_tool.commit()
		self.mesh = new_mesh
		
		# Apply material if provided
		self.set_surface_override_material(0, LOW_POLY_TERRAIN)
		
		print("Mesh created with ", vertices.size(), " vertices and ", indices.size() / 3, " triangles")
	else:
		print("No vertices or triangles generated!")
