extends SceneTree
# 自動檢查：載入開場關卡，模擬按鍵，確認玩家移動、碰撞、蹲下、手電筒、互動開播
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


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(3)


func _run() -> void:
	var scene: Node = load("res://levels/00_prologue/prologue.tscn").instantiate()
	root.add_child(scene)
	player = scene.get_node("Player")
	var overlay: CanvasLayer = scene.get_node("StreamOverlay")
	await _frames(60)
	_check("站在地上", player.is_on_floor() and absf(player.global_position.y) < 0.05, str(player.global_position))
	_check("開播前不顯示手機直播介面", not overlay.visible)

	# 起點在入口附近，面向北邊的閱覽區
	await _place(Vector3(1.4, 0, 8.6), 0)
	var start := player.global_position
	Input.action_press("move_forward"); await _frames(60); Input.action_release("move_forward")
	await _frames(30)
	var walk_dist := start.distance_to(player.global_position)
	_check("走路 1 秒約 2~2.8 公尺", walk_dist > 2.0 and walk_dist < 2.8, "%.2f" % walk_dist)

	await _place(Vector3(1.4, 0, 8.6), 0)
	start = player.global_position
	Input.action_press("move_forward"); Input.action_press("run"); await _frames(30)
	_check("奔跑中 is_running", player.is_running)
	await _frames(30)
	Input.action_release("move_forward"); Input.action_release("run"); await _frames(30)
	var run_dist := start.distance_to(player.global_position)
	_check("奔跑比走路遠", run_dist > walk_dist + 1.0, "%.2f" % run_dist)

	# 西側書架區的走道（兩排書架之間）
	await _place(Vector3(-10, 0, -6.4), 90)
	Input.action_press("move_forward"); await _frames(60 * 3); Input.action_release("move_forward")
	await _frames(20)
	_check("不會穿過西側靠牆書架", player.global_position.x > -13.5, "x=%.2f" % player.global_position.x)

	await _place(Vector3(-10, 0, -6.4), 0)
	Input.action_press("move_forward"); await _frames(60 * 2); Input.action_release("move_forward")
	await _frames(20)
	_check("不會穿過書架", player.global_position.z > -7.0, "z=%.2f" % player.global_position.z)

	# 服務櫃檯內側：桌面下方
	var head: Node3D = player.get_node("Head")
	await _place(Vector3(9.3, 0, 5.0), 90)
	Input.action_press("crouch"); await _frames(40)
	_check("蹲下後視線變低", player.is_crouching and head.global_position.y < 1.0, "head=%.2f" % head.global_position.y)
	await _place(Vector3(8.15, 0, 5.0), 90)
	Input.action_release("crouch"); await _frames(40)
	_check("櫃檯下放開蹲下仍維持蹲姿", player.is_crouching and head.global_position.y < 1.1, "head=%.2f" % head.global_position.y)
	await _place(Vector3(9.5, 0, 5.0), 90)
	await _frames(40)
	_check("離開櫃檯後自動站起", not player.is_crouching and head.global_position.y > 1.5, "head=%.2f" % head.global_position.y)

	# 手機手電筒
	await _press("flashlight")
	var light: SpotLight3D = player.get_node("Head/Flashlight")
	_check("按 F 打開手電筒", player.flashlight_on and light.visible)
	await _press("flashlight")
	_check("再按 F 關掉手電筒", not player.flashlight_on and not light.visible)

	# 東北角死角：看著直播點按 E
	var prompt := [""]
	root.get_node("EventBus").interaction_prompt_changed.connect(func(t: String) -> void: prompt[0] = t)
	await _place(Vector3(12.2, 0, -6.6), 0)
	await _frames(5)
	_check("對準直播點出現提示", prompt[0] == "按 E 開始直播", "prompt=" + prompt[0])
	await _press("interact")
	_check("按 E 後開始直播並顯示手機介面", overlay.is_live and overlay.visible)
	await create_timer(3.0).timeout
	var chat_count: int = overlay.get_node("ChatList").get_child_count()
	_check("開播後出現彈幕", chat_count >= 2, "count=%d" % chat_count)
	await _frames(5)
	_check("開播後提示消失（只能開一次）", prompt[0] == "", "prompt=" + prompt[0])

	print("RESULT fails=%d" % fails)
	quit(fails)
