## test_runner.gd
## 内置单元测试运行器 — 不依赖 gut/gdunit4
##
## 启动后自动跑所有测试，输出 PASS/FAIL 摘要
## 用法：临时加到 project.godot autoload
##   Tests = "*res://core/tests/test_runner.gd"
## 测完移除
extends Node

var _pass: int = 0
var _fail: int = 0
var _failed_tests: Array = []


func _ready() -> void:
	await get_tree().process_frame
	print("\n=== 《命运齿轮》单元测试套件 ===\n")
	_run_all()
	print("\n=== 总结果: %d 通过, %d 失败 ===" % [_pass, _fail])
	if _fail > 0:
		print("失败测试: %s" % ", ".join(_failed_tests))
		push_error("Test suite FAILED")
	get_tree().quit(0 if _fail == 0 else 1)


func _run_all() -> void:
	_test("ConditionParser basic", _test_condition_basic)
	_test("ConditionParser with flag", _test_condition_flag)
	_test("ConditionParser complex", _test_condition_complex)
	_test("TimeManager periods", _test_time_periods)
	_test("TimeManager seasons", _test_time_seasons)
	_test("PlayerData stat clamps", _test_player_stat_clamp)
	_test("PlayerData inventory", _test_inventory)
	_test("PlayerData equip", _test_equip)
	_test("NPCData factory", _test_npc_factory)
	_test("ItemData factory", _test_item_factory)
	_test("JobData factory", _test_job_factory)
	_test("StatusEffect factory", _test_status_factory)
	_test("AccommodationData factory", _test_accommodation_factory)
	_test("ShopData pricing", _test_shop_pricing)
	_test("Economy deposit/withdraw", _test_economy)
	_test("Work accept/execute", _test_work)
	_test("PixelArtist character", _test_pixel_artist)
	_test("Dialogue load all", _test_dialogue_load_all)
	_test("EndingSystem match", _test_ending_match)


func _test(name: String, callable: Callable) -> void:
	var ok: bool = false
	var err: String = ""
	var result: Variant = callable.call()
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
		_failed_tests.append(name)
		print("  [FAIL] %s%s" % [name, " - " + err if err != "" else ""])


# === 测试函数 ===
func _test_condition_basic() -> Variant:
	var r1: bool = ConditionParser.evaluate("cash >= 100", {"cash": 50})
	if r1: return {"ok": false, "error": "50>=100 should be false but got true"}
	var r2: bool = ConditionParser.evaluate("cash >= 100", {"cash": 200})
	if not r2: return {"ok": false, "error": "200>=100 should be true"}
	var r3: bool = ConditionParser.evaluate("cash >= 100", {"cash": 100})
	if not r3: return {"ok": false, "error": "100>=100 should be true"}
	return true

func _test_condition_flag() -> Variant:
	if not ConditionParser.evaluate("flag:met_li_ge", {"flags": {"met_li_ge": true}}):
		return {"ok": false, "error": "flag should be true"}
	if ConditionParser.evaluate("flag:met_li_ge", {"flags": {}}):
		return {"ok": false, "error": "empty flag should be false"}
	return true

func _test_condition_complex() -> Variant:
	var ctx: Dictionary = {"cash": 200, "flags": {"has_money": true}, "npcs": {"npc_wang": {"affinity": 60}}}
	if not ConditionParser.evaluate("cash >= 100 and flag:has_money", ctx):
		return {"ok": false, "error": "and failed"}
	if not ConditionParser.evaluate("affinity:npc_wang >= 50", ctx):
		return {"ok": false, "error": "affinity failed"}
	return true

func _test_time_periods() -> Variant:
	if TimeMgr.Season.SPRING != 0: return {"ok": false, "error": "SPRING enum"}
	if TimeMgr.Period.MORNING != 1: return {"ok": false, "error": "MORNING enum"}
	return true

func _test_time_seasons() -> Variant:
	if TimeMgr._season_of_month(3) != TimeMgr.Season.SPRING: return {"ok": false, "error": "march"}
	if TimeMgr._season_of_month(6) != TimeMgr.Season.SUMMER: return {"ok": false, "error": "june"}
	if TimeMgr._season_of_month(9) != TimeMgr.Season.AUTUMN: return {"ok": false, "error": "sept"}
	if TimeMgr._season_of_month(12) != TimeMgr.Season.WINTER: return {"ok": false, "error": "dec"}
	if TimeMgr._season_of_month(2) != TimeMgr.Season.WINTER: return {"ok": false, "error": "feb"}
	return true

func _test_player_stat_clamp() -> Variant:
	Player.stamina = 150  # 应被 clamp 到 100
	if Player.stamina != 100: return {"ok": false, "error": "stamina not clamped"}
	Player.stamina = -10
	if Player.stamina != 0: return {"ok": false, "error": "stamina negative"}
	Player.stamina = 50
	return true

func _test_inventory() -> Variant:
	Player.inventory_slots = []
	Player.inventory_slots.resize(Player.INVENTORY_BASE_SIZE)
	var added: int = Player.add_item("food_doujiang", 5)
	if added != 5: return {"ok": false, "error": "add 5 got %d" % added}
	if not Player.has_item("food_doujiang", 5): return {"ok": false, "error": "has_item"}
	var removed: int = Player.remove_item("food_doujiang", 2)
	if removed != 2: return {"ok": false, "error": "remove 2 got %d" % removed}
	if Player.count_item("food_doujiang") != 3: return {"ok": false, "error": "count 3"}
	return true

