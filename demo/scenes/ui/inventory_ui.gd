## inventory_ui.gd
## 背包 UI — 网格、悬停详情、右键使用/丢弃、分类筛选
extends Control

const SLOT_SIZE: Vector2 = Vector2(32, 32)
const GRID_COLS: int = 6

@onready var panel: PanelContainer = $Panel
@onready var grid: GridContainer = $Panel/Margin/VBox/Grid
@onready var detail_panel: PanelContainer = $Panel/Margin/VBox/HBox/DetailPanel
@onready var detail_name: Label = $Panel/Margin/VBox/HBox/DetailPanel/Margin/VBox/Name
@onready var detail_desc: Label = $Panel/Margin/VBox/HBox/DetailPanel/Margin/VBox/Desc
@onready var detail_use_btn: Button = $Panel/Margin/VBox/HBox/DetailPanel/Margin/VBox/UseButton
@onready var detail_drop_btn: Button = $Panel/Margin/VBox/HBox/DetailPanel/Margin/VBox/DropButton
@onready var category_tabs: HBoxContainer = $Panel/Margin/VBox/CategoryTabs

var _slot_buttons: Array[Button] = []
var _selected_slot: int = -1
var _current_filter: int = -1  # -1 = all, 0-6 = category


func _ready() -> void:
	visible = false
	_rebuild_grid()
	_build_category_tabs()
	EventBus.item_added.connect(_on_inventory_changed)
	EventBus.item_removed.connect(_on_inventory_changed)
	EventBus.item_used.connect(_on_inventory_changed)


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false
	_selected_slot = -1


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"open_menu") and visible:
		close()
		get_viewport().set_input_as_handled()


func _rebuild_grid() -> void:
	# 清空
	for c in grid.get_children():
		c.queue_free()
	_slot_buttons.clear()
	# 重建槽位
	for i in range(Player.inventory_capacity):
		var btn := Button.new()
		btn.custom_minimum_size = SLOT_SIZE
		btn.focus_mode = Control.FOCUS_ALL
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var idx: int = i
		btn.pressed.connect(func(): _on_slot_pressed(idx))
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		grid.add_child(btn)
		_slot_buttons.append(btn)
	grid.columns = GRID_COLS


func _build_category_tabs() -> void:
	for c in category_tabs.get_children():
		c.queue_free()
	# "全部" 按钮
	var all_btn := Button.new()
	all_btn.text = "全部"
	all_btn.toggle_mode = true
	all_btn.button_pressed = true
	all_btn.pressed.connect(func(): _on_filter_changed(-1))
	category_tabs.add_child(all_btn)
	# 每个分类
	for cat in 7:
		var btn := Button.new()
		btn.text = ItemData.category_name(cat)
		btn.toggle_mode = true
		var c2: int = cat
		btn.pressed.connect(func(): _on_filter_changed(c2))
		category_tabs.add_child(btn)


func _on_filter_changed(cat: int) -> void:
	_current_filter = cat
	_refresh()


func _refresh() -> void:
	var slots: Array[Dictionary] = Player.inventory_slots
	for i in range(_slot_buttons.size()):
		var btn: Button = _slot_buttons[i]
		if i >= slots.size():
			btn.text = ""
			btn.modulate = Color(0.3, 0.3, 0.3)
			continue
		var slot: Dictionary = slots[i]
		if slot.is_empty():
			btn.text = ""
			btn.modulate = Color(0.3, 0.3, 0.3)
			continue
		var item_id: String = slot.get("item_id", "")
		var qty: int = slot.get("quantity", 0)
		var data: ItemData = Player.get_item(item_id)
		if data == null:
			btn.text = "?"
			continue
		# 分类筛选
		if _current_filter >= 0 and data.category != _current_filter:
			btn.modulate = Color(0.3, 0.3, 0.3)
			btn.text = ""
			continue
		btn.text = "%s\n×%d" % [data.item_name.substr(0, 4), qty] if qty > 1 else data.item_name.substr(0, 6)
		btn.modulate = data.icon_color * 1.5 + Color(0.4, 0.4, 0.4)
	# 详情面板
	_update_detail()


func _on_inventory_changed(_arg1 = null, _arg2 = null) -> void:
	if visible:
		_refresh()


func _on_slot_pressed(idx: int) -> void:
	_selected_slot = idx
	_update_detail()


func _update_detail() -> void:
	if _selected_slot < 0 or _selected_slot >= Player.inventory_slots.size():
		detail_panel.visible = false
		return
	var slot: Dictionary = Player.inventory_slots[_selected_slot]
	if slot.is_empty():
		detail_panel.visible = false
		return
	var data: ItemData = Player.get_item(slot.get("item_id", ""))
	if data == null:
		detail_panel.visible = false
		return
	detail_panel.visible = true
	detail_name.text = "%s ×%d" % [data.item_name, slot.get("quantity", 0)]
	var lines: Array[String] = []
	lines.append(data.description)
	lines.append("[分类] " + ItemData.category_name(data.category))
	if data.buy_price > 0:
		lines.append("[买/卖] %d / %d" % [data.buy_price, data.sell_price])
	if not data.use_effect.is_empty():
		var eff: Array[String] = []
		for k in data.use_effect:
			eff.append("%s %+d" % [k, int(data.use_effect[k])])
		lines.append("[使用] " + ", ".join(eff))
	if data.equip_slot != ItemData.EquipSlot.NONE:
		var slot_name: String = ["", "头", "身体", "脚", "饰品"][data.equip_slot]
		lines.append("[装备槽] %s" % slot_name)
		if not data.equip_bonus.is_empty():
			var b: Array[String] = []
			for k in data.equip_bonus:
				b.append("%s %+d" % [k, int(data.equip_bonus[k])])
			lines.append("[加成] " + ", ".join(b))
	detail_desc.text = "\n".join(lines)
	# 按钮
	detail_use_btn.disabled = not data.is_usable()
	detail_drop_btn.disabled = false


func _on_use_pressed() -> void:
	if _selected_slot < 0:
		return
	var slot: Dictionary = Player.inventory_slots[_selected_slot]
	if slot.is_empty():
		return
	Player.use_item(slot.get("item_id", ""))


func _on_drop_pressed() -> void:
	if _selected_slot < 0:
		return
	var slot: Dictionary = Player.inventory_slots[_selected_slot]
	if slot.is_empty():
		return
	Player.remove_item(slot.get("item_id", ""), 1)
