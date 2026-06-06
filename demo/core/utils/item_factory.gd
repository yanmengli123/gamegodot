## item_factory.gd
## 运行时构造 15 个物品
## 阶段十美术到位后转 .tres
class_name ItemFactory
extends RefCounted

const _Self := preload("res://core/utils/item_factory.gd")


static func create_all() -> Array[ItemData]:
	return [
		_make(&"food_doujiang", "豆浆", "热乎乎的豆浆，恢复饱腹", Color(0.95, 0.92, 0.8), ItemData.Category.FOOD, 2, 1, {"hunger": 20}),
		_make(&"food_youtiao", "油条", "香脆的油条", Color(0.95, 0.78, 0.4), ItemData.Category.FOOD, 1, 1, {"hunger": 15}),
		_make(&"food_baozi", "包子", "肉馅包子，顶饱", Color(0.85, 0.65, 0.5), ItemData.Category.FOOD, 3, 1, {"hunger": 35}),
		_make(&"food_mifan", "盒饭", "工地盒饭，量大便宜", Color(0.7, 0.6, 0.4), ItemData.Category.FOOD, 12, 8, {"hunger": 60, "health": 5}),
		_make(&"food_xiaomi_zhou", "小米粥", "养胃的小米粥", Color(0.9, 0.85, 0.6), ItemData.Category.FOOD, 5, 3, {"hunger": 40, "health": 5}),
		_make(&"clothing_tshirt", "T恤", "普通的T恤", Color(0.4, 0.55, 0.8), ItemData.Category.CLOTHING, 30, 15, {}, ItemData.EquipSlot.BODY, {}),
		_make(&"clothing_jeans", "牛仔裤", "耐磨的牛仔裤", Color(0.25, 0.28, 0.4), ItemData.Category.CLOTHING, 80, 40, {}, ItemData.EquipSlot.BODY, {"strength": 1}),
		_make(&"clothing_sneaker", "运动鞋", "跑工地不累", Color(0.9, 0.9, 0.9), ItemData.Category.CLOTHING, 60, 30, {}, ItemData.EquipSlot.FEET, {"stamina_drain_mult": -0.1}),
		_make(&"clothing_cap", "工地帽", "安全帽，工地的标志", Color(1, 0.9, 0), ItemData.Category.CLOTHING, 20, 10, {}, ItemData.EquipSlot.HEAD, {"craft": 1}),
		_make(&"tool_phone", "手机", "能打电话、上网、查招聘信息", Color(0.1, 0.1, 0.15), ItemData.Category.TOOL, 800, 200, {}),
		_make(&"medicine_bandage", "创可贴", "处理小伤口", Color(0.85, 0.65, 0.65), ItemData.Category.MEDICINE, 5, 2, {"health": 10}),
		_make(&"medicine_cold", "感冒药", "退烧缓解症状", Color(0.5, 0.7, 0.9), ItemData.Category.MEDICINE, 25, 10, {"health": 30, "hunger": -5}),
		_make(&"medicine_painkiller", "止痛药", "临时止痛", Color(0.9, 0.5, 0.5), ItemData.Category.MEDICINE, 15, 5, {"health": 20}),
		_make(&"furniture_bed_basic", "折叠床", "简陋但能睡", Color(0.55, 0.4, 0.3), ItemData.Category.FURNITURE, 200, 80, {}),
		_make(&"misc_id_card", "身份证", "找工作必备", Color(0.6, 0.7, 0.8), ItemData.Category.QUEST, 0, 0, {}, ItemData.EquipSlot.NONE, {}),
	]


static func _make(id: StringName, name: String, desc: String, color: Color, cat: int, buy: int, sell: int, use_eff: Dictionary = {}, equip: int = ItemData.EquipSlot.NONE, bonus: Dictionary = {}) -> ItemData:
	var item := ItemData.new()
	item.item_id = id
	item.item_name = name
	item.description = desc
	item.icon_color = color
	item.category = cat
	item.buy_price = buy
	item.sell_price = sell
	item.use_effect = use_eff
	item.equip_slot = equip
	item.equip_bonus = bonus
	return item


## 索引：item_id -> ItemData
static func build_index(items: Array) -> Dictionary:
	var idx: Dictionary = {}
	for it in items:
		idx[String(it.item_id)] = it
	return idx
