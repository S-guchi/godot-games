extends SceneTree

func _initialize() -> void:
	var root := Control.new()
	root.name = "Main"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load("res://scripts/Main.gd"))
	var scene := PackedScene.new()
	var result := scene.pack(root)
	if result != OK:
		push_error("Main scene pack failed: %s" % result)
		quit(1)
		return
	result = ResourceSaver.save(scene, "res://scenes/Main.tscn")
	if result != OK:
		push_error("Main scene save failed: %s" % result)
		quit(1)
		return
	quit()
