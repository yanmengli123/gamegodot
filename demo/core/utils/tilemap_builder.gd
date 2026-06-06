## tilemap_builder.gd
## 程序化 TileSet 构建器 — 用 PixelArtist 生成 tile
## 阶段十美术到位后用真实 TileSet 资源替换
class_name TileMapBuilder
extends RefCounted

const _Self := preload("res://core/utils/tilemap_builder.gd")
const TILE_SIZE: int = 16


## 构造一个 TileSet 资源（4 套 tile 风格）
## 存到 res://data/tilesets/world.tres
static func build_world_tileset() -> TileSet:
	var ts: TileSet = TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Source 1: ground (atlas 4 tiles 横向)
	var ground_atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	var ground_img: Image = Image.create(TILE_SIZE * 4, TILE_SIZE, false, Image.FORMAT_RGBA8)
	ground_img.fill(Color(0, 0, 0, 0))
	for v in range(4):
		var tile_img: ImageTexture = PixelArtist.make_ground_tile(v)
		var tile_size: Vector2i = Vector2i(TILE_SIZE, TILE_SIZE)
		ground_atlas.texture = tile_img  # 用单 tile texture
		# 创建 atlas
		break
	# 简化：用 4 个独立 source
	for v in range(4):
		var src: TileSetAtlasSource = TileSetAtlasSource.new()
		src.texture = PixelArtist.make_ground_tile(v)
		src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		ts.add_source(src)
	# Wall (4 variants)
	for v in range(4):
		var src: TileSetAtlasSource = TileSetAtlasSource.new()
		src.texture = PixelArtist.make_wall_tile(v)
		src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		ts.add_source(src)
	# Road
	for v in range(2):
		var src: TileSetAtlasSource = TileSetAtlasSource.new()
		src.texture = PixelArtist.make_road_tile(v)
		src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		ts.add_source(src)
	# Grass
	for v in range(4):
		var src: TileSetAtlasSource = TileSetAtlasSource.new()
		src.texture = PixelArtist.make_grass_tile(v)
		src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		ts.add_source(src)
	# Floor (indoor)
	for v in range(2):
		var src: TileSetAtlasSource = TileSetAtlasSource.new()
		src.texture = PixelArtist.make_floor_tile(v)
		src.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		ts.add_source(src)

	return ts


## 把 TileSet 存到磁盘
static func save_world_tileset() -> String:
	var ts: TileSet = build_world_tileset()
	var path: String = "res://data/tilesets/world_tileset.tres"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/tilesets"))
	var result: int = ResourceSaver.save(ts, path)
	if result != OK:
		push_error("Failed to save tileset: %d" % result)
	return path


## 用 tile id 数组生成 TileMapLayer 节点
## tiles: Array of {x, y, source_id, atlas_coord} 或简化的 {x, y, kind}
static func fill_layer(layer: TileMapLayer, tiles: Array, tileset: TileSet) -> void:
	if layer == null or tileset == null: return
	layer.tile_set = tileset
	for t in tiles:
		var kind: String = t.get("kind", "ground")
		var variant: int = int(t.get("variant", 0))
		var x: int = int(t.get("x", 0))
		var y: int = int(t.get("y", 0))
		var source_id: int = _source_id_for_kind(tileset, kind, variant)
		if source_id < 0: continue
		var atlas: Vector2i = Vector2i(0, 0)  # 每个 source 单 tile
		layer.set_cell(Vector2i(x, y), source_id, atlas)


static func _source_id_for_kind(tileset: TileSet, kind: String, variant: int) -> int:
	# source 顺序：ground(0-3) wall(4-7) road(8-9) grass(10-13) floor(14-15)
	match kind:
		"ground": return variant % 4
		"wall": return 4 + (variant % 4)
		"road": return 8 + (variant % 2)
		"grass": return 10 + (variant % 4)
		"floor": return 14 + (variant % 2)
	return -1
