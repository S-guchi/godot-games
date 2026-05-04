@tool
extends SceneTree

func _initialize() -> void:
	var root := Control.new()
	root.name = "Main"
	root.set_script(load("res://scripts/main.gd"))

	var scene := PackedScene.new()
	var result := scene.pack(root)
	if result != OK:
		push_error("Main.tscnの生成に失敗しました。")
		quit(1)
		return

	var save_result := ResourceSaver.save(scene, "res://scenes/Main.tscn")
	if save_result != OK:
		push_error("Main.tscnの保存に失敗しました。")
		quit(1)
		return

	print("Main.tscnを生成しました。")
	quit()
