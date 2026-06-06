## economy_service.gd
## 经济服务 — 商店 + 银行 + 每日结算
##
## 提供：
##   - buy_from_shop(shop_id, item_id, qty) / sell_to_shop
##   - bank_deposit / bank_withdraw / take_loan / repay_loan
##   - 每日结算（自动订阅 day_started）：住所扣费 / 工资到账 / 贷款利息
extends Node

const _SELF := preload("res://core/autoload/economy_service.gd")

## 贷款上限
const LOAN_MAX: int = 5000
## 存款日利率
const DEPOSIT_INTEREST: float = 0.0001
## 贷款日利率
const LOAN_INTEREST: float = 0.001

## 商店数据缓存
var _shop_cache: Dictionary = {}

## 每日支出明细（最近 7 天，{day: {rent: x, food: y, ...}}）
var daily_expenses: Array[Dictionary] = []


func _ready() -> void:
	EventBus.day_started.connect(_on_day_started)
	# 注册默认商店（王阿姨早餐摊）
	_register_default_shops()


func _register_default_shops() -> void:
	var wang_shop := ShopData.new()
	wang_shop.shop_id = &"shop_wang_breakfast"
	wang_shop.shop_name = "王阿姨早餐摊"
	wang_shop.npc_id = &"npc_wang_ayi"
	wang_shop.stock_item_ids = PackedStringArray(["food_doujiang", "food_youtiao", "food_baozi", "food_xiaomi_zhou"])
	wang_shop.stock_quantity = 20
	wang_shop.buyback_categories = PackedInt32Array([ItemData.Category.FOOD, ItemData.Category.MISC])
	_shop_cache["shop_wang_breakfast"] = wang_shop

	var pharmacy := ShopData.new()
	pharmacy.shop_id = &"shop_pharmacy"
	pharmacy.shop_name = "便民药店"
	pharmacy.npc_id = &""
	pharmacy.stock_item_ids = PackedStringArray(["medicine_bandage", "medicine_cold", "medicine_painkiller"])
	pharmacy.stock_quantity = 5
	pharmacy.buyback_categories = PackedInt32Array()
	_shop_cache["shop_pharmacy"] = pharmacy

	var clothing := ShopData.new()
	clothing.shop_id = &"shop_clothing"
	clothing.shop_name = "老张服装店"
	clothing.npc_id = &""
	clothing.stock_item_ids = PackedStringArray(["clothing_tshirt", "clothing_jeans", "clothing_sneaker", "clothing_cap"])
	clothing.stock_quantity = 3
	clothing.buyback_categories = PackedInt32Array([ItemData.Category.CLOTHING])
	_shop_cache["shop_clothing"] = clothing


func get_shop(shop_id: String) -> ShopData:
	return _shop_cache.get(shop_id)


# === 交易 ===
## 玩家从商店买 qty 个物品
func buy_from_shop(shop_id: String, item_id: String, qty: int = 1) -> bool:
	var shop: ShopData = get_shop(shop_id)
	if shop == null: return false
	var data: ItemData = Player.get_item(item_id)
	if data == null: return false
	var aff: int = Player.get_affinity(String(shop.npc_id))
	var price_each: int = shop.get_sell_price(item_id, data.buy_price, aff, Player.eloquence)
	var total: int = price_each * qty
	if Player.cash < total:
		return false
	Player.cash -= total
	Player.add_item(item_id, qty)
	RecordExpense("shop_" + shop_id, total)
	return true


## 玩家卖给商店
func sell_to_shop(shop_id: String, item_id: String, qty: int = 1) -> bool:
	var shop: ShopData = get_shop(shop_id)
	if shop == null: return false
	var data: ItemData = Player.get_item(item_id)
	if data == null: return false
	if not shop.buys_category(data.category):
		return false
	if not Player.has_item(item_id, qty):
		return false
	var aff: int = Player.get_affinity(String(shop.npc_id))
	var price_each: int = shop.get_buyback_price(item_id, data.sell_price, aff)
	var total: int = price_each * qty
	Player.remove_item(item_id, qty)
	Player.cash += total
	RecordIncome("shop_" + shop_id, total)
	return true


# === 银行 ===
func bank_deposit(amount: int) -> bool:
	if amount <= 0 or Player.cash < amount:
		return false
	Player.cash -= amount
	Player.bank_balance += amount
	RecordExpense("bank_deposit", amount)
	return true


func bank_withdraw(amount: int) -> bool:
	if amount <= 0 or Player.bank_balance < amount:
		return false
	Player.bank_balance -= amount
	Player.cash += amount
	RecordIncome("bank_withdraw", amount)
	return true


func take_loan(amount: int) -> bool:
	if amount <= 0 or Player.debt + amount > LOAN_MAX:
		return false
	Player.debt += amount
	Player.cash += amount
	RecordIncome("loan", amount)
	return true


func repay_loan(amount: int) -> bool:
	if amount <= 0 or Player.cash < amount:
		return false
	var pay: int = min(amount, Player.debt)
	Player.cash -= pay
	Player.debt -= pay
	RecordExpense("loan_repay", pay)
	return true


# === 每日结算 ===
func _on_day_started(_day: int) -> void:
	# 1) 银行利息
	if Player.bank_balance > 0:
		var interest: int = int(floor(Player.bank_balance * DEPOSIT_INTEREST))
		if interest > 0:
			Player.bank_balance += interest
			RecordIncome("bank_interest", interest)
	if Player.debt > 0:
		var loan_int: int = int(ceil(Player.debt * LOAN_INTEREST))
		Player.debt += loan_int
		RecordExpense("loan_interest", loan_int)
		# 负债 > 5000：游戏结束（阶段八细化）
		if Player.debt > 5000:
			Game.trigger_game_over("负债超过 5000，被追债")
	# 2) 住所扣费（阶段五会按住所档次）
	_pay_accommodation()
	# 3) 长期失业 / 健康差：触发事件
	# TODO 阶段五
	# 4) 保留最近 7 天
	daily_expenses = daily_expenses.slice(-7)


func _pay_accommodation() -> void:
	# 阶段五实现：按 Player.current_accommodation 查价
	# 这里占位
	pass


# === 收入支出记录 ===
func RecordIncome(source: String, amount: int) -> void:
	_last_day_record()[source] = int(_last_day_record().get(source, 0)) + amount

func RecordExpense(source: String, amount: int) -> void:
	_last_day_record()["_" + source] = int(_last_day_record().get("_" + source, 0)) + amount

func _last_day_record() -> Dictionary:
	if daily_expenses.is_empty() or not daily_expenses[-1].has("day"):
		daily_expenses.append({"day": TimeMgr.day, "income": 0, "expense": 0})
	return daily_expenses[-1]
