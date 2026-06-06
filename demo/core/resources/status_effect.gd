## status_effect.gd
## 状态效果 — 生病/受伤/精力充沛等
class_name StatusEffect
extends Resource

@export var effect_id: StringName = &""
@export var effect_name: String = ""
@export var description: String = ""
## 持续小时数（-1 = 永久直到治愈）
@export var duration_hours: float = 0
## 图标颜色（占位）
@export var icon_color: Color = Color.WHITE
## 每小时对属性的影响 {stat: delta}
@export var per_hour_effect: Dictionary = {}
## 可叠加/不可叠加
@export var stackable: bool = false
## 互斥组（同组内只允许一个）
@export var mutex_group: StringName = &""
## 治愈条件
@export var cure_condition: String = ""


## 工厂
static func create_all() -> Array[StatusEffect]:
	return [
		_make(&"hungry", "饥饿", "饱腹过低，体力恢复减半", 1.0, Color(0.9, 0.7, 0.3),
			{"stamina_regen_mult": -0.5}, &"physical"),
		_make(&"malnutrition", "营养不良", "连续 3 天只吃最低级食物，所有恢复-30%", 72.0, Color(0.7, 0.5, 0.3),
			{"all_recovery_mult": -0.3}, &"physical"),
		_make(&"cold", "感冒", "体力-5/小时", 24.0, Color(0.5, 0.7, 0.9),
			{"stamina": -5}, &"physical"),
		_make(&"fever", "发烧", "感冒恶化，无法工作", 48.0, Color(0.9, 0.4, 0.3),
			{"stamina": -8, "health": -5}, &"physical"),
		_make(&"injured", "受伤", "体力上限临时-30", 24.0, Color(0.8, 0.2, 0.2),
			{"stamina_max": -30}, &"physical"),
		_make(&"depressed", "抑郁", "心情长期低落，所有效率-50%", 48.0, Color(0.3, 0.3, 0.4),
			{"all_efficiency_mult": -0.5}, &"mental"),
		_make(&"insomnia", "失眠", "夜间体力恢复减半", 24.0, Color(0.4, 0.3, 0.5),
			{"night_recovery_mult": -0.5}, &"mental"),
		_make(&"energetic", "精力充沛", "所有效率+20%", 12.0, Color(0.9, 0.9, 0.3),
			{"all_efficiency_mult": 0.2}, &"physical"),
		_make(&"confident", "自信", "口才临时+20", 8.0, Color(0.6, 0.4, 0.9),
			{"eloquence": 20}, &"mental"),
		_make(&"hangover", "宿醉", "智力-30，体力-20", 12.0, Color(0.4, 0.4, 0.2),
			{"intelligence": -30, "stamina": -20}, &"physical"),
	]


static func _make(id: StringName, name: String, desc: String, dur: float, color: Color, eff: Dictionary, mutex: StringName) -> StatusEffect:
	var s := StatusEffect.new()
	s.effect_id = id
	s.effect_name = name
	s.description = desc
	s.duration_hours = dur
	s.icon_color = color
	s.per_hour_effect = eff
	s.mutex_group = mutex
	return s


## 索引
static func build_index(arr: Array) -> Dictionary:
	var idx: Dictionary = {}
	for s in arr:
		idx[String(s.effect_id)] = s
	return idx
