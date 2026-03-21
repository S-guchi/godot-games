extends Node2D

@export var spawn_interval := 0.5
@export var spawn_distance := 500.0
@export var initial_batch := 3
@export var max_batch := 12

var enemy_scene: PackedScene
var score := 0
var kill_count := 0
var elapsed := 0.0

# Combo system
var combo := 0
var combo_timer := 0.0
const COMBO_TIMEOUT := 2.0
var combo_multiplier := 1

# Level / EXP system
var player_level := 1
var player_exp := 0
var exp_to_next_level := 5
var is_leveling_up := false

# Bomb system
var bomb_charge := 0.0
const BOMB_CHARGE_MAX := 100.0
var bomb_charge_rate := 2.0  # per kill

# Boss system
var boss_interval := 60.0
var next_boss_time := 60.0
var boss_active := false

# UI references
var score_label: Label
var kill_label: Label
var combo_label: Label
var combo_mult_label: Label
var exp_bar_bg: ColorRect
var exp_bar_fill: ColorRect
var exp_bar_label: Label
var bomb_bar_bg: ColorRect
var bomb_bar_fill: ColorRect
var bomb_label: Label
var level_label: Label
var boss_warning_label: Label


func _ready() -> void:
	enemy_scene = load("res://enemy.tscn")

	# Spawn timer
	var timer := Timer.new()
	timer.name = "SpawnTimer"
	timer.wait_time = spawn_interval
	timer.timeout.connect(_spawn_wave)
	add_child(timer)
	timer.start()

	# Boss timer
	var boss_timer := Timer.new()
	boss_timer.name = "BossCheckTimer"
	boss_timer.wait_time = 1.0
	boss_timer.timeout.connect(_check_boss_spawn)
	add_child(boss_timer)
	boss_timer.start()

	_setup_ui()


func _setup_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	# Score display (top-right)
	score_label = Label.new()
	score_label.text = "SCORE: 0"
	score_label.position = Vector2(620, 10)
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color.YELLOW)
	score_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(score_label)

	# Kill count (below score)
	kill_label = Label.new()
	kill_label.text = "KILLS: 0"
	kill_label.position = Vector2(620, 45)
	kill_label.add_theme_font_size_override("font_size", 18)
	kill_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	kill_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	kill_label.add_theme_constant_override("shadow_offset_x", 1)
	kill_label.add_theme_constant_override("shadow_offset_y", 1)
	ui.add_child(kill_label)

	# Combo counter (center-right)
	combo_label = Label.new()
	combo_label.text = ""
	combo_label.position = Vector2(620, 75)
	combo_label.add_theme_font_size_override("font_size", 24)
	combo_label.add_theme_color_override("font_color", Color.YELLOW)
	combo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	combo_label.add_theme_constant_override("shadow_offset_x", 2)
	combo_label.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(combo_label)

	# Combo multiplier
	combo_mult_label = Label.new()
	combo_mult_label.text = ""
	combo_mult_label.position = Vector2(620, 105)
	combo_mult_label.add_theme_font_size_override("font_size", 18)
	combo_mult_label.add_theme_color_override("font_color", Color.ORANGE)
	ui.add_child(combo_mult_label)

	# Level display (top-left)
	level_label = Label.new()
	level_label.text = "Lv.1"
	level_label.position = Vector2(10, 10)
	level_label.add_theme_font_size_override("font_size", 22)
	level_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	level_label.add_theme_constant_override("shadow_offset_x", 1)
	level_label.add_theme_constant_override("shadow_offset_y", 1)
	ui.add_child(level_label)

	# EXP bar (top-left, below level)
	exp_bar_bg = ColorRect.new()
	exp_bar_bg.position = Vector2(10, 40)
	exp_bar_bg.size = Vector2(200, 12)
	exp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	ui.add_child(exp_bar_bg)

	exp_bar_fill = ColorRect.new()
	exp_bar_fill.position = Vector2(10, 40)
	exp_bar_fill.size = Vector2(0, 12)
	exp_bar_fill.color = Color(0.3, 1.0, 0.3)
	ui.add_child(exp_bar_fill)

	exp_bar_label = Label.new()
	exp_bar_label.text = "EXP"
	exp_bar_label.position = Vector2(215, 36)
	exp_bar_label.add_theme_font_size_override("font_size", 14)
	exp_bar_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	ui.add_child(exp_bar_label)

	# Bomb bar (below EXP bar)
	bomb_bar_bg = ColorRect.new()
	bomb_bar_bg.position = Vector2(10, 58)
	bomb_bar_bg.size = Vector2(200, 10)
	bomb_bar_bg.color = Color(0.2, 0.15, 0.0, 0.8)
	ui.add_child(bomb_bar_bg)

	bomb_bar_fill = ColorRect.new()
	bomb_bar_fill.position = Vector2(10, 58)
	bomb_bar_fill.size = Vector2(0, 10)
	bomb_bar_fill.color = Color(1.0, 0.5, 0.0)
	ui.add_child(bomb_bar_fill)

	bomb_label = Label.new()
	bomb_label.text = "[Q] BOMB"
	bomb_label.position = Vector2(215, 53)
	bomb_label.add_theme_font_size_override("font_size", 12)
	bomb_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.2))
	ui.add_child(bomb_label)

	# Boss warning
	boss_warning_label = Label.new()
	boss_warning_label.text = ""
	boss_warning_label.position = Vector2(177, 200)
	boss_warning_label.size = Vector2(500, 60)
	boss_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_warning_label.add_theme_font_size_override("font_size", 48)
	boss_warning_label.add_theme_color_override("font_color", Color.RED)
	boss_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	boss_warning_label.add_theme_constant_override("shadow_offset_x", 3)
	boss_warning_label.add_theme_constant_override("shadow_offset_y", 3)
	boss_warning_label.visible = false
	ui.add_child(boss_warning_label)


