## player.gd
## 玩家角色 — 移动、动画、交互、外观
##
## 节点结构（见 Player.tscn）：
##   Player (CharacterBody2D)            <-- 本脚本
##   ├── Sprite2D                       渲染外观
##   ├── CollisionShape2D               物理碰撞
##   ├── InteractionArea (Area2D)       交互检测
##   │   └── CollisionShape2D
##   ├── FootstepTimer (Timer)          脚步声节拍
##   ├── AnimationPlayer                帧动画状态机
##   └── StateLabel (Label, 可选)       调试用
##
## 关键设计：
## - 移动用 CharacterBody2D.move_and_slide()（自带滑墙）
## - 动画不用 AnimationPlayer 的 timeline，而是程序化 swap texture（避免美术依赖）
## - 交互：InteractionArea 用 area_entered/exited 维护 interactable 列表，按确认键发 interact_requested(target)
## - 体力消耗在 _physics_process 里；与 PlayerData.stamina 解耦，避免在 _process 里做重量级运算
##
## 信号（供外部订阅）：
##   direction_changed(facing)        朝向改变
##   interact_requested(target)       请求交互某目标
##   area_entered_name(area_name)     进入区域（门/区域触发器用）
##   moved(world_pos)                  每帧移动事件（脚步声/事件触发用）
extends CharacterBody2D

# === 朝向 ===
enum Facing { DOWN, UP, LEFT, RIGHT }
const FACING_VECTORS: Dictionary = {
	Facing.DOWN: Vector2(0, 1),
	Facing.UP: Vector2(0, -1),
	Facing.LEFT: Vector2(-1, 0),
	Facing.RIGHT: Vector2(1, 0),
}

# === 移动参数 ===
const SPEED_WALK: float = 80.0
const SPEED_RUN: float = 140.0
const STAMINA_DRAIN_PER_SEC_RUN: float = 0.5  # 奔跑每秒消耗体力
const LOW_STAMINA_THRESHOLD: int = 10
const LOW_STAMINA_SPEED_MULT: float = 0.5      # 体力<10 时移速减半

# === 节点引用（@onready 在 _ready 时填充，避免 _process 中查找）===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var footstep_timer: Timer = $FootstepTimer
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# === 状态 ===
var current_facing: Facing = Facing.DOWN:
	set(v):
		if current_facing != v:
			current_facing = v
			direction_changed.emit(v)
var is_moving: bool = false
var is_running: bool = false
var movement_enabled: bool = true  # 对话/菜单时禁用

# === 交互 ===
## 当前可交互目标（最近优先）
var current_interactable: Node = null
## InteractionArea 进入的所有可交互体（用于最近优先）
var _interactable_candidates: Array[Node] = []

# === 外观 ===
var appearance: PlayerAppearance = PlayerAppearance.default_appearance():
	set(v):
		appearance = v
		_refresh_sprite()
		appearance_changed.emit(v)

# === 动画状态 ===
var _anim_time: float = 0.0
const ANIM_FPS_WALK: float = 8.0
const ANIM_FPS_RUN: float = 12.0
const ANIM_FRAME_COUNT: int = 4  # 0,1,2,1 = 4 帧循环

# === 信号 ===
signal direction_changed(facing: int)
signal interact_requested(target: Node)
signal player_entered_area(area_name: String)
signal player_exited_area(area_name: String)
signal moved(world_position: Vector2)
signal appearance_changed(appearance: PlayerAppearance)
signal stamina_consumed(amount: float)


func _ready() -> void:
	footstep_timer.timeout.connect(_on_footstep_tick)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	interaction_area.body_entered.connect(_on_interaction_body_entered)
	interaction_area.body_exited.connect(_on_interaction_body_exited)
	# 启动时刷新一次贴图
	_refresh_sprite()


func _physics_process(delta: float) -> void:
	_update_movement(delta)
	_update_animation(delta)
	_update_interaction_target()


# === 移动 ===
func _update_movement(delta: float) -> void:
	if not movement_enabled or Game.current_state != Game.State.EXPLORING:
		velocity = Vector2.ZERO
		move_and_slide()
		is_moving = false
		return
	# 输入向量
	var input_vec: Vector2 = Vector2(
		Input.get_axis(&"move_left", &"move_right"),
		Input.get_axis(&"move_up", &"move_down")
	)
	# 八方向保留对角线
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()
	# 奔跑判断
	is_running = Input.is_action_pressed(&"sprint") and input_vec != Vector2.ZERO and Player.stamina > 0
	# 体力低时减速
	var speed: float = SPEED_RUN if is_running else SPEED_WALK
	if Player.stamina <= LOW_STAMINA_THRESHOLD:
		speed *= LOW_STAMINA_SPEED_MULT
	velocity = input_vec * speed
	# 像素 snap（项目设置已全局开，这里冗余保证）
	move_and_slide()
	# 朝向
	if input_vec != Vector2.ZERO:
		is_moving = true
		_update_facing_from_input(input_vec)
		# 体力消耗
		if is_running:
			var drain: float = STAMINA_DRAIN_PER_SEC_RUN * delta
			Player.stamina = max(0, Player.stamina - int(ceil(drain)))
			stamina_consumed.emit(drain)
		# 移动事件
		moved.emit(global_position)
	else:
		is_moving = false


