extends Node
# 自動檢查（M2 地圖）：導航網格、巡邏路線、起點到直播點、躲藏點位置與遮蔽程度
# 導航需要正常的遊戲迴圈，所以這個檢查是一個場景（不是 --script）：
# 執行：Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/auto/test_m2_map.tscn

var fails := 0
var scene: Node3D
var space: PhysicsDirectSpaceState3D


func _ready() -> void:
	_run.call_deferred()


func _check(label: String, ok: bool, info := "") -> void:
	print(("PASS " if ok else "FAIL ") + label + "  " + info)
	if not ok:
		fails += 1


func _blocked(from: Vector3, to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	q.exclude = [scene.get_node("Player").get_rid()]
	return not space.intersect_ray(q).is_empty()


func _reachable(map: RID, from: Vector3, to: Vector3) -> Array:
	var target := NavigationServer3D.map_get_closest_point(map, to)
	var path := NavigationServer3D.map_get_path(map, NavigationServer3D.map_get_closest_point(map, from), target, true)
	var ok := path.size() > 0 and path[path.size() - 1].distance_to(target) < 0.3 and target.distance_to(Vector3(to.x, target.y, to.z)) < 0.5
	return [ok, path]


func _run() -> void:
	scene = load("res://levels/00_prologue/prologue.tscn").instantiate()
	add_child(scene)
	for i in 300:
		if scene.is_navigation_ready:
			break
		await get_tree().physics_frame
	_check("導航網格在 5 秒內準備好", scene.is_navigation_ready)
	space = scene.get_world_3d().direct_space_state

	# ── 導航網格與巡邏路線 ──
	var region: NavigationRegion3D = scene.get_node("NavigationRegion3D")
	var polys := region.navigation_mesh.get_polygon_count()
	_check("導航網格已烘焙", polys > 50, "polygons=%d" % polys)
	var map := region.get_navigation_map()
	var points: Array = scene.get_node("PatrolRoute").get_children()
	for i in points.size():
		var a: Node3D = points[i]
		var b: Node3D = points[(i + 1) % points.size()]
		var result := _reachable(map, a.global_position, b.global_position)
		_check("巡邏 %s → %s 走得到" % [a.name, b.name], result[0])
	# 不走替代路線時，W01 也要能直接走到 W02
	var r := _reachable(map, scene.get_node("PatrolRoute/W01_Entrance").global_position, scene.get_node("PatrolRoute/W02_CounterFront").global_position)
	_check("巡邏 W01 → W02（一般路線）走得到", r[0])

	# ── 玩家：起點到直播點 ──
	var start: Vector3 = scene.get_node("Player").global_position
	r = _reachable(map, start, Vector3(12.2, 0, -8.2))
	var length := 0.0
	for k in range(1, r[1].size()):
		length += r[1][k - 1].distance_to(r[1][k])
	_check("起點走得到直播點", r[0], "路徑長 %.1f 公尺" % length)

	# ── 躲藏點 ──
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 0.95
	for spot in scene.get_node("HidingSpots").get_children():
		var pos: Vector3 = spot.global_position
		var eye: Vector3 = pos + Vector3.UP * (spot.eye_height if spot.mode == 1 else 0.85)
		if spot.mode == 0:
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = capsule
			q.transform = Transform3D(Basis(), pos + Vector3.UP * 0.5)
			q.collision_mask = 1
			q.exclude = [scene.get_node("Player").get_rid()]
			_check("躲藏點 %s 蹲得進去（沒有卡在物體裡）" % spot.name, space.intersect_shape(q, 1).is_empty())
		# 遮蔽程度：從 16 個方向 × 2、4、6 公尺、館員眼睛高度 1.6 公尺看向躲藏者，有幾條視線被擋住
		var covered := 0
		for k in 16:
			var dir := Vector3.FORWARD.rotated(Vector3.UP, TAU * k / 16.0)
			for dist in [2.0, 4.0, 6.0]:
				if _blocked(eye + dir * dist + Vector3.UP * (1.6 - eye.y), eye):
					covered += 1
		var ratio := covered / 48.0
		_check("躲藏點 %s 有遮蔽、但不是完全安全" % spot.name, ratio >= 0.1 and ratio < 1.0,
			"遮蔽 %d%%（%s）" % [int(ratio * 100), spot.risk_note])

	# ── 桌子擋板真的擋住視線 ──
	var under_table := Vector3(-2.5, 0.45, 1.8)
	_check("閱覽桌：從長邊（南側）看不到桌底", _blocked(Vector3(-2.5, 1.6, 4.0), under_table))
	_check("閱覽桌：從長邊（北側）看不到桌底", _blocked(Vector3(-2.5, 1.6, -0.4), under_table))
	_check("閱覽桌：從桌子一端遠處看得到桌底", not _blocked(Vector3(4.2, 1.6, 1.8), under_table))
	_check("櫃檯：從櫃檯前方看不到櫃檯內側", _blocked(Vector3(5.5, 1.6, 5.0), Vector3(8.15, 0.55, 5.0)))
	_check("書架：隔著整排書架看不到", _blocked(Vector3(-10, 1.6, -4.4), Vector3(-10, 1.0, -6.4)))

	print("RESULT fails=%d" % fails)
	get_tree().quit(fails)
