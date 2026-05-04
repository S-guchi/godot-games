# Tap Dungeon 8bit - ゲーム設計メモ

## コンセプト

仮想パッドなしで遊べる、8bit風のダンジョン探索RPG。

主人公はダンジョン内を自動で進む。
プレイヤーは、分岐・戦闘・宝箱・イベントなど、判断が必要な場面だけタップで操作する。

一言でいうと、

**移動はオート、判断だけタップ。**

---

## 基本体験

プレイヤーはキャラクターを細かく移動させない。

探索中は主人公が自動で通路を歩き、イベント地点で停止する。

停止する場面は以下。

- 分岐
- 敵
- 宝箱
- 罠
- 泉
- 階段
- ボス
- 重要イベント

プレイヤーは、その場面で表示された選択肢やボタンをタップして進行する。

---

## ゲームループ

```text
ゲーム開始
↓
主人公が自動で歩く
↓
イベント地点で停止
↓
プレイヤーがタップで判断
↓
イベント解決
↓
主人公が再び自動で歩く
↓
階段で次の階へ
↓
最深部のボスを倒してクリア
````

---

## 操作

| 状況           | 操作                               |
| -------------- | ---------------------------------- |
| オート探索中   | 操作なし                           |
| 分岐           | 行き先をタップ                     |
| 戦闘           | 攻撃ボタンをタップ                 |
| 宝箱           | レリックをタップ                   |
| イベント結果   | OKをタップ、または短時間で自動復帰 |
| ゲームオーバー | リトライをタップ                   |

---

## 探索

探索中、主人公は自動で歩く。

オート歩行中は以下を演出する。

* 歩行アニメ
* 足音SE
* 背景スクロール
* 松明の揺れ
* 通路の奥へ進んでいる演出
* 次イベントの予兆テキスト

イベント間隔は短めにする。

```text
イベント間隔：1.5〜4秒程度
```

長くても5秒以内に何かが起きるようにする。

---

## 予兆テキスト

イベントが起きる少し前に、気配を表示する。

例：

```text
前方から獣の匂いがする……
```

その後、敵イベントが発生する。

```text
スライムが現れた！
```

### 予兆例

| 予兆             | 起きやすいイベント |
| ---------------- | ------------------ |
| 獣の匂いがする   | 敵                 |
| 金属音が聞こえる | 宝箱 or 罠         |
| 水音がする       | 泉                 |
| 冷たい風が吹く   | 階段               |
| 床がきしむ       | 罠                 |
| 魔力を感じる     | 祠 or レア宝箱     |
| 重い足音が響く   | 強敵               |

予兆によって、プレイヤーが「何か起きそう」と感じられるようにする。

---

## 分岐

分岐では、主人公が停止し、2つの道を提示する。

```text
道が二手に分かれている。

左：水音がする
右：獣の匂いがする
```

プレイヤーは進みたい道をタップする。

```text
[ 左へ進む ] [ 右へ進む ]
```

選択後、選んだ道に応じたイベントが発生するか、オート探索に戻る。

### 分岐の目的

分岐は、このゲームの主要な判断ポイント。

プレイヤーは現在の状況を見て選ぶ。

例：

* HPが少ないので水音の道に進む
* レリックが欲しいので金属音の道に進む
* 早く階段を探したいので冷たい風の道に進む
* 強くなりたいので獣の匂いの道に進む

---

## 戦闘

敵に遭遇すると、主人公が停止して戦闘に入る。

```text
スライムが現れた！
```

戦闘はタップで進む。

```text
[ 攻撃 ]
```

### 戦闘処理

```text
攻撃ボタンをタップ
↓
主人公が攻撃
↓
敵HPを減らす
↓
敵が生きていれば反撃
↓
主人公HPを減らす
↓
敵を倒すまで繰り返す
```

### ダメージ計算

```text
プレイヤーダメージ = ATK + レリック補正
敵ダメージ = max(1, 敵ATK - DEF)
```

### 敵例

| 敵             |   HP |  ATK |    報酬 |
| -------------- | ---: | ---: | ------: |
| スライム       |    8 |    2 | コイン2 |
| コウモリ       |   10 |    3 | コイン3 |
| ゴブリン       |   13 |    4 | コイン4 |
| スケルトン     |   16 |    5 | コイン5 |
| ミノタウロス   |   22 |    7 | コイン8 |
| ダンジョンの王 |   60 |   12 |  クリア |

---

## 宝箱

宝箱を見つけると、主人公が停止する。

```text
宝箱を見つけた！
```

宝箱からはレリックを1つ獲得する。

```text
[ 吸血剣 ]
敵を倒すたびHPを2回復

[ 探索者の地図 ]
分岐の気配が詳しくなる

