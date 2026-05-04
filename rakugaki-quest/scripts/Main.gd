extends Control

const SAVE_PATH := "user://rakugaki_mvp_save.json"
const PLAYER_BASE := {
	"id": "player_mycup",
	"name": "マイコップ",
	"image_path": "res://assets/rakugaki/cup.png",
	"max_hp": 50,
	"attack": 10,
	"defense": 0,
	"crit_rate": 0.05,
	"heal_on_kill": 0,
	"double_attack_rate": 0.0,
	"enemy_attack_down": 0,
	"first_strike": 0
}
const COLORS := {
	"ink": Color("#202124"),
	"paper": Color("#fff8dc"),
	"panel": Color("#fffdf3"),
	"green": Color("#7ecf5a"),
	"green_dark": Color("#2d6f3f"),
	"blue": Color("#89c7ff"),
	"red": Color("#f36b5f"),
	"yellow": Color("#ffd75a"),
	"shadow": Color("#d8d0a5")
}
const LOG_LIMIT := 5
const UPGRADE_INTERVAL := 3

var tab := "battle"
var enemies: Array = []
var upgrades: Array = []
var player := {}
var current_enemy := {}
var current_enemy_hp := 1
var defeated_count := 0
var run_upgrades: Array = []
var pending_upgrades: Array = []
var pending_upgrade := false
var is_game_over := false
var run_started := false
var battle_log: Array[String] = []
var busy := false
var rng := RandomNumberGenerator.new()

var best_defeated_count := 0
var total_defeated_count := 0
var discovered_enemy_ids: Array = []
var enemy_defeat_counts := {}
var play_count := 0

var root_box: VBoxContainer
var header: PanelContainer
var content: Control
var footer: HBoxContainer
var message_label: Label
var enemy_texture: TextureRect
var player_texture: TextureRect
var enemy_name_label: Label
var enemy_hp_label: Label
var player_status_label: Label
var tap_button: Button
var upgrade_box: VBoxContainer

func _ready() -> void:
	rng.randomize()
	_setup_window()
	_seed_data()
	_load_game()
	_start_new_run(false)
	_build_layout()
	_show_tab("battle")

func _setup_window() -> void:
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

func _seed_data() -> void:
	enemies = [
		_make_enemy("enemy_cup", "コップ", "res://assets/rakugaki/cup.png", 26, 6, 1, 8, "common", "からんころん", "空っぽの時ほど強気になる。"),
		_make_enemy("enemy_aircon", "エアコン", "res://assets/rakugaki/aircon.png", 32, 7, 1, 10, "common", "ぬる風ビーム", "設定温度を忘れてしまった箱。"),
		_make_enemy("enemy_tv", "テレビ", "res://assets/rakugaki/tv.png", 38, 8, 4, 14, "common", "砂嵐チョップ", "見ていない時だけよくしゃべる。"),
		_make_enemy("enemy_homework", "宿題", "res://assets/rakugaki/homework.png", 46, 10, 6, 18, "rare", "あとでやるパンチ", "放っておくと机の上で増える。"),
		_make_enemy("enemy_mikan", "みかん", "res://assets/rakugaki/mikan.png", 52, 11, 9, 24, "common", "すっぱい体当たり", "こたつを探して旅をしている。"),
		_make_enemy("enemy_school", "学校", "res://assets/rakugaki/school.png", 62, 13, 12, 0, "rare", "チャイム落とし", "放課後になると少しさみしい。"),
		_make_enemy("enemy_cola", "コーラ", "res://assets/rakugaki/cola.png", 72, 15, 18, 0, "super_rare", "あわあわアタック", "ぬるくなると急に弱気になる。")
	]
	upgrades = [
		{"id": "attack_3", "name": "ぺちっ強化", "description": "攻撃力 +3"},
		{"id": "hp_10", "name": "じょうぶになる", "description": "最大HP +10、HP +10"},
		{"id": "crit_10", "name": "たまに本気", "description": "クリティカル率 +10%"},
		{"id": "defense_2", "name": "ふんばる", "description": "受けるダメージ -2"},
		{"id": "heal_3", "name": "おやつ休憩", "description": "敵を倒すたびHP +3"},
		{"id": "double_20", "name": "二度ぺち", "description": "20%の確率で2回攻撃"},
		{"id": "enemy_down_1", "name": "あわてない心", "description": "敵の攻撃力 -1"},
		{"id": "first_5", "name": "先制ぺち", "description": "敵出現時に5ダメージ"}
	]

