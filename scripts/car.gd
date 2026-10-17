class_name DriftCar
extends Node3D

const MAX_SPEED := 64.0
const STEER_LIMIT := PI / 2.0
var velocity := Vector3.ZERO
var heading := 0.0
var steer := 0.0
var throttle := 0.0
var steering_input := 0.0
var braking := false
var handbrake := false
var speed_kmh := 0.0
var slip_angle := 0.0
var drift_active := false
var enabled := false
var front_wheels: Array[Node3D] = []
var shell: Node3D
var wheel_spin := 0.0
var obstacles: Array[Rect2] = []
var collision_count := 0

func _ready() -> void:
	build_car()

func material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.32 if metallic > 0.0 else 0.8
	return m

func box(parent: Node3D, size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mat
	n.position = at
	parent.add_child(n)
	return n

func build_car() -> void:
	shell = Node3D.new()
	add_child(shell)
	var black := material(Color("182027"), 0.72)
	var edge := material(Color("303d48"), 0.6)
	var glass := material(Color("6597a9"), 0.1)
	var tire := material(Color("171c24"))
	var alloy := material(Color("bbc9d3"), 0.8)
	var lamp := material(Color("fff2c1"))
	lamp.emission_enabled = true
	lamp.emission = Color("fff0b9")
	var red := material(Color("f46567"))
	red.emission_enabled = true
	red.emission = Color("df374b")
	# Squashed, wide proportions: a tiny Scandinavian sports sedan.
	box(shell, Vector3(2.18, 0.65, 4.0), Vector3(0, 0.77, 0), black)
	box(shell, Vector3(2.10, 0.32, 3.65), Vector3(0, 1.12, 0), black)
	build_cabin(glass)
	box(shell, Vector3(1.65, 0.12, 1.45), Vector3(0, 1.83, 0.2), black)
	for x in [-0.87, 0.87]:
		box(shell, Vector3(0.10, 0.61, 0.12), Vector3(x * 0.96, 1.5, 0.28), black)
		var front_pillar := box(shell, Vector3(0.10, 0.74, 0.10), Vector3(x * 0.96, 1.5, -0.73), black)
		front_pillar.rotation.x = 0.55
		var rear_pillar := box(shell, Vector3(0.10, 0.74, 0.10), Vector3(x * 0.96, 1.5, 1.12), black)
		rear_pillar.rotation.x = -0.55
		box(shell, Vector3(0.30, 0.19, 0.3), Vector3(x * 1.38, 1.36, -0.55), black)
	box(shell, Vector3(0.82, 0.29, 0.06), Vector3(0, 0.96, -2.025), tire)
	var slash := box(shell, Vector3(0.72, 0.035, 0.035), Vector3(0, 0.96, -2.065), alloy)
	slash.rotation.z = -0.31
	for x in [-0.76, 0.76]:
		box(shell, Vector3(0.48, 0.08, 0.06), Vector3(x, 1.09, -2.035), lamp)
		box(shell, Vector3(0.07, 0.19, 0.06), Vector3(x, 1.04, -2.04), lamp)
		box(shell, Vector3(0.42, 0.11, 0.06), Vector3(x, 1.09, 2.025), red)
		box(shell, Vector3(0.08, 0.38, 0.06), Vector3(x * 1.19, 1.2, 2.025), red)
	box(shell, Vector3(0.56, 0.16, 0.06), Vector3(0, 0.67, 2.035), alloy)
	box(shell, Vector3(2.0, 0.09, 0.25), Vector3(0, 1.32, 1.79), edge)
	for x in [-1.12, 1.12]:
		for z in [-1.25, 1.26]:
			var pivot := Node3D.new()
			pivot.position = Vector3(x, 0.48, z)
			add_child(pivot)
			if z < 0:
				front_wheels.append(pivot)
			var wheel := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.48
			cyl.bottom_radius = 0.48
			cyl.height = 0.29
			cyl.radial_segments = 16
			wheel.mesh = cyl
			wheel.rotation.z = PI / 2.0
			wheel.material_override = tire
			pivot.add_child(wheel)
			var hub := MeshInstance3D.new()
			var h := CylinderMesh.new()
			h.top_radius = 0.28
			h.bottom_radius = 0.28
			h.height = 0.305
			h.radial_segments = 12
			hub.mesh = h
			hub.rotation.z = PI / 2.0
			hub.material_override = alloy
			pivot.add_child(hub)

func build_cabin(mat: Material) -> void:
	var points := [Vector3(-0.90, 1.2, -0.93), Vector3(0.90, 1.2, -0.93), Vector3(0.90, 1.2, 1.32), Vector3(-0.90, 1.2, 1.32), Vector3(-0.80, 1.80, -0.53), Vector3(0.80, 1.80, -0.53), Vector3(0.80, 1.80, 0.92), Vector3(-0.80, 1.80, 0.92)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [[0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7], [4, 5, 6, 7]]:
		for index in [0, 1, 2, 0, 2, 3]:
			surface.add_vertex(points[face[index]])
	surface.generate_normals()
	var cabin := MeshInstance3D.new()
	cabin.mesh = surface.commit()
	cabin.material_override = mat
	shell.add_child(cabin)

func reset_car(at: Vector3 = Vector3(0, 0, 258), direction: float = PI / 2.0) -> void:
	position = at
	heading = direction
	rotation.y = heading
	velocity = Vector3.ZERO
	steer = 0.0
	speed_kmh = 0.0
	slip_angle = 0.0
	drift_active = false

func simulate(delta: float) -> void:
	if not enabled:
		return
	steer = move_toward(steer, steering_input * STEER_LIMIT, delta * 3.4)
	var forward := Vector3(-sin(heading), 0, -cos(heading))
	var right := Vector3(cos(heading), 0, -sin(heading))
	var speed := velocity.length()
	var longitudinal := velocity.dot(forward)
	# Yaw control stays effective at full lock; momentum barely follows the body.
	var travel_sign := -1.0 if longitudinal < -2.0 and throttle <= 0.0 else 1.0
	heading -= (steer / STEER_LIMIT) * minf(speed / 9.0, 1.0) * 1.6 * travel_sign * delta
	rotation.y = heading
	forward = Vector3(-sin(heading), 0, -cos(heading))
	right = Vector3(cos(heading), 0, -sin(heading))
	velocity += forward * throttle * 19.0 * delta
	# Very low lateral grip. Space releases the last bit of traction.
	velocity -= right * velocity.dot(right) * (0.015 if handbrake else 0.16) * delta
	velocity *= exp(-0.10 * delta)
	if braking:
		velocity = velocity.move_toward(Vector3.ZERO, 22.0 * delta)
	velocity = velocity.limit_length(MAX_SPEED)
	var before := position
	position += velocity * delta
	position.y = 0.0
	for rect in obstacles:
		if rect.grow(1.6).has_point(Vector2(position.x, position.z)):
			position = before
			velocity *= -0.42
			collision_count += 1
			break
	if Vector2(position.x, position.z).length() > 1080:
		position = before
		velocity *= -0.5
		collision_count += 1
	speed_kmh = velocity.length() * 3.6
	slip_angle = rad_to_deg(acos(clampf(absf(velocity.normalized().dot(forward)), 0, 1))) if speed_kmh > 1 else 0.0
	drift_active = speed_kmh > 22.0 and slip_angle > 14.0
	for wheel in front_wheels:
		wheel.rotation.y = -steer
	shell.rotation.z = lerpf(shell.rotation.z, -steering_input * minf(speed / 40.0, 1.0) * 0.055, delta * 5)
