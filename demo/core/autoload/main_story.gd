## main_story.gd
## 主线剧情控制器 — 4 章 + 30+ 对话
##
## 阶段推进：
##   序章 → 第 1 章（7 天）→ 第 2 章（30 天）→ 第 3 章（90 天）→ 终章
##
## 每章有 trigger_day 阈值 + flag 解锁
extends Node

const _SELF := preload("res://core/autoload/main_story.gd")

signal chapter_started(chapter: int)
signal chapter_completed(chapter: int)
signal story_completed

## 当前章节
enum Chapter { PROLOGUE, CHAPTER_1, CHAPTER_2, CHAPTER_3, ENDING }
var current_chapter: int = Chapter.PROLOGUE

## 章节目录
const CHAPTERS := {
	Chapter.PROLOGUE: {
		"name": "序章：初到锦城",
		"start_day": 0,
		"required_flag": "",
		"next_chapter": Chapter.CHAPTER_1,
		"next_chapter_flag": "intro_wang_ayi",
		"intro_dialogue": "dlg_prologue_arrive",
		"complete_flag": "prologue_done",
	},
	Chapter.CHAPTER_1: {
		"name": "第一章：生存",
		"start_day": 1,
		"required_flag": "prologue_done",
		"next_chapter": Chapter.CHAPTER_2,
		"next_chapter_flag": "first_salary",
		"intro_dialogue": "dlg_ch1_intro",
		"complete_flag": "chapter_1_done",
		"events": {
			1: "dlg_ch1_first_day",
			3: "dlg_ch1_find_work",
			5: "dlg_ch1_first_salary",
			7: "dlg_ch1_chapter_end",
		},
	},
	Chapter.CHAPTER_2: {
		"name": "第二章：立足",
		"start_day": 8,
		"required_flag": "chapter_1_done",
		"next_chapter": Chapter.CHAPTER_3,
		"next_chapter_flag": "stable_income",
		"intro_dialogue": "dlg_ch2_intro",
		"complete_flag": "chapter_2_done",
		"events": {
			10: "dlg_ch2_meet_mentor",
			15: "dlg_ch2_training",
			25: "dlg_ch2_monthly_pay",
			28: "dlg_ch2_scam",
		},
	},
	Chapter.CHAPTER_3: {
		"name": "第三章：抉择",
		"start_day": 31,
		"required_flag": "chapter_2_done",
		"next_chapter": Chapter.ENDING,
		"next_chapter_flag": "chapter_3_done",
		"intro_dialogue": "dlg_ch3_intro",
		"complete_flag": "chapter_3_done",
		"events": {
			35: "dlg_ch3_pro_route",
			50: "dlg_ch3_gray_route",
			65: "dlg_ch3_study_route",
			88: "dlg_ch3_decision_point",
		},
	},
	Chapter.ENDING: {
		"name": "终章：命运",
		"start_day": 90,
		"required_flag": "chapter_3_done",
		"next_chapter": -1,
		"intro_dialogue": "dlg_ending_intro",
		"complete_flag": "game_complete",
	},
}


func _ready() -> void:
	EventBus.day_started.connect(_on_day_started)


func _on_day_started(_day: int) -> void:
	# 检查章节进度
	_check_chapter_progression()
	# 触发当日章节事件
	_trigger_daily_event()


func _check_chapter_progression() -> void:
	var ch_data: Dictionary = CHAPTERS.get(current_chapter, {})
	# 满足下一章条件？
	if ch_data.is_empty(): return
	var next_ch: int = ch_data.get("next_chapter", -1)
	if next_ch < 0: return
	# 检查 flag
	var next_flag: String = ch_data.get("next_chapter_flag", "")
	if not next_flag.is_empty() and not Player.has_flag(next_flag):
		return
	# 检查天数（序章在 0 天时立即）
	if TimeMgr.total_days >= int(ch_data.get("start_day", 0)) and not Player.has_flag(ch_data.get("complete_flag", "")):
		# 完成当前章节
		Player.set_flag(ch_data.get("complete_flag", ""), true)
		chapter_completed.emit(current_chapter)
		# 切下一章
		current_chapter = next_ch
		chapter_started.emit(current_chapter)
		# 触发章首对话
		var intro_dlg: String = CHAPTERS.get(next_ch, {}).get("intro_dialogue", "")
		if not intro_dlg.is_empty():
			# 延一帧启动对话
			_start_intro_dialogue(intro_dlg)


func _trigger_daily_event() -> void:
	var ch_data: Dictionary = CHAPTERS.get(current_chapter, {})
	var events: Dictionary = ch_data.get("events", {})
	var dlg_id: String = events.get(TimeMgr.total_days, "")
	if not dlg_id.is_empty() and not Player.has_flag("evt_done_" + dlg_id):
		# 标记 + 启动对话（玩家在主场景时）
		Player.set_flag("evt_done_" + dlg_id, true)
		_start_intro_dialogue(dlg_id)


func _start_intro_dialogue(dlg_id: String) -> void:
	# 检查对话存在
	var path: String = "res://data/dialogues/%s.tres" % dlg_id
	if not ResourceLoader.exists(path): return
	# 延一帧（避免事件中切状态）
	get_tree().create_timer(0.5).timeout.connect(func():
		if not Dialogue.is_in_dialogue and Game.current_state == Game.State.EXPLORING:
			Dialogue.start_dialogue(StringName(dlg_id), &"narrator")
	)


## 外部：开始游戏时启动序章
func start_prologue() -> void:
	current_chapter = Chapter.PROLOGUE
	chapter_started.emit(Chapter.PROLOGUE)
	Player.set_flag("prologue_started", true)
	_start_intro_dialogue("dlg_prologue_arrive")


## 获取所有章节状态
func get_progress() -> Dictionary:
	return {
		"current_chapter": current_chapter,
		"chapter_name": CHAPTERS.get(current_chapter, {}).get("name", "未知"),
		"day_in_chapter": TimeMgr.total_days - int(CHAPTERS.get(current_chapter, {}).get("start_day", 0)),
		"chapters_completed": _count_completed_chapters(),
	}


func _count_completed_chapters() -> int:
	var n: int = 0
	for ch in CHAPTERS:
		if Player.has_flag(CHAPTERS[ch].get("complete_flag", "")):
			n += 1
	return n
