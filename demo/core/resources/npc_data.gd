## npc_data.gd
## NPC 数据资源 — 定义一个 NPC 的所有静态信息
## 运行时状态（好感度、当前对话）存在 PlayerData.known_npcs 里，不存在这里
class_name NPCData
extends Resource

enum AffinityTier { HOSTILE, COLD, NEUTRAL, FRIENDLY, INTIMATE, SOULMATE }

@export var npc_id: StringName = &""
@export var display_name: String = ""
@export var age: int = 30
@export var gender: String = "男"  # 仅显示
@export var occupation: String = ""
@export var personality_tags: PackedStringArray = PackedStringArray()  # ["友善", "话少"]
@export var sprite_seed: Color = Color(0.7, 0.6, 0.5)  # 像素精灵基础色

## 默认对话 ID（首次见面）
@export var default_dialogue_id: StringName = &""
## 好感度阈值触发的对话（key = threshold int, value = dialogue_id）
@export var affinity_dialogues: Dictionary = {}
## NPC 可能在的场景 ID 列表
@export var possible_scenes: PackedStringArray = PackedStringArray()
## 每场景的日程表
@export var schedules: Array[Resource] = []

## 好感度等级（阶段三用）
static func affinity_tier(affinity: int) -> AffinityTier:
	if affinity <= 10: return AffinityTier.HOSTILE
	if affinity <= 30: return AffinityTier.COLD
	if affinity <= 50: return AffinityTier.NEUTRAL
	if affinity <= 70: return AffinityTier.FRIENDLY
	if affinity <= 90: return AffinityTier.INTIMATE
	return AffinityTier.SOULMATE

static func tier_name(tier: AffinityTier) -> String:
	match tier:
		AffinityTier.HOSTILE: return "敌对"
		AffinityTier.COLD: return "冷淡"
		AffinityTier.NEUTRAL: return "中立"
		AffinityTier.FRIENDLY: return "友好"
		AffinityTier.INTIMATE: return "亲密"
		AffinityTier.SOULMATE: return "至交"
	return "未知"

## 序列化为字典
func to_dict() -> Dictionary:
	var arr: Array = []
	for s in schedules:
		if s is NPCScheduleData:
			arr.append(s.to_dict())
		elif s is Resource and s.has_method(&"to_dict"):
			arr.append(s.call(&"to_dict"))
	return {
		"npc_id": String(npc_id),
		"display_name": display_name,
		"age": age,
		"gender": gender,
		"occupation": occupation,
		"personality_tags": Array(personality_tags),
		"sprite_seed": [sprite_seed.r, sprite_seed.g, sprite_seed.b, sprite_seed.a],
		"default_dialogue_id": String(default_dialogue_id),
		"affinity_dialogues": affinity_dialogues,
		"possible_scenes": Array(possible_scenes),
		"schedules": arr,
	}
