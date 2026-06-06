## asset_importer.gd
## 真实像素美术导入工具 — 从 KENNEY.nl / OpenGameArt 下载并配置
##
## 用法（在 Godot 编辑器脚本里运行）：
##   godot --headless --script tools/asset_importer.gd
##
## 真实集成步骤：
##   1. 访问 https://kenney.nl/assets 或 https://opengameart.org/
##   2. 下载 .zip
##   3. 解压到 demo/assets/imported/
##   4. 重新打开 Godot，import 自动跑
##   5. 修改 PlaceholderTexture 的引用从程序化改为 load("res://assets/imported/...")
##
## 本文件提供配置说明 + URL 列表
extends SceneTree

const _Self := preload("res://tools/asset_importer.gd")


# === 推荐资源 ===
# KENNEY（CC0）
const RECOMMENDED_ASSETS := [
	{
		"url": "https://kenney.nl/assets/tiny-town",
		"name": "Tiny Town",
		"size": "16x16 像素",
		"license": "CC0",
		"dest": "res://assets/imported/kenney/tiny-town/",
	},
	{
		"url": "https://kenney.nl/assets/tiny-town-redux",
		"name": "Tiny Town Redux",
		"size": "16x16 像素",
		"license": "CC0",
		"dest": "res://assets/imported/kenney/tiny-town-redux/",
	},
	{
		"url": "https://kenney.nl/assets/topdown-tanks-redux",
		"name": "Topdown Tanks Redux",
		"size": "16x16 像素",
		"license": "CC0",
		"dest": "res://assets/imported/kenney/topdown-tanks/",
	},
	{
		"url": "https://kenney.nl/assets/topdown-shooter",
		"name": "Topdown Shooter",
		"size": "16x16 像素",
		"license": "CC0",
		"dest": "res://assets/imported/kenney/topdown-shooter/",
	},
	{
		"url": "https://kenney.nl/assets/character-animations",
		"name": "Character Animations",
		"size": "16x24 像素",
		"license": "CC0",
		"dest": "res://assets/imported/kenney/character-animations/",
	},
	{
		"url": "https://kenney.nl/assets/interface-sounds",
		"name": "Interface Sounds",
		"size": "UI 音效包",
		"license": "CC0",
		"dest": "res://assets/imported/kenney/interface-sounds/",
	},
	{
		"url": "https://kenney.nl/assets/digital-audio",
		"name": "Digital Audio (BGM)",
		"size": "8-bit BGM 循环",
		"license": "CC0",
		"dest": "res://assets/imported/kenney/digital-audio/",
	},
	# OpenGameArt
	{
		"url": "https://opengameart.org/content/16x16-tile-sets",
		"name": "16x16 Tile Sets",
		"size": "16x16 像素",
		"license": "CC-BY 3.0",
		"dest": "res://assets/imported/opengameart/tilesets/",
	},
	{
		"url": "https://opengameart.org/content/animated-top-down-character",
		"name": "Animated Top-Down Character",
		"size": "16x24 像素",
		"license": "CC-BY 3.0",
		"dest": "res://assets/imported/opengameart/character/",
	},
]


func _init() -> void:
	print("\n=== 真实像素美术导入指南 ===\n")
	print("要将占位图替换为真实美术资源，请按以下步骤操作：\n")
	print("推荐资源（按场景）：")
	print("=" * 50)
	for a in RECOMMENDED_ASSETS:
		print("[%s] %s" % [a.license, a.name])
		print("  URL: %s" % a.url)
		print("  像素: %s" % a.size)
		print("  解压到: %s" % a.dest)
		print("  说明: 下载后解包至 res://assets/imported/...")
		print("")
	print("=" * 50)
	print("\n下载后操作：")
	print("1. 解压 .zip 到 demo/assets/imported/<source>/")
	print("2. 重启 Godot 编辑器（自动 import）")
	print("3. 修改 core/utils/pixel_artist.gd 把 _draw_man() 改为 load(\"res://assets/.../player.png\")")
	print("4. 修改 core/utils/tilemap_builder.gd 加载真实 tileset 资源")
	print("5. 替换 core/utils/procedural_audio.gd 为真实 BGM 文件")
	quit(0)
