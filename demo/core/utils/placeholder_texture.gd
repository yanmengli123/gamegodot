## placeholder_texture.gd
## 程序化生成 16×16 / 16×24 像素占位贴图
## 阶段二用，阶段十美术到位后由设计师替换
##
## 用法：
##   var tex = PlaceholderTexture.solid(Color.RED, 16, 16)
##   $Sprite2D.texture = tex
##
## 所有贴图都强制 nearest filter（项目设置里已设）
class_name PlaceholderTexture
extends RefCounted

const _Self = preload("res://core/utils/placeholder_texture.gd")


## 单色方块
static func solid(color: Color, width: int = 16, height: int = 16) -> ImageTexture:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


## 边框方块（内部透明）
static func bordered(color: Color, width: int = 16, height: int = 16, border: int = 1) -> ImageTexture:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 四边
	for x in range(width):
		for y in range(border):
			img.set_pixel(x, y, color)
			img.set_pixel(x, height - 1 - y, color)
	for y in range(height):
		for x in range(border):
			img.set_pixel(x, y, color)
			img.set_pixel(width - 1 - x, y, color)
	return ImageTexture.create_from_image(img)


## 棋盘格（用于 Tile 预览）
static func checkerboard(c1: Color, c2: Color, cell: int = 8, width: int = 16, height: int = 16) -> ImageTexture:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for x in range(width):
		for y in range(height):
			var on: bool = ((x / cell) + (y / cell)) % 2 == 0
			img.set_pixel(x, y, c1 if on else c2)
	return ImageTexture.create_from_image(img)


## 像素角色（16×24 = 头 8×8 + 身 8×16）
## 用基础色块拼出可辨认的人形；阶段二足够测试
static func pixel_character(skin: Color, hair: Color, shirt: Color, pants: Color) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 头（4-12 行 x，2-10 列 y）
	for x in range(4, 12):
		for y in range(2, 10):
			img.set_pixel(x, y, skin)
	# 头发（2-4 行）
	for x in range(3, 13):
		for y in range(1, 4):
			img.set_pixel(x, y, hair)
	# 眼睛（6 行，x=6 和 x=9）
	img.set_pixel(6, 6, Color.BLACK)
	img.set_pixel(9, 6, Color.BLACK)
	# 嘴（7 行，x=7-8）
	img.set_pixel(7, 7, Color(0.5, 0.3, 0.3))
	img.set_pixel(8, 7, Color(0.5, 0.3, 0.3))
	# 衬衫（10-15 行）
	for x in range(3, 13):
		for y in range(10, 16):
			img.set_pixel(x, y, shirt)
	# 裤子（16-21 行）
	for x in range(3, 13):
		for y in range(16, 22):
			img.set_pixel(x, y, pants)
	# 鞋（22-23 行）
	for x in range(3, 7):
		img.set_pixel(x, 22, Color(0.2, 0.15, 0.1))
		img.set_pixel(x, 23, Color(0.2, 0.15, 0.1))
	for x in range(9, 13):
		img.set_pixel(x, 22, Color(0.2, 0.15, 0.1))
		img.set_pixel(x, 23, Color(0.2, 0.15, 0.1))
	return ImageTexture.create_from_image(img)


## 像素物件（N×N 单色 + 边框 + 中心点）
static func pixel_item(color: Color, size: int = 16) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 主块
	for x in range(2, size - 2):
		for y in range(2, size - 2):
			img.set_pixel(x, y, color)
	# 边框
	var border_c := color.darkened(0.3)
	for x in range(size):
		img.set_pixel(x, 0, border_c)
		img.set_pixel(x, size - 1, border_c)
	for y in range(size):
		img.set_pixel(0, y, border_c)
		img.set_pixel(size - 1, y, border_c)
	# 高光（左上角）
	for i in range(3):
		img.set_pixel(2 + i, 2, color.lightened(0.3))
		img.set_pixel(2, 2 + i, color.lightened(0.3))
	return ImageTexture.create_from_image(img)
