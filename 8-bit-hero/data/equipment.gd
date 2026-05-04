extends RefCounted

const EQUIPMENT := {
	"rusty_sword": {
		"name": "錆びた剣",
		"slot": "weapon",
		"atk": 2,
		"def": 0,
		"max_hp": 0,
		"price": 12,
		"desc": "ATK+2",
		"icon": "sword"
	},
	"knight_blade": {
		"name": "騎士の剣",
		"slot": "weapon",
		"atk": 4,
		"def": 0,
		"max_hp": 0,
		"price": 24,
		"desc": "ATK+4",
		"icon": "sword"
	},
	"iron_armor": {
		"name": "鉄の鎧",
		"slot": "armor",
		"atk": 0,
		"def": 2,
		"max_hp": 4,
		"price": 18,
		"desc": "DEF+2 / MaxHP+4",
		"icon": "armor"
	},
	"guardian_armor": {
		"name": "守護者の鎧",
		"slot": "armor",
		"atk": 0,
		"def": 4,
		"max_hp": 8,
		"price": 32,
		"desc": "DEF+4 / MaxHP+8",
		"icon": "armor"
	},
	"magic_ring": {
		"name": "魔除けの指輪",
		"slot": "accessory",
		"atk": 1,
		"def": 1,
		"max_hp": 3,
		"price": 20,
		"desc": "ATK+1 / DEF+1 / MaxHP+3",
		"icon": "ring"
	}
}

static func get_equipment(equipment_id: String) -> Dictionary:
	var equipment: Dictionary = EQUIPMENT[equipment_id].duplicate(true)
	equipment["id"] = equipment_id
	equipment["type"] = "equipment"
	return equipment

static func roll_equipment(rng: RandomNumberGenerator, floor: int) -> Dictionary:
	var pool: Array[String] = ["rusty_sword", "iron_armor", "magic_ring"]
	if floor >= 3:
		pool.append("knight_blade")
	if floor >= 4:
		pool.append("guardian_armor")
	return get_equipment(pool[rng.randi_range(0, pool.size() - 1)])

static func names_for(ids: Array) -> Array[String]:
	var names: Array[String] = []
	for equipment_id in ids:
		if EQUIPMENT.has(equipment_id):
			names.append(EQUIPMENT[equipment_id].name)
	return names
