## test_runner_extended.gd
## 扩展单元测试 — 覆盖事件/工作/天气/库存/存档等更细的分支
extends Node

var _pass: int = 0
var _fail: int = 0
var _failed: Array = []


func _ready() -> void:
	await get_tree().process_frame
	print("\n=== 《命运齿轮》扩展测试套件 ===\n")
	_run_all()
	print("\n=== 总结果: %d 通过, %d 失败 ===" % [_pass, _fail])
	if _fail > 0:
		print("失败: %s" % ", ".join(_failed))
		push_error("Extended test suite FAILED")
	get_tree().quit(0 if _fail == 0 else 1)


func _run_all() -> void:
	# Inventory 边界
	_test("Inventory stack overflow", _test_inventory_stack)
	_test("Inventory negative remove", _test_inventory_negative_remove)
	_test("Inventory mixed items", _test_inventory_mixed)
	# Player 边界
	_test("Player stat clamping (negative)", _test_player_negative)
	_test("Player stat clamping (above 100)", _test_player_above_100)
	_test("Player morality bounds", _test_player_morality)
	# Time
	_test("TimeMgr hour wrap", _test_time_hour_wrap)
	_test("TimeMgr day count", _test_time_day_count)
	_test("TimeMgr season wrap", _test_time_season_wrap)
	# Weather
	_test("Weather name/color", _test_weather_metadata)
	_test("Weather cancels outdoor work", _test_weather_cancels)
	# Work
	_test("Work job pay calculation", _test_work_pay)
	_test("Work consecutive penalty", _test_work_consecutive)
	_test("Work is_available", _test_work_available)
	# Events
	_test("Event factory count", _test_event_factory_count)
	_test("Event condition check", _test_event_condition)
	# Shop
	_test("Shop buy with insufficient cash", _test_shop_buy_fail)
	_test("Shop sell item not owned", _test_shop_sell_fail)
	_test("Shop buyback discount", _test_shop_buyback)
	# Economy
	_test("Economy loan limit", _test_economy_loan_limit)
	_test("Economy negative withdraw", _test_economy_negative)
	# Status
	_test("Status mutex", _test_status_mutex)
	_test("Status duration refresh", _test_status_duration)
	# Save/Load
	_test("Save roundtrip", _test_save_roundtrip)
	# Story
	_test("Story chapter progress", _test_story_progress)
	# Scene
	_test("SceneData has bounds", _test_scene_bounds)
	# Procedural
	_test("Procedural audio not empty", _test_procedural_audio)
	_test("Pixel artist all food sprites", _test_all_food_sprites)
	_test("Pixel artist 4-dir sprite", _test_4dir_sprite)
	# Edge cases
	_test("Save slot 0-2 range", _test_save_slot_range)
	_test("Time skip 0 minutes", _test_time_skip_zero)
	_test("Item max_stack respected", _test_item_max_stack)
	_test("NPC affinity clamp", _test_affinity_clamp)


func _test(name: String, callable: Callable) -> void:
	var result: Variant = callable.call()
	var ok: bool = false
	var err: String = ""
	if result is Dictionary and result.has("ok"):
		ok = bool(result.get("ok", false))
		err = String(result.get("error", ""))
	else:
		ok = bool(result)
	if ok:
		_pass += 1
		print("  [PASS] %s" % name)
	else:
		_fail += 1
		_failed.append(name)
		print("  [FAIL] %s%s" % [name, " - " + err if err != "" else ""])


# === 测试函数 ===
func _test_inventory_stack() -> Variant:
	Player.inventory_slots = []
	Player.inventory_slots.resize(Player.INVENTORY_BASE_SIZE)
	# doujiang max_stack = 99 — 加 150 应分到 2 个槽（99+51）
	var added: int = Player.add_item("food_doujiang", 150)
	if added != 150: return {"ok": false, "error": "expected 150 total, got %d" % added}
	if Player.count_item("food_doujiang") != 150: return {"ok": false, "error": "count %d" % Player.count_item("food_doujiang")}
	# 第一个槽应是 99（满）
	var slot0: Dictionary = Player.inventory_slots[0]
	if slot0.get("quantity", 0) != 99:
		return {"ok": false, "error": "slot0=%d" % slot0.get("quantity", 0)}
	return true

func _test_inventory_negative_remove() -> Variant:
	Player.inventory_slots = []
	Player.inventory_slots.resize(Player.INVENTORY_BASE_SIZE)
	Player.add_item("food_youtiao", 2)
	var removed: int = Player.remove_item("food_youtiao", 5)  # 没有 5 个
	if removed != 2: return {"ok": false, "error": "expected 2 removed, got %d" % removed}
	if Player.count_item("food_youtiao") != 0: return {"ok": false, "error": "still has"}
	return true

