## dialogue_test.gd
## 阶段三端到端自测 — 启动时自动跑，错误通过 push_error 让 stderr 看见
##
## 测什么：
##   1. ConditionParser 单元测试
##   2. 9 个 .tres 全部能 load
##   3. 启动 dlg_wang_first → 选 "要" → 走 buy 节点 → end
##   4. 验证 effect 触发：cash -= 2, hunger += 20
##
## 用法：临时把 [autoload] 加一行
##   DialogueTest = "*res://core/tests/dialogue_test.gd"
## 阶段三验证完后从 project.godot 删掉
extends Node

func _ready() -> void:
	# 延一帧，确保所有 autoload 完成 _ready
	await get_tree().process_frame
	_run_all_tests()


func _run_all_tests() -> void:
	print("=== Stage 3 Dialogue Engine Self-Test ===")
	var ok: int = 0
	var fail: int = 0

	# 1. ConditionParser
	if _test_condition_parser():
		print("  [PASS] ConditionParser")
		ok += 1
	else:
		printerr("  [FAIL] ConditionParser")
		fail += 1

	# 2. Load 9 .tres
	if _test_load_all_dialogues():
		print("  [PASS] Load 9 dialogues")
		ok += 1
	else:
		printerr("  [FAIL] Load 9 dialogues")
		fail += 1

	# 3. Full dialogue flow
	if _test_dialogue_flow():
		print("  [PASS] Dialogue flow (wang_first → buy → end)")
		ok += 1
	else:
		printerr("  [FAIL] Dialogue flow")
		fail += 1

	# 4. Effect trigger
	if _test_effect_trigger():
		print("  [PASS] Effect trigger (cash -= 2, hunger += 20)")
		ok += 1
	else:
		printerr("  [FAIL] Effect trigger")
		fail += 1

	print("=== Result: %d passed, %d failed ===" % [ok, fail])
	if fail > 0:
		push_error("Stage 3 self-test FAILED: %d failures" % fail)


func _test_condition_parser() -> bool:
	var tests: Array = [
		# [expr, context, expected]
		["cash >= 100", {"cash": 50}, false],
		["cash >= 100", {"cash": 200}, true],
		["cash >= 100", {"cash": 100}, true],
		["flag:met_li_ge", {"flags": {"met_li_ge": true}}, true],
		["flag:met_li_ge", {"flags": {}}, false],
		["affinity:npc_wang_ayi >= 50", {"npcs": {"npc_wang_ayi": {"affinity": 60}}}, true],
		["affinity:npc_wang_ayi >= 50", {"npcs": {"npc_wang_ayi": {"affinity": 30}}}, false],
		["stat:strength > 30", {"stats": {"strength": 50}}, true],
		["cash >= 5 and flag:has_money", {"cash": 10, "flags": {"has_money": true}}, true],
		["cash >= 5 and flag:has_money", {"cash": 10, "flags": {}}, false],
		["cash >= 5 or flag:broke", {"cash": 2, "flags": {"broke": true}}, true],
		["not cash < 0", {"cash": 5}, true],
		["", {}, true],  # 空表达式默认 true
	]
	for t in tests:
		var result: bool = ConditionParser.evaluate(t[0], t[1])
		if result != t[2]:
			printerr("    parser fail: '%s' ctx=%s expected=%s got=%s" % [t[0], t[1], t[2], result])
			return false
	return true


func _test_load_all_dialogues() -> bool:
	var ids: Array = [
		"dlg_wang_first", "dlg_wang_friendly", "dlg_wang_close",
		"dlg_li_first", "dlg_li_friendly", "dlg_li_close",
		"dlg_xm_first", "dlg_xm_friendly", "dlg_xm_close",
	]
	for id in ids:
		var res: Resource = load("res://data/dialogues/%s.tres" % id)
		if res == null:
			printerr("    load fail: %s" % id)
			return false
		if res.first_node.is_empty():
			printerr("    no first_node: %s" % id)
			return false
		if res.get_node(res.first_node).is_empty():
			printerr("    first_node not found: %s → %s" % [id, res.first_node])
			return false
	return true


