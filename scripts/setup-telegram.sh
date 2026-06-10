#!/bin/bash
# ============================================
# Setup canal Telegram -- OpenClaw original puro
# ============================================
# OpenClaw NAO tem 'channels add telegram'. O canal e configurado no openclaw.json.
# Uso:
#   TG_BOT_TOKEN="123:AAA..." TG_USER_ID="123456789" bash scripts/setup-telegram.sh
# ============================================

set -e

if [[ -z "$TG_BOT_TOKEN" || -z "$TG_USER_ID" ]]; then
    echo "ERRO: TG_BOT_TOKEN e TG_USER_ID sao obrigatorios."
    echo "Uso: TG_BOT_TOKEN=xxx TG_USER_ID=yyy bash scripts/setup-telegram.sh"
    exit 1
fi

echo ">> Configurando channels.telegram no openclaw.json..."
openclaw config set channels.telegram "{
  \"enabled\": true,
  \"botToken\": \"$TG_BOT_TOKEN\",
  \"dmPolicy\": \"allowlist\",
  \"allowFrom\": [\"$TG_USER_ID\"],
  \"groupPolicy\": \"allowlist\"
}" --strict-json --merge

echo ">> Restart gateway..."
systemctl restart openclaw-gateway 2>/dev/null || true
sleep 3

echo ">> Validando..."
openclaw doctor || true

echo ""
echo "OK! Telegram configurado (dmPolicy allowlist + seu user_id liberado)."
echo "Manda /start no seu bot pra testar."
