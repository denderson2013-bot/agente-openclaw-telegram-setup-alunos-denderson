# Agente OpenClaw + Telegram - Setup Automatizado (versao publica pra alunos)

Suporta dois caminhos de LLM no mesmo agente:

- **GLM 4.5 Turbo (Z.ai)** -- mais barato (~US$80/mes), perfeito pra rodar 24/7
- **GPT Codex 5.5 (OpenAI Codex CLI)** -- mais robusto (~US$200/mes via ChatGPT Plus + API), recomendado pra producao

---

## INSTALACAO 5 MIN -- Sem mexer em terminal (caminho recomendado)

> **Voce nao precisa saber comando nenhum.** O Claude Code (ou outro agente) que voce usa no PC faz SSH na sua VPS automaticamente, instala o OpenClaw, configura GLM ou GPT como backend, sobe o agente. Voce so responde perguntas.

**6 passos:**

1. Compre uma VPS Ubuntu 22.04+ (Hostinger KVM4, Hetzner CX22, DigitalOcean -- 4-8GB RAM)
2. Anote IP, usuario (`root`) e senha que o provedor te mandou
3. Abra o Claude Code no seu PC ([claude.com/code](https://claude.com/code) ou Cursor IDE)
4. Cole o prompt magico de [`prompt-instalador.txt`](./prompt-instalador.txt)
5. Responda as perguntas (qual LLM, IP, tokens, nome do agente)
6. Quando o agente estiver no ar, abra o Telegram e converse

**Guia detalhado passo a passo:** [`INSTRUCAO-PARA-ALUNO.md`](./INSTRUCAO-PARA-ALUNO.md)

**Comparativo dos 2 LLMs:** [`docs/GLM-vs-GPT.md`](./docs/GLM-vs-GPT.md)

---

## Caminho avancado (manual, pra quem ja sabe terminal)

> **VERSAO PUBLICA -- ALUNOS DO {{DONO}}**
> Esse repo e a versao publica/sanitizada do setup interno do {{DONO}}. Todos os dados pessoais viraram placeholders no formato `{{NOME}}`. Voce, aluno, vai preencher com os SEUS proprios dados.
>
> Tabela completa em `SETUP-AGENTE.md` (ETAPA 0).

Instala um agente OpenClaw conectado ao Telegram em qualquer VPS Ubuntu 22+ ou macOS. Roda 24/7 via systemd, sobrevive reboots e auto-reinicia se cair. OpenClaw ja tem canal Telegram nativo (nao precisa de bot externo Python).

**v1 (abril 2026)** -- baseline das 2 KVMs do {{DONO}}:
- Agente principal (Naia) + 12 subagentes (jonathan, paulo, juliana, rafael, {{DONO_SLUG}}, davi, lucas, felipe, matheus, amanda, carolina, bianca)
- Backend LLM intercambiavel: GLM 4.5/5 Turbo OU GPT Codex 5.5
- Telegram, Discord, WhatsApp nativos do OpenClaw
- Memoria via plugin `openclaw-mem0` (pgvector + OpenAI embeddings)
- Audio bidirecional (Whisper entrada / ElevenLabs TTS saida)
- Workspace persistente em `/root/.openclaw/workspace`

## Uso

### 1. Na VPS limpa (Ubuntu 22.04+):

```bash
curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/bootstrap.sh | bash
```

Roda como `root`. Instala: Node 22 (via nvm), Python 3, ffmpeg, OpenClaw CLI (`openclaw@2026.4.24`), Claude Code CLI 2.1.81 (auth backup), tmux, PostgreSQL 16 + pgvector, pnpm, pm2 globalmente.

### 2. Escolher o backend de LLM (uma das duas opcoes):

**Opcao A -- GLM 4.5/5 Turbo via Z.ai (api_key, mais barato):**

1. Cria conta em [z.ai](https://z.ai) e gera uma API key paga.
2. Roda `openclaw configure` e adiciona o provider `zai` com baseUrl `https://api.z.ai/api/coding/paas/v4` e api `openai-completions`.
3. Define o modelo primario `zai/glm-5-turbo` (ou `glm-5.1` pra melhor qualidade).

**Opcao B -- GPT Codex 5.5 via OpenAI Codex CLI (oauth, mais robusto):**

1. Tem que ter ChatGPT Plus + API key liberada pra Codex.
2. Roda `openclaw configure` e adiciona o profile `openai-codex` com mode `oauth`.
3. Define o modelo primario `openai-codex/gpt-5.5`.
4. Como fallback, mantem `anthropic/claude-opus-4-6` (roda via Claude Code CLI ja instalado pelo bootstrap).

### 3. Iniciar o gateway OpenClaw:

```bash
systemctl enable --now openclaw-gateway
systemctl status openclaw-gateway
```

O gateway sobe na porta 18789 e mantem o Telegram polling vivo 24/7.

### 4. Mandar `/start` no bot do Telegram

Pronto. O agente responde, delega pros 12 subagentes quando precisa, e mantem memoria via mem0.

## Arquitetura v1

```
[Telegram]  <==>  [OpenClaw Gateway systemd 24/7 :18789]
                            |
                            v
                  [Backend LLM: GLM (Z.ai) OU GPT Codex 5.5 OU Claude Opus 4.6]
                            |
                            v
                  [Naia (main agent)]
                            |
            +----+----+----+--+----+----+----+----+----+----+----+----+
            v    v    v    v  v    v    v    v    v    v    v    v
         jona paulo jul rafa dend davi lucas feli math aman caro bianca
                            |
                            v
                  [openclaw-mem0 plugin -> pgvector]
                            |
                            v
                  [workspace /root/.openclaw/workspace]
```

5 camadas de resiliencia:
- OpenClaw gateway via systemd `Restart=always`
- Plugin Telegram polling continuo (independente do estado do agente)
- Plugin `openclaw-mem0` mantem memoria persistente entre sessoes
- Backup automatico de `openclaw.json` (`.bak.1`, `.bak.2`, `.last-good`)
- Heartbeat configuravel (default 1h)

## Recursos v1

- 12 subagentes especializados (config em `openclaw.json` + workspaces dedicados em `/root/.openclaw/workspace-<nome>`)
- Telegram + Discord + WhatsApp embutidos (canais nativos do OpenClaw)
- Memoria vetorial via `@mem0/openclaw-mem0` plugin (HNSW + pgvector + OpenAI embeddings)
- Audio entrada (Whisper) e saida (ElevenLabs) -- skills `openai-whisper-api` e TTS embutido
- Image gen integrado (Gemini 3 Pro Image Preview via skill `openai-image-gen`)
- Compaction automatico com soft threshold 8000 tokens
- Multi-profile (`--profile`) pra rodar 2 agentes na mesma VPS sem colidir
- `openclaw doctor` pra healthchecks rapidos

## Requisitos

- VPS Ubuntu 22.04+ (8 GB RAM, 50 GB disco recomendado, 4 GB minimo) **ou** macOS 13+
- Conta {{Z_AI_OU_CHATGPT_PLUS}} pra LLM:
  - **Opcao A:** API key Z.ai paga (~US$80/mes uso medio)
  - **Opcao B:** ChatGPT Plus US$20/mes + API com Codex 5.5 liberado (~US$200/mes uso medio)
- Conta Telegram (pra @BotFather)
- (Opcional) OpenAI API key pra audio Whisper + image gen + mem0 embeddings
- (Opcional) ElevenLabs API key pra TTS voz
- (Opcional) Discord bot token, WhatsApp pareamento

## Custo mensal por agente (estimado)

| Item | GLM | GPT Codex |
|---|---|---|
| VPS 4-8 GB | R$40-120 | R$40-120 |
| API LLM | US$50-80 (Z.ai) | US$200 (ChatGPT Plus + Codex) |
| OpenAI (Whisper + mem0 embeddings) | US$5-15 | US$5-15 |
| ElevenLabs (audio) | US$5 (basic) | US$5 (basic) |
| Telegram + PostgreSQL | gratis | gratis |
| **TOTAL aprox** | **R$500-700/mes** | **R$1300-1500/mes** |

## Diferencas GLM vs GPT (resumo)

| Aspecto | GLM 4.5/5 Turbo | GPT Codex 5.5 |
|---|---|---|
| Auth | api_key direta (Z.ai) | OAuth (ChatGPT account) |
| Provider key em `openclaw.json` | `zai` | `openai-codex` |
| Modelo primary | `zai/glm-5-turbo` | `openai-codex/gpt-5.5` |
| Fallback recomendado | `zai/glm-5.1`, `zai/glm-5` | `anthropic/claude-opus-4-6` |
| Velocidade | ~2-4s/resposta | ~3-6s/resposta |
| Qualidade copy/codigo | excelente em PT-BR | top-tier global |
| Custo | barato | caro |
| Confiabilidade | media (Z.ai as vezes oscila) | alta |

Setup detalhado de cada caminho:
- [`docs/GLM-SETUP.md`](./docs/GLM-SETUP.md)
- [`docs/GPT-SETUP.md`](./docs/GPT-SETUP.md)
- [`docs/MIGRACAO.md`](./docs/MIGRACAO.md) -- como trocar de GLM pra GPT (ou vice-versa) sem reinstalar nada

## Issues / Suporte

https://github.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/issues

## Como personalizar (placeholders)

Antes de rodar o setup, voce preenche os placeholders no formato `{{NOME}}`. Tabela completa em `SETUP-AGENTE.md` (ETAPA 0).

Resumo dos principais:

| Placeholder | O que e | Onde voce acha |
|---|---|---|
| `{{DONO}}` | Seu primeiro nome (ou da empresa) | Voce decide |
| `{{DONO_NOME_COMPLETO}}` | Nome completo do dono do agente | Voce decide |
| `{{DONO_SLUG}}` | Versao "slug" do nome (lowercase, sem espacos) | Ex: `joao` se voce e Joao |
| `{{EMAIL_DONO}}` | Seu email | Seu email pessoal/profissional |
| `{{NICHO_DONO}}` | Nome da empresa/marca/produto principal | Voce decide |
| `{{TELEGRAM_USER_ID_DONO}}` | Seu ID numerico no Telegram | Mande qualquer msg pra @userinfobot |
| `{{TELEGRAM_BOT_USERNAME}}` | Username do bot que voce criou no @BotFather | Ex: `meuagente_bot` |
| `{{VPS_IP}}` | IP da VPS principal onde roda o agente | Hostinger/Hetzner/DigitalOcean |
| `{{DOMINIO_PRINCIPAL}}` | Seu dominio raiz | Ex: `meusite.com` |
| `{{LLM_BACKEND}}` | `glm` ou `gpt-codex` | Voce decide |
| `{{ZAI_API_KEY}}` | (Se GLM) API key do Z.ai | z.ai painel |
| `{{OPENAI_CODEX_OAUTH_EMAIL}}` | (Se GPT) email da conta ChatGPT Plus | Sua conta |
| `{{SENHA_PADRAO}}` | Senha admin que voce vai usar (TROCA depois!) | Voce define |
| `{{GITHUB_USERNAME}}` | Seu username no GitHub | Conta sua |
