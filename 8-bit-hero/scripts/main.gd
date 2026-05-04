extends Control

const GameStateScript = preload("res://scripts/game_state.gd")
const Items = preload("res://data/items.gd")
const Skills = preload("res://data/skills.gd")

const CHARACTER_REGIONS := {
	"hero": Rect2(0, 0, 384, 512),
	"slime": Rect2(384, 0, 384, 512),
	"bat": Rect2(768, 0, 384, 512),
	"goblin": Rect2(1152, 0, 384, 512),
	"skeleton": Rect2(0, 512, 384, 512),
	"minotaur": Rect2(384, 512, 384, 512),
	"king": Rect2(768, 512, 768, 512)
}

const OBJECT_REGIONS := {
	"chest": Rect2(0, 0, 429, 458),
	"trap": Rect2(429, 0, 429, 458),
	"fountain": Rect2(858, 0, 429, 458),
	"stairs": Rect2(1287, 0, 430, 458),
	"shrine": Rect2(0, 458, 429, 458),
	"torch": Rect2(429, 458, 429, 458),
	"coin": Rect2(858, 458, 429, 458),
	"heart": Rect2(1287, 458, 430, 458)
}

const MAP_ICON_REGIONS := {
	"current": Rect2(0, 0, 362, 362),
	"enemy": Rect2(362, 0, 362, 362),
	"elite": Rect2(724, 0, 362, 362),
	"chest": Rect2(1086, 0, 362, 362),
	"trap": Rect2(0, 362, 362, 362),
	"fountain": Rect2(362, 362, 362, 362),
	"shop": Rect2(724, 362, 362, 362),
	"stairs": Rect2(1086, 362, 362, 362),
	"boss": Rect2(0, 724, 362, 362),
	"event": Rect2(362, 724, 362, 362),
	"merchant": Rect2(724, 724, 362, 362),
	"unknown": Rect2(1086, 724, 362, 362)
}

var game
var result_auto_timer := -1.0
var hint_was_visible := false

var background: TextureRect
var floor_scroll_a: TextureRect
var floor_scroll_b: TextureRect
var hero_sprite: Sprite2D
var event_sprite: Sprite2D
var enemy_sprite: Sprite2D
var torch_left: Sprite2D
var torch_right: Sprite2D
var hud_label: Label
var hint_label: Label
var message_label: Label
var action_box: VBoxContainer
var relic_label: Label
var map_panel: PanelContainer
var map_layer: Control
var map_line_layer: Control
var inventory_label: Label

var character_texture: Texture2D
var object_texture: Texture2D
var map_icon_texture: Texture2D
var item_icon_texture: Texture2D

func _ready() -> void:
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	game = GameStateScript.new()
	character_texture = _load_png_texture("res://assets/sprites/characters.png")
	object_texture = _load_png_texture("res://assets/sprites/objects.png")
	map_icon_texture = _load_png_texture("res://assets/sprites/map_icons.png")
	item_icon_texture = _load_png_texture("res://assets/sprites/item_icons.png")
	_build_scene()
	_refresh_all()

func _process(delta: float) -> void:
	_update_walk_animation(delta)
	if game.mode == game.MOVING:
		if game.should_show_hint() and not hint_was_visible:
			hint_was_visible = true
			hint_label.text = game.current_hint
		if game.tick(delta):
			hint_was_visible = false
			_refresh_all()
	elif game.mode == game.EVENT_RESULT and result_auto_timer > 0.0:
		result_auto_timer -= delta
		if result_auto_timer <= 0.0:
			game.finish_event()
			_refresh_all()

