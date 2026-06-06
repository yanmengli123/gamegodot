## shop_ui.gd
## 商店交易 UI — 左货架 / 中交易 / 右玩家背包（简化）
extends Control

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var cash_label: Label = $Panel/Margin/VBox/CashLabel
@onready var shop_list: ItemList = $Panel/Margin/VBox/HBox/ShopList
@onready var inv_list: ItemList = $Panel/Margin/VBox/HBox/InvList
@onready var trade_label: Label = $Panel/Margin/VBox/HBox/TradePanel/Margin/VBox/TradeLabel
@onready var buy_btn: Button = $Panel/Margin/VBox/HBox/TradePanel/Margin/VBox/BuyButton
@onready var sell_btn: Button = $Panel/Margin/VBox/HBox/TradePanel/Margin/VBox/SellButton
@onready var close_btn: Button = $Panel/Margin/VBox/CloseButton

var _shop: ShopData = null
var _shop_stock: Dictionary = {}  # item_id -> remaining qty
var _mode: String = "buy"  # buy / sell


func open(shop_id: String) -> void:
	_shop = Economy.get_shop(shop_id)
	if _shop == null:
		push_warning("Shop not found: %s" % shop_id)
		return
	visible = true
	title_label.text = _shop.shop_name
	# 刷新库存
	_shop_stock.clear()
	for iid in _shop.stock_item_ids:
		_shop_stock[iid] = _shop.stock_quantity
	_refresh()


func close() -> void:
	visible = false
	_shop = null


func _ready() -> void:
	visible = false
	buy_btn.pressed.connect(func(): _on_mode_changed("buy"))
	sell_btn.pressed.connect(func(): _on_mode_changed("sell"))
	close_btn.pressed.connect(close)
	shop_list.item_selected.connect(_on_shop_item_selected)
	inv_list.item_selected.connect(_on_inv_item_selected)


func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"open_menu"):
		close()
		get_viewport().set_input_as_handled()


func _on_mode_changed(m: String) -> void:
	_mode = m
	_refresh()


func _refresh() -> void:
	_update_cash()
	# 商店货架
	shop_list.clear()
	for iid in _shop.stock_item_ids:
		var data: ItemData = Player.get_item(iid)
		if data == null: continue
		var remaining: int = _shop_stock.get(iid, 0)
		var aff: int = Player.get_affinity(String(_shop.npc_id))
		var price: int = _shop.get_sell_price(iid, data.buy_price, aff, Player.eloquence)
		shop_list.add_item("%s  ¥%d (剩%d)" % [data.item_name, price, remaining])
		shop_list.set_item_metadata(shop_list.item_count - 1, iid)
	# 玩家背包（可卖给商店的）
	inv_list.clear()
	for slot in Player.inventory_slots:
		if slot.is_empty(): continue
		var iid2: String = slot.get("item_id", "")
		var data2: ItemData = Player.get_item(iid2)
		if data2 == null: continue
		if not _shop.buys_category(data2.category): continue
		var qty: int = slot.get("quantity", 0)
		var bp: int = _shop.get_buyback_price(iid2, data2.sell_price, aff)
		inv_list.add_item("%s ×%d  卖¥%d" % [data2.item_name, qty, bp])
		inv_list.set_item_metadata(inv_list.item_count - 1, iid2)
	_update_trade_label()


func _update_cash() -> void:
	cash_label.text = "现金：¥%d  银行：¥%d  负债：¥%d" % [Player.cash, Player.bank_balance, Player.debt]


func _on_shop_item_selected(idx: int) -> void:
	_mode = "buy"
	_update_trade_label(idx)


func _on_inv_item_selected(idx: int) -> void:
	_mode = "sell"
	_update_trade_label(idx)


func _update_trade_label(shop_idx: int = -1) -> void:
	if _mode == "buy":
		var si: int = shop_list.get_selected_items()[0] if shop_list.get_selected_items().size() > 0 else -1
		if si < 0:
			trade_label.text = "选择商品"
			return
		var iid: String = shop_list.get_item_metadata(si)
		var data: ItemData = Player.get_item(iid)
		var aff: int = Player.get_affinity(String(_shop.npc_id))
		var price: int = _shop.get_sell_price(iid, data.buy_price, aff, Player.eloquence)
		trade_label.text = "购买 %s：¥%d" % [data.item_name, price]
	else:
		var ii: int = inv_list.get_selected_items()[0] if inv_list.get_selected_items().size() > 0 else -1
		if ii < 0:
			trade_label.text = "选择物品"
			return
		var iid2: String = inv_list.get_item_metadata(ii)
		var data2: ItemData = Player.get_item(iid2)
		var aff2: int = Player.get_affinity(String(_shop.npc_id))
		var price2: int = _shop.get_buyback_price(iid2, data2.sell_price, aff2)
		trade_label.text = "出售 %s：¥%d" % [data2.item_name, price2]


func _on_buy_pressed() -> void:
	if _mode != "buy" or _shop == null: return
	var si: int = shop_list.get_selected_items()[0] if shop_list.get_selected_items().size() > 0 else -1
	if si < 0: return
	var iid: String = shop_list.get_item_metadata(si)
	if Economy.buy_from_shop(String(_shop.shop_id), iid, 1):
		_shop_stock[iid] = max(0, _shop_stock[iid] - 1)
		_refresh()


func _on_sell_pressed() -> void:
	if _mode != "sell" or _shop == null: return
	var ii: int = inv_list.get_selected_items()[0] if inv_list.get_selected_items().size() > 0 else -1
	if ii < 0: return
	var iid: String = inv_list.get_item_metadata(ii)
	if Economy.sell_to_shop(String(_shop.shop_id), iid, 1):
		_refresh()
