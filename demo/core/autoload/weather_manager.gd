## weather_manager.gd
## 天气系统 — 每日随机天气，受季节影响
extends Node

enum Weather { SUNNY, CLOUDY, LIGHT_RAIN, HEAVY_RAIN, STORM, LIGHT_SNOW, HEAVY_SNOW, FOG }

const _SELF := preload("res://core/autoload/weather_manager.gd")

var current_weather: int = Weather.SUNNY
var tomorrow_weather: int = Weather.SUNNY


func _ready() -> void:
	EventBus.day_started.connect(_on_day_started)
	_roll_today()


func _on_day_started(_day: int) -> void:
	current_weather = tomorrow_weather
	_roll_today()


func _roll_today() -> void:
	# 季节权重
	var season: int = TimeMgr.season
	var pool: Array = _weather_pool(season)
	tomorrow_weather = pool[randi() % pool.size()]


func _weather_pool(season: int) -> Array:
	match season:
		TimeMgr.Season.SPRING:  # 3-5 月
			return [Weather.SUNNY, Weather.SUNNY, Weather.CLOUDY, Weather.CLOUDY, Weather.LIGHT_RAIN, Weather.LIGHT_RAIN, Weather.HEAVY_RAIN, Weather.FOG]
		TimeMgr.Season.SUMMER:  # 6-8 月
			return [Weather.SUNNY, Weather.SUNNY, Weather.SUNNY, Weather.CLOUDY, Weather.HEAVY_RAIN, Weather.STORM, Weather.STORM]
		TimeMgr.Season.AUTUMN:  # 9-11 月
			return [Weather.SUNNY, Weather.CLOUDY, Weather.CLOUDY, Weather.LIGHT_RAIN, Weather.FOG, Weather.HEAVY_RAIN]
		TimeMgr.Season.WINTER:  # 12-2 月
			return [Weather.CLOUDY, Weather.CLOUDY, Weather.LIGHT_SNOW, Weather.LIGHT_SNOW, Weather.HEAVY_SNOW, Weather.FOG, Weather.HEAVY_RAIN]
	return [Weather.SUNNY]


## 是否取消户外工作
func cancels_outdoor_work() -> bool:
	return current_weather in [Weather.HEAVY_RAIN, Weather.STORM, Weather.HEAVY_SNOW]


## 移动速度倍率
func move_speed_mult() -> float:
	if current_weather in [Weather.LIGHT_SNOW, Weather.HEAVY_SNOW]:
		return 0.85
	return 1.0


## 天气名
static func name_of(w: int) -> String:
	match w:
		Weather.SUNNY: return "晴"
		Weather.CLOUDY: return "多云"
		Weather.LIGHT_RAIN: return "小雨"
		Weather.HEAVY_RAIN: return "大雨"
		Weather.STORM: return "暴风雨"
		Weather.LIGHT_SNOW: return "小雪"
		Weather.HEAVY_SNOW: return "大雪"
		Weather.FOG: return "雾霾"
	return "未知"


## 图标颜色（占位）
static func color_of(w: int) -> Color:
	match w:
		Weather.SUNNY: return Color.YELLOW
		Weather.CLOUDY: return Color(0.7, 0.7, 0.7)
		Weather.LIGHT_RAIN: return Color(0.4, 0.6, 0.9)
		Weather.HEAVY_RAIN: return Color(0.2, 0.3, 0.6)
		Weather.STORM: return Color(0.1, 0.1, 0.3)
		Weather.LIGHT_SNOW: return Color(0.9, 0.9, 1.0)
		Weather.HEAVY_SNOW: return Color(0.7, 0.8, 1.0)
		Weather.FOG: return Color(0.5, 0.5, 0.5)
	return Color.WHITE
