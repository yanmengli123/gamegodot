## notification_manager.gd
## 通知系统 — 顶部弹出、队列管理、颜色分类
extends Node

const _SELF := preload("res://core/autoload/notification_manager.gd")
const QUEUE_INTERVAL: float = 2.5

enum Category { INFO, SUCCESS, WARNING, DANGER, ACHIEVEMENT }

const CATEGORY_COLOR := {
	Category.INFO: Color(0.4, 0.7, 1.0),
	Category.SUCCESS: Color(0.3, 0.9, 0.4),
	Category.WARNING: Color(1.0, 0.85, 0.2),
	Category.DANGER: Color(0.95, 0.3, 0.3),
	Category.ACHIEVEMENT: Color(1.0, 0.8, 0.3),
}

var _queue: Array[Dictionary] = []  # [{category, text}]
var _showing: bool = false
var _ui_root: CanvasLayer = null
var _current_label: Label = null


func _ready() -> void:
	# 延一帧，等 root 准备好
	call_deferred("_build_ui")
	EventBus.notification_requested.connect(_on_notification_requested)


func _build_ui() -> void:
	_ui_root = CanvasLayer.new()
	_ui_root.layer = 100
	_ui_root.name = "NotificationLayer"
	get_tree().root.add_child(_ui_root)
	var center: CenterContainer = CenterContainer.new()
	center.anchor_left = 0
	center.anchor_right = 1
	center.anchor_top = 0
	center.offset_top = 4
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 28)
	panel.visible = false
	center.add_child(panel)
	_current_label = Label.new()
	_current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_current_label.add_theme_font_size_override("font_size", 10)
	panel.add_child(_current_label)
	# 添加一个 StyleBox
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", style)


func _on_notification_requested(category: int, text: String) -> void:
	_queue.append({"category": category, "text": text})
	if not _showing:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		if _current_label.get_parent() is PanelContainer:
			(_current_label.get_parent() as PanelContainer).visible = false
		return
	_showing = true
	var item: Dictionary = _queue.pop_front()
	var cat: int = int(item.get("category", Category.INFO))
	_current_label.text = item.get("text", "")
	_current_label.modulate = CATEGORY_COLOR.get(cat, Color.WHITE)
	(_current_label.get_parent() as PanelContainer).visible = true
	# 队列间隔
	get_tree().create_timer(QUEUE_INTERVAL).timeout.connect(_show_next)


## 浮动数字（+5 / -10）— 简化版：直接在玩家位置显示 Label
func show_floating_number(world_pos: Vector2, text: String, color: Color) -> void:
	if _ui_root == null: return
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.modulate = color
	label.position = world_pos - Vector2(20, 0)
	_ui_root.add_child(label)
	var tween: Tween = create_tween()
	tween.set_parallel()
	tween.tween_property(label, "position:y", world_pos.y - 30, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
