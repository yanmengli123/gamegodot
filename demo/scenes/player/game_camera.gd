## game_camera.gd
## 主摄像机 — 跟随玩家 + 边界限制 + 临时聚焦 + 震动
##
## 用法：
##   - 作为 Player.tscn 的子节点自动跟随（player_path 指向同级 Player）
##   - 或外部调用 follow_target(node) 切换目标
##   - shake(intensity, duration) 受伤/爆炸时调用
##
## 设计：
## - 平滑用 lerp（不用 Camera2D 的 position_smoothing，因为我们要精确边界裁剪）
## - 边界是 Rect2i（像素对齐），限制摄像机不超过场景可走区域
## - 聚焦过渡用 Tween，结束时自动切回默认目标
extends Camera2D

# === 平滑参数 ===
const FOLLOW_LERP_NORMAL: float = 0.1
const FOLLOW_LERP_RUN: float = 0.18
const FOCUS_LERP: float = 0.06

# === 边界 ===
## Rect2i（像素坐标，god 摄像机移动范围）
var bounds: Rect2i = Rect2i(-1000000, -1000000, 2000000, 2000000)
## 视口大小（项目默认 640×360）
var viewport_size: Vector2i = Vector2i(640, 360)

# === 状态 ===
var _default_target: Node2D = null
var _focus_target: Node2D = null
var _shake_intensity: float = 0.0
var _shake_remaining: float = 0.0
var _shake_trauma: float = 0.0
var _shake_seed: float = 0.0


func _ready() -> void:
	# 像素完美：不要 zoom 抖动
	position_smoothing_enabled = false
	ignore_rotation = true
	# 视口拉大时自动调整
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()


func _on_viewport_size_changed() -> void:
	viewport_size = get_viewport().get_visible_rect().size
	# 缩放 = 窗口实际像素 / 视口 640×360
	# 不修改 zoom，让项目设置的 keep aspect 处理
	_clamp_to_bounds()


func _process(delta: float) -> void:
	var target_pos: Vector2 = global_position
	if _focus_target != null and is_instance_valid(_focus_target):
		target_pos = _focus_target.global_position
	elif _default_target != null and is_instance_valid(_default_target):
		# 玩家移动时用正常 lerp，奔跑时用更快
		var vel: Vector2 = Vector2.ZERO
		if _default_target is CharacterBody2D:
			vel = (_default_target as CharacterBody2D).velocity
		var speed_factor: float = clampf(vel.length() / 140.0, 0.0, 1.0)
		var t: float = lerpf(FOLLOW_LERP_NORMAL, FOLLOW_LERP_RUN, speed_factor)
		target_pos = global_position.lerp(_default_target.global_position, t)
	global_position = _clamp_to_bounds_vec(target_pos)
	# 震动
	if _shake_remaining > 0.0:
		_shake_remaining -= delta
		var trauma: float = _shake_trauma * _shake_trauma
		_shake_seed += delta * 60.0
		var shake_offset: Vector2 = Vector2(
			noise(_shake_seed) * trauma * _shake_intensity,
			noise(_shake_seed + 100.0) * trauma * _shake_intensity
		)
		global_position += shake_offset
		if _shake_remaining <= 0.0:
			_shake_trauma = 0.0


func noise(seed_v: float) -> float:
	# 简单值噪声替代 godot FastNoiseLite（避免 import 依赖）
	var s: float = sin(seed_v * 12.9898) * 43758.5453
	return (s - floorf(s)) * 2.0 - 1.0


# === 公开 API ===
func follow_target(target: Node2D) -> void:
	_default_target = target
	_focus_target = null


func focus_on(target: Node2D, duration: float = 0.0) -> void:
	_focus_target = target
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
		if _focus_target == target:
			_focus_target = null


func return_to_default() -> void:
	_focus_target = null


func set_bounds(rect: Rect2i) -> void:
	bounds = rect
	_clamp_to_bounds()


func shake(intensity: float = 4.0, duration: float = 0.3) -> void:
	_shake_intensity = intensity
	_shake_remaining = duration
	_shake_trauma = 1.0


# === 边界裁剪 ===
func _clamp_to_bounds() -> void:
	global_position = _clamp_to_bounds_vec(global_position)


func _clamp_to_bounds_vec(pos: Vector2) -> Vector2:
	# 摄像机不能超出 bounds + 视口半尺寸
	var half: Vector2 = viewport_size * 0.5 / zoom
	var min_x: float = float(bounds.position.x) + half.x
	var max_x: float = float(bounds.end.x) - half.x
	var min_y: float = float(bounds.position.y) + half.y
	var max_y: float = float(bounds.end.y) - half.y
	# 防止 bounds 比视口小导致 min > max
	if max_x < min_x:
		var mid_x: float = (float(bounds.position.x) + float(bounds.end.x)) * 0.5
		min_x = mid_x
		max_x = mid_x
	if max_y < min_y:
		var mid_y: float = (float(bounds.position.y) + float(bounds.end.y)) * 0.5
		min_y = mid_y
		max_y = mid_y
	return Vector2(clampf(pos.x, min_x, max_x), clampf(pos.y, min_y, max_y))
