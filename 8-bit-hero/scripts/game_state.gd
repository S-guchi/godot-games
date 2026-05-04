extends RefCounted
class_name GameState

const Enemies = preload("res://data/enemies.gd")
const Relics = preload("res://data/relics.gd")
const Equipment = preload("res://data/equipment.gd")
const Items = preload("res://data/items.gd")
const Skills = preload("res://data/skills.gd")
const Shops = preload("res://data/shops.gd")
const MapGeneratorScript = preload("res://scripts/map_generator.gd")
const InventoryManagerScript = preload("res://scripts/inventory_manager.gd")
const CombatManagerScript = preload("res://scripts/combat_manager.gd")

const MAP_SELECT := "MAP_SELECT"
const MOVING := "MOVING"
const BATTLE := "BATTLE"
const REWARD := "REWARD"
const EVENT_RESULT := "EVENT_RESULT"
const SHOP := "SHOP"
const INVENTORY := "INVENTORY"
const INSPECT := "INSPECT"
const GAME_OVER := "GAME_OVER"
const CLEAR := "CLEAR"

# 旧テストや既存UIとの互換用。探索待機はMAP_SELECTへ集約する。
const AUTO_WALK := MAP_SELECT
const BRANCH := MAP_SELECT

var rng := RandomNumberGenerator.new()
var mode := MAP_SELECT
var previous_mode := MAP_SELECT
var player := {}
var inventory := {}
var skills: Array[String] = []
var skill_cooldowns := {}
var floor_map := {}
var moving_timer := 0.0
var destination_node_id := -1
var current_hint := ""
var current_message := ""
var current_enemy := {}
var reward_options: Array[Dictionary] = []
var shop_stock: Array[Dictionary] = []
var inspect_node := {}
var visible_object := ""

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	reset()

func reset() -> void:
	inventory = InventoryManagerScript.create_inventory()
	skills = Skills.default_skills()
	skill_cooldowns = {}
	for skill_id in skills:
		skill_cooldowns[skill_id] = 0
	player = {
		"base_max_hp": 22,
		"hp": 22,
		"base_atk": 4,
		"base_def": 0,
		"gold": 0,
		"key": 0,
		"floor": 1,
		"relics": [],
		"statuses": {}
	}
	current_enemy = {}
	reward_options.clear()
	shop_stock.clear()
	visible_object = ""
	_generate_floor(1)
	mode = MAP_SELECT
	current_message = "自動生成された地図を見ながら進む道を選ぼう。"
	current_hint = "長押しで部屋の気配を詳しく調べられる。"

func get_player_max_hp() -> int:
	return int(player.base_max_hp) + int(InventoryManagerScript.equipment_bonus(inventory).max_hp)

func get_player_attack() -> int:
	var value := int(player.base_atk) + int(InventoryManagerScript.equipment_bonus(inventory).atk)
	if has_relic("cursed_crown") and int(player.hp) * 2 <= get_player_max_hp():
		value += 4
	if has_relic("gold_dagger"):
		value += int(player.gold) / 10
	return CombatManagerScript.attack_damage(value, player)

func get_player_defense() -> int:
	return int(player.base_def) + int(InventoryManagerScript.equipment_bonus(inventory).def)

func get_relic_names() -> Array[String]:
	var names: Array[String] = []
	for relic_id in player.relics:
		names.append(Relics.get_relic(relic_id).name)
	return names

func has_relic(relic_id: String) -> bool:
	return player.relics.has(relic_id)

func get_available_nodes() -> Array[Dictionary]:
	return MapGeneratorScript.get_available_nodes(floor_map)

func start_auto_walk(message := "") -> void:
	mode = MAP_SELECT
	current_message = message if message != "" else "地図から次の部屋を選ぼう。"
	current_hint = "隣接する部屋だけ選べる。"
	visible_object = ""

func tick(delta: float) -> bool:
	if mode != MOVING:
		return false
	moving_timer -= delta
	if moving_timer <= 0.0:
		_arrive_at_destination()
		return true
	return false

