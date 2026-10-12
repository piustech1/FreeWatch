#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"
export NODE_PATH="$DIR/scripts/node_modules"
export PATH="/Users/piustech/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

NODE_BIN="$(which node 2>/dev/null || echo "/Users/piustech/.local/bin/node")"

exec "$NODE_BIN" "$DIR/scripts/fcm_daemon.js" >> "$DIR/scripts/fcm_daemon.log" 2>&1
