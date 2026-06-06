## scene_manager.gd
## 场景切换 + 淡入淡出
extends Node

const _SELF := preload("res://core/autoload/scene_manager.gd")
const FADE_DURATION: float = 0.35

## 当前/上一个
var current_scene_id: StringName = &""
var previous_scene_id: StringName = &""
## 场景数据缓存
var _index: Dictionary = {}
## 玩家位置记忆 {scene_id: Vector2}
var _player_positions: Dictionary = {}
## 玩家朝向记忆
var _player_facings: Dictionary = {}


func _ready() -> void:
	EventBus.scene_about_to_change.connect(_on_scene_about_to_change)
	_build()


func _build() -> void:
	if not _index.is_empty(): return
	for s in SceneData.create_all():
		_index[String(s.scene_id)] = s


## 切换场景
func change_scene(scene_id: StringName, spawn_point: String = "default") -> void:
	_build()
	if not _index.has(String(scene_id)):
		push_error("Scene '%s' not found" % scene_id)
		return
	# 记忆当前位置/朝向（如果有玩家）
	_save_player_state()
	# 发信号
	EventBus.scene_about_to_change.emit(String(current_scene_id), String(scene_id))
	# 渐变
	_fade_out_then_change(scene_id, spawn_point)


func _fade_out_then_change(scene_id: StringName, spawn_point: String) -> void:
	var tween: Tween = create_tween()
	# 渐黑
	var rect: ColorRect = _get_or_create_transition_rect()
	rect.modulate.a = 0
	rect.visible = true
	tween.tween_property(rect, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_callback(_do_change.bind(scene_id, spawn_point))
	tween.tween_property(rect, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(func(): rect.visible = false)


func _do_change(scene_id: StringName, spawn_point: String) -> void:
	previous_scene_id = current_scene_id
	current_scene_id = scene_id
	var data: SceneData = _index[String(scene_id)]
	get_tree().change_scene_to_file(data.scene_path)
	# 等待一帧让新场景加载完，再设置玩家位置
	await get_tree().process_frame
	_restore_player_state(scene_id, spawn_point)
	EventBus.scene_changed.emit(String(scene_id))
	EventBus.scene_transition_finished.emit()


func _save_player_state() -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player_marker")
	if player == null: return
	# 不在此 autoload 直接访问 PlayerCharacter（避免循环引用）
	# 改用 PlayerData 里的全局位置
	# 简化：直接 get_tree().root 里找 Player
	var root: Node = get_tree().current_scene
	if root == null: return
	for child in root.get_children():
		if child.has_method(&"get_save_state"):
			var st: Dictionary = child.call(&"get_save_state")
			_player_positions[String(current_scene_id)] = st.get("global_position", Vector2.ZERO)
			_player_facings[String(current_scene_id)] = st.get("facing", 0)
			break


func _restore_player_state(scene_id: StringName, spawn_point: String) -> void:
	await get_tree().process_frame
	var root: Node = get_tree().current_scene
	if root == null: return
	var target_pos: Vector2
	var target_facing: int = -1
	if _player_positions.has(String(scene_id)):
		target_pos = _player_positions[String(scene_id)]
		target_facing = int(_player_facings.get(String(scene_id), -1))
	else:
		var data: SceneData = _index[String(scene_id)]
		target_pos = data.spawn_points.get(spawn_point, Vector2(320, 180))
	for child in root.get_children():
		if child.has_method(&"load_save_state"):
			var st: Dictionary = {
				"global_position": [target_pos.x, target_pos.y],
				"facing": target_facing,
			}
			child.call(&"load_save_state", st)
			break


func _on_scene_about_to_change(_from: String, _to: String) -> void:
	pass


func _get_or_create_transition_rect() -> ColorRect:
	var layer: CanvasLayer = get_tree().root.get_node_or_null("Main/TransitionLayer")
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "TransitionLayer"
		get_tree().root.add_child(layer)
	var rect: ColorRect = layer.get_node_or_null("TransitionRect") as ColorRect
	if rect == null:
		rect = ColorRect.new()
		rect.name = "TransitionRect"
		rect.color = Color.BLACK
		rect.anchor_left = 0
		rect.anchor_right = 1
		rect.anchor_top = 0
		rect.anchor_bottom = 1
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(rect)
	return rect


## 获取场景数据
func get_scene_data(scene_id: String) -> SceneData:
	_build()
	return _index.get(scene_id)


## 当前场景数据
func get_current_scene_data() -> SceneData:
	if String(current_scene_id).is_empty(): return null
	return get_scene_data(String(current_scene_id))


## 是否有此场景
func has_scene(scene_id: String) -> bool:
	_build()
	return _index.has(scene_id)