func should_show_hint() -> bool:
	return mode == MOVING and moving_timer <= 0.4

func move_to_node(node_id: int) -> void:
	if mode != MAP_SELECT:
		return
	var allowed := false
	for node in get_available_nodes():
		if int(node.id) == node_id:
			allowed = true
			break
	if not allowed:
		current_message = "その部屋へはまだ進めない。"
		return
	destination_node_id = node_id
	mode = MOVING
	moving_timer = 0.8
	current_hint = describe_node(MapGeneratorScript.get_node(floor_map, node_id), false)
	current_message = "通路を進んでいる……"
	visible_object = ""

func inspect_map_node(node_id: int) -> void:
	var node := MapGeneratorScript.get_node(floor_map, node_id)
	if node.is_empty():
		return
	previous_mode = mode
	mode = INSPECT
	inspect_node = node
	current_message = describe_node(node, true)
	current_hint = "OKで戻る。"

func close_inspect() -> void:
	mode = previous_mode
	current_message = "地図から次の部屋を選ぼう。"

func trigger_event(forced_type := "") -> void:
	if forced_type == "":
		var node := MapGeneratorScript.get_node(floor_map, int(floor_map.current_id))
		_resolve_node(node)
	else:
		_resolve_node({"type": forced_type})

func start_battle(enemy_id: String, elite := false) -> void:
	mode = BATTLE
	current_enemy = Enemies.get_enemy(enemy_id)
	current_enemy["id"] = enemy_id
	current_enemy["max_hp"] = int(current_enemy.hp)
	current_enemy["statuses"] = {}
	if elite:
		current_enemy.name = "強敵 " + String(current_enemy.name)
		current_enemy.hp = int(current_enemy.hp) + 8
		current_enemy.max_hp = int(current_enemy.max_hp) + 8
		current_enemy.atk = int(current_enemy.atk) + 2
		current_enemy.gold = int(current_enemy.gold) + 5
	visible_object = current_enemy.sprite
	current_message = "%sが現れた！" % current_enemy.name

func attack() -> void:
	if mode != BATTLE:
		return
	_player_deal_damage(get_player_attack(), "勇者の攻撃")

func charge_attack() -> void:
	if mode != BATTLE:
		return
	if int(skill_cooldowns.get("charged_attack", 0)) > 0:
		current_message = "溜め攻撃はまだ使えない。"
		return
	skill_cooldowns["charged_attack"] = Skills.get_skill("charged_attack").cooldown
	_player_deal_damage(get_player_attack() + 10, "溜め攻撃")

func use_skill(skill_id: String) -> void:
	if mode != BATTLE:
		return
	if int(skill_cooldowns.get(skill_id, 0)) > 0:
		current_message = "%sはまだ使えない。" % Skills.get_skill(skill_id).name
		return
	match skill_id:
		"power_strike":
			skill_cooldowns[skill_id] = Skills.get_skill(skill_id).cooldown
			_player_deal_damage(get_player_attack() + 5, "強撃")
		"guard":
			skill_cooldowns[skill_id] = Skills.get_skill(skill_id).cooldown
			CombatManagerScript.add_status(player, "shield", 2)
			current_message = "防御態勢を取った。盾を得た。"
			_enemy_turn()
		"first_aid":
			skill_cooldowns[skill_id] = Skills.get_skill(skill_id).cooldown
			player.hp = min(get_player_max_hp(), int(player.hp) + 8)
			current_message = "応急手当でHP+8。"
			_enemy_turn()
		"charged_attack":
			charge_attack()

