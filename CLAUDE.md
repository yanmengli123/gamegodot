# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**《命运齿轮》 (Fate Gear)** — a 2D pixel-art life-simulation / narrative game built in Godot 4.6.3. The player arrives in the fictional city of 锦城 with ¥500 and must survive 90 in-game days through work, relationships, and choices that lead to 12 different endings.

Engine constraints (do not change without confirming intent):
- Renderer: **Forward Plus**, Windows driver pinned to **D3D12** (`rendering_device/driver.windows="d3d12"`)
- 3D physics: **Jolt** (`3d/physics_engine="Jolt Physics"`)
- Display: 640×360 viewport, canvas_items stretch, `texture_filter=Nearest`, `2d/snap/*=true` (pixel-perfect)
- All content under `demo/` — Godot is the toolchain (no npm / cargo / Makefile)

## Quick start

```bash
# Smoke test the engine (path is whichever way godot is on Windows)
"D:/Godot_v4.6.3-stable_win64.exe" --path demo --quit-after 60

# Run the full unit test suite
# 1) Temporarily add to project.godot [autoload]:
#      Tests="*res://core/tests/test_runner.gd"
#      TestsExt="*res://core/tests/test_runner_extended.gd"
# 2) Run the godot binary (no --quit-after) — autoloads call get_tree().quit()
"D:/Godot_v4.6.3-stable_win64.exe" --path demo
# Expected: "总结果: 19 通过, 0 失败" + "总结果: 33 通过, 0 失败" then exit 0

# Re-import after pulling new assets
"D:/Godot_v4.6.3-stable_win64.exe" --path demo --headless --import
```

## Big-picture architecture

The game is a **data-driven, event-bus architecture** with 20 production autoloads (22 including tests). The core pattern across all systems:

1. **State lives in `Player` / `TimeMgr` autoloads** (single source of truth)
2. **Setters on autoloads emit signals on `EventBus`** (decouples systems)
3. **Resource (.tres) files hold static data** (NPCs, items, jobs, events, dialogues, status effects, accommodations, scenes)
4. **Factories in `core/utils/*_factory.gd` construct resources at runtime** (avoids typed-array serialization pitfalls; replace with .tres scans when stable)

### Autoload cheatsheet (all in `demo/core/autoload/`)

| Name | Purpose | Key API |
|---|---|---|
| `Game` | state machine, save/load | `Game.current_state`, `Game.save_game(0)` |
| `TimeMgr` | game clock, day/week/month/year | `TimeMgr.hour`, `TimeMgr.skip_hours(8)` |
| `Player` | all player state + inventory | `Player.cash`, `Player.add_item(id, qty)` |
| `EventBus` | 30+ cross-system signals | `EventBus.money_changed.connect(...)` |
| `Dialogue` | dialogue engine | `Dialogue.start_dialogue(&"dlg_id", &"npc_id")` |
| `Scenes` | scene switching with fade | `Scenes.change_scene(&"train_station")` |
| `Economy` | shop, bank, loan, daily expenses | `Economy.buy_from_shop(...)` |
| `Work` | job accept/execute/pay | `Work.accept_job("job_brick")` |
| `StatusMgr` | status effects (mutex + tick) | `StatusMgr.add_effect("cold", "test", 24.0)` |
| `Accommodation` | 9 housing tiers + daily rent | `Accommodation.set_accommodation("rental")` |
| `WeatherManager` | 8 weather types, seasonal weights | `WeatherManager.cancels_outdoor_work()` |
| `Events` | 20 random events + flag-based triggers | `Events.trigger("ev_robbed")` |
| `Notifications` | 5-category notification queue | `EventBus.notification_requested.emit(2, "...")` |
| `Audio` | BGM crossfade + SFX pool | `Audio.play_bgm("jincheng")`, `Audio.play_sfx("coin")` |
| `TileMapInit` | generates `data/tilesets/world_tileset.tres` on first run | — |
| `Story` | 4-chapter main story trigger | `Story.start_prologue()` |
| `Endings` | 12 endings, evaluates flag/数值 combos | `Endings.evaluate_ending()` |
| `Locale` | zh-CN / en i18n | `Locale.translate("item.food_doujiang")` |
| `Steam` | Steamworks + Workshop + P2P (mock) | `Steam.unlock_achievement(id)` |
| `DLC` | 5 default DLCs, register/enable API | `DLC.enable_demo("dlc_night_city")` |
| `Network` | ENet multiplayer stub | `Network.host_game("Room", 7777)` |

### Conventions

