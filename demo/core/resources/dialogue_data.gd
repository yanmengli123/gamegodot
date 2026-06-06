## dialogue_data.gd
## 对话数据资源 — 一段对话 = 节点数组
## 节点：speaker_id, text, portrait, choices[], effects[], next_node
## 变量替换：{player_name} {cash} {hour} {period}
class_name DialogueData
extends Resource

## 单个对话节点（Godot 不支持内嵌 class_name Dictionary，用纯 dict）
## schema：
## {
##   "node_id": "intro_1",
##   "speaker": "npc_wang",
##   "text": "早啊，{player_name}，来碗豆浆？",
##   "portrait": "happy",  # normal/happy/angry/sad/surprised
##   "choices": [
##     { "text": "要", "next_node": "buy", "condition": "cash >= 5", "effect": "cash -= 5" },
##     { "text": "不要", "next_node": "refuse" }
##   ],
##   "next_node": "intro_2",  # 线性时用
##   "condition": "flag:met_li_ge",  # 整节点显示条件（不满足则跳过到 next_node_otherwise）
##   "next_node_otherwise": "intro_default",
##   "effects": [  # 节点进入时立即执行
##     { "type": "modify_affinity", "npc_id": "npc_wang", "delta": 5 },
##     { "type": "modify_money", "delta": -5 },
##     { "type": "modify_stat", "stat": "hunger", "delta": 30 },
##     { "type": "give_item", "item_id": "food_doujiang", "quantity": 1 },
##     { "type": "unlock_event", "event_id": "ev_first_work" },
##     { "type": "set_flag", "flag_id": "met_wang_ayi", "value": true },
##     { "type": "trigger_event", "event_id": "ev_breakfast_special" }
##   ]
## }

@export var dialogue_id: StringName = &""
@export var first_node: String = ""
@export var nodes: Array = []  # Array[Dictionary]
@export var auto_close_on_end: bool = true  # 到末尾时自动关闭对话


## 根据 node_id 找节点
func get_node(node_id: String) -> Dictionary:
	for n in nodes:
		if n.get("node_id", "") == node_id:
			return n
	return {}


## 序列化
func to_dict() -> Dictionary:
	return {
		"dialogue_id": String(dialogue_id),
		"first_node": first_node,
		"nodes": nodes.duplicate(true),
		"auto_close_on_end": auto_close_on_end,
	}
