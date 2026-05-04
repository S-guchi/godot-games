extends RefCounted

const SKILLS := {
	"power_strike": {
		"name": "強撃",
		"cooldown": 2,
		"desc": "通常攻撃+5ダメージ",
		"icon": "power_strike"
	},
	"guard": {
		"name": "防御",
		"cooldown": 3,
		"desc": "盾を2ターン得る",
		"icon": "guard"
	},
	"first_aid": {
		"name": "応急手当",
		"cooldown": 4,
		"desc": "HPを8回復",
		"icon": "first_aid"
	},
	"charged_attack": {
		"name": "溜め攻撃",
		"cooldown": 3,
		"desc": "長押しで大ダメージ",
		"icon": "charged_attack"
	}
}

static func get_skill(skill_id: String) -> Dictionary:
	var skill: Dictionary = SKILLS[skill_id].duplicate(true)
	skill["id"] = skill_id
	return skill

static func default_skills() -> Array[String]:
	return ["power_strike", "guard", "first_aid", "charged_attack"]
