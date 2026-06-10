#!/bin/bash
# ============================================
# Configurador GPT Codex 5.5 (OpenAI via OAuth) -- OpenClaw original puro
# ============================================
# O provider no OpenClaw e 'openai' (rota Codex/subscription roda pelo plugin codex nativo).
# A auth e via OAuth, consumindo da quota da assinatura ChatGPT Plus do aluno.
# NAO existe "API key pra Codex CLI". Nao procure.
# Uso:
#   bash scripts/configure-gpt-codex.sh
# ============================================

set -e

echo ">> Login OAuth pro provider openai (device-code, ideal pra VPS headless)..."
echo ""
echo "Como funciona:"
echo "  1. O comando abaixo imprime uma URL (e as vezes um codigo)."
echo "  2. Copia a URL e cola no navegador do seu PC, JA LOGADO no ChatGPT Plus."
echo "  3. Autoriza (se aparecer codigo, digita o codigo na pagina)."
echo "  4. O CLI da VPS detecta sozinho. Nao precisa colar nada de volta."
echo ""
echo "NAO procure por 'API key pra Codex'. Nao existe. So OAuth via assinatura."
echo ""
read -p "Pressiona ENTER pra iniciar o login..."

openclaw models auth login --provider openai --device-code || true

echo ""
echo "(o CLI imprime a URL https://auth.openai.com/codex/device + um Code, ex EDYT-MLUDG;"
echo " abre a URL no PC logado no ChatGPT Plus, digita o code, autoriza."
echo " o CLI detecta sozinho e imprime 'OpenAI device code complete'.)"
echo ""
echo ">> Garantindo gateway.mode=local (obrigatorio)..."
openclaw config set gateway.mode local
openclaw config validate || true

echo ">> Definindo openai/gpt-5.5 como primary..."
openclaw models set openai/gpt-5.5

echo ">> Restart gateway..."
systemctl restart openclaw-gateway 2>/dev/null || true
sleep 3

echo ">> Validando..."
openclaw models status --probe || true

echo ""
echo "OK! GPT Codex 5.5 (openai/gpt-5.5) agora e o LLM primary."
echo "Pra voltar pra GLM no futuro: ZAI_API_KEY=xxx bash scripts/configure-glm.sh"
