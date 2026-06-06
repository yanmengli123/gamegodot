## pixel_rain.gd
## 程序化雨滴粒子效果
## 用 CPUParticles2D + GradientTexture2D 程序化生成
extends CPUParticles2D


func _ready() -> void:
	# 雨滴颜色
	color = Color(0.55, 0.7, 0.95, 0.7)
	# 形状：一条短斜线
	var tex: ImageTexture = _make_raindrop_texture()
	texture = tex
	# 发射参数
	emission_shape = EmissionShape.EMISSION_SHAPE_RECTANGLE
	emission_rect = Rect2(-640, -100, 1280, 50)
	direction = Vector2(0.2, 1).normalized()
	spread = 8.0
	gravity = Vector2(0, 400)
	initial_velocity_min = 350
	initial_velocity_max = 450
	scale_amount_min = 0.6
	scale_amount_max = 1.0
	amount = 200
	lifetime = 1.2
	preprocess = 0.5
	fixed_fps = 30
	emitting = true


func _make_raindrop_texture() -> ImageTexture:
	# 16×1 像素的细线，旋转 75° 在视感上是斜雨
	var img: Image = Image.create(16, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 16 像素全亮
	for x in range(16):
		img.set_pixel(x, 0, Color(0.55, 0.7, 0.95, 1.0))
	return ImageTexture.create_from_image(img)


func set_intensity(level: int) -> void:
	## level: 0=sun, 1=cloudy, 2=light_rain, 3=heavy_rain, 4=storm
	match level:
		2: amount = 100
		3: amount = 250
		4: amount = 400
		_: amount = 0
		emitting = amount > 0
