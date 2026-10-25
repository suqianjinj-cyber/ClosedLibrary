extends SceneTree
# 自動檢查：主選單 → 開場字卡 → 教學關 的流程
# 執行：Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/auto/test_flow.gd

var fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, ok: bool, info := "") -> void:
	print(("PASS " if ok else "FAIL ") + label + "  " + info)
	if not ok:
		fails += 1


func _press_any_key() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_SPACE
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)


func _run() -> void:
	change_scene_to_file("res://ui/menus/main_menu.tscn")
	await create_timer(0.5).timeout
	_check("主選單載入", current_scene != null and current_scene.name == "MainMenu")

	current_scene.get_node("%StartButton").pressed.emit()
	await create_timer(2.0).timeout
	_check("按開始後進入字卡", current_scene.name == "StoryCards", str(current_scene.name))
	var text: Label = current_scene.get_node("%Text")
	_check("第一張字卡有文字", text.text.length() > 0, text.text.replace("\n", " "))

	# 一直按鍵跳過字卡
	for i in 20:
		if current_scene.name != "StoryCards":
			break
		_press_any_key()
		await create_timer(1.6).timeout
	await create_timer(2.0).timeout
	_check("字卡結束後進入教學關", current_scene.name == "Prologue", str(current_scene.name))

	print("RESULT fails=%d" % fails)
	quit(fails)