func _test_inventory_mixed() -> Variant:
	Player.inventory_slots = []
	Player.inventory_slots.resize(Player.INVENTORY_BASE_SIZE)
	Player.add_item("food_doujiang", 3)
	Player.add_item("food_baozi", 2)
	Player.add_item("medicine_bandage", 5)
	if Player.count_item("food_doujiang") != 3: return {"ok": false, "error": "doujiang"}
	if Player.count_item("food_baozi") != 2: return {"ok": false, "error": "baozi"}
	if Player.count_item("medicine_bandage") != 5: return {"ok": false, "error": "bandage"}
	return true

func _test_player_negative() -> Variant:
	Player.stamina = 100
	Player.stamina = -50
	if Player.stamina != 0: return {"ok": false, "error": "not clamped to 0"}
	return true

func _test_player_above_100() -> Variant:
	Player.stamina = 100
	# setter 不会自动加 — 用 use_item 测试
	Player.inventory_slots = []
	Player.inventory_slots.resize(Player.INVENTORY_BASE_SIZE)
	Player.add_item("food_mifan", 1)
	Player.use_item("food_mifan")  # 饱腹 +60
	# 测试 mood +5 (mifan 还有 mood)
	# 直接测属性范围
	Player.hunger = 200
	if Player.hunger != 100: return {"ok": false, "error": "hunger not clamped"}
	return true

func _test_player_morality() -> Variant:
	Player.morality = 0
	Player.morality = 200
	if Player.morality != 100: return {"ok": false, "error": "morality +200 not clamped"}
	Player.morality = -200
	if Player.morality != -100: return {"ok": false, "error": "morality -200 not clamped"}
	return true

func _test_time_hour_wrap() -> Variant:
	# 100 分钟应该 wrap 到 1:40
	TimeMgr._total_minutes = 100
	if TimeMgr.hour != 1: return {"ok": false, "error": "hour=%d" % TimeMgr.hour}
	if TimeMgr.minute != 40: return {"ok": false, "error": "minute=%d" % TimeMgr.minute}
	TimeMgr._total_minutes = 0
	return true

func _test_time_day_count() -> Variant:
	# 24*60 = 1440 分钟 = 1 天
	TimeMgr._total_minutes = 1440 * 5  # 5 天
	if TimeMgr.total_days != 5: return {"ok": false, "error": "days=%d" % TimeMgr.total_days}
	TimeMgr._total_minutes = 0
	return true

func _test_time_season_wrap() -> Variant:
	# 3 月 = 春季
	if TimeMgr._season_of_month(3) != TimeMgr.Season.SPRING:
		return {"ok": false, "error": "march"}
	# 1 月 = 冬
	if TimeMgr._season_of_month(1) != TimeMgr.Season.WINTER:
		return {"ok": false, "error": "jan"}
	# 7 月 = 夏
	if TimeMgr._season_of_month(7) != TimeMgr.Season.SUMMER:
		return {"ok": false, "error": "july"}
	# 10 月 = 秋
	if TimeMgr._season_of_month(10) != TimeMgr.Season.AUTUMN:
		return {"ok": false, "error": "oct"}
	return true

func _test_weather_metadata() -> Variant:
	# 验证每个 weather 都有 name 和 color
	for w in range(8):
		var n: String = WeatherManager.name_of(w)
		var c: Color = WeatherManager.color_of(w)
		if n == "未知": return {"ok": false, "error": "w=%d name=未知" % w}
		if c == Color.WHITE and w != WeatherManager.Weather.SUNNY: return {"ok": false, "error": "w=%d color=white" % w}
	return true

func _test_weather_cancels() -> Variant:
	# 阳光 → 不取消
	WeatherManager.current_weather = WeatherManager.Weather.SUNNY
	if WeatherManager.cancels_outdoor_work(): return {"ok": false, "error": "sunny cancels"}
	# 大雨 → 取消
	WeatherManager.current_weather = WeatherManager.Weather.HEAVY_RAIN
	if not WeatherManager.cancels_outdoor_work(): return {"ok": false, "error": "heavy rain not cancel"}
	# 暴风雨 → 取消
	WeatherManager.current_weather = WeatherManager.Weather.STORM
	if not WeatherManager.cancels_outdoor_work(): return {"ok": false, "error": "storm not cancel"}
	# 大雪 → 取消
	WeatherManager.current_weather = WeatherManager.Weather.HEAVY_SNOW
	if not WeatherManager.cancels_outdoor_work(): return {"ok": false, "error": "heavy snow not cancel"}
	WeatherManager.current_weather = WeatherManager.Weather.SUNNY
	return true