func _build_scene() -> void:
	custom_minimum_size = Vector2(540, 960)
	background = TextureRect.new()
	background.name = "DungeonBackground"
	background.texture = _load_png_texture("res://assets/backgrounds/dungeon_corridor.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var darken := ColorRect.new()
	darken.name = "DungeonVignette"
	darken.color = Color(0.03, 0.04, 0.08, 0.27)
	darken.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(darken)

	floor_scroll_a = _make_floor_strip("FloorScrollA", 0.0)
	floor_scroll_b = _make_floor_strip("FloorScrollB", -170.0)
	add_child(floor_scroll_a)
	add_child(floor_scroll_b)

	var world := Node2D.new()
	world.name = "World"
	add_child(world)

	torch_left = _make_object_sprite("torch", Vector2(74, 392), 0.34)
	torch_right = _make_object_sprite("torch", Vector2(466, 392), 0.34)
	torch_right.flip_h = true
	world.add_child(torch_left)
	world.add_child(torch_right)

	event_sprite = Sprite2D.new()
	event_sprite.name = "EventSprite"
	event_sprite.texture = object_texture
	event_sprite.centered = true
	event_sprite.region_enabled = true
	event_sprite.position = Vector2(270, 500)
	event_sprite.scale = Vector2(0.38, 0.38)
	world.add_child(event_sprite)

	enemy_sprite = Sprite2D.new()
	enemy_sprite.name = "EnemySprite"
	enemy_sprite.texture = character_texture
	enemy_sprite.centered = true
	enemy_sprite.region_enabled = true
	enemy_sprite.position = Vector2(270, 492)
	enemy_sprite.scale = Vector2(0.46, 0.46)
	world.add_child(enemy_sprite)

	hero_sprite = Sprite2D.new()
	hero_sprite.name = "HeroSprite"
	hero_sprite.texture = character_texture
	hero_sprite.centered = true
	hero_sprite.region_enabled = true
	hero_sprite.region_rect = CHARACTER_REGIONS.hero
	hero_sprite.position = Vector2(270, 653)
	hero_sprite.scale = Vector2(0.31, 0.31)
	world.add_child(hero_sprite)

	_build_ui()

func _build_ui() -> void:
	var top_panel := PanelContainer.new()
	top_panel.name = "Hud"
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 12
	top_panel.offset_top = 12
	top_panel.offset_right = -12
	top_panel.offset_bottom = 74
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.07, 0.11, 0.84), Color(0.88, 0.64, 0.22, 0.85)))
	add_child(top_panel)

	hud_label = Label.new()
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_label.add_theme_font_size_override("font_size", 18)
	top_panel.add_child(hud_label)

	map_panel = PanelContainer.new()
	map_panel.name = "MapPanel"
	map_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	map_panel.offset_left = 12
	map_panel.offset_top = 82
	map_panel.offset_right = -12
	map_panel.offset_bottom = 258
	map_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.04, 0.065, 0.84), Color(0.36, 0.58, 0.7, 0.7)))
	add_child(map_panel)

	map_layer = Control.new()
	map_layer.custom_minimum_size = Vector2(516, 176)
	map_panel.add_child(map_layer)
	map_line_layer = Control.new()
	map_line_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_line_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_layer.add_child(map_line_layer)

	hint_label = Label.new()
	hint_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint_label.offset_left = 18
	hint_label.offset_top = 264
	hint_label.offset_right = -18
	hint_label.offset_bottom = 314
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	add_child(hint_label)

	var bottom_panel := PanelContainer.new()
	bottom_panel.name = "MessagePanel"
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_left = 12
	bottom_panel.offset_top = -316
	bottom_panel.offset_right = -12
	bottom_panel.offset_bottom = -12
	bottom_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.045, 0.065, 0.92), Color(0.56, 0.42, 0.25, 0.9)))
	add_child(bottom_panel)

	var bottom_margin := MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 14)
	bottom_margin.add_theme_constant_override("margin_top", 10)
	bottom_margin.add_theme_constant_override("margin_right", 14)
	bottom_margin.add_theme_constant_override("margin_bottom", 10)
	bottom_panel.add_child(bottom_margin)

	var bottom_stack := VBoxContainer.new()
	bottom_stack.add_theme_constant_override("separation", 8)
	bottom_margin.add_child(bottom_stack)

	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(0, 68)
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.84))
	bottom_stack.add_child(message_label)

	inventory_label = Label.new()
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_label.custom_minimum_size = Vector2(0, 34)
	inventory_label.add_theme_font_size_override("font_size", 14)
	inventory_label.add_theme_color_override("font_color", Color(0.78, 0.9, 0.72))
	bottom_stack.add_child(inventory_label)

	action_box = VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 7)
	bottom_stack.add_child(action_box)

	relic_label = Label.new()
	relic_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	relic_label.offset_left = 18
	relic_label.offset_top = -354
	relic_label.offset_right = -18
	relic_label.offset_bottom = -324
	relic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_label.add_theme_font_size_override("font_size", 14)
	relic_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.48))
	add_child(relic_label)

