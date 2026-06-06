## TimeManager.gd
## 游戏内时间流逝 + 时段/季节/天气
## 1 个游戏日 = 现实 5 分钟（默认 time_scale=288.0 即每秒推进 288 秒）
## 倍速切换不影响存档里的"总游戏内时间"
extends Node

enum Period {
	DAWN,        ## 5-8 点
	MORNING,     ## 8-12 点
	AFTERNOON,   ## 12-18 点
	EVENING,     ## 18-22 点
	NIGHT,       ## 22-2 点
	LATE_NIGHT,  ## 2-5 点
}

enum Season {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER,
}

const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const DAYS_PER_SEASON: int = 30
const DAYS_PER_WEEK: int = 7
const MONTHS_PER_YEAR: int = 12

# 当前时间（用总分钟数 + 起算日期，避免浮点漂移）
var _total_minutes: int = 0
# 倍速：1=正常，0=暂停，>1=快进
var time_scale: float = 288.0  # 现实 1 秒 = 游戏 288 秒 = 4.8 分钟
var _paused: bool = false
var _accumulator: float = 0.0

# 缓存时段（避免每帧查表）
var _last_period: Period = Period.MORNING
var _last_day: int = 1
var _last_week: int = 1
var _last_month: int = 1
var _last_year: int = 2025
var _last_season: Season = Season.SPRING
var _last_hour: int = 8

# === 公共只读 API ===
var year: int:
	get: return _last_year
var month: int:
	get: return _last_month
var day: int:  # 当月日
	get: return ((_total_minutes / MINUTES_PER_HOUR) % DAYS_PER_SEASON) + 1
var hour: int:
	get: return (_total_minutes / MINUTES_PER_HOUR) % HOURS_PER_DAY
var minute: int:
	get: return _total_minutes % MINUTES_PER_HOUR
var total_days: int:  # 自游戏开始经过的总日数
	get: return _total_minutes / (MINUTES_PER_HOUR * HOURS_PER_DAY)
var week: int:
	get: return (total_days / DAYS_PER_WEEK) + 1
var season: Season:
	get: return _last_season
var period: Period:
	get: return _last_period
var is_weekend: bool:
	get:
		var dow: int = total_days % 7
		return dow == 5 or dow == 6  # 周五周六（游戏内一周 = 现实 35 分钟，按需调）


func _ready() -> void:
	# 默认 2025 年春季，3 月 1 日 08:00
	_total_minutes = (_calc_days_to(2025, 3, 1) * HOURS_PER_DAY + 8) * MINUTES_PER_HOUR
	_recompute_cached()
	# 1 秒驱动一次 tick
	set_process(true)


func _process(delta: float) -> void:
	if _paused or time_scale <= 0.0:
		return
	_accumulator += delta * time_scale
	var to_advance: int = int(_accumulator)
	if to_advance > 0:
		_accumulator -= float(to_advance)
		_advance_minutes(to_advance)


func _advance_minutes(minutes: int) -> void:
	var old_total: int = _total_minutes
	_total_minutes += minutes
	_recompute_cached()
	# 通知所有订阅者
	EventBus.minute_tick.emit(_total_minutes)
	# 每小时发一次
	if _last_hour != _old_hour(old_total):
		EventBus.hour_tick.emit(_last_hour)
	# 每天开始（00:00 跨越）
	var old_day_total: int = old_total / (MINUTES_PER_HOUR * HOURS_PER_DAY)
	var new_day_total: int = _total_minutes / (MINUTES_PER_HOUR * HOURS_PER_DAY)
	if new_day_total > old_day_total:
		# 跨越了若干天，逐天发
		for d in range(new_day_total - old_day_total):
			var passing_day: int = old_day_total + d
			EventBus.day_ended.emit(passing_day + 1)
		EventBus.day_started.emit(new_day_total + 1)
	# 周结束
	if _last_week != _old_week(old_total):
		EventBus.week_ended.emit(_last_week)
	# 月结束
	if _last_month != _old_month(old_total):
		EventBus.month_ended.emit(_last_month)
	# 季节
	if _last_season != _old_season(old_total):
		EventBus.season_changed.emit(_last_season)
	# 年
	if _last_year != _old_year(old_total):
		EventBus.year_changed.emit(_last_year)
	# 时段
	if _last_period != _old_period(old_total):
		EventBus.time_period_changed.emit(_last_period)


