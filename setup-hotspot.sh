#!/usr/bin/env bash
# Start an Ubuntu NetworkManager Wi-Fi hotspot for offline guest sharing.
# Usage: setup-hotspot.sh <admin_dir> <mode> <env_out_file>
# Writes INSTABOOTH_HOTSPOT_* variables to env_out_file on success. Exit 0 on success, 1 on skip/failure.

set -euo pipefail

ADMIN_DIR="${1:?admin_dir required}"
MODE="${2:-prod}"
ENV_OUT="${3:?env_out file required}"

HOTSPOT_CON_NAME="instabooth-hotspot"

read_hotspot_config() {
  local booth_file="$ADMIN_DIR/booth.${MODE}.json"
  if [[ ! -f "$booth_file" ]]; then
    booth_file="$ADMIN_DIR/booth.json"
  fi
  python3 - "$booth_file" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
enabled = True
ssid = "InstaBooth"
password = "instabooth-guest"
interface = ""
if path.is_file():
    hotspot = json.loads(path.read_text(encoding="utf-8")).get("hotspot") or {}
    enabled = bool(hotspot.get("enabled", True))
    ssid = str(hotspot.get("ssid") or ssid)
    password = str(hotspot.get("password") or password)
    interface = str(hotspot.get("interface") or "")
print(enabled)
print(ssid)
print(password)
print(interface)
PY
}

mapfile -t _hotspot_cfg < <(read_hotspot_config)
HOTSPOT_ENABLED="${INSTABOOTH_HOTSPOT_ENABLED:-${_hotspot_cfg[0]}}"
SSID="${INSTABOOTH_HOTSPOT_SSID:-${_hotspot_cfg[1]}}"
PASSWORD="${INSTABOOTH_HOTSPOT_PASSWORD:-${_hotspot_cfg[2]}}"
IFACE="${INSTABOOTH_HOTSPOT_IFACE:-${_hotspot_cfg[3]}}"

if [[ "$HOTSPOT_ENABLED" != "True" && "$HOTSPOT_ENABLED" != "true" && "$HOTSPOT_ENABLED" != "1" ]]; then
  echo "hotspot: disabled in config" >&2
  exit 1
fi

if ! command -v nmcli >/dev/null 2>&1; then
  echo "hotspot: nmcli not found (install NetworkManager)" >&2
  exit 1
fi

if [[ -z "$IFACE" ]]; then
  IFACE="$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2 == "wifi" { print $1; exit }')"
fi

if [[ -z "$IFACE" ]]; then
  echo "hotspot: no Wi-Fi device found" >&2
  exit 1
fi

if [[ ${#PASSWORD} -lt 8 ]]; then
  echo "hotspot: password must be at least 8 characters" >&2
  exit 1
fi

nmcli connection down "$HOTSPOT_CON_NAME" >/dev/null 2>&1 || true
nmcli connection delete "$HOTSPOT_CON_NAME" >/dev/null 2>&1 || true

if ! nmcli device wifi hotspot ifname "$IFACE" ssid "$SSID" password "$PASSWORD" con-name "$HOTSPOT_CON_NAME"; then
  echo "hotspot: failed to start AP on $IFACE" >&2
  exit 1
fi

sleep 1
HOTSPOT_IP="$(nmcli -g IP4.ADDRESS device show "$IFACE" 2>/dev/null | head -n1 | cut -d/ -f1)"
if [[ -z "$HOTSPOT_IP" ]]; then
  HOTSPOT_IP="$(nmcli -g IP4.ADDRESS connection show "$HOTSPOT_CON_NAME" 2>/dev/null | head -n1 | cut -d/ -f1)"
fi

{
  printf 'INSTABOOTH_HOTSPOT_SSID=%q\n' "$SSID"
  printf 'INSTABOOTH_HOTSPOT_PASSWORD=%q\n' "$PASSWORD"
  printf 'INSTABOOTH_HOTSPOT_IFACE=%q\n' "$IFACE"
  printf 'INSTABOOTH_HOTSPOT_IP=%q\n' "${HOTSPOT_IP:-}"
} >"$ENV_OUT"

echo "hotspot: started SSID=$SSID on $IFACE (IP=${HOTSPOT_IP:-unknown})" >&2
exit 0
