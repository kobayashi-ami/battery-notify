# battery-notify

充電が20%より下がったら、iPhoneに知らせてくれるソフトです。

Macは、もともとOSが自分で「バッテリーが少なくなりました」と教えてくれます。
これは、Cubaseで書き出し中でも、Adobeのソフトを使っていても、お構いなしに出ます。
だから、Mac側の通知は、あらためて作る必要がありませんでした。
このソフトがやることは、ひとつだけです。iPhoneにも、同じタイミングで知らせること。

- 20%を切ったら → iPhoneにBarkで通知します（毎回、必ず）

## 見回りのしかた

ずっと同じ間隔でチェックするのは、もったいないです。CPUをむだに起こしてしまいます。
なので、状況によって見回る間隔を変えています。

- **電源につながっているとき**（満充電を保っているときも含む）
  → のんびり、既定600秒に1回だけ見ます
- **バッテリーで動いているとき**
  → `(今の% − 一番低いしきい値) × patrol_seconds_per_percent`秒。
  20%まで遠いときは長く休み、近づくほど、こまめに見に行きます。
  `patrol_min_interval_seconds`〜`patrol_max_interval_seconds`の
  範囲におさまるようにしています。

この計算のもとになっているのは、「一番はやくバッテリーが減るときで、
1分に1%減る」という想定です。この速さでも、20%のラインを
見のがさずにつかまえられるように、間隔を決めています。

launchdの`KeepAlive`が、この見回りを見守っています。もし止まっても、すぐにまた動き出します。

## つかいかた

1. iPhoneでApp Storeから「Bark - Custom Notifications」を入れます。
   出てきたデバイスキーをコピーしてください。
   （「Bark Kids」という似た名前の、子ども見守り用の別アプリがあるので、
   まちがえないでください）
2. `cp config.example.json config.json` を実行してから、
   `config.json`の`bark_key`を、そのキーに書きかえます。
   （`config.json`には本物のキーが入っているので、`.gitignore`で
   gitには乗らないようにしてあります）
3. `./install.sh` を実行します（launchdに登録され、動きはじめます）

見回りの間隔の数字を変えたいときは、`config.json`を書きかえるだけで大丈夫です。
入れ直す必要はありません。

## 通知の音

コンビニの入店音みたいに明るい音（Sosumi、alarm、chime、minuetの類）は、やめました。
ほしかったのは、もっと無機質で、低い音です。今は**bell**（一回だけ鳴って、
すっと消えていく音）にしています。

ほかにも選べます：alarm, anticipate, birdsong, bloom, calypso, chime,
choo, descent, electronic, fanfare, glass, gotosleep,
healthnotification, horn, ladder, mailsent, minuet,
multiwayinvitation, newmail, newsflash, noir, paymentsuccess, shake,
sherwoodforest, silence, spell, suspense, telegraph, tiptoes,
typewriters, update

`config.json`の`iphone_sound`を書きかえるだけで、次の通知から変わります。

## ファイルの説明

- `monitor.sh` — 本体です。見回りのループが入っています
  （バッテリーを見る→しきい値を見る→通知する→ログを整理する→
  次の間隔を決める→眠る、のくり返し）
- `config.json` — Barkのキーや、しきい値、見回りの間隔、通知の音の設定が入っています
- `config.example.json` — 上のひな形です。キーは入っていません。gitに乗るのはこちらだけです
- `state.json` — もう通知したしきい値の記録です。
  充電されて`reset_percent`以上にもどると、消えます
- `install.sh` / `uninstall.sh` — launchdへの登録・解除をします
- `logs/monitor.log` — 動いた記録です。2000行をこえたら、古い分から自動で消えます

## 止める・消す

```
./uninstall.sh
```
