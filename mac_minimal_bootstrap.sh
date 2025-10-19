#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Käynnistetään minimalistinen dev-ympäristön asennus Macille..."
echo "Tämä skripti asentaa vain Dockerin ja Coliman – kaikki muu ajetaan konteissa."
echo "-----------------------------------------------------------"

# ----------------------------
# Helper functions
# ----------------------------
log() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$*" >&2; }

# ----------------------------
# Homebrew installation
# ----------------------------
if ! command -v brew >/dev/null 2>&1; then
  log "Asennetaan Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"
else
  log "Homebrew on jo asennettu."
fi

log "Päivitetään Homebrew..."
brew update -q

# ----------------------------
# Install Colima + Docker CLI
# ----------------------------
log "Asennetaan Colima ja Docker CLI..."
brew install -q colima docker docker-compose

# Käynnistetään Colima perusresursseilla
if ! colima status >/dev/null 2>&1; then
  log "Käynnistetään Colima (Docker VM)..."
  colima start --cpu 4 --memory 6 --disk 60 --runtime docker
else
  log "Colima on jo käynnissä."
fi

# ----------------------------
# Test Docker installation
# ----------------------------
log "Tarkistetaan Docker-asennus..."
docker version >/dev/null 2>&1 && log "Docker toimii oikein!" || warn "Docker ei vastaa."

# ----------------------------
# Final instructions
# ----------------------------
echo ""
echo "✅ Minimalistinen dev-ympäristö on valmis!"
echo "-----------------------------------------------------------"
echo "🧱 Käytössäsi on nyt:"
echo "  - Homebrew (vain ylläpitoa varten)"
echo "  - Colima (Docker-virtuaalikone)"
echo "  - Docker CLI ja docker-compose"
echo ""
echo "💡 Kehitä ja asenna kaikki työkalut Docker-konttien sisällä, esim:"
echo ""
echo "  docker run -it --rm \\"
echo "    -v \"\$PWD\":/workspace -w /workspace \\"
echo "    mcr.microsoft.com/devcontainers/python:3.11 bash"
echo ""
echo "📦 Tämä avaa täysin eristetyn ympäristön, jossa voit asentaa dbt, Snowflake CLI jne."
echo ""
echo "💤 Jos haluat sammuttaa Dockerin, käytä: colima stop"
echo "🚀 Ja käynnistää uudelleen: colima start"
echo "-----------------------------------------------------------"
