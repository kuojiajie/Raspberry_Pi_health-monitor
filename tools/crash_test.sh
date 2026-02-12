#!/bin/bash
set -euo pipefail

echo "Triggering a crash via systemd environment override (temporary)..."

sudo systemctl set-environment FORCE_CRASH=1
sudo systemctl restart health-monitor.service

sleep 2
sudo systemctl unset-environment FORCE_CRASH

echo "Now follow logs:"
echo "  sudo journalctl -u health-monitor.service -f"

