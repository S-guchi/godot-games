extends RefCounted

const ITEMS := {
	"potion": {
		"name": "ポーション",
		"price": 8,
		"desc": "HPを12回復",
		"icon": "potion"
	},
	"smoke_bomb": {
		"name": "煙玉",
		"price": 10,
		"desc": "戦闘から逃げる",
		"icon": "smoke"
	},
	"antidote": {
		"name": "解毒薬",
		"price": 7,
		"desc": "毒と火傷を治す",
		"icon": "antidote"
	},
	"bomb": {
		"name": "爆弾",
		"price": 14,
		"desc": "敵に18ダメージ",
		"icon": "bomb"
	}
}

static func get_item(item_id: String) -> Dictionary:
	var item: Dictionary = ITEMS[item_id].duplicate(true)
	item["id"] = item_id
	item["type"] = "item"
	return item

static func roll_item(rng: RandomNumberGenerator) -> Dictionary:
	var ids: Array = ITEMS.keys()
	return get_item(String(ids[rng.randi_range(0, ids.size() - 1)]))

static func get_name(item_id: String) -> String:
	return ITEMS[item_id].name if ITEMS.has(item_id) else item_id