func _refresh_all() -> void:
	hud_label.text = "B%dF  HP %d/%d  ATK %d  DEF %d  Gold %d  状態:%s" % [
		game.player.floor,
		game.player.hp,
		game.get_player_max_hp(),
		game.get_player_attack(),
		game.get_player_defense(),
		game.player.gold,
		game.get_status_summary()
	]
	message_label.text = game.current_message
	inventory_label.text = game.get_inventory_summary()
	hint_label.text = game.current_hint if game.mode == game.MAP_SELECT else ""
	hint_was_visible = false
	result_auto_timer = 1.8 if game.mode == game.EVENT_RESULT else -1.0
	_update_relics()
	_update_sprites()
	_rebuild_map()
	_rebuild_actions()

func _update_sprites() -> void:
	event_sprite.visible = false
	enemy_sprite.visible = false
	if game.mode == game.BATTLE or game.mode == game.CLEAR:
		var sprite_key := String(game.current_enemy.get("sprite", "king")) if game.mode == game.BATTLE else "king"
		enemy_sprite.region_rect = CHARACTER_REGIONS.get(sprite_key, CHARACTER_REGIONS.slime)
		enemy_sprite.scale = Vector2(0.49, 0.49) if sprite_key != "king" else Vector2(0.39, 0.39)
		enemy_sprite.visible = true
	elif game.visible_object != "":
		if OBJECT_REGIONS.has(game.visible_object):
			event_sprite.texture = object_texture
			event_sprite.region_rect = OBJECT_REGIONS[game.visible_object]
			event_sprite.scale = Vector2(0.44, 0.44) if game.visible_object != "coin" else Vector2(0.32, 0.32)
			event_sprite.visible = true
		elif MAP_ICON_REGIONS.has(game.visible_object):
			event_sprite.texture = map_icon_texture
			event_sprite.region_rect = MAP_ICON_REGIONS[game.visible_object]
			event_sprite.scale = Vector2(0.34, 0.34)
			event_sprite.visible = true

func _rebuild_map() -> void:
	for child in map_layer.get_children():
		if child != map_line_layer:
			child.queue_free()
	for child in map_line_layer.get_children():
		child.queue_free()

	if game.floor_map.is_empty():
		return
	var nodes: Array = game.floor_map.nodes
	for node in nodes:
		for link_id in node.links:
			var target := _find_node(nodes, int(link_id))
			if not target.is_empty():
				_add_map_line(_node_position(node), _node_position(target))
	for node in nodes:
		_add_map_node(node)

func _add_map_node(node: Dictionary) -> void:
	var button := TextureButton.new()
	var icon_key := _map_icon_key(node)
	button.texture_normal = _atlas(map_icon_texture, MAP_ICON_REGIONS[icon_key])
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(42, 42)
	button.size = Vector2(42, 42)
	button.position = _node_position(node) - Vector2(21, 21)
	button.modulate = Color.WHITE if bool(node.known) else Color(0.45, 0.45, 0.5, 0.75)
	if bool(node.resolved):
		button.modulate = Color(0.52, 0.58, 0.62, 0.7)
	var node_id := int(node.id)
	button.button_down.connect(func() -> void:
		button.set_meta("down_at", Time.get_ticks_msec())
	)
	button.button_up.connect(func() -> void:
		var down_at := int(button.get_meta("down_at", Time.get_ticks_msec()))
		if Time.get_ticks_msec() - down_at >= 650:
			game.inspect_map_node(node_id)
		else:
			game.move_to_node(node_id)
		_refresh_all()
	)
	map_layer.add_child(button)

