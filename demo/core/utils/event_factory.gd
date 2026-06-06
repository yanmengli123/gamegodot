## event_factory.gd
## 运行时构造 20 个随机事件
class_name EventFactory
extends RefCounted

static func create_all() -> Array[EventData]:
	return [
		# === 正面事件 ===
		_make(&"ev_pickup_money", "路上捡到钱", EventData.Type.RANDOM, EventData.TriggerType.TIME_BASED,
			{"time": [8, 22]}, "", 5, true, 1, "", {"money": 25}, {}, 50),
		_make(&"ev_praised", "被路人夸奖", EventData.Type.RANDOM, EventData.TriggerType.TIME_BASED,
			{"time": [10, 18]}, "", 3, true, 3, "", {"stat": {"mood": 15}}, {}, 30),
		_make(&"ev_meet_classmate", "偶遇老同学", EventData.Type.SIDE, EventData.TriggerType.FLAG_BASED,
			{"flag": "intro_li_ge"}, "old_town_street", 10, false, 0, "dlg_classmate",
			{"flag": {"met_classmate": true}}, {}, 10),
		_make(&"ev_lottery_win", "小彩票中奖", EventData.Type.RANDOM, EventData.TriggerType.TIME_BASED,
			{}, "old_town_street", 2, true, 30, "", {"money": 200}, {}, 200),
		_make(&"ev_treat_meal", "被请吃饭", EventData.Type.RANDOM, EventData.TriggerType.AFFINITY_BASED,
			{"time": [11, 13]}, "old_town_market", 5, true, 5, "", {"stat": {"hunger": 50, "mood": 10}}, {}, 100),

		# === 中性事件 ===
		_make(&"ev_street_perform", "街头表演", EventData.Type.RANDOM, EventData.TriggerType.TIME_BASED,
			{"time": [18, 21]}, "old_town_street", 3, true, 2, "", {"stat": {"mood": 8}}, {}, 0),
		_make(&"ev_ask_direction", "问路", EventData.Type.RANDOM, EventData.TriggerType.TIME_BASED,
			{"time": [9, 18]}, "", 5, true, 1, "", {"morality": 5}, {}, 0),
		_make(&"ev_lottery_lose", "路边抽奖", EventData.Type.RANDOM, EventData.TriggerType.TIME_BASED,
			{}, "old_town_street", 3, true, 5, "", {}, {"money": 10}, 0),
		_make(&"ev_interview", "记者采访", EventData.Type.RANDOM, EventData.TriggerType.STAT_BASED,
			{"reputation_min": 100}, "commercial_district", 5, true, 60, "",
			{"stat": {"reputation": 20}, "morality": 3}, {}, 0),
		_make(&"ev_stray_cat", "流浪猫", EventData.Type.SIDE, EventData.TriggerType.TIME_BASED,
			{"time": [19, 23]}, "old_town_street", 4, true, 7, "", {"stat": {"mood": 15}}, {}, 0),

		# === 负面事件 ===
		_make(&"ev_stolen", "被偷钱", EventData.Type.RANDOM, EventData.TriggerType.TIME_BASED,
			{"time": [20, 24]}, "", 5, true, 3, "", {}, {"money": 50}, 0),
		_make(&"ev_rain_soak", "淋雨", EventData.Type.RANDOM, EventData.TriggerType.COMBINED,
			{"weather": 2}, "", 8, true, 1, "", {}, {"stat": {"hygiene": -20, "health": -5}}, 0),
		_make(&"ev_wage_cut", "克扣工资", EventData.Type.CRISIS, EventData.TriggerType.FLAG_BASED,
			{"flag": "today_work_assigned"}, "", 3, true, 30, "", {},
			{"money": 30, "stat": {"mood": -15}}, 0),
		_make(&"ev_phone_broken", "手机摔坏", EventData.Type.RANDOM, EventData.TriggerType.TIME_BASED,
			{}, "", 2, true, 60, "", {}, {"money": 200}, 0),
		_make(&"ev_scam", "碰瓷", EventData.Type.CRISIS, EventData.TriggerType.TIME_BASED,
			{"time": [20, 23]}, "old_town_street", 4, true, 7, "", {},
			{"money": 300, "stat": {"mood": -20}}, 0),

		# === 危机事件 ===
		_make(&"ev_robbed", "被抢劫", EventData.Type.CRISIS, EventData.TriggerType.TIME_BASED,
			{"time": [22, 24], "money_min": 200}, "", 3, true, 30, "", {},
			{"money": 500, "stat": {"health": -20, "mood": -25}, "morality": -3}, 0),
		_make(&"ev_hospitalized", "重病住院", EventData.Type.CRISIS, EventData.TriggerType.STAT_BASED,
			{"health_max": 20}, "", 5, true, 60, "", {},
			{"money": 2000, "stat": {"health": 30}}, 0),
		_make(&"ev_fired", "被辞退", EventData.Type.CRISIS, EventData.TriggerType.FLAG_BASED,
			{"flag": "has_job"}, "", 4, false, 0, "", {},
			{"flag": {"has_job": false}, "stat": {"mood": -20}}, 0),
		_make(&"ev_rent_hike", "房东涨租", EventData.Type.CRISIS, EventData.TriggerType.FLAG_BASED,
			{"flag": "rental_room"}, "", 5, true, 30, "", {},
			{"stat": {"mood": -10}}, 0),
		_make(&"ev_police_misunderstand", "被误抓", EventData.Type.CRISIS, EventData.TriggerType.STAT_BASED,
			{"criminal_record_min": 30}, "", 2, true, 90, "", {},
			{"money": 500, "stat": {"reputation": -20, "mood": -30}}, 0),
	]


static func _make(id: StringName, name: String, type_: int, trig: int, cond: Dictionary,
		loc: StringName, prio: int, repeat: bool, cd: int, dlg: StringName,
		rewards: Dictionary, consequences: Dictionary, _weight: int = 10) -> EventData:
	var e := EventData.new()
	e.event_id = id
	e.event_name = name
	e.event_type = type_
	e.trigger_type = trig
	e.trigger_conditions = cond
	e.location = loc
	e.priority = prio
	e.repeatable = repeat
	e.cooldown = cd
	e.dialogue_id = dlg
	e.rewards = rewards
	e.consequences = consequences
	return e


## 索引
static func build_index(arr: Array) -> Dictionary:
	var idx: Dictionary = {}
	for e in arr:
		idx[String(e.event_id)] = e
	return idx
