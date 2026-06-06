## job_data.gd
## 职业/工作数据
class_name JobData
extends Resource

enum JobType { DAILY, PART_TIME, FULL_TIME, FREELANCE, ILLEGAL }

@export var job_id: StringName = &""
@export var job_name: String = ""
@export var job_type: int = JobType.DAILY
@export var description: String = ""
## 工作地点场景 ID
@export var location: StringName = &""
## 开始时间（小时 0-23）
@export var start_hour: int = 8
## 持续小时
@export var duration_hours: int = 8
## 日薪（人民币）
@export var pay_per_day: int = 0
## 月薪（仅全职）
@export var pay_per_month: int = 0
## 工作要求属性：{stat: min_value}
@export var stat_requirements: Dictionary = {}
## 工作后获得的能力值：{stat: delta}
@export var stat_gains: Dictionary = {}
## 工作消耗：{stat: delta}（通常是负数）
@export var stat_costs: Dictionary = {}
## 解锁条件：{flag_id, level, ...}
@export var unlock_condition: Dictionary = {}
## 雨天/雪天是否取消
@export var weather_sensitive: bool = false
## 晋升链（由低到高）
@export var promotion_chain: PackedStringArray = PackedStringArray()


## 玩家是否能接受这份工作
func is_available() -> bool:
	# 等级要求（unlock_condition.level）
	if unlock_condition.has("level"):
		var req_level: int = int(unlock_condition["level"])
		# 阶段五：玩家没有"等级"，按累计工作天数算
		if Player.current_job_days_worked < req_level:
			return false
	# 剧情 flag
	if unlock_condition.has("flag"):
		if not Player.has_flag(String(unlock_condition["flag"])):
			return false
	# 属性要求
	for stat in stat_requirements:
		var need: int = int(stat_requirements[stat])
		var have: int = _get_stat(String(stat))
		if have < need:
			return false
	return true


static func _get_stat(stat: String) -> int:
	match stat:
		"strength": return Player.strength
		"intelligence": return Player.intelligence
		"eloquence": return Player.eloquence
		"craft": return Player.craft
		"charm": return Player.charm
		"stamina": return Player.stamina
	return 0


## 类型名
static func type_name(t: int) -> String:
	match t:
		JobType.DAILY: return "日结"
		JobType.PART_TIME: return "兼职"
		JobType.FULL_TIME: return "全职"
		JobType.FREELANCE: return "自由职业"
		JobType.ILLEGAL: return "违法"
	return "未知"
