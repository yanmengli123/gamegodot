## shop_data.gd
## 商店数据 — 哪个 NPC 开、卖什么、收购什么
class_name ShopData
extends Resource

@export var shop_id: StringName = &""
@export var shop_name: String = ""
@export var npc_id: StringName = &""
## 出售物品 ID 列表（每日刷新库存时复用）
@export var stock_item_ids: PackedStringArray = PackedStringArray()
## 每日每样物品初始库存
@export var stock_quantity: int = 10
## 收购物品的类别（空 = 不收购）
@export var buyback_categories: PackedInt32Array = PackedInt32Array()
## 季节性价格浮动（season: int -> {item_id: mult}）
@export var seasonal_modifiers: Dictionary = {}


## 获得某物品当前售价（含玩家好感度/口才折扣）
func get_sell_price(item_id: String, base_price: int, affinity: int = 30, eloquence: int = 30) -> int:
	if base_price <= 0:
		return 0
	var mult: float = 1.0
	# 好感度 ≥ 50：95%；≥ 70：90%
	if affinity >= 70: mult = 0.9
	elif affinity >= 50: mult = 0.95
	# 口才 ≥ 50：再 ×0.98
	if eloquence >= 50: mult *= 0.98
	# 季节 modifier
	var season: int = TimeMgr.season
	if seasonal_modifiers.has(season) and seasonal_modifiers[season].has(item_id):
		mult *= float(seasonal_modifiers[season][item_id])
	return int(ceil(base_price * mult))


## 玩家卖给商店的价格（基础 sell_price 的 80%）
func get_buyback_price(item_id: String, base_sell: int, affinity: int = 30) -> int:
	if base_sell <= 0:
		return 0
	var mult: float = 0.8
	if affinity >= 70: mult = 0.9  # 友好 NPC 收购价更高
	return int(ceil(base_sell * mult))


## 是否收购该类别
func buys_category(cat: int) -> bool:
	return buyback_categories.has(cat)
