#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-/tmp/post_create_command.log}"
POSTCREATE_MARKER="/var/tmp/devcontainer-postcreate.done"

log() {
  echo "$@" | tee -a "$LOG_FILE"
}

log "=== postCreate: start ==="
log "log file: $LOG_FILE"

# --- Idempotency check ---
if [[ -f "$POSTCREATE_MARKER" ]]; then
  log "postCreate already executed. skip."
  exit 0
fi

mkdir -p "$(dirname "$POSTCREATE_MARKER")"

# --- Template processing ---
log ">>> postCreate command running..."
log ">>> (No actual uv/pnpm commands in template version)"

#--- Completion Mark (Idempotency Check File Generation) ---
touch "$POSTCREATE_MARKER"
log "postCreate marker created: $POSTCREATE_MARKER"
log "=== postCreate: done ==="
