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

echo ">> Configurando channels.telegram via config patch (valida na escrita)..."
# Schema 2026.6.5: NAO escrever JSON na mao. dmPolicy/groupPolicy sao enums obrigatorios.
cat > /tmp/oc-telegram.json <<JSON
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "$TG_BOT_TOKEN",
      "dmPolicy": "allowlist",
      "groupPolicy": "allowlist",
      "allowFrom": ["$TG_USER_ID"]
    }
  }
}
JSON
openclaw config patch --file /tmp/oc-telegram.json
rm -f /tmp/oc-telegram.json

echo ">> Garantindo gateway.mode=local (obrigatorio, senao o gateway nem sobe)..."
openclaw config set gateway.mode local
openclaw config validate || true

echo ">> Restart gateway..."
systemctl restart openclaw-gateway 2>/dev/null || true
sleep 3

echo ">> Validando..."
openclaw doctor || true

echo ""
echo "OK! Telegram configurado (dmPolicy allowlist + seu user_id liberado)."
echo "Manda /start no seu bot pra testar."