func _process(delta: float) -> void:
	elapsed += delta

	# Combo decay
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo = 0
			combo_multiplier = 1
			combo_label.text = ""
			combo_mult_label.text = ""

	# Update bomb bar
	var bomb_ratio := bomb_charge / BOMB_CHARGE_MAX
	bomb_bar_fill.size.x = 200.0 * bomb_ratio
	if bomb_charge >= BOMB_CHARGE_MAX:
		bomb_bar_fill.color = Color(1.0, 0.8, 0.0)
		bomb_label.add_theme_color_override("font_color", Color.YELLOW)
		# Pulsing effect
		bomb_bar_fill.modulate.a = 0.7 + sin(elapsed * 8.0) * 0.3
	else:
		bomb_bar_fill.color = Color(1.0, 0.5, 0.0)
		bomb_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.2))
		bomb_bar_fill.modulate.a = 1.0


func add_score(amount: int) -> void:
	# Combo tracking
	combo += 1
	combo_timer = COMBO_TIMEOUT
	combo_multiplier = 1 + int(combo / 5)

	var final_score: int = amount * combo_multiplier
	score += final_score
	kill_count += 1

	# Bomb charge
	bomb_charge = minf(bomb_charge + bomb_charge_rate, BOMB_CHARGE_MAX)

	# Update score UI
	score_label.text = "SCORE: %d" % score
	kill_label.text = "KILLS: %d" % kill_count
	var tw := create_tween()
	tw.tween_property(score_label, "scale", Vector2(1.3, 1.3), 0.05)
	tw.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

	# Update combo UI
	var combo_color := _get_combo_color()
	combo_label.text = "%d COMBO!" % combo
	combo_label.add_theme_color_override("font_color", combo_color)
	combo_mult_label.text = "x%d" % combo_multiplier
	combo_mult_label.add_theme_color_override("font_color", combo_color)

	# Combo label pop animation
	var tw2 := create_tween()
	combo_label.scale = Vector2(1.5, 1.5)
	tw2.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.15)


