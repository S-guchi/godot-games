# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwipeQuest is a Reigns-style card swipe text adventure game. Players swipe left/right on cards to manage 3 stats (mind/body/money) within a day limit while pursuing a goal. The repo has two workspaces: `game/` (Godot 4.6.1 game) and `admin/` (Next.js 16 card editor UI).

## Build & Development Commands

### Game (Godot 4.6.1 / GDScript)

```bash
# Run tests
godot --headless --path game --script res://tests/run_tests.gd

# Syntax check a script
godot --headless --path game --check-only --script res://scripts/main.gd

# Web export
godot --headless --path game --export-release "Web" build/web/index.html

# Local preview
cd game/build/web && python3 -m http.server 8080
```

If Godot can't write to its data dirs (sandbox), set:
```bash
export XDG_DATA_HOME=game/.tmp-godot-data
export XDG_CONFIG_HOME=game/.tmp-godot-config
export XDG_CACHE_HOME=game/.tmp-godot-cache
```

### Admin (Next.js 16 / pnpm)

```bash
cd admin
pnpm dev          # Dev server at localhost:3000
pnpm build        # Production build
pnpm lint         # Biome check
pnpm format       # Biome format --write
```

## Architecture

### game/ — Godot game (GL Compatibility renderer, 480×854 portrait)

The entire UI is built programmatically in GDScript (no editor-designed scenes). `main.gd` constructs all nodes in `_build_scene()` and manages screen transitions (title → game → game over/victory). `game_manager.gd` owns all game state: stats, flags, context tags (with decay), deck mode, card history, and story progress. `card_data.gd` handles card definitions and selection logic. `card_ui.gd` implements swipe interaction. `stat_bar.gd` renders the 3-stat + days display. `effect_popup.gd` shows stat change feedback.

Card data lives in `game/data/` as JSON files (`cards.json`, `cards_v2.json`).

Key signals: `stats_changed`, `card_resolved`, `game_over_triggered` — all emitted by `game_manager.gd` and connected in `main.gd`.

### admin/ — Card editor (Next.js 16 App Router + Tailwind 4 + Biome)

Single-page card editing tool. `app/page.tsx` is the main page with card list + editor layout. Components: `CardList`, `CardEditor`, `CardPreview`, `EffectsEditor`, `ConditionsEditor`. Types in `app/types.ts`. Server actions in `app/actions.ts`. Sample card data in `admin/sample_cards.json`.

### docs/ — Design documents

Game design doc (`swipequest_game_design_v0_3.md`) and algorithm design docs define the card selection algorithm, stat balance rules, and context/flag system.

## Conventions

- **GDScript**: tab indent, `snake_case` files/signals, `PascalCase` nodes
- **TypeScript/React**: 2-space indent (Biome), `PascalCase.tsx` for components
- **Card IDs**: `snake_case`
- **Commits**: `feat:` / `refactor:` / `docs:` prefix with concise Japanese summary
- **No test infra for admin yet** — run `pnpm lint` + `pnpm build` and note manual verification in PRs
