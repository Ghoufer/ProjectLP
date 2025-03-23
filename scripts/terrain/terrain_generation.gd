@tool
extends MeshInstance3D

@export var update = false
@export var xSize = 20
@export var zSize = 20
@export var noise_amplitude = 4.5
@export var terrain_frequency = 0.2
@export var water_level = 0.0  # Height at which water is placed
@export var terrain_noise : FastNoiseLite
@export var water_material: Material  # Optional: Assign a water material

var min_height = 0
var max_height = 1

func _ready():
	generate_terrain()

func _process(delta):
	if update:
		generate_terrain()
		update_shader()
		update = false

func generate_terrain():
	var terrain_array_mesh : ArrayMesh
	var terrain_surface_tool = SurfaceTool.new()
	var rng = RandomNumberGenerator.new()
	
	terrain_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	terrain_noise.seed = rng.randi()
	
	for z in range(zSize + 1):
		for x in range(xSize + 1):
			var uv = Vector2()
			var y = terrain_noise.get_noise_2d(x, z) * noise_amplitude
			
			if (y < min_height) and y != null:
				min_height = y
			if (y > max_height) and y != null:
				max_height = y
			
			uv.x = inverse_lerp(0, xSize, x)
			uv.y = inverse_lerp(0, zSize, z)
			
			terrain_surface_tool.set_uv(uv)
			terrain_surface_tool.add_vertex(Vector3(x, y, z))
	
	var vert = 0
	for z in zSize:
		for x in xSize:
			terrain_surface_tool.add_index(vert + 0)
			terrain_surface_tool.add_index(vert + 1)
			terrain_surface_tool.add_index(vert + xSize + 1)
			
			terrain_surface_tool.add_index(vert + xSize + 1)
			terrain_surface_tool.add_index(vert + 1)
			terrain_surface_tool.add_index(vert + xSize + 2)
			
			vert += 1
		vert += 1
	
	terrain_surface_tool.generate_normals()
	terrain_array_mesh = terrain_surface_tool.commit()
	
	for child in self.get_children():
		child.queue_free()
	
	self.mesh = terrain_array_mesh
	self.create_trimesh_collision()

	# Generate water mesh
	generate_water()

func generate_water():
	var water_surface_tool = SurfaceTool.new()
	water_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertex_count = 0  # Manually track the vertex count
	
	for z in range(zSize):
		for x in range(xSize):
			# Get terrain height at the four corners of the quad
			var y1 = terrain_noise.get_noise_2d(x, z) * noise_amplitude - 2.0
			var y2 = terrain_noise.get_noise_2d(x + 1, z) * noise_amplitude - 2.0
			var y3 = terrain_noise.get_noise_2d(x, z + 1) * noise_amplitude - 2.0
			var y4 = terrain_noise.get_noise_2d(x + 1, z + 1) * noise_amplitude - 2.0
			
			# Check if any corner is below the water level
			if y1 <= water_level or y2 <= water_level or y3 <= water_level or y4 <= water_level:
				# Add vertices for the water surface
				water_surface_tool.add_vertex(Vector3(x, water_level, z))
				water_surface_tool.add_vertex(Vector3(x + 1, water_level, z))
				water_surface_tool.add_vertex(Vector3(x, water_level, z + 1))
				water_surface_tool.add_vertex(Vector3(x + 1, water_level, z + 1))
				
				# Add indices for the quad
				water_surface_tool.add_index(vertex_count + 0)
				water_surface_tool.add_index(vertex_count + 1)
				water_surface_tool.add_index(vertex_count + 2)
				water_surface_tool.add_index(vertex_count + 1)
				water_surface_tool.add_index(vertex_count + 3)
				water_surface_tool.add_index(vertex_count + 2)
				
				vertex_count += 4  # Increment vertex count by 4 for the quad
	
	water_surface_tool.generate_normals()
	var water_mesh = water_surface_tool.commit()
	
	var water_instance = MeshInstance3D.new()
	water_instance.mesh = water_mesh
	
	# Apply water material if provided
	if water_material:
		water_instance.material_override = water_material
	
	add_child(water_instance)

func update_shader():
	var material : ShaderMaterial = self.get_active_material(0)
	material.set_shader_parameter('min_height', min_height)
	material.set_shader_parameter('max_height', max_height)
