extends RefCounted
class_name CombatManager

static func tick_status(target: Dictionary) -> String:
	var messages: Array[String] = []
	var statuses: Dictionary = target.get("statuses", {})
	if int(statuses.get("poison", 0)) > 0:
		target.hp = max(0, int(target.hp) - 2)
		messages.append("%sは毒で2ダメージ。" % target.name)
	if int(statuses.get("burn", 0)) > 0:
		target.hp = max(0, int(target.hp) - 3)
		messages.append("%sは火傷で3ダメージ。" % target.name)
	for status_id in statuses.keys():
		statuses[status_id] = max(0, int(statuses[status_id]) - 1)
	return "\n".join(messages)

static func has_status(target: Dictionary, status_id: String) -> bool:
	return int(target.get("statuses", {}).get(status_id, 0)) > 0

static func add_status(target: Dictionary, status_id: String, turns: int) -> void:
	if not target.has("statuses"):
		target["statuses"] = {}
	target.statuses[status_id] = max(int(target.statuses.get(status_id, 0)), turns)

static func attack_damage(base_atk: int, attacker: Dictionary = {}) -> int:
	var damage := base_atk
	if has_status(attacker, "weaken"):
		damage = max(1, damage - 2)
	return damage

static func incoming_damage(raw_damage: int, defender: Dictionary) -> int:
	var damage := raw_damage
	if has_status(defender, "shield"):
		damage = max(1, damage - 3)
	return damage
