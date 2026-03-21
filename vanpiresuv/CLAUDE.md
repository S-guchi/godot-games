# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Vanpiresuv is a top-down physics-based bullet hell survivor game (Vampire Survivors x Physics). Enemies are RigidBody2D nodes that physically push each other, and player bullets apply impulse knockback for satisfying physics interactions. Built with Godot 4.6.1, GL Compatibility renderer.

## Build & Development Commands

### Game (Godot 4.6.1 / GDScript)

```bash
# Run tests
godot --headless --path vanpiresuv --script res://tests/run_tests.gd

# Syntax check a script
godot --headless --path vanpiresuv --check-only --script res://player.gd

# Run the game
godot --path vanpiresuv
```

If Godot can't write to its data dirs (sandbox), set:
```bash
export XDG_DATA_HOME=vanpiresuv/.tmp-godot-data
export XDG_CONFIG_HOME=vanpiresuv/.tmp-godot-config
export XDG_CACHE_HOME=vanpiresuv/.tmp-godot-cache
```

## Architecture

### Scene Structure (854x480 landscape)

- `world.tscn` (Node2D) - Main scene with enemy spawner
  - `player.tscn` (CharacterBody2D) - WASD movement, mouse aim, auto-fire bullets, Camera2D
  - Enemies spawned at runtime as `enemy.tscn` (RigidBody2D) - physics-based movement, push each other
  - Bullets spawned at runtime as `bullet.tscn` (Area2D) - applies impulse knockback to enemies

### Collision Layers

| Layer | Bit | Used By |
|-------|-----|---------|
| 1     | 1   | Player  |
| 2     | 2   | Bullets |
| 3     | 4   | Enemies |

### Key Scripts

- `input_setup.gd` - Autoload: registers WASD/arrow input actions
- `player.gd` - Movement, aiming, bullet firing
- `enemy.gd` - Chase player via linear_velocity.lerp, take_damage/die
- `bullet.gd` - Forward movement, impulse knockback on enemy hit
- `world.gd` - Enemy spawner on timer

### Physics Design

- Enemies (RigidBody2D): `gravity_scale=0`, `lock_rotation=true`, `linear_damp=3.0`
- Knockback: `apply_central_impulse(dir * 500)` from bullets
- Enemy chase: `linear_velocity.lerp(dir * 80, 0.03)` - low lerp weight for knockback feel

## Conventions

- **GDScript**: tab indent, `snake_case` files/signals, `PascalCase` nodes
- **Commits**: `feat:` / `refactor:` / `docs:` prefix with concise Japanese summary
