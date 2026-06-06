## npc_factory.gd
## 运行时构造 3 个 NPC 的完整 NPCData + schedule
## 阶段七：改成扫描 data/npcs/ 自动加载
##
## 用法：
##   var data := NPCFactory.create_wang_ayi()
class_name NPCFactory
extends RefCounted


static func create_all() -> Array[NPCData]:
	return [
		create_wang_ayi(),
		create_li_ge(),
		create_xiao_mei(),
	]


# === 王阿姨 ===
static func create_wang_ayi() -> NPCData:
	var d := NPCData.new()
	d.npc_id = &"npc_wang_ayi"
	d.display_name = "王阿姨"
	d.age = 50
	d.gender = "女"
	d.occupation = "早餐摊老板"
	d.personality_tags = PackedStringArray(["友善", "爱唠叨", "热心"])
	d.sprite_seed = Color(0.95, 0.78, 0.65)
	d.default_dialogue_id = &"dlg_wang_first"
	d.affinity_dialogues = {30: &"dlg_wang_friendly", 60: &"dlg_wang_close"}
	d.possible_scenes = PackedStringArray(["train_station", "old_town_market"])
	# 日程
	d.schedules = [
		_make_schedule(0, &"old_town_market", Vector2(200, 150), NPCScheduleData.Action.WORK, &"dlg_wang_first"),  # 黎明
		_make_schedule(1, &"old_town_market", Vector2(200, 150), NPCScheduleData.Action.WORK, &"dlg_wang_friendly"),  # 上午
		_make_schedule(2, &"train_station", Vector2(400, 200), NPCScheduleData.Action.IDLE, &""),  # 下午
		_make_schedule(3, &"old_town_market", Vector2(200, 150), NPCScheduleData.Action.IDLE, &""),  # 傍晚
		_make_schedule(4, &"old_town_market", Vector2(180, 130), NPCScheduleData.Action.SLEEP, &""),  # 夜晚
		_make_schedule(5, &"old_town_market", Vector2(180, 130), NPCScheduleData.Action.SLEEP, &""),  # 深夜
	]
	return d


# === 李哥 ===
static func create_li_ge() -> NPCData:
	var d := NPCData.new()
	d.npc_id = &"npc_li_ge"
	d.display_name = "李哥"
	d.age = 35
	d.gender = "男"
	d.occupation = "建筑工地工头"
	d.personality_tags = PackedStringArray(["严厉", "正直", "讲义气"])
	d.sprite_seed = Color(0.85, 0.65, 0.5)
	d.default_dialogue_id = &"dlg_li_first"
	d.affinity_dialogues = {30: &"dlg_li_friendly", 60: &"dlg_li_close"}
	d.possible_scenes = PackedStringArray(["industrial_site", "old_town_street"])
	d.schedules = [
		_make_schedule(0, &"industrial_site", Vector2(300, 250), NPCScheduleData.Action.SLEEP, &""),  # 黎明还在睡
		_make_schedule(1, &"industrial_site", Vector2(300, 250), NPCScheduleData.Action.WORK, &"dlg_li_first"),  # 上午
		_make_schedule(2, &"industrial_site", Vector2(300, 250), NPCScheduleData.Action.WORK, &"dlg_li_friendly"),  # 下午
		_make_schedule(3, &"old_town_street", Vector2(450, 180), NPCScheduleData.Action.EAT, &""),  # 傍晚吃饭
		_make_schedule(4, &"industrial_site", Vector2(280, 230), NPCScheduleData.Action.SLEEP, &""),  # 夜晚
		_make_schedule(5, &"industrial_site", Vector2(280, 230), NPCScheduleData.Action.SLEEP, &""),  # 深夜
	]
	return d


# === 小美 ===
static func create_xiao_mei() -> NPCData:
	var d := NPCData.new()
	d.npc_id = &"npc_xiao_mei"
	d.display_name = "小美"
	d.age = 22
	d.gender = "女"
	d.occupation = "网吧收银员"
	d.personality_tags = PackedStringArray(["内向", "敏感", "善良"])
	d.sprite_seed = Color(0.98, 0.85, 0.78)
	d.default_dialogue_id = &"dlg_xm_first"
	d.affinity_dialogues = {30: &"dlg_xm_friendly", 60: &"dlg_xm_close"}
	d.possible_scenes = PackedStringArray(["internet_cafe", "old_town_street"])
	d.schedules = [
		_make_schedule(0, &"internet_cafe", Vector2(500, 150), NPCScheduleData.Action.SLEEP, &""),
		_make_schedule(1, &"internet_cafe", Vector2(500, 150), NPCScheduleData.Action.WORK, &"dlg_xm_first"),
		_make_schedule(2, &"internet_cafe", Vector2(500, 150), NPCScheduleData.Action.WORK, &"dlg_xm_friendly"),
		_make_schedule(3, &"old_town_street", Vector2(600, 220), NPCScheduleData.Action.WALK_TO, &""),
		_make_schedule(4, &"internet_cafe", Vector2(490, 140), NPCScheduleData.Action.SLEEP, &""),
		_make_schedule(5, &"internet_cafe", Vector2(490, 140), NPCScheduleData.Action.SLEEP, &""),
	]
	return d


# === Helper ===
static func _make_schedule(period: int, scene_id: StringName, pos: Vector2, action: int, dlg_id: StringName) -> NPCScheduleData:
	var s := NPCScheduleData.new()
	s.period = period
	s.scene_id = scene_id
	s.target_position = pos
	s.action = action
	s.dialogue_id = dlg_id
	return s
