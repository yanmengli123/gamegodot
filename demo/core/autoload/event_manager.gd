## event_manager.gd
## 事件管理 — 触发评估 / 冷却 / 历史 / 链式选择
extends Node

const _SELF := preload("res://core/autoload/event_manager.gd")

## 已触发历史 {event_id: last_trigger_day}
var _triggered: Dictionary = {}
## 事件索引
var _index: Dictionary = {}


func _ready() -> void:
	EventBus.hour_tick.connect(_on_hour_tick)
	_build()


func _build() -> void:
	if not _index.is_empty(): return
	for e in EventFactory.create_all():
		_index[String(e.event_id)] = e


## 评估所有事件，返回 1 个应当触发的（按优先级 + 随机）
func roll_event() -> EventData:
	_build()
	var candidates: Array[EventData] = []
	for eid in _index:
		var e: EventData = _index[eid]
		# 冷却
		if _triggered.has(eid):
			var last_day: int = _triggered[eid]
			if not e.repeatable and (TimeMgr.day - last_day) < 999:
				continue
			if e.cooldown > 0 and (TimeMgr.day - last_day) < e.cooldown:
				continue
		if not e.check_conditions({}):
			continue
		candidates.append(e)
	if candidates.is_empty(): return null
	# 排序：优先级 desc
	candidates.sort_custom(func(a, b): return a.priority > b.priority)
	# 30% 概率触发
	if randf() < 0.3 and candidates.size() > 0:
		return candidates[0]
	return null


## 触发事件（应用 rewards + consequences）
func trigger(event_id: String) -> void:
	if not _index.has(event_id): return
	var e: EventData = _index[event_id]
	_triggered[event_id] = TimeMgr.day
	# 关联对话
	if not String(e.dialogue_id).is_empty():
		Dialogue.start_dialogue(e.dialogue_id, &"narrator")
	# 应用 rewards
	for k in e.rewards:
		match k:
			"money": Player.cash += int(e.rewards[k])
			"stat":
				var stat: String = e.rewards[k].keys()[0] if e.rewards[k] is Dictionary and not e.rewards[k].is_empty() else ""
				var delta: int = int(e.rewards[k][stat]) if stat != "" else 0
				match stat:
					"stamina": Player.stamina = clampi(Player.stamina + delta, 0, 100)
					"hunger": Player.hunger = clampi(Player.hunger + delta, 0, 100)
					"mood": Player.mood = clampi(Player.mood + delta, 0, 100)
					"health": Player.health = clampi(Player.health + delta, 0, 100)
					"hygiene": Player.hygiene = clampi(Player.hygiene + delta, 0, 100)
					"reputation": Player.reputation = clampi(Player.reputation + delta, 0, 1000)
					"strength": Player.strength = clampi(Player.strength + delta, 0, 100)
					"intelligence": Player.intelligence = clampi(Player.intelligence + delta, 0, 100)
					"eloquence": Player.eloquence = clampi(Player.eloquence + delta, 0, 100)
					"craft": Player.craft = clampi(Player.craft + delta, 0, 100)
					"charm": Player.charm = clampi(Player.charm + delta, 0, 100)
			"item":
				if e.rewards[k] is Dictionary:
					Player.add_item(String(e.rewards[k].get("id", "")), int(e.rewards[k].get("qty", 1)))
			"flag":
				if e.rewards[k] is Dictionary:
					Player.set_flag(String(e.rewards[k].keys()[0]), e.rewards[k].values()[0])
			"morality":
				Player.morality = clampi(Player.morality + int(e.rewards[k]), -100, 100)
	# 应用 consequences
	for k in e.consequences:
		match k:
			"money": Player.cash = max(0, Player.cash + int(e.consequences[k]))
			"stat":
				var stat2: String = e.consequences[k].keys()[0] if e.consequences[k] is Dictionary and not e.consequences[k].is_empty() else ""
				var delta2: int = int(e.consequences[k][stat2]) if stat2 != "" else 0
				match stat2:
					"stamina": Player.stamina = max(0, Player.stamina + delta2)
					"hunger": Player.hunger = max(0, Player.hunger + delta2)
					"mood": Player.mood = max(0, Player.mood + delta2)
					"health": Player.health = max(0, Player.health + delta2)
					"hygiene": Player.hygiene = max(0, Player.hygiene + delta2)
					"reputation": Player.reputation = max(0, Player.reputation + delta2)
					"strength": Player.strength = max(0, Player.strength + delta2)
					"intelligence": Player.intelligence = max(0, Player.intelligence + delta2)
					"eloquence": Player.eloquence = max(0, Player.eloquence + delta2)
					"craft": Player.craft = max(0, Player.craft + delta2)
					"charm": Player.charm = max(0, Player.charm + delta2)
			"flag":
				if e.consequences[k] is Dictionary:
					Player.set_flag(String(e.consequences[k].keys()[0]), e.consequences[k].values()[0])
			"morality":
				Player.morality = clampi(Player.morality + int(e.consequences[k]), -100, 100)
	EventBus.story_event_triggered.emit(event_id)
	EventBus.story_event_completed.emit(event_id)
	EventBus.notification_requested.emit(2, "事件：" + e.event_name)


func _on_hour_tick(_h: int) -> void:
	# 每小时 5% 概率 roll
	if randf() < 0.05:
		var e: EventData = roll_event()
		if e != null:
			trigger(String(e.event_id))
