@tool
extends Node

const GRID_SIZE = 10
const ISO_LEVEL = 0.5
const edgeTable = [
	[], # 0
	[[0, 1], [1, 2], [2, 3], [3, 0]], # 1
	[[1, 2], [2, 3], [0, 1], [0, 3]], # 2
	[[0, 1], [1, 2], [2, 3], [0, 3]], # 3
	[[4, 5], [5, 6], [6, 7], [7, 4]], # 4
	[[0, 1], [1, 5], [5, 4], [4, 0], [2, 3], [3, 7], [7, 6], [6, 2]], # 5
	[[1, 2], [2, 6], [6, 5], [5, 1], [3, 0], [0, 4], [4, 7], [7, 3]], # 6
	[[0, 3], [3, 7], [7, 6], [6, 2]], # 7
	[[0, 4], [4, 5], [5, 1], [1, 0]], # 8
	[[1, 5], [5, 6], [6, 2], [2, 1]], # 9
	[[3, 0], [0, 4], [4, 7], [7, 3]], # 10
	[[4, 5], [5, 6], [6, 7], [7, 4]] # 11
]

var amplitude = 5.0

func _ready():
	# Generate mesh
	var mesh = ArrayMesh.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = generate_mesh()
	add_child(mesh_instance)

func interpolate(p1, p2, valp1, valp2):
	if abs(ISO_LEVEL - valp1) < 0.00001:
		return p1
	if abs(ISO_LEVEL - valp2) < 0.00001:
		return p2
	if abs(valp1 - valp2) < 0.00001:
		return p1
	
	var mu = (ISO_LEVEL - valp1) / (valp2 - valp1)
	
	return Vector3(p1.x + mu * (p2.x - p1.x), p1.y + mu * (p2.y - p1.y), p1.z + mu * (p2.z - p1.z))

func polygonize(vertices, values):
	# Calculate the index for each cube
	var cubeindex = 0
	
	for i in range(8):
		if values[i] < ISO_LEVEL:
			cubeindex |= (1 << i)
	
	if cubeindex == 0 or cubeindex == 255:
		return []
	
	var vertlist = []
	
	for edge in edgeTable[cubeindex]:
		vertlist.append(interpolate(vertices[edge[0]], vertices[edge[1]], values[edge[0]], values[edge[1]]))
	
	return vertlist

func generate_mesh():
	var mesh = SurfaceTool.new()
	
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			for z in range(GRID_SIZE):
				# Define the vertices of the current cube
				var vertices = [
					Vector3(x, y, z),
					Vector3(x + 1, y, z),
					Vector3(x + 1, y + 1, z),
					Vector3(x, y + 1, z),
					Vector3(x, y, z + 1),
					Vector3(x + 1, y, z + 1),
					Vector3(x + 1, y + 1, z + 1),
					Vector3(x, y + 1, z + 1)
				]
				
				# Evaluate the function at each vertex
				var values = [
					get_noise_value(vertices[0]),
					get_noise_value(vertices[1]),
					get_noise_value(vertices[2]),
					get_noise_value(vertices[3]),
					get_noise_value(vertices[4]),
					get_noise_value(vertices[5]),
					get_noise_value(vertices[6]),
					get_noise_value(vertices[7])
				]
				
				# Polygonize the cube
				var verts = polygonize(vertices, values)
				print(verts)
				if len(verts) > 0:
					for i in range(0, len(verts), 3):
						mesh.add_triangle_fan(verts[i], verts[i + 1], verts[i + 2])
	
	return mesh.commit()

func get_noise_value(position : Vector3):
	var noise = FastNoiseLite.new()
	
	return noise.get_noise_2d(position.x, position.y)
