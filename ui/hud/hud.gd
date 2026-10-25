extends CanvasLayer
## 遊戲中畫面：準心、互動提示、字幕。

var _subtitle_queue: Array = []
var _subtitle_playing := false

@onready var _prompt: Label = %Prompt
@onready var _subtitle: Label = %Subtitle


func _ready() -> void:
	_prompt.text = ""
	_subtitle.text = ""
	EventBus.interaction_prompt_changed.connect(_on_prompt_changed)
	EventBus.subtitle_requested.connect(_on_subtitle_requested)


func _on_prompt_changed(text: String) -> void:
	_prompt.text = text


func _on_subtitle_requested(text: String, duration: float) -> void:
	# 字幕依序排隊播放，不會互相蓋掉
	_subtitle_queue.append([text, duration])
	if not _subtitle_playing:
		_play_subtitles()


func _play_subtitles() -> void:
	_subtitle_playing = true
	while not _subtitle_queue.is_empty():
		var entry: Array = _subtitle_queue.pop_front()
		_subtitle.text = entry[0]
		await get_tree().create_timer(entry[1]).timeout
		_subtitle.text = ""
		await get_tree().create_timer(0.3).timeout
	_subtitle_playing = false
