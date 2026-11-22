# 号数と送料（canvas-size-shipping）

画家のための、キャンバスの号数と発送の大きさのリファレンス。
寸法を入れると号数を逆に引き、梱包後の3辺合計から三社のサイズ区分と運賃を並べる。

- Bundle ID: `com.shodai4.canvassizeshipping`
- 表示名: 号数と送料
- 対応: iPhone / iOS 17.0 以上 / 縦向き
- 依存: Google Mobile Ads 13.x（Swift Package）

## できること

- 号数の一覧: F・P・M・S の 0〜100 号とサムホール（SM）の全 77 件
- 逆引き: 長辺・短辺（ミリ）を入れると、全号数から `√(Δ長辺² + Δ短辺²)` が
  最小のものを選び、近い候補を4件まで並べる。長辺と短辺を入れ替えても同じ結果になる
- 比率プレビュー: 選択中の号数の枠と黄金比（1 : 1.618）の枠を重ね、差を数値で出す
- 梱包: 余裕（既定 50 ミリ）と厚み（既定 30 ミリ）、額装の有無。
  額装では長辺・短辺に +30 ミリ、厚みに +20 ミリ
- 送料: 梱包後の3辺合計（センチ、切り上げ）から、ヤマト運輸（60〜200）・
  ゆうパック（60〜170）・佐川急便（60〜260）の区分と運賃
- 着地: 関西（大阪）発で、関西・中部北陸・関東信越・九州・北海道の5区分
- 大型便の案内: 170 / 200 / 260 を超えたときに、赤字で次の手を示す
- お気に入りと作品メモ: 端末の中（UserDefaults）だけに保存

## 画面の作り

```
VStack
 ├ ScrollView
 │   ├ 入力        長辺・短辺（ミリ）。入れると逆引きが走り、近い号数を一覧
 │   ├ 選択中の号数  号数（明朝）・実寸（等幅）・比率の枠・お気に入り・メモ
 │   └ 梱包と送料    3辺合計（等幅で大きく）・額装・着地・三社の運賃
 └ 広告           最下部の独立した帯（Pro 購入後は消える）
```

色はアイボリー `#F9F8F5`、文字は墨 `#1A1A1B`、合図だけ錆青 `#4A6A7A`。
罫線は墨の 10%。寸法・3辺合計・金額は `.monospaced`。絵文字・英字の補足・
原色のボタンは使わない。

## 中の構成

| 場所 | 役割 |
| --- | --- |
| `Sources/Models/CanvasSize.swift` | 号数の表（日本サイズ 77 件） |
| `Sources/Models/ReverseLookup.swift` | 寸法から号数を逆引きする距離計算 |
| `Sources/Models/PackingSpec.swift` | 余裕・厚み・額装と、3辺合計の切り上げ |
| `Sources/Models/ShippingRateData.swift` | 三社のサイズ区分と運賃表（差し替え可能な Codable） |
| `Sources/Models/ShippingEstimate.swift` | 区分の判定、運賃、大型便の案内 |
| `Sources/Store/ProStore.swift` | StoreKit 2 の買い切り（`com.shodai4.canvassizeshipping.pro`） |
| `Sources/Store/LibraryStore.swift` | お気に入りと作品メモ |
| `Sources/Views/` | 画面。比率の枠は `SwiftUI.Canvas` |
| `scripts/verify-logic.py` | データと計算の自己点検（CI の `test` ジョブ） |
| `scripts/check-syntax.py` | Swift の構文点検（tree-sitter） |
| `scripts/generate_icon.py` | アイコン（1024×1024、RGB） |
| `scripts/ci-testflight.sh` | アーカイブ → 仮署名 → 書き出し → TestFlight |

## 数値の出どころ

号数の寸法は、全日本画材協議会の支持体サイズ表を軸に、笹部洋画材料店、ゆめ画材、
世界堂の一覧と突き合わせた日本サイズ。長辺が縦、短辺が横にあたる。P0 と M0 は
一部の一覧に載らないが、画材店の呼び寸法として存在するため収録した。

運賃は関西発・税込・現金決済の基本運賃で、2026年11月時点の各社公表値。

| 社 | 出どころ | 上限 |
| --- | --- | --- |
| ヤマト運輸 | 2025年10月1日改定の宅急便運賃 | 3辺200cm・30kg、1辺170cm |
| ゆうパック | 2026年10月1日改定の基本運賃 | 3辺170cm・25kg |
| 佐川急便 | 関西発の料金表（飛脚宅配便・飛脚ラージサイズ宅配便） | 3辺260cm・50kg |

割引・契約運賃・離島の中継料は含まない。着地は5区分にまとめているため、
同じ区分の中でも差が出る（例: ゆうパックの大阪府内は近畿の区分より120円安い）。

## ビルド

```sh
brew install xcodegen
xcodegen generate
python3 scripts/verify-logic.py
python3 scripts/check-syntax.py
```

アイコンを作り直すときは `python3 scripts/generate_icon.py`。