func use_item(item_id: String) -> void:
	if not InventoryManagerScript.use_item(inventory, item_id):
		current_message = "そのアイテムは持っていない。"
		return
	match item_id:
		"potion":
			player.hp = min(get_player_max_hp(), int(player.hp) + 12)
			current_message = "ポーションを使った。HP+12。"
			if mode == BATTLE:
				_enemy_turn()
		"smoke_bomb":
			if mode == BATTLE:
				current_message = "煙玉で戦闘から離脱した。"
				_finish_node_after_event()
			else:
				current_message = "今は煙玉を使う場面ではない。"
				InventoryManagerScript.add_item(inventory, item_id, 1)
		"antidote":
			player.statuses["poison"] = 0
			player.statuses["burn"] = 0
			current_message = "解毒薬で毒と火傷を治した。"
			if mode == BATTLE:
				_enemy_turn()
		"bomb":
			if mode == BATTLE:
				_player_deal_damage(18, "爆弾")
			else:
				current_message = "今は爆弾を使う場面ではない。"
				InventoryManagerScript.add_item(inventory, item_id, 1)

func start_chest() -> void:
	mode = REWARD
	visible_object = "chest"
	reward_options.clear()
	reward_options.append({"kind": "relic", "payload": Relics.roll_options(player.relics, rng, 1)[0]})
	reward_options.append({"kind": "equipment", "payload": Equipment.roll_equipment(rng, int(player.floor))})
	reward_options.append({"kind": "item", "payload": Items.roll_item(rng)})
	if has_relic("thief_key"):
		player.gold += 5
		player.key += 1
	current_message = "宝箱を見つけた！ 報酬を選ぼう。"

func choose_relic(index: int) -> void:
	if mode != REWARD or index < 0 or index >= reward_options.size():
		return
	var option := reward_options[index]
	var payload: Dictionary = option.payload
	match String(option.kind):
		"relic":
			player.relics.append(payload.id)
			if payload.id == "life_ring":
				player.base_max_hp += 6
				player.hp += 6
			current_message = "%sを手に入れた。\n%s" % [payload.name, payload.desc]
		"equipment":
			InventoryManagerScript.add_equipment(inventory, payload.id)
			InventoryManagerScript.equip(inventory, payload.id)
			player.hp = min(get_player_max_hp(), int(player.hp) + int(payload.max_hp))
			current_message = "%sを装備した。\n%s" % [payload.name, payload.desc]
		"item":
			InventoryManagerScript.add_item(inventory, payload.id, 1)
			current_message = "%sを手に入れた。\n%s" % [payload.name, payload.desc]
	mode = EVENT_RESULT
	visible_object = String(payload.get("icon", "chest"))
	_finish_node_after_event(false)

func trigger_trap() -> void:
	mode = EVENT_RESULT
	visible_object = "trap"
	var damage := 7
	if has_relic("thick_cloak"):
		damage = max(1, damage - 3)
	damage = CombatManagerScript.incoming_damage(damage, player)
	player.hp = max(0, int(player.hp) - damage)
	if has_relic("trap_boots"):
		player.base_atk += 1
		current_message = "罠を踏んだ！ HP-%d。\n罠師の靴でATK+1。" % damage
	else:
		current_message = "罠を踏んだ！ HP-%d。" % damage
	if rng.randf() < 0.35:
		CombatManagerScript.add_status(player, "poison", 3)
		current_message += "\n毒を受けた。"
	if player.hp <= 0:
		game_over()
	else:
		_finish_node_after_event(false)

func trigger_fountain() -> void:
	mode = EVENT_RESULT
	visible_object = "fountain"
	var heal := 11
	if has_relic("fountain_cup"):
		heal += 5
	player.hp = min(get_player_max_hp(), int(player.hp) + heal)
	player.statuses["poison"] = 0
	player.statuses["burn"] = 0
	current_message = "回復の泉を見つけた。\nHP+%d。毒と火傷も癒えた。" % heal
	_finish_node_after_event(false)

func trigger_stairs() -> void:
	mode = EVENT_RESULT
	visible_object = "stairs"
	if int(player.floor) >= 5:
		start_battle("king")
		return
	player.floor += 1
	if has_relic("coward_shield"):
		player.base_def += 1
		current_message = "階段を見つけた。\nB%dFへ降りた。DEF+1。" % player.floor
	else:
		current_message = "階段を見つけた。\nB%dFへ降りた。" % player.floor
	_generate_floor(int(player.floor))

