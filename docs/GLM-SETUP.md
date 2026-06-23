# GLM 4.5/5 Turbo Setup (Z.ai)

## O que e GLM

GLM e a familia de modelos da Z.ai (Zhipu AI), focada em geracao de codigo e copy. Modelos disponiveis no OpenClaw:

| Modelo | Reasoning | Context | Custo input | Custo output | Recomendacao |
|---|---|---|---|---|---|
| `glm-5-turbo` | nao | 200k | gratis (limite mensal) | gratis | Default rapido |
| `glm-5.1` | nao | 200k | gratis | gratis | Quando precisa qualidade sem reasoning |
| `glm-5` | sim | 200k | $1/M | $3.2/M | Reasoning pesado |
| `glm-4.7` | sim | 200k | $0.6/M | $2.2/M | Reasoning balanceado |
| `glm-4.7-flash` | sim | 200k | $0.07/M | $0.4/M | Mais barato com reasoning |

## Pre-requisitos

1. Conta paga em [z.ai](https://z.ai)
2. API key gerada no painel
3. OpenClaw 2026.4.24+ instalado (`bootstrap.sh` ja faz isso)

## Configuracao via openclaw.json

Edita `/root/.openclaw/openclaw.json`, secao `models.providers.zai`:

```json
{
  "models": {
    "providers": {
      "zai": {
        "baseUrl": "https://api.z.ai/api/coding/paas/v4",
        "apiKey": "{{ZAI_API_KEY}}",
        "api": "openai-completions",
        "models": [
          {"id": "glm-5-turbo", "contextWindow": 204800, "maxTokens": 131072},
          {"id": "glm-5.1", "contextWindow": 204800, "maxTokens": 131072},
          {"id": "glm-5", "reasoning": true, "contextWindow": 202800, "maxTokens": 131100}
        ]
      }
    }
  },
  "auth": {
    "profiles": {
      "zai:default": {
        "provider": "zai",
        "mode": "api_key"
      }
    }
  }
}
```

E define o modelo primary do agente:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "zai/glm-5-turbo",
        "fallbacks": ["zai/glm-5.1", "zai/glm-5"]
      }
    }
  }
}
```

## Configuracao via CLI

Mais facil:

```bash
openclaw config set models.providers.zai.baseUrl "https://api.z.ai/api/coding/paas/v4"
openclaw config set models.providers.zai.apiKey "$ZAI_API_KEY"
openclaw config set models.providers.zai.api "openai-completions"
openclaw config set agents.defaults.model.primary "zai/glm-5-turbo"
openclaw config set agents.defaults.model.fallbacks '["zai/glm-5.1", "zai/glm-5"]'
systemctl restart openclaw-gateway
```

## Validar

```bash
openclaw infer simple --model zai/glm-5-turbo --prompt "Responde com OK em portugues."
```

Deve responder algo tipo "OK".

```bash
openclaw config get auth.profiles
# Deve mostrar zai:default presente

openclaw doctor
# Deve passar em todos os checks
```

## Custos reais (uso medio Naia)

GLM-5-Turbo + GLM-5.1 cobrem 90% dos casos sem custo (limite mensal generoso da Z.ai). Pra fallback em reasoning, GLM-5 cobra ~US$3/M output. No uso medio do projeto Naia (~10M tokens/mes mistos), ficou em **US$50-80/mes**.

## Troubleshooting

### Erro 401/403
API key invalida ou sem credito. Recarrega no painel z.ai.

### Erro de baseUrl
Confirma que e exatamente `https://api.z.ai/api/coding/paas/v4` (com `/coding/paas/v4` no final). E o endpoint da API Coding (compativel com OpenAI completions).

### Erro "model not found"
Confirma que o id no `models[]` bate com o `primary`. Ex: se primary e `zai/glm-5-turbo`, tem que ter `{"id": "glm-5-turbo"}` no array.

### Resposta vazia ou timeout
Z.ai as vezes oscila. Configura fallback chain: `["zai/glm-5.1", "anthropic/claude-opus-4-6"]` pra resilencia.

## Como migrar pra GPT Codex depois

Veja [`MIGRACAO.md`](./MIGRACAO.md). E so trocar `agents.defaults.model.primary` e reiniciar o gateway.