func _make_enemy(id: String, name: String, image_path: String, base_hp: int, base_attack: int, min_stage: int, max_stage: int, rarity: String, skill_name: String, description: String) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"image_path": image_path,
		"base_hp": base_hp,
		"base_attack": base_attack,
		"min_stage": min_stage,
		"max_stage": max_stage,
		"rarity": rarity,
		"skill_name": skill_name,
		"description": description
	}

func _build_layout() -> void:
	add_theme_font_size_override("font_size", 18)
	root_box = VBoxContainer.new()
	root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_box.add_theme_constant_override("separation", 0)
	add_child(root_box)

	header = _panel(Color("#f7e67a"), 0, 0)
	header.custom_minimum_size = Vector2(0, 58)
	var title := Label.new()
	title.text = "落書きクエスト"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", COLORS.ink)
	header.add_child(title)
	root_box.add_child(header)

	content = Control.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(content)

	footer = HBoxContainer.new()
	footer.custom_minimum_size = Vector2(0, 66)
	footer.add_theme_constant_override("separation", 4)
	footer.add_theme_constant_override("margin_left", 6)
	footer.add_theme_constant_override("margin_right", 6)
	root_box.add_child(footer)

	for item in [["battle", "バトル"], ["dex", "図鑑"], ["records", "記録"], ["settings", "設定"]]:
		var button := _button(item[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(func() -> void: _show_tab(item[0]))
		footer.add_child(button)

func _show_tab(next_tab: String) -> void:
	tab = next_tab
	for child in content.get_children():
		child.queue_free()
	match tab:
		"battle":
			_build_battle()
		"dex":
			_build_dex()
		"records":
			_build_records()
		"settings":
			_build_settings()

func _build_battle() -> void:
	var screen := _make_screen()
	content.add_child(screen)

	var battle_panel := _panel(Color("#dff3ff"), 5, 0)
	battle_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(battle_panel)

	var field := VBoxContainer.new()
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field.add_theme_constant_override("separation", 3)
	field.add_theme_constant_override("margin_left", 10)
	field.add_theme_constant_override("margin_right", 10)
	field.add_theme_constant_override("margin_top", 8)
	field.add_theme_constant_override("margin_bottom", 8)
	battle_panel.add_child(field)

	enemy_name_label = _label("", 18, HORIZONTAL_ALIGNMENT_CENTER)
	field.add_child(enemy_name_label)
	enemy_texture = _sprite_rect(Vector2(220, 220))
	enemy_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	field.add_child(enemy_texture)
	enemy_hp_label = _label("", 16, HORIZONTAL_ALIGNMENT_CENTER)
	field.add_child(enemy_hp_label)

	var vs := _label("VS", 21, HORIZONTAL_ALIGNMENT_CENTER)
	vs.add_theme_color_override("font_color", COLORS.red)
	field.add_child(vs)

	var player_row := HBoxContainer.new()
	player_row.alignment = BoxContainer.ALIGNMENT_CENTER
	player_row.add_theme_constant_override("separation", 10)
	field.add_child(player_row)

	player_texture = _sprite_rect(Vector2(78, 78))
	player_row.add_child(player_texture)
	player_status_label = _label("", 14, HORIZONTAL_ALIGNMENT_LEFT)
	player_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	player_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_row.add_child(player_status_label)

	var message_panel := _panel(Color("#fffdf3"), 5, 0)
	message_panel.custom_minimum_size = Vector2(0, 214)
	screen.add_child(message_panel)
	var message_box := VBoxContainer.new()
	message_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message_box.add_theme_constant_override("margin_left", 16)
	message_box.add_theme_constant_override("margin_right", 16)
	message_box.add_theme_constant_override("margin_top", 8)
	message_box.add_theme_constant_override("margin_bottom", 8)
	message_panel.add_child(message_box)
	message_label = _label("", 16, HORIZONTAL_ALIGNMENT_LEFT)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_box.add_child(message_label)
	upgrade_box = VBoxContainer.new()
	upgrade_box.add_theme_constant_override("separation", 5)
	message_box.add_child(upgrade_box)
	tap_button = _button("ぺちっ！")
	tap_button.custom_minimum_size = Vector2(0, 48)
	tap_button.pressed.connect(_battle_turn)
	message_box.add_child(tap_button)

	_refresh_battle()

func _build_dex() -> void:
	var screen := _make_screen()
	content.add_child(screen)
	screen.add_child(_label("図鑑 %d / %d" % [discovered_enemy_ids.size(), enemies.size()], 24, HORIZONTAL_ALIGNMENT_CENTER))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for enemy in enemies:
		grid.add_child(_enemy_card(enemy, discovered_enemy_ids.has(enemy.id)))

func _build_records() -> void:
	var screen := _make_screen()
	content.add_child(screen)
	screen.add_child(_label("記録", 24, HORIZONTAL_ALIGNMENT_CENTER))
	var panel := _panel(Color("#fffdf3"), 5, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 12)
	box.add_theme_constant_override("margin_left", 18)
	box.add_theme_constant_override("margin_right", 18)
	box.add_theme_constant_override("margin_top", 18)
	box.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(box)
	box.add_child(_label("最高到達数: %d体" % best_defeated_count, 20, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_label("累計撃破数: %d体" % total_defeated_count, 20, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_label("図鑑登録数: %d / %d" % [discovered_enemy_ids.size(), enemies.size()], 20, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_label("プレイ回数: %d回" % play_count, 18, HORIZONTAL_ALIGNMENT_LEFT))

func _build_settings() -> void:
	var screen := _make_screen()
	content.add_child(screen)
	screen.add_child(_label("設定", 24, HORIZONTAL_ALIGNMENT_CENTER))
	var panel := _panel(Color("#fffdf3"), 5, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen.add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 12)
	box.add_theme_constant_override("margin_left", 18)
	box.add_theme_constant_override("margin_right", 18)
	box.add_theme_constant_override("margin_top", 18)
	box.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(box)
	box.add_child(_label("保存データ", 20, HORIZONTAL_ALIGNMENT_LEFT))
	var reset_button := _button("記録をリセット")
	reset_button.custom_minimum_size = Vector2(0, 52)
	reset_button.pressed.connect(_reset_save)
	box.add_child(reset_button)

func _enemy_card(enemy: Dictionary, known: bool) -> PanelContainer:
	var card := _panel(Color("#ffffff"), 4, 0)
	card.custom_minimum_size = Vector2(172, 218)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("margin_left", 8)
	box.add_theme_constant_override("margin_right", 8)
	box.add_theme_constant_override("margin_top", 8)
	box.add_theme_constant_override("margin_bottom", 8)
	card.add_child(box)
	var sprite := _sprite_rect(Vector2(92, 92))
	sprite.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sprite.texture = _load_texture(enemy.image_path)
	if not known:
		sprite.modulate = Color("#222222")
	box.add_child(sprite)
	var text := "？？？\n未発見"
	if known:
		var count := int(enemy_defeat_counts.get(enemy.id, 0))
		text = "%s\n%s\n撃破 %d回\n%s" % [enemy.name, _rarity_label(enemy.rarity), count, enemy.description]
	var label := _label(text, 13, HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	return card

func _make_screen() -> VBoxContainer:
	var screen := VBoxContainer.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_theme_constant_override("separation", 10)
	screen.add_theme_constant_override("margin_left", 10)
	screen.add_theme_constant_override("margin_right", 10)
	screen.add_theme_constant_override("margin_top", 10)
	screen.add_theme_constant_override("margin_bottom", 10)
	var bg := ColorRect.new()
	bg.color = Color("#b7df7b")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(bg)
	return screen

func _panel(color: Color, border_width: int, corner: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = COLORS.ink
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner)
	style.shadow_color = COLORS.shadow
	style.shadow_size = 0
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", COLORS.ink)
	button.add_theme_color_override("font_hover_color", COLORS.ink)
	button.add_theme_color_override("font_pressed_color", COLORS.ink)
	button.add_theme_color_override("font_hover_pressed_color", COLORS.ink)
	button.add_theme_color_override("font_disabled_color", Color("#5b5b55"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLORS.yellow
	normal.border_color = COLORS.ink
	normal.set_border_width_all(4)
	var pressed := normal.duplicate()
	pressed.bg_color = Color("#ffba4b")
	var disabled := normal.duplicate()
	disabled.bg_color = Color("#d8d6c9")
	disabled.border_color = Color("#55554f")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	return button

func _label(text: String, size: int, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", COLORS.ink)
	return label

func _sprite_rect(min_size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = min_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect

func _refresh_battle() -> void:
	if enemy_name_label == null:
		return
	enemy_name_label.text = "到達 %d体目\n%s が あらわれた！" % [defeated_count + 1, current_enemy.name]
	enemy_hp_label.text = "HP: %d / %d" % [current_enemy_hp, int(current_enemy.hp)]
	player_status_label.text = "%s\nHP: %d / %d\n攻撃:%d 防御:%d クリ:%d%%" % [
		player.name,
		int(player.hp),
		int(player.max_hp),
		int(player.attack),
		int(player.defense),
		int(round(float(player.crit_rate) * 100.0))
	]
	enemy_texture.texture = _load_texture(current_enemy.image_path)
	player_texture.texture = _load_texture(player.image_path)
	message_label.text = "\n".join(battle_log)
	_rebuild_upgrade_buttons()
	if is_game_over:
		tap_button.text = "もう一度"
	elif pending_upgrade:
		tap_button.text = "強化を選ぶ"
	else:
		tap_button.text = "ぺちっ！"
	tap_button.disabled = busy or pending_upgrade

func _battle_turn() -> void:
	if busy:
		return
	if is_game_over:
		_start_new_run(true)
		_refresh_battle()
		return
	if pending_upgrade:
		return
	busy = true
	tap_button.disabled = true
	var total_damage := _deal_player_damage()
	_add_log("%sの「ぺちっ！」 %sに %dダメージ。" % [player.name, current_enemy.name, total_damage])
	_shake_enemy()
	await get_tree().create_timer(0.18).timeout
	_unshake_enemy()
	if current_enemy_hp <= 0:
		_win_battle()
		await get_tree().create_timer(0.35).timeout
		if not pending_upgrade and not is_game_over:
			_spawn_enemy()
		busy = false
		_refresh_battle()
		return
	var enemy_damage: int = max(1, int(current_enemy.attack) - int(player.defense) - int(player.enemy_attack_down) + rng.randi_range(-1, 1))
	player.hp = max(0, int(player.hp) - enemy_damage)
	_add_log("%sの「%s」！ %dダメージ。" % [current_enemy.name, current_enemy.skill_name, enemy_damage])
	if int(player.hp) <= 0:
		_game_over()
	busy = false
	_refresh_battle()

func _deal_player_damage() -> int:
	var hits := 1
	if rng.randf() < float(player.double_attack_rate):
		hits += 1
	var total := 0
	for i in range(hits):
		var damage: int = max(1, int(player.attack) + rng.randi_range(-2, 2))
		if rng.randf() < float(player.crit_rate):
			damage *= 2
			_add_log("たまに本気が出た！")
		total += damage
	current_enemy_hp = max(0, current_enemy_hp - total)
	return total

func _win_battle() -> void:
	defeated_count += 1
	total_defeated_count += 1
	best_defeated_count = max(best_defeated_count, defeated_count)
	enemy_defeat_counts[current_enemy.id] = int(enemy_defeat_counts.get(current_enemy.id, 0)) + 1
	_add_log("%sは しゅわしゅわ消えた。" % current_enemy.name)
	if not discovered_enemy_ids.has(current_enemy.id):
		discovered_enemy_ids.append(current_enemy.id)
		_add_log("図鑑に %s が登録された！" % current_enemy.name)
	if int(player.heal_on_kill) > 0:
		player.hp = min(int(player.max_hp), int(player.hp) + int(player.heal_on_kill))
		_add_log("%sは おやつで少し回復した。" % player.name)
	if defeated_count % UPGRADE_INTERVAL == 0:
		_open_upgrade_choices()
	else:
		_add_log("次の変な敵が近づいてくる。")
	_save_game()

func _open_upgrade_choices() -> void:
	pending_upgrade = true
	pending_upgrades.clear()
	var pool := upgrades.duplicate(true)
	while pending_upgrades.size() < 3 and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		pending_upgrades.append(pool[index])
		pool.remove_at(index)
	_add_log("今回だけの強化を選ぼう。")

func _choose_upgrade(upgrade: Dictionary) -> void:
	if busy:
		return
	run_upgrades.append(upgrade.id)
	match String(upgrade.id):
		"attack_3":
			player.attack += 3
		"hp_10":
			player.max_hp += 10
			player.hp += 10
		"crit_10":
			player.crit_rate += 0.10
		"defense_2":
			player.defense += 2
		"heal_3":
			player.heal_on_kill += 3
		"double_20":
			player.double_attack_rate += 0.20
		"enemy_down_1":
			player.enemy_attack_down += 1
		"first_5":
			player.first_strike += 5
	pending_upgrade = false
	pending_upgrades.clear()
	_add_log("%s を手に入れた。" % upgrade.name)
	_spawn_enemy()
	_refresh_battle()

func _rebuild_upgrade_buttons() -> void:
	if upgrade_box == null:
		return
	for child in upgrade_box.get_children():
		child.queue_free()
	if not pending_upgrade:
		return
	for upgrade in pending_upgrades:
		var button := _button("%s  %s" % [upgrade.name, upgrade.description])
		button.add_theme_font_size_override("font_size", 14)
		button.custom_minimum_size = Vector2(0, 38)
		button.pressed.connect(func(item: Dictionary = upgrade) -> void: _choose_upgrade(item))
		upgrade_box.add_child(button)

func _game_over() -> void:
	is_game_over = true
	_add_log("%sは ふにゃふにゃになった。" % player.name)
	_add_log("記録: %d体" % defeated_count)
	_save_game()

func _start_new_run(count_play: bool) -> void:
	player = PLAYER_BASE.duplicate(true)
	player.hp = player.max_hp
	defeated_count = 0
	run_upgrades.clear()
	pending_upgrades.clear()
	pending_upgrade = false
	is_game_over = false
	run_started = true
	battle_log.clear()
	if count_play:
		play_count += 1
	_save_game()
	_spawn_enemy()
	_add_log("バトル開始。変な敵を倒して進もう。")

func _spawn_enemy() -> void:
	var stage := defeated_count + 1
	var candidates: Array = []
	for enemy in enemies:
		var max_stage := int(enemy.max_stage)
		if stage >= int(enemy.min_stage) and (max_stage == 0 or stage <= max_stage):
			candidates.append(enemy)
	if candidates.is_empty():
		candidates = enemies
	current_enemy = candidates[rng.randi_range(0, candidates.size() - 1)].duplicate(true)
	current_enemy.hp = int(current_enemy.base_hp) + defeated_count * 2
	current_enemy.attack = int(current_enemy.base_attack) + int(floor(float(defeated_count) / 3.0))
	current_enemy_hp = int(current_enemy.hp)
	if int(player.first_strike) > 0:
		current_enemy_hp = max(0, current_enemy_hp - int(player.first_strike))
		_add_log("先制ぺち！ %sに %dダメージ。" % [current_enemy.name, int(player.first_strike)])

func _shake_enemy() -> void:
	if enemy_texture:
		enemy_texture.position.x += 10

func _unshake_enemy() -> void:
	if enemy_texture:
		enemy_texture.position.x -= 10

func _add_log(text: String) -> void:
	battle_log.append(text)
	while battle_log.size() > LOG_LIMIT:
		battle_log.pop_front()

func _rarity_label(rarity: String) -> String:
	match rarity:
		"rare":
			return "レア"
		"super_rare":
			return "すごくレア"
	return "ふつう"

func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) == OK:
		return ImageTexture.create_from_image(image)
	return null

func _reset_save() -> void:
	best_defeated_count = 0
	total_defeated_count = 0
	discovered_enemy_ids.clear()
	enemy_defeat_counts.clear()
	play_count = 0
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	_start_new_run(false)
	_show_tab("battle")

func _save_game() -> void:
	var data := {
		"best_defeated_count": best_defeated_count,
		"total_defeated_count": total_defeated_count,
		"discovered_enemy_ids": discovered_enemy_ids,
		"enemy_defeat_counts": enemy_defeat_counts,
		"play_count": play_count
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	best_defeated_count = int(parsed.get("best_defeated_count", 0))
	total_defeated_count = int(parsed.get("total_defeated_count", 0))
	discovered_enemy_ids = parsed.get("discovered_enemy_ids", [])
	enemy_defeat_counts = parsed.get("enemy_defeat_counts", {})
	play_count = int(parsed.get("play_count", 0))
