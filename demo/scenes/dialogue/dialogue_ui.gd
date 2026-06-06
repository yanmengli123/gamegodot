## dialogue_ui.gd
## 对话 UI 控制器
##
## 节点：
##   DialogueUI (Control)
##   ├── Panel (PanelContainer)         对话框背景
##   │   └── Margin
##   │       └── VBox
##   │           ├── HBox
##   │           │   ├── PortraitPanel (TextureRect)
##   │           │   └── VBox
##   │           │       ├── SpeakerName (Label)
##   │           │       └── DialogueText (RichTextLabel)
##   └── ChoicesContainer (VBoxContainer) 选项列表
##
## 工作流：
##   - Dialogue.show_node → 显示文字 + 启动打字机
##   - Dialogue.show_choices → 渲染选项按钮
##   - Dialogue.dialogue_ended → 关闭整个 UI
##   - 按 confirm 推进 / 选选项；按 cancel 关闭
extends Control

const TYPEWRITER_INTERVAL: float = 0.03  # 每字符秒数

@onready var panel: PanelContainer = $Panel
@onready var portrait_panel: TextureRect = $Panel/Margin/VBox/HBox/PortraitPanel
@onready var speaker_name: Label = $Panel/Margin/VBox/HBox/VBox/SpeakerName
@onready var dialogue_text: RichTextLabel = $Panel/Margin/VBox/HBox/VBox/DialogueText
@onready var choices_container: VBoxContainer = $ChoicesContainer
@onready var continue_indicator: TextureRect = $ContinueIndicator

## 状态
var _full_text: String = ""
var _visible_text: String = ""
var _typewriter_acc: float = 0.0
var _is_typing: bool = false
var _current_choices: Array = []


func _ready() -> void:
	# 默认隐藏
	visible = false
	continue_indicator.visible = false
	choices_container.visible = false
	# 订阅
	Dialogue.show_node.connect(_on_show_node)
	Dialogue.show_choices.connect(_on_show_choices)
	Dialogue.hide_choices.connect(_on_hide_choices)
	Dialogue.typewriter_progress.connect(_on_typewriter_progress)
	Dialogue.dialogue_ended.connect(_on_dialogue_ended)
	# 全屏锚点
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP  # 拦截输入


func _process(delta: float) -> void:
	if not _is_typing:
		return
	_typewriter_acc += delta
	while _typewriter_acc >= TYPEWRITER_INTERVAL and not _is_typing_finished():
		_typewriter_acc -= TYPEWRITER_INTERVAL
		_advance_typewriter()
	_apply_text()
	if _is_typing_finished():
		_is_typing = false
		_apply_text()
		continue_indicator.visible = true


func _is_typing_finished() -> bool:
	return _visible_text.length() >= _full_text.length()


func _advance_typewriter() -> void:
	if _is_typing_finished():
		return
	var next_len: int = mini(_visible_text.length() + 1, _full_text.length())
	_visible_text = _full_text.substr(0, next_len)


func _apply_text() -> void:
	dialogue_text.text = _visible_text


# === 事件 ===
func _on_show_node(node: Dictionary, speaker_name_str: String, portrait: String) -> void:
	visible = true
	speaker_name.text = speaker_name_str
	_full_text = _replace_variables(node.get("text", ""))
	_visible_text = ""
	_typewriter_acc = 0.0
	_is_typing = true
	continue_indicator.visible = false
	choices_container.visible = false
	_refresh_portrait(portrait)
	_apply_text()


func _on_typewriter_progress(visible_text: String, finished: bool) -> void:
	# Dialogue.advance() 调用后强制完成打字
	if finished:
		_visible_text = _full_text
		_is_typing = false
		_apply_text()
		continue_indicator.visible = true


func _on_show_choices(choices: Array) -> void:
	# 清除旧选项
	for c in choices_container.get_children():
		c.queue_free()
	_current_choices = choices
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = "%d. %s" % [i + 1, choice.get("text", "")]
		btn.disabled = not choice.get("enabled", true)
		btn.focus_mode = Control.FOCUS_ALL
		if not choice.get("enabled", true) and not choice.get("reason", "").is_empty():
			btn.tooltip_text = choice.get("reason", "")
		# 点击回调
		var idx: int = i
		btn.pressed.connect(func(): Dialogue.make_choice(idx))
		choices_container.add_child(btn)
	choices_container.visible = true
	# 默认焦点第一个
	if choices_container.get_child_count() > 0:
		var first: Button = choices_container.get_child(0)
		if not first.disabled:
			first.grab_focus()


func _on_hide_choices() -> void:
	for c in choices_container.get_children():
		c.queue_free()
	choices_container.visible = false


func _on_dialogue_ended(_dialogue_id: StringName) -> void:
	visible = false
	_is_typing = false
	_full_text = ""
	_visible_text = ""
	_on_hide_choices()


func _refresh_portrait(_portrait: String) -> void:
	# 阶段三简化：用 PlaceholderTexture 生成纯色方块当头像
	# 阶段三下半：换成 NPC 实际的精灵缩略图
	portrait_panel.texture = PlaceholderTexture.solid(Color(0.4, 0.5, 0.6), 48, 48)


func _replace_variables(text: String) -> String:
	# Dialogue 已经替换过变量；这里保留 hook 供阶段八扩展（颜色高亮玩家名等）
	return text


# === 键盘输入 ===
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"interact"):
		if choices_container.visible and not _is_typing:
			# 选项可见时 confirm 触发当前焦点按钮
			var focused: Control = get_viewport().gui_get_focus_owner()
			if focused is Button:
				focused.emit_signal(&"pressed")
			get_viewport().set_input_as_handled()
		else:
			# 推进对话（若还在打字则完成打字）
			Dialogue.advance()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"cancel"):
		Dialogue.cancel()
		get_viewport().set_input_as_handled()
