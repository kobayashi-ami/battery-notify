#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST="$HOME/Library/LaunchAgents/com.ami.battery-notify.plist"

chmod +x "$DIR/monitor.sh"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.ami.battery-notify</string>
  <key>ProgramArguments</key>
  <array><string>$DIR/monitor.sh</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$DIR/logs/launchd.log</string>
  <key>StandardErrorPath</key><string>$DIR/logs/launchd.log</string>
</dict>
</plist>
EOF

launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

echo "インストール完了。常駐ループで見回りスケジュールに沿ってチェックします。"
echo "iPhone通知を使うには config.json の bark_key を編集してください。"
