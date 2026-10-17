extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	for i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/workspace/artifacts/title.png")
	scene.playing = true
	scene.has_started = true
	scene.car.reset_car(Vector3(0, 0, 205), -0.5)
	scene.camera.position = Vector3(8, 6, 218)
	scene.camera.look_at(Vector3(0, 2, 200))
	scene.hud.queue_redraw()
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/workspace/artifacts/gameplay.png")
	scene.camera.position = Vector3(0, 1600, 900)
	scene.camera.near = 10
	scene.camera.look_at(Vector3.ZERO)
	scene.hud.hide()
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/workspace/artifacts/map.png")
	print("Rendered title and gameplay captures")
	scene.queue_free()
	await process_frame
	quit()
