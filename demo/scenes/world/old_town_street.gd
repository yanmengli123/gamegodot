## old_town_street.gd
extends Node2D

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
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam != null:
		cam.set_bounds(Rect2i(0, 0, 1920, 360))
	_spawn_npcs()
	Audio.play_bgm("jincheng")


func _ground_tiles() -> Array:
	var arr: Array = []
	for x in range(120):
		for y in range(15, 23):
			arr.append({"x": x, "y": y, "kind": "ground", "variant": (x + y) % 4})
	return arr


func _decor_tiles() -> Array:
	var arr: Array = []
	# 老街两侧建筑
	for y in range(3, 12):
		for x in range(5, 25):
			arr.append({"x": x, "y": y, "kind": "wall", "variant": (x + y) % 4})
		for x in range(95, 115):
			arr.append({"x": x, "y": y, "kind": "wall", "variant": (x + y) % 4})
	# 树
	for x in [35, 45, 55, 65, 75, 85]:
		arr.append({"x": x, "y": 11, "kind": "grass", "variant": (x / 5) % 4})
	return arr


func _spawn_npcs() -> void:
	for child in npcs_container.get_children():
		child.queue_free()
	for npc_data in NPCFactory.create_all():
		for sched in npc_data.schedules:
			if String(sched.scene_id) == "old_town_street":
				var scene_p: PackedScene = load("res://scenes/npc/NPC.tscn")
				var npc: Node = scene_p.instantiate()
				npc.data = npc_data
				npc.global_position = sched.target_position
				npcs_container.add_child(npc)
				break
