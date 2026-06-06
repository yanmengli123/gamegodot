## world_scene.gd
## 世界场景基类 — TileMap + 玩家 + NPC
extends Node2D

@export var scene_id: StringName = &""
@export var tilemap_data: Array = []  # 阶段七简化为 ColorRect；阶段十用 TileMap

@onready var world_root: Node2D = $WorldRoot
@onready var npcs_container: Node2D = $WorldRoot/NPCs
@onready var entry_points: Node2D = $EntryPoints
@onready var ground_layer: TileMapLayer = $WorldRoot/GroundLayer
@onready var decor_layer: TileMapLayer = $WorldRoot/DecorLayer


func _ready() -> void:
	# 加载 TileSet
	var ts: TileSet = load("res://data/tilesets/world_tileset.tres")
	if ts != null:
		ground_layer.tile_set = ts
		decor_layer.tile_set = ts
	# 填充 TileMap
	TileMapBuilder.fill_layer(ground_layer, _get_ground_tiles(), ts)
	TileMapBuilder.fill_layer(decor_layer, _get_decor_tiles(), ts)
	# 摄像机边界
	var data: SceneData = Scenes.get_scene_data(String(scene_id))
	if data != null and get_viewport().get_camera_2d() != null:
		get_viewport().get_camera_2d().set_bounds(data.bounds)
	# NPC
	_spawn_npcs()


func _spawn_npcs() -> void:
	for child in npcs_container.get_children():
		child.queue_free()
	var data: SceneData = Scenes.get_scene_data(String(scene_id))
	if data == null: return
	for npc_data in NPCFactory.create_all():
		for sched in npc_data.schedules:
			if String(sched.scene_id) == String(scene_id):
				var scene_p: PackedScene = load("res://scenes/npc/NPC.tscn")
				var npc: Node = scene_p.instantiate()
				npc.data = npc_data
				npc.global_position = sched.target_position
				npcs_container.add_child(npc)
				break


## 子类覆写：返回 tile 数组
func _get_ground_tiles() -> Array:
	return []

func _get_decor_tiles() -> Array:
	return []