func _recompute_cached() -> void:
	_last_hour = hour
	_last_period = _period_of(_last_hour)
	_last_day = day
	_last_week = week
	_last_month = month
	_last_year = year
	_last_season = _season_of_month(_last_month)


# === 旧值查询（用于检测跨越） ===
func _old_hour(old_total: int) -> int:
	return (old_total / MINUTES_PER_HOUR) % HOURS_PER_DAY
func _old_period(old_total: int) -> Period:
	return _period_of(_old_hour(old_total))
func _old_week(old_total: int) -> int:
	return (old_total / (MINUTES_PER_HOUR * HOURS_PER_DAY * DAYS_PER_WEEK)) + 1
func _old_month(old_total: int) -> int:
	return _calc_month(old_total)
func _old_season(old_total: int) -> Season:
	return _season_of_month(_old_month(old_total))
func _old_year(old_total: int) -> int:
	return _calc_year(old_total)


# === 静态工具 ===
static func _period_of(h: int) -> Period:
	if h >= 5 and h < 8: return Period.DAWN
	if h >= 8 and h < 12: return Period.MORNING
	if h >= 12 and h < 18: return Period.AFTERNOON
	if h >= 18 and h < 22: return Period.EVENING
	if h >= 22 or h < 2: return Period.NIGHT
	return Period.LATE_NIGHT  # 2-5

static func _season_of_month(m: int) -> Season:
	# 12 月一轮：3-5 春，6-8 夏，9-11 秋，12-2 冬
	if m >= 3 and m <= 5: return Season.SPRING
	if m >= 6 and m <= 8: return Season.SUMMER
	if m >= 9 and m <= 11: return Season.AUTUMN
	return Season.WINTER

static func _calc_month(total_minutes: int) -> int:
	var d: int = total_minutes / (MINUTES_PER_HOUR * HOURS_PER_DAY)
	return (d / DAYS_PER_SEASON) % MONTHS_PER_YEAR + 1

static func _calc_year(total_minutes: int) -> int:
	var d: int = total_minutes / (MINUTES_PER_HOUR * HOURS_PER_DAY)
	return 2025 + d / (DAYS_PER_SEASON * MONTHS_PER_YEAR)

static func _calc_days_to(y: int, m: int, d: int) -> int:
	return (y - 2025) * (DAYS_PER_SEASON * MONTHS_PER_YEAR) + (m - 1) * DAYS_PER_SEASON + (d - 1)


# === 控制 API ===
func pause_time() -> void:
	_paused = true

func resume_time() -> void:
	_paused = false

func set_time_scale(scale: float) -> void:
	time_scale = max(0.0, scale)

func skip_minutes(minutes: int) -> void:
	_advance_minutes(minutes)

func skip_hours(hours: int) -> void:
	_advance_minutes(hours * MINUTES_PER_HOUR)

func skip_to_next_period() -> void:
	# 跳到下一个时段开始
	var h: int = hour
	var next_h: int = [8, 12, 18, 22, 2, 5][_last_period]
	if next_h <= h:
		next_h += HOURS_PER_DAY
	skip_minutes((next_h - h) * MINUTES_PER_HOUR - minute)


# === 序列化 ===
func to_dict() -> Dictionary:
	return {
		"total_minutes": _total_minutes,
		"time_scale": time_scale,
	}

func from_dict(d: Dictionary) -> void:
	_total_minutes = d.get("total_minutes", 0)
	time_scale = d.get("time_scale", 288.0)
	_recompute_cached()
