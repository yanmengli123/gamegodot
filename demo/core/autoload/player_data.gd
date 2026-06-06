## PlayerData.gd
## 玩家全部状态：生存值、能力值、社会值、经济、状态效果、背包
## 所有属性变更走 setter → 触发 EventBus 信号 → UI/HUD/AI 监听
##
## 设计：单例 + 公开字段（避免 200 个 getter）
## 约束：不直接操作 TimeManager / SceneManager；只通过事件通信
extends Node

# === 基础信息 ===
var player_name: String = "无名"
var age: int = 22
var gender: String = "男"  # 仅显示用

# === 生存值（0-100） ===
var stamina: int = 100:
	set(v):
		var old: int = stamina
		stamina = clampi(v, 0, 100)
		if stamina != old:
			EventBus.stamina_changed.emit(stamina, stamina - old)
var hunger: int = 80:
	set(v):
		var old: int = hunger
		hunger = clampi(v, 0, 100)
		if hunger != old:
			EventBus.hunger_changed.emit(hunger, hunger - old)
var mood: int = 70:
	set(v):
		var old: int = mood
		mood = clampi(v, 0, 100)
		if mood != old:
			EventBus.mood_changed.emit(mood, mood - old)
var health: int = 100:
	set(v):
		var old: int = health
		health = clampi(v, 0, 100)
		if health != old:
			EventBus.health_changed.emit(health, health - old)
var hygiene: int = 100:
	set(v):
		var old: int = hygiene
		hygiene = clampi(v, 0, 100)
		if hygiene != old:
			EventBus.hygiene_changed.emit(hygiene, hygiene - old)

# === 能力值（0-100） ===
var strength: int = 30:    # 体力值
	set(v):
		var old: int = strength
		strength = clampi(v, 0, 100)
		if strength != old:
			EventBus.stat_changed.emit("strength", strength, strength - old)
var intelligence: int = 30:  # 智力
	set(v):
		var old: int = intelligence
		intelligence = clampi(v, 0, 100)
		if intelligence != old:
			EventBus.stat_changed.emit("intelligence", intelligence, intelligence - old)
var eloquence: int = 30:  # 口才
	set(v):
		var old: int = eloquence
		eloquence = clampi(v, 0, 100)
		if eloquence != old:
			EventBus.stat_changed.emit("eloquence", eloquence, eloquence - old)
var craft: int = 30:  # 手艺
	set(v):
		var old: int = craft
		craft = clampi(v, 0, 100)
		if craft != old:
			EventBus.stat_changed.emit("craft", craft, craft - old)
var charm: int = 30:  # 魅力
	set(v):
		var old: int = charm
		charm = clampi(v, 0, 100)
		if charm != old:
			EventBus.stat_changed.emit("charm", charm, charm - old)

# === 社会值 ===
var reputation: int = 0:  # 0-1000
	set(v):
		var old: int = reputation
		reputation = clampi(v, 0, 1000)
		if reputation != old:
			EventBus.reputation_changed.emit(reputation)
var morality: int = 0:  # -100 到 100
	set(v):
		var old: int = morality
		morality = clampi(v, -100, 100)
		if morality != old:
			EventBus.morality_changed.emit(morality)
var criminal_record: int = 0:  # 0-100（犯罪记录越高越危险）
	set(v):
		var old: int = criminal_record
		criminal_record = clampi(v, 0, 100)
		if criminal_record != old:
			EventBus.criminal_record_changed.emit(criminal_record)

# === 经济 ===
var cash: int = 500:
	set(v):
		var old: int = cash
		cash = max(0, v)
		if cash != old:
			EventBus.money_changed.emit(cash, cash - old)
var bank_balance: int = 0:
	set(v):
		var old: int = bank_balance
		bank_balance = max(0, v)
		if bank_balance != old:
			EventBus.bank_balance_changed.emit(bank_balance)
var debt: int = 0:
	set(v):
		var old: int = debt
		debt = max(0, v)
		if debt != old:
			EventBus.debt_changed.emit(debt)

# === 住所 ===
var current_accommodation: String = "homeless"  # AccommodationData.id
var accommodation_days_unpaid: int = 0  # 连续未付费天数