func _add_map_line(from_pos: Vector2, to_pos: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.45, 0.62, 0.72, 0.55)
	line.points = PackedVector2Array([from_pos, to_pos])
	map_line_layer.add_child(line)

func _rebuild_actions() -> void:
	for child in action_box.get_children():
		child.queue_free()

	match game.mode:
		game.MAP_SELECT:
			_add_map_choice_buttons()
		game.MOVING:
			_add_disabled_status("移動中")
		game.BATTLE:
			_add_battle_actions()
		game.REWARD:
			_add_reward_actions()
		game.SHOP:
			_add_shop_actions()
		game.INSPECT:
			var ok := _make_button("OK")
			ok.pressed.connect(func() -> void:
				game.close_inspect()
				_refresh_all()
			)
			action_box.add_child(ok)
		game.EVENT_RESULT:
			var ok_button := _make_button("OK")
			ok_button.pressed.connect(func() -> void:
				game.finish_event()
				_refresh_all()
			)
			action_box.add_child(ok_button)
		game.GAME_OVER:
			var retry := _make_button("リトライ")
			retry.pressed.connect(func() -> void:
				game.reset()
				_refresh_all()
			)
			action_box.add_child(retry)
		game.CLEAR:
			var retry_clear := _make_button("もう一度")
			retry_clear.pressed.connect(func() -> void:
				game.reset()
				_refresh_all()
			)
			action_box.add_child(retry_clear)

func _add_map_choice_buttons() -> void:
	var nodes: Array[Dictionary] = game.get_available_nodes()
	if nodes.is_empty():
		_add_disabled_status("この階層は踏破済み")
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	action_box.add_child(row)
	for node in nodes:
		var button := _make_button(game.describe_node(node, false).replace("\n", " "))
		var node_id := int(node.id)
		button.button_down.connect(func() -> void:
			button.set_meta("down_at", Time.get_ticks_msec())
		)
		button.button_up.connect(func() -> void:
			var down_at := int(button.get_meta("down_at", Time.get_ticks_msec()))
			if Time.get_ticks_msec() - down_at >= 650:
				game.inspect_map_node(node_id)
			else:
				game.move_to_node(node_id)
			_refresh_all()
		)
		row.add_child(button)

func _add_battle_actions() -> void:
	var enemy_hp := int(game.current_enemy.hp)
	var max_hp := int(game.current_enemy.max_hp)
	_add_disabled_status("%s HP %d/%d" % [game.current_enemy.name, enemy_hp, max_hp])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	action_box.add_child(row)
	var attack_button := _make_button("攻撃")
	attack_button.pressed.connect(func() -> void:
		game.attack()
		_refresh_all()
	)
	attack_button.button_down.connect(func() -> void:
		attack_button.set_meta("down_at", Time.get_ticks_msec())
	)
	attack_button.button_up.connect(func() -> void:
		var down_at := int(attack_button.get_meta("down_at", Time.get_ticks_msec()))
		if Time.get_ticks_msec() - down_at >= 650:
			game.charge_attack()
			_refresh_all()
	)
	row.add_child(attack_button)
	for skill_id in ["power_strike", "guard", "first_aid"]:
		var skill := Skills.get_skill(skill_id)
		var cooldown := int(game.skill_cooldowns.get(skill_id, 0))
		var skill_button := _make_button("%s%s" % [skill.name, " CD%d" % cooldown if cooldown > 0 else ""])
		skill_button.pressed.connect(func() -> void:
			game.use_skill(skill_id)
			_refresh_all()
		)
		row.add_child(skill_button)
	_add_item_row()

func _add_item_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	action_box.add_child(row)
	for item_id in ["potion", "smoke_bomb", "antidote", "bomb"]:
		var amount := int(game.inventory.items.get(item_id, 0))
		var button := _make_button("%s x%d" % [Items.get_item(item_id).name, amount])
		button.disabled = amount <= 0
		button.pressed.connect(func() -> void:
			game.use_item(item_id)
			_refresh_all()
		)
		row.add_child(button)

