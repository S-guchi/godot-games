extends RigidBody2D

enum Shape { CIRCLE, SQUARE, TRIANGLE, BOSS }

@export var move_speed := 80.0
@export var lerp_weight := 0.03

var hp := 3
var max_hp := 3
var flash_timer := 0.0
var shape_type: int = Shape.CIRCLE
var size := 20.0
var base_color := Color.RED
var inner_color := Color(0.8, 0.15, 0.1)
var score_value := 100
var gem_count := 1
var is_boss := false

# Boss pulse
var pulse_timer := 0.0

# Shape configs: [hp, size, speed, lerp, color, inner_color, score, gems]
const SHAPE_CONFIG := {
	Shape.CIRCLE: [3, 20.0, 80.0, 0.03, Color.RED, Color(0.8, 0.15, 0.1), 100, 1],
	Shape.SQUARE: [5, 22.0, 50.0, 0.02, Color(0.2, 0.4, 1.0), Color(0.15, 0.25, 0.7), 200, 2],
	Shape.TRIANGLE: [1, 16.0, 150.0, 0.06, Color(0.1, 0.9, 0.3), Color(0.05, 0.6, 0.15), 50, 1],
	Shape.BOSS: [80, 60.0, 40.0, 0.015, Color(1.0, 0.2, 0.8), Color(0.6, 0.1, 0.5), 2000, 20],
}


func _ready() -> void:
	add_to_group("enemy")


func setup_shape(type: int) -> void:
	shape_type = type
	var cfg: Array = SHAPE_CONFIG[type]
	hp = cfg[0]
	max_hp = hp
	size = cfg[1]
	move_speed = cfg[2]
	lerp_weight = cfg[3]
	base_color = cfg[4]
	inner_color = cfg[5]
	score_value = cfg[6]
	gem_count = cfg[7]
	is_boss = (type == Shape.BOSS)

	var col: CollisionShape2D = $CollisionShape2D
	if shape_type == Shape.SQUARE:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(size * 2, size * 2)
		col.shape = rect
	else:
		var circle := CircleShape2D.new()
		circle.radius = size
		col.shape = circle

	if shape_type == Shape.SQUARE:
		mass = 2.0
	elif shape_type == Shape.TRIANGLE:
		mass = 0.5
	elif shape_type == Shape.BOSS:
		mass = 10.0


func _physics_process(_delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		linear_velocity = linear_velocity.lerp(dir * move_speed, lerp_weight)

		# Boss special: charge at player periodically
		if is_boss and pulse_timer <= 0:
			pulse_timer = 3.0
			linear_velocity = dir * move_speed * 4.0


func _process(delta: float) -> void:
	if flash_timer > 0:
		flash_timer -= delta
		queue_redraw()

	if is_boss:
		pulse_timer -= delta
		queue_redraw()  # For HP bar and pulse animation


func take_damage(amount: int) -> void:
	hp -= amount
	flash_timer = 0.1
	queue_redraw()

	# Camera zoom on boss hit
	if is_boss:
		var cam := get_viewport().get_camera_2d()
		if cam:
			var tw := create_tween()
			tw.tween_property(cam, "zoom", Vector2(1.55, 1.55), 0.03)
			tw.tween_property(cam, "zoom", Vector2(1.5, 1.5), 0.1)

	if hp <= 0:
		call_deferred("die")


func die() -> void:
	# Death effect
	var effect_script := load("res://death_effect.gd")
	var effect := Node2D.new()
	effect.set_script(effect_script)
	effect.setup(global_position, "+%d" % score_value)
	if is_boss:
		effect.set_meta("boss", true)
	get_tree().current_scene.add_child(effect)

	# Add score
	var world := get_tree().current_scene
	if world.has_method("add_score"):
		world.add_score(score_value)

	# Drop gems
	_drop_gems()

	queue_free()


func _drop_gems() -> void:
	var gem_script := load("res://gem.gd")
	for i in gem_count:
		var gem := Node2D.new()
		gem.set_script(gem_script)
		gem.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		if is_boss:
			gem.set_meta("exp_value", 3)
			gem.set_meta("gem_size", 8.0)
		get_tree().current_scene.call_deferred("add_child", gem)


func _draw() -> void:
	if flash_timer > 0:
		_draw_shape(size + 2.0, Color.WHITE, Color.WHITE)
	else:
		_draw_shape(size, base_color, inner_color)

	# Boss HP bar
	if is_boss:
		var bar_width := size * 2.5
		var bar_height := 6.0
		var bar_y := -size - 15.0
		# Background
		draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2, 0.8))
		# HP fill
		var hp_ratio := float(hp) / float(max_hp)
		var hp_color := Color.RED if hp_ratio < 0.3 else (Color.YELLOW if hp_ratio < 0.6 else Color(1.0, 0.2, 0.8))
		draw_rect(Rect2(Vector2(-bar_width / 2, bar_y), Vector2(bar_width * hp_ratio, bar_height)), hp_color)
		# Pulsing aura
		var pulse := 0.5 + sin(pulse_timer * 5.0) * 0.3
		draw_circle(Vector2.ZERO, size + 10.0, Color(1.0, 0.2, 0.8, pulse * 0.15))


func _draw_shape(s: float, outer: Color, inner: Color) -> void:
	match shape_type:
		Shape.CIRCLE:
			draw_circle(Vector2.ZERO, s, outer)
			draw_circle(Vector2.ZERO, s * 0.7, inner)
		Shape.SQUARE:
			var rect := Rect2(Vector2(-s, -s), Vector2(s * 2, s * 2))
			draw_rect(rect, outer)
			var inner_rect := Rect2(Vector2(-s * 0.65, -s * 0.65), Vector2(s * 1.3, s * 1.3))
			draw_rect(inner_rect, inner)
		Shape.TRIANGLE:
			var points := PackedVector2Array([
				Vector2(0, -s),
				Vector2(s * 0.866, s * 0.5),
				Vector2(-s * 0.866, s * 0.5),
			])
			draw_colored_polygon(points, outer)
			var inner_points := PackedVector2Array([
				Vector2(0, -s * 0.6),
				Vector2(s * 0.52, s * 0.3),
				Vector2(-s * 0.52, s * 0.3),
			])
			draw_colored_polygon(inner_points, inner)
		Shape.BOSS:
			# Big menacing circle with spikes
			draw_circle(Vector2.ZERO, s, outer)
			draw_circle(Vector2.ZERO, s * 0.7, inner)
			# Spike ring
			for i in 12:
				var angle := (TAU / 12.0) * i + pulse_timer * 0.5
				var spike_start: Vector2 = Vector2.RIGHT.rotated(angle) * s * 0.9
				var spike_end: Vector2 = Vector2.RIGHT.rotated(angle) * s * 1.3
				draw_line(spike_start, spike_end, outer, 3.0)
			# Inner eye
			draw_circle(Vector2.ZERO, s * 0.3, Color(1.0, 1.0, 0.0))
			draw_circle(Vector2.ZERO, s * 0.15, Color(0.1, 0.0, 0.1))