# === 状态效果 ===
## key = effect_id, value = {source: String, remaining_hours: float, data: Dictionary}
var status_effects: Dictionary = {}

# === 背包 ===
## Array of {item_id: String, quantity: int}
var inventory_slots: Array[Dictionary] = []
const INVENTORY_BASE_SIZE: int = 12
var inventory_capacity: int = INVENTORY_BASE_SIZE  # 阶段四扩展到 36
## 物品索引（运行时构建，item_id -> ItemData）
var item_index: Dictionary = {}
## 装备：slot(int) -> {item_id, bonus}
var equipped: Dictionary = {}

# === 职业 ===
var current_job: String = ""  # JobData.id，空 = 失业
var current_job_days_worked: int = 0

# === 剧情标记 ===
## key = flag_id, value = bool / int / String
var story_flags: Dictionary = {}

# === 已认识 NPC ===
## key = npc_id, value = {affinity: int, last_meeting_day: int, meetings_today: int}
var known_npcs: Dictionary = {}


func _ready() -> void:
	# 重置 capacity（防止 setter 重复触发）
	inventory_slots.resize(INVENTORY_BASE_SIZE)
	# 订阅每日开始/小时 tick
	EventBus.hour_tick.connect(_on_hour_tick)
	EventBus.day_started.connect(_on_day_started)
	# 加载物品索引
	_build_item_index()


func _build_item_index() -> void:
	if not item_index.is_empty():
		return
	var all_items: Array = ItemFactory.create_all()
	for it in all_items:
		item_index[String(it.item_id)] = it


## 查 ItemData
func get_item(item_id: String) -> ItemData:
	if item_index.is_empty():
		_build_item_index()
	return item_index.get(item_id)


# === 状态效果 API ===
func add_status_effect(effect_id: String, source: String, duration_hours: float, data: Dictionary = {}) -> void:
	if status_effects.has(effect_id):
		# 刷新持续时间，取较长的
		var existing: Dictionary = status_effects[effect_id]
		existing.remaining_hours = max(existing.remaining_hours, duration_hours)
		existing.source = source
		existing.data = data
	else:
		status_effects[effect_id] = {
			"source": source,
			"remaining_hours": duration_hours,
			"data": data,
		}
		EventBus.status_effect_added.emit(effect_id)

func remove_status_effect(effect_id: String) -> void:
	if status_effects.has(effect_id):
		status_effects.erase(effect_id)
		EventBus.status_effect_removed.emit(effect_id)

func has_status_effect(effect_id: String) -> bool:
	return status_effects.has(effect_id)

func is_status_active(effect_id_query: String) -> bool:
	return status_effects.has(effect_id_query)


# === 背包 API ===
## 尝试加物品。先堆叠同类（若可堆叠），剩余找空位。
## 返回实际加进去的数量（可能少于请求）
func add_item(item_id: String, quantity: int = 1) -> int:
	if inventory_slots.size() < inventory_capacity:
		inventory_slots.resize(inventory_capacity)
	var data: ItemData = get_item(item_id)
	if data == null:
		push_warning("add_item: unknown item_id '%s'" % item_id)
		return 0
	var remaining: int = quantity
	# 1) 先堆叠
	if data.stackable:
		for i in range(inventory_slots.size()):
			if remaining <= 0:
				break
			var slot: Dictionary = inventory_slots[i]
			if not slot.is_empty() and slot.get("item_id") == item_id:
				var cur: int = slot.get("quantity", 0)
				if cur < data.max_stack:
					var can: int = data.max_stack - cur
					var add: int = min(can, remaining)
					slot["quantity"] = cur + add
					remaining -= add
	# 2) 找空位
	var start_idx: int = 0
	for i in range(inventory_slots.size()):
		if remaining <= 0:
			break
		if inventory_slots[i].is_empty():
			var add2: int = min(data.max_stack, remaining) if data.stackable else 1
			inventory_slots[i] = {"item_id": item_id, "quantity": add2}
			remaining -= add2
	var added: int = quantity - remaining
	if added > 0:
		EventBus.item_added.emit(item_id, added)
	if remaining > 0:
		EventBus.inventory_full.emit()
	return added


