## accommodation_data.gd
## 住所数据
class_name AccommodationData
extends Resource

enum Type { HOMELESS, SHELTER, CHEAP_HOTEL, RENTAL_ROOM, SINGLE_APARTMENT, COMFORTABLE_APARTMENT, LUXURY }

@export var accommodation_id: StringName = &""
@export var display_name: String = ""
@export var type: int = Type.HOMELESS
@export var description: String = ""
@export var daily_cost: int = 0
## 舒适度（影响体力恢复速度）
@export var comfort: int = 0
## 安全性（影响被偷概率）
@export var safety: int = 0
## 储物容量
@export var storage_capacity: int = 0
## 健康恢复加成
@export var healing_bonus: float = 0.0
@export var unlock_condition: Dictionary = {}


static func create_all() -> Array[AccommodationData]:
	return [
		_make(&"homeless", "露宿街头", AccommodationData.Type.HOMELESS, "露天睡觉", 0, 5, 0, 0, 0.0),
		_make(&"bridge", "桥洞/公园长椅", AccommodationData.Type.HOMELESS, "比街头稍好", 0, 8, 5, 0, 0.0),
		_make(&"shelter", "收容所", AccommodationData.Type.SHELTER, "基本遮风挡雨", 10, 20, 60, 0, 0.0),
		_make(&"net_bar", "网吧包夜", AccommodationData.Type.CHEAP_HOTEL, "可以上网", 15, 25, 50, 0, 0.0),
		_make(&"cheap_hotel", "廉价旅馆", AccommodationData.Type.CHEAP_HOTEL, "有热水", 40, 40, 70, 6, 0.05),
		_make(&"rental", "合租房", AccommodationData.Type.RENTAL_ROOM, "有自己的空间", 27, 55, 80, 12, 0.1),
		_make(&"single_apt", "单间公寓", AccommodationData.Type.SINGLE_APARTMENT, "有厨房", 50, 70, 90, 20, 0.15),
		_make(&"comfort_apt", "舒适公寓", AccommodationData.Type.COMFORTABLE_APARTMENT, "全面恢复加成", 100, 85, 95, 30, 0.25),
		_make(&"luxury_apt", "高级公寓", AccommodationData.Type.LUXURY, "全属性恢复", 200, 100, 100, 50, 0.4),
	]


static func _make(id: StringName, name: String, t: int, desc: String, cost: int, comfort: int, safety: int, storage: int, healing: float) -> AccommodationData:
	var a := AccommodationData.new()
	a.accommodation_id = id
	a.display_name = name
	a.type = t
	a.description = desc
	a.daily_cost = cost
	a.comfort = comfort
	a.safety = safety
	a.storage_capacity = storage
	a.healing_bonus = healing
	return a


static func build_index(arr: Array) -> Dictionary:
	var idx: Dictionary = {}
	for a in arr:
		idx[String(a.accommodation_id)] = a
	return idx


static func type_name(t: int) -> String:
	match t:
		Type.HOMELESS: return "露宿"
		Type.SHELTER: return "收容所"
		Type.CHEAP_HOTEL: return "廉价旅馆"
		Type.RENTAL_ROOM: return "合租"
		Type.SINGLE_APARTMENT: return "单间"
		Type.COMFORTABLE_APARTMENT: return "舒适公寓"
		Type.LUXURY: return "豪宅"
	return "未知"
