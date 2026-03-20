extends SceneTree

## SwipeQuest headless test runner (v0.3)
## 実行: godot --headless --path <PROJECT_DIR> --script res://tests/run_tests.gd

const CardDataScript = preload("res://scripts/card_data.gd")
const GameManagerScript = preload("res://scripts/game_manager.gd")

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	print("=== SwipeQuest Test Runner (v0.3) ===")
	print("")

	test_card_data_loading()
	test_card_data_structure()
	test_game_manager_init()
	test_game_manager_draw_card()
	test_game_manager_resolve_card()
	test_game_manager_flags()
	test_game_manager_context_decay()
	test_game_manager_requires_flags()
	test_game_manager_crisis_hidden_when_healthy()
	test_game_manager_crisis_appears_when_depleted()
	test_game_manager_low_stat_boosts_recovery_weight()
	test_game_manager_combat_wolves_route()
	test_game_manager_final_requires_final_card()
	test_game_manager_final_progression_requires_gate_then_trial_then_sacrifice()
	test_game_manager_final_arrival_wins()
	test_game_manager_day_zero_loses()

	print("")
	print("=== Results: %d passed, %d failed ===" % [_pass_count, _fail_count])

	if _fail_count > 0:
		quit(1)
	else:
		quit(0)


func assert_true(condition: bool, desc: String) -> void:
	if condition:
		_pass_count += 1
		print("  PASS: %s" % desc)
	else:
		_fail_count += 1
		print("  FAIL: %s" % desc)


func assert_eq(a, b, desc: String) -> void:
	if a == b:
		_pass_count += 1
		print("  PASS: %s" % desc)
	else:
		_fail_count += 1
		print("  FAIL: %s (got %s, expected %s)" % [desc, str(a), str(b)])


func test_card_data_loading() -> void:
	print("[test_card_data_loading]")
	var cards = CardDataScript.load_all()
	assert_true(cards.size() > 0, "Cards loaded from JSON")
	assert_true(cards.size() >= 10, "At least 10 cards exist")

	var first = cards[0]
	assert_true(first.id != "", "First card has an id")
	assert_true(first.text != "", "First card has text")
	assert_true(first.right_text != "", "First card has right_text")
	assert_true(first.left_text != "", "First card has left_text")


func test_card_data_structure() -> void:
	print("[test_card_data_structure]")
	var cards = CardDataScript.load_all()

	var has_mind := false
	var has_body := false
	var has_money := false
	var has_goal_progress := false
	var has_required_flags := false
	var has_forbidden_flags := false
	var has_crisis_cards := false
	var crisis_has_game_over := false
	var crisis_has_conditions := false
	var has_combat_entry := false
	var has_combat_finish := false
	var has_final_gate := false

	for card in cards:
		for eff in [card.left_effects, card.right_effects]:
			if eff.has("mind"):
				has_mind = true
			if eff.has("body"):
				has_body = true
			if eff.has("money"):
				has_money = true
			if eff.has("goal_progress"):
				has_goal_progress = true
			if eff.get("next_deck", "") == "combat_wolves" and card.id == "wolf_tracks":
				has_combat_entry = true
			if eff.get("next_deck", "") == "normal" and card.id == "combat_wolves_finish":
				has_combat_finish = true

		if card.conditions.get("required_flags", []).size() > 0:
			has_required_flags = true
		if card.conditions.get("forbidden_flags", []).size() > 0:
			has_forbidden_flags = true
		if card.id.begins_with("crisis_"):
			has_crisis_cards = true
			for eff in [card.left_effects, card.right_effects]:
				if eff.has("game_over"):
					crisis_has_game_over = true
			var cond = card.conditions
			if cond.has("mind_range") or cond.has("body_range") or cond.has("money_range"):
				crisis_has_conditions = true
		if card.id == "final_gate":
			has_final_gate = true

	assert_true(has_mind, "Some cards affect mind")
	assert_true(has_body, "Some cards affect body")
	assert_true(has_money, "Some cards affect money")
	assert_true(has_goal_progress, "Some cards affect goal_progress")
	assert_true(has_required_flags, "Some cards have required_flags")
	assert_true(has_forbidden_flags, "Some cards have forbidden_flags")
	assert_true(has_crisis_cards, "Crisis cards exist (crisis_ prefix)")
	assert_true(crisis_has_game_over, "Crisis cards have game_over effects")
	assert_true(crisis_has_conditions, "Crisis cards have stat range conditions")
	assert_true(has_combat_entry, "combat_wolves entry card exists")
	assert_true(has_combat_finish, "combat_wolves exit card exists")
	assert_true(has_final_gate, "final_gate exists")


