extends RefCounted

const RELICS := {
	"vampire_sword": {
		"name": "吸血剣",
		"desc": "敵を倒すたびHPを2回復",
		"sprite": "vampire_sword"
	},
	"scout_map": {
		"name": "探索者の地図",
		"desc": "分岐の気配が詳しくなる",
		"sprite": "scout_map"
	},
	"thief_key": {
		"name": "盗賊の鍵",
		"desc": "宝箱を開けるたびコイン+5、鍵+1",
		"sprite": "thief_key"
	},
	"trap_boots": {
		"name": "罠師の靴",
		"desc": "罠を踏むとATK+1",
		"sprite": "trap_boots"
	},
	"coward_shield": {
		"name": "臆病者の盾",
		"desc": "階段を降りるたびDEF+1",
		"sprite": "coward_shield"
	},
	"cursed_crown": {
		"name": "呪いの王冠",
		"desc": "HPが半分以下ならATK+4",
		"sprite": "cursed_crown"
	},
	"fountain_cup": {
		"name": "泉の杯",
		"desc": "泉の回復量+5",
		"sprite": "fountain_cup"
	},
	"gold_dagger": {
		"name": "黄金の短剣",
		"desc": "所持コイン10枚ごとにATK+1",
		"sprite": "gold_dagger"
	},
	"thick_cloak": {
		"name": "厚いマント",
		"desc": "罠ダメージ-3",
		"sprite": "thick_cloak"
	},
	"life_ring": {
		"name": "生命の指輪",
		"desc": "最大HP+6",
		"sprite": "life_ring"
	}
}

static func get_relic(relic_id: String) -> Dictionary:
	var relic: Dictionary = RELICS[relic_id].duplicate(true)
	relic["id"] = relic_id
	return relic

static func roll_options(owned: Array, rng: RandomNumberGenerator, count: int = 3) -> Array[Dictionary]:
	var ids: Array = RELICS.keys()
	var available: Array[String] = []
	for relic_id in ids:
		if not owned.has(relic_id):
			available.append(String(relic_id))
	if available.is_empty():
		for relic_id in ids:
			available.append(String(relic_id))

	var options: Array[Dictionary] = []
	while options.size() < min(count, available.size()):
		var index := rng.randi_range(0, available.size() - 1)
		var relic_id: String = available.pop_at(index)
		options.append(get_relic(relic_id))
	return options
