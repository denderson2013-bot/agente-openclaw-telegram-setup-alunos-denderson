#!/bin/bash
# ============================================
# Setup canal Telegram
# ============================================
# Uso:
#   TG_BOT_TOKEN="123:AAA..." TG_USER_ID="629399338" bash scripts/setup-telegram.sh
# ============================================

set -e

if [[ -z "$TG_BOT_TOKEN" || -z "$TG_USER_ID" ]]; then
    echo "ERRO: TG_BOT_TOKEN e TG_USER_ID sao obrigatorios."
    echo "Uso: TG_BOT_TOKEN=xxx TG_USER_ID=yyy bash scripts/setup-telegram.sh"
    exit 1
fi

echo ">> Configurando channels.telegram..."
openclaw config set channels.telegram.enabled true
openclaw config set channels.telegram.dmPolicy "allowlist"
openclaw config set channels.telegram.botToken "$TG_BOT_TOKEN"
openclaw config set channels.telegram.allowFrom "[\"$TG_USER_ID\"]"
openclaw config set channels.telegram.groupPolicy "allowlist"
openclaw config set channels.telegram.streaming.mode "partial"
openclaw config set channels.telegram.actions.reactions true

echo ">> Habilitando plugin telegram..."
openclaw config set plugins.entries.telegram.enabled true

echo ">> Restart gateway..."
systemctl restart openclaw-gateway
sleep 3

echo ">> Validando..."
openclaw channels list
openclaw doctor

echo ""
echo "OK! Telegram configurado."
echo "Manda /start no seu bot pra testar."
