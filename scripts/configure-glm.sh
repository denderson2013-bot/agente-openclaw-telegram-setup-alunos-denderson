#!/bin/bash
# ============================================
# Configurador GLM 4.5/5 Turbo (Z.ai)
# ============================================
# Uso:
#   ZAI_API_KEY=sk-xxx bash scripts/configure-glm.sh
# ============================================

set -e

if [[ -z "$ZAI_API_KEY" ]]; then
    echo "ERRO: ZAI_API_KEY nao definido."
    echo "Uso: ZAI_API_KEY=sk-xxx bash scripts/configure-glm.sh"
    exit 1
fi

echo ">> Configurando provider zai..."
openclaw config set models.providers.zai.baseUrl "https://api.z.ai/api/coding/paas/v4"
openclaw config set models.providers.zai.apiKey "$ZAI_API_KEY"
openclaw config set models.providers.zai.api "openai-completions"

echo ">> Definindo zai/glm-5-turbo como primary..."
openclaw config set agents.defaults.model.primary "zai/glm-5-turbo"
openclaw config set agents.defaults.model.fallbacks '["zai/glm-5.1", "zai/glm-5"]'

echo ">> Auth profile zai:default..."
openclaw config set 'auth.profiles.zai:default.provider' "zai"
openclaw config set 'auth.profiles.zai:default.mode' "api_key"

echo ">> Restart gateway..."
systemctl restart openclaw-gateway
sleep 3

echo ">> Validando..."
openclaw infer simple --model zai/glm-5-turbo --prompt "Responde com OK em portugues."

echo ""
echo "OK! GLM 5-Turbo agora e o LLM primary."
echo "Pra trocar pra GPT Codex no futuro: bash scripts/configure-gpt-codex.sh"
