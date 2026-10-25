extends Control
## 主選單：開始遊戲／離開。

const FIRST_SCENE := "res://ui/story_cards/story_cards.tscn"

@onready var _title: Label = %Title
@onready var _start_button: Button = %StartButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(get_tree().quit)
	_start_button.grab_focus()


func _process(_delta: float) -> void:
	# 標題像接觸不良的燈管，偶爾暗一下
	_title.modulate.a = 0.3 if randf() < 0.03 else 1.0


func _on_start_pressed() -> void:
	_start_button.disabled = true
	LevelManager.change_scene(FIRST_SCENE)
