extends CanvasLayer
## 換場景：畫面淡出成黑色 → 載入新場景 → 淡入。

const FADE_TIME := 0.6

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100  # 蓋在所有畫面最上層
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	await _tween_fade(1.0)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("無法載入場景：%s" % path)
	await get_tree().process_frame
	await _tween_fade(0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func _tween_fade(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", target_alpha, FADE_TIME)
	await tween.finished
