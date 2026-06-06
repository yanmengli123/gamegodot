## EventBus.gd
## 全局事件总线 — 跨系统通信的单一通道
## 用法：EventBus.money_changed.emit(500)
##      EventBus.money_changed.connect(_on_money_changed)
##
## 设计原则：只放"需要跨系统通知"的事件，系统内部状态变更走 return value / property setter
extends Node

# === 玩家经济 ===
signal money_changed(new_amount: int, delta: int)
signal debt_changed(new_debt: int)
signal bank_balance_changed(new_balance: int)

# === 玩家属性 ===
signal stamina_changed(new_value: int, delta: int)
signal hunger_changed(new_value: int, delta: int)
signal mood_changed(new_value: int, delta: int)
signal health_changed(new_value: int, delta: int)
signal hygiene_changed(new_value: int, delta: int)

# === 能力值 ===
signal stat_changed(stat_name: String, new_value: int, delta: int)

# === 社会值 ===
signal reputation_changed(new_value: int)
signal morality_changed(new_value: int)
signal criminal_record_changed(new_value: int)

# === 状态效果 ===
signal status_effect_added(effect_id: String)
signal status_effect_removed(effect_id: String)

# === 时间 ===
signal minute_tick(game_minute: int)
signal hour_tick(game_hour: int)
signal time_period_changed(period: int)  # TimeManager.Period
signal day_started(day: int)
signal day_ended(day: int)
signal week_ended(week: int)
signal month_ended(month: int)
signal season_changed(season: int)  # TimeManager.Season
signal year_changed(year: int)

# === 场景 ===
signal scene_about_to_change(from: String, to: String)
signal scene_changed(scene_id: String)
signal scene_transition_finished

# === 物品 / 背包 ===
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal item_used(item_id: String)
signal inventory_full

# === 状态机 ===
signal game_state_changed(old_state: int, new_state: int)  # GameManager.State
signal dialogue_started(dialogue_id: String, npc_id: String)
signal dialogue_ended(dialogue_id: String)
signal dialogue_choice_made(node_id: String, choice_index: int)
signal menu_opened(menu_id: String)
signal menu_closed(menu_id: String)

# === 事件系统 ===
signal story_event_triggered(event_id: String)
signal story_event_completed(event_id: String)
signal flag_set(flag_id: String, value: bool)

# === 工作 ===
signal job_started(job_id: String)
signal job_finished(job_id: String, pay: int, success: bool)
signal job_unlocked(job_id: String)

# === 住所 ===
signal accommodation_changed(accommodation_id: String)

# === 通知 ===
signal notification_requested(category: int, text: String)  # NotificationManager.Category
signal floating_number_requested(world_pos: Vector2, text: String, color: Color)


func _ready() -> void:
	# autoload 在所有节点之前；这里只挂信号，不订阅
	pass
