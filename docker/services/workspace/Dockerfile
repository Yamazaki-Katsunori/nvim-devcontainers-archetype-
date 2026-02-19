FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

# -----------------------------------------------------------------------------
# Base tools + Ensure user exists + passwordless sudo
# -----------------------------------------------------------------------------
RUN set -e; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
  ca-certificates curl git unzip jq \
  openssh-client sudo \
  ripgrep fd-find locales; \
  rm -rf /var/lib/apt/lists/*; \
  ln -sf "$(command -v fdfind)" /usr/local/bin/fd || true; \
  if ! id -u "$USERNAME" >/dev/null 2>&1; then \
  groupadd --gid "$USER_GID" "$USERNAME"; \
  useradd --uid "$USER_UID" --gid "$USER_GID" -m "$USERNAME"; \
  fi; \
  echo "$USERNAME ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME"; \
  chmod 0440 "/etc/sudoers.d/$USERNAME"

USER $USERNAME

