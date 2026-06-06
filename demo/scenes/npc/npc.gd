## npc.gd
## NPC 角色 — 渲染、交互触发、行为 AI（基础）
##
## 行为 AI：阶段三只做"按时间段找 schedule 决定位置和动作"，阶段六/七扩展寻路
## 现在 schedule 触发时 NPC 瞬移到目标位置（无平滑）
class_name NPC
extends CharacterBody2D

@export var data: NPCData = null
@export var start_dialogue_id: StringName = &""

## 节点
@onready var sprite: Sprite2D = $Sprite2D
@onready var indicator: Sprite2D = $DialogueIndicator
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_shape: CollisionShape2D = $InteractionArea/InteractionShape
@onready var anim_player: AnimationPlayer = $AnimationPlayer

## 状态
enum State { IDLE, WALKING, WORKING, SLEEPING, TALKING }
var current_state: State = State.IDLE

## 上次日程更新（小时）
var _last_schedule_hour: int = -1


func _ready() -> void:
	# 加入 interactable 组（Player 扫描时会找到）
	add_to_group(&"interactable")
	# 刷新外观
	_refresh_sprite()
	# 订阅时间变化
	EventBus.hour_tick.connect(_on_hour_tick)
	# 立即按当前时段跑一次日程
	_apply_schedule_for(TimeMgr.period)


func _process(_delta: float) -> void:
	# 玩家在范围内时显示「！」提示
	var in_range: bool = false
	for body in interaction_area.get_overlapping_bodies():
		if body.is_in_group(&"player_marker"):
			in_range = true
			break
	indicator.visible = in_range and data != null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and _player_nearby():
		_on_player_interact()


func _player_nearby() -> bool:
	for body in interaction_area.get_overlapping_bodies():
		if body.is_in_group(&"player_marker"):
			return true
	return false


func _on_player_interact() -> void:
	if data == null:
		return
	current_state = State.TALKING
	# 优先用 schedule 提供的 dialogue
	var dlg_id: StringName = start_dialogue_id
	if dlg_id.is_empty():
		dlg_id = data.default_dialogue_id
	# 阶段六扩展：好感度阈值切换 dialogue
	# 当前用 affinity_dialogues 中最大的满足项
	if data != null and not data.affinity_dialogues.is_empty():
		var affinity: int = Player.get_affinity(String(data.npc_id))
		var best_match: int = -1
		for threshold_v in data.affinity_dialogues.keys():
			var t: int = int(threshold_v)
			if affinity >= t and t > best_match:
				best_match = t
		if best_match >= 0:
			dlg_id = StringName(data.affinity_dialogues[best_match])
	if not dlg_id.is_empty():
		Dialogue.start_dialogue(dlg_id, data.npc_id)
		# 注册"今日已交互次数"（阶段四经济系统会用到）
		_remember_interaction()


func _remember_interaction() -> void:
	if data == null:
		return
	if not Player.known_npcs.has(String(data.npc_id)):
		Player.known_npcs[String(data.npc_id)] = {
			"affinity": 30,
			"last_meeting_day": 0,
			"meetings_today": 0,
		}
	var entry: Dictionary = Player.known_npcs[String(data.npc_id)]
	if entry.get("last_meeting_day", 0) != TimeMgr.day:
		entry["meetings_today"] = 0
		entry["last_meeting_day"] = TimeMgr.day
	entry["meetings_today"] = entry.get("meetings_today", 0) + 1


# === 日程系统 ===
func _on_hour_tick(_h: int) -> void:
	_apply_schedule_for(TimeMgr.period)


func _apply_schedule_for(period: int) -> void:
	if data == null:
		return
	# 找匹配 period 的 schedule
	for entry in data.schedules:
		if entry.period == period:
			_do_schedule_action(entry)
			return
	# 没匹配 → 保持现状（默认 IDLE）


func _do_schedule_action(entry: NPCScheduleData) -> void:
	# 移动到目标位置（瞬移，阶段六加 NavigationAgent2D）
	if entry.target_position != Vector2.ZERO:
		global_position = entry.target_position
	match entry.action:
		NPCScheduleData.Action.IDLE:
			current_state = State.IDLE
		NPCScheduleData.Action.WALK_TO:
			current_state = State.WALKING
		NPCScheduleData.Action.WORK:
			current_state = State.WORKING
		NPCScheduleData.Action.EAT:
			current_state = State.IDLE
		NPCScheduleData.Action.SLEEP:
			current_state = State.SLEEPING
		NPCScheduleData.Action.TALK:
			current_state = State.IDLE


# === 外观 ===
func _refresh_sprite() -> void:
	if sprite == null or data == null:
		return
	# 阶段三：用 data.sprite_seed + 一些扰动生成"另一个像素人"
	var skin: Color = data.sprite_seed
	var hair: Color = data.sprite_seed.darkened(0.3)
	var shirt: Color = data.sprite_seed.lightened(0.2)
	var pants: Color = data.sprite_seed.darkened(0.5)
	sprite.texture = PlaceholderTexture.pixel_character(skin, hair, shirt, pants)
	sprite.centered = true


# === 兼容 Player 的交互 API ===
func is_interactable() -> bool:
	return data != null


func get_area_name() -> String:
	return "npc_%s" % String(data.npc_id) if data else "npc"
