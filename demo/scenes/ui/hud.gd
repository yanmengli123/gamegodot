## hud.gd
## 游戏内 HUD — 顶部日期/时间/天气 + 右上角现金 + 底部属性条
extends CanvasLayer

@onready var date_label: Label = $HUD/TopBar/DateLabel
@onready var time_label: Label = $HUD/TopBar/TimeLabel
@onready var weather_label: Label = $HUD/TopBar/WeatherLabel
@onready var cash_label: Label = $HUD/TopRight/CashLabel
@onready var status_container: HBoxContainer = $HUD/TopRight/StatusContainer
@onready var bars_container: VBoxContainer = $HUD/BottomBars
@onready var stamina_bar: ProgressBar = $HUD/BottomBars/StaminaBar
@onready var hunger_bar: ProgressBar = $HUD/BottomBars/HungerBar
@onready var mood_bar: ProgressBar = $HUD/BottomBars/MoodBar
@onready var health_bar: ProgressBar = $HUD/BottomBars/HealthBar
@onready var hygiene_bar: ProgressBar = $HUD/BottomBars/HygieneBar


func _ready() -> void:
	EventBus.hour_tick.connect(_on_hour_tick)
	EventBus.minute_tick.connect(_on_minute_tick)
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.stamina_changed.connect(_on_vitals_changed)
	EventBus.hunger_changed.connect(_on_vitals_changed)
	EventBus.mood_changed.connect(_on_vitals_changed)
	EventBus.health_changed.connect(_on_vitals_changed)
	EventBus.hygiene_changed.connect(_on_vitals_changed)
	EventBus.status_effect_added.connect(_on_status_changed)
	EventBus.status_effect_removed.connect(_on_status_changed)
	_refresh_all()


func _process(_delta: float) -> void:
	# 危险属性红色闪烁
	_blink_if_danger(stamina_bar, Player.stamina)
	_blink_if_danger(hunger_bar, Player.hunger)
	_blink_if_danger(mood_bar, Player.mood)
	_blink_if_danger(health_bar, Player.health)
	_blink_if_danger(hygiene_bar, Player.hygiene)


func _on_minute_tick(_m: int) -> void:
	time_label.text = "%02d:%02d" % [TimeMgr.hour, TimeMgr.minute]


func _on_hour_tick(_h: int) -> void:
	date_label.text = "%d年%d月%d日" % [TimeMgr.year, TimeMgr.month, TimeMgr.day]
	weather_label.text = "[%s] %s" % [WeatherManager.name_of(WeatherManager.current_weather), ""]
	weather_label.modulate = WeatherManager.color_of(WeatherManager.current_weather)
	_refresh_bars()


func _on_money_changed(_new: int, _delta: int) -> void:
	cash_label.text = "¥%d" % Player.cash
	# 数字飘字（阶段九完善）
	cash_label.modulate = Color.GREEN if _delta >= 0 else Color.RED
	var tween: Tween = create_tween()
	tween.tween_property(cash_label, "modulate", Color.WHITE, 0.5)


func _on_vitals_changed(_new: int, _delta: int) -> void:
	_refresh_bars()


func _on_status_changed(_id: String) -> void:
	# 清空再填充状态图标
	for c in status_container.get_children():
		c.queue_free()
	for eid in Player.status_effects.keys():
		var data: Resource = _get_status_data(eid)
		if data == null: continue
		var lbl := Label.new()
		lbl.text = data.effect_name
		lbl.modulate = data.icon_color
		lbl.add_theme_font_size_override("font_size", 10)
		status_container.add_child(lbl)


func _get_status_data(eid: String) -> StatusEffect:
	# 查 status_manager 缓存（阶段五扩展）
	# 这里用直接构造避免循环引用
	for s in StatusEffect.create_all():
		if String(s.effect_id) == eid:
			return s
	return null


func _refresh_bars() -> void:
	stamina_bar.value = Player.stamina
	hunger_bar.value = Player.hunger
	mood_bar.value = Player.mood
	health_bar.value = Player.health
	hygiene_bar.value = Player.hygiene


func _refresh_all() -> void:
	_on_hour_tick(0)
	_on_money_changed(Player.cash, 0)
	_refresh_bars()


func _blink_if_danger(bar: ProgressBar, val: int) -> void:
	if val < 20:
		bar.modulate = Color.RED if fmod(Time.get_ticks_msec() / 1000.0, 0.6) < 0.3 else Color.WHITE
	else:
		bar.modulate = Color.WHITE
