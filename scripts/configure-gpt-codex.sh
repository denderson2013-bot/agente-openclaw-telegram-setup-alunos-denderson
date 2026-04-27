#!/bin/bash
# ============================================
# Configurador GPT Codex 5.5 (OpenAI Codex via OAuth)
# ============================================
# Pre-req: ChatGPT Plus + Codex API liberado.
# Uso:
#   bash scripts/configure-gpt-codex.sh
# ============================================

set -e

echo ">> Iniciando OAuth pro openai-codex..."
echo "(Se ja autenticou antes, pula essa etapa.)"
echo ""
echo "Passo 1: roda 'openclaw configure' interativamente"
echo "Passo 2: escolhe provider 'openai-codex' / mode 'oauth'"
echo "Passo 3: copia URL impressa, abre no navegador, autoriza"
echo "Passo 4: cola o codigo de retorno"
echo ""
read -p "Pressiona ENTER quando estiver pronto pra rodar 'openclaw configure'..."

openclaw configure || true

echo ""
echo ">> Validando profile openai-codex..."
if ! openclaw config get auth.profiles 2>/dev/null | grep -q "openai-codex"; then
    echo "ERRO: profile openai-codex nao foi criado. Volta e refaz o configure."
    exit 1
fi

echo ">> Definindo openai-codex/gpt-5.5 como primary..."
openclaw config set agents.defaults.model.primary "openai-codex/gpt-5.5"
openclaw config set agents.defaults.model.fallbacks '["anthropic/claude-opus-4-6"]'

echo ">> (Opcional) Garantir que claude-cli profile existe pra fallback..."
if ! openclaw config get auth.profiles 2>/dev/null | grep -q "anthropic:claude-cli"; then
    echo ""
    echo "AVISO: Voce ainda nao autenticou no Claude (Anthropic). Pra usar fallback claude-opus-4-6:"
    echo "  claude auth login --claudeai"
    echo "Depois roda esse script de novo."
fi

echo ">> Restart gateway..."
systemctl restart openclaw-gateway
sleep 3

echo ">> Validando..."
openclaw infer simple --model openai-codex/gpt-5.5 --prompt "Responde com OK em portugues." || true

echo ""
echo "OK! GPT Codex 5.5 agora e o LLM primary."
echo "Pra voltar pra GLM no futuro: bash scripts/configure-glm.sh"