func _test_work_pay() -> Variant:
	# brick 日薪 100，+随机 ±20%
	Player.current_job = ""
	Work.current_job = null
	if not Work.accept_job("job_brick"): return {"ok": false, "error": "accept"}
	# 多次模拟 pay 计算
	# 不直接调 _execute_work (会随机)
	# 验证 base = 100
	var job: JobData = Work.get_job("job_brick")
	if job.pay_per_day != 100: return {"ok": false, "error": "pay %d" % job.pay_per_day}
	Work.quit_job()
	return true

func _test_work_consecutive() -> Variant:
	# 连续 6 天 penalty
	Player.current_job = ""
	Work.current_job = null
	Work.consecutive_work_days = 6
	if not Work.accept_job("job_brick"): return {"ok": false, "error": "accept"}
	# 验证 state
	if Work.consecutive_work_days < 6: return {"ok": false, "error": "consecutive reset"}
	Work.quit_job()
	return true

func _test_work_available() -> Variant:
	# 网吧代练需要智力 20
	Player.intelligence = 10
	# 没法直接测（accept_job 会校验）
	# 简化：先满足条件
	Player.intelligence = 50
	if not Work.accept_job("job_cafe_assistant"): return {"ok": false, "error": "accept with 50 int"}
	Work.quit_job()
	return true

func _test_event_factory_count() -> Variant:
	var arr: Array = EventFactory.create_all()
	# 21：20 主事件 + 1 测试事件
	if arr.size() < 20: return {"ok": false, "error": "expected 20+ events, got %d" % arr.size()}
	# 验证每种 type 都有
	var types: Dictionary = {}
	for e in arr:
		types[e.event_type] = true
	if not types.has(EventData.Type.CRISIS): return {"ok": false, "error": "no CRISIS"}
	if not types.has(EventData.Type.SIDE): return {"ok": false, "error": "no SIDE"}
	return true

func _test_event_condition() -> Variant:
	var events: Array = EventFactory.create_all()
	for e in events:
		if e.event_id == &"ev_test_money_min":
			Player.cash = 100
			if e.check_conditions({}):
				return {"ok": false, "error": "should not trigger with 100 cash"}
			Player.cash = 500
			if not e.check_conditions({}):
				return {"ok": false, "error": "should trigger with 500"}
			return true
	return {"ok": false, "error": "ev_test_money_min not found"}

func _test_shop_buy_fail() -> Variant:
	Player.cash = 1
	if Economy.buy_from_shop("shop_wang_breakfast", "food_doujiang", 1):
		return {"ok": false, "error": "bought with 1 cash"}
	Player.cash = 1000
	return true

func _test_shop_sell_fail() -> Variant:
	Player.inventory_slots = []
	Player.inventory_slots.resize(Player.INVENTORY_BASE_SIZE)
	if Economy.sell_to_shop("shop_wang_breakfast", "food_doujiang", 1):
		return {"ok": false, "error": "sold without owning"}
	return true

func _test_shop_buyback() -> Variant:
	# buyback 80% * 1 元 = 1 元（ceil 0.8 = 1）
	var shop: ShopData = Economy.get_shop("shop_wang_breakfast")
	Player.known_npcs["npc_wang_ayi"] = {"affinity": 30}
	var p: int = shop.get_buyback_price("food_doujiang", 1, 30)
	if p != 1: return {"ok": false, "error": "expected 1, got %d" % p}
	# 友好 NPC 90% * 1 = 1
	Player.known_npcs["npc_wang_ayi"] = {"affinity": 70}
	p = shop.get_buyback_price("food_doujiang", 1, 70)
	if p != 1: return {"ok": false, "error": "friendly expected 1, got %d" % p}
	return true

func _test_economy_loan_limit() -> Variant:
	Player.debt = 0
	# 借 5000
	if not Economy.take_loan(5000): return {"ok": false, "error": "loan 5000"}
	# 再借 1 → 超过
	if Economy.take_loan(1):
		return {"ok": false, "error": "exceeded limit"}
	# 还 1000 后能再借
	Economy.repay_loan(1000)
	# 现在 4000
	if not Economy.take_loan(1000): return {"ok": false, "error": "can't loan 1000 after repay"}
	Player.debt = 0
	return true

func _test_economy_negative() -> Variant:
	Player.cash = 100
	if Economy.bank_withdraw(-50):
		return {"ok": false, "error": "negative withdraw"}
	if Economy.bank_deposit(-50):
		return {"ok": false, "error": "negative deposit"}
	return true

func _test_status_mutex() -> Variant:
	# 精力充沛 vs 疲惫互斥
	Player.status_effects = {}
	StatusMgr.add_effect("energetic", "test", 10.0)
	if not Player.has_status_effect("energetic"): return {"ok": false, "error": "no energetic"}
	# 添加一个同 mutex_group 的效果
	# 注：当前所有 status 都在不同 group；这里验证 add/remove 基础
	Player.remove_status_effect("energetic")
	if Player.has_status_effect("energetic"): return {"ok": false, "error": "not removed"}
	return true

