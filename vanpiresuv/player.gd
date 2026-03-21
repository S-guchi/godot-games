extends CharacterBody2D

@export var speed := 300.0

var bullet_scene: PackedScene
var dead := false

func _ready() -> void:
	add_to_group("player")
	bullet_scene = load("res://bullet.tscn")
	$FireTimer.timeout.connect(_on_fire_timer_timeout)
	$HitBox.body_entered.connect(_on_hit)

func _physics_process(_delta: float) -> void:
	if dead:
		return
	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	velocity = input.normalized() * speed
	move_and_slide()
	look_at(get_global_mouse_position())

func _on_hit(body: Node2D) -> void:
	if dead:
		return
	if body.is_in_group("enemy"):
		die()

func die() -> void:
	dead = true
	$FireTimer.stop()
	# Death effect at player position
	var effect_script := load("res://death_effect.gd")
	var effect := Node2D.new()
	effect.set_script(effect_script)
	effect.setup(global_position, "DEAD")
	get_tree().current_scene.add_child(effect)
	visible = false
	# Show game over after a short delay
	get_tree().create_timer(1.0).timeout.connect(_show_game_over)

func _show_game_over() -> void:
	var world := get_tree().current_scene
	if world.has_method("show_game_over"):
		world.show_game_over()

func _on_fire_timer_timeout() -> void:
	var b := bullet_scene.instantiate()
	b.global_position = global_position
	b.rotation = rotation
	get_tree().current_scene.add_child(b)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color.CYAN)
