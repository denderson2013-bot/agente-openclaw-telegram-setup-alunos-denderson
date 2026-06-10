#!/bin/bash
# ============================================
# Configurador GLM 4.5/5 Turbo (Z.ai) -- OpenClaw original puro
# ============================================
# GLM e um provider OpenAI-compativel custom.
# Uso:
#   ZAI_API_KEY=xx.xxx-xxx bash scripts/configure-glm.sh
# ============================================

set -e

if [[ -z "$ZAI_API_KEY" ]]; then
    echo "ERRO: ZAI_API_KEY nao definido."
    echo "Uso: ZAI_API_KEY=xx.xxx-xxx bash scripts/configure-glm.sh"
    exit 1
fi

echo ">> Adicionando provider zai (OpenAI-compativel) + modelos via config patch..."
cat > /tmp/oc-zai.json <<JSON
{
  "models": {
    "providers": {
      "zai": {
        "baseUrl": "https://api.z.ai/api/coding/paas/v4",
        "apiKey": "$ZAI_API_KEY",
        "api": "openai-completions",
        "models": [
          {"id": "glm-5-turbo", "name": "GLM-5-Turbo", "input": ["text"], "contextWindow": 204800, "maxTokens": 131072},
          {"id": "glm-5.1", "name": "GLM-5.1", "input": ["text"], "contextWindow": 204800, "maxTokens": 131072}
        ]
      }
    }
  }
}
JSON
openclaw config patch --file /tmp/oc-zai.json
rm -f /tmp/oc-zai.json
openclaw config validate || true

echo ">> Definindo zai/glm-5-turbo como primary + fallback glm-5.1..."
openclaw models set zai/glm-5-turbo
openclaw models fallbacks add zai/glm-5.1 2>/dev/null || true

echo ">> Restart gateway..."
systemctl restart openclaw-gateway 2>/dev/null || true
sleep 3

echo ">> Validando..."
openclaw models status --probe || true

echo ""
echo "OK! GLM 5-Turbo agora e o LLM primary."
echo "Pra trocar pra GPT Codex no futuro: bash scripts/configure-gpt-codex.sh"