[ 厚いマント ]
罠ダメージ-3
```

レリック選択後、オート探索に戻る。

---

## 罠

罠を踏むとダメージを受ける。

```text
罠を踏んだ！
HP -6
```

罠は基本的には悪いイベント。
ただし、レリックによって価値が変わる。

例：

| レリック   | 効果                               |
| ---------- | ---------------------------------- |
| 罠師の靴   | 罠を踏むとATK+1                    |
| 厚いマント | 罠ダメージ-3                       |
| 復讐の針   | 罠を踏んだ後、次の敵に追加ダメージ |

---

## 泉

泉を見つけるとHPを回復する。

```text
回復の泉を見つけた。
HP +10
```

レリックによって回復量を増やせる。

| レリック | 効果                 |
| -------- | -------------------- |
| 泉の杯   | 泉の回復量+5         |
| 聖水瓶   | 泉を使うたび最大HP+1 |

---

## 階段

階段を見つけると次の階へ進む。

```text
階段を見つけた。
B2Fへ降りた。
```

最初はB5Fのボス撃破をクリア条件にする。

```text
B1F → B2F → B3F → B4F → B5F → ボス
```

---

## プレイヤーステータス

| ステータス | 内容                    |
| ---------- | ----------------------- |
| HP         | 0になるとゲームオーバー |
| Max HP     | 最大HP                  |
| ATK        | 攻撃力                  |
| DEF        | 防御力                  |
| Gold       | コイン                  |
| Key        | 鍵                      |
| Relics     | 所持レリック            |
| Floor      | 現在階層                |

初期値案：

```text
HP: 22
Max HP: 22
ATK: 4
DEF: 0
Gold: 0
Key: 0
Floor: 1
```

---

## レリック

レリックはローグライト性の中心。

単なる数値アップだけではなく、イベントの価値が変わるものを優先する。

### レリック例

| レリック     | 効果                           |
| ------------ | ------------------------------ |
| 吸血剣       | 敵を倒すたびHPを2回復          |
| 探索者の地図 | 分岐の気配が詳しくなる         |
| 盗賊の鍵     | 宝箱を開けるたびコイン+5、鍵+1 |
| 罠師の靴     | 罠を踏むとATK+1                |
| 臆病者の盾   | 階段を降りるたびDEF+1          |
| 呪いの王冠   | HPが半分以下ならATK+4          |
| 泉の杯       | 泉の回復量+5                   |
| 黄金の短剣   | 所持コイン10枚ごとにATK+1      |
| 厚いマント   | 罠ダメージ-3                   |
| 生命の指輪   | 最大HP+6                       |

---

## ゲームモード

内部状態として以下を持つ。

```text
AUTO_WALK
BRANCH
BATTLE
REWARD
EVENT_RESULT
GAME_OVER
CLEAR
```

### AUTO_WALK

主人公が自動で歩いている状態。
一定時間または一定距離ごとにイベントが発生する。

### BRANCH

分岐選択中。
プレイヤーが行き先を選ぶ。

### BATTLE

戦闘中。
攻撃ボタンをタップして敵と戦う。

### REWARD

レリック選択中。

### EVENT_RESULT

罠、泉、階段などの結果表示中。
OKタップ、または短時間後にAUTO_WALKへ戻る。

### GAME_OVER

HPが0になった状態。

### CLEAR

ボス撃破状態。

---

## Godot実装イメージ

### シーン構成

```text
res://
  scenes/
    Main.tscn
    ui/
      Hud.tscn
      MessagePanel.tscn
      ChoiceButton.tscn
      RewardPanel.tscn
    dungeon/
      DungeonView.tscn
      PlayerSprite.tscn
      EnemySprite.tscn
  scripts/
    Main.gd
    GameState.gd
    EventManager.gd
    BattleManager.gd
    RelicManager.gd
    DungeonView.gd
  data/
    enemies.gd
    relics.gd
    events.gd
  assets/
    sprites/
    sfx/
    fonts/
```

### Main.tscn

```text
Main
├── DungeonView
│   ├── Background
│   ├── PlayerSprite
│   └── EnemySprite
├── Hud
├── MessagePanel
├── RewardPanel
└── AudioManager
```

---

## AUTO_WALK実装イメージ

```gdscript
enum GameMode {
    AUTO_WALK,
    BRANCH,
    BATTLE,
    REWARD,
    EVENT_RESULT,
    GAME_OVER,
    CLEAR
}

var mode: GameMode = GameMode.AUTO_WALK

var event_timer: float = 0.0
var event_interval_min: float = 1.5
var event_interval_max: float = 4.0

func _ready():
    start_auto_walk()

func _process(delta):
    match mode:
        GameMode.AUTO_WALK:
            update_auto_walk(delta)

func start_auto_walk():
    mode = GameMode.AUTO_WALK
    event_timer = randf_range(event_interval_min, event_interval_max)
    dungeon_view.play_walk()
    message_panel.show_text("ダンジョンを進んでいる...")

func update_auto_walk(delta):
    event_timer -= delta
    dungeon_view.scroll_path(delta)

    if event_timer <= 1.2:
        show_next_event_hint()

    if event_timer <= 0:
        trigger_event()
```

---

## イベント発生処理

```gdscript
func trigger_event():
    dungeon_view.stop_walk()

    var event = event_manager.roll_event(player_state.floor)

    match event.type:
        "enemy":
            start_battle(event.enemy)
        "branch":
            show_branch(event.choices)
        "chest":
            show_chest()
        "trap":
            trigger_trap()
        "fountain":
            trigger_fountain()
        "stairs":
            descend_stairs()
```

---

## イベント解決後

```gdscript
func finish_event():
    if player_state.hp <= 0:
        game_over()
        return

    start_auto_walk()
```

---

## MVPで作るもの

### 必須

* オート歩行
* イベント発生
* 予兆テキスト
* 分岐2択
* 敵戦闘
* 宝箱レリック3択
* 罠
* 泉
* 階段
* B5Fボス
* ゲームオーバー
* クリア

### 後回し

* 本格的な自動生成マップ
* 装備
* スキル
* アイテム使用
* 店
* 複数キャラ
* セーブ
* 状態異常
* 長押し操作

---

## 体験のゴール

このゲームで確認したいことは以下。

1. 移動がオートでもダンジョンを探索している感じがあるか
2. 分岐で小さな判断が生まれるか
3. 戦闘がタップだけで気持ちいいか
4. レリックで次の判断が変わるか
5. 1プレイが軽く、もう一度遊びたくなるか

---

## 一言説明

**移動はオート、判断だけタップ。**

仮想パッドなしで、8bitダンジョンRPGの探索感を楽しむローグライト。

