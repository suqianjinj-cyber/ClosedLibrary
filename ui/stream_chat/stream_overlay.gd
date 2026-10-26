extends CanvasLayer
## 手機直播介面：開播狀態、觀看人數、時間、訊號、電量、彈幕。
## 彈幕內容來自 data/chat/，數值來自 data/levels/。

@export var level_data_id := "levels/prologue"
@export var chat_data_id := "chat/prologue"
## 畫面上最多同時顯示幾則彈幕
@export var max_messages := 8

var is_live := false
var battery := 100.0

var _level: Dictionary = {}
var _chat: Dictionary = {}
var _clock_minutes := 0.0  # 從午夜起算的分鐘數
var _viewers := 0
var _filler_timer := 0.0
var _flashlight_on := false

@onready var _live_badge: Label = %LiveBadge
@onready var _viewers_label: Label = %Viewers
@onready var _clock_label: Label = %Clock
@onready var _battery_label: Label = %Battery
@onready var _signal_bars: Array[Node] = %SignalBars.get_children()
@onready var _chat_list: VBoxContainer = %ChatList


func _ready() -> void:
	var level: Variant = DataLoader.load_json(level_data_id)
	if level is Dictionary:
		_level = level
	var chat: Variant = DataLoader.load_json(chat_data_id)
	if chat is Dictionary:
		_chat = chat

	battery = float(_level.get("battery_start", 100))
	var hm: PackedStringArray = str(_level.get("clock_start", "21:00")).split(":")
	_clock_minutes = int(hm[0]) * 60 + int(hm[1])
	_set_signal(int(_level.get("signal_bars", 3)))
	_set_live_visuals(false)
	visible = false  # 開始直播時才顯示手機介面

	EventBus.stream_started.connect(_on_stream_started)
	EventBus.chat_message_posted.connect(_add_message)
	EventBus.flashlight_toggled.connect(func(on: bool) -> void: _flashlight_on = on)


func _process(delta: float) -> void:
	_clock_minutes += delta / 60.0  # 遊戲時間與現實時間同速
	var drain := float(_level.get("battery_drain_per_minute", 0.4)) / 60.0 * delta
	if is_live:
		drain *= float(_level.get("battery_drain_live_multiplier", 2.0))
	if _flashlight_on:
		drain *= float(_level.get("battery_drain_flashlight_multiplier", 2.0))
	var was_empty := battery <= 0.0
	battery = maxf(battery - drain, 0.0)
	if battery <= 0.0 and not was_empty:
		EventBus.battery_depleted.emit()

	var total := int(_clock_minutes) % (24 * 60)
	_clock_label.text = "%02d:%02d" % [total / 60, total % 60]
	_battery_label.text = "%d%%" % int(battery)

	if is_live:
		_update_filler_chat(delta)


func _on_stream_started() -> void:
	if is_live:
		return
	is_live = true
	visible = true
	_viewers = int(_chat.get("viewers_start", 10))
	_set_live_visuals(true)
	for entry in _chat.get("scripted", []):
		get_tree().create_timer(float(entry.get("t", 0.0))).timeout.connect(
			EventBus.chat_message_posted.emit.bind(entry.get("user", ""), entry.get("text", "")))
	var last_t := 0.0
	for entry in _chat.get("scripted", []):
		last_t = maxf(last_t, float(entry.get("t", 0.0)))
	_filler_timer = last_t + 2.0  # 腳本彈幕播完後才開始隨機彈幕


func _update_filler_chat(delta: float) -> void:
	_filler_timer -= delta
	if _filler_timer > 0.0:
		return
	var interval: Array = _chat.get("filler_interval", [3.0, 6.0])
	_filler_timer = randf_range(float(interval[0]), float(interval[1]))
	var users: Array = _chat.get("filler_users", [])
	var texts: Array = _chat.get("filler_texts", [])
	if users.is_empty() or texts.is_empty():
		return
	EventBus.chat_message_posted.emit(users.pick_random(), texts.pick_random())
	# 觀看人數小幅波動，整體慢慢增加
	_viewers = maxi(_viewers + randi_range(-2, 4), 1)
	_viewers_label.text = "觀看 %d" % _viewers


func _add_message(user: String, text: String) -> void:
	var line := RichTextLabel.new()
	line.bbcode_enabled = true
	line.fit_content = true
	line.scroll_active = false
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_font_size_override("normal_font_size", 17)
	line.add_theme_color_override("font_outline_color", Color.BLACK)
	line.add_theme_constant_override("outline_size", 5)
	line.text = "[color=#8fb8d8]%s[/color]  %s" % [user.replace("[", "［"), text.replace("[", "［")]
	_chat_list.add_child(line)
	while _chat_list.get_child_count() > max_messages:
		_chat_list.get_child(0).queue_free()
		_chat_list.remove_child(_chat_list.get_child(0))


func _set_live_visuals(live: bool) -> void:
	_live_badge.text = "● LIVE" if live else "● 未開播"
	_live_badge.add_theme_color_override("font_color",
			Color(1, 0.25, 0.25) if live else Color(0.6, 0.6, 0.6))
	_viewers_label.visible = live
	_viewers_label.text = "觀看 %d" % _viewers


func _set_signal(bars: int) -> void:
	for i in _signal_bars.size():
		(_signal_bars[i] as ColorRect).color = \
				Color(0.9, 0.9, 0.9, 0.9) if i < bars else Color(0.4, 0.4, 0.4, 0.5)
