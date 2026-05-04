extends RefCounted

const ENEMIES := {
	"slime": {
		"name": "スライム",
		"hp": 8,
		"atk": 2,
		"gold": 2,
		"sprite": "slime",
		"hint": "前方からぬめった気配がする……"
	},
	"bat": {
		"name": "コウモリ",
		"hp": 10,
		"atk": 3,
		"gold": 3,
		"sprite": "bat",
		"hint": "頭上で羽音が反響している……"
	},
	"goblin": {
		"name": "ゴブリン",
		"hp": 13,
		"atk": 4,
		"gold": 4,
		"sprite": "goblin",
		"hint": "獣の匂いがする……"
	},
	"skeleton": {
		"name": "スケルトン",
		"hp": 16,
		"atk": 5,
		"gold": 5,
		"sprite": "skeleton",
		"hint": "乾いた骨の音が近づいてくる……"
	},
	"minotaur": {
		"name": "ミノタウロス",
		"hp": 22,
		"atk": 7,
		"gold": 8,
		"sprite": "minotaur",
		"hint": "重い足音が響く……"
	},
	"king": {
		"name": "ダンジョンの王",
		"hp": 60,
		"atk": 12,
		"gold": 0,
		"sprite": "king",
		"hint": "玉座の間から魔力があふれている……"
	}
}

static func get_enemy(enemy_id: String) -> Dictionary:
	return ENEMIES[enemy_id].duplicate(true)

static func roll_enemy_id(floor: int, rng: RandomNumberGenerator) -> String:
	var candidates: Array[String] = ["slime", "bat"]
	if floor >= 2:
		candidates.append("goblin")
	if floor >= 3:
		candidates.append("skeleton")
	if floor >= 4:
		candidates.append("minotaur")
	return candidates[rng.randi_range(0, candidates.size() - 1)]
