## ending_system.gd
## 12 结局系统
##
## 结局由 flag / 数值触发：
##   - flag:pro_route_completed + 1000 cash → "老板" 结局
##   - flag:learned_tower_crane + flag:promoted_constructor → "工头" 结局
##   - flag:xm_milk_tea_funded → "情侣开店" 结局
##   - cash >= 10000 → "万元户"
##   - morality > 50 + flag:morality_good → "良心人"
##   - cash < 0 + 7天未付房租 → 流落街头
##   - debt > 5000 → 追债
##   - flag:xm_saving_together → 攒钱创业
##   - flag:cheat (3 次违法) → 入狱
##   - flag:free_work_30days → 普通市民
##   - flag:complete_game 12 种结局中的"大团圆"
##   - default: "回老家"（第 90 天没钱没工作没恋人）
extends Node

const _SELF := preload("res://core/autoload/ending_system.gd")

signal ending_triggered(ending_id: String)

## 12 结局定义
const ENDINGS: Array = [
	{"id": "ending_boss", "name": "成为老板", "desc": "你凭借努力和智慧，在锦城开设了自己的小店，迈出了人生新的一步。", "min_cash": 10000, "required_flag": "pro_route_completed"},
	{"id": "ending_foreman", "name": "建筑工头", "desc": "多年的工地经验让你成为工头，手下带着一帮兄弟。", "required_flag": "promoted_constructor"},
	{"id": "ending_chef", "name": "餐厅主厨", "desc": "你从洗碗工一路做到主厨，餐馆里弥漫着你做的菜香。", "required_flag": "became_chef"},
	{"id": "ending_milk_tea", "name": "奶茶店老板", "desc": "你和小美的奶茶店开业了，锦城又多了一个温暖的角落。", "required_flag": "xm_milk_tea_funded"},
	{"id": "ending_couple_saving", "name": "攒钱情侣", "desc": "你和小美一起攒钱，互相扶持，平凡但温暖。", "required_flag": "xm_saving_together"},
	{"id": "ending_homeless", "name": "流落街头", "desc": "钱花光了，工作也没了，你蜷缩在桥洞下，回想着锦城的日日夜夜。", "max_cash": 0, "max_days": 30},
	{"id": "ending_debt", "name": "被追债", "desc": "负债累累被黑社会追债，不得不连夜逃离锦城。", "min_debt": 5000},
	{"id": "ending_prison", "name": "锒铛入狱", "desc": "违法的事做多了，最终被警察逮捕。", "min_criminal_record": 80},
	{"id": "ending_worker", "name": "普通市民", "desc": "没有什么大起大落，你在锦城安安稳稳地过着普通的生活。", "default": true},
	{"id": "ending_student", "name": "重回校园", "desc": "你用攒下的钱重新考上了大学，知识改变命运。", "required_flag": "enrolled_university"},
	{"id": "ending_back_home", "name": "回老家", "desc": "锦城太难了，你带着 500 块又回到了老家，至少那里有亲人。", "default_fallback": true},
	{"id": "ending_story_complete", "name": "大团圆", "desc": "你不仅在锦城站稳了脚跟，还收获了爱情、友情、事业、声誉。", "required_flag": "complete_game", "min_reputation": 500},
]


## 评估结局（按顺序匹配第一个）
func evaluate_ending() -> Dictionary:
	# 检查结局条件（按 ENDINGS 顺序，第一个满足的胜出）
	for ending in ENDINGS:
		if _check_ending(ending):
			return ending
	# 兜底
	return ENDINGS[-1]  # ending_back_home


func _check_ending(ending: Dictionary) -> bool:
	# 强制要求
	if ending.has("required_flag") and not Player.has_flag(ending["required_flag"]):
		return false
	if ending.has("min_cash") and Player.cash < int(ending["min_cash"]):
		return false
	if ending.has("min_reputation") and Player.reputation < int(ending["min_reputation"]):
		return false
	if ending.has("min_debt") and Player.debt < int(ending["min_debt"]):
		return false
	if ending.has("max_cash") and Player.cash > int(ending["max_cash"]):
		return false
	if ending.has("max_days") and TimeMgr.total_days < int(ending["max_days"]):
		return false
	if ending.has("min_criminal_record") and Player.criminal_record < int(ending["min_criminal_record"]):
		return false
	if ending.get("default", false):
		# 默认结局只在第 90 天且其他没满足时
		if TimeMgr.total_days < 90: return false
		# 其他结局都失败
		return true
	if ending.get("default_fallback", false):
		return true
	return true


## 触发结局
func trigger_ending(ending_id: String) -> void:
	for e in ENDINGS:
		if e.id == ending_id:
			ending_triggered.emit(ending_id)
			Player.set_flag("ending_" + ending_id, true)
			Player.set_flag("ending_reached", true)
			Game.trigger_game_over(e.desc)
			return


## 列出所有解锁的结局
func unlocked_endings() -> Array:
	var arr: Array = []
	for e in ENDINGS:
		if Player.has_flag("ending_" + e.id):
			arr.append(e)
	return arr
