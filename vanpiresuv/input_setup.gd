extends Node

func _ready() -> void:
	_add_key_action("move_up", KEY_W, KEY_UP)
	_add_key_action("move_down", KEY_S, KEY_DOWN)
	_add_key_action("move_left", KEY_A, KEY_LEFT)
	_add_key_action("move_right", KEY_D, KEY_RIGHT)

func _add_key_action(action_name: String, key1: Key, key2: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var ev1 := InputEventKey.new()
		ev1.keycode = key1
		InputMap.action_add_event(action_name, ev1)
		var ev2 := InputEventKey.new()
		ev2.keycode = key2
		InputMap.action_add_event(action_name, ev2)
