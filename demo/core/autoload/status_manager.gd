## status_manager.gd
## 状态效果管理 — 添加/移除/互斥/tick 应用
extends Node

var _effect_index: Dictionary = {}
var _last_hour: int = -1


func _ready() -> void:
	EventBus.hour_tick.connect(_on_hour_tick)
	_build_index()


func _build_index() -> void:
	if not _effect_index.is_empty(): return
	for s in StatusEffect.create_all():
		_effect_index[String(s.effect_id)] = s


func get_effect(effect_id: String) -> StatusEffect:
	if _effect_index.is_empty(): _build_index()
	return _effect_index.get(effect_id)


## 添加状态（应用互斥规则）
func add_effect(effect_id: String, source: String = "system", duration_override: float = -1.0) -> bool:
	var data: StatusEffect = get_effect(effect_id)
	if data == null: return false
	# 互斥：同组已有则替换
	if data.mutex_group != &"":
		for existing_id in Player.status_effects.keys():
			var existing: StatusEffect = get_effect(existing_id)
			if existing != null and existing.mutex_group == data.mutex_group and existing_id != effect_id:
				Player.remove_status_effect(existing_id)
	# 已存在且不可叠加
	if Player.has_status_effect(effect_id) and not data.stackable:
		# 刷新时长
		var dur: float = duration_override if duration_override > 0 else data.duration_hours
		Player.status_effects[effect_id]["remaining_hours"] = max(
			Player.status_effects[effect_id].get("remaining_hours", 0.0), dur)
		return true
	var dur2: float = duration_override if duration_override > 0 else data.duration_hours
	Player.add_status_effect(effect_id, source, dur2)
	return true


func remove_effect(effect_id: String) -> void:
	Player.remove_status_effect(effect_id)


## 每小时 tick：扣除/增加 + 倒计时
func _on_hour_tick(hour: int) -> void:
	if hour == _last_hour: return
	_last_hour = hour
	var to_remove: Array = []
	for eid in Player.status_effects.keys():
		var data: StatusEffect = get_effect(eid)
		if data == null:
			to_remove.append(eid)
			continue
		# 应用效果
		for stat in data.per_hour_effect:
			var delta: int = int(data.per_hour_effect[stat])
			match stat:
				"stamina": Player.stamina = clampi(Player.stamina + delta, 0, 100)
				"hunger": Player.mood = clampi(Player.mood + delta, 0, 100) if stat == "mood" else Player.hunger
				"mood": Player.mood = clampi(Player.mood + delta, 0, 100)
				"health": Player.health = clampi(Player.health + delta, 0, 100)
				"hygiene": Player.hygiene = clampi(Player.hygiene + delta, 0, 100)
				"strength": Player.strength = clampi(Player.strength + delta, 0, 100)
				"intelligence": Player.intelligence = clampi(Player.intelligence + delta, 0, 100)
				"eloquence": Player.eloquence = clampi(Player.eloquence + delta, 0, 100)
				"craft": Player.craft = clampi(Player.craft + delta, 0, 100)
				"charm": Player.charm = clampi(Player.charm + delta, 0, 100)
		# 倒计时
		var entry: Dictionary = Player.status_effects[eid]
		entry["remaining_hours"] = entry.get("remaining_hours", 0.0) - 1.0
		if entry["remaining_hours"] <= 0.0:
			to_remove.append(eid)
	for eid in to_remove:
		Player.remove_status_effect(eid)
