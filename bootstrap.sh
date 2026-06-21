#!/bin/bash
# ============================================
# BOOTSTRAP -- OpenClaw ORIGINAL puro + Telegram v2
# ============================================
# Roda UMA VEZ numa VPS Ubuntu 22+ (ou macOS 13+).
# Linux: roda como root.  Mac: roda como usuario normal.
#
# Instala: Node 22 (via nvm), Python 3, ffmpeg, tmux e o
#          OpenClaw CLI ORIGINAL (npm install -g openclaw@2026.6.5).
#          https://github.com/openclaw/openclaw
#
# NAO instala nada customizado: sem subagentes, sem skills, sem banco de memoria.
# OpenClaw puro. O aluno configura o resto seguindo SETUP-AGENTE.md.
#
# Uso (Ubuntu, root):
#   curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/bootstrap.sh | bash
# ============================================

set -e

# Detecta SO
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ -f /etc/os-release ]] && grep -qiE "ubuntu|debian" /etc/os-release; then
  OS="ubuntu"
else
  echo "ERRO: SO nao suportado. Precisa Ubuntu 22+ (ou Debian) ou macOS 13+."
  exit 1
fi

echo "============================================"
echo "BOOTSTRAP OpenClaw PURO + TELEGRAM v2 ($OS)"
echo "============================================"

# ============================================
# UBUNTU / DEBIAN
# ============================================
if [[ "$OS" == "ubuntu" ]]; then
  if [[ "$EUID" -ne 0 ]]; then
    echo "ERRO: rode como root no Ubuntu."
    echo "Tenta: sudo bash <(curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/bootstrap.sh)"
    exit 1
  fi

  echo ">> Sistema base + Python + ffmpeg..."
  apt update
  apt install -y curl git tmux build-essential unzip ca-certificates \
                 python3 python3-pip python3-venv \
                 ffmpeg lsof jq sshpass gnupg

  # Node 22 via nvm (OpenClaw exige Node 22.19+; 24 recomendado)
  if ! command -v node &> /dev/null || [[ "$(node -v 2>/dev/null)" != v2[2-9]* ]]; then
    echo ">> Instalando nvm + Node 22..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 22
    nvm use 22
    nvm alias default 22

    # Symlinks globais pra systemd / cron acharem o node
    ln -sf "$NVM_DIR/versions/node/$(nvm version)/bin/node" /usr/local/bin/node
    ln -sf "$NVM_DIR/versions/node/$(nvm version)/bin/npm" /usr/local/bin/npm
    ln -sf "$NVM_DIR/versions/node/$(nvm version)/bin/npx" /usr/local/bin/npx
  fi

  # OpenClaw CLI ORIGINAL (ultima versao)
  echo ">> Instalando OpenClaw CLI original (openclaw@2026.6.5)..."
  npm install -g openclaw@2026.6.5

  # Symlink global do openclaw pra systemd / cron
  NPM_BIN="$(npm config get prefix)/bin"
  [ -x "$NPM_BIN/openclaw" ] && ln -sf "$NPM_BIN/openclaw" /usr/local/bin/openclaw

  # Baixa SETUP-AGENTE.md pra /root/
  echo ">> Baixando SETUP-AGENTE.md..."
  curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/SETUP-AGENTE.md \
    -o /root/SETUP-AGENTE.md
  curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/.env.example \
    -o /root/.env.example 2>/dev/null || true

  mkdir -p /root/.openclaw
  chmod 700 /root/.openclaw

  HOME_DIR="/root"
fi

# ============================================
# MACOS
# ============================================
if [[ "$OS" == "macos" ]]; then
  if [[ "$EUID" -eq 0 ]]; then
    echo "ERRO: NAO rode como root no Mac. Roda como seu usuario normal."
    exit 1
  fi

  if ! command -v brew &> /dev/null; then
    echo ">> Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  echo ">> Instalando dependencias via Homebrew..."
  brew install python@3.11 ffmpeg tmux jq 2>/dev/null || \
    brew install python@3.11 ffmpeg tmux jq

  if ! command -v node &> /dev/null || [[ "$(node -v 2>/dev/null)" != v2[2-9]* ]]; then
    echo ">> Instalando nvm + Node 22..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 22
    nvm alias default 22
  fi

  echo ">> Instalando OpenClaw CLI original..."
  npm install -g openclaw@2026.6.5

  mkdir -p $HOME/.openclaw
  chmod 700 $HOME/.openclaw

  curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/SETUP-AGENTE.md \
    -o $HOME/SETUP-AGENTE.md
  curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/.env.example \
    -o $HOME/.env.example 2>/dev/null || true

  HOME_DIR="$HOME"
fi

# ============================================
# RESUMO FINAL
# ============================================
echo ""
echo "============================================"
echo "OK! OpenClaw puro instalado."
echo "============================================"
echo ""
echo "VERSOES:"
node --version 2>/dev/null    | xargs echo "  Node:"
python3 --version 2>/dev/null | xargs echo "  Python:"
ffmpeg -version 2>/dev/null | head -1 | xargs echo "  ffmpeg:"
openclaw --version 2>/dev/null | head -1 | xargs echo "  OpenClaw:"
echo ""
echo "============================================"
echo "PROXIMOS PASSOS (ver SETUP-AGENTE.md):"
echo "============================================"
echo "1. Criar /root/.openclaw/openclaw.json com o canal Telegram (ETAPA 2)"
echo "2. Autenticar o LLM escolhido (ETAPA 3):"
echo "   - GLM (Z.ai): cola a API key e 'openclaw models set zai/glm-5-turbo'"
echo "   - GPT Codex 5.5: 'openclaw models auth login --provider openai --device-code'"
echo "     (OAuth no navegador, sem API key, gasta da assinatura ChatGPT Plus)"
echo "3. Subir o systemd 'openclaw-gateway' (ETAPA 5)"
echo "4. Mandar /start no bot do Telegram (ETAPA 6)"
echo ""
echo "Doc oficial do OpenClaw: https://docs.openclaw.ai"
echo "============================================"
