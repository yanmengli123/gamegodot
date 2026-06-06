## dialogue_manager.gd
## 对话状态机 — 完整的推进、条件评估、效果触发
##
## 工作流：
##   start_dialogue(dialogue_id, npc_id)
##   → DialogueUI 监听 show_node / show_choices 信号渲染
##   → UI 调 advance() / make_choice(index) 推进
##   → 节点 effects 立即执行（钱、物品、好感度）
##   → 条件不满足的选项灰显
##   → 节点为空 → 关闭对话
extends Node

## 资源缓存
const _DIALOGUE_DIR: String = "res://data/dialogues/"
var _dialogue_cache: Dictionary = {}  # dialogue_id -> DialogueData

## 当前状态
var current_dialogue: Resource = null  # DialogueData
var current_npc_id: StringName = &""
var current_node: Dictionary = {}
var current_node_id: String = ""
var is_in_dialogue: bool = false

## 打字机状态
var typewriter_finished: bool = false
var typewriter_full_text: String = ""

## 信号（供 DialogueUI 订阅）
signal dialogue_started(dialogue_id: StringName, npc_id: StringName)
signal dialogue_ended(dialogue_id: StringName)
signal show_node(node: Dictionary, speaker_name: String, portrait: String)
signal show_choices(choices: Array)  # Array[Dictionary] 含 enabled 字段
signal hide_choices
signal typewriter_progress(visible_text: String, finished: bool)
signal dialogue_text_variable_replaced(text: String)  # 替换完变量后的完整文本


func _ready() -> void:
	# 启动时扫描 data/dialogues 目录（阶段三完成时建）
	# 阶段三简化：通过 DialogueData.load() 懒加载
	pass


# === 公开 API ===

## 启动一段对话
func start_dialogue(dialogue_id: StringName, npc_id: StringName) -> void:
	if is_in_dialogue:
		push_warning("Dialogue already in progress")
		return
	var data: Resource = _load_dialogue(dialogue_id)
	if data == null:
		push_error("Dialogue '%s' not found" % dialogue_id)
		return
	current_dialogue = data
	current_npc_id = npc_id
	is_in_dialogue = true
	# 立即切游戏状态
	Game.current_state = Game.State.DIALOGUE
	dialogue_started.emit(dialogue_id, npc_id)
	# 跳到第一个节点
	if data.first_node.is_empty():
		push_warning("Dialogue '%s' has no first_node" % dialogue_id)
		end_dialogue()
		return
	_go_to_node(data.first_node)


## 推进到 next_node（线性对话按确认键时）
func advance() -> void:
	if not is_in_dialogue:
		return
	# 如果还在打字中，先把打字完成
	if not typewriter_finished:
		typewriter_finished = true
		typewriter_progress.emit(_replace_variables(current_node.get("text", "")), true)
		return
	var next_id: String = current_node.get("next_node", "")
	if next_id.is_empty():
		end_dialogue()
		return
	_go_to_node(next_id)


## 玩家选择了一个选项
func make_choice(choice_index: int) -> void:
	if not is_in_dialogue:
		return
	var choices: Array = current_node.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return
	var choice: Dictionary = choices[choice_index]
	# 检查 condition
	var cond: String = choice.get("condition", "")
	if not cond.is_empty() and not ConditionParser.evaluate(cond, _build_context()):
		# 条件不满足，UI 应已灰显；理论上不会到这里
		return
	# 执行选项级 effect
	var effect: String = choice.get("effect", "")
	if not effect.is_empty():
		_execute_effect_string(effect)
	EventBus.dialogue_choice_made.emit(current_node_id, choice_index)
	var next_id: String = choice.get("next_node", "")
	if next_id.is_empty():
		end_dialogue()
		return
	_go_to_node(next_id)


## 关闭对话
func end_dialogue() -> void:
	if not is_in_dialogue:
		return
	var finished_id: StringName = current_dialogue.dialogue_id if current_dialogue else &""
	current_dialogue = null
	current_npc_id = &""
	current_node = {}
	current_node_id = ""
	is_in_dialogue = false
	typewriter_finished = false
	hide_choices.emit()
	Game.current_state = Game.State.EXPLORING
	dialogue_ended.emit(finished_id)


## 玩家按取消键
func cancel() -> void:
	end_dialogue()


