## world_scene.gd
## 世界场景基类 — 每个场景继承它获得统一行为：
##   - 加载时初始化 NPC（按时间表）
##   - 玩家传送点
##   - 摄像机边界
##   - 退出时清理
##
## 场景结构：
##   WorldScene (Node2D, 本脚本)
##   ├── WorldRoot (Node2D)  实际世界节点
##   │   ├── TileMap / Background (占位)
##   │   ├── NPCs (Node2D)
##   │   └── Player (从 main 实例化或本场景自带)
##   └── EntryPoints (Node2D)
extends Node2D

@export var scene_id: StringName = &""

@onready var world_root: Node2D = $WorldRoot
@onready var npcs_container: Node2D = $WorldRoot/NPCs
@onready var entry_points: Node2D = $EntryPoints


func _ready() -> void:
	# 摄像机边界
	var data: SceneData = Scenes.get_scene_data(String(scene_id))
	if data != null and get_viewport().get_camera_2d() != null:
		get_viewport().get_camera_2d().set_bounds(data.bounds)
	# 加载该场景应有的 NPC
	_spawn_npcs()


func _spawn_npcs() -> void:
	for child in npcs_container.get_children():
		child.queue_free()
	var data: SceneData = Scenes.get_scene_data(String(scene_id))
	if data == null: return
	# 找此场景的 NPC
	for npc_data in NPCFactory.create_all():
		var npc: Node = null
		for sched in npc_data.schedules:
			if String(sched.scene_id) == String(scene_id):
				var scene := load("res://scenes/npc/NPC.tscn")
				npc = scene.instantiate()
				npc.data = npc_data
				npc.global_position = sched.target_position
				npcs_container.add_child(npc)
				break
