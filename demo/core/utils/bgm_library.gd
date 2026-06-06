## bgm_library.gd
## BGM 资源库 — 优先用真实文件，缺失时回退到程序化
##
## 把 BGM 文件放到 demo/assets/audio/bgm/ 下，命名对应 kind：
##   - jincheng.ogg
##   - indoor.ogg
##   - work.ogg
##
## 自动检测：有文件就 load，没文件就用 ProceduralAudio
class_name BGMLibrary
extends RefCounted

const _Self := preload("res://core/utils/bgm_library.gd")
const BGM_DIR: String = "res://assets/audio/bgm/"

## 缓存加载结果
static var _cache: Dictionary = {}


## 加载 BGM（如果有真实文件就 load，否则用程序化）
static func get_stream(kind: String) -> AudioStream:
	if _cache.has(kind):
		return _cache[kind]
	var path: String = "%s%s.ogg" % [BGM_DIR, kind]
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		_cache[kind] = stream
		return stream
	# Fallback
	var procedural: AudioStream = null
	match kind:
		"jincheng": procedural = ProceduralAudio.make_stream(ProceduralAudio.bgm_jincheng())
		"indoor": procedural = ProceduralAudio.make_stream(ProceduralAudio.bgm_indoor())
		"work": procedural = ProceduralAudio.make_stream(ProceduralAudio.bgm_work())
		_:
			procedural = ProceduralAudio.make_stream(ProceduralAudio.bgm_jincheng())
	_cache[kind] = procedural
	return procedural


## 列出所有可用的 BGM（含 fallback 状态）
static func list_available() -> Dictionary:
	var result: Dictionary = {}
	for kind in ["jincheng", "indoor", "work"]:
		var path: String = "%s%s.ogg" % [BGM_DIR, kind]
		result[kind] = {
			"file_exists": ResourceLoader.exists(path),
			"source": "file" if ResourceLoader.exists(path) else "procedural",
		}
	return result


## 同理 SFX
const SFX_DIR: String = "res://assets/audio/sfx/"
static var _sfx_cache: Dictionary = {}

static func get_sfx(name: String) -> AudioStream:
	if _sfx_cache.has(name):
		return _sfx_cache[name]
	var path: String = "%s%s.ogg" % [SFX_DIR, name]
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		_sfx_cache[name] = stream
		return stream
	# Fallback
	var proc: AudioStream = null
	match name:
		"click": proc = ProceduralAudio.make_stream(ProceduralAudio.click_sfx())
		"footstep": proc = ProceduralAudio.make_stream(ProceduralAudio.footstep_sfx())
		"coin": proc = ProceduralAudio.make_stream(ProceduralAudio.coin_sfx())
		"notify": proc = ProceduralAudio.make_stream(ProceduralAudio.notify_sfx())
		"error": proc = ProceduralAudio.make_stream(ProceduralAudio.error_sfx())
		_:
			proc = ProceduralAudio.make_stream(ProceduralAudio.click_sfx())
	_sfx_cache[name] = proc
	return proc