- **Class names**: PascalCase (`Player`, `NPCData`, `ItemFactory`)
- **Files**: snake_case (`player_data.gd`, `item_factory.gd`)
- **Signals**: past tense (`money_changed`, `day_started`, `dialogue_ended`)
- **Public API**: type-annotated everywhere; `@onready` for node refs (no `find_node` in `_process`)
- **Tween/Dialogue use**: `Game.current_state` must be `EXPLORING` to allow player movement
- **Resource data**: prefer runtime factory (`Factory.create_all()`) over typed-array `.tres` (latter has Godot 4.6 serialization edge cases)

### Directory layout

```
demo/
├── project.godot          # all 20 autoloads declared here
├── core/
│   ├── autoload/          # 20 singletons
│   ├── resources/         # 9 Resource classes (NPCData, ItemData, ...)
│   ├── tests/             # test_runner.gd (19) + test_runner_extended.gd (33)
│   └── utils/             # pixel_artist, procedural_audio, condition_parser, factories
├── data/
│   ├── dialogues/         # 47 .tres dialogue files
│   ├── npcs/              # NPCData .tres (empty in 1.x, use factories)
│   └── tilesets/          # world_tileset.tres (auto-generated)
├── scenes/
│   ├── main/Main.tscn     # main scene, 5 layer structure
│   ├── player/            # Player.tscn + game_camera.gd
│   ├── npc/               # NPC.tscn + npc.gd
│   ├── dialogue/          # DialogueUI.tscn + dialogue_ui.gd
│   ├── world/             # world scenes (train_station, old_town_street, ...)
│   ├── ui/                # HUD, MainMenu, SaveLoadUI, ShopUI, InventoryUI, PhoneUI, TouchControls
│   └── effects/           # PixelRain, EffectsLayer
├── addons/godotsteam/     # GodotSteam SDK stub (real install via tools/install_godotsteam.sh)
├── tools/                  # asset_importer.gd, install_godotsteam.{sh,ps1,gd}
└── build/web/             # PWA manifest + service worker + web export target

.github/workflows/ci.yml  # 4 jobs: test / lint / build / artifact
```

### Common gotchas (real bugs hit during development)

1. **`Time` is a Godot built-in class** — never use as autoload name (use `TimeMgr`)
2. **`get()` shadows `Object.get()`** — use `get_accommodation()` etc.
3. **Typed `Array[Dictionary]` doesn't accept untyped Array** — when deserializing from JSON, build a new typed array via loop
4. **`-1` as enum default fails in Godot 4.6** — use `Variant = null` sentinel
5. **`class_name` globals require `godot --headless --import` first run** to populate `global_script_class_cache.cfg`; missing class_name gives "Identifier not found"
6. **Chain assignment like `min_x = max_x = mid_x` is invalid in 4.6** — split into 2 lines
7. **autoloads can't be added during `add_child()` busy state** — wrap UI setup in `call_deferred("_build_ui")`
8. **Typed Array in .tres as const** — use `var` not `const` for resources containing typed arrays of Dictionary

### Testing approach

Tests run as **autoloads that call `get_tree().quit(0)` on success**. The pattern:
1. Add `Tests` and `TestsExt` to `[autoload]` in `project.godot`
2. Run godot binary without `--quit-after`
3. Each test prints `[PASS]` / `[FAIL]` and returns 0/1
4. **Remove from autoload when done** (otherwise game auto-quits on startup)

CI runs the same pattern in `.github/workflows/ci.yml`.

### When extending the game

- **New item**: add to `ItemFactory.create_all()`, set icon_color for placeholder
- **New NPC**: add to `NPCFactory.create_all()` with schedules
- **New dialogue**: save as `.tres` in `data/dialogues/`, use Dialogue.start_dialogue(&"id", &"npc")
- **New event**: add to `EventFactory.create_all()` with conditions dict
- **New scene**: add to `SceneData.create_all()` + create `.tscn` + add Exit area
- **New ending**: add to `Endings.ENDINGS` array

### Asset replacement path

The game ships with **procedural placeholders** for art/audio:
- `core/utils/pixel_artist.gd` generates all sprites
- `core/utils/procedural_audio.gd` synthesizes BGM/SFX
- `core/utils/tilemap_builder.gd` creates `world_tileset.tres`

To swap to real assets: drop files into `demo/assets/imported/<source>/` (see `tools/asset_importer.gd` for KENNEY/OpenGameArt recommendations) and modify the factories to `load("res://assets/imported/...")`.

### Notes on future work

- Renderer section in `project.godot` is **do not touch** — D3D12 + Forward Plus is the only tested path
- Jolt is the 3D physics backend; we don't use 3D physics, but don't disable it (config inheritance)
- Real GodotSteam integration: `bash tools/install_godotsteam.sh` then enable plugin in editor
- DLC/Network/Steam are **mocks** — replace method bodies with real `Steam.*` calls when SDK is installed
