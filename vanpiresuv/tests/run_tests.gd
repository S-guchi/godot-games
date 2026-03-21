extends SceneTree

## Vanpiresuv Physics Survivor headless test runner
## Run: godot --headless --path <PROJECT_DIR> --script res://tests/run_tests.gd

var _pass_count := 0
var _fail_count := 0


func _init() -> void:
	print("=== Vanpiresuv Physics Survivor Test Runner ===")
	print("")

	test_scenes_exist()
	test_bullet_properties()
	test_enemy_properties()
	test_player_properties()

	print("")
	print("=== Results: %d passed, %d failed ===" % [_pass_count, _fail_count])

	if _fail_count > 0:
		quit(1)
	else:
		quit(0)


func assert_true(condition: bool, desc: String) -> void:
	if condition:
		_pass_count += 1
		print("  PASS: %s" % desc)
	else:
		_fail_count += 1
		print("  FAIL: %s" % desc)


func assert_eq(a, b, desc: String) -> void:
	if a == b:
		_pass_count += 1
		print("  PASS: %s" % desc)
	else:
		_fail_count += 1
		print("  FAIL: %s (got %s, expected %s)" % [desc, str(a), str(b)])


func test_scenes_exist() -> void:
	print("[test_scenes_exist]")
	assert_true(ResourceLoader.exists("res://player.tscn"), "player.tscn exists")
	assert_true(ResourceLoader.exists("res://enemy.tscn"), "enemy.tscn exists")
	assert_true(ResourceLoader.exists("res://bullet.tscn"), "bullet.tscn exists")
	assert_true(ResourceLoader.exists("res://world.tscn"), "world.tscn exists")


func test_bullet_properties() -> void:
	print("[test_bullet_properties]")
	var scene := load("res://bullet.tscn") as PackedScene
	assert_true(scene != null, "bullet.tscn loads successfully")
	var bullet := scene.instantiate()
	assert_true(bullet is Area2D, "Bullet is Area2D")
	assert_eq(bullet.collision_layer, 2, "Bullet collision_layer is 2")
	assert_eq(bullet.collision_mask, 4, "Bullet collision_mask is 4")
	assert_eq(bullet.speed, 600.0, "Bullet speed is 600")
	assert_eq(bullet.knockback_force, 500.0, "Bullet knockback_force is 500")
	bullet.free()


func test_enemy_properties() -> void:
	print("[test_enemy_properties]")
	var scene := load("res://enemy.tscn") as PackedScene
	assert_true(scene != null, "enemy.tscn loads successfully")
	var enemy := scene.instantiate()
	assert_true(enemy is RigidBody2D, "Enemy is RigidBody2D")
	assert_eq(enemy.gravity_scale, 0.0, "Enemy gravity_scale is 0")
	assert_true(enemy.lock_rotation, "Enemy lock_rotation is true")
	assert_true(enemy.contact_monitor, "Enemy contact_monitor is true")
	assert_eq(enemy.collision_layer, 4, "Enemy collision_layer is 4")
	assert_eq(enemy.collision_mask, 5, "Enemy collision_mask is 5")
	assert_eq(enemy.hp, 3, "Enemy HP is 3")
	enemy.free()


func test_player_properties() -> void:
	print("[test_player_properties]")
	var scene := load("res://player.tscn") as PackedScene
	assert_true(scene != null, "player.tscn loads successfully")
	var player := scene.instantiate()
	assert_true(player is CharacterBody2D, "Player is CharacterBody2D")
	assert_eq(player.collision_layer, 1, "Player collision_layer is 1")
	assert_eq(player.collision_mask, 4, "Player collision_mask is 4")
	assert_eq(player.speed, 300.0, "Player speed is 300")
	player.free()
