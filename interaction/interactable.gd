class_name Interactable
extends Area3D
## 可互動物件：玩家準心對準時顯示 prompt_text，按 E 送出 interacted 訊號。
## 用法：把這個腳本掛在 Area3D 上，並給它一個 CollisionShape3D。

signal interacted

@export var prompt_text := "按 E 互動"
## 勾選後只能互動一次
@export var one_shot := false

const INTERACT_LAYER := 2  # 第 2 層：可互動物件


func _ready() -> void:
	collision_layer = INTERACT_LAYER
	collision_mask = 0
	monitoring = false


func interact() -> void:
	interacted.emit()
	if one_shot:
		collision_layer = 0  # 玩家的射線就偵測不到了
