extends Node2D

## Quick fade ghost of the player

var lifetime := 0.25
var timer := 0.0
var radius := 16.0


func _ready() -> void:
	if has_meta("radius"):
		radius = get_meta("radius")
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _process(delta: float) -> void:
	timer += delta
	var t := timer / lifetime
	modulate.a = (1.0 - t) * 0.35
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.3, 1.0, 1.0))