# === 内部 ===
func _go_to_node(node_id: String) -> void:
	if current_dialogue == null:
		return
	var node: Dictionary = current_dialogue.get_node(node_id)
	if node.is_empty():
		push_warning("Dialogue node '%s' not found" % node_id)
		end_dialogue()
		return
	# 节点级 condition
	var cond: String = node.get("condition", "")
	if not cond.is_empty() and not ConditionParser.evaluate(cond, _build_context()):
		# 跳到 next_node_otherwise
		var otherwise: String = node.get("next_node_otherwise", "")
		if otherwise.is_empty():
			end_dialogue()
			return
		_go_to_node(otherwise)
		return
	current_node = node
	current_node_id = node_id
	# 执行节点 effects
	for eff in node.get("effects", []):
		_execute_effect(eff)
	# 渲染节点
	var speaker_name: String = _resolve_speaker_name(node.get("speaker", ""))
	var portrait: String = node.get("portrait", "normal")
	show_node.emit(node, speaker_name, portrait)
	# 启动打字机
	typewriter_finished = false
	typewriter_full_text = _replace_variables(node.get("text", ""))
	typewriter_progress.emit("", false)
	# 选项
	var choices: Array = node.get("choices", [])
	if choices.is_empty():
		hide_choices.emit()
	else:
		# 评估每个选项的 condition
		var ctx: Dictionary = _build_context()
		var annotated: Array = []
		for ch in choices:
			var enabled: bool = true
			var c: String = ch.get("condition", "")
			if not c.is_empty():
				enabled = ConditionParser.evaluate(c, ctx)
			annotated.append({
				"text": ch.get("text", ""),
				"enabled": enabled,
				"reason": "" if enabled else _condition_hint(c),
			})
		show_choices.emit(annotated)


func _resolve_speaker_name(speaker_id: String) -> String:
	if speaker_id == "player" or speaker_id == "我":
		return Player.player_name
	# TODO 阶段三完善：查 NPCData.display_name
	if speaker_id.is_empty():
		return ""
	# 用 npc_id 当显示名（fallback）
	return speaker_id


func _replace_variables(text: String) -> String:
	if text.is_empty():
		return text
	var result: String = text
	result = result.replace("{player_name}", Player.player_name)
	result = result.replace("{cash}", str(Player.cash))
	result = result.replace("{hour}", "%02d:00" % TimeMgr.hour)
	result = result.replace("{day}", str(TimeMgr.day))
	result = result.replace("{month}", str(TimeMgr.month))
	result = result.replace("{year}", str(TimeMgr.year))
	result = result.replace("{period}", _period_name(TimeMgr.period))
	return result


func _period_name(p: int) -> String:
	match p:
		0: return "黎明"
		1: return "上午"
		2: return "下午"
		3: return "傍晚"
		4: return "夜晚"
		5: return "深夜"
	return "未知"


func _condition_hint(cond: String) -> String:
	# 简易提示（阶段八完善为友好提示）
	if cond.begins_with("cash") or cond.begins_with("money"):
		return "钱不够"
	if cond.begins_with("affinity:"):
		return "好感度不够"
	if cond.begins_with("flag:"):
		return "尚未触发条件"
	if cond.begins_with("stat:"):
		return "属性不足"
	return "条件不满足"


# === Effect 执行 ===
func _execute_effect(eff: Dictionary) -> void:
	var t: String = eff.get("type", "")
	match t:
		"modify_affinity":
			var npc_id: String = eff.get("npc_id", String(current_npc_id))
			Player.modify_affinity(npc_id, int(eff.get("delta", 0)))
		"modify_money":
			Player.cash = Player.cash + int(eff.get("delta", 0))
		"modify_stat":
			var stat: String = eff.get("stat", "")
			var delta: int = int(eff.get("delta", 0))
			match stat:
				"stamina": Player.stamina = clampi(Player.stamina + delta, 0, 100)
				"hunger": Player.hunger = clampi(Player.hunger + delta, 0, 100)
				"mood": Player.mood = clampi(Player.mood + delta, 0, 100)
				"health": Player.health = clampi(Player.health + delta, 0, 100)
				"hygiene": Player.hygiene = clampi(Player.hygiene + delta, 0, 100)
				"strength": Player.strength = clampi(Player.strength + delta, 0, 100)
				"intelligence": Player.intelligence = clampi(Player.intelligence + delta, 0, 100)
				"eloquence": Player.eloquence = clampi(Player.eloquence + delta, 0, 100)
				"craft": Player.craft = clampi(Player.craft + delta, 0, 100)
				"charm": Player.charm = clampi(Player.charm + delta, 0, 100)
		"give_item":
			Player.add_item(StringName(eff.get("item_id", "")), int(eff.get("quantity", 1)))
		"unlock_event":
			EventBus.story_event_triggered.emit(String(eff.get("event_id", "")))
		"set_flag":
			Player.set_flag(String(eff.get("flag_id", "")), eff.get("value", true))
		"trigger_event":
			EventBus.story_event_triggered.emit(String(eff.get("event_id", "")))
		_:
			push_warning("Unknown effect type: %s" % t)


