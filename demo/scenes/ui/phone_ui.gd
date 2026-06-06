## phone_ui.gd
## 手机界面 — 简化版：单页信息卡（时间 / 现金 / 联系人 / 设置入口）
extends Control

@onready var time_label: Label = $Panel/Margin/VBox/TimeLabel
@onready var cash_label: Label = $Panel/Margin/VBox/CashLabel
@onready var npc_list: ItemList = $Panel/Margin/VBox/NPCList
@onready var close_btn: Button = $Panel/Margin/CloseButton


func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close)
	EventBus.minute_tick.connect(_on_tick)


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"cancel") or event.is_action_pressed(&"open_phone")):
		close()
		get_viewport().set_input_as_handled()


func _on_tick(_m: int) -> void:
	if visible: _refresh()


func _refresh() -> void:
	time_label.text = "%d年%d月%d日  %02d:%02d\n%s" % [TimeMgr.year, TimeMgr.month, TimeMgr.day, TimeMgr.hour, TimeMgr.minute, WeatherManager.name_of(WeatherManager.current_weather)]
	cash_label.text = "现金 ¥%d  银行 ¥%d  负债 ¥%d\n住所：%s" % [Player.cash, Player.bank_balance, Player.debt, Accommodation.get_accommodation(Player.current_accommodation).display_name if Accommodation.get_accommodation(Player.current_accommodation) else "无"]
	npc_list.clear()
	for nid in Player.known_npcs:
		var aff: int = int(Player.known_npcs[nid].get("affinity", 30))
		npc_list.add_item("%s  好感 %d" % [nid, aff])
