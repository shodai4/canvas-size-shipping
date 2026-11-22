# GitHub Actions の定義（未設置）

`.github/workflows/` へ置くと動く。このリポジトリへの push では、GitHub App に
`workflows` 権限がないため `.github/workflows/*.yml` を含められず、ここに退避している。

```sh
mkdir -p .github/workflows
cp ci/ios-build.yml .github/workflows/
git add .github/workflows && git commit -m "CI を設置" && git push
```

ブラウザから `.github/workflows/ios-build.yml` としてアップロードしても同じ。

`ios-build.yml` は 3 つのジョブを順に走らせる。

| ジョブ | 環境 | 内容 |
| --- | --- | --- |
| `test` | ubuntu-latest | `verify-logic.py`（号数・送料・梱包の計算）と `check-syntax.py`（tree-sitter の構文点検） |
| `build` | macos-26 | XcodeGen ＋ SPM 解決 ＋ 署名なしビルド |
| `testflight` | macos-26 | アーカイブ → 埋め込みフレームワークに仮署名 → 書き出し（クラウド署名） → TestFlight へアップロード |

必要なリポジトリ Secrets:

| Secret | 内容 |
| --- | --- |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API キーの Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | AuthKey_\*.p8 の中身 |
| `APPLE_TEAM_ID` | チーム ID（86WNUS2875） |

注意点:

- `ci-testflight.sh` は macOS ランナーで走るため、tree-sitter が入っていれば構文点検を
  呼び、入っていなければ飛ばす。構文点検の本体は `test` ジョブ（ubuntu-latest）で行う。
- アーカイブは署名なしで作り、`Frameworks/*` に
  `codesign --force --sign - --timestamp=none` で ad-hoc 仮署名をしてから
  `-exportArchive`（`-allowProvisioningUpdates` のクラウド署名）で配布署名に付け替える。
  これを飛ばすと GoogleMobileAds が ITMS-90035 で弾かれる。
- `BUILD_NUMBER` は `github.run_number` を渡している。App Store Connect 側の
  App ID は `6837962030`、Bundle ID は `com.shodai4.canvassizeshipping`。
