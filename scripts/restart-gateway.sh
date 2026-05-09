#!/usr/bin/env bash
# Restart the OpenClaw gateway using the native openclaw CLI.
# setup.sh (line 127) in this repo documents the correct restart pattern:
#   openclaw gateway stop && openclaw gateway start
# Previous versions used pkill + nohup + setsid which bypassed OpenClaw's
# own process manager and caused the gateway to fail to start.
#
# DO NOT reference openclaw-gateway.service. There is no installed systemd
# unit. The gateway is managed by the openclaw CLI directly. Using systemctl
# was the wrong diagnostic target on 2026-05-08 and caused the deploy to
# false-fail when the gateway was actually healthy.
set -euo pipefail

# appleboy/ssh-action runs a non-interactive shell — ~/.bashrc is never sourced,
# so ~/.npm-global/bin (where openclaw lives) is not in PATH. Add it explicitly.
export PATH="$HOME/.npm-global/bin:$PATH"

echo "restart-gateway: stopping existing gateway..."
openclaw gateway stop 2>/dev/null || true

echo "restart-gateway: starting gateway..."
openclaw gateway start

echo "restart-gateway: done"