## 执行单行 effect 字符串（用于 choice.effect 简写）
## 支持："cash -= 50", "stamina += 10", "give:food_doujiang", "flag:met_wang_ayi = true"
func _execute_effect_string(s: String) -> void:
	var st: String = s.strip_edges()
	if st.is_empty():
		return
	# key OP value
	if "=" in st:
		var parts: PackedStringArray = st.split("=", true, 1)
		var lhs: String = parts[0].strip_edges()
		var rhs: String = parts[1].strip_edges()
		# flag:ID = value
		if lhs.begins_with("flag:"):
			var key: String = lhs.substr(5)
			var v: Variant = _parse_value_token(rhs)
			Player.set_flag(key, v)
			return
		# 简单算术（只支持 + -）
		var delta: int = 0
		if "+=" in st:
			var p2: PackedStringArray = st.split("+=", true, 1)
			delta = int(p2[1].strip_edges())
		elif "-=" in st:
			var p3: PackedStringArray = st.split("-=", true, 1)
			delta = -int(p3[1].strip_edges())
		match lhs:
			"cash", "money": Player.cash = max(0, Player.cash + delta)
			"stamina": Player.stamina = clampi(Player.stamina + delta, 0, 100)
			"hunger": Player.hunger = clampi(Player.hunger + delta, 0, 100)
			"mood": Player.mood = clampi(Player.mood + delta, 0, 100)
			"health": Player.health = clampi(Player.health + delta, 0, 100)
			"hygiene": Player.hygiene = clampi(Player.hygiene + delta, 0, 100)
			"strength": Player.strength = clampi(Player.strength + delta, 0, 100)
			"intelligence": Player.intelligence = clampi(Player.intelligence + delta, 0, 100)
			"eloquence": Player.eloquence = clampi(Player.eloquence + delta, 0, 100)
			"craft": Player.craft = clampi(Player.craft + delta, 0, 100)
			"charm": Player.charm = clampi(Player.charm + delta, 0, 100)
	# "give:item_id" 简写
	if st.begins_with("give:"):
		Player.add_item(StringName(st.substr(5)), 1)
		return


func _parse_value_token(tok: String) -> Variant:
	if tok == "true": return true
	if tok == "false": return false
	if tok.is_valid_int(): return int(tok)
	if tok.is_valid_float(): return float(tok)
	return tok


# === 条件求值上下文 ===
func _build_context() -> Dictionary:
	return {
		"cash": Player.cash,
		"money": Player.cash,
		"flags": Player.story_flags,
		"npcs": Player.known_npcs,
		"stats": {
			"stamina": Player.stamina,
			"hunger": Player.hunger,
			"mood": Player.mood,
			"health": Player.health,
			"hygiene": Player.hygiene,
			"strength": Player.strength,
			"intelligence": Player.intelligence,
			"eloquence": Player.eloquence,
			"craft": Player.craft,
			"charm": Player.charm,
		},
		"current_npc_id": String(current_npc_id),
		"current_dialogue_id": String(current_dialogue.dialogue_id) if current_dialogue else "",
	}


# === 资源加载 ===
func _load_dialogue(dialogue_id: StringName) -> Resource:
	if _dialogue_cache.has(dialogue_id):
		return _dialogue_cache[dialogue_id]
	var path: String = "%s%s.tres" % [_DIALOGUE_DIR, dialogue_id]
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res != null:
		_dialogue_cache[dialogue_id] = res
	return res
