#!/bin/bash
set -euo pipefail
PLIST="$HOME/Library/LaunchAgents/com.ami.battery-notify.plist"
launchctl unload "$PLIST" 2>/dev/null || true
rm -f "$PLIST"
echo "アンインストール完了。"
