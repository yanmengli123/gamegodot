## scene_data.gd
## 场景数据 — 一个游戏内地点的元信息
class_name SceneData
extends Resource

@export var scene_id: StringName = &""
@export var display_name: String = ""
@export var scene_path: String = ""
@export var region: String = ""  # train_station / old_town / commercial / industrial / residential
## 入口位置 {spawn_name: Vector2}
@export var spawn_points: Dictionary = {}
## 该场景中的 NPC 列表（每个 {npc_id, period}）
@export var npc_schedules: Array = []
## 边界（摄像机限制）Rect2i
@export var bounds: Rect2i = Rect2i(-10000, -10000, 20000, 20000)
## 区域（train_station = 起始）
@export var is_starting_area: bool = false


static func create_all() -> Array[SceneData]:
	return [
		_make(&"train_station", "火车站广场", "res://scenes/world/train_station.tscn", "train_station", true,
			{"default": Vector2(320, 180), "from_old_town": Vector2(580, 160)},
			Rect2i(0, 0, 1280, 360)),
		_make(&"old_town_market", "老城菜市场", "res://scenes/world/old_town_market.tscn", "old_town", false,
			{"default": Vector2(320, 180), "from_street": Vector2(50, 180)},
			Rect2i(0, 0, 1280, 360)),
		_make(&"old_town_street", "老城老街", "res://scenes/world/old_town_street.tscn", "old_town", false,
			{"default": Vector2(320, 180)},
			Rect2i(0, 0, 1920, 360)),
		_make(&"internet_cafe", "网吧", "res://scenes/world/internet_cafe.tscn", "old_town", false,
			{"default": Vector2(320, 200)},
			Rect2i(0, 0, 640, 360)),
		_make(&"industrial_site", "建筑工地", "res://scenes/world/industrial_site.tscn", "industrial", false,
			{"default": Vector2(320, 180)},
			Rect2i(0, 0, 1920, 360)),
	]


static func _make(id: StringName, name: String, path: String, region: String, starting: bool,
		spawns: Dictionary, bounds: Rect2i) -> SceneData:
	var s := SceneData.new()
	s.scene_id = id
	s.display_name = name
	s.scene_path = path
	s.region = region
	s.is_starting_area = starting
	s.spawn_points = spawns
	s.bounds = bounds
	return s


static func build_index(arr: Array) -> Dictionary:
	var idx: Dictionary = {}
	for s in arr:
		idx[String(s.scene_id)] = s
	return idx
