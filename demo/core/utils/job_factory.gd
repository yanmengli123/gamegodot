## job_factory.gd
## 10 个职业数据
class_name JobFactory
extends RefCounted

const _Self := preload("res://core/utils/job_factory.gd")


static func create_all() -> Array[JobData]:
	return [
		# === 日结工（无门槛）===
		_make(&"job_brick", "搬砖工", JobData.JobType.DAILY, "industrial_site", 7, 8, 100, {},
			{"strength": 1}, {"stamina": -30, "hunger": -20}),
		_make(&"job_flyer", "发传单", JobData.JobType.DAILY, "old_town_street", 9, 4, 60, {},
			{"eloquence": 1}, {"stamina": -10, "hunger": -15}, true),  # 雨天取消
		_make(&"job_dishwasher", "餐厅洗碗", JobData.JobType.DAILY, "old_town_market", 10, 6, 75, {},
			{"craft": 1}, {"stamina": -15, "hunger": -5}, false, false, true),  # 包一顿饭
		_make(&"job_cafe_assistant", "网吧代练", JobData.JobType.DAILY, "internet_cafe", 14, 4, 150, {"intelligence": 20},
			{"intelligence": 1}, {"mood": -5, "stamina": -5}),

		# === 兼职 ===
		_make(&"job_courier", "快递员", JobData.JobType.PART_TIME, "industrial_site", 8, 8, 150, {"strength": 30},
			{"strength": 1}, {"stamina": -25, "hunger": -20}),
		_make(&"job_waiter", "餐厅服务员", JobData.JobType.PART_TIME, "old_town_market", 11, 6, 120, {"eloquence": 20},
			{"eloquence": 1}, {"stamina": -15, "hunger": -10}),
		_make(&"job_factory_worker", "工厂工人", JobData.JobType.FULL_TIME, "industrial_site", 8, 8, 0, {},
			{"strength": 2, "craft": 1}, {"stamina": -30, "hunger": -25}, false, true, false, 4000),  # 月薪 4000

		# === 全职 ===
		_make(&"job_office_clerk", "写字楼文员", JobData.JobType.FULL_TIME, "commercial_district", 9, 8, 0, {"intelligence": 50},
			{"intelligence": 2, "eloquence": 1}, {"stamina": -15, "hunger": -15}, false, true, false, 5000),
		_make(&"job_chef", "餐厅厨师", JobData.JobType.FULL_TIME, "old_town_market", 10, 8, 0, {"craft": 40},
			{"craft": 3}, {"stamina": -20, "hunger": -10}, false, true, false, 4500),

		# === 自由职业 ===
		_make(&"job_freelance_writer", "写作投稿", JobData.JobType.FREELANCE, "old_town_street", 0, 1, 100, {"intelligence": 60},
			{"intelligence": 1}, {"mood": -3}),
	]


static func _make(id: StringName, name: String, type_: int, loc: StringName, start_h: int, dur: int,
		pay: int, reqs: Dictionary, gains: Dictionary, costs: Dictionary,
		weather: bool = false, is_full_time: bool = false, free_meal: bool = false, monthly: int = 0) -> JobData:
	var j := JobData.new()
	j.job_id = id
	j.job_name = name
	j.job_type = type_
	j.location = loc
	j.start_hour = start_h
	j.duration_hours = dur
	j.pay_per_day = pay
	j.pay_per_month = monthly
	j.stat_requirements = reqs
	j.stat_gains = gains
	j.stat_costs = costs
	j.weather_sensitive = weather
	return j


## 索引
static func build_index(jobs: Array) -> Dictionary:
	var idx: Dictionary = {}
	for j in jobs:
		idx[String(j.job_id)] = j
	return idx
