## GameManager.gd
## 游戏状态机 + 暂停/恢复 + 存档/读档
##
## State 切换规则：
## - EXPLORING ↔ DIALOGUE / MENU / CUTSCENE / MINIGAME
## - DIALOGUE / CUTSCENE / MINIGAME 时 Time.pause_time()（除特例）
## - MENU 暂停游戏但可单独控制 time
extends Node

enum State {
	BOOT,            ## 启动中
	MAIN_MENU,       ## 主菜单
	LOADING,         ## 场景加载
	EXPLORING,       ## 探索
	DIALOGUE,        ## 对话中
	MENU,            ## 任意菜单打开
	CUTSCENE,        ## 过场
	MINIGAME,        ## 小游戏
	PAUSED,          ## 暂停
	GAME_OVER,       ## 游戏结束
}

var current_state: State = State.BOOT:
	set(v):
		var old: int = current_state
		if old == v:
			return
		current_state = v
		EventBus.game_state_changed.emit(old, v)
		_apply_state_side_effects(old, v)

const SAVE_DIR: String = "user://saves"
const SAVE_SLOT_COUNT: int = 3


func _ready() -> void:
	_ensure_save_dir()


func _apply_state_side_effects(old: int, new: int) -> void:
	# 进入对话/过场/小游戏：暂停时间
	if new in [State.DIALOGUE, State.CUTSCENE, State.MINIGAME]:
		TimeMgr.pause_time()
	# 离开时恢复
	elif old in [State.DIALOGUE, State.CUTSCENE, State.MINIGAME] and new == State.EXPLORING:
		TimeMgr.resume_time()
	# 暂停：完全冻结
	if new == State.PAUSED:
		TimeMgr.pause_time()
		get_tree().paused = true
	elif old == State.PAUSED:
		get_tree().paused = false


# === 状态查询 ===
func is_state(s: State) -> bool:
	return current_state == s

func can_player_move() -> bool:
	return current_state == State.EXPLORING


# === 存档 / 读档 ===
func _ensure_save_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))

func save_game(slot: int) -> bool:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		push_error("Invalid save slot: %d" % slot)
		return false
	var path: String = "%s/slot_%d.json" % [SAVE_DIR, slot]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save file: %s (err %d)" % [path, FileAccess.get_open_error()])
		return false
	var data: Dictionary = {
		"version": "0.1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"current_scene": Scenes.current_scene_id,
		"player": Player.to_dict(),
		"time": TimeMgr.to_dict(),
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func load_game(slot: int) -> bool:
	if slot < 0 or slot >= SAVE_SLOT_COUNT:
		return false
	var path: String = "%s/slot_%d.json" % [SAVE_DIR, slot]
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Corrupt save file: %s" % path)
		return false
	var data: Dictionary = parsed
	TimeMgr.from_dict(data.get("time", {}))
	Player.from_dict(data.get("player", {}))
	var scene_id: String = data.get("current_scene", "")
	if not scene_id.is_empty():
		Scenes.change_scene(scene_id)
	return true

func has_save(slot: int) -> bool:
	var path: String = "%s/slot_%d.json" % [SAVE_DIR, slot]
	return FileAccess.file_exists(path)

func get_save_info(slot: int) -> Dictionary:
	var path: String = "%s/slot_%d.json" % [SAVE_DIR, slot]
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


# === 游戏结束 ===
func trigger_game_over(reason: String) -> void:
	current_state = State.GAME_OVER
	EventBus.notification_requested.emit(0, "游戏结束：" + reason)
	# TODO 阶段八：弹 GameOverUI
	print("[Game] GAME OVER: %s" % reason)
