#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADMIN_DIR="${INSTABOOTH_ADMIN_DIR:-$ROOT/instabooth-admin}"
DATA_DIR="${INSTABOOTH_DATA_DIR:-}"
SERVER_SRC="${INSTABOOTH_SERVER_SRC:-$ROOT/instabooth-server/src}"
VENV="${INSTABOOTH_VENV:-$ROOT/instabooth-server/myenv/bin/activate}"

if [[ -z "$DATA_DIR" && -f "$ADMIN_DIR/active-event.json" ]]; then
  DATA_PATH="$(python3 -c "import json; print(json.load(open('$ADMIN_DIR/active-event.json'))['data_path'])")"
  if [[ "$DATA_PATH" = /* ]]; then
    DATA_DIR="$DATA_PATH"
  else
    DATA_DIR="$ROOT/$DATA_PATH"
  fi
fi

DATA_DIR="${DATA_DIR:-$ROOT/instabooth-data/events/default}"

# shellcheck disable=SC1090
source "$VENV"
export PYTHONPATH="$SERVER_SRC${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m photobooth --admin-dir "$ADMIN_DIR" --data-dir "$DATA_DIR" "$@"
