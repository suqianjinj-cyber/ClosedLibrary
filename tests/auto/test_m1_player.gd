extends SceneTree
# 自動檢查：載入教學關，模擬按鍵，確認玩家移動、碰撞、蹲下、互動開播
# 執行：Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/auto/test_m1_player.gd

var player: CharacterBody3D
var fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(label: String, ok: bool, info := "") -> void:
	print(("PASS " if ok else "FAIL ") + label + "  " + info)
	if not ok:
		fails += 1


func _place(pos: Vector3, yaw_deg: float) -> void:
	player.global_position = pos
	player.rotation_degrees.y = yaw_deg
	player.velocity = Vector3.ZERO
	await _frames(10)


func _run() -> void:
	var scene: Node = load("res://levels/00_prologue/prologue.tscn").instantiate()
	root.add_child(scene)
	player = scene.get_node("Player")
	await _frames(60)
	_check("站在地上", player.is_on_floor() and absf(player.global_position.y) < 0.05, str(player.global_position))

	# 起點在東北側書庫走道，面向西（-x）
	await _place(Vector3(14, 0, -11.9), 90)
	var start := player.global_position
	Input.action_press("move_forward"); await _frames(60); Input.action_release("move_forward")
	await _frames(30)
	var walk_dist := start.distance_to(player.global_position)
	_check("走路 1 秒約 2~2.8 公尺", walk_dist > 2.0 and walk_dist < 2.8, "%.2f" % walk_dist)

	await _place(Vector3(14, 0, -11.9), 90)
	start = player.global_position
	Input.action_press("move_forward"); Input.action_press("run"); await _frames(30)
	_check("奔跑中 is_running", player.is_running)
	await _frames(30)
	Input.action_release("move_forward"); Input.action_release("run"); await _frames(30)
	var run_dist := start.distance_to(player.global_position)
	_check("奔跑比走路遠", run_dist > walk_dist + 1.0, "%.2f" % run_dist)

	await _place(Vector3(-17, 0, -11.9), 90)
	Input.action_press("move_forward"); await _frames(60 * 3); Input.action_release("move_forward")
	await _frames(20)
	_check("不會穿過西牆", player.global_position.x > -20.0, "x=%.2f" % player.global_position.x)

	await _place(Vector3(14, 0, -11.9), 0)  # 面向北邊的書架
	Input.action_press("move_forward"); await _frames(60 * 2); Input.action_release("move_forward")
	await _frames(20)
	_check("不會穿過書架", player.global_position.z > -12.7, "z=%.2f" % player.global_position.z)

	# 服務櫃檯（中心 7, 9），開口朝北
	var head: Node3D = player.get_node("Head")
	await _place(Vector3(7, 0, 7.2), 0)
	Input.action_press("crouch"); await _frames(40)
	_check("蹲下後視線變低", player.is_crouching and head.global_position.y < 1.0, "head=%.2f" % head.global_position.y)
	await _place(Vector3(7, 0, 9.0), 0)
	Input.action_release("crouch"); await _frames(40)
	_check("櫃檯下放開蹲下仍維持蹲姿", player.is_crouching and head.global_position.y < 1.1, "head=%.2f" % head.global_position.y)
	await _place(Vector3(7, 0, 7.0), 0)
	await _frames(40)
	_check("離開櫃檯後自動站起", not player.is_crouching and head.global_position.y > 1.5, "head=%.2f" % head.global_position.y)

	# 西北角死角：看著開播點按 E
	var prompt := [""]
	root.get_node("EventBus").interaction_prompt_changed.connect(func(t: String) -> void: prompt[0] = t)
	await _place(Vector3(-17.0, 0, -14.2), 90)
	await _frames(5)
	_check("對準開播點出現提示", prompt[0] == "按 E 開始直播", "prompt=" + prompt[0])
	var overlay: Node = scene.get_node("StreamOverlay")
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(5)
	_check("按 E 後開始直播", overlay.is_live)
	await create_timer(3.0).timeout
	var chat_count: int = overlay.get_node("ChatList").get_child_count()
	_check("開播後出現彈幕", chat_count >= 2, "count=%d" % chat_count)
	await _frames(5)
	_check("開播後提示消失（只能開一次）", prompt[0] == "", "prompt=" + prompt[0])

	print("RESULT fails=%d" % fails)
	quit(fails)
