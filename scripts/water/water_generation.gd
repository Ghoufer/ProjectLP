@tool
extends MeshInstance3D

@export var update = false
@export var xSize = 150
@export var zSize = 150

func _ready():
	generate_water_mesh()

func _process(delta):
	if update:
		generate_water_mesh()
		update = false

func generate_water_mesh():
	var array_mesh : ArrayMesh
	var surface_tool = SurfaceTool.new()

	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(zSize + 1):
		for x in range(xSize + 1):
			var uv = Vector2()
			
			uv.x = inverse_lerp(0, xSize, x)
			uv.y = inverse_lerp(0, zSize, z)
			
			surface_tool.set_uv(uv)
			surface_tool.add_vertex(Vector3(x, 0, z))
	
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
