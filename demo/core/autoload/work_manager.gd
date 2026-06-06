## work_manager.gd
## 工作管理 — 接受工作 / 执行 / 结算 / 失业
##
## 流程：
##   start_job(job_id) → 等待到 start_hour → 工作中（玩家可继续探索但 job_in_progress=true）→ 结算
##   工作在 day_started 触发：如果今天已分配工作 → 推进到 start_hour
extends Node

const _SELF := preload("res://core/autoload/work_manager.gd")

## 当前进行中的工作
var current_job: JobData = null
var is_working_today: bool = false  # 今天是否还有工作要做
var consecutive_work_days: int = 0  # 连续工作天数
## 累计收入（按 source 记录）
var total_earned: int = 0
var total_jobs_done: int = 0
## 工作历史
var job_history: Array[Dictionary] = []  # [{job_id, day, pay}]

## 职业索引
var job_index: Dictionary = {}


func _ready() -> void:
	EventBus.hour_tick.connect(_on_hour_tick)
	EventBus.day_started.connect(_on_day_started)
	_build_index()


func _build_index() -> void:
	if not job_index.is_empty(): return
	for j in JobFactory.create_all():
		job_index[String(j.job_id)] = j


func get_job(job_id: String) -> JobData:
	if job_index.is_empty(): _build_index()
	return job_index.get(job_id)


# === 接受工作 ===
## 玩家接受一份工作（今天分配到 start_hour 自动执行）
func accept_job(job_id: String) -> bool:
	var job: JobData = get_job(job_id)
	if job == null: return false
	if not job.is_available(): return false
	if is_working_today: return false
	current_job = job
	is_working_today = true
	Player.current_job = String(job_id)
	EventBus.job_started.emit(job_id)
	EventBus.notification_requested.emit(2, "已接工作：%s" % job.job_name)
	return true


## 拒绝/辞职
func quit_job() -> void:
	if current_job == null: return
	current_job = null
	Player.current_job = ""
	is_working_today = false
	consecutive_work_days = 0
	EventBus.job_finished.emit(Player.current_job, 0, false)


# === 时间驱动 ===
func _on_hour_tick(_h: int) -> void:
	if current_job == null or not is_working_today:
		return
	if TimeMgr.hour == current_job.start_hour:
		_execute_work()


func _execute_work() -> void:
	var job: JobData = current_job
	# 1) 扣消耗
	for stat in job.stat_costs:
		var delta: int = int(job.stat_costs[stat])
		match stat:
			"stamina": Player.stamina = max(0, Player.stamina + delta)
			"hunger": Player.hunger = max(0, Player.hunger + delta)
			"mood": Player.mood = max(0, Player.mood + delta)
			"health": Player.health = max(0, Player.health + delta)
			"hygiene": Player.hygiene = max(0, Player.hygiene + delta)
	# 2) 加能力
	for stat in job.stat_gains:
		var delta2: int = int(job.stat_gains[stat])
		match stat:
			"strength": Player.strength = clampi(Player.strength + delta2, 0, 100)
			"intelligence": Player.intelligence = clampi(Player.intelligence + delta2, 0, 100)
			"eloquence": Player.eloquence = clampi(Player.eloquence + delta2, 0, 100)
			"craft": Player.craft = clampi(Player.craft + delta2, 0, 100)
			"charm": Player.charm = clampi(Player.charm + delta2, 0, 100)
	# 3) 算工资（含随机浮动 + 连续工作惩罚）
	var pay: int = _calculate_pay(job)
	Player.cash += pay
	total_earned += pay
	# 4) 随机事件（10% 概率）
	_work_random_event(job)
	# 5) 标记完成
	job_history.append({"job_id": String(job.job_id), "day": TimeMgr.day, "pay": pay})
	total_jobs_done += 1
	consecutive_work_days += 1
	is_working_today = false
	current_job = null
	EventBus.job_finished.emit(String(job.job_id), pay, true)
	EventBus.notification_requested.emit(1, "工作完成，+¥%d" % pay)


func _calculate_pay(job: JobData) -> int:
	var base: int = job.pay_per_day
	if job.job_type == JobData.JobType.FULL_TIME:
		base = int(job.pay_per_month / 30)  # 简化按月分摊
	# ±20% 随机
	var variance: float = 1.0 + randf_range(-0.2, 0.2)
	# 连续工作 ≥ 6 天：-10% 效率
	if consecutive_work_days >= 6:
		variance *= 0.9
	# 口才影响
	if Player.eloquence >= 50:
		variance += 0.05
	return int(base * variance)


func _work_random_event(job: JobData) -> void:
	var r: float = randf()
	if r < 0.05:
		# 被表扬
		Player.mood = min(100, Player.mood + 10)
		EventBus.notification_requested.emit(1, "老板今天表扬了你！心情 +10")
	elif r < 0.10:
		# 被扣钱
		var fine: int = int(job.pay_per_day * 0.2)
		Player.cash = max(0, Player.cash - fine)
		EventBus.notification_requested.emit(3, "工作失误被扣 ¥%d" % fine)
	elif r < 0.13:
		# 遇到贵人
		Player.cash += 50
		EventBus.notification_requested.emit(1, "同事请你吃了一顿，还借了你 50 块")
	elif r < 0.16:
		# 受伤
		Player.health = max(0, Player.health - 10)
		EventBus.notification_requested.emit(3, "工作中小意外，健康 -10")


func _on_day_started(_day: int) -> void:
	# 检查是否连续工作 6+ 天
	if is_working_today:
		consecutive_work_days += 1
	else:
		consecutive_work_days = 0


# === 序列化 ===
func to_dict() -> Dictionary:
	return {
		"current_job": Player.current_job,
		"consecutive_work_days": consecutive_work_days,
		"total_earned": total_earned,
		"total_jobs_done": total_jobs_done,
		"job_history": job_history.duplicate(true),
	}

func from_dict(d: Dictionary) -> void:
	Player.current_job = d.get("current_job", "")
	consecutive_work_days = d.get("consecutive_work_days", 0)
	total_earned = d.get("total_earned", 0)
	total_jobs_done = d.get("total_jobs_done", 0)
	job_history = d.get("job_history", [])
	if not Player.current_job.is_empty():
		current_job = get_job(Player.current_job)
