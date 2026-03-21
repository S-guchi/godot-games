extends Node2D

## Enemy death effect: white flash + physics debris + score popup

const DEBRIS_COUNT := 12
const DEBRIS_SPEED_MIN := 200.0
const DEBRIS_SPEED_MAX := 500.0
const FLASH_DURATION := 0.12

var flash_timer := 0.0
var flash_radius := 40.0
var score_text := ""
var score_alpha := 1.0
var score_offset := 0.0


func _ready() -> void:
	flash_timer = FLASH_DURATION
	_spawn_debris()
	# Screen shake
	_apply_screen_shake()
	# Hit stop (tiny freeze frame for impact feel)
	get_tree().paused = true
	get_tree().create_timer(0.04, true, false, true).timeout.connect(_unfreeze)
	# Self-destruct after effects finish
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
	# White flash circle (expanding + fading)
	if flash_timer > 0:
		var t := flash_timer / FLASH_DURATION
		var radius := flash_radius * (2.0 - t)
		var alpha := t * 0.9
		draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, alpha))
		# Inner bright core
		draw_circle(Vector2.ZERO, radius * 0.4, Color(1, 1, 0.8, alpha))

	# Score popup floating up
	if score_alpha > 0 and score_text != "":
		var font := ThemeDB.fallback_font
		var font_size := 20
		var pos := Vector2(-15, score_offset - 30)
		draw_string(font, pos, score_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 1, 0.3, score_alpha))


func _spawn_debris() -> void:
	for i in DEBRIS_COUNT:
		var debris := RigidBody2D.new()
		debris.gravity_scale = 0.0
		debris.linear_damp = 2.0
		var angle := (TAU / DEBRIS_COUNT) * i + randf_range(-0.3, 0.3)
		var spd := randf_range(DEBRIS_SPEED_MIN, DEBRIS_SPEED_MAX)
		debris.linear_velocity = Vector2.RIGHT.rotated(angle) * spd
		# Random size and color for variety
		var size := randf_range(3.0, 8.0)
		var colors := [Color.RED, Color.DARK_RED, Color(1, 0.3, 0.1), Color(0.8, 0.1, 0.1), Color(1, 0.6, 0.2)]
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

		# Disable collision with everything (pure visual)
		debris.collision_layer = 0
		debris.collision_mask = 0
		debris.angular_velocity = randf_range(-10, 10)

		add_child(debris)

		# Fade out and free debris
		var tw := create_tween()
		tw.tween_property(visual, "modulate:a", 0.0, randf_range(0.8, 1.5))
		tw.tween_callback(debris.queue_free)


func _apply_screen_shake() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		var tw := create_tween()
		var shake_strength := 6.0
		for j in 6:
			var offset := Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
			tw.tween_property(cam, "offset", offset, 0.03)
			shake_strength *= 0.7
		tw.tween_property(cam, "offset", Vector2.ZERO, 0.03)


## Inner class for debris visual
class _DebrisVisual extends Node2D:
	var radius := 5.0
	var color := Color.RED

	func _draw() -> void:
		# Draw irregular chunk shape
		var points := PackedVector2Array()
		var num_points := randi_range(4, 6)
		for i in num_points:
			var angle := (TAU / num_points) * i + randf_range(-0.4, 0.4)
			var r := radius * randf_range(0.5, 1.0)
			points.append(Vector2.RIGHT.rotated(angle) * r)
		if points.size() >= 3:
			draw_colored_polygon(points, color)
