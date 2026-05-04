extends RefCounted
class_name InventoryManager

const Equipment = preload("res://data/equipment.gd")
const Items = preload("res://data/items.gd")

static func create_inventory() -> Dictionary:
	return {
		"equipment": {
			"weapon": "",
			"armor": "",
			"accessory": ""
		},
		"equipment_bag": [],
		"items": {
			"potion": 1,
			"smoke_bomb": 0,
			"antidote": 0,
			"bomb": 0
		}
	}

static func add_item(inventory: Dictionary, item_id: String, amount: int = 1) -> void:
	inventory.items[item_id] = int(inventory.items.get(item_id, 0)) + amount

static func use_item(inventory: Dictionary, item_id: String) -> bool:
	if int(inventory.items.get(item_id, 0)) <= 0:
		return false
	inventory.items[item_id] = int(inventory.items[item_id]) - 1
	return true

static func add_equipment(inventory: Dictionary, equipment_id: String) -> void:
	inventory.equipment_bag.append(equipment_id)

static func equip(inventory: Dictionary, equipment_id: String) -> String:
	var equipment := Equipment.get_equipment(equipment_id)
	var slot := String(equipment.slot)
	var previous := String(inventory.equipment.get(slot, ""))
	inventory.equipment[slot] = equipment_id
	if inventory.equipment_bag.has(equipment_id):
		inventory.equipment_bag.erase(equipment_id)
	if previous != "":
		inventory.equipment_bag.append(previous)
	return previous

static func equipment_bonus(inventory: Dictionary) -> Dictionary:
	var bonus := {"atk": 0, "def": 0, "max_hp": 0}
	for slot in inventory.equipment.keys():
		var equipment_id := String(inventory.equipment[slot])
		if equipment_id == "":
			continue
		var equipment := Equipment.get_equipment(equipment_id)
		bonus.atk += int(equipment.atk)
		bonus.def += int(equipment.def)
		bonus.max_hp += int(equipment.max_hp)
	return bonus

static func item_summary(inventory: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id in inventory.items.keys():
		var amount := int(inventory.items[item_id])
		if amount > 0:
			parts.append("%s x%d" % [Items.get_item(String(item_id)).name, amount])
	return " / ".join(parts) if not parts.is_empty() else "なし"

static func equipment_summary(inventory: Dictionary) -> String:
	var parts: Array[String] = []
	for slot in ["weapon", "armor", "accessory"]:
		var equipment_id := String(inventory.equipment[slot])
		if equipment_id != "":
			parts.append(Equipment.get_equipment(equipment_id).name)
	return " / ".join(parts) if not parts.is_empty() else "なし"