func _test_dialogue_flow() -> bool:
	# 重置玩家 cash 和 hunger
	Player.cash = 100
	Player.hunger = 50
	Player.mood = 50
	# 启动对话
	Dialogue.start_dialogue(&"dlg_wang_first", &"npc_wang_ayi")
	print("    after start: is_in_dialogue=%s current_node_id=%s cash=%d" % [Dialogue.is_in_dialogue, Dialogue.current_node_id, Player.cash])
	if not Dialogue.is_in_dialogue:
		printerr("    start_dialogue didn't set is_in_dialogue")
		return false
	if Dialogue.current_dialogue == null:
		printerr("    current_dialogue is null")
		return false
	if Dialogue.current_node_id != "intro":
		printerr("    current_node_id = %s (expected intro)" % Dialogue.current_node_id)
		return false
	# 选项应至少 2 个（"要" 和 "没钱"）
	var choices: Array = Dialogue.current_node.get("choices", [])
	print("    intro has %d choices: %s" % [choices.size(), choices])
	if choices.size() < 2:
		printerr("    intro should have 2+ choices, got %d" % choices.size())
		return false
	# 选第 0 个（"来碗豆浆"）
	Dialogue.make_choice(0)
	print("    after make_choice(0): current_node_id=%s cash=%d" % [Dialogue.current_node_id, Player.cash])
	# 验证跳到 "buy"
	if Dialogue.current_node_id != "buy":
		printerr("    after choice 0, current_node = %s (expected buy)" % Dialogue.current_node_id)
		return false
	# 推进：buy 节点没有 next_node → advance 第一次完成打字，第二次才 end
	Dialogue.advance()  # 第一次：完成打字
	Dialogue.advance()  # 第二次：因 next_node 空 → end_dialogue
	print("    after 2x advance: is_in_dialogue=%s current_node_id=%s" % [Dialogue.is_in_dialogue, Dialogue.current_node_id])
	if Dialogue.is_in_dialogue:
		printerr("    should be ended after advance from terminal node")
		return false
	return true


func _test_effect_trigger() -> bool:
	Player.cash = 100
	Player.hunger = 50
	Player.mood = 50
	# 重置 met_wang_ayi flag
	Player.set_flag("met_wang_ayi", false)
	# 重置 affinity 到 30
	Player.known_npcs = {}  # 清空已知 NPC
	print("    before start: cash=%d hunger=%d mood=%d affinity=%d" % [Player.cash, Player.hunger, Player.mood, Player.get_affinity("npc_wang_ayi")])
	Dialogue.start_dialogue(&"dlg_wang_first", &"npc_wang_ayi")
	print("    after start: cash=%d hunger=%d mood=%d affinity=%d flag_met=%s" % [Player.cash, Player.hunger, Player.mood, Player.get_affinity("npc_wang_ayi"), Player.has_flag("met_wang_ayi")])
	# intro 节点的 effect：modify_affinity +1, set_flag met_wang_ayi=true
	# 启动后 set_flag 应该已经触发
	if not Player.has_flag("met_wang_ayi"):
		printerr("    set_flag effect not triggered")
		return false
	# 选 "要" → buy 节点：cash -= 2, hunger += 20, mood += 5
	Dialogue.make_choice(0)
	print("    after make_choice(0): cash=%d hunger=%d mood=%d affinity=%d" % [Player.cash, Player.hunger, Player.mood, Player.get_affinity("npc_wang_ayi")])
	if Player.cash != 98:
		printerr("    cash = %d (expected 98)" % Player.cash)
		return false
	if Player.hunger != 70:
		printerr("    hunger = %d (expected 70)" % Player.hunger)
		return false
	if Player.mood != 55:
		printerr("    mood = %d (expected 55)" % Player.mood)
		return false
	# 好感度应该是 30 (default) + 1 (intro effect) = 31
	var aff: int = Player.get_affinity("npc_wang_ayi")
	if aff != 31:
		printerr("    affinity = %d (expected 31)" % aff)
		return false
	return true
