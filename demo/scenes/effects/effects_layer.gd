## effects_layer.gd
## 视觉特效层 — 雨/雪/受伤闪红 — 根据 WeatherManager 自动启用
extends Node2D

@onready var rain: CPUParticles2D = $PixelRain


func _ready() -> void:
	EventBus.day_started.connect(_on_day_started)
	_on_day_started(0)


func _on_day_started(_d: int) -> void:
	# 把雨滴对齐到当前摄像机视口
	if rain == null: return
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam != null:
		rain.global_position = cam.global_position
	# 按天气调整
	var intensity: int = 0
	match WeatherManager.current_weather:
		WeatherManager.Weather.LIGHT_RAIN: intensity = 2
		WeatherManager.Weather.HEAVY_RAIN: intensity = 3
		WeatherManager.Weather.STORM: intensity = 4
		_: intensity = 0
	rain.set_intensity(intensity)
