extends Node2D

## Enemy death effect: white flash + physics debris + score popup + camera zoom

const DEBRIS_COUNT := 12
const DEBRIS_SPEED_MIN := 200.0
const DEBRIS_SPEED_MAX := 500.0
const FLASH_DURATION := 0.12

var flash_timer := 0.0
var flash_radius := 40.0
var score_text := ""
var score_alpha := 1.0
var score_offset := 0.0
var is_boss := false


func _ready() -> void:
	if has_meta("boss"):
		is_boss = true
	flash_timer = FLASH_DURATION

	if is_boss:
		_spawn_boss_death()
	else:
		_spawn_debris()

	_apply_screen_shake()
	_apply_camera_zoom()

	# Hit stop
	var freeze_time := 0.15 if is_boss else 0.04
	get_tree().paused = true
	get_tree().create_timer(freeze_time, true, false, true).timeout.connect(_unfreeze)

	# Slow motion after boss kill
	if is_boss:
		Engine.time_scale = 0.2
		get_tree().create_timer(1.0, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

	get_tree().create_timer(2.0).timeout.connect(queue_free)


func setup(pos: Vector2, text: String) -> void:
	global_position = pos
	score_text = text


func _unfreeze() -> void:
	get_tree().paused = false


func _process(delta: float) -> void:
	flash_timer -= delta
	score_alpha = maxf(score_alpha - delta * 1.5, 0.0)
	score_offset -= delta * 60.0
	queue_redraw()


func _draw() -> void:
	if flash_timer > 0:
		var t := flash_timer / FLASH_DURATION
		var radius := flash_radius * (2.0 - t)
		var alpha := t * 0.9

		if is_boss:
			radius *= 3.0
			# Multi-colored flash for boss
			draw_circle(Vector2.ZERO, radius, Color(1, 0.3, 0.8, alpha))
			draw_circle(Vector2.ZERO, radius * 0.6, Color(1, 1, 0.5, alpha))
			draw_circle(Vector2.ZERO, radius * 0.3, Color(1, 1, 1, alpha))
		else:
			draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, alpha))
			draw_circle(Vector2.ZERO, radius * 0.4, Color(1, 1, 0.8, alpha))

	if score_alpha > 0 and score_text != "":
		var font := ThemeDB.fallback_font
		var font_size := 32 if is_boss else 20
		var pos := Vector2(-15, score_offset - 30)
		var color := Color(1, 0.3, 1.0, score_alpha) if is_boss else Color(1, 1, 0.3, score_alpha)
		draw_string(font, pos, score_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)


func _spawn_debris() -> void:
	for i in DEBRIS_COUNT:
		_create_debris_piece(i, DEBRIS_COUNT, 1.0)


func _spawn_boss_death() -> void:
	# Massive debris explosion
	var boss_debris_count := 40
	for i in boss_debris_count:
		_create_debris_piece(i, boss_debris_count, 2.0)

	# Multiple shockwave rings
	for ring in 3:
		var wave := Node2D.new()
		wave.global_position = global_position
		wave.set_script(load("res://shockwave.gd"))
		wave.set_meta("max_radius", 200.0 + ring * 100.0)
		wave.set_meta("duration", 0.4 + ring * 0.15)
		get_tree().current_scene.call_deferred("add_child", wave)

	# Screen flash
	var world := get_tree().current_scene
	if world.has_method("_flash_screen"):
		world._flash_screen(Color(1, 0.3, 0.8, 0.6))


func _create_debris_piece(i: int, total: int, scale_mult: float) -> void:
	var debris := RigidBody2D.new()
	debris.gravity_scale = 0.0
	debris.linear_damp = 2.0
	var angle := (TAU / total) * i + randf_range(-0.3, 0.3)
	var spd := randf_range(DEBRIS_SPEED_MIN, DEBRIS_SPEED_MAX) * scale_mult
	debris.linear_velocity = Vector2.RIGHT.rotated(angle) * spd
	var size := randf_range(3.0, 8.0) * scale_mult
	var colors: Array
	if is_boss:
		colors = [Color(1, 0.2, 0.8), Color(0.8, 0.1, 0.6), Color(1, 0.5, 0.9), Color(1, 1, 0.3), Color(1, 0.6, 0.2)]
	else:
		colors = [Color.RED, Color.DARK_RED, Color(1, 0.3, 0.1), Color(0.8, 0.1, 0.1), Color(1, 0.6, 0.2)]
	var color: Color = colors[i % colors.size()]

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = size
	shape.shape = circle
	debris.add_child(shape)

	var visual := _DebrisVisual.new()
	visual.radius = size
	visual.color = color
	debris.add_child(visual)

	debris.collision_layer = 0
	debris.collision_mask = 0
	debris.angular_velocity = randf_range(-10, 10)

	add_child(debris)

	var tw := create_tween()
	tw.tween_property(visual, "modulate:a", 0.0, randf_range(0.8, 1.5))
	tw.tween_callback(debris.queue_free)


func _apply_screen_shake() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		var tw := create_tween()
		var shake_strength := 20.0 if is_boss else 6.0
		var shake_count := 12 if is_boss else 6
		for j in shake_count:
			var offset := Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
			tw.tween_property(cam, "offset", offset, 0.03)
			shake_strength *= 0.7
		tw.tween_property(cam, "offset", Vector2.ZERO, 0.03)


func _apply_camera_zoom() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		var tw := create_tween()
		if is_boss:
			tw.tween_property(cam, "zoom", Vector2(1.7, 1.7), 0.05)
			tw.tween_property(cam, "zoom", Vector2(1.3, 1.3), 0.3)
			tw.tween_property(cam, "zoom", Vector2(1.5, 1.5), 0.2)
		else:
			tw.tween_property(cam, "zoom", Vector2(1.55, 1.55), 0.03)
			tw.tween_property(cam, "zoom", Vector2(1.5, 1.5), 0.1)


class _DebrisVisual extends Node2D:
	var radius := 5.0
	var color := Color.RED

	func _draw() -> void:
		var points := PackedVector2Array()
		var num_points := randi_range(4, 6)
		for i in num_points:
			var angle := (TAU / num_points) * i + randf_range(-0.4, 0.4)
			var r := radius * randf_range(0.5, 1.0)
			points.append(Vector2.RIGHT.rotated(angle) * r)
		if points.size() >= 3:
			draw_colored_polygon(points, color)
