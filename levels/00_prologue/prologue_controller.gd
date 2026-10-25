extends Node3D
## 教學關流程：開場自言自語 → 走到死角按 E 開播 → 彈幕開始。
## （M4 會加入巡邏館員，M5 會在開播後接上異變。）

@export var dialogue_id := "dialogue/prologue"
@export var level_data_id := "levels/prologue"

@onready var _broadcast_spot: Interactable = $BroadcastSpot

var _lines: Dictionary = {}


func _ready() -> void:
	var lines: Variant = DataLoader.load_json(dialogue_id)
	if lines is Dictionary:
		_lines = lines
	_broadcast_spot.interacted.connect(_on_broadcast_spot_used)

	var level: Variant = DataLoader.load_json(level_data_id)
	var delay := 1.0
	if level is Dictionary:
		delay = float(level.get("subtitle_delay", 1.0))
	await get_tree().create_timer(delay).timeout
	_say("start")


func _on_broadcast_spot_used() -> void:
	EventBus.stream_started.emit()
	_say("go_live")


func _say(key: String) -> void:
	for entry in _lines.get(key, []):
		EventBus.subtitle_requested.emit(entry.get("text", ""), float(entry.get("seconds", 3.0)))
