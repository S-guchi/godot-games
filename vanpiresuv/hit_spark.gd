extends Node2D

## Quick spark effect on bullet impact

var lifetime := 0.15
var timer := 0.0
var spark_lines: Array[Dictionary] = []

func _ready() -> void:
	# Generate random spark lines
	for i in 8:
		var angle := randf() * TAU
		var length := randf_range(10, 25)
		var color := Color(1, 1, randf_range(0.3, 1.0))
		spark_lines.append({"angle": angle, "length": length, "color": color})
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _process(delta: float) -> void:
	timer += delta
	queue_redraw()

func _draw() -> void:
	var t := timer / lifetime
	var alpha := 1.0 - t
	# Central flash
	draw_circle(Vector2.ZERO, (1.0 - t) * 12.0, Color(1, 1, 0.8, alpha * 0.7))
	# Spark lines radiating outward
	for s in spark_lines:
		var a: float = s.angle
		var l: float = s.length
		var start: Vector2 = Vector2.RIGHT.rotated(a) * t * l * 0.5
		var end: Vector2 = Vector2.RIGHT.rotated(a) * (0.3 + t * 0.7) * l
		var c: Color = s.color
		c.a = alpha
		draw_line(start, end, c, 2.0)
