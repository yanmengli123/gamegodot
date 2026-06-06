## tilemap_autoload.gd
## TileMap 自动初始化 — 启动时生成 world tileset
extends Node


func _ready() -> void:
	call_deferred("_ensure_tileset")


func _ensure_tileset() -> void:
	var path: String = "res://data/tilesets/world_tileset.tres"
	if not ResourceLoader.exists(path):
		TileMapBuilder.save_world_tileset()