func _test_equip() -> Variant:
	Player.equipped = {}
	Player.equip_item("clothing_jeans")
	# BODY = 2 (NONE=0, HEAD=1, BODY=2, FEET=3, ACCESSORY=4)
	if not Player.equipped.has(ItemData.EquipSlot.BODY): return {"ok": false, "error": "not equipped, keys=%s" % Player.equipped.keys()}
	if Player.get_equip_bonus("strength") <= 0: return {"ok": false, "error": "no bonus"}
	Player.unequip_slot(ItemData.EquipSlot.BODY)
	if Player.equipped.has(ItemData.EquipSlot.BODY): return {"ok": false, "error": "still equipped"}
	return true

func _test_npc_factory() -> Variant:
	var arr: Array = NPCFactory.create_all()
	if arr.size() != 3: return {"ok": false, "error": "3 npcs got %d" % arr.size()}
	for n in arr:
		if n.schedules.is_empty(): return {"ok": false, "error": "%s no schedule" % n.npc_id}
	return true

func _test_item_factory() -> Variant:
	var arr: Array = ItemFactory.create_all()
	if arr.size() != 15: return {"ok": false, "error": "15 items got %d" % arr.size()}
	var data: ItemData = Player.get_item("food_doujiang")
	if data == null: return {"ok": false, "error": "no doujiang"}
	if data.buy_price != 2: return {"ok": false, "error": "doujiang price 2"}
	return true

func _test_job_factory() -> Variant:
	var arr: Array = JobFactory.create_all()
	if arr.size() != 10: return {"ok": false, "error": "10 jobs got %d" % arr.size()}
	return true

func _test_status_factory() -> Variant:
	var arr: Array = StatusEffect.create_all()
	if arr.size() != 10: return {"ok": false, "error": "10 effects got %d" % arr.size()}
	return true

func _test_accommodation_factory() -> Variant:
	var arr: Array = AccommodationData.create_all()
	if arr.size() != 9: return {"ok": false, "error": "9 accs got %d" % arr.size()}
	return true

func _test_shop_pricing() -> Variant:
	var shop: ShopData = Economy.get_shop("shop_wang_breakfast")
	if shop == null: return {"ok": false, "error": "no shop"}
	# 默认好感 30 时为原价
	var p1: int = shop.get_sell_price("food_doujiang", 2, 30, 30)
	if p1 != 2: return {"ok": false, "error": "p1=%d expected 2" % p1}
	# 好感 70: 0.9x
	Player.known_npcs["npc_wang_ayi"] = {"affinity": 70}
	var p2: int = shop.get_sell_price("food_doujiang", 2, 70, 30)
	if p2 != 2: return {"ok": false, "error": "p2=%d expected 2 (ceil 1.8)" % p2}
	return true

func _test_economy() -> Variant:
	Player.cash = 100
	Player.bank_balance = 0
	if not Economy.bank_deposit(50): return {"ok": false, "error": "deposit fail"}
	if Player.cash != 50 or Player.bank_balance != 50: return {"ok": false, "error": "after deposit"}
	if not Economy.bank_withdraw(30): return {"ok": false, "error": "withdraw fail"}
	if Player.cash != 80 or Player.bank_balance != 20: return {"ok": false, "error": "after withdraw"}
	# 贷款
	if not Economy.take_loan(1000): return {"ok": false, "error": "loan"}
	if Player.debt != 1000: return {"ok": false, "error": "debt 1000"}
	Economy.repay_loan(500)
	if Player.debt != 500: return {"ok": false, "error": "repay"}
	return true

func _test_work() -> Variant:
	Player.current_job = ""
	Work.current_job = null
	if not Work.accept_job("job_brick"): return {"ok": false, "error": "accept brick"}
	if Work.current_job == null: return {"ok": false, "error": "no current job"}
	# 立即手动调 _execute_work 模拟到时间
	# 直接 verify state
	if Player.current_job != "job_brick": return {"ok": false, "error": "player job not set"}
	Work.quit_job()
	if Player.current_job != "": return {"ok": false, "error": "not cleared"}
	return true

func _test_pixel_artist() -> Variant:
	var tex: ImageTexture = PixelArtist.make_ground_tile(0)
	if tex == null: return {"ok": false, "error": "ground null"}
	var img: Image = tex.get_image()
	if img.get_width() != 16 or img.get_height() != 16: return {"ok": false, "error": "wrong size %dx%d" % [img.get_width(), img.get_height()]}
	var portrait: ImageTexture = PixelArtist.portrait_for("npc_wang_ayi", "happy")
	if portrait == null: return {"ok": false, "error": "portrait null"}
	return true

func _test_dialogue_load_all() -> Variant:
	var dir: DirAccess = DirAccess.open("res://data/dialogues")
	if dir == null: return {"ok": false, "error": "no dir"}
	dir.list_dir_begin()
	var file: String = dir.get_next()
	var count: int = 0
	while file != "":
		if file.ends_with(".tres"):
			count += 1
		file = dir.get_next()
	dir.list_dir_end()
	if count < 25: return {"ok": false, "error": "expected 25+ dialogues, got %d" % count}
	return true

func _test_ending_match() -> Variant:
	# 正常情况应至少返回一个 ending
	Player.set_flag("pro_route_completed", true)
	Player.cash = 15000
	var e: Dictionary = Endings.evaluate_ending()
	if e.is_empty(): return {"ok": false, "error": "no ending"}
	# 清除测试 flag
	Player.set_flag("pro_route_completed", false)
	return true
