## event_data.gd
## 事件数据
class_name EventData
extends Resource

enum Type { MAIN, SIDE, RANDOM, DAILY, CRISIS, SEASONAL }
enum TriggerType { TIME_BASED, LOCATION_BASED, STAT_BASED, AFFINITY_BASED, FLAG_BASED, COMBINED }

@export var event_id: StringName = &""
@export var event_name: String = ""
@export var event_type: int = Type.RANDOM
@export var trigger_type: int = TriggerType.TIME_BASED
## 触发条件
## { "time": [start_hour, end_hour], "day_of_week": [5,6], "flag": "name", "money_min": int, "weather": int, "season": int }
@export var trigger_conditions: Dictionary = {}
## 发生地点
@export var location: StringName = &""
## 优先级
@export var priority: int = 0
## 可重复
@export var repeatable: bool = false
## 冷却天数
@export var cooldown: int = 0
## 关联对话
@export var dialogue_id: StringName = &""
## 奖励 {money: int, item: {id, qty}, stat: {stat, delta}, flag: {id, value}}
@export var rewards: Dictionary = {}
## 后果（可能负面）{stat: {stat, delta}, money: int, flag: {id, value}}
@export var consequences: Dictionary = {}
## 后续事件链（按选项跳转）
@export var choices: Array = []


## 检查触发条件
func check_conditions(ctx: Dictionary) -> bool:
	var cond: Dictionary = trigger_conditions
	# 时间窗口
	if cond.has("time"):
		var arr: Array = cond["time"]
		if arr.size() >= 2:
			var s: int = int(arr[0])
			var e: int = int(arr[1])
			if not (TimeMgr.hour >= s and TimeMgr.hour <= e):
				return false
	# 星期
	if cond.has("day_of_week"):
		var days: Array = cond["day_of_week"]
		if not days.has(TimeMgr.total_days % 7):
			return false
	# flag
	if cond.has("flag"):
		if not Player.has_flag(String(cond["flag"])):
			return false
	# money_min
	if cond.has("money_min"):
		if Player.cash < int(cond["money_min"]):
			return false
	# weather
	if cond.has("weather"):
		if WeatherManager.current_weather != int(cond["weather"]):
			return false
	# season
	if cond.has("season"):
		if TimeMgr.season != int(cond["season"]):
			return false
	return true
