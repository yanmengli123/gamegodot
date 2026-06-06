## dlc_service.gd
## DLC 系统 — 数据驱动的可下载内容
##
## 真实集成：通过 Steam.Service.IsDLCInstalled() 检测
## 离线模式：用户可手动启用/禁用 DLC（用于演示）
##
## 用法：
##   DLC.register("dlc_night_city", "夜城之梦", "解锁夜间场景和新对话")
##   if DLC.is_enabled("dlc_night_city"):
##       # 显示新场景
extends Node

## DLC 信息
class DLCInfo:
	extends Resource
	var dlc_id: String
	var display_name: String
	var description: String
	var steam_app_id: int  # 对应 Steam DLC app_id
	var icon_color: Color
	var is_free: bool
	var price_cny: int


## 已注册 DLC
var _registry: Dictionary = {}

## 玩家启用的 DLC（可手动开启 demo 用）
## 真实：基于 Steam.Service.IsDLCInstalled()
var _enabled: Dictionary = {}


func _ready() -> void:
	_register_default_dlcs()
	EventBus.dlc_enabled.connect(_on_dlc_enabled)


## 注册 DLC
func register(dlc_id: String, name: String, description: String, steam_app_id: int = 0, price: int = 0, is_free: bool = false) -> void:
	var info := DLCInfo.new()
	info.dlc_id = dlc_id
	info.display_name = name
	info.description = description
	info.steam_app_id = steam_app_id
	info.is_free = is_free
	info.price_cny = price
	info.icon_color = Color(0.6, 0.4, 0.9)
	_registry[dlc_id] = info


## 检查 DLC 是否启用（真实：Steam.Service.IsDLCInstalled()）
func is_enabled(dlc_id: String) -> bool:
	if not _registry.has(dlc_id): return false
	# 离线模式用 _enabled dict
	if _enabled.get(dlc_id, false):
		return true
	# 在线：检查 Steam
	if Steam.is_initialized and not Steam.is_offline:
		return false  # 真实：Steam.isDLCInstalled(_registry[dlc_id].steam_app_id)
	return false


## 手动启用（演示 / 测试用）
func enable_demo(dlc_id: String) -> void:
	if not _registry.has(dlc_id): return
	_enabled[dlc_id] = true
	EventBus.dlc_enabled.emit(dlc_id)


## 手动禁用
func disable(dlc_id: String) -> void:
	_enabled[dlc_id] = false


## 列出所有
func list_all() -> Array:
	var arr: Array = []
	for id in _registry:
		arr.append(_registry[id])
	return arr


## 列出已启用的
func list_enabled() -> Array:
	var arr: Array = []
	for id in _registry:
		if is_enabled(id):
			arr.append(_registry[id])
	return arr


# === 默认 DLC 包 ===
func _register_default_dlcs() -> void:
	register("dlc_night_city", "夜城之梦", "解锁夜间专属场景、新 NPC、新对话、夜班工作", 1001, 25)
	register("dlc_overseas", "海外篇", "解锁海外剧情线：东京、首尔、曼谷", 1002, 35)
	register("dlc_chef_pack", "厨神包", "解锁全部 30 道食谱 + 厨师专属结局", 1003, 18)
	register("dlc_pet", "萌宠包", "解锁宠物系统：猫、狗、乌龟，可收养", 1004, 12)
	register("dlc_soundtrack", "原声大碟", "解锁 12 首原创 BGM + 钢琴版", 1005, 0, true)


func _on_dlc_enabled(dlc_id: String) -> void:
	# 通知其他系统（DLC 启用时刷新场景、加载新数据等）
	print("DLC enabled: %s" % dlc_id)
