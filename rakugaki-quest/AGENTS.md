# Repository Guidelines

## Build, Test, and Development Commands
`godot --headless --path vanpiresuv --script res://tests/run_tests.gd` でテスト、`godot --headless --path vanpiresuv --check-only --script res://player.gd` で構文検証を行います。ゲーム起動は `godot --path vanpiresuv` です。

## Coding Style & Naming Conventions
GDScript はタブインデント、ファイル名は `snake_case.gd`、ノード名は `PascalCase` を使います。

## Testing Guidelines
ゲームロジックを変えたら headless テストを必ず実行し、必要ならケースを追加してください。

## Commit & Pull Request Guidelines
コミット履歴には `feat: ...`、`refactor: ...`、`docs: ...` と、日本語の簡潔な要約の両方があります。

## Environment Notes
サンドボックスや権限制約下で Godot が書き込めない場合は、`XDG_DATA_HOME`、`XDG_CONFIG_HOME`、`XDG_CACHE_HOME` を `.tmp-godot-*` に向けてから実行してください。
