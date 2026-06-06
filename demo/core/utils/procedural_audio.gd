## procedural_audio.gd
## 程序化音频生成 — 不依赖外部文件
## 用 AudioStreamGenerator + 实时合成 PCM
##
## BGM：简单旋律循环（不同场景不同 key）
## SFX：短促波形（footstep / coin / click / notify）
class_name ProceduralAudio
extends RefCounted

const SAMPLE_RATE: int = 22050


# === 简单波形生成 ===

## 正弦波片段
static func sine_wave(freq: float, duration: float, volume: float = 0.3) -> PackedByteArray:
	return _synth(_SineGen.new(), freq, duration, volume)


## 短促 click（衰减白噪声）
static func click_sfx() -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	var n: int = int(SAMPLE_RATE * 0.05)
	for i in range(n):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = 1.0 - (float(i) / n)
		var v: float = (randf() * 2.0 - 1.0) * env * 0.4
		data.append(_to_u8(v))
	return data


## 脚步（短低频）
static func footstep_sfx() -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	var n: int = int(SAMPLE_RATE * 0.1)
	for i in range(n):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = sin(t / 0.1 * PI) * 0.4  # 半正弦包络
		var v: float = sin(t * 2 * PI * 80) * env  # 80Hz
		data.append(_to_u8(v))
	return data


## 硬币（上扬短促）
static func coin_sfx() -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	var n: int = int(SAMPLE_RATE * 0.15)
	for i in range(n):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = 1.0 - (float(i) / n)
		var freq: float = 800 + t * 2000  # 频率上滑
		var v: float = sin(t * 2 * PI * freq) * env * 0.4
		data.append(_to_u8(v))
	return data


## 通知（双音）
static func notify_sfx() -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	var n: int = int(SAMPLE_RATE * 0.2)
	for i in range(n):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = 1.0 - (float(i) / n)
		var freq: float = 600.0 if t < 0.1 else 900.0
		var v: float = sin(t * 2 * PI * freq) * env * 0.3
		data.append(_to_u8(v))
	return data


## 错误（低频下降）
static func error_sfx() -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	var n: int = int(SAMPLE_RATE * 0.25)
	for i in range(n):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = 1.0 - (float(i) / n)
		var freq: float = 300.0 - t * 500
		var v: float = sin(t * 2 * PI * max(50, freq)) * env * 0.3
		data.append(_to_u8(v))
	return data


## 雨声（持续白噪声）
static func rain_loop(duration: float = 4.0) -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	var n: int = int(SAMPLE_RATE * duration)
	for i in range(n):
		var v: float = (randf() * 2.0 - 1.0) * 0.15
		data.append(_to_u8(v))
	return data


# === BGM：简单旋律 ===

## 8-bit 风格 BGM（小调低沉 — 适合老城/锦城氛围）
## 用 4 个小节循环：每节 4 拍，每拍 1/4 秒
static func bgm_jincheng(duration: float = 16.0) -> PackedByteArray:
	# A minor pentatonic：220, 261, 293, 329, 392
	# 旋律（小节）：
	var melody: Array = [
		# beat 0..3, freq
		[220, 0.5], [0, 0.1], [261, 0.4], [293, 0.4],
		[220, 0.5], [293, 0.3], [329, 0.3], [0, 0.3],
		[261, 0.5], [220, 0.3], [196, 0.3], [0, 0.3],
		[293, 0.5], [261, 0.3], [220, 0.3], [196, 0.4],
	]
	return _melody_to_pcm(melody, 0.25, duration)


## 室内（更柔和）
static func bgm_indoor(duration: float = 16.0) -> PackedByteArray:
	var melody: Array = [
		[196, 0.5], [0, 0.2], [220, 0.4], [261, 0.4],
		[220, 0.4], [196, 0.4], [174, 0.4], [0, 0.3],
		[196, 0.5], [220, 0.3], [261, 0.3], [0, 0.3],
		[293, 0.5], [261, 0.3], [220, 0.3], [196, 0.4],
	]
	return _melody_to_pcm(melody, 0.3, duration)


## 紧张/工作
static func bgm_work(duration: float = 12.0) -> PackedByteArray:
	var melody: Array = [
		[220, 0.25], [261, 0.25], [293, 0.25], [329, 0.25],
		[293, 0.25], [329, 0.25], [392, 0.25], [440, 0.25],
		[392, 0.25], [329, 0.25], [293, 0.25], [261, 0.25],
		[220, 0.5], [0, 0.25], [220, 0.5], [0, 0.25],
	]
	return _melody_to_pcm(melody, 0.2, duration)


# === Helpers ===
class _SineGen:
	extends RefCounted
	func sample(t: float, freq: float) -> float:
		return sin(t * 2 * PI * freq)


static func _synth(gen: RefCounted, freq: float, duration: float, volume: float) -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	var n: int = int(SAMPLE_RATE * duration)
	for i in range(n):
		var t: float = float(i) / SAMPLE_RATE
		# 简单包络
		var env: float = 1.0
		if t < 0.05: env = t / 0.05
		elif t > duration - 0.05: env = max(0.0, (duration - t) / 0.05)
		var v: float = gen.sample(t, freq) * env * volume
		data.append(_to_u8(v))
	return data


static func _melody_to_pcm(melody: Array, beat_sec: float, total_sec: float) -> PackedByteArray:
	var data: PackedByteArray = PackedByteArray()
	var total_samples: int = int(SAMPLE_RATE * total_sec)
	var pos: int = 0
	var idx: int = 0
	while pos < total_samples:
		var beat: Array = melody[idx % melody.size()]
		var freq: float = float(beat[0])
		var dur: float = float(beat[1]) * beat_sec
		var n: int = int(SAMPLE_RATE * dur)
		for i in range(n):
			if pos + i >= total_samples: break
			var t: float = float(i) / SAMPLE_RATE
			var env: float = 1.0
			if t < 0.02: env = t / 0.02
			elif t > dur - 0.02: env = max(0.0, (dur - t) / 0.02)
			var v: float = 0.0
			if freq > 0:
				# 加点方波感
				var sine: float = sin(t * 2 * PI * freq)
				var square: float = 1.0 if sine > 0 else -1.0
				v = (sine * 0.6 + square * 0.2) * env * 0.25
			data.append(_to_u8(v))
		pos += n
		idx += 1
	return data


static func _to_u8(v: float) -> int:
	# float [-1, 1] -> uint8 [0, 255] (中心 128)
	return int(clampf((v + 1.0) * 0.5 * 255.0, 0, 255))


## 包装成 AudioStream
static func make_stream(data: PackedByteArray, mix_rate: int = SAMPLE_RATE) -> AudioStream:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream
