class_name ChodovMap
extends Node3D

const RING_RADIUS := 5000.0 / TAU
var obstacles: Array[Rect2] = []
var mats: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 420148
	for pair in [["grass", "a2b9a0"], ["road", "424b5c"], ["line", "e3e2ca"], ["concrete", "c6c9ba"], ["cream", "e7deca"], ["pink", "c99c9b"], ["dark", "344658"], ["glass", "719ba2"], ["orange", "f49d65"], ["tree", "658a70"], ["trunk", "8a8275"], ["roof", "adbbbb"]]:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(pair[1])
		mat.roughness = 0.92
		mats[pair[0]] = mat
	box(Vector3(2300, 2, 2300), Vector3(0, -1.13, 0), "grass")
	box(Vector3(610, 0.10, 530), Vector3(0, -0.05, 0), "concrete")
	# Exactly 5 km around the outer road centreline. Inner boulevard and spurs are additional.
	ring(RING_RADIUS, 30, 0.01, "road")
	ring(315, 28, 0.025, "road")
	for a in range(4):
		var angle := float(a) * PI / 2
		var road := box(Vector3(26, 0.08, RING_RADIUS - 305), Vector3(sin(angle), 0, cos(angle)) * ((RING_RADIUS + 305) / 2), "road")
		road.rotation.y = angle
		for t in range(348, 775, 20):
			var dash := box(Vector3(0.38, 0.02, 6), Vector3(sin(angle) * t, 0.08, cos(angle) * t), "line")
			dash.rotation.y = angle
	for radius in [RING_RADIUS, 315.0]:
		for i in range(int(TAU * radius / 20)):
			var angle: float = i * 20.0 / radius
			var dash := box(Vector3(0.45, 0.035, 7), Vector3(cos(angle) * radius, 0.08, sin(angle) * radius), "line")
			dash.rotation.y = -angle
		for offset in [-13.0, 13.0]:
			ring(radius + offset, 0.35, 0.08, "line")
	# Simplified Chodov: low shopping blocks, glass entrance, rooftop parking.
	building(Vector3(250, 22, 160), Vector3(0, 11, -18), "cream")
	building(Vector3(105, 18, 92), Vector3(-140, 9, 10), "pink")
	building(Vector3(94, 26, 110), Vector3(135, 13, -40), "cream")
	box(Vector3(180, 16, 2), Vector3(0, 11, 63), "glass")
	for x in range(-88, 89, 11):
		box(Vector3(0.8, 16.3, 2.4), Vector3(x, 11, 64), "cream")
	box(Vector3(205, 1.2, 22), Vector3(0, 19, 73), "orange")
	box(Vector3(248, 0.5, 158), Vector3(0, 22.4, -18), "roof")
	for x in range(-100, 101, 14):
		box(Vector3(0.35, 0.05, 20), Vector3(x, 22.7, -28), "line")
	label("WESTFIELD", Vector3(0, 29, 65), 3.0, Color("344658"))
	label("C H O D O V", Vector3(0, 23.5, 86), 2.6, Color("344658"))
	label("PRAHA 11  /  LITTLE DRIFT CLUB", Vector3(0, 4.8, 87), 0.65, Color("344658"))
	# Open plaza and parking bays; no parked cars to obstruct long slides.
	box(Vector3(420, 0.05, 140), Vector3(0, 0.015, 209), "road")
	for x in range(-195, 196, 13):
		for z in [155, 181]:
			box(Vector3(0.25, 0.03, 10), Vector3(x, 0.06, z), "line")
	for x in [-220, 220]:
		building(Vector3(5, 10, 5), Vector3(x, 5, 118), "orange")
		label("P", Vector3(x, 13, 121), 2, Color("344658"))
	# Decorative apartment clusters evoke the south Prague skyline.
	for i in range(64):
		var angle := rng.randf_range(0, TAU)
		var radius := rng.randf_range(890, 1020)
		var at := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var height := rng.randf_range(18, 62)
		building(Vector3(rng.randf_range(24, 45), height, rng.randf_range(22, 40)), at + Vector3(0, height / 2, 0), "cream" if i % 3 else "pink")
		for y in range(6, int(height), 7):
			box(Vector3(18, 2.2, 0.3), at + Vector3(0, y, 21), "glass")
	# Shared geometry instancing keeps the park inexpensive to render.
	var crowns := MultiMesh.new()
	crowns.transform_format = MultiMesh.TRANSFORM_3D
	var crown := SphereMesh.new()
	crown.radius = 5.5
	crown.height = 12
	crown.radial_segments = 8
	crown.rings = 4
	crowns.mesh = crown
	crowns.instance_count = 220
	var trunks := MultiMesh.new()
	trunks.transform_format = MultiMesh.TRANSFORM_3D
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.55
	trunk.bottom_radius = 0.8
	trunk.height = 7
	trunk.radial_segments = 6
	trunks.mesh = trunk
	trunks.instance_count = 220
	for i in range(220):
		var angle := rng.randf_range(0, TAU)
		var radius := rng.randf_range(365, 740)
		var at := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		if absf(at.x) < 28 or absf(at.z) < 28:
			at.x += 55
			at.z += 55
		crowns.set_instance_transform(i, Transform3D(Basis.IDENTITY, at + Vector3(0, 10, 0)))
		trunks.set_instance_transform(i, Transform3D(Basis.IDENTITY, at + Vector3(0, 3.5, 0)))
	for pair in [[crowns, "tree"], [trunks, "trunk"]]:
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = pair[0]
		instance.material_override = mats[pair[1]]
		add_child(instance)
	batch_boxes()

func batch_boxes() -> void:
	# Hundreds of road markings and buildings become a handful of draw calls.
	var groups: Dictionary = {}
	for node in get_children():
		if node is MeshInstance3D and node.mesh is BoxMesh:
			var key: Material = node.material_override
			if not groups.has(key):
				groups[key] = []
			groups[key].append(Transform3D(node.basis * Basis.from_scale(node.mesh.size), node.position))
			node.queue_free()
	for mat in groups:
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE
		batch.mesh = cube
		batch.instance_count = groups[mat].size()
		for i in range(batch.instance_count):
			batch.set_instance_transform(i, groups[mat][i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = batch
		instance.material_override = mat
		add_child(instance)

func box(size: Vector3, at: Vector3, mat: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.material_override = mats[mat]
	add_child(node)
	return node

func building(size: Vector3, at: Vector3, mat: String) -> void:
	box(size, at, mat)
	obstacles.append(Rect2(Vector2(at.x - size.x / 2, at.z - size.z / 2), Vector2(size.x, size.z)))

func label(words: String, at: Vector3, scale_factor: float, color: Color) -> void:
	var node := Label3D.new()
	node.text = words
	node.font_size = 64
	node.pixel_size = 0.025 * scale_factor
	node.position = at
	node.modulate = color
	node.outline_size = 0
	add_child(node)

func ring(radius: float, width: float, y: float, mat: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(256):
		var a := TAU * i / 256.0
		var b := TAU * (i + 1) / 256.0
		var points := [Vector3(cos(a) * (radius - width / 2), y, sin(a) * (radius - width / 2)), Vector3(cos(a) * (radius + width / 2), y, sin(a) * (radius + width / 2)), Vector3(cos(b) * (radius - width / 2), y, sin(b) * (radius - width / 2)), Vector3(cos(b) * (radius + width / 2), y, sin(b) * (radius + width / 2))]
		for index in [0, 1, 2, 1, 3, 2]:
			surface.set_normal(Vector3.UP)
			surface.add_vertex(points[index])
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	instance.material_override = mats[mat]
	add_child(instance)
