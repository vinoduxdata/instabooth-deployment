#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADMIN_DIR="${INSTABOOTH_ADMIN_DIR:-$ROOT/instabooth-admin}"
DATA_DIR="${INSTABOOTH_DATA_DIR:-}"
SERVER_SRC="${INSTABOOTH_SERVER_SRC:-$ROOT/instabooth-server/src}"
VENV_PYTHON="${INSTABOOTH_PYTHON:-$ROOT/instabooth-server/myenv/bin/python}"

MODE="${INSTABOOTH_MODE:-prod}"
FORWARD_ARGS=()
expect_mode_value=false

for arg in "$@"; do
  if [[ "$expect_mode_value" == true ]]; then
    MODE="$arg"
    expect_mode_value=false
    continue
  fi
  case "$arg" in
    --mode=demo) MODE="demo" ;;
    --mode=prod) MODE="prod" ;;
    --mode)
      expect_mode_value=true
      ;;
    *)
      FORWARD_ARGS+=("$arg")
      ;;
  esac
done

if [[ "$expect_mode_value" == true ]]; then
  echo "error: --mode requires a value (demo or prod)" >&2
  exit 1
fi

case "$MODE" in
  demo|prod) ;;
  *)
    echo "error: unknown mode '$MODE' (use demo or prod)" >&2
    exit 1
    ;;
esac

export INSTABOOTH_MODE="$MODE"

if [[ -z "$DATA_DIR" && -f "$ADMIN_DIR/active-event.json" ]]; then
  DATA_PATH="$(python3 -c "import json; print(json.load(open('$ADMIN_DIR/active-event.json'))['data_path'])")"
  if [[ "$DATA_PATH" = /* ]]; then
    DATA_DIR="$DATA_PATH"
  else
    DATA_DIR="$ROOT/$DATA_PATH"
  fi
fi

DATA_DIR="${DATA_DIR:-$ROOT/instabooth-data/events/default}"

cleanup_hotspot() {
  sudo "$DEPLOY_DIR/stop-hotspot.sh" 2>/dev/null || true
}
trap cleanup_hotspot EXIT

echo "Starting instabooth in ${MODE} mode..."

HOTSPOT_ENV="$(mktemp)"
if sudo "$DEPLOY_DIR/setup-hotspot.sh" "$ADMIN_DIR" "$MODE" "$HOTSPOT_ENV"; then
  # shellcheck source=/dev/null
  source "$HOTSPOT_ENV"
  export INSTABOOTH_HOTSPOT_SSID INSTABOOTH_HOTSPOT_PASSWORD INSTABOOTH_HOTSPOT_IFACE INSTABOOTH_HOTSPOT_IP
else
  echo "warning: hotspot not started; offline Wi-Fi QR will be unavailable" >&2
fi
rm -f "$HOTSPOT_ENV"

export PYTHONPATH="$SERVER_SRC${PYTHONPATH:+:$PYTHONPATH}"
exec "$VENV_PYTHON" -m photobooth --admin-dir "$ADMIN_DIR" --data-dir "$DATA_DIR" "${FORWARD_ARGS[@]}"
