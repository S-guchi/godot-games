extends Node2D

## Experience gem - drops from enemies, magnetically attracted to player

var exp_value := 1
var gem_size := 5.0
var magnet_range := 120.0
var magnet_speed := 400.0
var collected := false
var bob_timer := 0.0
var spawn_velocity := Vector2.ZERO
var spawn_friction := 5.0
var gem_color := Color(0.3, 1.0, 0.5)
var glow_color := Color(0.5, 1.0, 0.7, 0.3)


func _ready() -> void:
	# Check for meta overrides
	if has_meta("exp_value"):
		exp_value = get_meta("exp_value")
	if has_meta("gem_size"):
		gem_size = get_meta("gem_size")
		gem_color = Color(0.3, 0.5, 1.0)  # Blue for big gems
		glow_color = Color(0.3, 0.6, 1.0, 0.3)

	# Random initial pop
	spawn_velocity = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(80, 160)

	# Auto-despawn after 30s
	get_tree().create_timer(30.0).timeout.connect(queue_free)


func _process(delta: float) -> void:
	bob_timer += delta

	# Spawn pop deceleration
	if spawn_velocity.length() > 1.0:
		spawn_velocity = spawn_velocity.lerp(Vector2.ZERO, spawn_friction * delta)
		global_position += spawn_velocity * delta

	# Magnet to player
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player and not collected:
		var dist: float = global_position.distance_to(player.global_position)
		if dist < magnet_range:
			var dir: Vector2 = (player.global_position - global_position).normalized()
			var attract_speed: float = magnet_speed * (1.0 - dist / magnet_range)
			global_position += dir * attract_speed * delta

			if dist < 20.0:
				_collect()

	queue_redraw()


func _collect() -> void:
	if collected:
		return
	collected = true

	var world := get_tree().current_scene
	if world.has_method("add_exp"):
		world.add_exp(exp_value)

	# Quick scale-down and disappear
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(0.01, 0.01), 0.1)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var bob := sin(bob_timer * 4.0) * 2.0

	# Glow
	draw_circle(Vector2(0, bob), gem_size + 3.0, glow_color)
	# Main gem
	var points := PackedVector2Array([
		Vector2(0, -gem_size + bob),
		Vector2(gem_size * 0.7, bob),
		Vector2(0, gem_size + bob),
		Vector2(-gem_size * 0.7, bob),
	])
	draw_colored_polygon(points, gem_color)
	# Shine
	draw_circle(Vector2(-gem_size * 0.2, -gem_size * 0.3 + bob), gem_size * 0.2, Color(1, 1, 1, 0.6))