func _update_facing_from_input(input_vec: Vector2) -> void:
	# 优先考虑水平分量（避免上下/对角抖动）
	if absf(input_vec.x) > absf(input_vec.y):
		current_facing = Facing.RIGHT if input_vec.x > 0 else Facing.LEFT
	else:
		current_facing = Facing.DOWN if input_vec.y > 0 else Facing.UP


# === 动画（程序化帧切换）===
func _update_animation(delta: float) -> void:
	if not is_moving:
		_anim_time = 0.0
		_apply_frame(1)  # 静止帧（腿并拢）
		return
	var fps: float = ANIM_FPS_RUN if is_running else ANIM_FPS_WALK
	_anim_time += delta * fps
	# 4 帧循环：0 → 1 → 2 → 1 → 0
	var frame: int = int(_anim_time) % ANIM_FRAME_COUNT
	if frame == 3:
		frame = 1
	_apply_frame(frame)


func _apply_frame(frame: int) -> void:
	# 阶段二简化：直接用外观基色，不做腿部分离
	# 通过 sprite.position 模拟腿摆动（y 偏移 0/-1 像素）
	if is_moving:
		sprite.position = Vector2(0, -1 if frame == 0 or frame == 2 else 0)
	else:
		sprite.position = Vector2.ZERO


# === 交互 ===
func _on_interaction_area_entered(area: Area2D) -> void:
	_add_candidate(area)

func _on_interaction_area_exited(area: Area2D) -> void:
	_remove_candidate(area)

func _on_interaction_body_entered(body: Node) -> void:
	_add_candidate(body)

func _on_interaction_body_exited(body: Node) -> void:
	_remove_candidate(body)

func _add_candidate(node: Node) -> void:
	# 必须标记为 interactable 组或实现 is_interactable()
	if not _is_interactable(node):
		return
	if not _interactable_candidates.has(node):
		_interactable_candidates.append(node)
	# 区域事件
	if node.has_method(&"get_area_name"):
		var area_name: String = node.call(&"get_area_name")
		if not area_name.is_empty():
			player_entered_area.emit(area_name)

func _remove_candidate(node: Node) -> void:
	_interactable_candidates.erase(node)
	if node.has_method(&"get_area_name"):
		var area_name: String = node.call(&"get_area_name")
		if not area_name.is_empty():
			player_exited_area.emit(area_name)

func _is_interactable(node: Node) -> bool:
	if not is_instance_valid(node):
		return false
	if node.is_in_group(&"interactable"):
		return true
	if node.has_method(&"is_interactable") and node.call(&"is_interactable"):
		return true
	return false

func _update_interaction_target() -> void:
	# 找最近的 interactable
	var best: Node = null
	var best_dist: float = INF
	for node in _interactable_candidates:
		if not is_instance_valid(node):
			continue
		var d: float = global_position.distance_to(_target_pos_of(node))
		if d < best_dist:
			best_dist = d
			best = node
	if best != current_interactable:
		current_interactable = best
		# TODO 阶段八：头顶显示「！」提示

func _target_pos_of(node: Node) -> Vector2:
	if node is Node2D:
		return (node as Node2D).global_position
	return global_position

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact"):
		if current_interactable != null and is_instance_valid(current_interactable):
			interact_requested.emit(current_interactable)


# === 脚步声 ===
func _on_footstep_tick() -> void:
	# 阶段九：接入 AudioManager 播放脚步声
	# 当前先空实现
	pass


# === 外观 ===
func _refresh_sprite() -> void:
	if sprite == null:
		return
	sprite.texture = PlaceholderTexture.pixel_character(
		appearance.skin_tone,
		appearance.hair_color,
		appearance.shirt_color,
		appearance.pants_color
	)
	# 居中（角色中心略偏下让头在上）
	sprite.centered = true
	sprite.position = Vector2.ZERO


# === 公开 API ===
func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled

func teleport_to(pos: Vector2, facing: Variant = null) -> void:
	global_position = pos
	if facing != null:
		current_facing = facing

func set_appearance(app: PlayerAppearance) -> void:
	appearance = app

func get_facing_vector() -> Vector2:
	return FACING_VECTORS[current_facing]


# === 序列化 ===
func get_save_state() -> Dictionary:
	return {
		"global_position": [global_position.x, global_position.y],
		"facing": current_facing,
		"appearance": appearance.to_dict(),
	}

func load_save_state(state: Dictionary) -> void:
	var pos: Array = state.get("global_position", [320.0, 180.0])
	global_position = Vector2(pos[0], pos[1])
	current_facing = state.get("facing", Facing.DOWN)
	var app := PlayerAppearance.new()
	app.from_dict(state.get("appearance", {}))
	appearance = app
