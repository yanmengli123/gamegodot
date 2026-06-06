## audio_manager.gd
## 音频管理 — BGM 淡入淡出 + SFX 池
## 阶段九只搭骨架，所有音频文件用 null（程序化占位）
extends Node

const _SELF := preload("res://core/autoload/audio_manager.gd")
const MAX_SFX: int = 16
const BGM_FADE: float = 1.0

var _current_bgm: AudioStreamPlayer = null
var _bgm_volume: float = 0.8
var _sfx_volume: float = 0.8
var _ambient_volume: float = 0.5
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_idx: int = 0


func _ready() -> void:
	# 预建 SFX 池
	for i in range(MAX_SFX):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)


## 播放 BGM（带淡入淡出）
func play_bgm(stream: AudioStream, fade_in: bool = true) -> void:
	if stream == null:
		# 占位：什么都不做
		_current_bgm = null
		return
	if _current_bgm != null and is_instance_valid(_current_bgm):
		var old: AudioStreamPlayer = _current_bgm
		var tween: Tween = create_tween()
		tween.tween_property(old, "volume_db", -40.0, BGM_FADE)
		tween.tween_callback(old.queue_free)
	var new_player: AudioStreamPlayer = AudioStreamPlayer.new()
	new_player.bus = "BGM"
	new_player.stream = stream
	new_player.volume_db = -40.0 if fade_in else 0
	add_child(new_player)
	new_player.play()
	if fade_in:
		var tween2: Tween = create_tween()
		tween2.tween_property(new_player, "volume_db", 0, BGM_FADE)
	_current_bgm = new_player


func stop_bgm(fade_out: bool = true) -> void:
	if _current_bgm == null: return
	if fade_out:
		var tween: Tween = create_tween()
		tween.tween_property(_current_bgm, "volume_db", -40.0, BGM_FADE)
		tween.tween_callback(_current_bgm.queue_free)
	else:
		_current_bgm.queue_free()
	_current_bgm = null


## 播放 SFX
func play_sfx(stream: AudioStream) -> void:
	if stream == null: return
	if _sfx_pool.is_empty(): return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
	p.stream = stream
	p.volume_db = linear_to_db(_sfx_volume) if _sfx_volume > 0 else 0
	p.play()


## 音量控制
func set_bgm_volume(v: float) -> void:
	_bgm_volume = clampf(v, 0.0, 1.0)
	if _current_bgm != null and is_instance_valid(_current_bgm):
		_current_bgm.volume_db = linear_to_db(_bgm_volume) if _bgm_volume > 0 else -40

func set_sfx_volume(v: float) -> void:
	_sfx_volume = clampf(v, 0.0, 1.0)

func set_ambient_volume(v: float) -> void:
	_ambient_volume = clampf(v, 0.0, 1.0)
