# Subagents

12 subagentes que rodam debaixo da Naia (agente principal `main`).

| Arquivo | Subagente | Especialidade | Modelo recomendado |
|---|---|---|---|
| `paulo-dev.md` | Paulo | Dev full-stack, APIs, deploy | GLM-5.1 ou GPT Codex |
| `juliana-ops.md` | Juliana | Sub-gerente, design, processos | GPT Codex (precisa qualidade) |
| `jonathan-copy.md` | Jonathan | Copywriter, roteiros | GLM-5.1 (otimo PT-BR) |
| `rafael-projetos.md` | Rafael | Gestao de projetos | GLM-5-Turbo |
| `dono-clone.md` | {{DONO}} Clone | Trafego pago, Meta Ads | GLM-5-Turbo |
| `dono-clone-dm.md` | {{DONO}} Clone DM | Responder DMs Insta | GLM-5-Turbo |
| `davi-sdr.md` | Davi | SDR vendas | GLM-5-Turbo |
| `lucas-sdr.md` | Lucas | SDR vendas | GLM-5-Turbo |
| `felipe-sdr.md` | Felipe | SDR vendas | GLM-5-Turbo |
| `matheus-sdr.md` | Matheus | SDR vendas | GLM-5-Turbo |
| `amanda-sdr.md` | Amanda | SDR vendas | GLM-5-Turbo |
| `carolina-sdr.md` | Carolina | SDR vendas | GLM-5-Turbo |
| `bianca-sdr.md` | Bianca | SDR vendas | GLM-5-Turbo |
| `amanda-crm.md` | Amanda CRM | Gestao do {{PRODUTO_DONO}} | GLM-5-Turbo |

## Como o OpenClaw usa esses arquivos

OpenClaw nao le esses .md diretamente como o Claude Code. Em vez disso, voce coloca o conteudo de cada `.md` no `systemPrompt` correspondente em `openclaw.json` agents.list[].

O setup no `SETUP-AGENTE.md` (ETAPA 5) faz isso automaticamente: copia o `agents/<nome>.md` pra `/root/.openclaw/workspace-<nome>/SOUL.md`, e o agente le esse SOUL.md como sistema prompt na boot.

Se quiser editar a personalidade de algum subagente, edita o arquivo correspondente em `/root/.openclaw/workspace-<nome>/SOUL.md`. Nao precisa restart, OpenClaw le na proxima sessao.