## 移除指定数量。返回实际移除数量。
func remove_item(item_id: String, quantity: int = 1) -> int:
	var remaining: int = quantity
	for i in range(inventory_slots.size()):
		if remaining <= 0:
			break
		var slot: Dictionary = inventory_slots[i]
		if not slot.is_empty() and slot.get("item_id") == item_id:
			var cur: int = slot.get("quantity", 0)
			if cur <= remaining:
				remaining -= cur
				inventory_slots[i] = {}
				EventBus.item_removed.emit(item_id, cur)
			else:
				slot["quantity"] = cur - remaining
				EventBus.item_removed.emit(item_id, remaining)
				remaining = 0
	return quantity - remaining


## 是否拥有至少 quantity 个
func has_item(item_id: String, quantity: int = 1) -> bool:
	return count_item(item_id) >= quantity


## 持有数量
func count_item(item_id: String) -> int:
	var total: int = 0
	for slot in inventory_slots:
		if not slot.is_empty() and slot.get("item_id") == item_id:
			total += slot.get("quantity", 0)
	return total


## 使用物品：触发 use_effect / equip
func use_item(item_id: String, slot_index: int = -1) -> bool:
	var data: ItemData = get_item(item_id)
	if data == null:
		return false
	if not data.is_usable():
		return false
	# 装备
	if data.equip_slot != ItemData.EquipSlot.NONE:
		return equip_item(item_id)
	# 消耗品
	for stat in data.use_effect:
		var delta: int = int(data.use_effect[stat])
		match stat:
			"stamina": stamina = clampi(stamina + delta, 0, 100)
			"hunger": hunger = clampi(hunger + delta, 0, 100)
			"mood": mood = clampi(mood + delta, 0, 100)
			"health": health = clampi(health + delta, 0, 100)
			"hygiene": hygiene = clampi(hygiene + delta, 0, 100)
			"strength": strength = clampi(strength + delta, 0, 100)
			"intelligence": intelligence = clampi(intelligence + delta, 0, 100)
			"eloquence": eloquence = clampi(eloquence + delta, 0, 100)
			"craft": craft = clampi(craft + delta, 0, 100)
			"charm": charm = clampi(charm + delta, 0, 100)
	EventBus.item_used.emit(item_id)
	remove_item(item_id, 1)
	return true


func equip_item(item_id: String) -> bool:
	var data: ItemData = get_item(item_id)
	if data == null or data.equip_slot == ItemData.EquipSlot.NONE:
		return false
	# 同槽位已装备 → 卸下
	if equipped.has(data.equip_slot):
		var prev_id: String = equipped[data.equip_slot].get("item_id", "")
		if prev_id == item_id:
			unequip_slot(data.equip_slot)
			return true
		else:
			unequip_slot(data.equip_slot)
	equipped[data.equip_slot] = {"item_id": item_id, "bonus": data.equip_bonus.duplicate(true)}
	EventBus.item_used.emit(item_id)
	return true


func unequip_slot(slot: int) -> void:
	if equipped.has(slot):
		equipped.erase(slot)


## 按类别排序（返回新数组，不修改原 slots）
func sorted_by_category() -> Array[Dictionary]:
	var arr: Array[Dictionary] = []
	for slot in inventory_slots:
		if not slot.is_empty():
			arr.append(slot.duplicate())
	arr.sort_custom(func(a, b):
		var da: ItemData = get_item(a.get("item_id", ""))
		var db: ItemData = get_item(b.get("item_id", ""))
		if da == null and db == null: return false
		if da == null: return true
		if db == null: return false
		if da.category != db.category: return da.category < db.category
		return da.item_name < db.item_name)
	return arr


## 计算装备的总 buff（简化版）
func get_equip_bonus(stat: String) -> int:
	var total: int = 0
	for slot in equipped.values():
		for k in slot.get("bonus", {}):
			if k == stat:
				total += int(slot["bonus"][k])
	return total


# === 剧情标记 API ===
func set_flag(flag_id: String, value) -> void:
	story_flags[flag_id] = value
	EventBus.flag_set.emit(flag_id, value)

func get_flag(flag_id: String, default = null) -> Variant:
	return story_flags.get(flag_id, default)