func start_shop() -> void:
	mode = SHOP
	visible_object = "shop"
	shop_stock = Shops.roll_stock(rng, int(player.floor))
	current_message = "旅商人が小さな店を開いている。"

func buy_shop_item(index: int) -> void:
	if mode != SHOP or index < 0 or index >= shop_stock.size():
		return
	var item := shop_stock[index]
	var price := int(item.price)
	if int(player.gold) < price:
		current_message = "コインが足りない。"
		return
	player.gold -= price
	match String(item.type):
		"item":
			InventoryManagerScript.add_item(inventory, item.id, 1)
			current_message = "%sを買った。" % item.name
		"equipment":
			InventoryManagerScript.add_equipment(inventory, item.id)
			InventoryManagerScript.equip(inventory, item.id)
			current_message = "%sを買って装備した。" % item.name
		"service":
			player.hp = get_player_max_hp()
			current_message = "休憩してHPを全回復した。"

func leave_shop() -> void:
	if mode == SHOP:
		_finish_node_after_event()

func finish_event() -> void:
	if mode == GAME_OVER or mode == CLEAR:
		return
	if player.hp <= 0:
		game_over()
		return
	mode = MAP_SELECT
	current_message = "地図から次の部屋を選ぼう。"
	current_hint = "長押しで部屋の気配を詳しく調べられる。"
	visible_object = ""

func game_over() -> void:
	mode = GAME_OVER
	visible_object = ""
	current_message = "力尽きた……"

func describe_node(node: Dictionary, detailed := false) -> String:
	if node.is_empty():
		return "何も見えない。"
	var type := String(node.type)
	var hint := _hint_for_event(type)
	if has_relic("scout_map") or detailed:
		return "%s\n予想: %s" % [hint, _node_type_name(type)]
	return hint

func get_status_summary() -> String:
	var names: Array[String] = []
	for status_id in player.statuses.keys():
		if int(player.statuses[status_id]) > 0:
			names.append("%s%d" % [status_id, int(player.statuses[status_id])])
	return " / ".join(names) if not names.is_empty() else "なし"

func get_inventory_summary() -> String:
	return "装備: %s\n道具: %s" % [
		InventoryManagerScript.equipment_summary(inventory),
		InventoryManagerScript.item_summary(inventory)
	]

func _generate_floor(floor: int) -> void:
	floor_map = MapGeneratorScript.generate_floor(floor, rng)
	MapGeneratorScript.mark_reachable_known(floor_map)

func _arrive_at_destination() -> void:
	var node := MapGeneratorScript.move_to(floor_map, destination_node_id)
	destination_node_id = -1
	_resolve_node(node)

func _resolve_node(node: Dictionary) -> void:
	if node.is_empty():
		mode = MAP_SELECT
		return
	match String(node.type):
		"start":
			_finish_node_after_event()
		"enemy":
			start_battle(Enemies.roll_enemy_id(int(player.floor), rng))
		"elite":
			start_battle(Enemies.roll_enemy_id(int(player.floor) + 1, rng), true)
		"chest":
			start_chest()
		"trap":
			trigger_trap()
		"fountain":
			trigger_fountain()
		"shop":
			start_shop()
		"stairs":
			trigger_stairs()
		"boss":
			start_battle("king")
		"event":
			_resolve_random_event()
		_:
			_finish_node_after_event()

func _resolve_random_event() -> void:
	mode = EVENT_RESULT
	visible_object = "shrine"
	var roll := rng.randf()
	if roll < 0.34:
		player.gold += 6
		current_message = "古い祠からコインを見つけた。Gold+6。"
	elif roll < 0.67:
		CombatManagerScript.add_status(player, "shield", 2)
		current_message = "祠の加護で盾を得た。"
	else:
		CombatManagerScript.add_status(player, "weaken", 2)
		current_message = "呪いの霧を浴びた。弱体を受けた。"
	_finish_node_after_event(false)

