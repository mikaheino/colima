#!/usr/bin/env bash
# MacOS bootstrap for dev setup (Cursor/VSCode + Colima + dbt + Snowflake + Azure)
# Tested on macOS 14+ (Apple Silicon & Intel)
# Safe to re-run (idempotent)

set -uo pipefail
IFS=$'\n\t'

### -------------------- toggles --------------------
INSTALL_GIT=${INSTALL_GIT:-1}
INSTALL_TERRAFORM=${INSTALL_TERRAFORM:-1}
INSTALL_AZURE=${INSTALL_AZURE:-1}
INSTALL_DBT_FUSION=${INSTALL_DBT_FUSION:-1}
INSTALL_DBT_CORE=${INSTALL_DBT_CORE:-1}
INSTALL_SNOWCLI=${INSTALL_SNOWCLI:-1}
INSTALL_SNOWSQL=${INSTALL_SNOWSQL:-0}
INSTALL_SHELL_HELP=${INSTALL_SHELL_HELP:-1}

### -------------------- helpers --------------------
log()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }
die()  { printf "\033[1;31mXX\033[0m %s\n" "$*" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }

### -------------------- preflight --------------------
if ! has brew; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"
fi

brew update -q

### -------------------- base tools --------------------
log "Installing core CLI tools..."
brew install -q git curl wget jq unzip python3 pipx

pipx ensurepath
export PATH="$HOME/.local/bin:$PATH"

### -------------------- container runtime --------------------
log "Installing Colima + Docker CLI..."
brew install -q colima docker docker-compose
if ! colima list | grep -q "default"; then
  colima start --cpu 4 --memory 6 --disk 60
fi

### -------------------- editors --------------------
log "Installing editors (Cursor + VS Code)..."
brew install --cask cursor visual-studio-code || true

### -------------------- developer CLIs --------------------
if [[ "$INSTALL_TERRAFORM" == "1" ]]; then
  log "Installing Terraform..."
  brew install -q terraform
fi

if [[ "$INSTALL_AZURE" == "1" ]]; then
  log "Installing Azure CLI..."
  brew install -q azure-cli
fi

if [[ "$INSTALL_DBT_FUSION" == "1" ]]; then
  log "Installing dbt Fusion CLI..."
  curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --update
fi

if [[ "$INSTALL_DBT_CORE" == "1" ]]; then
  log "Installing dbt + Snowflake adapter..."
  pipx install dbt-snowflake || true
fi

if [[ "$INSTALL_SNOWCLI" == "1" ]]; then
  log "Installing Snowflake CLI..."
  pipx install snowflake-cli-labs || pipx install snowflake-cli
fi

if [[ "$INSTALL_SNOWSQL" == "1" ]]; then
  log "Installing SnowSQL (legacy client)..."
  brew install --cask snowflake-snowsql
fi

### -------------------- shell helpers --------------------
if [[ "$INSTALL_SHELL_HELP" == "1" ]]; then
  log "Configuring shell helpers..."
  SHELL_RC="$HOME/.zshrc"
  [[ -n "$BASH_VERSION" ]] && SHELL_RC="$HOME/.bashrc"

  mkdir -p "$HOME/.bashrc.d"

  cat > "$HOME/.bashrc.d/dev-help.sh" <<'EOF'
parse_git_branch() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
  git symbolic-ref --short -q HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}
if [ -n "$PS1" ]; then
  export PS1='%F{green}%~%f$(b=$(parse_git_branch); [ -n "$b" ] && printf " ⌥%s⌥" "$b") \$ '
fi
alias mkenv='python3 -m venv .venv && echo "Run: source .venv/bin/activate"'
alias act='[ -f .venv/bin/activate ] && source .venv/bin/activate || echo ".venv missing"'
alias deact='deactivate 2>/dev/null || echo "No venv active"'
alias gst='git status -sb'
alias ga='git add'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gl='git pull --ff-only'
alias gsync='git fetch --all --prune && git pull --rebase --autostash'
alias setgitme='git config --global user.name "$1"; git config --global user.email "$2"; git config --global init.defaultBranch main; git config --global pull.rebase true;'
EOF

  if ! grep -q '.bashrc.d' "$SHELL_RC" 2>/dev/null; then
    echo '[ -d "$HOME/.bashrc.d" ] && for f in $HOME/.bashrc.d/*.sh; do source "$f"; done' >> "$SHELL_RC"
  fi
fi

### -------------------- summary --------------------
log "✅ All done!"
echo
echo "Installed versions:"
git --version | head -n1
terraform -version | head -n1 || true
az version 2>/dev/null | head -n1 || true
dbt --version | head -n1 || true
snow --version 2>/dev/null || true
python3 --version
echo
echo "Tip: restart your terminal so PATH & completions load."
