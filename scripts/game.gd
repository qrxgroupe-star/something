extends Node3D

var car: DriftCar
var world: ChodovMap
var camera: Camera3D
var hud: Control
var playing := false
var has_started := false
var total_score := 0.0
var chain_score := 0.0
var multiplier := 1.0
var drift_time := 0.0
var chain_grace := 0.0
var notice := ""
var notice_timer := 0.0
var camera_mode := 0
var camera_heading := PI / 2
var trail_mesh: MultiMesh
var trail_index := 0
var trail_tick := 0.0
var previous_tires: Array[Vector3] = []
var last_collision := 0
var audio: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var audio_phase := 0.0
var muted := false

func _ready() -> void:
	setup_input()
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a9c8cc")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d7e3df")
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color("a9c8cc")
	env.fog_density = 0.00045
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_color = Color("fff0d1")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180
	add_child(sun)
	world = ChodovMap.new()
	add_child(world)
	car = DriftCar.new()
	add_child(car)
	car.obstacles = world.obstacles
	car.reset_car()
	camera = Camera3D.new()
	camera.fov = 65
	camera.near = 0.5
	camera.far = 2300
	add_child(camera)
	camera.current = true
	update_camera(1.0, true)
	setup_trails()
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Control.new()
	hud.set_script(load("res://scripts/hud.gd"))
	hud.game = self
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(hud)
	setup_audio()

func setup_input() -> void:
	var bindings := {"accelerate": [KEY_W, KEY_UP], "brake": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "slide": [KEY_SPACE], "reset": [KEY_R], "camera": [KEY_C], "pause": [KEY_ESCAPE], "start": [KEY_ENTER], "mute": [KEY_M], "quit_game": [KEY_Q]}
	for action in bindings:
		InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start") or event.is_action_pressed("pause"):
		playing = not playing
		has_started = true
		car.enabled = playing
	if event.is_action_pressed("quit_game") and not playing:
		get_tree().quit()
	if event.is_action_pressed("reset"):
		car.reset_car()
		chain_score = 0
		drift_time = 0
		chain_grace = 0
		previous_tires.clear()
		camera_heading = car.heading
		update_camera(1, true)
	if event.is_action_pressed("camera"):
		camera_mode = (camera_mode + 1) % 3
	if event.is_action_pressed("mute"):
		muted = not muted
		notice = "SOUND OFF" if muted else "SOUND ON"
		notice_timer = 2

func _physics_process(delta: float) -> void:
	if playing:
		car.steering_input = Input.get_axis("left", "right")
		car.throttle = Input.get_action_strength("accelerate")
		car.braking = false
		if Input.is_action_pressed("brake"):
			var fwd := Vector3(-sin(car.heading), 0, -cos(car.heading))
			if car.velocity.dot(fwd) > 1.5:
				car.braking = true
			else:
				car.throttle = -0.5
		car.handbrake = Input.is_action_pressed("slide")
		car.simulate(delta)
		update_score(delta)
		update_trails(delta)
		notice_timer = maxf(0, notice_timer - delta)
	update_camera(delta)
	hud.queue_redraw()

func update_score(delta: float) -> void:
	if car.collision_count != last_collision:
		last_collision = car.collision_count
		chain_score = 0
		drift_time = 0
		chain_grace = 0
		notice = "BONK!  CHAIN RESET"
		notice_timer = 2
	if car.drift_active:
		drift_time += delta
		multiplier = minf(1 + drift_time / 5.0, 5.0)
		chain_score += car.speed_kmh * (car.slip_angle / 90.0) * multiplier * delta
		chain_grace = 1.5
	else:
		chain_grace -= delta
		if chain_grace <= 0 and chain_score > 0:
			total_score += chain_score
			notice = "+%d  /  NICE SLIDE" % int(chain_score)
			notice_timer = 2.5
			chain_score = 0
			drift_time = 0
			multiplier = 1

func update_camera(delta: float, snap: bool = false) -> void:
	camera_heading = lerp_angle(camera_heading, car.heading, 1.0 if snap else 1.0 - exp(-delta * 2.6))
	var behind := Vector3(sin(camera_heading), 0, cos(camera_heading))
	var target: Vector3
	match camera_mode:
		0: target = car.position + behind * 10 + Vector3(0, 5.3, 0)
		1: target = car.position + behind * 18 + Vector3(0, 13, 0)
		_: target = car.position + Vector3(0, 70, 24)
	if camera_mode < 2:
		var focus := car.position + Vector3(0, 1.5, 0)
		var clear := focus
		for step in range(1, 25):
			var point := focus.lerp(target, step / 24.0)
			var blocked := false
			for rect in world.obstacles:
				if rect.grow(0.3).has_point(Vector2(point.x, point.z)):
					blocked = true
					break
			if blocked:
				target = clear
				break
			clear = point
	camera.position = target if snap else camera.position.lerp(target, 1.0 - exp(-delta * 8))
	camera.look_at(car.position + Vector3(0, 0.9, 0))
	camera.fov = lerpf(camera.fov, 65 + car.speed_kmh / 25, minf(delta * 3, 1))

func setup_trails() -> void:
	trail_mesh = MultiMesh.new()
	trail_mesh.transform_format = MultiMesh.TRANSFORM_3D
	var quad := PlaneMesh.new()
	quad.size = Vector2(0.24, 1)
	trail_mesh.mesh = quad
	trail_mesh.instance_count = 5000
	var hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, -20, 0))
	for i in range(trail_mesh.instance_count):
		trail_mesh.set_instance_transform(i, hidden)
	var trails := MultiMeshInstance3D.new()
	trails.multimesh = trail_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("2b313d")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trails.material_override = mat
	trails.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trails)

func update_trails(delta: float) -> void:
	trail_tick += delta
	if not car.drift_active:
		previous_tires.clear()
		return
	if trail_tick < 0.035:
		return
	trail_tick = 0
	var tires: Array[Vector3] = []
	for x in [-0.97, 0.97]:
		tires.append(car.position + Vector3(x, 0.11, 1.26).rotated(Vector3.UP, car.heading))
	if previous_tires.size() == 2:
		for i in range(2):
			var difference := tires[i] - previous_tires[i]
			var length := difference.length()
			if length > 0.02 and length < 8:
				var basis := Basis(Vector3.UP, atan2(difference.x, difference.z)) * Basis.from_scale(Vector3(1, 1, length + 0.04))
				trail_mesh.set_instance_transform(trail_index, Transform3D(basis, (tires[i] + previous_tires[i]) / 2))
				trail_index = (trail_index + 1) % trail_mesh.instance_count
	previous_tires = tires

func setup_audio() -> void:
	if DisplayServer.get_name() == "headless":
		return
	audio = AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.15
	audio.stream = stream
	audio.volume_db = -20
	add_child(audio)
	audio.play()
	playback = audio.get_stream_playback()

func _process(_delta: float) -> void:
	if playback == null:
		return
	var frequency := 45.0 + car.speed_kmh * 0.55 + absf(car.throttle) * 25
	for i in range(playback.get_frames_available()):
		audio_phase = fmod(audio_phase + frequency / 22050.0, 1)
		var sample := (sin(audio_phase * TAU) * 0.6 + sin(audio_phase * TAU * 2) * 0.2) * (0.0 if muted or not playing else 0.30)
		if car.drift_active and not muted and playing:
			sample += sin(audio_phase * TAU * 13) * 0.035
		playback.push_frame(Vector2(sample, sample))
