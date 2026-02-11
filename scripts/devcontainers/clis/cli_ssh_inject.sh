#!/usr/bin/env bash
set -euo pipefail

echo "=== ssh inject for devcontainer: start (stdin mode) ==="

# repo root
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO_ROOT"

WORKSPACE_DIR="${WORKSPACE_DIR:-.}"
USER_NAME="${USER_NAME:-vscode}"

# host public key path (no mount needed)
PUBKEY_PATH="${PUBKEY_PATH:-$HOME/.ssh/id_ed25519.pub}"

echo "workspace: $WORKSPACE_DIR"
echo "user:      $USER_NAME"
echo "pubkey:    $PUBKEY_PATH"

if [[ ! -f "$PUBKEY_PATH" ]]; then
  echo "ERROR: public key not found on host: $PUBKEY_PATH" >&2
  echo "Tip: set PUBKEY_PATH=/path/to/your.pub" >&2
  exit 1
fi

KEY="$(cat "$PUBKEY_PATH")"
if [[ -z "$KEY" ]]; then
  echo "ERROR: public key is empty: $PUBKEY_PATH" >&2
  exit 1
fi

devcontainer exec --workspace-folder "$WORKSPACE_DIR" bash -lc "
set -euo pipefail

USER_NAME='$USER_NAME'

if ! getent passwd \"\$USER_NAME\" >/dev/null; then
  echo \"ERROR: user not found: \$USER_NAME\" >&2
  exit 1
fi

HOME_DIR=\$(getent passwd \"\$USER_NAME\" | cut -d: -f6)
test -n \"\$HOME_DIR\"

SSH_DIR=\"\$HOME_DIR/.ssh\"
AUTH_KEYS=\"\$SSH_DIR/authorized_keys\"

# rootで用意 → 最終的にユーザー所有にする
sudo install -d -m 700 -o \"\$USER_NAME\" -g \"\$USER_NAME\" \"\$SSH_DIR\"
sudo touch \"\$AUTH_KEYS\"
sudo chmod 600 \"\$AUTH_KEYS\"
sudo chown \"\$USER_NAME:\$USER_NAME\" \"\$AUTH_KEYS\"

KEY='$KEY'

# 以降は (既に \$USER_NAME で動いている想定なので) sudo -u は使わない
if ! grep -qxF \"\$KEY\" \"\$AUTH_KEYS\"; then
  printf '%s\n' \"\$KEY\" >> \"\$AUTH_KEYS\"
fi

echo \"OK: injected -> \$AUTH_KEYS\"
ls -la \"\$SSH_DIR\"
tail -n 2 \"\$AUTH_KEYS\" || true
"

echo "=== old host_key delete script run ==="
ssh-keygen -f ~/.ssh/known_hosts_devc -R "[localhost]:2222"
echo "=== old host_key delete script: done ==="

echo "=== ssh inject for devcontainer: done ==="
