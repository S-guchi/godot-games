extends Node2D

## Expanding ring shockwave effect

var max_radius := 200.0
var duration := 0.5
var timer := 0.0
var ring_color := Color(1.0, 0.8, 0.2)
var ring_width := 4.0


func _ready() -> void:
	if has_meta("max_radius"):
		max_radius = get_meta("max_radius")
	if has_meta("duration"):
		duration = get_meta("duration")
	get_tree().create_timer(duration).timeout.connect(queue_free)


func _process(delta: float) -> void:
	timer += delta
	queue_redraw()


func _draw() -> void:
	var t := timer / duration
	var radius := max_radius * t
	var alpha := (1.0 - t) * 0.8

	# Outer ring
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(ring_color.r, ring_color.g, ring_color.b, alpha), ring_width)
	# Inner glow ring
	draw_arc(Vector2.ZERO, radius * 0.8, 0, TAU, 64, Color(1, 1, 1, alpha * 0.3), ring_width * 2)
	# Core flash (early phase only)
	if t < 0.3:
		var core_alpha := (1.0 - t / 0.3) * 0.5
		draw_circle(Vector2.ZERO, radius * 0.3, Color(1, 1, 0.8, core_alpha))
