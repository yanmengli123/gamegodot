## steam_service.gd
## Steam 集成 stub — 接入 GodotSteam GDExtension
##
## 真实集成步骤：
##   1. 下载 GodotSteam：https://github.com/Grashopr/godot_steam/releases
##   2. 解压后把 gdsteam/ 整个目录放到 demo/addons/godotsteam/
##   3. project.godot 启用插件：enabled = PackedStringArray("res://addons/godotsteam/plugin.cfg")
##   4. 把本文件的 mock 实现替换成真实 Steam.* 调用
##
## 本文件提供完整接口 + mock 实现（不依赖 Steamworks SDK 即可跑）
extends Node

const _SELF := preload("res://core/autoload/steam_service.gd")

## 是否已初始化
var is_initialized: bool = false
var steam_id: String = "STEAM_MOCK_12345"
var steam_username: String = "LocalUser"
var app_id: int = 480  # Spacewar（默认测试 app）
var is_offline: bool = true

## 成就
signal achievement_unlocked(achievement_id: String)
## 云存档
signal cloud_save_synced(success: bool)

## 统计
var achievements_unlocked: Array[String] = []
var total_playtime_minutes: int = 0


func _ready() -> void:
	# 真实实现：Steam.steamInit()
	# 离线模式默认 true（不连接 Steam）
	is_offline = true
	is_initialized = true
	print("SteamService initialized (offline mode)")


## 实际 Steam.steamInit() 调用方式（注释保留）：
##   if not Steam.steamInit():
##       push_error("Steam init failed")
##       return
##   self.steam_id = str(Steam.getSteamID())
##   self.steam_username = Steam.getPersonaName()
##   self.app_id = Steam.getAppID()


## 解锁成就
func unlock_achievement(achievement_id: String) -> void:
	if achievements_unlocked.has(achievement_id): return
	achievements_unlocked.append(achievement_id)
	# 真实：Steam.setAchievement(achievement_id, true); Steam.storeStats()
	achievement_unlocked.emit(achievement_id)
	print("🏆 Achievement unlocked: %s" % achievement_id)


## 重置成就（用于二周目）
func reset_achievements() -> void:
	achievements_unlocked.clear()
	# 真实：Steam.resetAllStats(true)


## 同步云存档
func sync_cloud_save(slot: int, data: Dictionary) -> bool:
	# 真实：Steam.fileWrite(...)
	print("Cloud save sync (slot %d): %d bytes" % [slot, JSON.stringify(data).length()])
	cloud_save_synced.emit(true)
	return true


## 从云端加载
func load_cloud_save(slot: int) -> Dictionary:
	# 真实：Steam.fileRead(...)
	print("Cloud save load (slot %d)" % slot)
	return {}


## 邀请好友
func invite_friend() -> void:
	# 真实：Steam.activateGameOverlayInviteDialog(Steam.getLobbyOwner())
	print("Steam friend invite (mock)")


## 打开 Steam 商店页面
func open_store_page() -> void:
	# 真实：Steam.activateGameOverlayToWebPage("store.steampowered.com/app/%d" % app_id)
	print("Opening Steam store page (mock)")


## 打开成就面板
func open_achievements() -> void:
	# 真实：Steam.activateGameOverlay("Achievements")
	print("Opening Steam achievements overlay (mock)")


## 报告游戏状态
func report_game_state(in_menu: bool = false) -> void:
	# 真实：Steam.getInputType() 等
	pass


## 关闭时调用
func shutdown() -> void:
	# 真实：Steam.dismissFloatingGamepadTextInputIfNecessary() 等
	# 真实：Steam.steamShutdown()
	is_initialized = false


# === Steam Workshop 集成 ===

## 列出玩家已订阅的 Workshop 物品
## 真实：Steam.ugcGetSubscribedItems()
func get_subscribed_workshop_items() -> Array[Dictionary]:
	if is_offline: return []
	# 真实：Steam.getSubscribedItems() 返回 PublishedFileId_t 列表
	# 然后 Steam.ugcQueryUGCDetails() 获取详情
	return []


## 玩家是否订阅了某物品
func has_workshop_item(workshop_id: String) -> bool:
	if is_offline: return false
	# 真实：检查 get_subscribed_workshop_items() 里
	return false


## 打开 Workshop 浏览页
func open_workshop_browser() -> void:
	# 真实：Steam.activateGameOverlayToWebPage("steamcommunity.com/app/%d/workshop" % app_id)
	print("Opening Steam Workshop browser (mock)")


## 订阅 / 取消订阅
func subscribe_to_item(workshop_id: String) -> bool:
	# 真实：Steam.ugcSubscribeItem(workshop_id)
	print("Subscribed to Workshop item: %s" % workshop_id)
	return true

func unsubscribe_from_item(workshop_id: String) -> bool:
	# 真实：Steam.ugcUnsubscribeItem(workshop_id)
	print("Unsubscribed: %s" % workshop_id)
	return true


## 下载 Workshop mod
func download_workshop_item(workshop_id: String) -> bool:
	# 真实：Steam.ugcDownloadItem(workshop_id)
	# 完成后用 Steam.ugcGetItemDownloadInfo() 查询进度
	print("Downloading Workshop item: %s" % workshop_id)
	return true


## 上传玩家的 mod
func upload_workshop_item(title: String, description: String, file_path: String) -> bool:
	# 真实：Steam.ugcCreateItem() 然后 ugcSubmitItemUpdate()
	print("Uploaded: %s (%s)" % [title, file_path])
	return true


# === Steam P2P / Lobbies（多人游戏）===

## 创建 Steam 大厅
func create_lobby(lobby_type: int = 0, max_members: int = 4) -> String:
	# 真实：Steam.lobbyCreated.connect(...) + Steam.createLobby(lobby_type, max_members)
	# 返回 lobby_id
	print("Created Steam lobby (mock)")
	return "MOCK_LOBBY_12345"

## 加入大厅
func join_lobby(lobby_id: String) -> bool:
	# 真实：Steam.joinLobby(lobby_id)
	print("Joined Steam lobby: %s" % lobby_id)
	return true

## 离开大厅
func leave_lobby(lobby_id: String) -> void:
	# 真实：Steam.leaveLobby(lobby_id)
	print("Left Steam lobby: %s" % lobby_id)


## 12 结局对应成就 ID
const ENDING_ACHIEVEMENTS: Dictionary = {
	"ending_boss": "ACH_BECAME_BOSS",
	"ending_foreman": "ACH_FOREMAN",
	"ending_chef": "ACH_BECAME_CHEF",
	"ending_milk_tea": "ACH_MILK_TEA_SHOP",
	"ending_couple_saving": "ACH_COUPLE",
	"ending_homeless": "ACH_HOMELESS",
	"ending_debt": "ACH_DEBT",
	"ending_prison": "ACH_PRISON",
	"ending_worker": "ACH_ORDINARY_CITIZEN",
	"ending_student": "ACH_BACK_TO_SCHOOL",
	"ending_back_home": "ACH_BACK_HOME",
	"ending_story_complete": "ACH_GRAND_FINALE",
}


## 当结局触发时调用
func unlock_ending_achievement(ending_id: String) -> void:
	if ENDING_ACHIEVEMENTS.has(ending_id):
		unlock_achievement(ENDING_ACHIEVEMENTS[ending_id])
