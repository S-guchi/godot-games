extends Area2D

@export var speed := 600.0
@export var knockback_force := 500.0
@export var damage := 1

var direction := Vector2.RIGHT

func _ready() -> void:
	direction = Vector2.RIGHT.rotated(rotation)
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is RigidBody2D and body.is_in_group("enemy"):
		var impulse_dir := (body.global_position - global_position).normalized()
		body.apply_central_impulse(impulse_dir * knockback_force)
		_spawn_hit_spark()
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()


func _spawn_hit_spark() -> void:
	var spark := Node2D.new()
	spark.global_position = global_position
	spark.set_script(_HitSpark)
	get_tree().current_scene.add_child(spark)

func _draw() -> void:
	# Glowing bullet with trail feel
	draw_circle(Vector2.ZERO, 8.0, Color(1, 1, 0.5, 0.3))
	draw_circle(Vector2.ZERO, 5.0, Color.YELLOW)
	draw_circle(Vector2.ZERO, 2.5, Color.WHITE)


## Hit spark inner class
const _HitSpark := preload("res://hit_spark.gd")