func has_flag(flag_id: String) -> bool:
	return story_flags.has(flag_id)


# === NPC 关系 API ===
func get_affinity(npc_id: String) -> int:
	if known_npcs.has(npc_id):
		return known_npcs[npc_id].get("affinity", 30)
	return 30  # 默认中立

func modify_affinity(npc_id: String, delta: int) -> void:
	if not known_npcs.has(npc_id):
		known_npcs[npc_id] = {"affinity": 30, "last_meeting_day": 0, "meetings_today": 0}
	var current: int = known_npcs[npc_id]["affinity"]
	known_npcs[npc_id]["affinity"] = clampi(current + delta, 0, 100)


# === 时间驱动 ===
func _on_hour_tick(_h: int) -> void:
	# 状态效果倒计时
	for effect_id in status_effects.keys():
		var eff: Dictionary = status_effects[effect_id]
		eff.remaining_hours -= 1.0
		if eff.remaining_hours <= 0.0:
			remove_status_effect(effect_id)
	# 简单衰减
	hunger = max(0, hunger - 2)
	mood = max(0, mood - 1)
	if hygiene < 20:
		mood = max(0, mood - 2)


func _on_day_started(_d: int) -> void:
	# 每日结算入口（阶段五扩展：住所扣费、属性恢复）
	accommodation_days_unpaid = 0  # 简化：重置计数
	current_job_days_worked += 1
	# 体力根据住所恢复
	# TODO 阶段五：根据 current_accommodation 调体力
	if stamina < 100:
		stamina = min(100, stamina + 20)  # 临时默认
	if hunger < 100 and has_item("food_basic"):
		# 简化：吃了基础食物
		pass


# === 序列化（存档接口） ===
func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"age": age,
		"gender": gender,
		"stamina": stamina,
		"hunger": hunger,
		"mood": mood,
		"health": health,
		"hygiene": hygiene,
		"strength": strength,
		"intelligence": intelligence,
		"eloquence": eloquence,
		"craft": craft,
		"charm": charm,
		"reputation": reputation,
		"morality": morality,
		"criminal_record": criminal_record,
		"cash": cash,
		"bank_balance": bank_balance,
		"debt": debt,
		"current_accommodation": current_accommodation,
		"accommodation_days_unpaid": accommodation_days_unpaid,
		"status_effects": status_effects.duplicate(true),
		"inventory_slots": inventory_slots.duplicate(true),
		"inventory_capacity": inventory_capacity,
		"current_job": current_job,
		"current_job_days_worked": current_job_days_worked,
		"story_flags": story_flags.duplicate(true),
		"known_npcs": known_npcs.duplicate(true),
	}

func from_dict(d: Dictionary) -> void:
	player_name = d.get("player_name", "无名")
	age = d.get("age", 22)
	gender = d.get("gender", "男")
	stamina = d.get("stamina", 100)
	hunger = d.get("hunger", 80)
	mood = d.get("mood", 70)
	health = d.get("health", 100)
	hygiene = d.get("hygiene", 100)
	strength = d.get("strength", 30)
	intelligence = d.get("intelligence", 30)
	eloquence = d.get("eloquence", 30)
	craft = d.get("craft", 30)
	charm = d.get("charm", 30)
	reputation = d.get("reputation", 0)
	morality = d.get("morality", 0)
	criminal_record = d.get("criminal_record", 0)
	cash = d.get("cash", 500)
	bank_balance = d.get("bank_balance", 0)
	debt = d.get("debt", 0)
	current_accommodation = d.get("current_accommodation", "homeless")
	accommodation_days_unpaid = d.get("accommodation_days_unpaid", 0)
	status_effects = d.get("status_effects", {})
	var inv: Array = d.get("inventory_slots", [])
	inventory_slots = []
	for s in inv:
		inventory_slots.append(s)
	inventory_capacity = d.get("inventory_capacity", INVENTORY_BASE_SIZE)
	current_job = d.get("current_job", "")
	current_job_days_worked = d.get("current_job_days_worked", 0)
	story_flags = d.get("story_flags", {})
	known_npcs = d.get("known_npcs", {})
