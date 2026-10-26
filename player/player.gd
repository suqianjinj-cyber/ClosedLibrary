extends CharacterBody3D
## 第一人稱玩家：滑鼠視角、走路、奔跑、蹲下。
## 之後的喘氣值、聲音、躲藏系統會讀取 is_running 與 is_crouching。

@export_group("移動速度（公尺／秒）")
@export var walk_speed := 2.5
@export var run_speed := 4.5
@export var crouch_speed := 1.2
## 加速與減速的快慢，數字越大越靈敏
@export var acceleration := 12.0

@export_group("身高（公尺）")
@export var stand_height := 1.7
@export var crouch_height := 1.0
## 眼睛與頭頂的距離
@export var eye_offset := 0.12
## 站起／蹲下的速度（公尺／秒）
@export var crouch_transition_speed := 4.0
## 勾選：按一下蹲下、再按一下站起；不勾選：按住才蹲
@export var crouch_is_toggle := false

@export_group("視角")
@export var mouse_sensitivity := 0.0025
## 抬頭與低頭的最大角度
@export var max_look_angle := 85.0

var is_running := false
var is_crouching := false
## 手機手電筒是否開著（館員 AI 會讀取：開著比較容易被發現）
var flashlight_on := false
var _battery_empty := false

var _current_height := 0.0
var _crouch_toggled := false
var _current_interactable: Interactable = null

@onready var _head: Node3D = $Head
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _capsule: CapsuleShape3D = _collision.shape
@onready var _interact_ray: RayCast3D = $Head/InteractRay
@onready var _flashlight: SpotLight3D = $Head/Flashlight


func _ready() -> void:
	_current_height = stand_height
	_apply_height()
	_interact_ray.add_exception(self)
	_flashlight.visible = false
	EventBus.battery_depleted.connect(_on_battery_depleted)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func set_flashlight(on: bool) -> void:
	if on and _battery_empty:
		return
	flashlight_on = on
	_flashlight.visible = on
	EventBus.flashlight_toggled.emit(on)


func _on_battery_depleted() -> void:
	_battery_empty = true
	set_flashlight(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _current_interactable:
		_current_interactable.interact()
	elif event.is_action_pressed("flashlight"):
		set_flashlight(not flashlight_on)
	elif event.is_action_pressed("ui_cancel"):
		# ESC：放開滑鼠
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# 點一下畫面：重新鎖定滑鼠
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		var limit := deg_to_rad(max_look_angle)
		_head.rotation.x = clampf(_head.rotation.x, -limit, limit)


func _physics_process(delta: float) -> void:
	_update_crouch(delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	# 只有往前走、沒有蹲下時才能跑
	is_running = Input.is_action_pressed("run") and not is_crouching and input_dir.y < 0.0

	var speed := walk_speed
	if is_crouching:
		speed = crouch_speed
	elif is_running:
		speed = run_speed

	var target_velocity := direction * speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	move_and_slide()
	_update_interaction()


func _update_interaction() -> void:
	# 準心前方 2 公尺內有可互動物件就顯示提示（牆壁會擋住）
	var target: Interactable = null
	if _interact_ray.is_colliding():
		target = _interact_ray.get_collider() as Interactable
	if target != _current_interactable:
		_current_interactable = target
		EventBus.interaction_prompt_changed.emit(target.prompt_text if target else "")


func _update_crouch(delta: float) -> void:
	var wants_crouch: bool
	if crouch_is_toggle:
		if Input.is_action_just_pressed("crouch"):
			_crouch_toggled = not _crouch_toggled
		wants_crouch = _crouch_toggled
	else:
		wants_crouch = Input.is_action_pressed("crouch")

	# 頭上有東西（例如在櫃檯下）時，放開蹲下鍵也站不起來
	if not wants_crouch and is_crouching and not _can_stand_up():
		wants_crouch = true
	is_crouching = wants_crouch

	var target_height := crouch_height if is_crouching else stand_height
	if not is_equal_approx(_current_height, target_height):
		_current_height = move_toward(_current_height, target_height, crouch_transition_speed * delta)
		_apply_height()


func _can_stand_up() -> bool:
	var rise := stand_height - _current_height
	return not test_move(global_transform, Vector3.UP * rise)


func _apply_height() -> void:
	# 腳底固定在地面，身體往上長或往下縮
	_capsule.height = _current_height
	_collision.position.y = _current_height * 0.5
	_head.position.y = _current_height - eye_offset
