## item_data.gd
## 物品数据资源 — 食物 / 服装 / 工具 / 药品 / 家具 / 杂项 / 任务
class_name ItemData
extends Resource

enum Category { FOOD, CLOTHING, TOOL, MEDICINE, FURNITURE, MISC, QUEST }
enum EquipSlot { NONE, HEAD, BODY, FEET, ACCESSORY }

@export var item_id: StringName = &""
@export var item_name: String = ""
@export var description: String = ""
@export var icon_color: Color = Color.WHITE  ## 占位图标用纯色
@export var category: int = Category.MISC
@export var stackable: bool = true
@export var max_stack: int = 99
@export var buy_price: int = 0
@export var sell_price: int = 0
## 使用效果：{stat_name: delta}
@export var use_effect: Dictionary = {}
## 装备槽（NONE = 不可装备）
@export var equip_slot: int = EquipSlot.NONE
## 装备属性加成：{stat_name: bonus}
@export var equip_bonus: Dictionary = {}


## 分类名
static func category_name(c: int) -> String:
	match c:
		Category.FOOD: return "食物"
		Category.CLOTHING: return "服装"
		Category.TOOL: return "工具"
		Category.MEDICINE: return "药品"
		Category.FURNITURE: return "家具"
		Category.MISC: return "杂项"
		Category.QUEST: return "任务"
	return "未知"


## 是否能使用（有 use_effect 或可装备）
func is_usable() -> bool:
	return not use_effect.is_empty() or equip_slot != EquipSlot.NONE
