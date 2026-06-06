## train_station.gd
## 火车站广场 — 用 TileMap
extends Node2D

const _Self := preload("res://scenes/world/train_station.gd")

@onready var world_root: Node2D = $WorldRoot
@onready var npcs_container: Node2D = $WorldRoot/NPCs
@onready var entry_points: Node2D = $EntryPoints
@onready var ground_layer: TileMapLayer = $WorldRoot/GroundLayer
@onready var decor_layer: TileMapLayer = $WorldRoot/DecorLayer


func _ready() -> void:
	var ts: TileSet = load("res://data/tilesets/world_tileset.tres")
	if ts != null:
		ground_layer.tile_set = ts
		decor_layer.tile_set = ts
	TileMapBuilder.fill_layer(ground_layer, _ground_tiles(), ts)
	TileMapBuilder.fill_layer(decor_layer, _decor_tiles(), ts)
	# 摄像机
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam != null:
		cam.set_bounds(Rect2i(0, 0, 1280, 360))
	_spawn_npcs()
	# 播放 BGM
	Audio.play_bgm("jincheng")


func _ground_tiles() -> Array:
	var arr: Array = []
	# 80x23 tile 网格（1280/16 × 360/16 = 80 × 22.5）
	# 地面：ground variant
	for x in range(80):
		for y in range(15, 23):
			arr.append({"x": x, "y": y, "kind": "ground", "variant": (x + y) % 4})
	# 道路（人行横道）
	for x in range(20, 60):
		arr.append({"x": x, "y": 14, "kind": "road", "variant": x % 2})
		arr.append({"x": x, "y": 13, "kind": "road", "variant": x % 2})
	return arr


func _decor_tiles() -> Array:
	var arr: Array = []
	# 火车站建筑（wall）
	for x in range(10, 30):
		arr.append({"x": x, "y": 5, "kind": "wall", "variant": 0})
		arr.append({"x": x, "y": 6, "kind": "wall", "variant": 1})
		arr.append({"x": x, "y": 7, "kind": "wall", "variant": 2})
		arr.append({"x": x, "y": 8, "kind": "wall", "variant": 3})
	# 树
	arr.append({"x": 65, "y": 10, "kind": "grass", "variant": 0})
	arr.append({"x": 66, "y": 10, "kind": "grass", "variant": 1})
	arr.append({"x": 75, "y": 10, "kind": "grass", "variant": 2})
	arr.append({"x": 76, "y": 10, "kind": "grass", "variant": 3})
	return arr


func _spawn_npcs() -> void:
	for child in npcs_container.get_children():
		child.queue_free()
	for npc_data in NPCFactory.create_all():
		for sched in npc_data.schedules:
			if String(sched.scene_id) == "train_station":
				var scene_p: PackedScene = load("res://scenes/npc/NPC.tscn")
				var npc: Node = scene_p.instantiate()
				npc.data = npc_data
				npc.global_position = sched.target_position
				npcs_container.add_child(npc)
				break
