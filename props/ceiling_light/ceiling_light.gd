@tool
extends Node3D
## 天花板日光燈（向下照的聚光燈，在地面形成光圈）。lit：有沒有亮；flicker：會不會像接觸不良一樣閃爍。
## 只有亮著的燈才會產生真的光源；文書筆電上建議整個場景亮著的燈不超過 10 盞。

@export var lit := false:
	set(value):
		lit = value
		_apply(lit)
@export var flicker := false
@export var light_energy := 4.0
@export var light_range := 9.0
@export var on_material: Material
@export var off_material: Material

var _flicker_timer := 0.0


func _ready() -> void:
	_apply(lit)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not (lit and flicker):
		return
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		var on := randf() > 0.3
		_apply(on)
		# 熄滅很短，亮著比較久
		_flicker_timer = randf_range(0.1, 1.6) if on else randf_range(0.03, 0.12)


func _apply(on: bool) -> void:
	if not is_inside_tree():
		return
	var light: SpotLight3D = $Light
	light.visible = on
	light.light_energy = light_energy
	light.spot_range = light_range
	($Panel as MeshInstance3D).material_override = on_material if on else off_material
