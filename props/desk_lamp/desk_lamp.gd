extends Node3D
## 桌燈。lit 不勾選時燈罩仍會發光，但不產生真的光源（節省效能）。

@export var lit := false


func _ready() -> void:
	$Light.visible = lit