func test_game_manager_init() -> void:
	print("[test_game_manager_init]")
	var gm := _create_game_manager()
	assert_eq(gm.mind, 5, "Initial mind is 5")
	assert_eq(gm.body, 5, "Initial body is 5")
	assert_eq(gm.money, 5, "Initial money is 5")
	assert_eq(gm.days_remaining, 20, "Initial days_remaining is 20")
	assert_eq(gm.goal_progress, 0, "Initial goal_progress is 0")
	assert_eq(gm.score, 0, "Initial score is 0")
	assert_true(not gm.is_game_over, "Game is not over at start")
	assert_eq(gm.deck_mode, "normal", "Deck mode is normal")
	gm.free()


func test_game_manager_draw_card() -> void:
	print("[test_game_manager_draw_card]")
	var gm := _create_game_manager()
	var card = gm.draw_card()
	assert_true(card != null, "draw_card returns a card")
	assert_true(card.id != "", "Drawn card has an id")
	assert_true(card.text != "", "Drawn card has text")
	gm.free()


func test_game_manager_resolve_card() -> void:
	print("[test_game_manager_resolve_card]")
	var gm := _create_game_manager()
	var card = _make_test_card({
		"id": "test_resolve",
		"right_effects": {"body": -2, "money": 3, "goal_progress": 1},
		"left_effects": {"mind": -1},
	})

	var prev_body = gm.body
	var prev_money = gm.money
	gm.resolve_card(card, "right")

	assert_eq(gm.body, prev_body - 2, "Body decreased by 2")
	assert_eq(gm.money, prev_money + 3, "Money increased by 3")
	assert_eq(gm.goal_progress, 1, "Goal progress increased by 1")
	assert_eq(gm.score, 1, "Score incremented")
	assert_eq(gm.days_remaining, 19, "Days decreased by 1")
	gm.free()


func test_game_manager_flags() -> void:
	print("[test_game_manager_flags]")
	var gm := _create_game_manager()

	var card = _make_test_card({
		"id": "flag_test",
		"right_effects": {"set_flags": ["test_flag", "another_flag"]},
		"left_effects": {"unset_flags": ["test_flag"]},
	})

	gm.resolve_card(card, "right")
	assert_true(gm.flags.get("test_flag", false), "Flag set after right swipe")
	assert_true(gm.flags.get("another_flag", false), "Second flag also set")

	var card2 = _make_test_card({
		"id": "flag_test2",
		"left_effects": {"unset_flags": ["test_flag"]},
	})
	gm.resolve_card(card2, "left")
	assert_true(not gm.flags.get("test_flag", false), "Flag unset after left swipe")
	assert_true(gm.flags.get("another_flag", false), "Other flag still set")
	gm.free()


func test_game_manager_context_decay() -> void:
	print("[test_game_manager_context_decay]")
	var gm := _create_game_manager()

	var card = _make_test_card({
		"id": "ctx_test",
		"tags": ["forest"],
		"right_effects": {"context_shift": {"forest": 3}},
	})
	gm.resolve_card(card, "right")
	var forest_val: float = gm.context.get("forest", 0.0)
	assert_true(forest_val > 0, "Forest context is positive after card")

	var card2 = _make_test_card({"id": "ctx_test2"})
	gm.resolve_card(card2, "right")
	var forest_val2: float = gm.context.get("forest", 0.0)
	assert_true(forest_val2 < forest_val, "Forest context decayed after another card")
	gm.free()


