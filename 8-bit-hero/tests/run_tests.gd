extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const MapGeneratorScript = preload("res://scripts/map_generator.gd")

var failures := 0

func _initialize() -> void:
	_test_initial_state_and_map()
	_test_map_movement()
	_test_battle_win()
	_test_skill_and_status()
	_test_item_usage()
	_test_shop_purchase()
	_test_stairs_generate_next_map()
	_test_trap_game_over()
	_test_relic_effects()
	_test_clear_condition()
	if failures > 0:
		push_error("%d件のテストが失敗しました。" % failures)
		quit(1)
		return
	print("すべてのテストが成功しました。")
	quit()

func _test_initial_state_and_map() -> void:
	var game = GameStateScript.new(1)
	_assert(game.mode == game.MAP_SELECT, "初期状態はMAP_SELECT")
	_assert(game.player.hp == 22, "初期HP")
	_assert(game.player.floor == 1, "初期階層")
	_assert(not game.floor_map.is_empty(), "マップが生成される")
	_assert(game.get_available_nodes().size() > 0, "開始地点から進めるノードがある")

func _test_map_movement() -> void:
	var game = GameStateScript.new(2)
	var node := game.get_available_nodes()[0]
	game.move_to_node(int(node.id))
	_assert(game.mode == game.MOVING, "移動開始でMOVING")
	game.tick(1.0)
	_assert(int(game.floor_map.current_id) == int(node.id), "目的ノードへ移動する")
	_assert(game.mode != game.MOVING, "到着後はイベントへ進む")

func _test_battle_win() -> void:
	var game = GameStateScript.new(3)
	game.start_battle("slime")
	game.attack()
	game.attack()
	_assert(game.mode == game.EVENT_RESULT, "敵撃破後はEVENT_RESULT")
	_assert(game.player.gold >= 2, "撃破報酬を得る")

func _test_skill_and_status() -> void:
	var game = GameStateScript.new(4)
	game.start_battle("goblin")
	game.use_skill("guard")
	_assert(int(game.player.statuses.get("shield", 0)) > 0, "防御で盾を得る")
	game.use_skill("power_strike")
	_assert(int(game.skill_cooldowns.get("power_strike", 0)) >= 0, "強撃のクールダウンを管理する")

func _test_item_usage() -> void:
	var game = GameStateScript.new(5)
	game.player.hp = 5
	game.use_item("potion")
	_assert(game.player.hp == 17, "ポーションでHP回復")
	_assert(int(game.inventory.items.potion) == 0, "アイテム数が減る")

func _test_shop_purchase() -> void:
	var game = GameStateScript.new(6)
	game.player.gold = 100
	game.start_shop()
	var before := int(game.player.gold)
	game.buy_shop_item(0)
	_assert(game.player.gold < before, "購入でGoldが減る")

func _test_stairs_generate_next_map() -> void:
	var game = GameStateScript.new(10)
	game.player.relics.append("coward_shield")
	var old_map: Dictionary = game.floor_map
	game.trigger_stairs()
	_assert(game.player.floor == 2, "階段で次階層へ進む")
	_assert(game.floor_map != old_map, "次階層のマップを生成する")
	_assert(game.get_available_nodes().size() > 0, "次階層にも進めるノードがある")

func _test_trap_game_over() -> void:
	var game = GameStateScript.new(7)
	game.player.hp = 2
	game.trigger_trap()
	_assert(game.mode == game.GAME_OVER, "罠でHP0ならGAME_OVER")

func _test_relic_effects() -> void:
	var game = GameStateScript.new(8)
	game.player.relics.append("thick_cloak")
	game.player.hp = 22
	game.trigger_trap()
	_assert(game.player.hp == 18, "厚いマントで罠ダメージ軽減")
	game.player.relics.append("fountain_cup")
	game.player.hp = 1
	game.trigger_fountain()
	_assert(game.player.hp == 17, "泉の杯で回復量増加")

func _test_clear_condition() -> void:
	var game = GameStateScript.new(9)
	game.start_battle("king")
	game.current_enemy.hp = 1
	game.attack()
	_assert(game.mode == game.CLEAR, "ボス撃破でCLEAR")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
