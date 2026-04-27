#!/bin/bash
# ============================================
# BOOTSTRAP DO AGENTE OPENCLAW + TELEGRAM v1
# ============================================
# Roda UMA VEZ SO numa VPS Ubuntu 22+ ou no macOS.
# Linux: roda como root (sudo bash ou ja como root)
# Mac: roda como usuario normal (sem sudo na chamada)
#
# Instala: Node 22 (via nvm), Python 3, ffmpeg, OpenClaw CLI 2026.4.24,
#          Claude Code CLI 2.1.81 (auth backup pra fallback Anthropic),
#          tmux, PostgreSQL 16 + pgvector, pnpm, pm2 globalmente.
#
# v1: baseline das KVMs do {{DONO}}.
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/bootstrap.sh | bash
# ============================================

set -e

# Detecta SO
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ -f /etc/os-release ]] && grep -q "Ubuntu" /etc/os-release; then
  OS="ubuntu"
else
  echo "ERRO: SO nao suportado. Precisa Ubuntu 22+ ou macOS 13+."
  exit 1
fi

echo "============================================"
echo "BOOTSTRAP AGENTE OPENCLAW + TELEGRAM v1 ($OS)"
echo "============================================"

# ============================================
# UBUNTU
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
                 ffmpeg lsof jq sshpass debian-keyring debian-archive-keyring apt-transport-https \
                 software-properties-common gnupg

  pip3 install --break-system-packages requests psycopg2-binary anthropic openai 2>/dev/null || \
    pip3 install requests psycopg2-binary anthropic openai

  # Node 22 via nvm
  if ! command -v node &> /dev/null || [[ "$(node -v)" != v2[2-9]* ]]; then
    echo ">> Instalando nvm + Node 22..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 22
    nvm use 22
    nvm alias default 22

    ln -sf "$NVM_DIR/versions/node/$(nvm version)/bin/node" /usr/local/bin/node
    ln -sf "$NVM_DIR/versions/node/$(nvm version)/bin/npm" /usr/local/bin/npm
    ln -sf "$NVM_DIR/versions/node/$(nvm version)/bin/npx" /usr/local/bin/npx
  fi

  # PostgreSQL 16 + pgvector
  if ! command -v psql &> /dev/null; then
    echo ">> Instalando PostgreSQL 16 + pgvector..."
    install -d /usr/share/postgresql-common/pgdg
    curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
      --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" \
      > /etc/apt/sources.list.d/pgdg.list
    apt update
    apt install -y postgresql-16 postgresql-16-pgvector
    systemctl enable --now postgresql
  fi

  # OpenClaw CLI (PINADO 2026.4.24)
  echo ">> Instalando OpenClaw CLI 2026.4.24..."
  npm install -g openclaw@2026.4.24

  # Claude Code CLI (auth backup pra fallback anthropic/claude-opus-4-6)
  echo ">> Instalando Claude Code CLI 2.1.81 (auth backup)..."
  npm install -g @anthropic-ai/claude-code@2.1.81

  # PM2 + pnpm
  echo ">> Instalando pm2 + pnpm..."
  npm install -g pm2 pnpm playwright

  # Playwright browsers (necessario pro browser tool do OpenClaw)
  npx playwright install chromium 2>/dev/null || true

  # Baixa SETUP-AGENTE.md pra /root/
  echo ">> Baixando SETUP-AGENTE.md..."
  curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/SETUP-AGENTE.md \
    -o /root/SETUP-AGENTE.md
  curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/.env.example \
    -o /root/.env.example

  # Cria estrutura base
  mkdir -p /root/.openclaw/{workspace,cron,delivery-queue,credentials,flows,logs,media,telegram}
  chmod -R 700 /root/.openclaw

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
  brew install python@3.11 ffmpeg tmux postgresql@16 pgvector jq sshpass 2>/dev/null || \
    brew install python@3.11 ffmpeg tmux postgresql@16 pgvector jq

  if ! command -v node &> /dev/null || [[ "$(node -v)" != v2[2-9]* ]]; then
    echo ">> Instalando nvm + Node 22..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 22
    nvm alias default 22
  fi

  brew services start postgresql@16

  pip3 install --user requests psycopg2-binary anthropic openai

  echo ">> Instalando OpenClaw CLI + Claude Code CLI + pm2 + pnpm..."
  npm install -g openclaw@2026.4.24 @anthropic-ai/claude-code@2.1.81 pm2 pnpm playwright

  npx playwright install chromium 2>/dev/null || true

  mkdir -p $HOME/.openclaw/{workspace,cron,delivery-queue,credentials,flows,logs,media,telegram}
  chmod -R 700 $HOME/.openclaw

  curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/SETUP-AGENTE.md \
    -o $HOME/SETUP-AGENTE.md
  curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/.env.example \
    -o $HOME/.env.example

  HOME_DIR="$HOME"
fi

# ============================================
# RESUMO FINAL
# ============================================
echo ""
echo "============================================"
echo "OK! Pre-requisitos instalados (v1)."
echo "============================================"
echo ""
echo "VERSOES INSTALADAS:"
node --version 2>/dev/null   | xargs echo "  Node:"
python3 --version 2>/dev/null | xargs echo "  Python:"
ffmpeg -version 2>/dev/null | head -1 | xargs echo "  ffmpeg:"
openclaw --version 2>/dev/null | head -1 | xargs echo "  OpenClaw:"
claude --version 2>/dev/null | xargs echo "  Claude Code:"
psql --version 2>/dev/null | head -1 | xargs echo "  PostgreSQL:"
pm2 --version 2>/dev/null | xargs echo "  pm2:"
pnpm --version 2>/dev/null | xargs echo "  pnpm:"
echo ""
echo "============================================"
echo "PROXIMOS PASSOS:"
echo "============================================"
echo ""
echo "1. Escolher backend de LLM:"
echo "   - GLM (Z.ai, mais barato): so cola sua API key na ETAPA 4 do SETUP"
echo "   - GPT Codex 5.5 (OpenAI, mais robusto): roda 'openclaw configure'"
echo "     e segue OAuth. Precisa ChatGPT Plus + Codex liberado."
echo ""
echo "2. (Opcional) Logar na conta Claude pra usar fallback Anthropic:"
echo "   claude auth login --claudeai"
echo ""
echo "3. Iniciar o Claude Code (ou outro agente) e seguir SETUP-AGENTE.md:"
echo "   cd $HOME_DIR && claude --dangerously-skip-permissions"
echo ""
echo "4. Dentro do Claude, cola essa mensagem:"
echo ""
echo "   Leia o arquivo SETUP-AGENTE.md e execute todos os passos."
echo "   Vou te dizer qual LLM escolher (GLM ou GPT Codex) e te dar os tokens."
echo ""
echo "============================================"