func _player_deal_damage(damage: int, label: String) -> void:
	current_enemy.hp = max(0, int(current_enemy.hp) - damage)
	current_message = "%s！ %dダメージ。" % [label, damage]
	if current_enemy.hp <= 0:
		_finish_enemy()
		return
	if rng.randf() < 0.18:
		CombatManagerScript.add_status(current_enemy, "burn", 2)
		current_message += "\n敵が火傷を負った。"
	_enemy_turn()

func _enemy_turn() -> void:
	if mode != BATTLE:
		return
	var status_message := CombatManagerScript.tick_status(current_enemy)
	if status_message != "":
		current_message += "\n" + status_message
	if current_enemy.hp <= 0:
		_finish_enemy()
		return
	if CombatManagerScript.has_status(current_enemy, "stun"):
		current_message += "\n%sは動けない。" % current_enemy.name
		_decrement_cooldowns()
		return
	var raw_damage: int = max(1, int(current_enemy.atk) - get_player_defense())
	var enemy_damage := CombatManagerScript.incoming_damage(raw_damage, player)
	player.hp = max(0, int(player.hp) - enemy_damage)
	current_message += "\n%sの反撃！ HP-%d。" % [current_enemy.name, enemy_damage]
	if rng.randf() < 0.14:
		CombatManagerScript.add_status(player, "poison", 3)
		current_message += "\n毒を受けた。"
	var player_status_message := CombatManagerScript.tick_status(player)
	if player_status_message != "":
		current_message += "\n" + player_status_message
	_decrement_cooldowns()
	if player.hp <= 0:
		game_over()

func _decrement_cooldowns() -> void:
	for skill_id in skill_cooldowns.keys():
		skill_cooldowns[skill_id] = max(0, int(skill_cooldowns[skill_id]) - 1)

func _finish_enemy() -> void:
	if current_enemy.id == "king":
		mode = CLEAR
		visible_object = "king"
		current_message = "ダンジョンの王を倒した！\n最深部を踏破した。"
		MapGeneratorScript.resolve_current(floor_map)
		return
	player.gold += int(current_enemy.gold)
	if has_relic("vampire_sword"):
		player.hp = min(get_player_max_hp(), int(player.hp) + 2)
		current_message = "%sを倒した！ コイン+%d。\n吸血剣でHP+2。" % [current_enemy.name, current_enemy.gold]
	else:
		current_message = "%sを倒した！ コイン+%d。" % [current_enemy.name, current_enemy.gold]
	mode = EVENT_RESULT
	visible_object = "coin"
	_finish_node_after_event(false)

func _finish_node_after_event(go_map := true) -> void:
	MapGeneratorScript.resolve_current(floor_map)
	if go_map:
		finish_event()

func _hint_for_event(event_type: String) -> String:
	match event_type:
		"enemy":
			return "獣の匂いがする……"
		"elite":
			return "重い足音が響く……"
		"chest":
			return "金属音が聞こえる……"
		"trap":
			return "床がきしむ……"
		"fountain":
			return "水音がする……"
		"shop":
			return "灯りと人の気配がある……"
		"stairs":
			return "冷たい風が下から吹く……"
		"boss":
			return "玉座から魔力があふれている……"
		"event":
			return "不思議な魔力を感じる……"
		_:
			return "通路が続いている……"

func _node_type_name(event_type: String) -> String:
	match event_type:
		"enemy":
			return "敵"
		"elite":
			return "強敵"
		"chest":
			return "宝箱"
		"trap":
			return "罠"
		"fountain":
			return "泉"
		"shop":
			return "店"
		"stairs":
			return "階段"
		"boss":
			return "ボス"
		"event":
			return "イベント"
		"start":
			return "現在地"
		_:
			return "未探索"
