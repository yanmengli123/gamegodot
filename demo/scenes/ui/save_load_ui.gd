## save_load_ui.gd
## 存档/读档 UI
extends Control

@onready var slot1_btn: Button = $Panel/VBox/HBox/Slot1
@onready var slot2_btn: Button = $Panel/VBox/HBox/Slot2
@onready var slot3_btn: Button = $Panel/VBox/HBox/Slot3
@onready var close_btn: Button = $Panel/VBox/CloseButton
@onready var save_btn: Button = $Panel/VBox/SaveButton


func _ready() -> void:
	visible = false
	slot1_btn.pressed.connect(func(): _on_slot(0))
	slot2_btn.pressed.connect(func(): _on_slot(1))
	slot3_btn.pressed.connect(func(): _on_slot(2))
	close_btn.pressed.connect(close)
	save_btn.pressed.connect(_on_save_pressed)


func open() -> void:
	visible = true
	get_tree().paused = true
	_refresh()


func close() -> void:
	visible = false
	get_tree().paused = false


func _refresh() -> void:
	for i in range(3):
		var btn: Button = [slot1_btn, slot2_btn, slot3_btn][i]
		var info: Dictionary = Game.get_save_info(i)
		if info.is_empty():
			btn.text = "槽位 %d\n[空]" % (i + 1)
		else:
			btn.text = "槽位 %d\n第 %d 天\n¥%d" % [i + 1, info.get("player", {}).get("total_days", 0) if info.get("player") is Dictionary else 0,
				info.get("player", {}).get("cash", 0) if info.get("player") is Dictionary else 0]


func _on_slot(idx: int) -> void:
	if Game.has_save(idx):
		Game.load_game(idx)
		close()
	else:
		# 空槽位 → 存
		Game.save_game(idx)
		_refresh()


func _on_save_pressed() -> void:
	# 找到第一个空槽或覆盖槽 0
	for i in range(3):
		if not Game.has_save(i):
			Game.save_game(i)
			_refresh()
			return
	Game.save_game(0)
	_refresh()