func _get_combo_color() -> Color:
	if combo >= 50:
		return Color(1.0, 0.0, 1.0)  # Purple
	elif combo >= 30:
		return Color(1.0, 0.0, 0.0)  # Red
	elif combo >= 15:
		return Color(1.0, 0.5, 0.0)  # Orange
	elif combo >= 5:
		return Color(1.0, 1.0, 0.0)  # Yellow
	else:
		return Color(1.0, 1.0, 1.0)  # White


func add_exp(amount: int) -> void:
	if is_leveling_up:
		return
	player_exp += amount
	_update_exp_bar()
	if player_exp >= exp_to_next_level:
		_trigger_level_up()


func _update_exp_bar() -> void:
	var ratio := clampf(float(player_exp) / float(exp_to_next_level), 0.0, 1.0)
	exp_bar_fill.size.x = 200.0 * ratio


func _trigger_level_up() -> void:
	is_leveling_up = true
	player_exp -= exp_to_next_level
	player_level += 1
	exp_to_next_level = 5 + player_level * 3
	level_label.text = "Lv.%d" % player_level

	# Level up flash
	_flash_screen(Color(0.5, 1.0, 0.5, 0.3))

	# Level up label animation
	var tw := create_tween()
	level_label.scale = Vector2(2.0, 2.0)
	tw.tween_property(level_label, "scale", Vector2(1.0, 1.0), 0.3)

	# Slow motion for level up
	Engine.time_scale = 0.3

	# Show upgrade choices
	_show_level_up_choices()


func _show_level_up_choices() -> void:
	var ui := get_node("UI")

	# Darken overlay
	var overlay := ColorRect.new()
	overlay.name = "LevelUpOverlay"
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(854, 480)
	ui.add_child(overlay)

	# LEVEL UP! text
	var title := Label.new()
	title.name = "LevelUpTitle"
	title.text = "LEVEL UP!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(177, 60)
	title.size = Vector2(500, 50)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(title)

	# Generate 3 random upgrade choices
	var all_upgrades := _get_available_upgrades()
	all_upgrades.shuffle()
	var choices: Array = all_upgrades.slice(0, mini(3, all_upgrades.size()))

	for i in choices.size():
		var upgrade: Dictionary = choices[i]
		var btn := Button.new()
		btn.name = "UpgradeBtn%d" % i
		btn.text = "%s\n%s" % [upgrade.name, upgrade.desc]
		btn.position = Vector2(127 + i * 210, 140)
		btn.size = Vector2(190, 200)
		btn.add_theme_font_size_override("font_size", 14)
		var upgrade_id: String = upgrade.id
		btn.pressed.connect(_on_upgrade_chosen.bind(upgrade_id))
		ui.add_child(btn)

		# Animate in
		btn.modulate.a = 0
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "modulate:a", 1.0, 0.2).set_delay(i * 0.1)


func _get_available_upgrades() -> Array:
	var upgrades: Array = []
	var player := $Player
	if not player:
		return upgrades

	upgrades.append({"id": "fire_rate", "name": "RAPID FIRE", "desc": "Fire rate +25%"})
	upgrades.append({"id": "damage", "name": "POWER UP", "desc": "Bullet damage +1"})
	upgrades.append({"id": "speed", "name": "SPEED BOOST", "desc": "Move speed +15%"})
	upgrades.append({"id": "bullet_size", "name": "BIG BULLETS", "desc": "Bullet size +30%"})
	upgrades.append({"id": "knockback", "name": "HEAVY IMPACT", "desc": "Knockback +40%"})

	if not player.has_shotgun:
		upgrades.append({"id": "shotgun", "name": "SHOTGUN", "desc": "Spread shot (5 bullets)"})
	else:
		upgrades.append({"id": "shotgun_up", "name": "SHOTGUN+", "desc": "+2 spread bullets"})

	if not player.has_omni:
		upgrades.append({"id": "omni", "name": "OMNI SHOT", "desc": "Fire in 8 directions"})
	else:
		upgrades.append({"id": "omni_up", "name": "OMNI+", "desc": "+4 directions"})

	if not player.has_pierce:
		upgrades.append({"id": "pierce", "name": "PIERCING", "desc": "Bullets pierce enemies"})
	else:
		upgrades.append({"id": "pierce_up", "name": "PIERCE+", "desc": "+1 pierce count"})

	if not player.has_homing:
		upgrades.append({"id": "homing", "name": "HOMING", "desc": "Bullets seek enemies"})
	else:
		upgrades.append({"id": "homing_up", "name": "HOMING+", "desc": "Stronger tracking"})

	upgrades.append({"id": "bomb_charge", "name": "BOMB MASTER", "desc": "Bomb charges 2x faster"})
	upgrades.append({"id": "dash_cd", "name": "FLASH STEP", "desc": "Dash cooldown -30%"})

	return upgrades


