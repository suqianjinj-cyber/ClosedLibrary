@tool
extends Node3D
## 散落在地上或桌上的一堆書（佔位）。沒有碰撞，玩家可以直接走過去。

@export var book_material: Material
@export_range(1, 40) var count := 10
## 散落範圍（公尺）
@export var spread := 0.6
## 0 = 依位置自動產生
@export var pile_seed := 0

const COLORS := [
	Color(0.35, 0.08, 0.07), Color(0.12, 0.2, 0.14), Color(0.1, 0.14, 0.25),
	Color(0.38, 0.27, 0.15), Color(0.62, 0.56, 0.45), Color(0.18, 0.16, 0.15),
]


func _ready() -> void:
	for child in get_children():
		if child.has_meta("generated"):
			remove_child(child)
			child.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = pile_seed if pile_seed != 0 else hash(global_position.snapped(Vector3.ONE * 0.1))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = count
	# 一部分疊在中間，一部分散開
	var stack_y := 0.0
	for i in count:
		var size := Vector3(rng.randf_range(0.15, 0.24), rng.randf_range(0.025, 0.06), rng.randf_range(0.2, 0.3))
		var pos: Vector3
		if rng.randf() < 0.5:
			pos = Vector3(rng.randf_range(-0.05, 0.05), stack_y + size.y * 0.5, rng.randf_range(-0.05, 0.05))
			stack_y += size.y
		else:
			pos = Vector3(rng.randf_range(-spread, spread) * 0.5, size.y * 0.5, rng.randf_range(-spread, spread) * 0.5)
		var basis := Basis(Vector3.UP, rng.randf_range(-PI, PI)) * Basis.from_scale(size)
		mm.set_instance_transform(i, Transform3D(basis, pos))
		mm.set_instance_color(i, (COLORS[rng.randi_range(0, COLORS.size() - 1)] as Color).darkened(rng.randf_range(0.0, 0.4)))

	var books := MultiMeshInstance3D.new()
	books.multimesh = mm
	books.material_override = book_material
	books.visibility_range_end = 20.0
	books.set_meta("generated", true)
	add_child(books)
