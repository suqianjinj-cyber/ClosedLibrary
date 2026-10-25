extends SceneTree
# M1 自動檢查：載入教學關，模擬按鍵，確認玩家行為

var player: CharacterBody3D
var fails := 0

func _initialize() -> void:
	_run.call_deferred()

func _frames(n: int) -> void:
	for i in n:
		await physics_frame

func _check(label: String, ok: bool, info := "") -> void:
	print(("PASS " if ok else "FAIL ") + label + "  " + info)
	if not ok: fails += 1

func _run() -> void:
	var scene: Node = load("res://levels/00_prologue/prologue.tscn").instantiate()
	root.add_child(scene)
	player = scene.get_node("Player")
	await _frames(60)
	_check("站在地上", player.is_on_floor() and absf(player.global_position.y) < 0.05, str(player.global_position))

	var z0 := player.global_position.z
	Input.action_press("move_forward"); await _frames(60); Input.action_release("move_forward")
	await _frames(30)
	var walk_dist := z0 - player.global_position.z
	_check("走路 1 秒約 2~2.6 公尺", walk_dist > 2.0 and walk_dist < 2.8, "%.2f" % walk_dist)

	player.global_position = Vector3(0, 0, 4.5); await _frames(10)
	z0 = player.global_position.z
	Input.action_press("move_forward"); Input.action_press("run"); await _frames(30)
	_check("奔跑中 is_running", player.is_running)
	await _frames(30)
	Input.action_release("move_forward"); Input.action_release("run"); await _frames(30)
	var run_dist := z0 - player.global_position.z
	_check("奔跑比走路遠", run_dist > walk_dist + 1.0, "%.2f" % run_dist)

	player.global_position = Vector3(0, 0, 4.5); await _frames(10)
	Input.action_press("move_forward"); await _frames(60 * 6); Input.action_release("move_forward")
	await _frames(20)
	_check("不會穿過北牆", player.global_position.z > -6.0, "z=%.2f" % player.global_position.z)

	player.global_position = Vector3(4, 0, 4.5); await _frames(10)
	Input.action_press("crouch"); await _frames(40)
	var head: Node3D = player.get_node("Head")
	_check("蹲下後視線變低", player.is_crouching and head.global_position.y < 1.0, "head=%.2f" % head.global_position.y)
	player.global_position = Vector3(4, 0, 2.6); await _frames(10)
	Input.action_release("crouch"); await _frames(40)
	_check("櫃檯下放開蹲下仍維持蹲姿", player.is_crouching and head.global_position.y < 1.1, "head=%.2f" % head.global_position.y)
	player.global_position = Vector3(4, 0, 4.5); await _frames(40)
	_check("離開櫃檯後自動站起", not player.is_crouching and head.global_position.y > 1.5, "head=%.2f" % head.global_position.y)

	print("RESULT fails=%d" % fails)
	quit(fails)
