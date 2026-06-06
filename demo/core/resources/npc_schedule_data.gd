## npc_schedule_data.gd
## NPC 日程表 — 一个 entry 定义"在哪个时段/场景/做什么"
## 配合 TimeManager.Period 枚举使用
class_name NPCScheduleData
extends Resource

enum Action { IDLE, WALK_TO, WORK, EAT, SLEEP, TALK }

@export var period: int = 0  # TimeManager.Period
@export var scene_id: StringName = &""
@export var target_position: Vector2 = Vector2.ZERO
@export var action: int = Action.IDLE
@export var dialogue_id: StringName = &""  # 该时段遇到时优先触发的对话


func to_dict() -> Dictionary:
	return {
		"period": period,
		"scene_id": String(scene_id),
		"target_position": [target_position.x, target_position.y],
		"action": action,
		"dialogue_id": String(dialogue_id),
	}
