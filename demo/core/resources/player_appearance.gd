## player_appearance.gd
## 玩家外观数据资源 — 阶段二用，阶段四扩展（购买服装时存为 .tres）
##
## 通过设置 hair_id/hair_color/skin_tone/shirt_id/pants_id 触发
## Player.appearance_changed 信号 → 重新生成 Sprite2D 贴图
class_name PlayerAppearance
extends Resource

const _Self = preload("res://core/resources/player_appearance.gd")

## 发型 ID：short / long / buzzcut / ponytail / beanie
@export var hair_id: StringName = &"short"
## 发色
@export var hair_color: Color = Color(0.15, 0.1, 0.05)
## 肤色
@export var skin_tone: Color = Color(0.95, 0.78, 0.65)
## 上衣 ID
@export var shirt_id: StringName = &"tshirt_basic"
## 上衣颜色
@export var shirt_color: Color = Color(0.25, 0.45, 0.7)
## 裤子 ID
@export var pants_id: StringName = &"jeans_basic"
## 裤子颜色
@export var pants_color: Color = Color(0.2, 0.22, 0.3)
## 鞋子 ID
@export var shoes_id: StringName = &"sneaker_basic"

## 默认外观（用于新游戏初始化）
static func default_appearance() -> Resource:
	return _Self.new()


## 序列化为字典（用于存档）
func to_dict() -> Dictionary:
	return {
		"hair_id": String(hair_id),
		"hair_color": [hair_color.r, hair_color.g, hair_color.b, hair_color.a],
		"skin_tone": [skin_tone.r, skin_tone.g, skin_tone.b, skin_tone.a],
		"shirt_id": String(shirt_id),
		"shirt_color": [shirt_color.r, shirt_color.g, shirt_color.b, shirt_color.a],
		"pants_id": String(pants_id),
		"pants_color": [pants_color.r, pants_color.g, pants_color.b, pants_color.a],
		"shoes_id": String(shoes_id),
	}

func from_dict(d: Dictionary) -> void:
	hair_id = StringName(d.get("hair_id", "short"))
	var hc: Array = d.get("hair_color", [0.15, 0.1, 0.05, 1.0])
	hair_color = Color(hc[0], hc[1], hc[2], hc[3])
	var st: Array = d.get("skin_tone", [0.95, 0.78, 0.65, 1.0])
	skin_tone = Color(st[0], st[1], st[2], st[3])
	shirt_id = StringName(d.get("shirt_id", "tshirt_basic"))
	var sc: Array = d.get("shirt_color", [0.25, 0.45, 0.7, 1.0])
	shirt_color = Color(sc[0], sc[1], sc[2], sc[3])
	pants_id = StringName(d.get("pants_id", "jeans_basic"))
	var pc: Array = d.get("pants_color", [0.2, 0.22, 0.3, 1.0])
	pants_color = Color(pc[0], pc[1], pc[2], pc[3])
	shoes_id = StringName(d.get("shoes_id", "sneaker_basic"))
