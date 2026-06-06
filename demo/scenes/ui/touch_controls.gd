## touch_controls.gd
## 移动端虚拟摇杆 + 按钮
##
## 节点（Control，full rect）：
##   TouchControls
##   ├── Joystick (Control, 左下角 100x100)
##   │   ├── JoystickBase (TextureRect, 100x100, 圆形)
##   │   └── JoystickKnob (TextureRect, 40x40, 跟随触摸位置)
##   ├── InteractButton (Button, 右下角 "E")
##   ├── MenuButton (Button, 右上角 "M")
##   ├── MapButton (Button, 右上角 "T")
##   └── PhoneButton (Button, 右上角 "P")
##
## 工作流：玩家在 Joystick 上拖动 → 发送 input_axis 信号
## Player 接收 input_axis → 等同于 WASD 按键
extends Control

@onready var joystick_base: TextureRect = $Joystick/JoystickBase
@onready var joystick_knob: TextureRect = $Joystick/JoystickKnob
@onready var interact_btn: Button = $InteractButton
@onready var menu_btn: Button = $MenuButton
@onready var map_btn: Button = $MapButton
@onready var phone_btn: Button = $PhoneButton
@onready var sprint_btn: Button = $SprintButton

const JOYSTICK_RADIUS: float = 50.0
const KNOB_RADIUS: float = 20.0

var _dragging: bool = false
var _touch_index: int = -1

signal input_axis(axis: Vector2)
var current_axis: Vector2 = Vector2.ZERO


func _ready() -> void:
	# 默认隐藏（桌面端不需要）
	visible = false
	_refresh_visibility()
	get_window().size_changed.connect(_refresh_visibility)
	# 按钮回调
	interact_btn.pressed.connect(_on_interact_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	map_btn.pressed.connect(_on_map_pressed)
	phone_btn.pressed.connect(_on_phone_pressed)
	sprint_btn.button_down.connect(func(): _set_sprint(true))
	sprint_btn.button_up.connect(func(): _set_sprint(false))
	# 调试
	print("TouchControls initialized. Mobile: %s" % OS.has_feature("mobile"))


func _refresh_visibility() -> void:
	# 移动端或窗口极小时才显示
	visible = OS.has_feature("mobile") or OS.has_feature("web")


func _unhandled_input(event: InputEvent) -> void:
	# 仅在移动端或显式启用时处理
	if not visible: return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# 开始拖动（如果触摸点在 Joystick 范围内）
		var local_pos: Vector2 = _to_local(event.position)
		if _is_in_joystick(local_pos):
			_dragging = true
			_touch_index = event.index
			_update_knob(local_pos)
	else:
		if event.index == _touch_index:
			_dragging = false
			_touch_index = -1
			current_axis = Vector2.ZERO
			_knob_reset()
			input_axis.emit(Vector2.ZERO)


func _handle_drag(event: InputEventScreenDrag) -> void:
	if not _dragging or event.index != _touch_index: return
	var local_pos: Vector2 = _to_local(event.position)
	_update_knob(local_pos)


func _to_local(global_pos: Vector2) -> Vector2:
	return global_pos - joystick_base.global_position


func _is_in_joystick(local_pos: Vector2) -> bool:
	return local_pos.length() <= JOYSTICK_RADIUS * 1.5


func _update_knob(local_pos: Vector2) -> void:
	# 限制在半径内
	var clamped: Vector2 = local_pos
	if clamped.length() > JOYSTICK_RADIUS:
		clamped = clamped.normalized() * JOYSTICK_RADIUS
	joystick_knob.position = Vector2(JOYSTICK_RADIUS - KNOB_RADIUS, JOYSTICK_RADIUS - KNOB_RADIUS) + clamped
	# 计算 axis（-1..1）
	current_axis = clamped / JOYSTICK_RADIUS
	input_axis.emit(current_axis)


func _knob_reset() -> void:
	joystick_knob.position = Vector2(JOYSTICK_RADIUS - KNOB_RADIUS, JOYSTICK_RADIUS - KNOB_RADIUS)


func _on_interact_pressed() -> void:
	# 模拟 interact 按键
	var ev := InputEventAction.new()
	ev.action = &"interact"
	ev.pressed = true
	Input.parse_input_event(ev)


func _on_menu_pressed() -> void:
	var ev := InputEventAction.new()
	ev.action = &"open_menu"
	ev.pressed = true
	Input.parse_input_event(ev)


func _on_map_pressed() -> void:
	var ev := InputEventAction.new()
	ev.action = &"open_map"
	ev.pressed = true
	Input.parse_input_event(ev)


func _on_phone_pressed() -> void:
	var ev := InputEventAction.new()
	ev.action = &"open_phone"
	ev.pressed = true
	Input.parse_input_event(ev)


func _set_sprint(pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = &"sprint"
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _process(_delta: float) -> void:
	# 把 joystick axis 映射到 move_left/right/up/down
	if not _dragging: return
	var a: Vector2 = current_axis
	_set_move(&"move_left", a.x < -0.3)
	_set_move(&"move_right", a.x > 0.3)
	_set_move(&"move_up", a.y < -0.3)
	_set_move(&"move_down", a.y > 0.3)


func _set_move(action: StringName, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)
