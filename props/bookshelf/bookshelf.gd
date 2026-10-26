@tool
extends StaticBody3D
## 書架（佔位）：木頭框架＋隨機排列的書。
## 可調整寬度、層數（3 層＝矮書架、5 層＝一般、6 層＝靠牆高書架）、單面或雙面。
## 書本會隨機缺漏、傾倒、橫放成一疊，每座書架都不一樣。

const DEPTH := 0.6
const BOARD := 0.03
const BASE := 0.1  # 底座高度
const LEVEL_HEIGHT := 0.42  # 每層高度
const BOOK_COLORS := [
	Color(0.35, 0.08, 0.07), Color(0.12, 0.2, 0.14), Color(0.1, 0.14, 0.25),
	Color(0.38, 0.27, 0.15), Color(0.62, 0.56, 0.45), Color(0.18, 0.16, 0.15),
	Color(0.45, 0.3, 0.1), Color(0.25, 0.1, 0.18),
]

@export var frame_material: Material
@export var book_material: Material
## 寬度（公尺），建議 1 或 2
@export var width := 2.0
## 層數：3 = 矮書架（蹲下可躲在後面）、5 = 一般、6 = 靠牆高書架
@export_range(2, 6) var levels := 5
@export var double_sided := true
## 空位比例：數字越大書越少、越凌亂
@export_range(0.0, 0.8) var missing_ratio := 0.12
## 書本傾倒、橫放的比例
@export_range(0.0, 0.5) var messy_ratio := 0.08
## 0 = 依書架位置自動產生不同的排列
@export var book_seed := 0
## 超過這個距離（公尺）就不畫書本，節省效能；遠處本來就被黑暗和霧遮住
@export var books_visible_distance := 20.0

static var _frame_meshes := {}


func get_height() -> float:
	return BASE + levels * LEVEL_HEIGHT


func _ready() -> void:
	for child in get_children():
		if child.has_meta("generated"):
			remove_child(child)
			child.queue_free()
	var height := get_height()

	var frame := MeshInstance3D.new()
	frame.mesh = _get_frame_mesh(width, levels, double_sided)
	frame.material_override = frame_material
	_add_generated(frame)

	var books := MultiMeshInstance3D.new()
	books.multimesh = _build_books()
	books.material_override = book_material
	books.visibility_range_end = books_visible_distance
	_add_generated(books)

	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height, DEPTH)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = height * 0.5
	_add_generated(collision)

	# 遮擋：書架後方的東西不必畫出來（效能）
	var box := BoxOccluder3D.new()
	box.size = Vector3(width - 0.1, height - 0.1, 0.02)
	var occluder := OccluderInstance3D.new()
	occluder.occluder = box
	occluder.position.y = height * 0.5
	_add_generated(occluder)


func _add_generated(node: Node) -> void:
	node.set_meta("generated", true)
	add_child(node)


static func _get_frame_mesh(w_total: float, level_count: int, two_sided: bool) -> ArrayMesh:
	# 同樣尺寸的書架共用同一個框架網格
	var key := "%s_%d_%s" % [w_total, level_count, two_sided]
	if _frame_meshes.has(key):
		return _frame_meshes[key]
	var height := BASE + level_count * LEVEL_HEIGHT
	var w := w_total * 0.5
	var d := DEPTH * 0.5
	var back_z := -0.01 if two_sided else -d
	var list: Array[AABB] = [
		AABB(Vector3(-w, 0, -d), Vector3(w_total, BASE, DEPTH)),  # 底座
		AABB(Vector3(-w, height - BOARD, -d), Vector3(w_total, BOARD, DEPTH)),  # 頂板
		AABB(Vector3(-w, 0, -d), Vector3(BOARD, height, DEPTH)),  # 左側板
		AABB(Vector3(w - BOARD, 0, -d), Vector3(BOARD, height, DEPTH)),  # 右側板
		AABB(Vector3(-w, 0, back_z), Vector3(w_total, height, 0.02)),  # 背板
	]
	for i in range(1, level_count):
		list.append(AABB(Vector3(-w, BASE + i * LEVEL_HEIGHT - BOARD, -d), Vector3(w_total, BOARD, DEPTH)))
	var mesh := BoxProp.build_mesh(list)
	_frame_meshes[key] = mesh
	return mesh


func _build_books() -> MultiMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = book_seed if book_seed != 0 else hash(global_position.snapped(Vector3.ONE * 0.1))

	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var sides := [1.0, -1.0] if double_sided else [1.0]
	var x_min := -width * 0.5 + BOARD + 0.005
	var x_max := width * 0.5 - BOARD - 0.005
	var max_h := LEVEL_HEIGHT - BOARD - 0.02
	for side in sides:
		for level in levels:
			var base_y := BASE + level * LEVEL_HEIGHT
			var x := x_min
			while true:
				var roll := rng.randf()
				if roll < messy_ratio * 0.5:
					# 一疊橫放的書
					var stack_w := rng.randf_range(0.2, 0.3)
					if x + stack_w > x_max:
						break
					var y := base_y
					for i in rng.randi_range(2, 6):
						var t := rng.randf_range(0.03, 0.06)
						var d := rng.randf_range(0.16, 0.24)
						var w := stack_w * rng.randf_range(0.8, 1.0)
						var pos := Vector3(x + stack_w * 0.5, y + t * 0.5, _book_z(side, d))
						var basis := Basis(Vector3.UP, rng.randf_range(-0.15, 0.15)) * Basis.from_scale(Vector3(w, t, d))
						transforms.append(Transform3D(basis, pos))
						colors.append(_random_color(rng))
						y += t
					x += stack_w + 0.01
					continue
				var w := rng.randf_range(0.025, 0.06)
				var h := rng.randf_range(0.2, minf(0.34, max_h))
				if x + w > x_max:
					break
				if roll < messy_ratio:
					# 傾倒靠在旁邊的書
					var angle := rng.randf_range(0.25, 0.6) * (1.0 if rng.randf() < 0.5 else -1.0)
					var d := rng.randf_range(0.17, 0.25)
					var pos := Vector3(x + w * 0.5 + sin(absf(angle)) * h * 0.4, base_y + cos(angle) * h * 0.5, _book_z(side, d))
					var basis := Basis(Vector3.BACK, angle) * Basis.from_scale(Vector3(w, h, d))
					transforms.append(Transform3D(basis, pos))
					colors.append(_random_color(rng))
					x += w + h * 0.35
				elif rng.randf() >= missing_ratio:
					var d := rng.randf_range(0.17, 0.25)
					transforms.append(Transform3D(Basis.from_scale(Vector3(w, h, d)), Vector3(x + w * 0.5, base_y + h * 0.5, _book_z(side, d))))
					colors.append(_random_color(rng))
					x += w + 0.002
				else:
					x += w + 0.002

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()  # 預設 1×1×1，靠縮放變成書
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])
	return mm


func _book_z(side: float, depth: float) -> float:
	# 書背對齊外側；單面書架只有正面（+Z）
	return side * (DEPTH * 0.5 - 0.02 - depth * 0.5)


func _random_color(rng: RandomNumberGenerator) -> Color:
	var c: Color = BOOK_COLORS[rng.randi_range(0, BOOK_COLORS.size() - 1)]
	return c.darkened(rng.randf_range(0.0, 0.4))
