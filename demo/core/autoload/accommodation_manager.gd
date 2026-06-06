## accommodation_manager.gd
## 住所切换 + 每日扣费
extends Node

var _index: Dictionary = {}
const UNAFFORDABLE_DAYS_TO_GAMEOVER: int = 3


func _ready() -> void:
	EventBus.day_started.connect(_on_day_started)
	_build()


func _build() -> void:
	if not _index.is_empty(): return
	for a in AccommodationData.create_all():
		_index[String(a.accommodation_id)] = a


func get_accommodation(id: String) -> AccommodationData:
	if _index.is_empty(): _build()
	return _index.get(id)


func get_all() -> Array[AccommodationData]:
	if _index.is_empty(): _build()
	var arr: Array[AccommodationData] = []
	for k in _index:
		arr.append(_index[k])
	return arr


func set_accommodation(id: String) -> void:
	if not _index.has(id): return
	Player.current_accommodation = id
	Player.accommodation_days_unpaid = 0
	# 调整背包容量
	var data: AccommodationData = get_accommodation(id)
	if data != null and data.storage_capacity > 0:
		Player.inventory_capacity = max(Player.INVENTORY_BASE_SIZE, data.storage_capacity)
	EventBus.accommodation_changed.emit(id)


func _on_day_started(_day: int) -> void:
	var data: AccommodationData = get_accommodation(Player.current_accommodation)
	if data == null or data.daily_cost <= 0: return
	if Player.cash >= data.daily_cost:
		Player.cash -= data.daily_cost
		Player.accommodation_days_unpaid = 0
		Economy.RecordExpense("rent", data.daily_cost)
		# 体力恢复（按舒适度）
		var recover: int = int(20 + data.comfort * 0.5)
		Player.stamina = clampi(Player.stamina + recover, 0, 100)
		# 健康恢复
		if data.healing_bonus > 0:
			Player.health = clampi(Player.health + int(data.healing_bonus * 5), 0, 100)
	else:
		Player.accommodation_days_unpaid += 1
		if Player.accommodation_days_unpaid >= UNAFFORDABLE_DAYS_TO_GAMEOVER:
			Game.trigger_game_over("连续 3 天交不起房租，流落街头")
