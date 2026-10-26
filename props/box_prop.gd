@tool
class_name BoxProp
extends StaticBody3D
## 用數個方塊組成的佔位家具（桌椅、櫃檯、還書箱……）。
## 之後換成 Tripo 模型時，把整個節點換成模型場景即可，不影響程式。
## boxes 每一項是 AABB(左下後角位置, 尺寸)，單位公尺，原點在家具底部中央。

@export var boxes: Array[AABB] = []:
	set(value):
		boxes = value
		_rebuild()
@export var material: Material:
	set(value):
		material = value
		_rebuild()
@export var has_collision := true
## 勾選後會遮擋後方物件（牆壁用），被擋住的東西不會畫出來，節省效能
@export var occlude := false


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		if child.has_meta("generated"):
			remove_child(child)
			child.queue_free()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = build_mesh(boxes)
	mesh_instance.material_override = material
	mesh_instance.set_meta("generated", true)
	add_child(mesh_instance)

	if has_collision:
		for box in boxes:
			var shape := BoxShape3D.new()
			shape.size = box.size
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = box.get_center()
			collision.set_meta("generated", true)
			add_child(collision)

	if occlude:
		for box in boxes:
			var shape := BoxOccluder3D.new()
			shape.size = box.size
			var occluder := OccluderInstance3D.new()
			occluder.occluder = shape
			occluder.position = box.get_center()
			occluder.set_meta("generated", true)
			add_child(occluder)


## 把多個方塊合併成一個網格，減少繪製次數（對文書筆電比較友善）
static func build_mesh(list: Array[AABB]) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for box in list:
		append_box(st, box)
	st.generate_tangents()
	return st.commit()


static func append_box(st: SurfaceTool, box: AABB) -> void:
	var cube := BoxMesh.new()
	cube.size = box.size
	var arrays := cube.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var center := box.get_center()
	for i in indices:
		st.set_normal(normals[i])
		st.set_uv(uvs[i])
		st.add_vertex(verts[i] + center)
