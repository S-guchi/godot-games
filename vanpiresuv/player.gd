extends CharacterBody2D

@export var speed := 300.0

var bullet_scene: PackedScene
var dead := false

# Weapon upgrades
var bullet_damage := 1
var bullet_scale := 1.0
var knockback_mult := 1.0
var fire_rate_mult := 1.0
var has_shotgun := false
var shotgun_count := 5
var has_omni := false
var omni_count := 8
var has_pierce := false
var pierce_count := 2
var has_homing := false
var homing_strength := 3.0

# Dash
var dash_cooldown := 1.5
var dash_timer := 0.0
var dash_speed := 900.0
var dash_duration := 0.15
var dash_active := false
var dash_time_left := 0.0
var is_invincible := false

# Afterimage
var afterimage_timer := 0.0
const AFTERIMAGE_INTERVAL := 0.03


func _ready() -> void:
	add_to_group("player")
	bullet_scene = load("res://bullet.tscn")
	$FireTimer.timeout.connect(_on_fire_timer_timeout)
	$HitBox.body_entered.connect(_on_hit)

	# Register dash input
	if not InputMap.has_action("dash"):
		InputMap.add_action("dash")
		var ev := InputEventKey.new()
		ev.keycode = KEY_SPACE
		InputMap.action_add_event("dash", ev)

	# Register bomb input
	if not InputMap.has_action("bomb"):
		InputMap.add_action("bomb")
		var ev := InputEventKey.new()
		ev.keycode = KEY_Q
		InputMap.action_add_event("bomb", ev)


func _physics_process(delta: float) -> void:
	if dead:
		return

	# Dash cooldown
	if dash_timer > 0:
		dash_timer -= delta

	# Dash active
	if dash_active:
		dash_time_left -= delta
		if dash_time_left <= 0:
			dash_active = false
			is_invincible = false
		else:
			move_and_slide()
			# Afterimage during dash
			afterimage_timer -= delta
			if afterimage_timer <= 0:
				afterimage_timer = AFTERIMAGE_INTERVAL
				_spawn_afterimage()
			return

	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	velocity = input.normalized() * speed
	move_and_slide()
	look_at(get_global_mouse_position())

	# Spawn afterimage while moving
	if input.length() > 0.1:
		afterimage_timer -= delta
		if afterimage_timer <= 0:
			afterimage_timer = 0.08
			_spawn_afterimage()

	# Dash input
	if Input.is_action_just_pressed("dash") and dash_timer <= 0 and input.length() > 0.1:
		_start_dash(input.normalized())

	# Bomb input
	if Input.is_action_just_pressed("bomb"):
		var world := get_tree().current_scene
		if world.has_method("try_bomb"):
			if world.try_bomb():
				# Bomb visual feedback on player
				_spawn_dash_shockwave()


func _start_dash(dir: Vector2) -> void:
	dash_active = true
	dash_time_left = dash_duration
	dash_timer = dash_cooldown
	is_invincible = true
	velocity = dir * dash_speed

	# Dash shockwave
	_spawn_dash_shockwave()

	# Screen shake
	var cam := get_viewport().get_camera_2d()
	if cam:
		var tw := create_tween()
		tw.tween_property(cam, "offset", velocity.normalized() * -8, 0.03)
		tw.tween_property(cam, "offset", Vector2.ZERO, 0.1)


func _spawn_dash_shockwave() -> void:
	var wave := Node2D.new()
	wave.global_position = global_position
	wave.set_script(load("res://shockwave.gd"))
	wave.set_meta("max_radius", 60.0)
	wave.set_meta("duration", 0.2)
	get_tree().current_scene.add_child(wave)


func _spawn_afterimage() -> void:
	var ghost := Node2D.new()
	ghost.global_position = global_position
	ghost.rotation = rotation
	ghost.modulate = Color(0.3, 1.0, 1.0, 0.4)
	ghost.set_script(load("res://afterimage.gd"))
	ghost.set_meta("radius", 16.0)
	get_tree().current_scene.add_child(ghost)


func _on_hit(body: Node2D) -> void:
	if dead or is_invincible:
		return
	if body.is_in_group("enemy"):
		die()


func die() -> void:
	dead = true
	$FireTimer.stop()
	var effect_script := load("res://death_effect.gd")
	var effect := Node2D.new()
	effect.set_script(effect_script)
	effect.set_meta("player_death", true)
	effect.setup(global_position, "DEAD")
	get_tree().current_scene.add_child(effect)
	visible = false
	get_tree().create_timer(2.5).timeout.connect(_show_game_over)


func _show_game_over() -> void:
	var world := get_tree().current_scene
	if world.has_method("show_game_over"):
		world.show_game_over()


func _on_fire_timer_timeout() -> void:
	if dead:
		return
	_fire_main_bullet()
	if has_shotgun:
		_fire_shotgun()
	if has_omni:
		_fire_omni()


func _fire_main_bullet() -> void:
	var b := _create_bullet()
	b.global_position = global_position
	b.rotation = rotation
	get_tree().current_scene.add_child(b)


func _fire_shotgun() -> void:
	var spread := deg_to_rad(40.0)
	var half := shotgun_count / 2
	for i in shotgun_count:
		var angle_offset: float = (i - half) * (spread / shotgun_count)
		var b := _create_bullet()
		b.global_position = global_position
		b.rotation = rotation + angle_offset
		get_tree().current_scene.add_child(b)


func _fire_omni() -> void:
	for i in omni_count:
		var angle := (TAU / omni_count) * i
		var b := _create_bullet()
		b.global_position = global_position
		b.rotation = angle
		get_tree().current_scene.add_child(b)


func _create_bullet() -> Node:
	var b := bullet_scene.instantiate()
	b.damage = bullet_damage
	b.knockback_force = 500.0 * knockback_mult
	if has_pierce:
		b.pierce_count = pierce_count
	if has_homing:
		b.is_homing = true
		b.homing_strength = homing_strength
	if bullet_scale != 1.0:
		b.scale = Vector2(bullet_scale, bullet_scale)
	return b


func _draw() -> void:
	# Main body
	draw_circle(Vector2.ZERO, 16.0, Color.CYAN)
	# Inner glow
	draw_circle(Vector2.ZERO, 10.0, Color(0.7, 1.0, 1.0, 0.6))
	# Direction indicator
	draw_line(Vector2.ZERO, Vector2(20, 0), Color.WHITE, 2.0)

	# Dash cooldown ring
	if dash_timer > 0:
		var ratio := dash_timer / dash_cooldown
		var arc_end := TAU * (1.0 - ratio)
		draw_arc(Vector2.ZERO, 22.0, 0, arc_end, 32, Color(0, 1, 1, 0.3), 2.0)
