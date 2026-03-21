extends Area2D

@export var speed := 600.0
@export var knockback_force := 500.0
@export var damage := 1

var direction := Vector2.RIGHT

# Pierce
var pierce_count := 0
var hits_remaining := 0

# Homing
var is_homing := false
var homing_strength := 3.0

# Trail particles
var trail_points: Array[Vector2] = []
const MAX_TRAIL := 8
var trail_timer := 0.0


func _ready() -> void:
	direction = Vector2.RIGHT.rotated(rotation)
	hits_remaining = pierce_count
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	# Homing logic
	if is_homing:
		var closest: Node2D = null
		var closest_dist := 99999.0
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(enemy):
				var d: float = global_position.distance_to(enemy.global_position)
				if d < closest_dist:
					closest_dist = d
					closest = enemy
		if closest and closest_dist < 400.0:
			var target_dir: Vector2 = (closest.global_position - global_position).normalized()
			direction = direction.lerp(target_dir, homing_strength * delta).normalized()
			rotation = direction.angle()

	position += direction * speed * delta

	# Trail
	trail_timer += delta
	if trail_timer >= 0.02:
		trail_timer = 0.0
		trail_points.push_front(global_position)
		if trail_points.size() > MAX_TRAIL:
			trail_points.resize(MAX_TRAIL)
		queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and body.is_in_group("enemy"):
		var impulse_dir := (body.global_position - global_position).normalized()
		body.apply_central_impulse(impulse_dir * knockback_force)
		_spawn_hit_spark()
		if body.has_method("take_damage"):
			body.take_damage(damage)

		if hits_remaining > 0:
			hits_remaining -= 1
			# Continue through enemy
		else:
			queue_free()


func _spawn_hit_spark() -> void:
	var spark := Node2D.new()
	spark.global_position = global_position
	spark.set_script(_HitSpark)
	get_tree().current_scene.add_child(spark)


func _draw() -> void:
	# Glowing bullet with trail feel
	var glow_size := 8.0
	var core_size := 5.0
	var inner_size := 2.5

	if is_homing:
		draw_circle(Vector2.ZERO, glow_size, Color(0.5, 0.3, 1.0, 0.3))
		draw_circle(Vector2.ZERO, core_size, Color(0.7, 0.4, 1.0))
		draw_circle(Vector2.ZERO, inner_size, Color.WHITE)
	else:
		draw_circle(Vector2.ZERO, glow_size, Color(1, 1, 0.5, 0.3))
		draw_circle(Vector2.ZERO, core_size, Color.YELLOW)
		draw_circle(Vector2.ZERO, inner_size, Color.WHITE)

	# Draw trail
	for i in trail_points.size():
		var t := float(i) / float(MAX_TRAIL)
		var alpha := (1.0 - t) * 0.4
		var radius := (1.0 - t) * 3.0
		var local_pos: Vector2 = trail_points[i] - global_position
		if is_homing:
			draw_circle(local_pos, radius, Color(0.7, 0.4, 1.0, alpha))
		else:
			draw_circle(local_pos, radius, Color(1.0, 0.8, 0.2, alpha))


const _HitSpark := preload("res://hit_spark.gd")
