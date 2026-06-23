# GLM vs GPT Codex - Comparativo Completo

## Resumo executivo

| Aspecto | GLM 4.5/5 Turbo (Z.ai) | GPT Codex 5.5 |
|---|---|---|
| **Auth** | api_key direta | OAuth (ChatGPT Plus) |
| **Modelo primary recomendado** | `zai/glm-5-turbo` | `openai-codex/gpt-5.5` |
| **Custo mensal medio** | US$50-80 | US$200 |
| **Velocidade P50** | 2-4s | 3-6s |
| **Qualidade copy/codigo** | excelente em PT-BR | top-tier global |
| **Context window** | 200k | 1M |
| **Reasoning** | so glm-5/4.7 | sim, sempre |
| **Vision/imagem** | so `glm-4.6v` | sim |
| **Confiabilidade** | media (oscila as vezes) | alta |
| **Setup** | facil (so cola key) | medio (precisa OAuth + Codex liberado) |
| **Pra quem** | Aluno comecando, SDRs, automacao alta volume | Producao, orquestrador, lancamento |

## Quando usar GLM

- Voce ta comecando agora e quer minimizar custo
- A maior parte das chamadas e geracao de copy ou codigo (GLM e exelente nisso)
- Voce roda muitos SDRs em paralelo (volume alto, custo importa)
- Mensagens curtas/medias (ate 30k tokens de contexto)
- Voce ja tem assinatura Z.ai paga

## Quando usar GPT Codex

- Voce esta em producao com cliente real
- O agente e orquestrador (precisa raciocinar bem antes de delegar)
- Tarefas complexas com >100k tokens de contexto
- Voce ja tem ChatGPT Plus + Codex liberado
- Confiabilidade > custo

## Hibrido (recomendado pra producao)

Roda os 2 simultaneos. Define agentes mais criticos com GPT, e SDRs/operacionais com GLM:

```
main (Naia)            -> GPT Codex 5.5     (orquestracao critica)
juliana (sub-gerente)  -> GPT Codex 5.5     (coordena com qualidade)
paulo (dev)            -> GLM-5.1           (codigo, GLM e otimo)
jonathan (copy)        -> GLM-5.1           (copy em PT-BR)
rafael (projetos)      -> GLM-5-Turbo       (rapido)
clone-{{DONO_SLUG}}    -> GLM-5-Turbo       (Meta Ads, criativos)
7 SDRs                 -> GLM-5-Turbo       (volume alto, custo importa)
```

Custo desse setup: ~US$120-150/mes total (orquestracao GPT + execucao GLM).

## Como configurar cada modelo num agente diferente

Edita `/root/.openclaw/openclaw.json`, secao `agents.list[]`:

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "model": "openai-codex/gpt-5.5"
      },
      {
        "id": "paulo",
        "model": "zai/glm-5.1"
      },
      ...
    ]
  }
}
```

Reinicia o gateway:
```bash
systemctl restart openclaw-gateway
```

E so. Cada agente passa a usar seu LLM dedicado.

## Fallback chain

Independente do primary, sempre defina fallbacks pra resiliencia:

```bash
# Se GLM principal:
openclaw config set agents.defaults.model.fallbacks '["zai/glm-5.1", "anthropic/claude-opus-4-6"]'

# Se GPT principal:
openclaw config set agents.defaults.model.fallbacks '["zai/glm-5-turbo", "anthropic/claude-opus-4-6"]'
```

Quando o primary falha (rate limit, network, modelo offline), OpenClaw automaticamente tenta o proximo da lista, sem perder a sessao.
