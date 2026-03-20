# Repository Guidelines

## Project Structure & Module Organization
このリポジトリは `game/` と `admin/` の 2 つの作業領域で構成されます。`game/` は Godot 4.6.1 の本体で、シーンは `game/scenes/`、GDScript は `game/scripts/`、テストは `game/tests/`、画像やフォントなどの素材は `game/images/` と `game/fonts/` にあります。`admin/` は Next.js 16 のカード編集 UI で、画面とロジックは `admin/app/`、再利用コンポーネントは `admin/app/components/`、型定義は `admin/app/types.ts` にあります。設計メモや仕様は `docs/` を参照してください。

## Build, Test, and Development Commands
ゲーム開発では `godot --headless --path game --script res://tests/run_tests.gd` でテスト、`godot --headless --path game --check-only --script res://scripts/main.gd` で構文検証、`godot --headless --path game --export-release "Web" build/web/index.html` で Web ビルドを行います。ビルド後の確認は `cd game/build/web && python3 -m http.server 8080` を使います。管理画面は `cd admin && pnpm dev` で起動し、`pnpm build` で本番ビルド、`pnpm lint` で Biome 検査、`pnpm format` で整形します。

## Coding Style & Naming Conventions
`admin/` は TypeScript/React を 2 スペースで整形し、Biome の設定に従います。React コンポーネントは `PascalCase.tsx`、ユーティリティやアクションは用途ベースの名前を使ってください。カード ID や GDScript のシグナル名は `snake_case` を維持します。`game/` の GDScript はタブインデントを前提とし、ファイル名は `snake_case.gd`、ノード名は `PascalCase` を使います。

## Testing Guidelines
自動テストは現在 `game/tests/run_tests.gd` が中心です。ゲームロジックを変えたら headless テストを必ず実行し、必要ならケースを追加してください。`admin/` には専用テスト基盤がまだないため、少なくとも `pnpm lint` と `pnpm build` を通し、カード編集・プレビューの手動確認結果を PR に書いてください。

## Commit & Pull Request Guidelines
コミット履歴には `feat: ...`、`refactor: ...`、`docs: ...` と、日本語の簡潔な要約の両方があります。今後も 1 コミット 1 目的を守り、先頭に種別を付ける形式を推奨します。PR には変更概要、影響範囲（`game` / `admin` / `docs`）、実行した確認コマンド、UI 変更時のスクリーンショットを含めてください。

## Environment Notes
サンドボックスや権限制約下で Godot が書き込めない場合は、`XDG_DATA_HOME`、`XDG_CONFIG_HOME`、`XDG_CACHE_HOME` を `game/.tmp-godot-*` に向けてから実行してください。`admin/` では `pnpm` を標準にし、`node_modules/` や `.next/` は手編集しません。