func test_game_manager_requires_flags() -> void:
	print("[test_game_manager_requires_flags]")
	var gm := _create_game_manager()

	assert_true(not gm._passes_hard_filter(_find_card("wolf_tracks")), "wolf_tracks hidden without entered_forest")
	gm.flags["entered_forest"] = true
	assert_true(gm._passes_hard_filter(_find_card("wolf_tracks")), "wolf_tracks appears after entered_forest")
	gm.free()


func test_game_manager_crisis_hidden_when_healthy() -> void:
	print("[test_game_manager_crisis_hidden_when_healthy]")
	var gm := _create_game_manager()
	assert_true(not gm._passes_hard_filter(_find_card("crisis_mind_abyss")), "Mind crisis is hidden (mind_range condition) while mind is healthy")
	assert_true(not gm._passes_hard_filter(_find_card("crisis_body_collapse")), "Body crisis is hidden (body_range condition) while body is healthy")
	assert_true(not gm._passes_hard_filter(_find_card("crisis_money_ruin")), "Money crisis is hidden (money_range condition) while money is healthy")
	gm.free()


func test_game_manager_crisis_appears_when_depleted() -> void:
	print("[test_game_manager_crisis_appears_when_depleted]")
	var gm := _create_game_manager()
	gm.body = 0
	assert_true(gm._passes_hard_filter(_find_card("crisis_body_collapse")), "Body crisis appears when body is depleted (body_range satisfied)")
	assert_true(not gm._passes_hard_filter(_find_card("crisis_mind_abyss")), "Mind crisis stays hidden when only body is depleted (mind_range unsatisfied)")
	gm.free()


func test_game_manager_low_stat_boosts_recovery_weight() -> void:
	print("[test_game_manager_low_stat_boosts_recovery_weight]")
	var gm := _create_game_manager()
	# campfire_rest has body +2 in left_effects
	var recovery = _find_card("campfire_rest")
	var normal_weight = gm._state_weight(recovery, gm.get_depletion_count())

	gm.body = 1
	var low_weight = gm._state_weight(recovery, gm.get_depletion_count())

	assert_true(low_weight > normal_weight, "Recovery card weight increases when corresponding stat is low")
	gm.free()


func test_game_manager_combat_wolves_route() -> void:
	print("[test_game_manager_combat_wolves_route]")
	var gm := _create_game_manager()
	gm.flags["entered_forest"] = true

	var entry = _find_card("wolf_tracks")
	gm.resolve_card(entry, "right")
	assert_eq(gm.deck_mode, "combat_wolves", "Entry card switches to combat_wolves")

	var start = gm.draw_card()
	assert_eq(start.id, "combat_wolves_start", "combat_wolves_start is drawn inside local deck")
	gm.resolve_card(start, "left")

	var finish = gm.draw_card()
	assert_eq(finish.id, "combat_wolves_finish", "combat_wolves_finish follows the start card")
	gm.resolve_card(finish, "right")
	assert_eq(gm.deck_mode, "normal", "Combat finish returns to normal deck")
	gm.free()


func test_game_manager_final_requires_final_card() -> void:
	print("[test_game_manager_final_requires_final_card]")
	var gm := _create_game_manager()
	var card = _make_test_card({
		"id": "almost_goal",
		"right_effects": {"goal_progress": 1},
	})
	gm.goal_progress = GameManagerScript.GOAL_TARGET - 1

	gm.resolve_card(card, "right")
	assert_eq(gm.goal_progress, GameManagerScript.GOAL_TARGET, "Goal target reached on normal card")
	assert_true(not gm.is_game_over, "Reaching target on normal card does not win immediately")

	var next_card = gm.draw_card()
	assert_eq(next_card.id, "final_gate", "After reaching target, only final cards are drawn")
	gm.free()


