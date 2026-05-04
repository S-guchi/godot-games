extends RefCounted

const Equipment = preload("res://data/equipment.gd")
const Items = preload("res://data/items.gd")

static func roll_stock(rng: RandomNumberGenerator, floor: int) -> Array[Dictionary]:
	var stock: Array[Dictionary] = []
	stock.append(Items.get_item("potion"))
	stock.append(Items.roll_item(rng))
	stock.append(Equipment.roll_equipment(rng, floor))
	stock.append({"id": "heal", "type": "service", "name": "休憩", "price": 10 + floor * 2, "desc": "HPを最大まで回復", "icon": "potion"})
	return stock