func _add_reward_actions() -> void:
	for i in game.reward_options.size():
		var option: Dictionary = game.reward_options[i]
		var payload: Dictionary = option.payload
		var button := _make_button("%s\n%s" % [payload.name, payload.desc])
		button.pressed.connect(func() -> void:
			game.choose_relic(i)
			_refresh_all()
		)
		action_box.add_child(button)

func _add_shop_actions() -> void:
	for i in game.shop_stock.size():
		var item: Dictionary = game.shop_stock[i]
		var button := _make_button("%s %dG\n%s" % [item.name, item.price, item.desc])
		button.pressed.connect(func() -> void:
			game.buy_shop_item(i)
			_refresh_all()
		)
		action_box.add_child(button)
	var leave := _make_button("店を出る")
	leave.pressed.connect(func() -> void:
		game.leave_shop()
		_refresh_all()
	)
	action_box.add_child(leave)

func _update_relics() -> void:
	var names: Array[String] = game.get_relic_names()
	relic_label.text = "Relic: " + (" / ".join(names) if not names.is_empty() else "なし")

func _update_walk_animation(delta: float) -> void:
	if game.mode == game.MOVING:
		floor_scroll_a.position.y += 88.0 * delta
		floor_scroll_b.position.y += 88.0 * delta
		if floor_scroll_a.position.y > 170.0:
			floor_scroll_a.position.y = -170.0
		if floor_scroll_b.position.y > 170.0:
			floor_scroll_b.position.y = -170.0
		hero_sprite.position.y = 653.0 + sin(Time.get_ticks_msec() / 86.0) * 6.0
	else:
		hero_sprite.position.y = lerpf(hero_sprite.position.y, 653.0, 0.2)
	var flicker := 1.0 + sin(Time.get_ticks_msec() / 75.0) * 0.06
	torch_left.scale = Vector2(0.34 * flicker, 0.34 * flicker)
	torch_right.scale = Vector2(-0.34 * flicker, 0.34 * flicker)

func _make_floor_strip(node_name: String, y_offset: float) -> TextureRect:
	var strip := TextureRect.new()
	strip.name = node_name
	strip.texture = _load_png_texture("res://assets/backgrounds/dungeon_corridor.png")
	strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	strip.stretch_mode = TextureRect.STRETCH_TILE
	strip.modulate = Color(1.0, 0.86, 0.62, 0.13)
	strip.custom_minimum_size = Vector2(540, 180)
	strip.size = Vector2(540, 180)
	strip.position = Vector2(0, 494 + y_offset)
	return strip

func _make_object_sprite(region_key: String, position_value: Vector2, scale_value: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = object_texture
	sprite.centered = true
	sprite.region_enabled = true
	sprite.region_rect = OBJECT_REGIONS[region_key]
	sprite.position = position_value
	sprite.scale = Vector2(scale_value, scale_value)
	return sprite

func _make_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.98, 0.94, 0.82))
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.19, 0.12, 0.18, 0.95), Color(0.8, 0.54, 0.22, 0.92)))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.28, 0.16, 0.24, 0.98), Color(1.0, 0.72, 0.3, 1.0)))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.12, 0.08, 0.13, 0.98), Color(0.95, 0.44, 0.22, 1.0)))
	return button

func _add_disabled_status(text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.68, 0.82, 0.9))
	action_box.add_child(label)

func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_top = 7
	style.content_margin_right = 8
	style.content_margin_bottom = 7
	return style

func _load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	var result := image.load(path)
	if result != OK:
		push_error("画像を読み込めません: %s" % path)
		return PlaceholderTexture2D.new()
	return ImageTexture.create_from_image(image)

func _atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas

func _node_position(node: Dictionary) -> Vector2:
	return Vector2(34 + float(node.x) * 448.0, 18 + float(node.y) * 138.0)

func _find_node(nodes: Array, node_id: int) -> Dictionary:
	for node in nodes:
		if int(node.id) == node_id:
			return node
	return {}

func _map_icon_key(node: Dictionary) -> String:
	if int(node.id) == int(game.floor_map.current_id):
		return "current"
	if not bool(node.known):
		return "unknown"
	var type := String(node.type)
	return type if MAP_ICON_REGIONS.has(type) else "event"
