extends SceneTree

var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	await process_frame
	var car: DriftCar = scene.car
	check(absf(ChodovMap.RING_RADIUS * TAU - 5000) < 0.01, "Outer road centreline measures 5 km")
	check(scene.world.obstacles.size() >= 3, "Shopping centre and buildings have collision bounds")
	check(not scene.playing, "Game begins in title menu")
	var event := InputEventAction.new()
	event.action = "start"
	event.pressed = true
	scene._unhandled_input(event)
	check(scene.playing and car.enabled, "Enter starts gameplay")
	car.reset_car(Vector3(0, 0, 500), 0)
	car.throttle = 1
	for i in range(120):
		car.simulate(1.0 / 60)
	check(car.speed_kmh > 90, "Throttle accelerates the car")
	car.throttle = 0
	car.steering_input = 1
	car.handbrake = true
	var original_velocity := car.velocity
	for i in range(50):
		car.simulate(1.0 / 60)
	check(absf(rad_to_deg(car.steer) - 90) < 0.1, "Front steering reaches 90 degrees")
	check(car.slip_angle > 45, "Car can rotate sideways to its travel direction")
	check(car.velocity.length() > original_velocity.length() * 0.85, "Handbrake slide retains momentum")
	check(car.drift_active, "Sideways motion activates drift detection")
	scene.update_score(1.0)
	check(scene.chain_score > 0, "Drifts earn score")
	car.drift_active = false
	scene.update_score(2.0)
	check(scene.total_score > 0 and scene.chain_score == 0, "Finished drift banks its score")
	car.steering_input = -1
	for i in range(65):
		car.simulate(1.0 / 60)
	check(absf(rad_to_deg(car.steer) + 90) < 0.1, "Countersteer reaches negative 90 degrees")
	car.steering_input = 0
	car.braking = true
	for i in range(180):
		car.simulate(1.0 / 60)
	check(car.speed_kmh < 0.1, "Brake brings car to a stop")
	car.braking = false
	car.throttle = -0.5
	car.reset_car(Vector3(0, 0, 500), 0)
	for i in range(60):
		car.simulate(1.0 / 60)
	check(car.position.z > 500, "Reverse moves backwards")
	car.throttle = 0
	car.reset_car(Vector3(0, 0, 85), 0)
	car.velocity = Vector3(0, 0, -30)
	var collisions := car.collision_count
	for i in range(60):
		car.simulate(1.0 / 60)
	check(car.collision_count > collisions and car.position.z > 63, "Car bounces off the shopping centre")
	car.reset_car(Vector3(1079, 0, 0), 0)
	car.velocity = Vector3(30, 0, 0)
	for i in range(30):
		car.simulate(1.0 / 60)
	check(Vector2(car.position.x, car.position.z).length() <= 1080, "World boundary keeps car on the map")
	car.reset_car()
	check(car.velocity == Vector3.ZERO and car.position == Vector3(0, 0, 258), "Reset restores spawn and clears momentum")
	event.action = "pause"
	scene._unhandled_input(event)
	check(not scene.playing and not car.enabled, "Pause disables driving")
	var saved := car.position
	car.throttle = 1
	car.simulate(1)
	check(car.position == saved, "Paused car does not move")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
