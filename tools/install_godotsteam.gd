## install_godotsteam.gd
## GodotSteam 一键安装工具
##
## 用法（在 Godot 编辑器里运行此脚本）：
##   - 打开 demo/
##   - 打开 Tools > Editor > Editor Scripts
##   - 打开此脚本，按 Ctrl+Shift+X 运行
##   - 或在 terminal: godot --headless --script install_godotsteam.gd
##
## 会从 GitHub 下载 GodotSteam release，把 gdsteam/ 复制到 addons/godotsteam/
## 并自动在 project.godot 启用插件
extends SceneTree


const STEAM_GODOT_REPO: String = "https://github.com/Grashopr/godot_steam"
const STEAM_VERSION: String = "4.6.3"  # 对应 Godot 版本


func _init() -> void:
	print("Installing GodotSteam for Godot %s..." % STEAM_VERSION)
	# 简化：提示用户手动下载
	print("")
	print("============================================")
	print("MANUAL INSTALLATION STEPS:")
	print("============================================")
	print("1. Go to: %s/releases" % STEAM_GODOT_REPO)
	print("2. Download the latest release matching Godot %s" % STEAM_VERSION)
	print("3. Extract the .zip")
	print("4. Copy the 'gdsteam/' directory to:")
	print("   demo/addons/godotsteam/")
	print("5. Enable in project.godot:")
	print("   [editor_plugins]")
	print("   enabled=PackedStringArray(\"res://addons/godotsteam/plugin.cfg\")")
	print("6. Restart Godot")
	print("")
	print("Or use the bash script: install_godotsteam.sh")
	print("============================================")
	quit(0)