func _on_upgrade_chosen(upgrade_id: String) -> void:
	var player := $Player
	if not player:
		return

	match upgrade_id:
		"fire_rate":
			player.fire_rate_mult *= 0.75
			$Player/FireTimer.wait_time *= 0.75
		"damage":
			player.bullet_damage += 1
		"speed":
			player.speed *= 1.15
		"bullet_size":
			player.bullet_scale += 0.3
		"knockback":
			player.knockback_mult *= 1.4
		"shotgun":
			player.has_shotgun = true
			player.shotgun_count = 5
		"shotgun_up":
			player.shotgun_count += 2
		"omni":
			player.has_omni = true
			player.omni_count = 8
		"omni_up":
			player.omni_count += 4
		"pierce":
			player.has_pierce = true
			player.pierce_count = 2
		"pierce_up":
			player.pierce_count += 1
		"homing":
			player.has_homing = true
			player.homing_strength = 3.0
		"homing_up":
			player.homing_strength += 2.0
		"bomb_charge":
			bomb_charge_rate *= 2.0
		"dash_cd":
			player.dash_cooldown *= 0.7

	# Clean up level up UI
	var ui := get_node("UI")
	for child_name in ["LevelUpOverlay", "LevelUpTitle", "UpgradeBtn0", "UpgradeBtn1", "UpgradeBtn2"]:
		var node := ui.get_node_or_null(child_name)
		if node:
			node.queue_free()

	Engine.time_scale = 1.0
	is_leveling_up = false
	_update_exp_bar()


func try_bomb() -> bool:
	if bomb_charge < BOMB_CHARGE_MAX:
		return false
	bomb_charge = 0.0
	_execute_bomb()
	return true


func _execute_bomb() -> void:
	var player := $Player
	if not player:
		return

	# Screen flash
	_flash_screen(Color(1.0, 0.8, 0.2, 0.6))

	# Heavy screen shake
	var cam := get_viewport().get_camera_2d()
	if cam:
		var tw := create_tween()
		var strength := 20.0
		for j in 12:
			var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
			tw.tween_property(cam, "offset", offset, 0.03)
			strength *= 0.8
		tw.tween_property(cam, "offset", Vector2.ZERO, 0.05)

	# Hit stop
	get_tree().paused = true
	get_tree().create_timer(0.15, true, false, true).timeout.connect(func(): get_tree().paused = false)

	# Spawn shockwave visual
	var wave := Node2D.new()
	wave.global_position = player.global_position
	wave.set_script(load("res://shockwave.gd"))
	add_child(wave)

	# Damage all enemies
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and enemy is RigidBody2D:
			var dir: Vector2 = (enemy.global_position - player.global_position).normalized()
			enemy.apply_central_impulse(dir * 2000.0)
			if enemy.has_method("take_damage"):
				enemy.take_damage(10)


func _flash_screen(color: Color) -> void:
	var ui := get_node("UI")
	var flash := ColorRect.new()
	flash.color = color
	flash.position = Vector2.ZERO
	flash.size = Vector2(854, 480)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	tw.tween_callback(flash.queue_free)


