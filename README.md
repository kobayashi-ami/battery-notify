# battery-notify

充電残量が20%を切ったら通知が来る。ただしこの見張り番は、いつ声を上げていいかをわきまえている。

Cubaseで書き出し中、Adobeで格闘中、配信や映画に沈んでいる最中に、右上からポップアップで割り込まれるのは邪魔でしかない。だからそのときは画面には何も出さず、代わりにiPhoneのポケットの中でひっそり鳴らす。判断基準は単純で、フォアグラウンドのアプリ名か、ブラウザが開いている視聴中タブのドメインを見るだけ。PVかライブか映画かまでは区別しない、そこまでは踏み込まない主義。

- **通常時** → Macにネイティブ通知（terminal-notifier）
- **Cubase / FL Studio / Adobeアプリ / Facebook が最前面、または主要ストリーミングサイト
  （YouTube, Netflix, Twitch, Prime Video, U-NEXT, Hulu, Disney+, ABEMA, ニコニコ動画, TVer）
  を視聴中** → Mac通知は出さず、iPhoneにBark通知

## 見回りスケジュール

固定間隔でずっと監視するのは芸がないし、無駄にCPUを起こし続けるだけなので、状況に応じて見回りの足取りを変える常駐ループにした。

- **AC接続中**（満充電維持中も含む）→ ゆったり、既定600秒に1回だけ様子を見る
- **バッテリー駆動中** → `(現在% − 最低閾値) × patrol_seconds_per_percent`秒。
  20%が遠いうちは長く休み、近づくにつれて足早になる。
  `patrol_min_interval_seconds`〜`patrol_max_interval_seconds`でクランプ

安全マージンの根拠は「最悪ケースのドレイン速度＝1%/分」。この係数なら、Adobeの書き出しやCubaseのレンダリングで電力を食い潰している最中でも、閾値の窓を素通りせずに捕まえられる計算になっている。launchdは`KeepAlive`でこのループを見守り、死んだら即座に叩き起こす。

## セットアップ

1. iPhoneでApp Storeから「Bark - Custom Notifications」をインストールし、
   表示されるデバイスキーをコピー（「Bark Kids」は子供の見守りアプリで別物なので注意）
2. `cp config.example.json config.json` してから `bark_key` をそのキーに書き換える
   （`config.json` は実キー入りなので`.gitignore`済み、コミットされない）
3. `./install.sh` を実行（launchdに登録、常駐開始）

除外アプリやストリーミングサイトを増やしたい場合は `config.json` の
`excluded_apps` / `streaming_domains` を編集するだけでいい（再インストール不要、
次の見回りから即反映される）。見回り間隔の係数も同様。

## 通知音

コーポレートな「LLCっぽい」明るいチャイム（Sosumi、alarm、chime、minuetの類）は却下した。狙ったのはもっとインダストリアルで、無機質で、低い周波数帯のもの。

- `mac_sound`（既定: **Submarine**） — ソナーの底鳴りのような、低くくぐもった単音。
  他の候補: Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse, Ping, Pop, Purr, Sosumi, Tink, default
- `iphone_sound`（既定: **bell**） — 一発だけ鳴って、そのまま余韻に沈んでいくポーンという音。
  他の候補: alarm, anticipate, birdsong, bloom, calypso, chime, choo, descent, electronic, fanfare,
  glass, gotosleep, healthnotification, horn, ladder, mailsent, minuet,
  multiwayinvitation, newmail, newsflash, noir, paymentsuccess, shake,
  sherwoodforest, silence, spell, suspense, telegraph, tiptoes,
  typewriters, update

`config.json`を書き換えるだけで、次の通知から反映される。

## ファイル

- `monitor.sh` — 本体。見回りループ（バッテリー%取得→閾値判定→除外判定→通知→ログローテーション→次回間隔計算→sleep）
- `config.json` — Bark key・閾値・見回り間隔係数・通知音・除外アプリ/サイトの設定
- `config.example.json` — 上記のテンプレート（実キーなし、gitにはこちらだけ乗る）
- `state.json` — 通知済み閾値の記録（充電されて`reset_percent`以上になるとリセット）
- `install.sh` / `uninstall.sh` — launchd登録/解除
- `logs/monitor.log` — 動作ログ。2000行を超えると古い分から静かに切り捨てられる

## 停止・削除

```
./uninstall.sh
```

## 注意

- 初回、System EventsやブラウザのURL取得でmacOSの権限ダイアログ
  （アクセシビリティ／自動化、通知の許可）が出ることがある。許可すること。
  terminal-notifierは`System Settings → 通知`で個別に許可が必要な場合がある。
- Cubase/FL Studioが他のアプリ名と被る場合は完全一致ではなく部分一致で
  判定しているので、`config.json`側で調整可能。
