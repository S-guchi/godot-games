extends SceneTree

func _initialize() -> void:
	var scene := load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main.tscn が見つかりません")
		quit(1)
		return
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	if main.player.is_empty():
		push_error("固定プレイヤーが初期化されていません")
		quit(1)
		return
	if main.enemies.size() != 7:
		push_error("MVP敵データが7体ではありません")
		quit(1)
		return
	if main.tap_button.text != "ぺちっ！":
		push_error("バトルボタンがMVP仕様ではありません")
		quit(1)
		return

	main.current_enemy_hp = 1
	await main._battle_turn()
	if main.discovered_enemy_ids.is_empty():
		push_error("敵撃破後に図鑑登録されません")
		quit(1)
		return
	if main.best_defeated_count < 1 or main.total_defeated_count < 1:
		push_error("撃破後に記録が更新されません")
		quit(1)
		return

	while main.defeated_count < 3:
		main.current_enemy_hp = 1
		await main._battle_turn()
	if not main.pending_upgrade or main.pending_upgrades.size() != 3:
		push_error("3体撃破後に3択強化が出ません")
		quit(1)
		return
	main._choose_upgrade(main.pending_upgrades[0])
	if main.pending_upgrade:
		push_error("強化選択後にバトルへ戻りません")
		quit(1)
		return

	main.player.hp = 1
	main.current_enemy_hp = int(main.current_enemy.hp)
	main.current_enemy.attack = 999
	await main._battle_turn()
	if not main.is_game_over:
		push_error("HP0でゲームオーバーになりません")
		quit(1)
		return

	main._show_tab("dex")
	await process_frame
	main._show_tab("records")
	await process_frame
	main._show_tab("settings")
	await process_frame
	main._reset_save()
	if main.best_defeated_count != 0 or main.total_defeated_count != 0 or not main.discovered_enemy_ids.is_empty():
		push_error("記録リセットが保存状態を初期化しません")
		quit(1)
		return
	print("SMOKE TEST OK")
	quit()
