## main_menu.gd
## 主菜单 — 新游戏 / 继续 / 退出
extends Control

@onready var title_label: Label = $Panel/VBox/Title
@onready var new_btn: Button = $Panel/VBox/NewButton
@onready var continue_btn: Button = $Panel/VBox/ContinueButton
@onready var quit_btn: Button = $Panel/VBox/QuitButton


func _ready() -> void:
	visible = false
	new_btn.pressed.connect(_on_new)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(_on_quit)
	continue_btn.disabled = not _any_save_exists()


func _any_save_exists() -> bool:
	for i in range(Game.SAVE_SLOT_COUNT):
		if Game.has_save(i): return true
	return false


func open() -> void:
	visible = true
	get_tree().paused = true
	continue_btn.disabled = not _any_save_exists()


func close() -> void:
	visible = false
	get_tree().paused = false


func _on_new() -> void:
	# 新游戏：重置玩家数据，跳到 train_station
	Player.cash = 500
	Player.stamina = 100
	Player.hunger = 80
	Player.mood = 70
	Player.health = 100
	Player.hygiene = 100
	Player.current_accommodation = "homeless"
	Player.current_job = ""
	Player.known_npcs = {}
	Player.story_flags = {}
	Player.inventory_slots = []
	Player.inventory_slots.resize(Player.INVENTORY_BASE_SIZE)
	Player.bank_balance = 0
	Player.debt = 0
	TimeMgr._total_minutes = 0
	TimeMgr._recompute_cached()
	Scenes.change_scene(&"train_station", "default")
	close()


func _on_continue() -> void:
	# 找最近的有存档的槽位
	for i in range(Game.SAVE_SLOT_COUNT):
		if Game.has_save(i):
			Game.load_game(i)
			close()
			return


func _on_quit() -> void:
	get_tree().quit()
