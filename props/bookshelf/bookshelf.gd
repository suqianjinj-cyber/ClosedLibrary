@tool
extends StaticBody3D
## 雙面書架（佔位）：木頭框架＋隨機排列的書。
## 尺寸固定：寬 2 公尺、高 2.2 公尺、深 0.6 公尺；排成一排就是一整列書庫。

const WIDTH := 2.0
const HEIGHT := 2.2
const DEPTH := 0.6
const BOARD := 0.03
## 每一層放書的高度（第一層是底座上方）
const SHELF_LEVELS := [0.1, 0.52, 0.94, 1.36, 1.78]
const BOOK_COLORS := [
	Color(0.35, 0.08, 0.07), Color(0.12, 0.2, 0.14), Color(0.1, 0.14, 0.25),
	Color(0.38, 0.27, 0.15), Color(0.62, 0.56, 0.45), Color(0.18, 0.16, 0.15),
	Color(0.45, 0.3, 0.1), Color(0.25, 0.1, 0.18),
]

@export var frame_material: Material
@export var book_material: Material
@export var double_sided := true
## 空位比例：數字越大書越少、越凌亂
@export_range(0.0, 0.6) var missing_ratio := 0.12
## 0 = 依書架位置自動產生不同的排列
@export var book_seed := 0
## 超過這個距離（公尺）就不畫書本，節省效能；遠處本來就被黑暗和霧遮住
@export var books_visible_distance := 20.0

static var _frame_mesh: ArrayMesh


func _ready() -> void:
	for child in get_children():
		if child.has_meta("generated"):
			remove_child(child)
			child.queue_free()

	var frame := MeshInstance3D.new()
	frame.mesh = _get_frame_mesh()
	frame.material_override = frame_material
	frame.set_meta("generated", true)
	add_child(frame)

	var books := MultiMeshInstance3D.new()
	books.multimesh = _build_books()
	books.material_override = book_material
	books.visibility_range_end = books_visible_distance
	books.set_meta("generated", true)
	add_child(books)


static func _get_frame_mesh() -> ArrayMesh:
	# 所有書架共用同一個框架網格
	if _frame_mesh:
		return _frame_mesh
	var w := WIDTH * 0.5
	var d := DEPTH * 0.5
	var list: Array[AABB] = [
		AABB(Vector3(-w, 0, -d), Vector3(WIDTH, SHELF_LEVELS[0], DEPTH)),  # 底座
		AABB(Vector3(-w, HEIGHT - BOARD, -d), Vector3(WIDTH, BOARD, DEPTH)),  # 頂板
		AABB(Vector3(-w, 0, -d), Vector3(BOARD, HEIGHT, DEPTH)),  # 左側板
		AABB(Vector3(w - BOARD, 0, -d), Vector3(BOARD, HEIGHT, DEPTH)),  # 右側板
		AABB(Vector3(-w, 0, -0.01), Vector3(WIDTH, HEIGHT, 0.02)),  # 中間背板
	]
	for i in range(1, SHELF_LEVELS.size()):
		list.append(AABB(Vector3(-w, SHELF_LEVELS[i] - BOARD, -d), Vector3(WIDTH, BOARD, DEPTH)))
	_frame_mesh = BoxProp.build_mesh(list)
	return _frame_mesh


func _build_books() -> MultiMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = book_seed if book_seed != 0 else hash(global_position.snapped(Vector3.ONE * 0.1))

	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var sides := [1.0, -1.0] if double_sided else [1.0]
	var x_min := -WIDTH * 0.5 + BOARD + 0.005
	var x_max := WIDTH * 0.5 - BOARD - 0.005
	for side in sides:
		for base_y in SHELF_LEVELS:
			var x := x_min
			while true:
				var w := rng.randf_range(0.025, 0.06)
				if x + w > x_max:
					break
				if rng.randf() >= missing_ratio:
					var h := rng.randf_range(0.2, 0.34)
					var d := rng.randf_range(0.17, 0.25)
					var pos := Vector3(x + w * 0.5, base_y + h * 0.5, side * (DEPTH * 0.5 - 0.02 - d * 0.5))
					transforms.append(Transform3D(Basis.from_scale(Vector3(w, h, d)), pos))
					var c: Color = BOOK_COLORS[rng.randi_range(0, BOOK_COLORS.size() - 1)]
					colors.append(c.darkened(rng.randf_range(0.0, 0.4)))
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
