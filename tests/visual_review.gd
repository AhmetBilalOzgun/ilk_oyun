extends Node

# Deterministic visual QA in real renderer; does not complete runs or change unlocks.
const OUT := "res://output/visual-revision"

func _ready() -> void:
	get_window().size = Vector2i(540, 960)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await get_tree().process_frame
	for scene in ["home", "level_select", "characters", "battle"]:
		var node = load("res://scenes/%s.tscn" % scene).instantiate()
		add_child(node)
		await get_tree().create_timer(0.25).timeout
		await _capture(scene)
		if scene == "battle":
			node.set_process(false)
			var rhythm := RhythmMinigame.new()
			add_child(rhythm)
			rhythm.setup(5, Rect2(90, 400, 900, 560), 1.0)
			rhythm.set_process(false)
			rhythm._steps = [0, 1, 2, 3, 4]
			for i in range(5):
				var cue: Node2D = rhythm._notes[i]["node"]
				for art in cue.get_children():
					cue.remove_child(art)
					art.queue_free()
				rhythm._notes[i]["step"] = i
				cue.add_child(rhythm._create_pixel_tile(i, i == 4))
			rhythm._clock = 0.08
			rhythm._process(0)
			await _capture("rhythm-faint")
			rhythm._clock = 0.70
			rhythm._process(0)
			await _capture("rhythm-ready")
			# All swipe directions render as native arrows, independent of fonts.
			var first_cue: Node2D = rhythm._notes[0]["node"]
			for art in first_cue.get_children():
				first_cue.remove_child(art)
				art.queue_free()
			first_cue.add_child(rhythm._create_pixel_tile(InputSequence.Step.SWIPE_RIGHT, false))
			rhythm._notes[0]["step"] = InputSequence.Step.SWIPE_RIGHT
			rhythm._process(0)
			await _capture("rhythm-arrow")
			# Deliberately overlapping note windows: input must resolve large cue.
			rhythm._notes[0]["t"] = 1.0
			rhythm._notes[1]["t"] = 1.2
			rhythm._clock = 1.16
			rhythm._register_gesture(rhythm._notes[0]["step"])
			assert(rhythm._notes[0]["hit"] and not rhythm._notes[1]["hit"], "input must resolve first cue")
			assert(not rhythm._broke)
			# Wrong direction breaks, timeouts break, and out-of-window input waits.
			rhythm._clock = float(rhythm._notes[1]["t"])
			rhythm._register_gesture(InputSequence.Step.TAP)
			assert(rhythm._broke and rhythm._finished)
			rhythm.queue_free()
			var timeout := RhythmMinigame.new()
			add_child(timeout)
			timeout.setup(1, Rect2(90, 400, 900, 560))
			timeout.set_process(false)
			timeout._register_gesture(timeout._notes[0]["step"])
			assert(not timeout._notes[0]["hit"], "early gesture waits")
			timeout._process(2.0)
			assert(timeout._broke and timeout._finished, "late gesture misses")
			timeout.queue_free()
			await get_tree().process_frame
			for world in range(5):
				node._world_index = world
				node._update_world()
				node._clear_bodies()
				node._build_bodies()
				await _capture("battle-world-%d" % world)
		node.queue_free()
		await get_tree().process_frame
	await _gallery()
	print("VISUAL_REVIEW_OK")
	get_tree().quit()

func _capture(capture_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + "/" + capture_name + ".png")

func _gallery() -> void:
	var page := Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	GameLook.background(page, 1)
	var title := GameLook.label("BÜYÜCÜ FORMLARI", 54)
	title.position = Vector2(70, 65)
	page.add_child(title)
	var names := ["Alev", "Alev · Kritik", "Alev · Yakma", "Alev · Patlama", "Plazma", "Plazma · Kritik", "Plazma · Patlama", "Plazma · Kör Eden"]
	var keys := ["fire", "fire_crit", "fire_burn", "fire_explosive", "plasma", "plasma_crit", "plasma_explosive", "plasma_blind"]
	for i in range(8):
		var p := Vector2(55 + (i % 2) * 500, 190 + floori(i / 2.0) * 420)
		GameLook.card(page, Rect2(p, Vector2(470, 390)))
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = GameLook.frames(keys[i])
		sprite.position = p + Vector2(235, 170)
		sprite.scale = Vector2.ONE * 1.2
		page.add_child(sprite)
		sprite.play("idle")
		var label := GameLook.label(names[i], 30)
		label.position = p + Vector2(12, 335)
		label.size.x = 446
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		page.add_child(label)
	await _capture("forms")
	page.queue_free()
