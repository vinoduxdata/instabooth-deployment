#!/usr/bin/env bash
# Tear down the instabooth NetworkManager hotspot connection.

set -euo pipefail

HOTSPOT_CON_NAME="instabooth-hotspot"

if ! command -v nmcli >/dev/null 2>&1; then
  exit 0
fi

nmcli connection down "$HOTSPOT_CON_NAME" >/dev/null 2>&1 || true
nmcli connection delete "$HOTSPOT_CON_NAME" >/dev/null 2>&1 || true

echo "hotspot: stopped" >&2
