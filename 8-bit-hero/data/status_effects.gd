extends RefCounted

const STATUS := {
	"poison": {"name": "毒", "icon": "poison", "desc": "ターン終了時に2ダメージ"},
	"burn": {"name": "火傷", "icon": "burn", "desc": "ターン終了時に3ダメージ"},
	"shield": {"name": "盾", "icon": "shield_status", "desc": "被ダメージ-3"},
	"weaken": {"name": "弱体", "icon": "weaken", "desc": "ATK-2"},
	"stun": {"name": "スタン", "icon": "stun", "desc": "次の行動を失う"}
}

static func get_name(status_id: String) -> String:
	return STATUS[status_id].name if STATUS.has(status_id) else status_id
