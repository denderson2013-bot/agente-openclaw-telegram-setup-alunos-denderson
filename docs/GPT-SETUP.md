# GPT Codex 5.5 Setup (OpenAI Codex CLI)

## O que e GPT Codex 5.5

GPT Codex 5.5 e o modelo proprietario da OpenAI otimizado pra coding e raciocinio em contexto longo. No OpenClaw, ele e exposto via provider `openai-codex` que usa OAuth (login com sua conta ChatGPT Plus + API Codex liberada).

| Modelo | Reasoning | Context | Notas |
|---|---|---|---|
| `gpt-5.5` | sim | 1M tokens | Top tier, pra producao |
| `gpt-5.4` | sim | 400k tokens | Versao anterior, ainda excelente |

## Pre-requisitos

1. Assinatura **ChatGPT Plus** (US$20/mes minimo, podem exigir Pro pra Codex)
2. Acesso liberado a **Codex API** (solicitar em [chatgpt.com/codex](https://chatgpt.com/codex))
3. OpenClaw 2026.4.24+ instalado
4. Browser disponivel pra primeiro OAuth (PC do dono)

## Configuracao via OAuth

Roda na VPS:

```bash
openclaw configure
# Escolhe: provider openai-codex
# Mode: oauth
# A CLI imprime URL pra abrir no navegador
```

Aluno copia a URL, abre no navegador do PC dele, loga com ChatGPT Plus, autoriza, copia o code de retorno e cola no terminal da VPS. OpenClaw guarda o token em `/root/.openclaw/credentials/openai-codex/`.

Apos sucesso:

```bash
openclaw config get auth.profiles
# Deve mostrar profile "openai-codex:<email>" presente
```

## Definir como primary

```bash
openclaw config set agents.defaults.model.primary "openai-codex/gpt-5.5"
openclaw config set agents.defaults.model.fallbacks '["anthropic/claude-opus-4-6"]'
systemctl restart openclaw-gateway
```

> Por que ter `claude-opus-4-6` como fallback? Se o quota Codex acabar (raro mas acontece), o agente cai no Claude pra continuar funcionando. Pra usar esse fallback voce precisa rodar `claude auth login --claudeai` primeiro.

## openclaw.json equivalente

```json
{
  "auth": {
    "profiles": {
      "openai-codex:{{OPENAI_CODEX_OAUTH_EMAIL}}": {
        "provider": "openai-codex",
        "mode": "oauth"
      },
      "anthropic:claude-cli": {
        "provider": "claude-cli",
        "mode": "oauth"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai-codex/gpt-5.5",
        "fallbacks": ["anthropic/claude-opus-4-6"]
      },
      "models": {
        "openai-codex/gpt-5.5": {"alias": "codex"},
        "anthropic/claude-opus-4-6": {"alias": "opus"}
      }
    }
  }
}
```

## Validar

```bash
openclaw infer simple --model openai-codex/gpt-5.5 --prompt "Responde com OK em portugues."
```

```bash
openclaw doctor
```

## Custos reais (uso medio Naia)

ChatGPT Plus US$20 + cota Codex API consumida via uso. No projeto Naia interno, gasto medio com GPT-5.5 + GPT-5.4 ficou em **US$200/mes**.

## Troubleshooting

### "Token expired, please re-authenticate"
OAuth expirou (pode acontecer em refreshes longos):
```bash
openclaw configure
# refaz oauth pro openai-codex
```

### "Model not found"
Confirma que voce tem acesso liberado a Codex API:
- Loga em chatgpt.com/codex
- Verifica o status da feature flag

### "Rate limited"
Cota mensal estourada. Espera reset ou faz upgrade pra Pro.

### Fallback nao dispara
Verifica `agents.defaults.model.fallbacks`. Tem que ser array. Cada entry tem que estar autenticada.

## Como voltar pra GLM depois

Veja [`MIGRACAO.md`](./MIGRACAO.md).
