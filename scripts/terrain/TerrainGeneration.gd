@tool
extends MeshInstance3D

@export var update = false
@export var xSize = 20
@export var zSize = 20
@export var noise_amplitude = 4.5
@export var terrain_frequency = 0.2

var min_height = 0
var max_height = 1
var terrain_noise = FastNoiseLite.new()

func _ready():
	generate_terrain()

func _process(delta):
	if update:
		generate_terrain()
		update_shader()
		update = false

func generate_terrain():
	var array_mesh : ArrayMesh
	var surface_tool = SurfaceTool.new()
	var rng = RandomNumberGenerator.new()
	
	terrain_noise.seed = rng.randi()
	terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	terrain_noise.frequency = terrain_frequency

	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
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
			
			surface_tool.set_uv(uv)
			surface_tool.add_vertex(Vector3(x, y, z))
	
	var vert = 0
	for z in zSize:
		for x in xSize:
			surface_tool.add_index(vert + 0)
			surface_tool.add_index(vert + 1)
			surface_tool.add_index(vert + xSize + 1)
			
			surface_tool.add_index(vert + xSize + 1)
			surface_tool.add_index(vert + 1)
			surface_tool.add_index(vert + xSize + 2)
			
			vert += 1
		vert += 1
	
	surface_tool.generate_normals()
	array_mesh = surface_tool.commit()
	
	self.mesh = array_mesh
	
	for child in self.get_children():
		child.queue_free()
	
	self.create_trimesh_collision()

func update_shader():
	var material : ShaderMaterial = self.get_active_material(0)
	material.set_shader_parameter('min_height', min_height)
	material.set_shader_parameter('max_height', max_height)
