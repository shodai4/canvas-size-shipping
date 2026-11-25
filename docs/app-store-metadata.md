# App Store 提出用メタデータ — 号数と送料

App Store Connect にそのまま貼れる形でまとめた。字数は実測値（全角1文字＝1文字で計算）。
最終更新 2026-11-23 ／ 対象バージョン 1.0（ビルド番号は CI の `github.run_number`）。

## 1. 基本情報

| 項目 | 値 |
| --- | --- |
| ホーム画面の表示名 | 号数と送料 |
| App Store のアプリ名 | 号数と送料（5文字／上限30） |
| Bundle ID | `com.shodai4.canvassizeshipping` |
| App Store Connect の Apple ID | 6837962030 |
| バージョン | 1.0 |
| 対応 | iPhone（iOS 17.0 以上）・縦向きのみ・iPad 非対応 |
| 価格 | 無料（広告あり） |
| アプリ内課金 | 広告非表示の買い切り `com.shodai4.canvassizeshipping.pro`（コード側は実装済み・App Store Connect への商品登録は未了） |
| 対応言語 | 日本語のみ |
| カテゴリ | プライマリ：仕事効率化 ／ セカンダリ：辞書／参考資料 |
| 年齢制限 | 4+（全年齢） |
| 端末の許可 | なし（カメラ・写真・位置情報などの許可を求めない） |

## 2. App Store に貼るテキスト

### アプリ名（30文字以内）
```
号数と送料
```

### サブタイトル（30文字以内）
```
キャンバスの寸法と発送の大きさ
```
（15文字）

### プロモーションテキスト（170文字以内・審査なしで更新できる）
```
全77号の一覧に、寸法からの逆引き、梱包後の3辺合計から出すヤマト・ゆうパック・佐川の運賃。作品を送るときに必要な数字が、1本にまとまっています。
```
（73文字）

### 概要（4000文字以内）
```
キャンバスの号数と、送るときの大きさを調べるリファレンスです。

■ 号数の一覧
F・P・M・S の 0〜100号とサムホール（SM）の全77件。長辺・短辺のミリ寸法を、号数と一緒に確かめられます。

■ 寸法から号数を逆引き
長辺と短辺を入れると、いちばん近い号数を選び、近い候補を4件まで並べます。長辺と短辺を入れ替えても同じ結果です。

■ 号数の選択と比率の確認
型（F・P・M・S・SM）と数字をプルダウンで選べます。枠には長辺・短辺のミリ数を沿えて描きます。

■ 梱包と送料
余裕・厚み・額装の有無から3辺合計を出し、ヤマト運輸・ゆうパック・佐川急便のサイズ区分と運賃を並べます。発地と着地は47都道府県から選べ、同じ都道府県どうしは県内運賃になります。
平べったい段ボール1枚で包む「ヤッコ包み」の必要寸法も出します。
三社の補償の上限と、美術便・家財おまかせ便の扱いも添えています。

■ お気に入りとメモ
よく使う号数と作品メモを、端末のなかに保存できます。

※ 運賃は2026年11月時点の各社公表値（全国発着・税込の基本運賃）です。割引・契約運賃・離島の中継料は含みません。実際の運賃は各社の表示が優先されます。
※ iPhone（iOS 17.0 以上）・縦向き。
```
（456文字）

### キーワード（100文字以内・カンマ区切り・スペースなし）
```
号数,キャンバス,送料,宅急便,ゆうパック,佐川,額装,画材,寸法,発送,梱包
```
（39文字）

キーワードの考え方：アプリ名とサブタイトルに入っている語（号数と送料／キャンバスの寸法と発送の大きさ）は重複しても検索対象になるため、ここでは**入っていない語**を優先した。「号数」「キャンバス」「送料」を軸に、配送会社名と発送の語を足した。

## 3. URL

| 項目 | URL |
| --- | --- |
| サポートURL（必須） | https://shodai4.com/apps/canvas-size-shipping/support.html |
| プライバシーポリシーURL（必須） | https://shodai4.com/apps/canvas-size-shipping/privacy.html |
| マーケティングURL（任意） | https://shodai4.com/apps/canvas-size-shipping/ |
| サポートの入口（アプリのページ） | https://shodai4.com/apps/canvas-size-shipping/ |

3つとも公開済み（2026-11-23 に 200 OK を確認）。

## 4. 年齢制限（App の年齢制限）

- 全年齢（4+）。暴力・性的表現・ギャンブル・ホラー・医薬品・ユーザー生成コンテンツ・位置情報の共有はいずれも「なし」。
- 広告は画面下部の独立した帯に Google AdMob のバナーを表示する（内容は Google の広告ネットワークの審査を通ったもの）。

端末の許可は求めず、利用者の入力は端末内だけで扱う。

## 5. App のプライバシー（栄養ラベル）

アプリ本体は何も収集しない。広告SDK（Google Mobile Ads）分だけを、サードパーティの広告目的として申告する。

| データの種類 | 収集 | 使途 | トラッキング |
| --- | --- | --- | --- |
| 識別子（端末ID） | する（Google Mobile Ads SDK） | サードパーティの広告 | しない |
| 使用状況データ（広告の表示・反応） | する（Google Mobile Ads SDK） | サードパーティの広告 | しない |
| ユーザーのコンテンツ（メモ） | しない | 端末内のみ | — |
| 診断 | しない | — | — |

