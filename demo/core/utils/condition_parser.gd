## condition_parser.gd
## 微型条件表达式解析器 + 求值器
##
## 支持的语法（按优先级从低到高）：
##   expr      := or_expr
##   or_expr   := and_expr (("or" | "||") and_expr)*
##   and_expr  := not_expr (("and" | "&&") not_expr)*
##   not_expr  := ("not" | "!")? comparison
##   comparison:= value ((">=" | "<=" | ">" | "<" | "==" | "!=") value)?
##   value     := number | string | identifier
##   identifier:= ALPHA (ALPHA|DIGIT|_)*
##               | "flag:" IDENT
##               | "affinity:" IDENT
##               | "stat:" IDENT
##
## 例子：
##   "cash >= 100"
##   "affinity:npc_wang >= 50"
##   "flag:met_li_ge and cash >= 200"
##   "stat:strength > 30 or flag:cheat"
##
## 阶段三需要的所有 case 都覆盖了
class_name ConditionParser
extends RefCounted

const _Self := preload("res://core/utils/condition_parser.gd")


## 公开 API
static func evaluate(expr: String, context: Dictionary = {}) -> bool:
	if expr.strip_edges().is_empty():
		return true
	var parser = _Self.new()
	return parser._parse(expr.strip_edges(), context)


# === 内部 ===
var _input: String = ""
var _pos: int = 0
var _ctx: Dictionary = {}

func _parse(input: String, context: Dictionary) -> bool:
	_input = input
	_pos = 0
	_ctx = context
	var result: bool = _parse_or()
	# 跳过空白后若还有字符，认为无效
	_skip_ws()
	if _pos < _input.length():
		push_warning("ConditionParser: trailing characters at pos %d in '%s'" % [_pos, _input])
	return result


func _parse_or() -> bool:
	var left: bool = _parse_and()
	while _peek_kw(&"or") or _peek_op(&"||"):
		_consume()
		var right: bool = _parse_and()
		left = left or right
	return left

func _parse_and() -> bool:
	var left: bool = _parse_not()
	while _peek_kw(&"and") or _peek_op(&"&&"):
		_consume()
		var right: bool = _parse_not()
		left = left and right
	return left

func _parse_not() -> bool:
	if _peek_kw(&"not") or _peek_op(&"!"):
		_consume()
		return not _parse_comparison()
	return _parse_comparison()

func _parse_comparison() -> bool:
	var left_val: Variant = _parse_value()
	_skip_ws()
	var op: String = ""
	if _pos < _input.length():
		var c: String = _input[_pos]
		if c in [">", "<", "=", "!"]:
			# 可能是 >=, <=, ==, !=
			op = c
			_pos += 1
			if _pos < _input.length() and _input[_pos] == "=":
				op += "="
				_pos += 1
	if op.is_empty():
		# 布尔上下文中，单独值作为 truthy
		return _to_bool(left_val)
	var right_val: Variant = _parse_value()
	return _compare(left_val, op, right_val)


func _parse_value() -> Variant:
	_skip_ws()
	if _pos >= _input.length():
		return null
	var c: String = _input[_pos]
	if c == "\"" or c == "'":
		return _read_string(c)
	# 数字
	if c.is_valid_int() or (c == "-" and _pos + 1 < _input.length() and _input[_pos + 1].is_valid_int()):
		return _read_number()
	# 标识符
	if _is_alpha(c) or c == "_":
		return _read_identifier_value()
	push_warning("ConditionParser: unexpected char '%s' at pos %d" % [c, _pos])
	_pos += 1
	return null


func _read_string(quote: String) -> String:
	_pos += 1  # skip opening quote
	var start: int = _pos
	while _pos < _input.length() and _input[_pos] != quote:
		_pos += 1
	var s: String = _input.substr(start, _pos - start)
	if _pos < _input.length():
		_pos += 1  # skip closing quote
	return s


func _read_number() -> float:
	var start: int = _pos
	if _input[_pos] == "-":
		_pos += 1
	while _pos < _input.length() and (_input[_pos].is_valid_int() or _input[_pos] == "."):
		_pos += 1
	return _input.substr(start, _pos - start).to_float()


func _read_identifier_value() -> Variant:
	var start: int = _pos
	while _pos < _input.length() and (_is_alnum(_input[_pos]) or _input[_pos] == "_" or _input[_pos] == ":"):
		_pos += 1
	var ident: String = _input.substr(start, _pos - start)
	# 命名空间解析
	if ident.begins_with("flag:"):
		var key: String = ident.substr(5)
		return _ctx.get("flags", {}).get(key, false)
	if ident.begins_with("affinity:"):
		var key2: String = ident.substr(9)
		var npcs: Dictionary = _ctx.get("npcs", {})
		if npcs.has(key2):
			return npcs[key2].get("affinity", 30)
		return 30
	if ident.begins_with("stat:"):
		var key3: String = ident.substr(5)
		return _ctx.get("stats", {}).get(key3, 0)
	# 普通变量
	return _ctx.get(ident, null)


# === Helpers ===
func _peek_kw(kw: String) -> bool:
	_skip_ws()
	if _pos + kw.length() > _input.length():
		return false
	for i in range(kw.length()):
		if _input[_pos + i] != kw[i]:
			return false
	# 后必须是 word boundary
	var end: int = _pos + kw.length()
	if end < _input.length() and _is_alnum(_input[end]):
		return false
	return true

func _peek_op(op: String) -> bool:
	_skip_ws()
	if _pos + op.length() > _input.length():
		return false
	for i in range(op.length()):
		if _input[_pos + i] != op[i]:
			return false
	return true

func _consume() -> void:
	_skip_ws()
	while _pos < _input.length() and _is_alnum(_input[_pos]):
		_pos += 1

func _skip_ws() -> void:
	while _pos < _input.length() and (_input[_pos] == " " or _input[_pos] == "\t"):
		_pos += 1

func _is_alpha(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")

func _is_alnum(c: String) -> bool:
	return _is_alpha(c) or c.is_valid_int() or c == "_"

func _to_bool(v: Variant) -> bool:
	if v == null: return false
	if typeof(v) == TYPE_BOOL: return v
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT: return v != 0
	if typeof(v) == TYPE_STRING: return not v.is_empty()
	return true

func _compare(left: Variant, op: String, right: Variant) -> bool:
	# 字符串比较
	if typeof(left) == TYPE_STRING or typeof(right) == TYPE_STRING:
		var ls: String = str(left)
		var rs: String = str(right)
		match op:
			"==": return ls == rs
			"!=": return ls != rs
			">": return ls > rs
			"<": return ls < rs
			">=": return ls >= rs
			"<=": return ls <= rs
	# 数值比较
	var ln: float = float(left) if left != null else 0.0
	var rn: float = float(right) if right != null else 0.0
	match op:
		"==": return ln == rn
		"!=": return ln != rn
		">": return ln > rn
		"<": return ln < rn
		">=": return ln >= rn
		"<=": return ln <= rn
	return false
