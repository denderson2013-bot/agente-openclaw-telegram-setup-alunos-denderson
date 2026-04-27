# Migracao GLM <-> GPT Codex (sem reinstalar nada)

OpenClaw permite trocar o backend LLM em runtime, sem reinstalar nada. Voce ja tem o agente rodando e quer testar outro LLM, ou precisa migrar de GLM (gratis) pra GPT (pago) porque cresceu, ou vice-versa pra cortar custo. Tudo isso e questao de mudar 2 linhas.

## De GLM pra GPT Codex 5.5

1. Garante que voce tem ChatGPT Plus + Codex liberado.
2. Faz OAuth do openai-codex:
   ```bash
   openclaw configure
   # Provider: openai-codex
   # Mode: oauth
   # Segue browser flow
   ```
3. Troca o primary:
   ```bash
   openclaw config set agents.defaults.model.primary "openai-codex/gpt-5.5"
   openclaw config set agents.defaults.model.fallbacks '["zai/glm-5-turbo", "anthropic/claude-opus-4-6"]'
   ```
4. Restart:
   ```bash
   systemctl restart openclaw-gateway
   ```
5. Valida:
   ```bash
   openclaw infer simple --model openai-codex/gpt-5.5 --prompt "OK?"
   ```

A configuracao GLM continua presente no `openclaw.json` (Z.ai como fallback). Se Codex cair, o agente automaticamente usa GLM.

## De GPT Codex pra GLM

1. Garante que voce tem API key Z.ai com credito:
   ```bash
   openclaw config set models.providers.zai.apiKey "$ZAI_API_KEY"
   openclaw config set models.providers.zai.baseUrl "https://api.z.ai/api/coding/paas/v4"
   openclaw config set models.providers.zai.api "openai-completions"
   ```
2. Troca o primary:
   ```bash
   openclaw config set agents.defaults.model.primary "zai/glm-5-turbo"
   openclaw config set agents.defaults.model.fallbacks '["zai/glm-5.1", "openai-codex/gpt-5.5"]'
   ```
3. Restart:
   ```bash
   systemctl restart openclaw-gateway
   ```

## Rodando os dois ao mesmo tempo (multi-agent)

Voce pode ter agente principal rodando GPT (`main`) e algum subagente rodando GLM pra economizar:

```bash
# Edita openclaw.json, secao agents.list[]
# Acha o agent paulo (ou outro) e troca o model:
#   "model": "zai/glm-5.1"   <-- subagente rodando GLM
# Mantem main em GPT Codex
systemctl restart openclaw-gateway
```

Padrao recomendado pra economizar:
- `main` (Naia) -> `openai-codex/gpt-5.5` (precisa qualidade pra orquestrar)
- `juliana` (sub-gerente) -> `openai-codex/gpt-5.5` (precisa qualidade)
- `paulo`, `jonathan` -> `zai/glm-5.1` (codigo e copy, GLM e top)
- `rafael`, `{{DONO}} Clone` -> `zai/glm-5-turbo` (gestor e clone, rapido)
- 7 SDRs -> `zai/glm-5-turbo` (vendas via WhatsApp, GLM e otimo em PT-BR)

Esse setup mistura GPT na orquestracao + GLM na execucao. Custo mensal cai pra **US$120-150** com qualidade alta na entrega.

## Backup antes de migrar

OpenClaw faz backup automatico de `openclaw.json` antes de cada save:
```
/root/.openclaw/openclaw.json.bak.1
/root/.openclaw/openclaw.json.bak.2
/root/.openclaw/openclaw.json.last-good
```

Se algo quebrar:
```bash
cp /root/.openclaw/openclaw.json.last-good /root/.openclaw/openclaw.json
systemctl restart openclaw-gateway
```

## Diferencas operacionais (importante saber antes de migrar)

| Aspecto | GLM | GPT Codex |
|---|---|---|
| Streaming | partial (chunks parciais) | partial |
| Tool calling | nativo | nativo |
| Image input | nao (so glm-4.6v) | sim (vision) |
| Reasoning explicito | so glm-5/4.7 | sim |
| Context window | 200k tokens | 1M tokens |
| Custo medio mensal | US$50-80 | US$200 |
| OAuth dependency | nao (api_key) | sim (browser) |
| Latencia P50 | 2-4s | 3-6s |
| Confiabilidade | media | alta |
| Suporta `gemini-3-pro-image-preview` (image gen)? | sim (via Google provider, separado) | sim |

## Quando trocar pra qual

- **Cliente novo, comeca pequeno** -> GLM (US$50-80/mes, da pra rodar 30 dias antes de avaliar custo)
- **Lancamento ou tarefa critica** -> GPT (qualidade > custo)
- **SDR de venda WhatsApp** -> GLM (custo importa, GLM e otimo em PT-BR)
- **Naia principal em producao** -> GPT (orquestracao precisa qualidade top)
