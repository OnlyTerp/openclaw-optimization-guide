#!/usr/bin/env bash
export PATH="$HOME/.npm-global/bin:$PATH"
# Restart the OpenClaw gateway using the native openclaw CLI.
# setup.sh (line 127) in this repo documents the correct restart pattern:
#   openclaw gateway stop && openclaw gateway start
# Previous versions used pkill + nohup + setsid which bypassed OpenClaw's
# own process manager and caused the gateway to fail to start.
set -euo pipefail

echo "restart-gateway: stopping existing gateway..."
openclaw gateway stop 2>/dev/null || true

echo "restart-gateway: starting gateway..."
openclaw gateway start

echo "restart-gateway: done"