- 「トラッキング」はすべて**しない**（ATT を要求しておらず、`PrivacyInfo.xcprivacy` も `NSPrivacyTracking=false`）。App Store Connect では「データをトラッキングに使用していますか」に **いいえ**。
- 提出前に Google の開示（<https://policies.google.com/technologies/partner-sites>）と AdMob SDK のデータ開示を照合し、過不足がないか最終確認する。

## 6. App Review 担当者向けメモ（Review Notes）

英日どちらも貼れるようにしてある。ASC の Review Notes は英語を推奨。

### English

```
No account, sign-in or device permission is required. Size and rate tables ship inside the app; favourites and work memos are stored only in UserDefaults on the device.

The app works offline; the only network traffic is the Google Mobile Ads banner. No App Tracking Transparency request; the privacy manifest declares no tracking.

Shipping rates are reference values: basic published tariffs from Osaka for Nov 2026 (tax included, cash payment). Discounts, contract rates and remote-island surcharges are not included, and the carrier's own quote governs.

To reach the core feature: enter long and short side in mm to get the nearest canvas size, then open 梱包 and 送料 to see the three carriers' size classes and fares.
```

### 日本語（控え）

```
ログイン・端末の許可ともに不要。号数表と運賃表はアプリ内に同梱、お気に入りとメモは端末内（UserDefaults）のみ。通信は広告のみ。運賃は2026年11月時点の各社公表値（全国発着・税込）で、割引等は含まない旨を概要にも明記。
```

## 7. スクリーンショット

- 必須：iPhone 6.9インチ（1290×2796px または 1320×2868px）。3〜10枚。
- 任意：iPhone 6.5インチ（1284×2778px）。iPad は非対応なので不要。
- 1枚目でアプリの核心が分かる画面を出す（起動 → 長辺・短辺を入力（逆引き）→ 「梱包」「送料」を開く）。
- 端末の枠やキャプションを載せる場合も、実際のアプリ画面をそのまま使う（合成した偽のUIは不可）。
- 撮影は実機または iOS 17 以降のシミュレータ。逆引きの結果と、三社の運賃が並ぶ画面の2枚は必ず入れる。

## 8. 提出前チェックリスト

- [ ] App Store Connect にアプリレコードがある（Apple ID 6837962030）／Bundle ID `com.shodai4.canvassizeshipping`
- [ ] バージョン 1.0 に、CI がアップロードしたビルドを選択
- [ ] サポートURL・プライバシーポリシーURL が 200 で開く
- [ ] 「App のプライバシー」を第5節のとおり入力
- [ ] 年齢制限を 4+ に設定
- [ ] カテゴリを第1節のとおり設定
- [ ] スクリーンショットを 6.9インチで3枚以上
- [ ] 広告の本番IDへの差し替え（下記「未対応」を参照）
- [ ] アプリ内課金を出す場合は商品登録と審査提出、出さない場合は導線が「準備中」で押せないことを確認
- [ ] 輸出コンプライアンス：`ITSAppUsesNonExemptEncryption=false` 済み（追加質問なし）
- [ ] 審査用の連絡先メールと電話を記入

## 9. 未対応・提出前に判断がいること

1. **広告IDが Google のテスト用IDのまま**（`Sources/Views/BannerAdView.swift` の `adUnitID` と `Info.plist` の `GADApplicationIdentifier` が `ca-app-pub-3940256099942544` 系）。このまま審査に出すと広告はテスト広告のままで、収益も出ない。本番のアプリID・ユニットIDへ差し替えるか、いったん広告を外して出すかを決める。差し替えは Swift 側の変更なので、このタスクでは触っていない。
2. **アプリ内課金（広告非表示）が ASC 未登録**。商品を作らないまま提出すると、アプリ内の「広告を消す」が「準備中」で押せない状態になる。審査で「機能していない課金導線」と見られる可能性があるため、商品登録して提出するか、導線ごと外すかを決める。
3. **6本同時提出のスパム判定（ガイドライン4.3）**。同じ開発者から同じ分野のアプリをまとめて出すため、機能の違いが伝わるよう、概要とレビューメモで「何をするアプリか」を明確にしている。スクリーンショットもアプリごとに別の画面にすること。
4. **`PrivacyInfo.xcprivacy` は同梱済み**（追跡なし・UserDefaults の利用理由 CA92.1）。
5. 運賃は各社の公表値を写したもの。改定があったら `Sources/Models/ShippingRateData.swift` を更新する（概要の「2026年11月時点」も合わせる）。

## 10. 審査で聞かれやすい点と回答

| 想定される指摘 | 回答 |
| --- | --- |
| カメラ／写真を何に使うのか | 端末の許可は一切求めない（カメラ・写真・位置情報を使わない）。 |
| 通信はあるのか | 広告の読み込みのみ。メモや寸法は送らない。 |
| 広告はどこから出ているのか | 画面下部の独立した帯の AdMob バナー。 |
| データはどこに保存されるのか | お気に入りと作品メモは端末内（UserDefaults）のみ。 |
| 似たアプリが複数ある（4.3） | それぞれ目的が異なる（明暗を見る／配色を逆算する／額装を確かめる／構図を決める／号数と送料を調べる／乾燥日数を見積もる）。画面構成もデータも別で、共通のコードベースは使っていない。 |