func _check_boss_spawn() -> void:
	if elapsed >= next_boss_time and not boss_active:
		_spawn_boss()


func _spawn_boss() -> void:
	boss_active = true
	next_boss_time = elapsed + boss_interval

	# Warning
	boss_warning_label.text = "WARNING: BOSS INCOMING!"
	boss_warning_label.visible = true
	var tw := create_tween()
	# Flashing warning
	for i in 6:
		tw.tween_property(boss_warning_label, "modulate:a", 0.0, 0.25)
		tw.tween_property(boss_warning_label, "modulate:a", 1.0, 0.25)
	tw.tween_callback(func():
		boss_warning_label.visible = false
		_do_spawn_boss()
	)

	# Screen shake for warning
	var cam := get_viewport().get_camera_2d()
	if cam:
		var shake_tw := create_tween()
		shake_tw.set_loops(6)
		shake_tw.tween_property(cam, "offset", Vector2(4, 4), 0.1)
		shake_tw.tween_property(cam, "offset", Vector2(-4, -4), 0.1)
		shake_tw.tween_property(cam, "offset", Vector2.ZERO, 0.1)


func _do_spawn_boss() -> void:
	var player := $Player
	if not player:
		return
	var e := enemy_scene.instantiate()
	var angle := randf() * TAU
	e.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * spawn_distance
	e.setup_shape(3)  # BOSS type
	e.tree_exited.connect(func(): boss_active = false)
	add_child(e)

	# Flash screen red
	_flash_screen(Color(1, 0, 0, 0.4))


func show_game_over() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	for child in get_children():
		if child is Timer:
			child.stop()

	var ui := get_node("UI")

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(854, 480)
	ui.add_child(overlay)

	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(177, 100)
	title.size = Vector2(500, 80)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color.RED)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	ui.add_child(title)

	var score_text := Label.new()
	score_text.text = "SCORE: %d  |  KILLS: %d  |  Lv.%d" % [score, kill_count, player_level]
	score_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_text.position = Vector2(177, 190)
	score_text.size = Vector2(500, 40)
	score_text.add_theme_font_size_override("font_size", 24)
	score_text.add_theme_color_override("font_color", Color.YELLOW)
	ui.add_child(score_text)

	var combo_text := Label.new()
	combo_text.text = "MAX COMBO: %d" % combo
	combo_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_text.position = Vector2(177, 225)
	combo_text.size = Vector2(500, 30)
	combo_text.add_theme_font_size_override("font_size", 18)
	combo_text.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	ui.add_child(combo_text)

	var retry := Button.new()
	retry.text = "RETRY"
	retry.position = Vector2(327, 280)
	retry.size = Vector2(200, 60)
	retry.add_theme_font_size_override("font_size", 32)
	retry.pressed.connect(_on_retry)
	ui.add_child(retry)

	var tw := create_tween()
	title.modulate.a = 0
	score_text.modulate.a = 0
	combo_text.modulate.a = 0
	retry.modulate.a = 0
	tw.tween_property(title, "modulate:a", 1.0, 0.3)
	tw.tween_property(score_text, "modulate:a", 1.0, 0.3)
	tw.tween_property(combo_text, "modulate:a", 1.0, 0.3)
	tw.tween_property(retry, "modulate:a", 1.0, 0.3)


func _on_retry() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()


func _spawn_wave() -> void:
	var player := $Player
	if not player:
		return
	var batch: int = mini(initial_batch + int(elapsed / 15.0), max_batch)
	for i in batch:
		var angle := randf() * TAU
		var dist := spawn_distance + randf_range(-80, 80)
		var offset := Vector2.RIGHT.rotated(angle) * dist
		var e := enemy_scene.instantiate()
		e.global_position = player.global_position + offset
		var roll := randf()
		if roll < 0.25:
			e.setup_shape(1)  # SQUARE
		elif roll < 0.5:
			e.setup_shape(2)  # TRIANGLE
		else:
			e.setup_shape(0)  # CIRCLE
		add_child(e)
