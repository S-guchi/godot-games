extends RigidBody2D

enum Shape { CIRCLE, SQUARE, TRIANGLE }

@export var move_speed := 80.0
@export var lerp_weight := 0.03

var hp := 3
var flash_timer := 0.0
var shape_type: int = Shape.CIRCLE
var size := 20.0
var base_color := Color.RED
var inner_color := Color(0.8, 0.15, 0.1)
var score_value := 100

# Shape configs: [hp, size, speed, lerp, color, inner_color, score]
const SHAPE_CONFIG := {
	Shape.CIRCLE: [3, 20.0, 80.0, 0.03, Color.RED, Color(0.8, 0.15, 0.1), 100],
	Shape.SQUARE: [5, 22.0, 50.0, 0.02, Color(0.2, 0.4, 1.0), Color(0.15, 0.25, 0.7), 200],
	Shape.TRIANGLE: [1, 16.0, 150.0, 0.06, Color(0.1, 0.9, 0.3), Color(0.05, 0.6, 0.15), 50],
}


func _ready() -> void:
	add_to_group("enemy")


func setup_shape(type: int) -> void:
	shape_type = type
	var cfg: Array = SHAPE_CONFIG[type]
	hp = cfg[0]
	size = cfg[1]
	move_speed = cfg[2]
	lerp_weight = cfg[3]
	base_color = cfg[4]
	inner_color = cfg[5]
	score_value = cfg[6]
	# Update collision shape to match
	var col: CollisionShape2D = $CollisionShape2D
	if shape_type == Shape.SQUARE:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(size * 2, size * 2)
		col.shape = rect
	else:
		var circle := CircleShape2D.new()
		circle.radius = size
		col.shape = circle
	# Heavier squares, lighter triangles
	if shape_type == Shape.SQUARE:
		mass = 2.0
	elif shape_type == Shape.TRIANGLE:
		mass = 0.5


func _physics_process(_delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		linear_velocity = linear_velocity.lerp(dir * move_speed, lerp_weight)


func _process(delta: float) -> void:
	if flash_timer > 0:
		flash_timer -= delta
		queue_redraw()


func take_damage(amount: int) -> void:
	hp -= amount
	flash_timer = 0.1
	queue_redraw()
	if hp <= 0:
		die()


func die() -> void:
	var effect_script := load("res://death_effect.gd")
	var effect := Node2D.new()
	effect.set_script(effect_script)
	effect.setup(global_position, "+%d" % score_value)
	get_tree().current_scene.add_child(effect)
	var world := get_tree().current_scene
	if world.has_method("add_score"):
		world.add_score(score_value)
	queue_free()


func _draw() -> void:
	if flash_timer > 0:
		_draw_shape(size + 2.0, Color.WHITE, Color.WHITE)
	else:
		_draw_shape(size, base_color, inner_color)


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
