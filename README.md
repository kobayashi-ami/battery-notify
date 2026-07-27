# battery-notify

充電残量が20%を切ったら通知するソフト。

- 通常時: Macの右上にネイティブ通知（terminal-notifier）
- Cubase / FL Studio / Adobeアプリ / Facebook / 主要ストリーミングサイト
  （YouTube, Netflix, Twitch, Prime Video, U-NEXT, Hulu, Disney+, ABEMA,
  ニコニコ動画, TVer）を視聴中は、Mac通知を出さずiPhoneにBark通知を送る

起動時のフォアグラウンドアプリ／ブラウザの視聴中タブを見て判定する。
判定はサイト単位（ドメインが一致すれば「視聴中」扱い）で、動画の種類
（PV/ライブ/映画）までは区別しない。

見回りは固定間隔ではなく「見回りスケジュール」方式。AC接続中（満充電維持中含む）
は`patrol_ac_interval_seconds`（既定600秒）、バッテリー駆動中は
`(現在% − 最低閾値) × patrol_seconds_per_percent`秒で、20%に近づくほど
間隔が短くなり、`patrol_min_interval_seconds`〜`patrol_max_interval_seconds`
の範囲でクランプされる。launchdは`KeepAlive`でこの常駐ループを維持し、
落ちても自動再起動する。

## セットアップ

1. iPhoneでApp Storeから「Bark - Custom Notifications」をインストールし、
   表示されるデバイスキーをコピー（「Bark Kids」は別アプリなので注意）
2. `cp config.example.json config.json` してから `bark_key` をそのキーに書き換える
   （`config.json` は実キー入りなので`.gitignore`済み、コミットされない）
3. `./install.sh` を実行（launchdに登録、常駐開始）

除外アプリやストリーミングサイトを増やしたい場合は `config.json` の
`excluded_apps` / `streaming_domains` を編集するだけでよい（再インストール不要）。
見回り間隔の係数を変えた場合も同様に再インストール不要（毎回configを読み直す）。

## 通知音

- `mac_sound`（既定: Sosumi） — 選べる音: Basso, Blow, Bottle, Frog, Funk,
  Glass, Hero, Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink, default
- `iphone_sound`（既定: alarm） — 選べる音: alarm, anticipate, bell,
  birdsong, bloom, calypso, chime, choo, descent, electronic, fanfare,
  glass, gotosleep, healthnotification, horn, ladder, mailsent, minuet,
  multiwayinvitation, newmail, newsflash, noir, paymentsuccess, shake,
  sherwoodforest, silence, spell, suspense, telegraph, tiptoes,
  typewriters, update

`config.json`を編集するだけで反映される（次回通知時にconfigを読み直すため
再インストール不要）。

## ファイル

- `monitor.sh` — 本体。見回りループ（バッテリー%取得→閾値判定→除外判定→通知→ログローテーション→次回間隔計算→sleep）
- `config.json` — Bark key・閾値・見回り間隔係数・通知音・除外アプリ/サイトの設定
- `state.json` — 通知済み閾値の記録（充電されて`reset_percent`以上になるとリセット）
- `install.sh` / `uninstall.sh` — launchd登録/解除
- `logs/monitor.log` — 動作ログ。2000行を超えると自動で古い分を切り捨てる（`rotate_log`）

## 停止・削除

```
./uninstall.sh
```

## 注意

- 初回、System EventsやブラウザのURL取得でmacOSの権限ダイアログ
  （アクセシビリティ／自動化）が出ることがある。許可すること。
- Cubase/FL StudioがXなど他アプリ名と被る場合はアプリ名の完全一致ではなく
  部分一致で判定しているので、`config.json`側で調整可能。
