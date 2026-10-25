extends Control
## 黑底字卡：依序顯示 JSON 裡的文字，時間到或按任意鍵進入下一張，最後換到下一個場景。

@export var data_id := "dialogue/intro"

const FADE_IN := 0.8
const FADE_OUT := 0.6

var _cards: Array = []
var _next_scene := ""
var _index := -1
var _timer := 0.0
var _busy := true  # 淡入淡出時不接受跳過

@onready var _card: Control = %Card
@onready var _text: Label = %Text
@onready var _caption: Label = %Caption


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_card.modulate.a = 0.0
	var data: Variant = DataLoader.load_json(data_id)
	if data is Dictionary:
		_cards = data.get("cards", [])
		_next_scene = data.get("next_scene", "")
	_show_next()


func _process(delta: float) -> void:
	if _busy:
		return
	_timer -= delta
	if _timer <= 0.0:
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		_advance()


func _show_next() -> void:
	_index += 1
	if _index >= _cards.size():
		set_process(false)
		LevelManager.change_scene(_next_scene)
		return
	var card: Dictionary = _cards[_index]
	_text.text = card.get("text", "")
	_caption.text = card.get("caption", "")
	_timer = float(card.get("seconds", 4.0))
	_busy = true
	var tween := create_tween()
	tween.tween_property(_card, "modulate:a", 1.0, FADE_IN)
	tween.finished.connect(func() -> void: _busy = false)


func _advance() -> void:
	_busy = true
	var tween := create_tween()
	tween.tween_property(_card, "modulate:a", 0.0, FADE_OUT)
	tween.finished.connect(_show_next)
