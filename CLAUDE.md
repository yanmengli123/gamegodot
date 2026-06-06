# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Godot 4.6 project located in `demo/`. Forward Plus renderer, Jolt Physics 3D, Direct3D 12 on Windows. The project is fresh — only the default `icon.svg` and engine-generated `project.godot` exist; no scenes, scripts, or assets have been added yet.

## Layout

- `demo/project.godot` — project entry point (config_version=5; name "demo"; Godot 4.6, Forward Plus)
- `demo/icon.svg` + `demo/icon.svg.import` — default app icon
- `demo/.godot/` — engine-generated import/shader/UID caches (gitignored)
- `demo/.gitignore` ignores `.godot/` and `/android/`
- `demo/.gitattributes` forces LF line endings
- `demo/.editorconfig` sets UTF-8

All new project content (scenes `.tscn`, scripts `.gd`/`.cs`, shaders, assets) goes under `demo/`.

## Common commands

Open the project in the Godot editor, then run it with F5 (or play the current scene with F6):

```bash
# Linux/macOS
godot --path demo

# Windows (if godot is on PATH; otherwise use the full path to godot.exe)
godot --path demo
```

Headless run (CI / smoke test from the command line):

```bash
godot --path demo --headless
```

Importing assets without opening the editor (useful after pulling):

```bash
godot --path demo --headless --import
```

There is no test runner, linter, build step, or package.json — Godot is the toolchain. Add tests via `gut`/`gdunit4`/etc. only when the project actually needs them.

## Notes for future work

- Use `extends Node` / `CharacterBody3D` / etc. and `class_name` for any new scripts; Godot 4.6 GDScript 2.0 syntax applies.
- New scenes are saved as `.tscn` under `demo/`. Reference them via `res://` paths.
- The renderer is set to Forward Plus and the Windows graphics driver is pinned to D3D12. Don't change the rendering section without confirming intent — changing `rendering_device/driver.windows` will break D3D12-only assumptions.
- Jolt is the active 3D physics engine. If physics-related code is added, prefer Jolt-compatible APIs.
