## locale_service.gd
## 本地化服务 — 中英双语 + 翻译字典
##
## 用法：
##   Locale.set_locale("en")
##   var t = Locale.tr("ui.hud.cash", "现金：¥%d")  # 带 fallback
##
## 设计：内置翻译字典（避免依赖 .po/.csv 文件）
## 阶段十一：可替换为 Godot 官方 TranslationServer + .po 文件
extends Node

const _SELF := preload("res://core/autoload/locale_service.gd")

enum Locale { ZH_CN, EN }

var current_locale: int = Locale.ZH_CN:
	set(v):
		if v != current_locale:
			current_locale = v
			locale_changed.emit(v)

signal locale_changed(locale: int)

## 中英对照表
## key 是 "namespace.id"，值是 Dictionary {zh: ..., en: ...}
var TRANSLATIONS: Dictionary = {
	# === UI ===
	"ui.hud.cash": {"zh": "现金：¥%d", "en": "Cash: ¥%d"},
	"ui.hud.bank": {"zh": "银行：¥%d", "en": "Bank: ¥%d"},
	"ui.hud.debt": {"zh": "负债：¥%d", "en": "Debt: ¥%d"},
	"ui.hud.stamina": {"zh": "体力", "en": "Stamina"},
	"ui.hud.hunger": {"zh": "饱腹", "en": "Hunger"},
	"ui.hud.mood": {"zh": "心情", "en": "Mood"},
	"ui.hud.health": {"zh": "健康", "en": "Health"},
	"ui.hud.hygiene": {"zh": "卫生", "en": "Hygiene"},
	"ui.menu.title": {"zh": "菜单", "en": "Menu"},
	"ui.menu.new_game": {"zh": "新游戏", "en": "New Game"},
	"ui.menu.continue": {"zh": "继续游戏", "en": "Continue"},
	"ui.menu.save": {"zh": "保存", "en": "Save"},
	"ui.menu.load": {"zh": "读取", "en": "Load"},
	"ui.menu.settings": {"zh": "设置", "en": "Settings"},
	"ui.menu.quit": {"zh": "退出", "en": "Quit"},
	# === 通用 ===
	"common.yes": {"zh": "是", "en": "Yes"},
	"common.no": {"zh": "否", "en": "No"},
	"common.ok": {"zh": "好", "en": "OK"},
	"common.cancel": {"zh": "取消", "en": "Cancel"},
	"common.confirm": {"zh": "确认", "en": "Confirm"},
	"common.close": {"zh": "关闭", "en": "Close"},
	"common.back": {"zh": "返回", "en": "Back"},
	"common.save": {"zh": "保存", "en": "Save"},
	"common.load": {"zh": "读取", "en": "Load"},
	# === 游戏内 ===
	"game.start": {"zh": "开始游戏", "en": "Start Game"},
	"game.save_success": {"zh": "存档成功", "en": "Saved"},
	"game.load_success": {"zh": "读档成功", "en": "Loaded"},
	"game.game_over": {"zh": "游戏结束", "en": "Game Over"},
	"game.new_day": {"zh": "第 %d 天", "en": "Day %d"},
	# === 工作 ===
	"job.brick": {"zh": "搬砖工", "en": "Brick Layer"},
	"job.flyer": {"zh": "发传单", "en": "Flyer Distributor"},
	"job.dishwasher": {"zh": "餐厅洗碗", "en": "Dishwasher"},
	"job.cafe_assistant": {"zh": "网吧代练", "en": "Net Cafe Coach"},
	"job.courier": {"zh": "快递员", "en": "Courier"},
	"job.waiter": {"zh": "餐厅服务员", "en": "Waiter"},
	"job.factory_worker": {"zh": "工厂工人", "en": "Factory Worker"},
	"job.office_clerk": {"zh": "写字楼文员", "en": "Office Clerk"},
	"job.chef": {"zh": "餐厅厨师", "en": "Chef"},
	"job.freelance_writer": {"zh": "写作投稿", "en": "Freelance Writer"},
	# === 物品 ===
	"item.food_doujiang": {"zh": "豆浆", "en": "Soy Milk"},
	"item.food_youtiao": {"zh": "油条", "en": "Youtiao"},
	"item.food_baozi": {"zh": "包子", "en": "Baozi"},
	"item.food_mifan": {"zh": "盒饭", "en": "Lunchbox"},
	"item.food_xiaomi_zhou": {"zh": "小米粥", "en": "Millet Porridge"},
	"item.clothing_tshirt": {"zh": "T恤", "en": "T-Shirt"},
	"item.clothing_jeans": {"zh": "牛仔裤", "en": "Jeans"},
	"item.clothing_sneaker": {"zh": "运动鞋", "en": "Sneakers"},
	"item.clothing_cap": {"zh": "工地帽", "en": "Hard Hat"},
	"item.tool_phone": {"zh": "手机", "en": "Phone"},
	"item.medicine_bandage": {"zh": "创可贴", "en": "Bandage"},
	"item.medicine_cold": {"zh": "感冒药", "en": "Cold Medicine"},
	"item.medicine_painkiller": {"zh": "止痛药", "en": "Painkiller"},
	"item.furniture_bed_basic": {"zh": "折叠床", "en": "Folding Bed"},
	"item.misc_id_card": {"zh": "身份证", "en": "ID Card"},
	# === 状态效果 ===
	"status.hungry": {"zh": "饥饿", "en": "Hungry"},
	"status.malnutrition": {"zh": "营养不良", "en": "Malnutrition"},
	"status.cold": {"zh": "感冒", "en": "Cold"},
	"status.fever": {"zh": "发烧", "en": "Fever"},
	"status.injured": {"zh": "受伤", "en": "Injured"},
	"status.depressed": {"zh": "抑郁", "en": "Depressed"},
	"status.insomnia": {"zh": "失眠", "en": "Insomnia"},
	"status.energetic": {"zh": "精力充沛", "en": "Energetic"},
	"status.confident": {"zh": "自信", "en": "Confident"},
	"status.hangover": {"zh": "宿醉", "en": "Hangover"},
	# === 天气 ===
	"weather.sunny": {"zh": "晴", "en": "Sunny"},
	"weather.cloudy": {"zh": "多云", "en": "Cloudy"},
	"weather.light_rain": {"zh": "小雨", "en": "Light Rain"},
	"weather.heavy_rain": {"zh": "大雨", "en": "Heavy Rain"},
	"weather.storm": {"zh": "暴风雨", "en": "Storm"},
	"weather.light_snow": {"zh": "小雪", "en": "Light Snow"},
	"weather.heavy_snow": {"zh": "大雪", "en": "Heavy Snow"},
	"weather.fog": {"zh": "雾霾", "en": "Fog"},
	# === 章节 ===
	"chapter.prologue": {"zh": "序章：初到锦城", "en": "Prologue: Arrival"},
	"chapter.ch1": {"zh": "第一章：生存", "en": "Chapter 1: Survival"},
	"chapter.ch2": {"zh": "第二章：立足", "en": "Chapter 2: Standing"},
	"chapter.ch3": {"zh": "第三章：抉择", "en": "Chapter 3: Choice"},
	"chapter.ending": {"zh": "终章：命运", "en": "Epilogue: Fate"},
	# === 结局 ===
	"ending.boss": {"zh": "成为老板", "en": "Became a Boss"},
	"ending.foreman": {"zh": "建筑工头", "en": "Construction Foreman"},
	"ending.chef": {"zh": "餐厅主厨", "en": "Restaurant Chef"},
	"ending.milk_tea": {"zh": "奶茶店老板", "en": "Bubble Tea Shop Owner"},
	"ending.couple_saving": {"zh": "攒钱情侣", "en": "Saving Couple"},
	"ending.homeless": {"zh": "流落街头", "en": "Homeless"},
	"ending.debt": {"zh": "被追债", "en": "Chased by Debt"},
	"ending.prison": {"zh": "锒铛入狱", "en": "Imprisoned"},
	"ending.worker": {"zh": "普通市民", "en": "Ordinary Citizen"},
	"ending.student": {"zh": "重回校园", "en": "Back to School"},
	"ending.back_home": {"zh": "回老家", "en": "Back Home"},
	"ending.story_complete": {"zh": "大团圆", "en": "Grand Finale"},
}


