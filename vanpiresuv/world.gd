extends Node2D

@export var spawn_interval := 0.5
@export var spawn_distance := 500.0
@export var initial_batch := 3
@export var max_batch := 12

var enemy_scene: PackedScene
var score := 0
var score_label: Label
var kill_count := 0
var kill_label: Label
var elapsed := 0.0


func _ready() -> void:
	enemy_scene = load("res://enemy.tscn")

	# Spawn timer
	var timer := Timer.new()
	timer.wait_time = spawn_interval
	timer.timeout.connect(_spawn_wave)
	add_child(timer)
	timer.start()

	# UI layer
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	# Score display (top-right)
	score_label = Label.new()
	score_label.text = "SCORE: 0"
	score_label.position = Vector2(620, 10)
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color.YELLOW)
	score_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(score_label)

	# Kill count (below score)
	kill_label = Label.new()
	kill_label.text = "KILLS: 0"
	kill_label.position = Vector2(620, 45)
	kill_label.add_theme_font_size_override("font_size", 18)
	kill_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	kill_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	kill_label.add_theme_constant_override("shadow_offset_x", 1)
	kill_label.add_theme_constant_override("shadow_offset_y", 1)
	ui.add_child(kill_label)


func _process(delta: float) -> void:
	elapsed += delta


func show_game_over() -> void:
	# Stop spawning
	get_tree().paused = false
	for child in get_children():
		if child is Timer:
			child.stop()

	var ui := get_node("UI")

	# Dark overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(854, 480)
	ui.add_child(overlay)

	# GAME OVER text
	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(177, 120)
	title.size = Vector2(500, 80)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color.RED)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	ui.add_child(title)

	# Final score
	var score_text := Label.new()
	score_text.text = "SCORE: %d  |  KILLS: %d" % [score, kill_count]
	score_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_text.position = Vector2(177, 200)
	score_text.size = Vector2(500, 40)
	score_text.add_theme_font_size_override("font_size", 28)
	score_text.add_theme_color_override("font_color", Color.YELLOW)
	ui.add_child(score_text)

	# Retry button
	var retry := Button.new()
	retry.text = "RETRY"
	retry.position = Vector2(327, 280)
	retry.size = Vector2(200, 60)
	retry.add_theme_font_size_override("font_size", 32)
	retry.pressed.connect(_on_retry)
	ui.add_child(retry)

	# Animate in
	var tw := create_tween()
	title.modulate.a = 0
	score_text.modulate.a = 0
	retry.modulate.a = 0
	tw.tween_property(title, "modulate:a", 1.0, 0.3)
	tw.tween_property(score_text, "modulate:a", 1.0, 0.3)
	tw.tween_property(retry, "modulate:a", 1.0, 0.3)


func _on_retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func add_score(amount: int) -> void:
	score += amount
	kill_count += 1
	score_label.text = "SCORE: %d" % score
	kill_label.text = "KILLS: %d" % kill_count
	var tw := create_tween()
	tw.tween_property(score_label, "scale", Vector2(1.3, 1.3), 0.05)
	tw.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)


func _spawn_wave() -> void:
	var player := $Player
	if not player:
		return
	# Batch size ramps up over time: +1 every 15 seconds
	var batch: int = mini(initial_batch + int(elapsed / 15.0), max_batch)
	for i in batch:
		var angle := randf() * TAU
		var dist := spawn_distance + randf_range(-80, 80)
		var offset := Vector2.RIGHT.rotated(angle) * dist
		var e := enemy_scene.instantiate()
		e.global_position = player.global_position + offset
		# Random shape: 50% circle, 25% square, 25% triangle
		var roll := randf()
		if roll < 0.25:
			e.setup_shape(1)  # SQUARE
		elif roll < 0.5:
			e.setup_shape(2)  # TRIANGLE
		else:
			e.setup_shape(0)  # CIRCLE
		add_child(e)
