extends Node3D
## 閉館鐵門：平常捲在上方，呼叫 close_shutter() 時落下並擋住入口。

signal closed

@export var width := 3.0
@export var height := 2.7
## 落下需要的秒數
@export var close_time := 2.5

@onready var _door: MeshInstance3D = $Door
@onready var _blocker: CollisionShape3D = $Blocker/CollisionShape3D


func _ready() -> void:
	_door.scale.y = 0.02
	_door.position.y = height - 0.01
	_blocker.disabled = true


func close_shutter() -> void:
	_blocker.disabled = false
	var tween := create_tween().set_parallel()
	tween.tween_property(_door, "scale:y", 1.0, close_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_door, "position:y", height * 0.5, close_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	closed.emit()