func test_game_manager_final_progression_requires_gate_then_trial_then_sacrifice() -> void:
	print("[test_game_manager_final_progression_requires_gate_then_trial_then_sacrifice]")
	var gm := _create_game_manager()
	gm.goal_progress = GameManagerScript.GOAL_TARGET
	gm.deck_mode = "final"  # draw_card() が自動遷移するが、直接テスト用に手動設定

	assert_true(not gm._passes_hard_filter(_find_card("final_trial")), "final_trial is blocked before final_gate")
	assert_true(not gm._passes_hard_filter(_find_card("final_sacrifice")), "final_sacrifice is blocked before final_trial")
	assert_true(not gm._passes_hard_filter(_find_card("final_arrival")), "final_arrival is blocked before final_gate")
	assert_true(gm._passes_hard_filter(_find_card("final_gate")), "final_gate is available first")

	var gate = gm.draw_card()
	assert_eq(gate.id, "final_gate", "final_gate is the first final card drawn")
	gm.resolve_card(gate, "left")
	assert_true(not gm.is_game_over, "Clearing final_gate alone does not win the game")
	assert_true(gm._passes_hard_filter(_find_card("final_trial")), "final_trial unlocks after final_gate")
	assert_true(not gm._passes_hard_filter(_find_card("final_arrival")), "final_arrival still waits for later steps")

	var trial = _find_card("final_trial")
	gm.resolve_card(trial, "left")
	assert_true(gm._passes_hard_filter(_find_card("final_sacrifice")), "final_sacrifice unlocks after trial_passed")
	assert_true(not gm._passes_hard_filter(_find_card("final_arrival")), "final_arrival still waits for sacrifice")
	gm.free()


func test_game_manager_final_arrival_wins() -> void:
	print("[test_game_manager_final_arrival_wins]")
	var gm := _create_game_manager()
	gm.goal_progress = GameManagerScript.GOAL_TARGET
	gm.deck_mode = "final"  # draw_card() が自動遷移するが、直接テスト用に手動設定

	gm.resolve_card(_find_card("final_gate"), "left")
	gm.resolve_card(_find_card("final_trial"), "left")
	gm.resolve_card(_find_card("final_sacrifice"), "left")
	assert_true(gm._passes_hard_filter(_find_card("final_arrival")), "final_arrival unlocks after all required final steps")

	gm.resolve_card(_find_card("final_arrival"), "left")
	assert_true(gm.is_game_over, "final_arrival ends the run in victory")
	gm.free()


func test_game_manager_day_zero_loses() -> void:
	print("[test_game_manager_day_zero_loses]")
	var gm := _create_game_manager()
	var card = _make_test_card({"id": "last_day"})
	gm.days_remaining = 1

	gm.resolve_card(card, "right")
	assert_true(gm.is_game_over, "Days reaching zero causes defeat")
	gm.free()


func _create_game_manager() -> Node:
	var gm := Node.new()
	gm.set_script(GameManagerScript)
	gm._all_cards = CardDataScript.load_all()
	gm._rng = RandomNumberGenerator.new()
	gm._rng.seed = 12345
	gm.reset()
	return gm


func _make_test_card(overrides: Dictionary):
	var d := {
		"id": overrides.get("id", "test"),
		"text": overrides.get("text", "Test card"),
		"left_text": overrides.get("left_text", "Left"),
		"right_text": overrides.get("right_text", "Right"),
		"left_effects": overrides.get("left_effects", {}),
		"right_effects": overrides.get("right_effects", {}),
		"conditions": overrides.get("conditions", {}),
		"base_weight": overrides.get("base_weight", 1.0),
		"tags": overrides.get("tags", []),
	}
	return CardDataScript.from_dict(d)


func _find_card(card_id: String):
	for card in CardDataScript.load_all():
		if card.id == card_id:
			return card
	return null