func _ready() -> void:
	# 检测系统语言
	var os_lang: String = OS.get_locale().to_lower()
	if os_lang.begins_with("en"):
		current_locale = Locale.EN


## 设置语言
func set_locale(loc: String) -> void:
	match loc.to_lower():
		"en", "en_us", "english":
			current_locale = Locale.EN
		_:
			current_locale = Locale.ZH_CN


## 切换语言（toggle）
func toggle_locale() -> void:
	current_locale = Locale.EN if current_locale == Locale.ZH_CN else Locale.ZH_CN


## 当前语言名
func get_locale_name() -> String:
	match current_locale:
		Locale.ZH_CN: return "zh-CN"
		Locale.EN: return "en"
	return "unknown"


## 翻译（无 fallback 字符串时直接返回 key）
## 支持 %s, %d 格式化
func translate(key: String, fallback: String = "") -> String:
	if not TRANSLATIONS.has(key):
		return fallback if fallback != "" else key
	var entry: Dictionary = TRANSLATIONS[key]
	var lang: String = "zh" if current_locale == Locale.ZH_CN else "en"
	if not entry.has(lang):
		lang = "zh"
	var template: String = entry[lang]
	return template


## 翻译 + 格式化
func translatef(key: String, args: Array) -> String:
	var template: String = translate(key)
	if args.is_empty():
		return template
	# 用 vformat（支持 %d, %s）
	return template % args
