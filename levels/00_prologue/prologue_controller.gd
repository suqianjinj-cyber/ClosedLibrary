extends Node3D
## 開場關卡流程：開場自言自語 → 躲過館員抵達直播點 → 按 E 開播。
## （M4 加入館員，M5 在開播後接上鐵門落下、熄燈、雜訊與「第一章完成」。）

## 導航網格烘焙並同步完成，館員可以開始走路
signal navigation_ready

@export var dialogue_id := "dialogue/prologue"
@export var level_data_id := "levels/prologue"

var is_navigation_ready := false

@onready var _broadcast_spot: Interactable = $BroadcastSpot
@onready var _navigation: NavigationRegion3D = $NavigationRegion3D

var _lines: Dictionary = {}


func _ready() -> void:
	var lines: Variant = DataLoader.load_json(dialogue_id)
	if lines is Dictionary:
		_lines = lines
	_broadcast_spot.interacted.connect(_on_broadcast_spot_used)

	# 等碰撞體都建立好之後，依照目前的場景烘焙導航網格（館員走路用）
	await get_tree().physics_frame
	_navigation.bake_navigation_mesh(false)
	_wait_for_navigation()

	var level: Variant = DataLoader.load_json(level_data_id)
	var delay := 1.0
	if level is Dictionary:
		delay = float(level.get("subtitle_delay", 1.0))
	await get_tree().create_timer(delay).timeout
	_say("start")


func _wait_for_navigation() -> void:
	# 烘焙完成後的下一個影格，再明確把網格交給導航伺服器；
	# 關卡在遊戲中途才載入時（例如從主選單進來），少了這一步地圖不會更新
	await get_tree().physics_frame
	NavigationServer3D.region_set_navigation_mesh(_navigation.get_rid(), _navigation.navigation_mesh)
	# 導航伺服器在背景更新地圖，等到地圖上查得到點才算完成
	var map := _navigation.get_navigation_map()
	var probe := $Player.global_position as Vector3
	for i in 300:
		await get_tree().physics_frame
		if NavigationServer3D.map_get_closest_point(map, probe) != Vector3.ZERO:
			is_navigation_ready = true
			navigation_ready.emit()
			return
	push_error("導航網格同步逾時，館員將無法移動")


func _on_broadcast_spot_used() -> void:
	EventBus.stream_started.emit()
	_say("go_live")


func _say(key: String) -> void:
	for entry in _lines.get(key, []):
		EventBus.subtitle_requested.emit(entry.get("text", ""), float(entry.get("seconds", 3.0)))
