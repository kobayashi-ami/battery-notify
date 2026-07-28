#!/bin/bash
# バッテリー残量監視: 20%を切ったらiPhoneにBark通知。
# Mac自体がOS標準で低バッテリー通知を出す（アプリを問わず出る）ので、
# こちらはMac側の通知は作らず、常にiPhoneへ送るだけにしている。
#
# 見回りスケジュール方式：固定間隔ではなく、AC接続中/バッテリー残量から
# 次の見回りまでの秒数を毎回計算する常駐ループ（launchdのKeepAliveで維持）。

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$DIR/config.json"
STATE="$DIR/state.json"
LOG="$DIR/logs/monitor.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; }

# ログが肥大化しないよう、一定行数を超えたら古い分を切り捨てる
rotate_log() {
  local max_lines=2000
  [ -f "$LOG" ] || return
  local lines
  lines=$(wc -l < "$LOG" | tr -d ' ')
  if [ "$lines" -gt "$max_lines" ]; then
    tail -n "$max_lines" "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
  fi
}

[ -f "$STATE" ] || echo '{"notified_thresholds":[]}' > "$STATE"

notify_iphone() {
  local percent="$1" sound
  if [ "$BARK_KEY" = "YOUR_BARK_KEY_HERE" ] || [ -z "$BARK_KEY" ]; then
    log "Bark keyが未設定のためiPhone通知をスキップ（config.jsonを編集してください）"
    return
  fi
  sound=$(jq -r '.iphone_sound // "bell"' "$CONFIG")
  local payload
  payload=$(jq -n --arg key "$BARK_KEY" --arg title "バッテリー残量低下" \
    --arg body "残り${percent}%です" \
    --arg sound "$sound" \
    '{device_key:$key, title:$title, body:$body, sound:$sound}')
  curl -s -X POST "https://api.day.app/push" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "$payload" > /dev/null
}

# 1回分のチェック。結果はグローバル変数 LAST_PERCENT / LAST_ON_AC にセットする
# （次の見回り間隔の計算に使う）。
do_check() {
  local batt_info percent on_ac_local reset_percent thresholds t already

  BARK_KEY=$(jq -r '.bark_key' "$CONFIG")
  reset_percent=$(jq -r '.reset_percent' "$CONFIG")

  batt_info=$(pmset -g batt)
  percent=$(echo "$batt_info" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')

  if [ -z "$percent" ]; then
    log "バッテリー情報を取得できませんでした（デスクトップ機の可能性）"
    LAST_PERCENT=""
    LAST_ON_AC="true"
    return
  fi

  on_ac_local=false
  if echo "$batt_info" | head -1 | grep -q "AC Power"; then
    on_ac_local=true
  fi

  LAST_PERCENT="$percent"
  LAST_ON_AC="$on_ac_local"

  if [ "$on_ac_local" = "true" ]; then
    if [ "$percent" -ge "$reset_percent" ]; then
      tmp=$(jq '.notified_thresholds=[]' "$STATE")
      echo "$tmp" > "$STATE"
    fi
    return
  fi

  thresholds=$(jq -r '.battery_thresholds[]' "$CONFIG" | sort -rn)
  for t in $thresholds; do
    if [ "$percent" -le "$t" ]; then
      already=$(jq --argjson t "$t" '.notified_thresholds | index($t) != null' "$STATE")
      if [ "$already" = "false" ]; then
        notify_iphone "$percent"
        log "${t}%到達（${percent}%）: iPhone通知"
        tmp=$(jq --argjson t "$t" '.notified_thresholds += [$t]' "$STATE")
        echo "$tmp" > "$STATE"
      fi
    fi
  done
}

# 次の見回りまでの秒数を算出する。
# AC接続中（満充電維持中含む）は長め固定。バッテリー駆動中は
# 「最低閾値までの残りポイント数 × 1ポイントあたりの安全秒数」で、
# 閾値に近いほど短くなる。min/maxでクランプする。
compute_sleep_interval() {
  local min_i max_i ac_i per_point lowest_threshold distance interval

  min_i=$(jq -r '.patrol_min_interval_seconds' "$CONFIG")
  max_i=$(jq -r '.patrol_max_interval_seconds' "$CONFIG")
  ac_i=$(jq -r '.patrol_ac_interval_seconds' "$CONFIG")
  per_point=$(jq -r '.patrol_seconds_per_percent' "$CONFIG")

  if [ -z "$LAST_PERCENT" ] || [ "$LAST_ON_AC" = "true" ]; then
    echo "$ac_i"
    return
  fi

  lowest_threshold=$(jq -r '.battery_thresholds | min' "$CONFIG")
  distance=$((LAST_PERCENT - lowest_threshold))
  [ "$distance" -lt 0 ] && distance=0

  interval=$((distance * per_point))
  [ "$interval" -lt "$min_i" ] && interval=$min_i
  [ "$interval" -gt "$max_i" ] && interval=$max_i
  echo "$interval"
}

log "見回りループ開始"

while true; do
  do_check
  rotate_log
  sleep_for=$(compute_sleep_interval)
  log "残${LAST_PERCENT:-?}% AC=${LAST_ON_AC:-?} → 次回まで${sleep_for}秒"
  sleep "$sleep_for"
done
