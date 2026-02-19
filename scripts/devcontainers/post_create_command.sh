#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-$HOME/.cache/devcontainer/post_create_command.log}"
POSTCREATE_MARKER="${POSTCREATE_MARKER:-$HOME/.cache/devcontainer/postcreate.done}"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$POSTCREATE_MARKER")"

log() { echo "$@" | tee -a "$LOG_FILE"; }

log "=== postCreate: start ==="
log "log file: $LOG_FILE"

# --- Idempotency check ---
if [[ -f "$POSTCREATE_MARKER" ]]; then
  log "postCreate already executed. skip."
  exit 0
fi

# --- Template processing ---
log ">>> postCreate command running..."
log ">>> (Template: no project-specific installs)"

#--- Completion Mark (Idempotency Check File Generation) ---
touch "$POSTCREATE_MARKER"
log "postCreate marker created: $POSTCREATE_MARKER"
log "=== postCreate: done ==="
