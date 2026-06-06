## network_service.gd
## 多人联机服务 — ENet RPC stub
##
## 真实集成：替换 ENetMultiplayerPeer + MultiplayerAPI.rpc()
## 离线模式：所有网络调用 no-op
##
## 用法：
##   Network.host_game("My Room", 4)
##   Network.join_game("192.168.1.10", 7777)
##   Network.rpc_call("player_moved", [x, y])
##
## RPC 方法需要在参与方都有同名函数（@rpc("any_peer", "call_local", "reliable")）
extends Node

const _Self := preload("res://core/autoload/network_service.gd")
const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 4

enum Mode { OFFLINE, HOST, CLIENT }

var current_mode: int = Mode.OFFLINE
var peer_id: int = 0  # 0 = offline, 1 = host, 2-4 = clients
var connected_peers: Array[int] = []  # 在线玩家 ID 列表

## 房间名（仅 host）
var room_name: String = ""

signal player_joined(peer_id: int)
signal player_left(peer_id: int)
signal connected_to_server
signal connection_failed
signal disconnected_from_server
signal room_state_received(state: Dictionary)


## Host 模式开服
func host_game(room: String = "Fate Gear Room", port: int = DEFAULT_PORT, max_players: int = MAX_PLAYERS) -> bool:
	# 真实实现：
	#   var peer := ENetMultiplayerPeer.new()
	#   var err := peer.create_server(port, max_players)
	#   if err != OK: return false
	#   multiplayer.multiplayer_peer = peer
	#   multiplayer.peer_connected.connect(_on_peer_connected)
	#   multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	current_mode = Mode.HOST
	peer_id = 1
	connected_peers = [1]
	room_name = room
	print("Hosted: %s on port %d (mock)" % [room, port])
	return true


## 加入游戏
func join_game(host: String, port: int = DEFAULT_PORT) -> bool:
	# 真实：
	#   var peer := ENetMultiplayerPeer.new()
	#   var err := peer.create_client(host, port)
	#   if err != OK: return false
	#   multiplayer.multiplayer_peer = peer
	#   multiplayer.connected_to_server.connect(_on_connected)
	#   multiplayer.connection_failed.connect(_on_connection_failed)
	current_mode = Mode.CLIENT
	peer_id = 2  # 假设第二个加入
	connected_peers = [1, 2]
	print("Joined: %s:%d (mock)" % [host, port])
	connected_to_server.emit()
	return true


## 离开 / 关闭
func leave_game() -> void:
	# 真实：multiplayer.multiplayer_peer.close()
	current_mode = Mode.OFFLINE
	peer_id = 0
	connected_peers = []
	disconnected_from_server.emit()


## RPC 调用
func rpc_call(method: String, args: Array = []) -> void:
	if current_mode == Mode.OFFLINE:
		return
	# 真实：multiplayer.rpc(method, args)
	# 或：multiplayer.rpc_id(peer_id, method, args)
	pass


## 同步房间状态（player 位置、属性等）
func broadcast_state(state: Dictionary) -> void:
	if current_mode == Mode.OFFLINE: return
	# 真实：multiplayer.rpc("receive_state", state)
	# 其他客户端触发 room_state_received.emit(state)
	room_state_received.emit(state)


## 完整状态快照（30fps 同步）
func get_state_snapshot() -> Dictionary:
	return {
		"players": [{
			"id": peer_id,
			"name": Player.player_name,
			"x": 320,  # TODO: 实际玩家位置
			"y": 180,
		}],
		"day": TimeMgr.day,
		"hour": TimeMgr.hour,
		"weather": WeatherManager.current_weather,
		"cash": Player.cash,
	}


# === 内部 handlers (注释) ===
# func _on_peer_connected(id: int):
#     connected_peers.append(id)
#     player_joined.emit(id)
#
# func _on_peer_disconnected(id: int):
#     connected_peers.erase(id)
#     player_left.emit(id)
#
# func _on_connected():
#     connected_to_server.emit()
#
# func _on_connection_failed():
#     connection_failed.emit()
#     leave_game()
#
# @rpc("any_peer", "call_local", "reliable")
# func receive_state(state: Dictionary):
#     room_state_received.emit(state)
#
# @rpc("any_peer", "call_local", "reliable")
# func player_moved(x: float, y: float):
#     pass