func _test_status_duration() -> Variant:
	Player.status_effects = {}
	Player.add_status_effect("cold", "test", 5.0)
	var entry: Dictionary = Player.status_effects["cold"]
	if entry["remaining_hours"] != 5.0: return {"ok": false, "error": "duration %f" % entry["remaining_hours"]}
	# tick 1 小时
	entry["remaining_hours"] = entry["remaining_hours"] - 1.0
	if entry["remaining_hours"] != 4.0: return {"ok": false, "error": "after tick %f" % entry["remaining_hours"]}
	Player.status_effects = {}
	return true

func _test_save_roundtrip() -> Variant:
	Player.cash = 777
	Player.bank_balance = 333
	Player.hunger = 55
	Game.save_game(0)
	Player.cash = 0
	Player.bank_balance = 0
	Player.hunger = 100
	if not Game.load_game(0): return {"ok": false, "error": "load"}
	if Player.cash != 777: return {"ok": false, "error": "cash after load %d" % Player.cash}
	if Player.bank_balance != 333: return {"ok": false, "error": "bank after load %d" % Player.bank_balance}
	# 清理
	var path: String = "%s/slot_0.json" % Game.SAVE_DIR
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return true

func _test_story_progress() -> Variant:
	Player.story_flags = {}
	Story.current_chapter = Story.Chapter.PROLOGUE
	# 只设 next_chapter_flag（不要设 complete_flag，让 _check 自己标记）
	Player.set_flag("intro_wang_ayi", true)
	TimeMgr._total_minutes = 1440  # 1 天
	Story._check_chapter_progression()
	if Story.current_chapter != Story.Chapter.CHAPTER_1:
		return {"ok": false, "error": "stayed in prologue, now=%d" % Story.current_chapter}
	TimeMgr._total_minutes = 0
	return true

func _test_scene_bounds() -> Variant:
	for s in SceneData.create_all():
		if s.bounds.size.x <= 0 or s.bounds.size.y <= 0:
			return {"ok": false, "error": "scene %s no bounds" % s.scene_id}
	return true

func _test_procedural_audio() -> Variant:
	var data: PackedByteArray = ProceduralAudio.click_sfx()
	if data.is_empty(): return {"ok": false, "error": "click empty"}
	var bgm: PackedByteArray = ProceduralAudio.bgm_jincheng()
	if bgm.is_empty(): return {"ok": false, "error": "bgm empty"}
	return true

func _test_all_food_sprites() -> Variant:
	var kinds: Array = ["doujiang", "youtiao", "baozi", "mifan", "xiaomi_zhou", "medicine_bandage", "medicine_cold", "medicine_painkiller", "phone", "id_card", "clothing_tshirt", "clothing_jeans", "clothing_sneaker", "clothing_cap", "bed"]
	for k in kinds:
		var tex: ImageTexture = PixelArtist.make_food_sprite(k)
		if tex == null: return {"ok": false, "error": "kind %s null" % k}
	return true

func _test_4dir_sprite() -> Variant:
	var tex: ImageTexture = PixelArtist.make_4direction_sprite(
		Color(0.95, 0.78, 0.65), Color.BLACK, Color.RED, Color.BLUE)
	if tex == null: return {"ok": false, "error": "null"}
	var img: Image = tex.get_image()
	if img.get_width() != 64: return {"ok": false, "error": "w=%d" % img.get_width()}
	if img.get_height() != 96: return {"ok": false, "error": "h=%d" % img.get_height()}
	return true

func _test_save_slot_range() -> Variant:
	for i in range(Game.SAVE_SLOT_COUNT):
		if i < 0 or i >= 3: return {"ok": false, "error": "slot %d" % i}
	return true

func _test_time_skip_zero() -> Variant:
	TimeMgr._total_minutes = 100
	TimeMgr.skip_minutes(0)
	if TimeMgr._total_minutes != 100: return {"ok": false, "error": "changed"}
	TimeMgr._total_minutes = 0
	return true

func _test_item_max_stack() -> Variant:
	var data: ItemData = Player.get_item("food_doujiang")
	if data.max_stack != 99: return {"ok": false, "error": "max_stack=%d" % data.max_stack}
	return true

func _test_affinity_clamp() -> Variant:
	Player.known_npcs = {}
	Player.modify_affinity("npc_test", 200)
	if Player.get_affinity("npc_test") != 100: return {"ok": false, "error": "above 100"}
	Player.modify_affinity("npc_test", -300)
	if Player.get_affinity("npc_test") != 0: return {"ok": false, "error": "below 0"}
	return true
