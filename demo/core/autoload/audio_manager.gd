## audio_manager.gd
## 音频管理 — 用程序化音频（无需文件依赖）
extends Node

const _SELF := preload("res://core/autoload/audio_manager.gd")
const MAX_SFX: int = 16
const BGM_FADE: float = 1.0

## 缓存程序化生成的音频流
var _sfx_cache: Dictionary = {}
var _bgm_cache: Dictionary = {}

var _current_bgm: AudioStreamPlayer = null
var _bgm_volume: float = 0.6
var _sfx_volume: float = 0.7
var _ambient_volume: float = 0.5
var _current_bgm_kind: String = ""
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_idx: int = 0


func _ready() -> void:
	_preload_audio()
	for i in range(MAX_SFX):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)


func _preload_audio() -> void:
	# SFX — 优先用文件，回退程序化
	_sfx_cache["click"] = BGMLibrary.get_sfx("click")
	_sfx_cache["footstep"] = BGMLibrary.get_sfx("footstep")
	_sfx_cache["coin"] = BGMLibrary.get_sfx("coin")
	_sfx_cache["notify"] = BGMLibrary.get_sfx("notify")
	_sfx_cache["error"] = BGMLibrary.get_sfx("error")
	# BGM — 优先用文件，回退程序化
	_bgm_cache["jincheng"] = BGMLibrary.get_stream("jincheng")
	_bgm_cache["indoor"] = BGMLibrary.get_stream("indoor")
	_bgm_cache["work"] = BGMLibrary.get_stream("work")


## 播放 BGM
func play_bgm(kind: String = "jincheng", fade_in: bool = true) -> void:
	if _current_bgm_kind == kind and _current_bgm != null and is_instance_valid(_current_bgm):
		return
	if not _bgm_cache.has(kind):
		push_warning("BGM kind '%s' not found" % kind)
		return
	_current_bgm_kind = kind
	var stream: AudioStream = _bgm_cache[kind]
	# 淡出旧的
	if _current_bgm != null and is_instance_valid(_current_bgm):
		var old: AudioStreamPlayer = _current_bgm
		var tween: Tween = create_tween()
		tween.tween_property(old, "volume_db", -40.0, BGM_FADE)
		tween.tween_callback(old.queue_free)
	# 新的
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = "BGM"
	p.stream = stream
	p.volume_db = -40.0 if fade_in else linear_to_db(_bgm_volume) if _bgm_volume > 0 else 0
	add_child(p)
	p.play()
	if fade_in:
		var tween2: Tween = create_tween()
		tween2.tween_property(p, "volume_db", linear_to_db(_bgm_volume) if _bgm_volume > 0 else 0, BGM_FADE)
	_current_bgm = p


func stop_bgm(fade_out: bool = true) -> void:
	if _current_bgm == null: return
	if fade_out:
		var tween: Tween = create_tween()
		tween.tween_property(_current_bgm, "volume_db", -40.0, BGM_FADE)
		tween.tween_callback(_current_bgm.queue_free)
	else:
		_current_bgm.queue_free()
	_current_bgm = null
	_current_bgm_kind = ""


## 播放 SFX（按名字）
func play_sfx(name: String) -> void:
	if not _sfx_cache.has(name): return
	if _sfx_pool.is_empty(): return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
	p.stream = _sfx_cache[name]
	p.volume_db = linear_to_db(_sfx_volume) if _sfx_volume > 0 else -40
	p.play()


## 音量
func set_bgm_volume(v: float) -> void:
	_bgm_volume = clampf(v, 0.0, 1.0)
	if _current_bgm != null and is_instance_valid(_current_bgm):
		_current_bgm.volume_db = linear_to_db(_bgm_volume) if _bgm_volume > 0 else -40

func set_sfx_volume(v: float) -> void:
	_sfx_volume = clampf(v, 0.0, 1.0)

func set_ambient_volume(v: float) -> void:
	_ambient_volume = clampf(v, 0.0, 1.0)
