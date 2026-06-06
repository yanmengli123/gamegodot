## pixel_artist.gd
## 高级像素角色 / 物品 / 瓦片生成器
##
## 阶段十美术到位之前所有精灵从这里出
## 每个函数返回 ImageTexture，调用方负责塞到 Sprite2D / TileSetAtlas
class_name PixelArtist
extends RefCounted

const _Self := preload("res://core/utils/pixel_artist.gd")


# === 基础原语 ===

## 4 帧走路动画（16×24 each，2x2 grid = 64×48）
## frames[0,1,2,1] 标准循环
static func make_walk_sprite(skin: Color, hair: Color, shirt: Color, pants: Color, _shoes: Color = Color(0.2, 0.15, 0.1)) -> ImageTexture:
	# 64×48 包含 2 帧水平 × 2 帧垂直
	# 实际只生成 down 方向 4 帧（其他方向用 down 镜像 + 偏移）
	var img: Image = Image.create(64, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 4 帧：x=0, 16, 32, 48；y=0（向下）
	for fx in range(4):
		var ox: int = fx * 16
		_draw_man(img, ox, 0, skin, hair, shirt, pants, fx)
	return ImageTexture.create_from_image(img)


static func _draw_man(img: Image, ox: int, oy: int, skin: Color, hair: Color, shirt: Color, pants: Color, frame: int) -> void:
	# 头部 8x8 @ (4..12, 2..10)
	for x in range(4, 12):
		for y in range(2, 10):
			img.set_pixel(ox + x, oy + y, skin)
	# 头发 8x3 @ (3..13, 1..4)
	for x in range(3, 13):
		for y in range(1, 4):
			img.set_pixel(ox + x, oy + y, hair)
	# 眼睛 @ y=6
	img.set_pixel(ox + 6, oy + 6, Color.BLACK)
	img.set_pixel(ox + 9, oy + 6, Color.BLACK)
	# 嘴 @ y=7
	img.set_pixel(ox + 7, oy + 7, Color(0.5, 0.3, 0.3))
	img.set_pixel(ox + 8, oy + 7, Color(0.5, 0.3, 0.3))
	# 衬衫 10x6 @ (3..13, 10..16)
	for x in range(3, 13):
		for y in range(10, 16):
			img.set_pixel(ox + x, oy + y, shirt)
	# 腿动画：frame 0 = 左前；frame 1 = 中；frame 2 = 右前；frame 3 = 中
	match frame:
		0:
			_draw_limb(img, ox + 4, oy + 16, 2, 5, pants)  # 左腿前
			_draw_limb(img, ox + 9, oy + 16, 2, 5, pants)  # 右腿后（稍微暗）
			# 鞋
			img.set_pixel(ox + 4, oy + 21, Color(0.15, 0.1, 0.05))
			img.set_pixel(ox + 4, oy + 22, Color(0.15, 0.1, 0.05))
			img.set_pixel(ox + 10, oy + 22, Color(0.1, 0.08, 0.04))
		2:
			_draw_limb(img, ox + 4, oy + 16, 2, 5, pants)
			_draw_limb(img, ox + 9, oy + 16, 2, 5, pants)
			img.set_pixel(ox + 5, oy + 22, Color(0.1, 0.08, 0.04))
			img.set_pixel(ox + 9, oy + 21, Color(0.15, 0.1, 0.05))
			img.set_pixel(ox + 9, oy + 22, Color(0.15, 0.1, 0.05))
		_:
			# 中间帧：腿并拢
			for x in range(4, 11):
				for y in range(16, 22):
					img.set_pixel(ox + x, oy + y, pants)
			img.set_pixel(ox + 4, oy + 22, Color(0.15, 0.1, 0.05))
			img.set_pixel(ox + 4, oy + 23, Color(0.15, 0.1, 0.05))
			img.set_pixel(ox + 9, oy + 22, Color(0.15, 0.1, 0.05))
			img.set_pixel(ox + 9, oy + 23, Color(0.15, 0.1, 0.05))


static func _draw_limb(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for dx in range(w):
		for dy in range(h):
			img.set_pixel(x + dx, y + dy, color)


## 4 朝向精灵（down / up / left / right）= 64×96
static func make_4direction_sprite(skin: Color, hair: Color, shirt: Color, pants: Color) -> ImageTexture:
	# 64x96 包含 2x2 朝向布局，每个朝向 32x48
	# 实际：down (0,0) up (32,0) right (0,48) left (32,48)
	var img: Image = Image.create(64, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Down (0,0) 32x48
	_draw_man(img, 8, 0, skin, hair, shirt, pants, 1)  # 居中
	# Up (32,0) — 反向画（头不画眼/嘴）
	_draw_man_back(img, 40, 0, skin, hair, shirt, pants, 1)
	# Right (0,48) — 侧脸只露一只眼
	_draw_man_side(img, 8, 48, true, skin, hair, shirt, pants, 1)
	# Left (32,48) — 镜像
	_draw_man_side(img, 40, 48, false, skin, hair, shirt, pants, 1)
	return ImageTexture.create_from_image(img)


static func _draw_man_back(img: Image, ox: int, oy: int, skin: Color, hair: Color, shirt: Color, pants: Color, frame: int) -> void:
	for x in range(4, 12):
		for y in range(2, 10):
			img.set_pixel(ox + x, oy + y, skin)
	for x in range(3, 13):
		for y in range(1, 4):
			img.set_pixel(ox + x, oy + y, hair)
	# 后脑勺头发（更多覆盖）
	for x in range(3, 13):
		for y in range(4, 6):
			img.set_pixel(ox + x, oy + y, hair)
	# 衬衫
	for x in range(3, 13):
		for y in range(10, 16):
			img.set_pixel(ox + x, oy + y, shirt)
	# 裤
	for x in range(3, 13):
		for y in range(16, 22):
			img.set_pixel(ox + x, oy + y, pants)
	# 鞋
	img.set_pixel(ox + 4, oy + 22, Color(0.15, 0.1, 0.05))
	img.set_pixel(ox + 4, oy + 23, Color(0.15, 0.1, 0.05))
	img.set_pixel(ox + 9, oy + 22, Color(0.15, 0.1, 0.05))
	img.set_pixel(ox + 9, oy + 23, Color(0.15, 0.1, 0.05))


static func _draw_man_side(img: Image, ox: int, oy: int, facing_right: bool, skin: Color, hair: Color, shirt: Color, pants: Color, frame: int) -> void:
	# 头（侧脸，比正面窄）
	for x in range(5, 11):
		for y in range(2, 10):
			img.set_pixel(ox + x, oy + y, skin)
	# 头发
	for x in range(4, 12):
		for y in range(1, 4):
			img.set_pixel(ox + x, oy + y, hair)
	# 眼睛（侧脸只一只眼，朝前）
	var eye_x: int = 9 if facing_right else 6
	img.set_pixel(ox + eye_x, oy + 6, Color.BLACK)
	# 嘴
	img.set_pixel(ox + eye_x, oy + 7, Color(0.5, 0.3, 0.3))
	# 衬衫
	for x in range(4, 12):
		for y in range(10, 16):
			img.set_pixel(ox + x, oy + y, shirt)
	# 裤
	for x in range(4, 12):
		for y in range(16, 22):
			img.set_pixel(ox + x, oy + y, pants)
	# 鞋
	img.set_pixel(ox + 4, oy + 22, Color(0.15, 0.1, 0.05))
	img.set_pixel(ox + 4, oy + 23, Color(0.15, 0.1, 0.05))
	img.set_pixel(ox + 9, oy + 22, Color(0.15, 0.1, 0.05))
	img.set_pixel(ox + 9, oy + 23, Color(0.15, 0.1, 0.05))


# === 物品精灵 ===

## 食物（碗/包/药瓶）— 16x16
static func make_food_sprite(kind: String) -> ImageTexture:
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match kind:
		"doujiang":  # 碗
			for x in range(2, 14):
				img.set_pixel(x, 10, Color(0.6, 0.5, 0.4))  # 碗沿
			for x in range(3, 13):
				img.set_pixel(x, 11, Color(0.5, 0.4, 0.3))
			for x in range(3, 13):
				for y in range(5, 10):
					img.set_pixel(x, y, Color(0.95, 0.92, 0.8))  # 豆浆
		"youtiao":  # 长条
			for x in range(3, 13):
				for y in range(6, 10):
					img.set_pixel(x, y, Color(0.95, 0.78, 0.4))
		"baozi":
			for x in range(3, 13):
				for y in range(6, 12):
					img.set_pixel(x, y, Color(0.95, 0.92, 0.85))
			# 褶
			img.set_pixel(5, 8, Color(0.7, 0.6, 0.5))
			img.set_pixel(10, 8, Color(0.7, 0.6, 0.5))
		"mifan":
			for x in range(2, 14):
				img.set_pixel(x, 11, Color(0.4, 0.3, 0.25))
			for x in range(3, 13):
				for y in range(5, 10):
					img.set_pixel(x, y, Color(0.85, 0.7, 0.4))
		"xiaomi_zhou":
			for x in range(2, 14):
				img.set_pixel(x, 10, Color(0.6, 0.5, 0.4))
			for x in range(3, 13):
				for y in range(5, 10):
					img.set_pixel(x, y, Color(0.9, 0.85, 0.6))
		"medicine_bandage":
			for x in range(3, 13):
				for y in range(5, 11):
					img.set_pixel(x, y, Color(0.85, 0.65, 0.65))
			# 十字
			img.set_pixel(7, 7, Color.WHITE)
			img.set_pixel(8, 7, Color.WHITE)
			img.set_pixel(7, 8, Color.WHITE)
			img.set_pixel(8, 8, Color.WHITE)
		"medicine_cold":
			for x in range(4, 12):
				for y in range(3, 13):
					img.set_pixel(x, y, Color(0.5, 0.7, 0.9))
			img.set_pixel(8, 3, Color(0.4, 0.6, 0.8))
		"medicine_painkiller":
			for x in range(4, 12):
				for y in range(3, 13):
					img.set_pixel(x, y, Color(0.9, 0.5, 0.5))
		"phone":
			for x in range(5, 11):
				for y in range(2, 14):
					img.set_pixel(x, y, Color(0.1, 0.1, 0.15))
			# 屏幕
			for x in range(6, 10):
				for y in range(3, 11):
					img.set_pixel(x, y, Color(0.3, 0.5, 0.8))
		"id_card":
			for x in range(2, 14):
				for y in range(5, 11):
					img.set_pixel(x, y, Color(0.6, 0.7, 0.8))
			# 头像
			for x in range(4, 8):
				for y in range(6, 9):
					img.set_pixel(x, y, Color(0.8, 0.7, 0.6))
		"clothing_tshirt":
			for x in range(3, 13):
				for y in range(4, 13):
					img.set_pixel(x, y, Color(0.4, 0.55, 0.8))
			# 领
			img.set_pixel(7, 4, Color(0.3, 0.4, 0.6))
			img.set_pixel(8, 4, Color(0.3, 0.4, 0.6))
		"clothing_jeans":
			for x in range(3, 13):
				for y in range(2, 14):
					img.set_pixel(x, y, Color(0.25, 0.28, 0.4))
		"clothing_sneaker":
			for x in range(2, 14):
				for y in range(8, 12):
					img.set_pixel(x, y, Color(0.9, 0.9, 0.9))
			# 鞋带
			img.set_pixel(5, 7, Color(0.4, 0.4, 0.4))
			img.set_pixel(10, 7, Color(0.4, 0.4, 0.4))
		"clothing_cap":
			for x in range(3, 13):
				for y in range(4, 10):
					img.set_pixel(x, y, Color(1, 0.9, 0))
			# 帽檐
			for x in range(2, 14):
				img.set_pixel(x, 10, Color(0.8, 0.7, 0))
		"bed":
			for x in range(2, 14):
				for y in range(8, 12):
					img.set_pixel(x, y, Color(0.55, 0.4, 0.3))
			# 枕头
			for x in range(2, 6):
				for y in range(6, 9):
					img.set_pixel(x, y, Color(0.95, 0.9, 0.85))
		_:
			# 默认：方块
			for x in range(3, 13):
				for y in range(3, 13):
					img.set_pixel(x, y, Color(0.7, 0.7, 0.7))
	return ImageTexture.create_from_image(img)


# === Tile 16x16 ===

## 地面 tile（4 种变体）
static func make_ground_tile(variant: int) -> ImageTexture:
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var base: Color = Color(0.5, 0.45, 0.38)
	# 噪声
	for x in range(16):
		for y in range(16):
			var noise: float = sin(x * 0.7 + variant) * cos(y * 0.5 + variant * 0.3) * 0.05
			var c: Color = base + Color(noise, noise, noise)
			img.set_pixel(x, y, c)
	# 一些污渍
	for i in range(variant * 3 + 2):
		var sx: int = (i * 7 + variant * 5) % 16
		var sy: int = (i * 11 + variant * 3) % 16
		img.set_pixel(sx, sy, base.darkened(0.2))
	return ImageTexture.create_from_image(img)


## 墙 tile（顶部带深色）
static func make_wall_tile(variant: int) -> ImageTexture:
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var base: Color = Color(0.4, 0.35, 0.3) if variant % 2 == 0 else Color(0.45, 0.4, 0.33)
	img.fill(base)
	# 砖纹
	for y in range(0, 16, 4):
		for x in range(16):
			img.set_pixel(x, y, base.darkened(0.2))
	for x in range(0, 16, 8):
		for y in range(0, 16):
			img.set_pixel(x, y, base.darkened(0.2))
	return ImageTexture.create_from_image(img)


## 道路 tile
static func make_road_tile(variant: int) -> ImageTexture:
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var base: Color = Color(0.25, 0.25, 0.27)
	img.fill(base)
	# 中线（虚线）
	if variant % 2 == 0:
		for x in range(0, 16, 4):
			for y in range(7, 9):
				img.set_pixel(x, y, Color(1, 0.95, 0.3))
	# 边缘
	for x in range(16):
		img.set_pixel(x, 0, Color(0.4, 0.4, 0.42))
		img.set_pixel(x, 15, Color(0.4, 0.4, 0.42))
	return ImageTexture.create_from_image(img)


## 草地 tile
static func make_grass_tile(variant: int) -> ImageTexture:
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var base: Color = Color(0.3, 0.55, 0.25)
	img.fill(base)
	# 草叶
	for i in range(8 + variant * 2):
		var x: int = (i * 7 + variant * 3) % 16
		var y: int = (i * 5 + variant * 5) % 16
		img.set_pixel(x, y, base.lightened(0.15))
		img.set_pixel(x, y - 1, base.darkened(0.1))
	return ImageTexture.create_from_image(img)


## 室内地板（瓷砖）
static func make_floor_tile(variant: int) -> ImageTexture:
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var base: Color = Color(0.7, 0.65, 0.55)
	img.fill(base)
	# 拼缝
	for x in range(16):
		img.set_pixel(x, 8, base.darkened(0.3))
	for y in range(16):
		img.set_pixel(8, y, base.darkened(0.3))
	return ImageTexture.create_from_image(img)


# === UI 元素 ===

## 像素按钮（3 状态）
static func make_button_pixel(normal: Color, hover: Color, pressed: Color) -> Array[ImageTexture]:
	var arr: Array[ImageTexture] = []
	for c in [normal, hover, pressed]:
		var img: Image = Image.create(48, 16, false, Image.FORMAT_RGBA8)
		img.fill(c)
		# 边框
		for x in range(48):
			img.set_pixel(x, 0, c.darkened(0.3))
			img.set_pixel(x, 15, c.darkened(0.3))
		for y in range(16):
			img.set_pixel(0, y, c.darkened(0.3))
			img.set_pixel(47, y, c.darkened(0.3))
		arr.append(ImageTexture.create_from_image(img))
	return arr


## 问号/感叹号（头顶提示）
static func make_indicator(kind: String) -> ImageTexture:
	var img: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match kind:
		"!":
			img.set_pixel(3, 1, Color.YELLOW)
			img.set_pixel(4, 1, Color.YELLOW)
			img.set_pixel(3, 2, Color.YELLOW)
			img.set_pixel(4, 2, Color.YELLOW)
			img.set_pixel(3, 3, Color.YELLOW)
			img.set_pixel(4, 3, Color.YELLOW)
			img.set_pixel(3, 4, Color.YELLOW)
			img.set_pixel(4, 4, Color.YELLOW)
			img.set_pixel(3, 6, Color.YELLOW)
			img.set_pixel(4, 6, Color.YELLOW)
		"?":
			img.set_pixel(3, 1, Color.WHITE)
			img.set_pixel(4, 1, Color.WHITE)
			img.set_pixel(2, 2, Color.WHITE)
			img.set_pixel(5, 2, Color.WHITE)
			img.set_pixel(5, 3, Color.WHITE)
			img.set_pixel(5, 4, Color.WHITE)
			img.set_pixel(4, 5, Color.WHITE)
			img.set_pixel(4, 7, Color.WHITE)
		"new":
			img.set_pixel(1, 1, Color.RED)
			img.set_pixel(6, 1, Color.RED)
			img.set_pixel(2, 2, Color.RED)
			img.set_pixel(5, 2, Color.RED)
			img.set_pixel(3, 3, Color.RED)
			img.set_pixel(4, 3, Color.RED)
			img.set_pixel(2, 5, Color.RED)
			img.set_pixel(5, 5, Color.RED)
	return ImageTexture.create_from_image(img)


# === 场景物件 ===

## 长椅/桌/树/路灯（16x16 或 16x24）
static func make_furniture(kind: String) -> ImageTexture:
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match kind:
		"bench":
			# 椅面
			for x in range(1, 15):
				for y in range(8, 11):
					img.set_pixel(x, y, Color(0.45, 0.3, 0.2))
			# 椅腿
			for y in range(11, 15):
				img.set_pixel(2, y, Color(0.4, 0.28, 0.18))
				img.set_pixel(13, y, Color(0.4, 0.28, 0.18))
		"table":
			# 桌面
			for x in range(1, 15):
				for y in range(6, 9):
					img.set_pixel(x, y, Color(0.5, 0.35, 0.25))
			# 腿
			for y in range(9, 15):
				img.set_pixel(2, y, Color(0.45, 0.3, 0.2))
				img.set_pixel(13, y, Color(0.45, 0.3, 0.2))
		"tree":
			# 树冠
			for x in range(2, 14):
				for y in range(1, 12):
					img.set_pixel(x, y, Color(0.2, 0.5, 0.2))
			# 树干
			for y in range(11, 16):
				img.set_pixel(7, y, Color(0.4, 0.25, 0.15))
				img.set_pixel(8, y, Color(0.4, 0.25, 0.15))
		"lamp":
			# 灯柱
			for y in range(4, 16):
				img.set_pixel(7, y, Color(0.2, 0.2, 0.25))
				img.set_pixel(8, y, Color(0.2, 0.2, 0.25))
			# 灯
			img.set_pixel(6, 2, Color(0.2, 0.2, 0.25))
			img.set_pixel(9, 2, Color(0.2, 0.2, 0.25))
			img.set_pixel(7, 3, Color(0.2, 0.2, 0.25))
			img.set_pixel(8, 3, Color(0.2, 0.2, 0.25))
			for x in range(5, 11):
				img.set_pixel(x, 1, Color(0.2, 0.2, 0.25))
			# 灯光晕（黄）
			img.set_pixel(7, 2, Color.YELLOW)
			img.set_pixel(8, 2, Color.YELLOW)
		"trash":
			# 桶
			for x in range(4, 12):
				for y in range(4, 14):
					img.set_pixel(x, y, Color(0.3, 0.35, 0.3))
			# 边
			for y in range(3, 5):
				img.set_pixel(4, y, Color(0.25, 0.3, 0.25))
				img.set_pixel(11, y, Color(0.25, 0.3, 0.25))
		"sign":
			# 招牌
			for x in range(1, 15):
				for y in range(3, 11):
					img.set_pixel(x, y, Color(0.6, 0.5, 0.3))
			# 杆
			for y in range(11, 16):
				img.set_pixel(7, y, Color(0.3, 0.2, 0.15))
				img.set_pixel(8, y, Color(0.3, 0.2, 0.15))
	return ImageTexture.create_from_image(img)


# === 头像（48x48）===

static func make_portrait(face_id: String, expression: String = "normal") -> ImageTexture:
	var img: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.15, 0.1))
	# 简化：根据 face_id 选肤色
	var skin: Color = Color(0.95, 0.78, 0.65)
	var hair: Color = Color(0.15, 0.1, 0.05)
	match face_id:
		"wang_ayi":  # 50岁女性
			skin = Color(0.9, 0.72, 0.6)
			hair = Color(0.3, 0.25, 0.2)
		"li_ge":  # 35岁男性
			skin = Color(0.85, 0.65, 0.5)
			hair = Color(0.1, 0.08, 0.05)
		"xiao_mei":  # 22岁女性
			skin = Color(0.98, 0.85, 0.78)
			hair = Color(0.2, 0.15, 0.1)
	# 头
	for x in range(12, 36):
		for y in range(10, 38):
			img.set_pixel(x, y, skin)
	# 头发
	for x in range(10, 38):
		for y in range(8, 16):
			img.set_pixel(x, y, hair)
	# 表情
	match expression:
		"happy":
			# 笑眼
			img.set_pixel(17, 25, Color.BLACK)
			img.set_pixel(18, 25, Color.BLACK)
			img.set_pixel(29, 25, Color.BLACK)
			img.set_pixel(30, 25, Color.BLACK)
			# 嘴
			for x in range(20, 28):
				img.set_pixel(x, 30, Color(0.4, 0.2, 0.2))
		"sad":
			# 下眉
			img.set_pixel(17, 24, Color.BLACK)
			img.set_pixel(18, 25, Color.BLACK)
			img.set_pixel(29, 25, Color.BLACK)
			img.set_pixel(30, 24, Color.BLACK)
			# 嘴（向下）
			for x in range(20, 28):
				img.set_pixel(x, 32, Color(0.4, 0.2, 0.2))
		"angry":
			# 倒八眉
			img.set_pixel(15, 24, Color.BLACK)
			img.set_pixel(19, 26, Color.BLACK)
			img.set_pixel(27, 26, Color.BLACK)
			img.set_pixel(31, 24, Color.BLACK)
			img.set_pixel(17, 26, Color.BLACK)
			img.set_pixel(29, 26, Color.BLACK)
		"surprised":
			# 圆眼
			img.set_pixel(17, 24, Color.BLACK)
			img.set_pixel(18, 24, Color.BLACK)
			img.set_pixel(17, 26, Color.BLACK)
			img.set_pixel(18, 26, Color.BLACK)
			img.set_pixel(29, 24, Color.BLACK)
			img.set_pixel(30, 24, Color.BLACK)
			img.set_pixel(29, 26, Color.BLACK)
			img.set_pixel(30, 26, Color.BLACK)
			# O嘴
			img.set_pixel(23, 30, Color(0.4, 0.2, 0.2))
			img.set_pixel(24, 30, Color(0.4, 0.2, 0.2))
			img.set_pixel(23, 31, Color(0.4, 0.2, 0.2))
			img.set_pixel(24, 31, Color(0.4, 0.2, 0.2))
		_:
			# normal
			img.set_pixel(18, 25, Color.BLACK)
			img.set_pixel(30, 25, Color.BLACK)
			img.set_pixel(22, 30, Color(0.4, 0.2, 0.2))
			img.set_pixel(25, 30, Color(0.4, 0.2, 0.2))
	return ImageTexture.create_from_image(img)


## 头像数据：根据 NPC ID + 表情
static func portrait_for(npc_id: String, expression: String = "normal") -> ImageTexture:
	var face_id: String = String(npc_id).substr(4)  # 去掉 "npc_"
	return make_portrait(face_id, expression)
